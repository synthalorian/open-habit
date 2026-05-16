use std::sync::Mutex;

use rusqlite::{params, Connection};

use crate::api::model::{
    Achievement, Challenge, ChallengeStatus, CompletionResult, Difficulty, Habit, PlayerProgression,
    PlayerStat, Streak,
};

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Return today's date as "YYYY-MM-DD" using chrono internally.
fn today_string() -> String {
    chrono::Local::now().format("%Y-%m-%d").to_string()
}

/// Compute the player level from total XP.
///
/// Formula: total_xp = 50 × level × (level - 1)
/// Solving for level: level = floor((1 + sqrt(1 + 8·total_xp/50)) / 2)
fn level_from_xp(total_xp: u32) -> u32 {
    if total_xp == 0 {
        return 1;
    }
    let t = total_xp as f64;
    let disc = 1.0 + (8.0 * t) / 50.0;
    let level = ((1.0 + disc.sqrt()) / 2.0).floor() as u32;
    if level < 1 {
        1
    } else {
        level
    }
}

/// XP needed to reach the next level from current total_xp.
fn xp_to_next_level(total_xp: u32) -> u32 {
    let level = level_from_xp(total_xp);
    let next_level_xp = 50 * (level + 1) * level; // XP needed for next level
    let current_xp = 50 * level * (level - 1); // XP at start of current level
    (next_level_xp - current_xp) as u32
}

/// Is `a` one day before `b`?  (all "YYYY-MM-DD")
fn is_yesterday(a: &str, b: &str) -> bool {
    if let (Ok(da), Ok(db)) = (
        chrono::NaiveDate::parse_from_str(a, "%Y-%m-%d"),
        chrono::NaiveDate::parse_from_str(b, "%Y-%m-%d"),
    ) {
        (db - da).num_days() == 1
    } else {
        false
    }
}

/// Is `a` the same day as `b`?
fn is_same_day(a: &str, b: &str) -> bool {
    a == b
}

/// Base XP award per difficulty
fn base_xp(difficulty: &Difficulty) -> u32 {
    match difficulty {
        Difficulty::Easy => 10,
        Difficulty::Medium => 25,
        Difficulty::Hard => 50,
        Difficulty::Extreme => 100,
    }
}

/// Convert a difficulty string to the enum
fn difficulty_from_str(s: &str) -> Difficulty {
    match s.to_lowercase().as_str() {
        "easy" => Difficulty::Easy,
        "hard" => Difficulty::Hard,
        "extreme" => Difficulty::Extreme,
        _ => Difficulty::Medium,
    }
}

/// Convert a frequency string to the enum
fn frequency_from_str(s: &str) -> crate::api::model::Frequency {
    match s.to_lowercase().as_str() {
        "weekly" => crate::api::model::Frequency::Weekly,
        "monthly" => crate::api::model::Frequency::Monthly,
        _ => crate::api::model::Frequency::Daily,
    }
}

/// Convert a status string to the enum
fn status_from_str(s: &str) -> crate::api::model::HabitStatus {
    match s.to_lowercase().as_str() {
        "paused" => crate::api::model::HabitStatus::Paused,
        "archived" => crate::api::model::HabitStatus::Archived,
        _ => crate::api::model::HabitStatus::Active,
    }
}

/// Challenge status from string
fn challenge_status_from_str(s: &str) -> ChallengeStatus {
    match s.to_lowercase().as_str() {
        "completed" => ChallengeStatus::Completed,
        "failed" => ChallengeStatus::Failed,
        _ => ChallengeStatus::Active,
    }
}

/// Challenge status to string
fn challenge_status_to_str(s: &ChallengeStatus) -> &'static str {
    match s {
        ChallengeStatus::Active => "active",
        ChallengeStatus::Completed => "completed",
        ChallengeStatus::Failed => "failed",
    }
}

// ── Default stats ─────────────────────────────────────────────────────────────

const DEFAULT_STATS: &[(&str, &str, &str, &str)] = &[
    ("stat_strength", "Strength", "💪", "#E53935"),
    ("stat_intelligence", "Intelligence", "🧠", "#1E88E5"),
    ("stat_vitality", "Vitality", "❤️", "#43A047"),
    ("stat_agility", "Agility", "⚡", "#FB8C00"),
    ("stat_wisdom", "Wisdom", "🔮", "#8E24AA"),
    ("stat_charisma", "Charisma", "🎭", "#F4511E"),
    ("stat_luck", "Luck", "🍀", "#00ACC1"),
];

// ── Database ──────────────────────────────────────────────────────────────────

/// Thread-safe database handle for open_habit
pub struct Database {
    conn: Mutex<Connection>,
}

impl Database {
    /// Open or create the database at the given path, run migrations.
    pub fn new(db_path: String) -> Result<Self, String> {
        let conn = Connection::open(&db_path).map_err(|e| format!("Failed to open DB: {e}"))?;
        let db = Self {
            conn: Mutex::new(conn),
        };
        db.migrate()?;
        db.seed_default_stats()?;
        db.seed_progression()?;
        Ok(db)
    }

    // ── Migrations ────────────────────────────────────────────────────────

    /// Create all tables if they do not exist.
    fn migrate(&self) -> Result<(), String> {
        let conn = self.conn.lock().map_err(|e| format!("Lock error: {e}"))?;
        conn.execute_batch(
            "
            CREATE TABLE IF NOT EXISTS habits (
                id              TEXT PRIMARY KEY,
                name            TEXT NOT NULL,
                description     TEXT NOT NULL DEFAULT '',
                category        TEXT NOT NULL DEFAULT '',
                difficulty      TEXT NOT NULL DEFAULT 'medium',
                frequency       TEXT NOT NULL DEFAULT 'daily',
                status          TEXT NOT NULL DEFAULT 'active',
                xp_reward       INTEGER NOT NULL DEFAULT 0,
                streak_count    INTEGER NOT NULL DEFAULT 0,
                last_completed  TEXT,
                created_at      TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS streaks (
                habit_id    TEXT PRIMARY KEY,
                count       INTEGER NOT NULL DEFAULT 0,
                is_active   INTEGER NOT NULL DEFAULT 1,
                FOREIGN KEY (habit_id) REFERENCES habits(id) ON DELETE CASCADE
            );

            CREATE TABLE IF NOT EXISTS achievements (
                id          TEXT PRIMARY KEY,
                title       TEXT NOT NULL,
                description TEXT NOT NULL DEFAULT '',
                icon        TEXT NOT NULL DEFAULT '',
                xp_reward   INTEGER NOT NULL DEFAULT 0,
                unlocked    INTEGER NOT NULL DEFAULT 0
            );

            CREATE TABLE IF NOT EXISTS xp_records (
                id          INTEGER PRIMARY KEY AUTOINCREMENT,
                amount      INTEGER NOT NULL,
                source      TEXT NOT NULL DEFAULT 'habit',
                habit_id    TEXT,
                created_at  TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS challenges (
                id              TEXT PRIMARY KEY,
                title           TEXT NOT NULL,
                description     TEXT NOT NULL DEFAULT '',
                challenge_type  TEXT NOT NULL DEFAULT 'streak',
                xp_reward       INTEGER NOT NULL DEFAULT 0,
                progress        INTEGER NOT NULL DEFAULT 0,
                target          INTEGER NOT NULL DEFAULT 1,
                status          TEXT NOT NULL DEFAULT 'active'
            );

            CREATE TABLE IF NOT EXISTS player_stats (
                id                  TEXT PRIMARY KEY,
                name                TEXT NOT NULL,
                value               INTEGER NOT NULL DEFAULT 0,
                level               INTEGER NOT NULL DEFAULT 1,
                xp_in_stat          INTEGER NOT NULL DEFAULT 0,
                xp_to_next          INTEGER NOT NULL DEFAULT 100,
                icon                TEXT NOT NULL DEFAULT '',
                color               TEXT NOT NULL DEFAULT '#FFFFFF',
                category_mappings   TEXT NOT NULL DEFAULT '[]'
            );

            CREATE TABLE IF NOT EXISTS progression (
                id          INTEGER PRIMARY KEY CHECK (id = 1),
                total_xp    INTEGER NOT NULL DEFAULT 0
            );
            ",
        )
        .map_err(|e| format!("Migration failed: {e}"))?;
        Ok(())
    }

    /// Insert the 7 default stats if they do not exist.
    fn seed_default_stats(&self) -> Result<(), String> {
        let conn = self.conn.lock().map_err(|e| format!("Lock error: {e}"))?;
        for (id, name, icon, color) in DEFAULT_STATS {
            conn.execute(
                "INSERT OR IGNORE INTO player_stats (id, name, value, level, xp_in_stat, xp_to_next, icon, color, category_mappings)
                 VALUES (?1, ?2, 0, 1, 0, 100, ?3, ?4, '[]')",
                params![id, name, icon, color],
            )
            .map_err(|e| format!("Seed stats failed: {e}"))?;
        }
        Ok(())
    }

    /// Ensure the single progression row exists.
    fn seed_progression(&self) -> Result<(), String> {
        let conn = self.conn.lock().map_err(|e| format!("Lock error: {e}"))?;
        conn.execute(
            "INSERT OR IGNORE INTO progression (id, total_xp) VALUES (1, 0)",
            [],
        )
        .map_err(|e| format!("Seed progression failed: {e}"))?;
        Ok(())
    }

    // ── Habits ────────────────────────────────────────────────────────────

    /// Get all habits ordered by creation date (newest first).
    pub fn get_all_habits(&self) -> Result<Vec<Habit>, String> {
        let conn = self.conn.lock().map_err(|e| format!("Lock error: {e}"))?;
        let mut stmt = conn
            .prepare(
                "SELECT id, name, description, category, difficulty, frequency, status,
                        xp_reward, streak_count, last_completed, created_at
                 FROM habits ORDER BY created_at DESC",
            )
            .map_err(|e| format!("Prepare failed: {e}"))?;

        let rows = stmt
            .query_map([], |row| {
                Ok(Habit {
                    id: row.get(0)?,
                    name: row.get(1)?,
                    description: row.get(2)?,
                    category: row.get(3)?,
                    difficulty: difficulty_from_str(&row.get::<_, String>(4)?),
                    frequency: frequency_from_str(&row.get::<_, String>(5)?),
                    status: status_from_str(&row.get::<_, String>(6)?),
                    xp_reward: row.get::<_, i32>(7)? as u32,
                    streak_count: row.get::<_, i32>(8)? as u32,
                    last_completed: row.get(9)?,
                    created_at: row.get(10)?,
                })
            })
            .map_err(|e| format!("Query failed: {e}"))?;

        let mut habits = Vec::new();
        for row in rows {
            habits.push(row.map_err(|e| format!("Row error: {e}"))?);
        }
        Ok(habits)
    }

    /// Get a single habit by ID.
    pub fn get_habit(&self, id: String) -> Result<Option<Habit>, String> {
        let conn = self.conn.lock().map_err(|e| format!("Lock error: {e}"))?;
        let mut stmt = conn
            .prepare(
                "SELECT id, name, description, category, difficulty, frequency, status,
                        xp_reward, streak_count, last_completed, created_at
                 FROM habits WHERE id = ?1",
            )
            .map_err(|e| format!("Prepare failed: {e}"))?;

        let mut rows = stmt
            .query_map(params![id], |row| {
                Ok(Habit {
                    id: row.get(0)?,
                    name: row.get(1)?,
                    description: row.get(2)?,
                    category: row.get(3)?,
                    difficulty: difficulty_from_str(&row.get::<_, String>(4)?),
                    frequency: frequency_from_str(&row.get::<_, String>(5)?),
                    status: status_from_str(&row.get::<_, String>(6)?),
                    xp_reward: row.get::<_, i32>(7)? as u32,
                    streak_count: row.get::<_, i32>(8)? as u32,
                    last_completed: row.get(9)?,
                    created_at: row.get(10)?,
                })
            })
            .map_err(|e| format!("Query failed: {e}"))?;

        match rows.next() {
            Some(Ok(habit)) => Ok(Some(habit)),
            Some(Err(e)) => Err(format!("Row error: {e}")),
            None => Ok(None),
        }
    }

    /// Create a new habit.
    pub fn create_habit(&self, habit: Habit) -> Result<(), String> {
        let conn = self.conn.lock().map_err(|e| format!("Lock error: {e}"))?;
        conn.execute(
            "INSERT INTO habits (id, name, description, category, difficulty, frequency, status,
                                xp_reward, streak_count, last_completed, created_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11)",
            params![
                habit.id,
                habit.name,
                habit.description,
                habit.category,
                format!("{:?}", habit.difficulty).to_lowercase(),
                format!("{:?}", habit.frequency).to_lowercase(),
                format!("{:?}", habit.status).to_lowercase(),
                habit.xp_reward as i32,
                habit.streak_count as i32,
                habit.last_completed,
                habit.created_at,
            ],
        )
        .map_err(|e| format!("Insert habit failed: {e}"))?;
        Ok(())
    }

    /// Update a habit's mutable fields.  Only non-None parameters are updated.
    pub fn update_habit(
        &self,
        id: String,
        name: Option<String>,
        description: Option<String>,
        status: Option<String>,
    ) -> Result<(), String> {
        let conn = self.conn.lock().map_err(|e| format!("Lock error: {e}"))?;

        if let Some(n) = name {
            conn.execute(
                "UPDATE habits SET name = ?1 WHERE id = ?2",
                params![n, id],
            )
            .map_err(|e| format!("Update name failed: {e}"))?;
        }
        if let Some(d) = description {
            conn.execute(
                "UPDATE habits SET description = ?1 WHERE id = ?2",
                params![d, id],
            )
            .map_err(|e| format!("Update description failed: {e}"))?;
        }
        if let Some(s) = status {
            conn.execute(
                "UPDATE habits SET status = ?1 WHERE id = ?2",
                params![s, id],
            )
            .map_err(|e| format!("Update status failed: {e}"))?;
        }

        Ok(())
    }

    /// Delete a habit by ID.
    pub fn delete_habit(&self, id: String) -> Result<(), String> {
        let conn = self.conn.lock().map_err(|e| format!("Lock error: {e}"))?;

        conn.execute("DELETE FROM streaks WHERE habit_id = ?1", params![id])
            .map_err(|e| format!("Delete streak failed: {e}"))?;
        conn.execute("DELETE FROM habits WHERE id = ?1", params![id])
            .map_err(|e| format!("Delete habit failed: {e}"))?;

        Ok(())
    }

    /// Complete a habit: update last_completed, manage streak, award XP,
    /// update progression, return a CompletionResult.
    pub fn complete_habit(&self, id: String) -> Result<CompletionResult, String> {
        let today = today_string();
        let conn = self.conn.lock().map_err(|e| format!("Lock error: {e}"))?;

        // ── 1. Fetch current habit state ──────────────────────────────────
        let (_name, difficulty_str, prev_last_completed, prev_streak): (
            String,
            String,
            Option<String>,
            i32,
        ) = conn
            .query_row(
                "SELECT name, difficulty, last_completed, streak_count FROM habits WHERE id = ?1",
                params![id],
                |row| Ok((row.get(0)?, row.get(1)?, row.get(2)?, row.get(3)?)),
            )
            .map_err(|e| format!("Habit not found: {e}"))?;

        let difficulty = difficulty_from_str(&difficulty_str);

        // ── 2. Calculate streak ───────────────────────────────────────────
        let new_streak = match &prev_last_completed {
            Some(prev_date) if is_same_day(prev_date, &today) => {
                // Already done today — same streak, no new XP
                prev_streak as u32
            }
            Some(prev_date) if is_yesterday(prev_date, &today) => {
                // Consecutive day — increment streak
                (prev_streak + 1) as u32
            }
            _ => {
                // First completion or gap — start/restart streak at 1
                1u32
            }
        };

        // ── 3. Calculate XP ───────────────────────────────────────────────
        let base = base_xp(&difficulty);
        let bonus = if new_streak > 1 {
            new_streak * 5
        } else {
            0
        };
        let total_awarded = base + bonus;

        // ── 4. Update habit (last_completed, streak_count) ────────────────
        conn.execute(
            "UPDATE habits SET last_completed = ?1, streak_count = ?2 WHERE id = ?3",
            params![today, new_streak as i32, id],
        )
        .map_err(|e| format!("Update habit completion failed: {e}"))?;

        // ── 5. Upsert streak record ───────────────────────────────────────
        conn.execute(
            "INSERT OR REPLACE INTO streaks (habit_id, count, is_active)
             VALUES (?1, ?2, 1)",
            params![id, new_streak as i32],
        )
        .map_err(|e| format!("Upsert streak failed: {e}"))?;

        // ── 6. Record XP ──────────────────────────────────────────────────
        conn.execute(
            "INSERT INTO xp_records (amount, source, habit_id, created_at)
             VALUES (?1, 'habit', ?2, ?3)",
            params![total_awarded as i32, id, today],
        )
        .map_err(|e| format!("Record XP failed: {e}"))?;

        // ── 7. Update progression ─────────────────────────────────────────
        let prev_total: i32 = conn
            .query_row("SELECT total_xp FROM progression WHERE id = 1", [], |row| {
                row.get(0)
            })
            .map_err(|e| format!("Read progression failed: {e}"))?;

        let new_total = prev_total + total_awarded as i32;
        conn.execute(
            "UPDATE progression SET total_xp = ?1 WHERE id = 1",
            params![new_total],
        )
        .map_err(|e| format!("Update progression failed: {e}"))?;

        // ── 8. Check level-up ─────────────────────────────────────────────
        let old_level = level_from_xp(prev_total as u32);
        let new_level = level_from_xp(new_total as u32);
        let levelled_up = new_level > old_level;

        // ── 9. Check achievements (basic milestone check) ─────────────────
        let new_achievements = check_and_unlock_achievements(&conn, new_total as u32, new_streak)?;

        drop(conn);

        Ok(CompletionResult {
            xp_awarded: base,
            bonus_xp: bonus,
            total_xp: new_total as u32,
            streak: new_streak,
            levelled_up,
            new_achievements,
        })
    }

    // ── Progression ─────────────────────────────────────────────────────────

    /// Get the current player progression.
    pub fn get_progression(&self) -> Result<PlayerProgression, String> {
        let conn = self.conn.lock().map_err(|e| format!("Lock error: {e}"))?;
        let total_xp: i32 = conn
            .query_row("SELECT total_xp FROM progression WHERE id = 1", [], |row| {
                row.get(0)
            })
            .map_err(|e| format!("Read progression failed: {e}"))?;

        let total = total_xp as u32;
        Ok(PlayerProgression {
            total_xp: total,
            level: level_from_xp(total),
            xp_to_next: xp_to_next_level(total),
        })
    }

    /// Record an arbitrary XP award.
    pub fn record_xp(&self, amount: u32) -> Result<(), String> {
        let today = today_string();
        let conn = self.conn.lock().map_err(|e| format!("Lock error: {e}"))?;

        conn.execute(
            "INSERT INTO xp_records (amount, source, habit_id, created_at)
             VALUES (?1, 'manual', NULL, ?2)",
            params![amount as i32, today],
        )
        .map_err(|e| format!("Record XP failed: {e}"))?;

        let prev_total: i32 = conn
            .query_row("SELECT total_xp FROM progression WHERE id = 1", [], |row| {
                row.get(0)
            })
            .map_err(|e| format!("Read progression failed: {e}"))?;

        conn.execute(
            "UPDATE progression SET total_xp = ?1 WHERE id = 1",
            params![prev_total + amount as i32],
        )
        .map_err(|e| format!("Update progression failed: {e}"))?;

        Ok(())
    }

    // ── Achievements ───────────────────────────────────────────────────────

    /// Get all achievements.
    pub fn get_all_achievements(&self) -> Result<Vec<Achievement>, String> {
        let conn = self.conn.lock().map_err(|e| format!("Lock error: {e}"))?;
        let mut stmt = conn
            .prepare(
                "SELECT id, title, description, icon, xp_reward, unlocked
                 FROM achievements ORDER BY id",
            )
            .map_err(|e| format!("Prepare failed: {e}"))?;

        let rows = stmt
            .query_map([], |row| {
                Ok(Achievement {
                    id: row.get(0)?,
                    title: row.get(1)?,
                    description: row.get(2)?,
                    icon: row.get(3)?,
                    xp_reward: row.get::<_, i32>(4)? as u32,
                    unlocked: row.get::<_, i32>(5)? != 0,
                })
            })
            .map_err(|e| format!("Query failed: {e}"))?;

        let mut achievements = Vec::new();
        for row in rows {
            achievements.push(row.map_err(|e| format!("Row error: {e}"))?);
        }
        Ok(achievements)
    }

    // ── Streaks ────────────────────────────────────────────────────────────

    /// Get all streak records.
    pub fn get_all_streaks(&self) -> Result<Vec<Streak>, String> {
        let conn = self.conn.lock().map_err(|e| format!("Lock error: {e}"))?;
        let mut stmt = conn
            .prepare("SELECT habit_id, count, is_active FROM streaks ORDER BY habit_id")
            .map_err(|e| format!("Prepare failed: {e}"))?;

        let rows = stmt
            .query_map([], |row| {
                Ok(Streak {
                    habit_id: row.get(0)?,
                    count: row.get::<_, i32>(1)? as u32,
                    is_active: row.get::<_, i32>(2)? != 0,
                })
            })
            .map_err(|e| format!("Query failed: {e}"))?;

        let mut streaks = Vec::new();
        for row in rows {
            streaks.push(row.map_err(|e| format!("Row error: {e}"))?);
        }
        Ok(streaks)
    }

    // ── Challenges ─────────────────────────────────────────────────────────

    /// Get all challenges.
    pub fn get_all_challenges(&self) -> Result<Vec<Challenge>, String> {
        let conn = self.conn.lock().map_err(|e| format!("Lock error: {e}"))?;
        let mut stmt = conn
            .prepare(
                "SELECT id, title, description, challenge_type, xp_reward,
                        progress, target, status
                 FROM challenges ORDER BY id",
            )
            .map_err(|e| format!("Prepare failed: {e}"))?;

        let rows = stmt
            .query_map([], |row| {
                let ctype: String = row.get(3)?;
                let target: i32 = row.get(6)?;
                Ok(Challenge {
                    id: row.get(0)?,
                    title: row.get(1)?,
                    description: row.get(2)?,
                    challenge_type: if ctype.to_lowercase() == "completions" {
                        crate::api::model::ChallengeType::Completions(target as u32)
                    } else {
                        crate::api::model::ChallengeType::Streak(target as u32)
                    },
                    xp_reward: row.get::<_, i32>(4)? as u32,
                    progress: row.get::<_, i32>(5)? as u32,
                    target: target as u32,
                    status: challenge_status_from_str(&row.get::<_, String>(7)?),
                })
            })
            .map_err(|e| format!("Query failed: {e}"))?;

        let mut challenges = Vec::new();
        for row in rows {
            challenges.push(row.map_err(|e| format!("Row error: {e}"))?);
        }
        Ok(challenges)
    }

    /// Replace all challenges with the given list.
    pub fn save_challenges(&self, challenges: Vec<Challenge>) -> Result<(), String> {
        let conn = self.conn.lock().map_err(|e| format!("Lock error: {e}"))?;
        conn.execute_batch("DELETE FROM challenges")
            .map_err(|e| format!("Clear challenges failed: {e}"))?;

        for c in &challenges {
            let (ctype_str, target) = match &c.challenge_type {
                crate::api::model::ChallengeType::Streak(t) => ("streak", *t),
                crate::api::model::ChallengeType::Completions(t) => ("completions", *t),
            };
            conn.execute(
                "INSERT INTO challenges (id, title, description, challenge_type, xp_reward,
                                        progress, target, status)
                 VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)",
                params![
                    c.id,
                    c.title,
                    c.description,
                    ctype_str,
                    c.xp_reward as i32,
                    c.progress as i32,
                    target as i32,
                    challenge_status_to_str(&c.status),
                ],
            )
            .map_err(|e| format!("Insert challenge failed: {e}"))?;
        }
        Ok(())
    }

    /// Increment a challenge's progress by `amount`. Auto-completes if target is reached.
    pub fn progress_challenge(&self, id: String, amount: u32) -> Result<Challenge, String> {
        let conn = self.conn.lock().map_err(|e| format!("Lock error: {e}"))?;

        // Fetch current challenge
        let (current_progress, target, current_status): (i32, i32, String) = conn
            .query_row(
                "SELECT progress, target, status FROM challenges WHERE id = ?1",
                params![id],
                |row| Ok((row.get(0)?, row.get(1)?, row.get(2)?)),
            )
            .map_err(|e| format!("Challenge not found: {e}"))?;

        if current_status != "active" {
            // Already completed/failed; return as-is
            return get_challenge_by_id(&conn, &id);
        }

        let new_progress = (current_progress + amount as i32).min(target);
        let new_status = if new_progress >= target {
            // Complete! Award XP
            let xp_reward: i32 = conn
                .query_row(
                    "SELECT xp_reward FROM challenges WHERE id = ?1",
                    params![id],
                    |row| row.get(0),
                )
                .map_err(|e| format!("Read challenge failed: {e}"))?;

            let today = today_string();
            conn.execute(
                "INSERT INTO xp_records (amount, source, habit_id, created_at)
                 VALUES (?1, 'challenge', NULL, ?2)",
                params![xp_reward, today],
            )
            .map_err(|e| format!("Record challenge XP failed: {e}"))?;

            let prev_total: i32 = conn
                .query_row(
                    "SELECT total_xp FROM progression WHERE id = 1",
                    [],
                    |row| row.get(0),
                )
                .map_err(|e| format!("Read progression failed: {e}"))?;

            conn.execute(
                "UPDATE progression SET total_xp = ?1 WHERE id = 1",
                params![prev_total + xp_reward],
            )
            .map_err(|e| format!("Update progression failed: {e}"))?;

            "completed"
        } else {
            "active"
        };

        conn.execute(
            "UPDATE challenges SET progress = ?1, status = ?2 WHERE id = ?3",
            params![new_progress, new_status, id],
        )
        .map_err(|e| format!("Update challenge failed: {e}"))?;

        get_challenge_by_id(&conn, &id)
    }

    // ── Player Stats ───────────────────────────────────────────────────────

    /// Get all player stats.
    pub fn get_all_stats(&self) -> Result<Vec<PlayerStat>, String> {
        let conn = self.conn.lock().map_err(|e| format!("Lock error: {e}"))?;
        let mut stmt = conn
            .prepare(
                "SELECT id, name, value, level, xp_in_stat, xp_to_next, icon, color, category_mappings
                 FROM player_stats ORDER BY id",
            )
            .map_err(|e| format!("Prepare failed: {e}"))?;

        let rows = stmt
            .query_map([], |row| {
                Ok(PlayerStat {
                    id: row.get(0)?,
                    name: row.get(1)?,
                    value: row.get(2)?,
                    level: row.get::<_, i32>(3)? as u32,
                    xp_in_stat: row.get::<_, i32>(4)? as u32,
                    xp_to_next: row.get::<_, i32>(5)? as u32,
                    icon: row.get(6)?,
                    color: row.get(7)?,
                    category_mappings: row.get(8)?,
                })
            })
            .map_err(|e| format!("Query failed: {e}"))?;

        let mut stats = Vec::new();
        for row in rows {
            stats.push(row.map_err(|e| format!("Row error: {e}"))?);
        }
        Ok(stats)
    }

    /// Insert or update a player stat.
    pub fn upsert_stat(&self, stat: PlayerStat) -> Result<(), String> {
        let conn = self.conn.lock().map_err(|e| format!("Lock error: {e}"))?;
        conn.execute(
            "INSERT OR REPLACE INTO player_stats (id, name, value, level, xp_in_stat, xp_to_next, icon, color, category_mappings)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)",
            params![
                stat.id,
                stat.name,
                stat.value,
                stat.level as i32,
                stat.xp_in_stat as i32,
                stat.xp_to_next as i32,
                stat.icon,
                stat.color,
                stat.category_mappings,
            ],
        )
        .map_err(|e| format!("Upsert stat failed: {e}"))?;
        Ok(())
    }

    /// Delete a player stat by ID.
    pub fn delete_stat(&self, id: String) -> Result<(), String> {
        let conn = self.conn.lock().map_err(|e| format!("Lock error: {e}"))?;
        conn.execute("DELETE FROM player_stats WHERE id = ?1", params![id])
            .map_err(|e| format!("Delete stat failed: {e}"))?;
        Ok(())
    }

    /// Get the default 7 stats (re-seeded).
    pub fn get_default_stats(&self) -> Result<Vec<PlayerStat>, String> {
        // Re-seed to ensure defaults exist, then read them back
        self.seed_default_stats()?;
        self.get_all_stats().map(|all| {
            all.into_iter()
                .filter(|s| DEFAULT_STATS.iter().any(|(id, _, _, _)| id == &s.id))
                .collect()
        })
    }

    // ── Reset ──────────────────────────────────────────────────────────────

    /// Delete all data and re-initialise with defaults.
    pub fn reset_all_data(&self) -> Result<(), String> {
        let conn = self.conn.lock().map_err(|e| format!("Lock error: {e}"))?;
        conn.execute_batch(
            "DELETE FROM habits;
             DELETE FROM streaks;
             DELETE FROM achievements;
             DELETE FROM xp_records;
             DELETE FROM challenges;
             DELETE FROM player_stats;
             DELETE FROM progression;",
        )
        .map_err(|e| format!("Reset failed: {e}"))?;

        // Re-seed defaults
        drop(conn);
        self.seed_default_stats()?;
        self.seed_progression()?;
        Ok(())
    }
}

// ── Internal helpers (not public API) ─────────────────────────────────────────

/// Fetch a single challenge by ID (used internally within a locked connection).
fn get_challenge_by_id(conn: &Connection, id: &str) -> Result<Challenge, String> {
    let mut stmt = conn
        .prepare(
            "SELECT id, title, description, challenge_type, xp_reward,
                    progress, target, status
             FROM challenges WHERE id = ?1",
        )
        .map_err(|e| format!("Prepare failed: {e}"))?;

    stmt.query_row(params![id], |row| {
        let ctype: String = row.get(3)?;
        let target: i32 = row.get(6)?;
        Ok(Challenge {
            id: row.get(0)?,
            title: row.get(1)?,
            description: row.get(2)?,
            challenge_type: if ctype.to_lowercase() == "completions" {
                crate::api::model::ChallengeType::Completions(target as u32)
            } else {
                crate::api::model::ChallengeType::Streak(target as u32)
            },
            xp_reward: row.get::<_, i32>(4)? as u32,
            progress: row.get::<_, i32>(5)? as u32,
            target: target as u32,
            status: challenge_status_from_str(&row.get::<_, String>(7)?),
        })
    })
    .map_err(|e| format!("Query challenge failed: {e}"))
}

/// Check and unlock milestone achievements.  Returns any newly-unlocked achievements.
fn check_and_unlock_achievements(
    conn: &Connection,
    total_xp: u32,
    streak: u32,
) -> Result<Vec<Achievement>, String> {
    let mut new_achievements = Vec::new();

    // XP milestones
    let xp_milestones: Vec<(&str, &str, &str, &str, u32, u32)> = vec![
        ("ach_first_xp", "First Steps", "Earn your first XP", "⭐", 10, 1),
        ("ach_100_xp", "Century", "Earn 100 total XP", "🏅", 25, 100),
        ("ach_500_xp", "Iron Will", "Earn 500 total XP", "🥈", 50, 500),
        ("ach_1000_xp", "Unstoppable", "Earn 1,000 total XP", "🥇", 100, 1000),
        ("ach_5000_xp", "Legendary", "Earn 5,000 total XP", "🏆", 250, 5000),
    ];

    for (id, title, desc, icon, reward, threshold) in &xp_milestones {
        if total_xp >= *threshold {
            maybe_unlock(conn, id, title, desc, icon, *reward, &mut new_achievements)?;
        }
    }

    // Streak milestones
    let streak_milestones: Vec<(&str, &str, &str, &str, u32, u32)> = vec![
        ("ach_streak_3", "Threepeat", "3-day streak", "🔥", 15, 3),
        ("ach_streak_7", "Week Warrior", "7-day streak", "📅", 30, 7),
        ("ach_streak_14", "Fortnight Force", "14-day streak", "💪", 50, 14),
        ("ach_streak_30", "Monthly Master", "30-day streak", "🌙", 100, 30),
    ];

    for (id, title, desc, icon, reward, threshold) in &streak_milestones {
        if streak >= *threshold {
            maybe_unlock(conn, id, title, desc, icon, *reward, &mut new_achievements)?;
        }
    }

    Ok(new_achievements)
}

/// If an achievement doesn't exist, create and unlock it, and add to `out`.
fn maybe_unlock(
    conn: &Connection,
    id: &str,
    title: &str,
    description: &str,
    icon: &str,
    xp_reward: u32,
    out: &mut Vec<Achievement>,
) -> Result<(), String> {
    let exists: bool = conn
        .query_row(
            "SELECT COUNT(*) FROM achievements WHERE id = ?1",
            params![id],
            |row| row.get::<_, i32>(0),
        )
        .map(|c| c > 0)
        .unwrap_or(false);

    if !exists {
        conn.execute(
            "INSERT INTO achievements (id, title, description, icon, xp_reward, unlocked)
             VALUES (?1, ?2, ?3, ?4, ?5, 1)",
            params![id, title, description, icon, xp_reward as i32],
        )
        .map_err(|e| format!("Insert achievement failed: {e}"))?;

        // Award XP for achievement
        conn.execute(
            "INSERT INTO xp_records (amount, source, habit_id, created_at)
             VALUES (?1, 'achievement', NULL, ?2)",
            params![xp_reward as i32, today_string()],
        )
        .map_err(|e| format!("Record achievement XP failed: {e}"))?;

        let prev_total: i32 = conn
            .query_row("SELECT total_xp FROM progression WHERE id = 1", [], |row| {
                row.get(0)
            })
            .map_err(|e| format!("Read progression failed: {e}"))?;
        conn.execute(
            "UPDATE progression SET total_xp = ?1 WHERE id = 1",
            params![prev_total + xp_reward as i32],
        )
        .map_err(|e| format!("Update progression failed: {e}"))?;

        out.push(Achievement {
            id: id.to_string(),
            title: title.to_string(),
            description: description.to_string(),
            icon: icon.to_string(),
            xp_reward,
            unlocked: true,
        });
    }
    Ok(())
}
