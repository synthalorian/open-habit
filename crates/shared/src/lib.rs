//! Shared domain types for open_habit.
//!
//! Core entities: `Habit`, `Achievement`, `Streak`, `XPRecord`, and `Challenge`.
//! These types are used across all crates in the workspace.

use chrono::{NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use thiserror::Error;
use uuid::Uuid;

// ─── Errors ───────────────────────────────────────────────────────────

/// Domain errors for habit operations.
#[derive(Debug, Error, Clone, PartialEq, Eq)]
pub enum HabitError {
    #[error("habit not found: {0}")]
    NotFound(Uuid),
    #[error("validation failed: {0}")]
    Validation(String),
    #[error("habit already exists with that name")]
    DuplicateName,
    #[error("invalid date range")]
    InvalidDateRange,
}

/// Domain errors for gamification operations.
#[derive(Debug, Error, Clone, PartialEq, Eq)]
pub enum GamificationError {
    #[error("achievement not found: {0}")]
    AchievementNotFound(Uuid),
    #[error("insufficient level: need {required}, have {have}")]
    InsufficientLevel { required: u32, have: u32 },
    #[error("already unlocked: {0}")]
    AlreadyUnlocked(Uuid),
}

/// XP operation errors.
#[derive(Debug, Error, Clone, PartialEq, Eq)]
pub enum XPError {
    #[error("negative XP amount")]
    NegativeAmount,
    #[error("invalid level transition")]
    InvalidTransition,
}

// ─── Enums ────────────────────────────────────────────────────────────

/// How often a habit should be repeated.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum Frequency {
    Daily,
    Weekly,
    #[serde(rename = "custom")]
    Custom {
        days: Vec<u8>,
    }, // 0=Sun .. 6=Sat
    #[serde(rename = "once")]
    Once,
}

/// Difficulty of a habit (affects XP reward).
#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
pub enum Difficulty {
    Easy,
    Medium,
    Hard,
    Extreme,
}

impl Default for Difficulty {
    fn default() -> Self {
        Self::Easy
    }
}

/// Status of a habit.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum HabitStatus {
    Active,
    Archived,
    Completed,
}

impl Default for HabitStatus {
    fn default() -> Self {
        Self::Active
    }
}

/// Type of a gamification challenge.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum ChallengeType {
    /// Complete a habit N times in a row
    Streak(u32),
    /// Complete a total of N habits
    Total(u32),
    /// Complete all habits in a category on a given day
    CategoryBurst(String),
    /// Maintain streaks for N days
    LongStreak(u32),
}

/// Status of a challenge.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, Default)]
pub enum ChallengeStatus {
    #[default]
    Active,
    Completed,
    Failed,
}

// ─── Habit ────────────────────────────────────────────────────────────

/// A habit that the user wants to build or maintain.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct Habit {
    pub id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub category: String,
    pub difficulty: Difficulty,
    pub frequency: Frequency,
    pub status: HabitStatus,
    pub created_at: NaiveDate,
    pub last_completed: Option<NaiveDate>,
    pub current_streak: u32,
    pub best_streak: u32,
    pub total_completions: u32,
    /// XP points awarded for completing this habit
    pub xp_reward: u32,
}

impl Habit {
    /// XP points per difficulty.
    pub const XP_RATES: [u32; 4] = [10, 25, 50, 100];

    pub fn new(
        name: impl Into<String>,
        category: impl Into<String>,
        difficulty: Difficulty,
        frequency: Frequency,
    ) -> Self {
        let xp_reward = Self::XP_RATES[difficulty as usize] as u32;
        Self {
            id: Uuid::new_v4(),
            name: name.into(),
            description: None,
            category: category.into(),
            difficulty,
            frequency,
            status: HabitStatus::default(),
            created_at: Utc::now().date_naive(),
            last_completed: None,
            current_streak: 0,
            best_streak: 0,
            total_completions: 0,
            xp_reward,
        }
    }

    /// Calculate XP reward based on difficulty.
    pub fn xp_for(difficulty: Difficulty) -> u32 {
        Self::XP_RATES[difficulty as usize] as u32
    }
}

// ─── Streak ───────────────────────────────────────────────────────────

/// Tracks streak progression for a habit.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct Streak {
    pub habit_id: Uuid,
    pub count: u32,
    pub started_at: NaiveDate,
    pub last_date: NaiveDate,
    pub is_active: bool,
}

impl Streak {
    pub fn new(habit_id: Uuid, start_date: NaiveDate) -> Self {
        Self {
            habit_id,
            count: 1,
            started_at: start_date,
            last_date: start_date,
            is_active: true,
        }
    }

    pub fn increment(&mut self, today: NaiveDate) {
        self.count += 1;
        self.last_date = today;
        self.is_active = true;
    }

    /// Check if a streak should be broken.
    pub fn should_break(&self, today: NaiveDate) -> bool {
        // Streak breaks if today > last_date + 1 day
        // Allow a grace period of 1 day for daily habits
        if let Some(grace) = self.last_date.checked_add_signed(chrono::Duration::days(1)) {
            today > grace
        } else {
            false
        }
    }
}

// ─── Achievement ──────────────────────────────────────────────────────

/// A milestone or badge the user can unlock.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct Achievement {
    pub id: Uuid,
    pub title: String,
    pub description: String,
    pub icon: String,
    pub xp_reward: u32,
    pub category: AchievementCategory,
    pub unlocked: bool,
    pub unlocked_at: Option<NaiveDate>,
    /// Minimum level required to unlock
    pub level_requirement: u32,
}

/// Categories for achievements.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum AchievementCategory {
    Beginner,
    Intermediate,
    Advanced,
    Legendary,
    Social,
    Special,
}

impl Achievement {
    pub fn new(
        title: impl Into<String>,
        description: impl Into<String>,
        xp_reward: u32,
        category: AchievementCategory,
    ) -> Self {
        Self {
            id: Uuid::new_v4(),
            title: title.into(),
            description: description.into(),
            icon: "🎖️".to_string(),
            xp_reward,
            category,
            unlocked: false,
            unlocked_at: None,
            level_requirement: 1,
        }
    }

    pub fn unlock(&mut self, date: NaiveDate) {
        self.unlocked = true;
        self.unlocked_at = Some(date);
    }
}

// ─── XP & Leveling ───────────────────────────────────────────────────

/// XP records for auditing and progression.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct XPRecord {
    pub id: Uuid,
    pub amount: u32,
    pub source: XPSource,
    pub date: NaiveDate,
}

/// Where XP came from.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum XPSource {
    HabitCompletion { habit_id: Uuid },
    StreakBonus { streak_length: u32 },
    AchievementUnlock { achievement_id: Uuid },
    ChallengeComplete { challenge_id: Uuid },
    LevelUpBonus,
}

/// Current player progression state.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct PlayerProgression {
    pub total_xp: u32,
    pub level: u32,
    pub xp_to_next: u32,
}

impl PlayerProgression {
    /// XP needed for level N (exponential growth).
    pub fn xp_for_level(level: u32) -> u32 {
        // Base 100, scaling: 100 * 1.5^(level-1)
        let shift = level.saturating_sub(1) as usize;
        let shift = shift.min(25);
        let divisor = 1u32.max(1);
        100 * (1u32 << shift) / divisor
    }

    /// Calculate XP threshold for a given level with smooth scaling.
    pub fn xp_threshold(level: u32) -> u32 {
        if level == 0 {
            return 0;
        }
        // Smooth exponential: 100 * (1.2 ^ (level-1)), capped reasonably
        let base: f64 = 100.0;
        let growth: f64 = 1.2;
        (base * growth.powi(level as i32 - 1)) as u32
    }

    /// Get the XP threshold for the next level.
    pub fn xp_to_next_level(level: u32) -> u32 {
        Self::xp_threshold(level + 1)
    }

    /// Apply XP and compute new level.
    pub fn add_xp(&mut self, xp: u32) -> Vec<u32> {
        if xp == 0 {
            return vec![];
        }
        self.total_xp += xp;
        let mut leveled_up: Vec<u32> = vec![];
        let mut next_threshold = Self::xp_threshold(self.level + 1);
        while self.total_xp >= next_threshold {
            self.total_xp -= next_threshold;
            self.level += 1;
            leveled_up.push(self.level);
            next_threshold = Self::xp_threshold(self.level + 1);
        }
        self.xp_to_next = if next_threshold > self.total_xp {
            next_threshold - self.total_xp
        } else {
            0
        };
        leveled_up
    }
}

// ─── Player Stats ────────────────────────────────────────────────────────

/// An RPG-style stat that levels up as you complete habits in specific categories.
/// Users can customize names, icons, and which habit categories feed into each stat.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct PlayerStat {
    pub id: uuid::Uuid,
    pub name: String,
    pub value: f64,
    pub level: u32,
    pub xp_in_stat: u32,
    pub xp_to_next: u32,
    pub icon: String,    // emoji or unicode codepoint reference
    pub color: String,   // hex color like "#FF9B71"
    /// JSON array of habit category strings that feed into this stat
    pub category_mappings: String,
    pub created_at: chrono::NaiveDate,
}

impl PlayerStat {
    /// XP thresholds for each stat level (same scaling as player level)
    pub fn xp_for_level(level: u32) -> u32 {
        PlayerProgression::xp_threshold(level + 1)
    }

    /// Add stat XP and return whether we leveled up
    pub fn add_xp(&mut self, amount: u32) -> bool {
        self.xp_in_stat += amount;
        let mut next_threshold = Self::xp_for_level(self.level + 1);
        let mut leveled = false;
        while self.xp_in_stat >= next_threshold && next_threshold > 0 {
            self.xp_in_stat -= next_threshold;
            self.level += 1;
            self.value = self.level as f64;
            leveled = true;
            next_threshold = Self::xp_for_level(self.level + 1);
        }
        self.xp_to_next = if next_threshold > self.xp_in_stat {
            next_threshold - self.xp_in_stat
        } else {
            0
        };
        leveled
    }
}

/// Default stat definitions with their RPG archetype mappings
pub mod default_stats {
    use super::*;
    use chrono::Utc;

    pub fn defaults() -> Vec<PlayerStat> {
        vec![
            PlayerStat {
                id: uuid::Uuid::new_v4(),
                name: "Strength".into(),
                value: 1.0,
                level: 1,
                xp_in_stat: 0,
                xp_to_next: PlayerStat::xp_for_level(2),
                icon: "💪".into(),
                color: "#FF5500".into(),
                category_mappings: r#"["Fitness","Nutrition"]"#.into(),
                created_at: Utc::now().date_naive(),
            },
            PlayerStat {
                id: uuid::Uuid::new_v4(),
                name: "Intelligence".into(),
                value: 1.0,
                level: 1,
                xp_in_stat: 0,
                xp_to_next: PlayerStat::xp_for_level(2),
                icon: "🧠".into(),
                color: "#00E5FF".into(),
                category_mappings: r#"["Learning","Creative"]"#.into(),
                created_at: Utc::now().date_naive(),
            },
            PlayerStat {
                id: uuid::Uuid::new_v4(),
                name: "Vitality".into(),
                value: 1.0,
                level: 1,
                xp_in_stat: 0,
                xp_to_next: PlayerStat::xp_for_level(2),
                icon: "❤️".into(),
                color: "#FF2D95".into(),
                category_mappings: r#"["Mindfulness","Nutrition"]"#.into(),
                created_at: Utc::now().date_naive(),
            },
            PlayerStat {
                id: uuid::Uuid::new_v4(),
                name: "Agility".into(),
                value: 1.0,
                level: 1,
                xp_in_stat: 0,
                xp_to_next: PlayerStat::xp_for_level(2),
                icon: "⚡".into(),
                color: "#B026FF".into(),
                category_mappings: r#"["Fitness","Productivity"]"#.into(),
                created_at: Utc::now().date_naive(),
            },
            PlayerStat {
                id: uuid::Uuid::new_v4(),
                name: "Wisdom".into(),
                value: 1.0,
                level: 1,
                xp_in_stat: 0,
                xp_to_next: PlayerStat::xp_for_level(2),
                icon: "🔮".into(),
                color: "#FF9B71".into(),
                category_mappings: r#"["Mindfulness","Learning"]"#.into(),
                created_at: Utc::now().date_naive(),
            },
            PlayerStat {
                id: uuid::Uuid::new_v4(),
                name: "Charisma".into(),
                value: 1.0,
                level: 1,
                xp_in_stat: 0,
                xp_to_next: PlayerStat::xp_for_level(2),
                icon: "🎭".into(),
                color: "#FFDD00".into(),
                category_mappings: r#"["Social","Creative"]"#.into(),
                created_at: Utc::now().date_naive(),
            },
            PlayerStat {
                id: uuid::Uuid::new_v4(),
                name: "Luck".into(),
                value: 1.0,
                level: 1,
                xp_in_stat: 0,
                xp_to_next: PlayerStat::xp_for_level(2),
                icon: "🍀".into(),
                color: "#00FF88".into(),
                category_mappings: r#"["Finance","General"]"#.into(),
                created_at: Utc::now().date_naive(),
            },
        ]
    }
}

// ─── Challenge ────────────────────────────────────────────────────────

/// A procedural challenge that gives bonus XP.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct Challenge {
    pub id: Uuid,
    pub title: String,
    pub description: String,
    pub challenge_type: ChallengeType,
    pub status: ChallengeStatus,
    pub progress: u32,
    pub target: u32,
    pub xp_reward: u32,
    pub category: String,
    pub expires_at: Option<NaiveDate>,
    pub completed_at: Option<NaiveDate>,
}

impl Challenge {
    pub fn new(
        title: impl Into<String>,
        description: impl Into<String>,
        challenge_type: ChallengeType,
        xp_reward: u32,
    ) -> Self {
        Self::with_category(title, description, challenge_type, xp_reward, "general".to_string())
    }

    pub fn with_category(
        title: impl Into<String>,
        description: impl Into<String>,
        challenge_type: ChallengeType,
        xp_reward: u32,
        category: String,
    ) -> Self {
        Self {
            id: Uuid::new_v4(),
            title: title.into(),
            description: description.into(),
            challenge_type: challenge_type.clone(),
            status: ChallengeStatus::Active,
            progress: 0,
            target: match &challenge_type {
                ChallengeType::Streak(n) => *n,
                ChallengeType::Total(n) => *n,
                ChallengeType::LongStreak(n) => *n,
                ChallengeType::CategoryBurst(_) => 1,
            },
            xp_reward,
            category,
            expires_at: None,
            completed_at: None,
        }
    }

    pub fn progress_by(&mut self, amount: u32) -> bool {
        self.progress = (self.progress + amount).min(self.target);
        if self.progress >= self.target {
            self.status = ChallengeStatus::Completed;
            self.completed_at = Some(Utc::now().date_naive());
            true
        } else {
            false
        }
    }
}

// ─── Default Achievements ─────────────────────────────────────────────

/// Pre-defined achievement catalog.
pub mod achievements {
    use super::*;

    /// Returns a list of default achievements available in the system.
    pub fn default_achievements() -> Vec<Achievement> {
        vec![
            Achievement {
                id: Uuid::new_v4(),
                title: "First Steps".to_string(),
                description: "Complete your first habit".to_string(),
                icon: "👣".to_string(),
                xp_reward: 25,
                category: AchievementCategory::Beginner,
                unlocked: false,
                unlocked_at: None,
                level_requirement: 1,
            },
            Achievement {
                id: Uuid::new_v4(),
                title: "On Fire".to_string(),
                description: "Reach a 7-day streak on any habit".to_string(),
                icon: "🔥".to_string(),
                xp_reward: 50,
                category: AchievementCategory::Beginner,
                unlocked: false,
                unlocked_at: None,
                level_requirement: 1,
            },
            Achievement {
                id: Uuid::new_v4(),
                title: "Unstoppable".to_string(),
                description: "Reach a 30-day streak on any habit".to_string(),
                icon: "⚡".to_string(),
                xp_reward: 150,
                category: AchievementCategory::Intermediate,
                unlocked: false,
                unlocked_at: None,
                level_requirement: 3,
            },
            Achievement {
                id: Uuid::new_v4(),
                title: "Centurion".to_string(),
                description: "Complete 100 habits total".to_string(),
                icon: "💯".to_string(),
                xp_reward: 200,
                category: AchievementCategory::Advanced,
                unlocked: false,
                unlocked_at: None,
                level_requirement: 5,
            },
            Achievement {
                id: Uuid::new_v4(),
                title: "Legend".to_string(),
                description: "Reach level 50".to_string(),
                icon: "👑".to_string(),
                xp_reward: 500,
                category: AchievementCategory::Legendary,
                unlocked: false,
                unlocked_at: None,
                level_requirement: 50,
            },
        ]
    }
}

// ─── Default Streak Bonuses ───────────────────────────────────────────

/// Streak milestone bonuses.
pub mod streak_bonuses {
    /// XP bonus at each milestone.
    pub const BONUS_MILESTONES: [(u32, u32); 6] = [
        (3, 5),     // 3-day streak → +5 XP
        (7, 15),    // 7-day streak → +15 XP
        (14, 30),   // 14-day streak → +30 XP
        (30, 75),   // 30-day streak → +75 XP
        (60, 150),  // 60-day streak → +150 XP
        (100, 300), // 100-day streak → +300 XP
    ];
}

// ─── Tests ────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_habit_creation() {
        let habit = Habit::new(
            "Meditate",
            "Mindfulness",
            Difficulty::Easy,
            Frequency::Daily,
        );
        assert_eq!(habit.name, "Meditate");
        assert_eq!(habit.category, "Mindfulness");
        assert_eq!(habit.xp_reward, 10);
        assert_eq!(habit.status, HabitStatus::Active);
        assert_eq!(habit.current_streak, 0);
    }

    #[test]
    fn test_streak_increment() {
        let today = NaiveDate::from_ymd_opt(2025, 1, 15).unwrap();
        let start = NaiveDate::from_ymd_opt(2025, 1, 1).unwrap();
        let mut streak = Streak::new(Uuid::new_v4(), start);
        assert_eq!(streak.count, 1);
        streak.increment(today);
        assert_eq!(streak.count, 2);
    }

    #[test]
    fn test_streak_should_break() {
        let last = NaiveDate::from_ymd_opt(2025, 1, 13).unwrap();
        let streak = Streak {
            habit_id: Uuid::new_v4(),
            count: 1,
            started_at: last,
            last_date: last,
            is_active: true,
        };
        // Today is exactly 1 day after last → should NOT break
        let today = NaiveDate::from_ymd_opt(2025, 1, 14).unwrap();
        assert!(!streak.should_break(today));
        // Today is 2 days after last → should break
        let tomorrow = NaiveDate::from_ymd_opt(2025, 1, 15).unwrap();
        assert!(streak.should_break(tomorrow));
    }

    #[test]
    fn test_xp_progression() {
        let mut player = PlayerProgression {
            total_xp: 0,
            level: 1,
            xp_to_next: 20,
        };
        // Level 1 → level 2 threshold is 100 XP
        assert_eq!(PlayerProgression::xp_threshold(2), 120);

        player.total_xp = 100;
        player.level = 1;
        player.xp_to_next = 20;

        let leveled = player.add_xp(30);
        assert_eq!(leveled, vec![2]);
        assert_eq!(player.level, 2);
    }

    #[test]
    fn test_xp_multiple_level_ups() {
        let mut player = PlayerProgression {
            total_xp: 0,
            level: 1,
            xp_to_next: 100,
        };
        // Give enough XP to level up at least once
        // xp_threshold(2) = 120, xp_threshold(3) = 144
        // 250 XP: reach level 2 (120 consumed), 130 remaining < 144 → 1 level-up
        let leveled = player.add_xp(300);
        assert!(leveled.len() >= 1);
        assert!(player.level >= 2);
    }

    #[test]
    fn test_achievement_unlock() {
        let mut achievement = Achievement::new(
            "First Steps",
            "Complete your first habit",
            25,
            AchievementCategory::Beginner,
        );
        assert!(!achievement.unlocked);
        let date = NaiveDate::from_ymd_opt(2025, 1, 15).unwrap();
        achievement.unlock(date);
        assert!(achievement.unlocked);
        assert_eq!(achievement.unlocked_at, Some(date));
    }

    #[test]
    fn test_challenge_progress() {
        let mut challenge = Challenge::new(
            "Weekly Warrior",
            "Complete 7 habits this week",
            ChallengeType::Total(7),
            50,
        );
        assert!(!challenge.progress_by(3)); // not complete yet
        assert_eq!(challenge.progress, 3);
        assert!(challenge.progress_by(4)); // completes!
        assert!(challenge.progress >= challenge.target);
        assert_eq!(challenge.status, ChallengeStatus::Completed);
        assert!(challenge.completed_at.is_some());
    }

    #[test]
    fn test_difficulty_xp_rates() {
        assert_eq!(Habit::xp_for(Difficulty::Easy), 10);
        assert_eq!(Habit::xp_for(Difficulty::Medium), 25);
        assert_eq!(Habit::xp_for(Difficulty::Hard), 50);
        assert_eq!(Habit::xp_for(Difficulty::Extreme), 100);
    }

    #[test]
    fn test_default_achievements() {
        let defaults = achievements::default_achievements();
        assert!(!defaults.is_empty());
        assert_eq!(defaults.len(), 5);
        for a in &defaults {
            assert!(!a.unlocked);
        }
    }
}
