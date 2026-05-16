//! Procedural content generation for challenges and events.
//!
//! Seeded PRNG for deterministic daily content.

pub mod rng;
pub mod generator;
// pub mod events; // TODO: implement random events
// pub mod quests; // TODO: implement quest chains

/// The procedural engine that generates daily challenges and random events.
#[derive(Debug, Clone, Default)]
pub struct Engine {
    // Could hold state like current day's seed, but we'll generate on demand.
}

impl Engine {
    pub fn new() -> Self {
        Self::default()
    }

    /// Generate daily challenges for the given date and player state.
    /// Deterministic: same date + user_id yields same challenges.
    pub fn generate_daily(
        &self,
        date: chrono::NaiveDate,
        level: u32,
        total_habits: u32,
        best_streaks: &[u32],
        user_id: Option<uuid::Uuid>,
    ) -> Vec<open_habit_shared::Challenge> {
        let mut rng = rng::SeededRng::from_date(date, user_id);
        generator::generate_daily(&mut rng, level, total_habits, best_streaks)
    }

    /// Check for random events that should trigger based on player state.
    /// Returns list of events that are active.
    #[allow(dead_code)]
    pub fn check_events(&self) -> Vec<open_habit_shared::Challenge> {
        // Placeholder for now
        vec![]
    }
}
