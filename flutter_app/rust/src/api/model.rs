use serde::{Deserialize, Serialize};

// ── Enums ─────────────────────────────────────────────────────────────────────

/// How often a habit repeats
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum Frequency {
    Daily,
    Weekly,
    Monthly,
}

/// How hard a habit is to complete
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum Difficulty {
    Easy,
    Medium,
    Hard,
    Extreme,
}

/// Lifecycle state of a habit
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum HabitStatus {
    Active,
    Paused,
    Archived,
}

/// The type of challenge and its target condition
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ChallengeType {
    Streak(u32),
    Completions(u32),
}

/// Current outcome of a challenge
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ChallengeStatus {
    Active,
    Completed,
    Failed,
}

// ── Core structs ──────────────────────────────────────────────────────────────

/// A single trackable habit
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Habit {
    pub id: String,
    pub name: String,
    pub description: String,
    pub category: String,
    pub difficulty: Difficulty,
    pub frequency: Frequency,
    pub status: HabitStatus,
    pub xp_reward: u32,
    pub streak_count: u32,
    /// ISO date string "YYYY-MM-DD" or None if never completed
    pub last_completed: Option<String>,
    pub created_at: String,
}

/// The player's overall level and XP progress
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlayerProgression {
    pub total_xp: u32,
    pub level: u32,
    pub xp_to_next: u32,
}

/// A milestone achievement that can be unlocked
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Achievement {
    pub id: String,
    pub title: String,
    pub description: String,
    pub icon: String,
    pub xp_reward: u32,
    pub unlocked: bool,
}

/// A running streak for a specific habit
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Streak {
    pub habit_id: String,
    pub count: u32,
    pub is_active: bool,
}

/// A challenge with a specific goal (streak- or completion-based)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Challenge {
    pub id: String,
    pub title: String,
    pub description: String,
    pub challenge_type: ChallengeType,
    pub xp_reward: u32,
    pub progress: u32,
    pub target: u32,
    pub status: ChallengeStatus,
}

/// A player stat tracked with its own XP sub-system
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlayerStat {
    pub id: String,
    pub name: String,
    pub value: i32,
    pub level: u32,
    pub xp_in_stat: u32,
    pub xp_to_next: u32,
    pub icon: String,
    pub color: String,
    /// JSON string mapping categories to this stat, e.g. `["fitness", "mindfulness"]`
    pub category_mappings: String,
}

/// Result returned after completing a habit
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CompletionResult {
    pub xp_awarded: u32,
    pub bonus_xp: u32,
    pub total_xp: u32,
    pub streak: u32,
    pub levelled_up: bool,
    pub new_achievements: Vec<Achievement>,
}
