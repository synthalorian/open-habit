//! open_habit_db — SQLite persistence layer
//!
//! Provides persistent storage for habits, achievements, XP records,
//! streaks, and challenges. All data is stored in a single SQLite database
//! file, making the app fully offline-first.

use chrono::{NaiveDate, Utc};
use open_habit_shared::*;
use rusqlite::{params, Connection, Row};
use std::path::Path;
use uuid::Uuid;

// ─── Database errors ──────────────────────────────────────────────────

#[derive(Debug, thiserror::Error)]
pub enum DBError {
    #[error("database error: {0}")]
    SQL(#[from] rusqlite::Error),
    #[error("initialization failed: {0}")]
    Init(String),
    #[error("parse error: {0}")]
    Parse(String),
}

pub type DBResult<T> = std::result::Result<T, DBError>;

// ─── Thread-safe client ──────────────────────────────────────────────

use std::sync::mpsc;
use std::thread;

pub enum DbCommand {
    ListHabits { status: Option<String>, respond: mpsc::Sender<DBResult<Vec<Habit>>> },
    GetHabit { id: String, respond: mpsc::Sender<DBResult<Option<Habit>>> },
    CreateHabit { habit: Habit, respond: mpsc::Sender<DBResult<()>> },
    CompleteHabit { id: String, respond: mpsc::Sender<DBResult<u32>> },
    GetProgression { respond: mpsc::Sender<DBResult<PlayerProgression>> },
    RecordXp { xp: u32, respond: mpsc::Sender<DBResult<()>> },
    ListAchievements { respond: mpsc::Sender<DBResult<Vec<Achievement>>> },
    ListChallenges { respond: mpsc::Sender<DBResult<Vec<Challenge>>> },
    ListStreaks { respond: mpsc::Sender<DBResult<Vec<Streak>>> },
    UpdateHabit { id: String, name: Option<String>, description: Option<String>, status: Option<String>, respond: mpsc::Sender<DBResult<()>> },
    DeleteHabit { id: String, respond: mpsc::Sender<DBResult<()>> },
}

pub struct DatabaseClient {
    sender: mpsc::Sender<DbCommand>,
}

impl DatabaseClient {
    pub fn new(path: String) -> DBResult<Self> {
        let (sender, receiver) = mpsc::channel();

        thread::spawn(move || {
            let mut db = match Database::open(path) {
                Ok(db) => db,
                Err(e) => {
                    eprintln!("Failed to open database: {}", e);
                    return;
                }
            };
            while let Ok(cmd) = receiver.recv() {
                match cmd {
                    DbCommand::ListHabits { status, respond } => {
                        respond.send(db.list_habits(status.as_deref())).ok();
                    }
                    DbCommand::GetHabit { id, respond } => {
                        let uuid = Uuid::parse_str(&id).map_err(|e| DBError::Parse(e.to_string()));
                        respond.send(match uuid {
                            Ok(uuid) => db.get_habit(&uuid),
                            Err(e) => Err(e),
                        }).ok();
                    }
                    DbCommand::CreateHabit { habit, respond } => {
                        respond.send(db.create_habit(&habit)).ok();
                    }
                    DbCommand::CompleteHabit { id, respond } => {
                        let uuid = Uuid::parse_str(&id).map_err(|e| DBError::Parse(e.to_string()));
                        respond.send(match uuid {
                            Ok(uuid) => {
                                let today = Utc::now().date_naive();
                                db.complete_habit(&uuid, today)
                            }
                            Err(e) => Err(e),
                        }).ok();
                    }
                    DbCommand::GetProgression { respond } => {
                        respond.send(db.get_progression()).ok();
                    }
                    DbCommand::RecordXp { xp, respond } => {
                        let today = Utc::now().date_naive();
                        respond.send(db.record_xp(xp, "API", None, today)).ok();
                    }
                    DbCommand::ListAchievements { respond } => {
                        respond.send(db.list_achievements()).ok();
                    }
                    DbCommand::ListChallenges { respond } => {
                        respond.send(db.list_challenges()).ok();
                    }
                    DbCommand::ListStreaks { respond } => {
                        respond.send(db.list_all_streaks()).ok();
                    }
                    DbCommand::UpdateHabit { id, name, description, status, respond } => {
                        let uuid = Uuid::parse_str(&id).map_err(|e| DBError::Parse(e.to_string()));
                        respond.send(match uuid {
                            Ok(uuid) => db.update_habit(&uuid, name.as_deref(), description.as_deref(), status.as_deref()),
                            Err(e) => Err(e),
                        }).ok();
                    }
                    DbCommand::DeleteHabit { id, respond } => {
                        let uuid = Uuid::parse_str(&id).map_err(|e| DBError::Parse(e.to_string()));
                        respond.send(match uuid {
                            Ok(uuid) => db.delete_habit(&uuid),
                            Err(e) => Err(e),
                        }).ok();
                    }
                }
            }
        });

        Ok(Self { sender })
    }

    fn send<T, F>(&self, cmd: DbCommand, f: F) -> T
    where
        F: FnOnce(Option<DBResult<T>>) -> T,
    {
        let (respond, recv) = mpsc::channel();
        // This sends the command to the receiver; the receiver will send the response
        self.sender.send(cmd).ok();
        // Wait for response
        f(recv.recv().ok())
    }

    pub fn list_habits(&self, status: Option<String>) -> DBResult<Vec<Habit>> {
        let (respond, recv) = mpsc::channel();
        self.sender.send(DbCommand::ListHabits { status, respond }).ok();
        recv.recv().unwrap()
    }

    pub fn get_habit(&self, id: String) -> DBResult<Option<Habit>> {
        let (respond, recv) = mpsc::channel();
        self.sender.send(DbCommand::GetHabit { id, respond }).ok();
        recv.recv().unwrap()
    }

    pub fn create_habit(&self, habit: Habit) -> DBResult<()> {
        let (respond, recv) = mpsc::channel();
        self.sender.send(DbCommand::CreateHabit { habit, respond }).ok();
        recv.recv().unwrap()
    }

    pub fn complete_habit(&self, id: String) -> DBResult<u32> {
        let (respond, recv) = mpsc::channel();
        self.sender.send(DbCommand::CompleteHabit { id, respond }).ok();
        recv.recv().unwrap()
    }

    pub fn get_progression(&self) -> DBResult<PlayerProgression> {
        let (respond, recv) = mpsc::channel();
        self.sender.send(DbCommand::GetProgression { respond }).ok();
        recv.recv().unwrap()
    }

    pub fn record_xp(&self, xp: u32) -> DBResult<()> {
        let (respond, recv) = mpsc::channel();
        self.sender.send(DbCommand::RecordXp { xp, respond }).ok();
        recv.recv().unwrap()
    }

    pub fn list_achievements(&self) -> DBResult<Vec<Achievement>> {
        let (respond, recv) = mpsc::channel();
        self.sender.send(DbCommand::ListAchievements { respond }).ok();
        recv.recv().unwrap()
    }

    pub fn list_challenges(&self) -> DBResult<Vec<Challenge>> {
        let (respond, recv) = mpsc::channel();
        self.sender.send(DbCommand::ListChallenges { respond }).ok();
        recv.recv().unwrap()
    }

    pub fn list_streaks(&self) -> DBResult<Vec<Streak>> {
        let (respond, recv) = mpsc::channel();
        self.sender.send(DbCommand::ListStreaks { respond }).ok();
        recv.recv().unwrap()
    }

    pub fn update_habit(&self, id: String, name: Option<String>, description: Option<String>, status: Option<String>) -> DBResult<()> {
        let (respond, recv) = mpsc::channel();
        self.sender.send(DbCommand::UpdateHabit { id, name, description, status, respond }).ok();
        recv.recv().unwrap()
    }

    pub fn delete_habit(&self, id: String) -> DBResult<()> {
        let (respond, recv) = mpsc::channel();
        self.sender.send(DbCommand::DeleteHabit { id, respond }).ok();
        recv.recv().unwrap()
    }
}

/// Manages the SQLite database connection and schema.
pub struct Database {
    conn: Connection,
}

impl Database {
    /// Open or create a database at the given path.
    pub fn open(path: impl AsRef<Path>) -> DBResult<Self> {
        let conn = Connection::open(path)
            .map_err(|e| DBError::Init(format!("Failed to open database: {}", e)))?;
        let db = Self { conn };
        db.initialize()?;
        Ok(db)
    }

    /// Open an in-memory database (useful for testing).
    pub fn open_memory() -> DBResult<Self> {
        let conn = Connection::open_in_memory()
            .map_err(|e| DBError::Init(format!("Failed to open in-memory DB: {}", e)))?;
        let db = Self { conn };
        db.initialize()?;
        Ok(db)
    }

    fn initialize(&self) -> DBResult<()> {
        self.conn.execute_batch(
            r#"
            CREATE TABLE IF NOT EXISTS habits (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                description TEXT,
                category TEXT NOT NULL DEFAULT 'general',
                difficulty TEXT NOT NULL DEFAULT 'easy',
                frequency TEXT NOT NULL DEFAULT 'daily',
                status TEXT NOT NULL DEFAULT 'active',
                created_at TEXT NOT NULL,
                last_completed TEXT,
                current_streak INTEGER NOT NULL DEFAULT 0,
                best_streak INTEGER NOT NULL DEFAULT 0,
                total_completions INTEGER NOT NULL DEFAULT 0,
                xp_reward INTEGER NOT NULL DEFAULT 10,
                UNIQUE(name)
            );

            CREATE TABLE IF NOT EXISTS achievements (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                description TEXT NOT NULL,
                icon TEXT NOT NULL DEFAULT '🎖️',
                xp_reward INTEGER NOT NULL,
                category TEXT NOT NULL,
                unlocked INTEGER NOT NULL DEFAULT 0,
                unlocked_at TEXT,
                level_requirement INTEGER NOT NULL DEFAULT 1
            );

            CREATE TABLE IF NOT EXISTS xp_records (
                id TEXT PRIMARY KEY,
                amount INTEGER NOT NULL,
                source_type TEXT NOT NULL,
                source_id TEXT,
                date TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS streaks (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                habit_id TEXT NOT NULL UNIQUE,
                count INTEGER NOT NULL DEFAULT 0,
                started_at TEXT NOT NULL,
                last_date TEXT NOT NULL,
                is_active INTEGER NOT NULL DEFAULT 1,
                FOREIGN KEY (habit_id) REFERENCES habits(id)
            );

            CREATE TABLE IF NOT EXISTS challenges (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                description TEXT NOT NULL,
                type TEXT NOT NULL,
                status TEXT NOT NULL DEFAULT 'active',
                progress INTEGER NOT NULL DEFAULT 0,
                target INTEGER NOT NULL,
                xp_reward INTEGER NOT NULL,
                expires_at TEXT,
                completed_at TEXT
            );

            CREATE TABLE IF NOT EXISTS progression (
                id INTEGER PRIMARY KEY CHECK (id = 1),
                total_xp INTEGER NOT NULL DEFAULT 0,
                level INTEGER NOT NULL DEFAULT 1,
                xp_to_next INTEGER NOT NULL DEFAULT 120
            );

            INSERT OR IGNORE INTO progression (id, total_xp, level, xp_to_next)
                VALUES (1, 0, 1, 120);

            CREATE INDEX IF NOT EXISTS idx_habits_status ON habits(status);
            CREATE INDEX IF NOT EXISTS idx_streaks_habit ON streaks(habit_id);
            CREATE INDEX IF NOT EXISTS idx_xp_records_date ON xp_records(date);
        "#,
        )?;
        Ok(())
    }

    // ─── Habit CRUD ────────────────────────────────────────────────────

    pub fn create_habit(&mut self, habit: &Habit) -> DBResult<()> {
        self.conn.execute(
            r#"INSERT OR IGNORE INTO habits (id, name, description, category, difficulty, frequency, status, created_at, last_completed, current_streak, best_streak, total_completions, xp_reward)
               VALUES (:id, :name, :description, :category, :difficulty, :frequency, :status, :created_at, :last_completed, :current_streak, :best_streak, :total_completions, :xp_reward)"#,
            params![
                &habit.id.to_string(),
                &habit.name,
                &habit.description,
                &habit.category,
                &format!("{:?}", habit.difficulty),
                &format!("{:?}", habit.frequency),
                &format!("{:?}", habit.status),
                &habit.created_at.to_string(),
                &habit.last_completed.map(|d| d.to_string()),
                habit.current_streak,
                habit.best_streak,
                habit.total_completions,
                habit.xp_reward,
            ],
        )?;
        Ok(())
    }

    pub fn get_habit(&self, id: &Uuid) -> DBResult<Option<Habit>> {
        let mut stmt = self.conn.prepare(
            r#"SELECT id, name, description, category, difficulty, frequency, status, created_at, last_completed, current_streak, best_streak, total_completions, xp_reward FROM habits WHERE id = ?"#
        )?;
        let mut rows = stmt.query(params![&id.to_string()])?;
        if let Some(row) = rows.next()? {
            Ok(Some(Self::row_to_habit(row)?))
        } else {
            Ok(None)
        }
    }

    pub fn list_habits(&self, status: Option<&str>) -> DBResult<Vec<Habit>> {
        let query = match status {
            Some(s) => format!("WHERE status = '{}'", s),
            None => String::from("WHERE status = 'Active'"),
        };
        let mut stmt = self.conn.prepare(&format!(
            "SELECT id, name, description, category, difficulty, frequency, status, created_at, last_completed, current_streak, best_streak, total_completions, xp_reward FROM habits {} ORDER BY name",
            query
        ))?;
        let mut rows = stmt.query([])?;
        let mut habits = Vec::new();
        while let Some(row) = rows.next()? {
            habits.push(Self::row_to_habit(row)?);
        }
        Ok(habits)
    }

    pub fn update_habit(
        &mut self,
        id: &Uuid,
        name: Option<&str>,
        description: Option<&str>,
        status: Option<&str>,
    ) -> DBResult<()> {
        self.conn.execute(
            r#"UPDATE habits SET name = COALESCE(:name, name), description = COALESCE(:description, description), status = COALESCE(:status, status) WHERE id = :id"#,
            params![
                &name.map(|s| s.to_string()),
                &description.map(|s| s.to_string()),
                &status.map(|s| s.to_string()),
                &id.to_string(),
            ],
        )?;
        Ok(())
    }

    pub fn complete_habit(&mut self, id: &Uuid, completed_date: NaiveDate) -> DBResult<u32> {
        self.conn.execute(
            r#"UPDATE habits SET last_completed = :completed, current_streak = current_streak + 1, total_completions = total_completions + 1, status = 'active'
               WHERE id = :id"#,
            params![
                &completed_date.to_string(),
                &id.to_string(),
            ],
        )?;
        if let Some(habit) = self.get_habit(id)? {
            Ok(habit.xp_reward)
        } else {
            Ok(0)
        }
    }

    pub fn delete_habit(&mut self, id: &Uuid) -> DBResult<()> {
        self.conn.execute(
            "DELETE FROM habits WHERE id = ?",
            params![&id.to_string()],
        )?;
        Ok(())
    }

    // ─── XP & Progression ─────────────────────────────────────────────

    pub fn add_xp(&mut self, amount: u32) -> DBResult<u32> {
        let (new_total, new_level, new_xp_to_next) = self.conn.query_row(
            "SELECT total_xp, level, xp_to_next FROM progression WHERE id = 1",
            [],
            |row| {
                let total_xp: u32 = row.get(0)?;
                let new_total = total_xp + amount;
                let new_level = (new_total / 100).max(1);
                let new_xp_to_next = (new_level + 1) * 100;
                Ok::<(u32, u32, u32), rusqlite::Error>((new_total, new_level, new_xp_to_next))
            },
        )?;

        self.conn.execute(
            "UPDATE progression SET total_xp = ?, level = ?, xp_to_next = ? WHERE id = 1",
            params![new_total, new_level, new_xp_to_next],
        )?;

        Ok(new_level)
    }

    pub fn get_progression(&self) -> DBResult<PlayerProgression> {
        self.conn.query_row(
            "SELECT total_xp, level, xp_to_next FROM progression WHERE id = 1",
            [],
            |row| {
                Ok(PlayerProgression {
                    total_xp: row.get(0)?,
                    level: row.get(1)?,
                    xp_to_next: row.get(2)?,
                })
            },
        ).map_err(|e| DBError::SQL(e))
    }

    pub fn record_xp(
        &mut self,
        amount: u32,
        source_type: &str,
        source_id: Option<&str>,
        date: NaiveDate,
    ) -> DBResult<()> {
        let id = Uuid::new_v4();
        self.conn.execute(
            "INSERT INTO xp_records (id, amount, source_type, source_id, date) VALUES (?, ?, ?, ?, ?)",
            params![
                &id.to_string(),
                amount,
                source_type,
                source_id.map(|s| s.to_string()),
                &date.to_string(),
            ],
        )?;
        Ok(())
    }

    pub fn list_xp_records(&self, limit: u32) -> DBResult<Vec<XPRecord>> {
        let mut stmt = self.conn.prepare(
            "SELECT id, amount, source_type, source_id, date FROM xp_records ORDER BY date DESC LIMIT ?"
        )?;
        let mut rows = stmt.query(params![limit])?;
        let mut records = Vec::new();
        while let Some(row) = rows.next()? {
            records.push(Self::row_to_xp_record(row)?);
        }
        Ok(records)
    }

    // ─── Streaks ──────────────────────────────────────────────────────

    pub fn save_streak(&mut self, streak: &Streak) -> DBResult<()> {
        self.conn.execute(
            r#"INSERT INTO streaks (habit_id, count, started_at, last_date, is_active)
               VALUES (:habit_id, :count, :started_at, :last_date, :is_active)
               ON CONFLICT(habit_id) DO UPDATE SET count = :count, last_date = :last_date, is_active = :is_active"#,
            params![
                &streak.habit_id.to_string(),
                streak.count,
                &streak.started_at.to_string(),
                &streak.last_date.to_string(),
                streak.is_active as i32,
            ],
        )?;
        Ok(())
    }

    pub fn get_streaks(&self, habit_id: &Uuid) -> DBResult<Vec<Streak>> {
        let mut stmt = self.conn.prepare(
            "SELECT id, habit_id, count, started_at, last_date, is_active FROM streaks WHERE habit_id = ?"
        )?;
        let mut rows = stmt.query(params![&habit_id.to_string()])?;
        let mut streaks = Vec::new();
        while let Some(row) = rows.next()? {
            streaks.push(Self::row_to_streak(row)?);
        }
        Ok(streaks)
    }

    pub fn list_all_streaks(&self) -> DBResult<Vec<Streak>> {
        let mut stmt = self.conn.prepare(
            "SELECT id, habit_id, count, started_at, last_date, is_active FROM streaks WHERE is_active = 1"
        )?;
        let mut rows = stmt.query([])?;
        let mut streaks = Vec::new();
        while let Some(row) = rows.next()? {
            streaks.push(Self::row_to_streak(row)?);
        }
        Ok(streaks)
    }

    // ─── Achievements ─────────────────────────────────────────────────

    pub fn save_achievements(&mut self, achievements: &[Achievement]) -> DBResult<()> {
        for achievement in achievements {
            self.conn.execute(
                r#"INSERT OR REPLACE INTO achievements (id, title, description, icon, xp_reward, category, unlocked, unlocked_at, level_requirement)
                   VALUES (:id, :title, :description, :icon, :xp_reward, :category, :unlocked, :unlocked_at, :level_requirement)"#,
                params![
                    &achievement.id.to_string(),
                    &achievement.title,
                    &achievement.description,
                    &achievement.icon,
                    achievement.xp_reward,
                    &format!("{:?}", achievement.category),
                    achievement.unlocked as i32,
                    &achievement.unlocked_at.map(|d| d.to_string()),
                    achievement.level_requirement,
                ],
            )?;
        }
        Ok(())
    }

    pub fn list_achievements(&self) -> DBResult<Vec<Achievement>> {
        let mut stmt = self.conn.prepare(
            "SELECT id, title, description, icon, xp_reward, category, unlocked, unlocked_at, level_requirement FROM achievements ORDER BY unlocked ASC, title"
        )?;
        let mut rows = stmt.query([])?;
        let mut achievements = Vec::new();
        while let Some(row) = rows.next()? {
            achievements.push(Self::row_to_achievement(row)?);
        }
        Ok(achievements)
    }

    // ─── Challenges ───────────────────────────────────────────────────

    pub fn save_challenges(&mut self, challenges: &[Challenge]) -> DBResult<()> {
        for challenge in challenges {
            self.conn.execute(
                r#"INSERT OR REPLACE INTO challenges (id, title, description, type, status, progress, target, xp_reward, expires_at, completed_at)
                   VALUES (:id, :title, :description, :type, :status, :progress, :target, :xp_reward, :expires_at, :completed_at)"#,
                params![
                    &challenge.id.to_string(),
                    &challenge.title,
                    &challenge.description,
                    &format!("{:?}", challenge.challenge_type),
                    &format!("{:?}", challenge.status),
                    challenge.progress,
                    challenge.target,
                    challenge.xp_reward,
                    &challenge.expires_at.map(|d| d.to_string()),
                    &challenge.completed_at.map(|d| d.to_string()),
                ],
            )?;
        }
        Ok(())
    }

    pub fn list_challenges(&self) -> DBResult<Vec<Challenge>> {
        let mut stmt = self.conn.prepare(
            "SELECT id, title, description, type, status, progress, target, xp_reward, expires_at, completed_at FROM challenges ORDER BY status, title"
        )?;
        let mut rows = stmt.query([])?;
        let mut challenges = Vec::new();
        while let Some(row) = rows.next()? {
            challenges.push(Self::row_to_challenge(row)?);
        }
        Ok(challenges)
    }

    // ─── Row parsers ──────────────────────────────────────────────────

    fn row_to_habit(row: &Row<'_>) -> DBResult<Habit> {
        Ok(Habit {
            id: Uuid::parse_str(&row.get::<_, String>(0)?).map_err(|e| DBError::Parse(e.to_string()))?,
            name: row.get(1)?,
            description: row.get(2)?,
            category: row.get(3)?,
            difficulty: Self::parse_difficulty(row.get::<_, String>(4)?),
            frequency: Self::parse_frequency(row.get::<_, String>(5)?),
            status: Self::parse_habit_status(row.get::<_, String>(6)?),
            created_at: NaiveDate::parse_from_str(&row.get::<_, String>(7)?, "%Y-%m-%d")
                .map_err(|e| DBError::Parse(e.to_string()))?,
            last_completed: Self::parse_date(&row.get::<_, Option<String>>(8)?),
            current_streak: row.get(9)?,
            best_streak: row.get(10)?,
            total_completions: row.get(11)?,
            xp_reward: row.get(12)?,
        })
    }

    fn row_to_streak(row: &Row<'_>) -> DBResult<Streak> {
        Ok(Streak {
            habit_id: Uuid::parse_str(&row.get::<_, String>(1)?).map_err(|e| DBError::Parse(e.to_string()))?,
            count: row.get(2)?,
            started_at: NaiveDate::parse_from_str(&row.get::<_, String>(3)?, "%Y-%m-%d")
                .map_err(|e| DBError::Parse(e.to_string()))?,
            last_date: NaiveDate::parse_from_str(&row.get::<_, String>(4)?, "%Y-%m-%d")
                .map_err(|e| DBError::Parse(e.to_string()))?,
            is_active: row.get::<_, i32>(5)? == 1,
        })
    }

    fn row_to_xp_record(row: &Row<'_>) -> DBResult<XPRecord> {
        let source_type = row.get::<_, String>(2)?;
        let source_id = row.get::<_, Option<String>>(3)?;
        let source = match source_type.as_str() {
            "HabitCompletion" => XPSource::HabitCompletion {
                habit_id: Self::parse_uuid(&source_id).unwrap_or(Uuid::new_v4()),
            },
            "StreakBonus" => XPSource::StreakBonus { streak_length: 0 },
            "AchievementUnlock" => XPSource::AchievementUnlock {
                achievement_id: Self::parse_uuid(&source_id).unwrap_or(Uuid::new_v4()),
            },
            "ChallengeComplete" => XPSource::ChallengeComplete {
                challenge_id: Self::parse_uuid(&source_id).unwrap_or(Uuid::new_v4()),
            },
            "LevelUpBonus" => XPSource::LevelUpBonus,
            _ => XPSource::HabitCompletion {
                habit_id: Uuid::new_v4(),
            },
        };
        Ok(XPRecord {
            id: Uuid::parse_str(&row.get::<_, String>(0)?).map_err(|e| DBError::Parse(e.to_string()))?,
            amount: row.get(1)?,
            source,
            date: NaiveDate::parse_from_str(&row.get::<_, String>(4)?, "%Y-%m-%d")
                .map_err(|e| DBError::Parse(e.to_string()))?,
        })
    }

    fn row_to_achievement(row: &Row<'_>) -> DBResult<Achievement> {
        Ok(Achievement {
            id: Uuid::parse_str(&row.get::<_, String>(0)?).map_err(|e| DBError::Parse(e.to_string()))?,
            title: row.get(1)?,
            description: row.get(2)?,
            icon: row.get(3)?,
            xp_reward: row.get(4)?,
            category: Self::parse_achievement_category(row.get::<_, String>(5)?),
            unlocked: row.get::<_, i32>(6)? == 1,
            unlocked_at: Self::parse_date(&row.get::<_, Option<String>>(7)?),
            level_requirement: row.get(8)?,
        })
    }

    fn row_to_challenge(row: &Row<'_>) -> DBResult<Challenge> {
        Ok(Challenge {
            id: Uuid::parse_str(&row.get::<_, String>(0)?).map_err(|e| DBError::Parse(e.to_string()))?,
            title: row.get(1)?,
            description: row.get(2)?,
            challenge_type: Self::parse_challenge_type(row.get::<_, String>(3)?),
            status: Self::parse_challenge_status(row.get::<_, String>(4)?),
            progress: row.get(5)?,
            target: row.get(6)?,
            xp_reward: row.get(7)?,
            expires_at: Self::parse_date(&row.get::<_, Option<String>>(8)?),
            completed_at: Self::parse_date(&row.get::<_, Option<String>>(9)?),
        })
    }

    // ─── Parsing helpers ──────────────────────────────────────────────

    fn parse_difficulty(s: String) -> Difficulty {
        match s.as_str() {
            "Easy" => Difficulty::Easy,
            "Medium" => Difficulty::Medium,
            "Hard" => Difficulty::Hard,
            "Extreme" => Difficulty::Extreme,
            _ => Difficulty::Easy,
        }
    }

    fn parse_frequency(s: String) -> Frequency {
        match s.as_str() {
            "Daily" => Frequency::Daily,
            "Weekly" => Frequency::Weekly,
            "Once" => Frequency::Once,
            _ => Frequency::Daily,
        }
    }

    fn parse_habit_status(s: String) -> HabitStatus {
        match s.as_str() {
            "Active" => HabitStatus::Active,
            "Archived" => HabitStatus::Archived,
            "Completed" => HabitStatus::Completed,
            _ => HabitStatus::Active,
        }
    }

    fn parse_achievement_category(s: String) -> AchievementCategory {
        match s.as_str() {
            "Beginner" => AchievementCategory::Beginner,
            "Intermediate" => AchievementCategory::Intermediate,
            "Advanced" => AchievementCategory::Advanced,
            "Legendary" => AchievementCategory::Legendary,
            "Social" => AchievementCategory::Social,
            "Special" => AchievementCategory::Special,
            _ => AchievementCategory::Beginner,
        }
    }

    fn parse_challenge_type(s: String) -> ChallengeType {
        match s.as_str() {
            "Streak" => ChallengeType::Streak(1),
            "Total" => ChallengeType::Total(1),
            "LongStreak" => ChallengeType::LongStreak(1),
            "CategoryBurst" => ChallengeType::CategoryBurst("all".into()),
            _ => ChallengeType::Total(1),
        }
    }

    fn parse_challenge_status(s: String) -> ChallengeStatus {
        match s.as_str() {
            "Active" => ChallengeStatus::Active,
            "Completed" => ChallengeStatus::Completed,
            "Failed" => ChallengeStatus::Failed,
            _ => ChallengeStatus::Active,
        }
    }

    fn parse_uuid(s: &Option<String>) -> Option<Uuid> {
        s.as_ref().and_then(|s| Uuid::parse_str(s).ok())
    }

    fn parse_date(s: &Option<String>) -> Option<NaiveDate> {
        s.as_ref().and_then(|s| NaiveDate::parse_from_str(s, "%Y-%m-%d").ok())
    }
}

// ─── Tests ────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    fn test_db() -> Database {
        Database::open_memory().unwrap()
    }

    #[test]
    fn test_create_and_get_habit() {
        let mut db = test_db();
        let habit = Habit::new(
            "Meditate",
            "Mindfulness",
            Difficulty::Easy,
            Frequency::Daily,
        );
        db.create_habit(&habit).unwrap();
        let retrieved = db.get_habit(&habit.id).unwrap().unwrap();
        assert_eq!(retrieved.name, "Meditate");
        assert_eq!(retrieved.category, "Mindfulness");
        assert_eq!(retrieved.xp_reward, 10);
    }

    #[test]
    fn test_list_habits() {
        let mut db = test_db();
        let h1 = Habit::new(
            "Meditate",
            "Mindfulness",
            Difficulty::Easy,
            Frequency::Daily,
        );
        let h2 = Habit::new("Run", "Fitness", Difficulty::Hard, Frequency::Daily);
        db.create_habit(&h1).unwrap();
        db.create_habit(&h2).unwrap();
        let habits = db.list_habits(None).unwrap();
        assert_eq!(habits.len(), 2);
    }

    #[test]
    fn test_complete_habit() {
        let mut db = test_db();
        let habit = Habit::new(
            "Meditate",
            "Mindfulness",
            Difficulty::Medium,
            Frequency::Daily,
        );
        db.create_habit(&habit).unwrap();
        let today = chrono::Utc::now().date_naive();
        let xp = db.complete_habit(&habit.id, today).unwrap();
        assert_eq!(xp, 25);
        let updated = db.get_habit(&habit.id).unwrap().unwrap();
        assert_eq!(updated.current_streak, 1);
        assert_eq!(updated.total_completions, 1);
    }

    #[test]
    fn test_add_xp_and_progression() {
        let mut db = test_db();
        let level = db.add_xp(250).unwrap();
        assert_eq!(level, 2);
        let prog = db.get_progression().unwrap();
        assert_eq!(prog.total_xp, 250);
        assert_eq!(prog.level, 2);
    }

    #[test]
    fn test_record_and_list_xp() {
        let mut db = test_db();
        let today = chrono::Utc::now().date_naive();
        let habit_id = Uuid::new_v4().to_string();
        db.record_xp(25, "HabitCompletion", Some(&habit_id), today)
            .unwrap();
        db.record_xp(10, "HabitCompletion", Some("other"), today)
            .unwrap();
        let records = db.list_xp_records(10).unwrap();
        assert_eq!(records.len(), 2);
    }

    #[test]
    fn test_save_and_list_achievements() {
        let mut db = test_db();
        let mut ach = Achievement::new(
            "First Steps",
            "Complete your first habit",
            25,
            AchievementCategory::Beginner,
        );
        ach.unlock(chrono::Utc::now().date_naive());
        db.save_achievements(&[ach]).unwrap();
        let achievements = db.list_achievements().unwrap();
        assert_eq!(achievements.len(), 1);
        assert!(achievements[0].unlocked);
    }

    #[test]
    fn test_save_streak() {
        let mut db = test_db();
        let habit = Habit::new("Meditate", "Mindfulness", Difficulty::Easy, Frequency::Daily);
        db.create_habit(&habit).unwrap();

        let streak = Streak::new(habit.id, chrono::Utc::now().date_naive());
        db.save_streak(&streak).unwrap();
        let streaks = db.get_streaks(&habit.id).unwrap();
        assert_eq!(streaks.len(), 1);
    }

    #[test]
    fn test_delete_habit() {
        let mut db = test_db();
        let habit = Habit::new("To Delete", "Test", Difficulty::Easy, Frequency::Once);
        db.create_habit(&habit).unwrap();
        db.delete_habit(&habit.id).unwrap();
        let retrieved = db.get_habit(&habit.id).unwrap();
        assert!(retrieved.is_none());
    }
}
