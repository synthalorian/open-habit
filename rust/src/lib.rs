//! open_habit — Retro-synthwave habit tracker with gamification.
//!
//! XP, streaks, achievements, procedural challenges.
//! Level up your life. Neon all the way.

#![forbid(unsafe_code)]
#![warn(clippy::all, clippy::pedantic)]
#![allow(clippy::doc_missing_intra_doc_links)]

pub mod gamification;
pub procedural;
pub mod rules;
pub mod db;
pub mod server;

pub use gamification::*;
pub use procedural::*;
pub use rules::*;
pub use db::*;
pub use server::*;

/// Application version.
pub const VERSION: &str = env!("CARGO_PKG_VERSION");

/// Application name.
pub const APP_NAME: &str = "open_habit";

/// Starting XP for a new user.
pub const STARTING_XP: u32 = 0;

/// XP per habit completion (base rate).
pub const XP_PER_COMPLETION: u32 = 50;

/// Streak bonus multiplier per day.
pub const STREAK_BONUS_MULTIPLIER: f32 = 0.1;

/// Default level threshold progression.
pub const XP_LEVEL_MULTIPLIER: f32 = 1.5;

#[cfg(test)]
mod tests {
    #[test]
    fn test_version() {
        assert!(!VERSION.is_empty());
    }

    #[test]
    fn test_constants() {
        assert_eq!(STARTING_XP, 0);
        assert_eq!(XP_PER_COMPLETION, 50);
        assert!((STREAK_BONUS_MULTIPLIER - 0.1).abs() < 0.001);
    }
}
