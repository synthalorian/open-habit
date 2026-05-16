mod frb_generated; /* AUTO INJECTED BY flutter_rust_bridge. This line may not be accurate, and you can change it according to your needs. */
mod api;

/// Re-export the bridge API for flutter_rust_bridge codegen
pub use api::database::Database;
pub use api::model::{
    Achievement, Challenge, ChallengeStatus, ChallengeType, CompletionResult, Difficulty,
    Frequency, Habit, HabitStatus, PlayerProgression, PlayerStat, Streak,
};
