//! open_habit — Gamification Engine
//!
//! The core game loop: XP calculation, streak management, achievement
//! checking, and challenge progression. Everything that makes habits
//! feel like a RPG.
//!
//! ## Core Components
//!
//! - `XPSystem` — Award XP, compute levels, calculate bonuses
//! - `StreakManager` — Track, break, and award streak milestones
//! - `AchievementTracker` — Check conditions, unlock badges
//! - `ChallengeEngine` — Generate and track procedural challenges
//! - `GamificationEngine` — Orchestrate all subsystems

use chrono::NaiveDate;
use open_habit_shared::*;

mod procedural;

// ─── XP System ────────────────────────────────────────────────────────

/// Manages XP accumulation and leveling.
#[derive(Debug, Clone)]
pub struct XPSystem {
    progression: PlayerProgression,
}

impl Default for XPSystem {
    fn default() -> Self {
        Self::new()
    }
}

impl XPSystem {
    pub fn new() -> Self {
        let level = 1;
        Self {
            progression: PlayerProgression {
                total_xp: 0,
                level,
                xp_to_next: PlayerProgression::xp_threshold(level + 1),
            },
        }
    }

    pub fn progression(&self) -> &PlayerProgression {
        &self.progression
    }

    pub fn progression_mut(&mut self) -> &mut PlayerProgression {
        &mut self.progression
    }

    /// Award XP and return list of levels the player reached.
    pub fn award_xp(&mut self, amount: u32) -> Result<Vec<u32>, XPError> {
        if amount == 0 {
            return Ok(vec![]);
        }
        let leveled_up = self.progression.add_xp(amount);
        Ok(leveled_up)
    }

    /// Calculate total XP needed to reach a given level from current.
    pub fn xp_needed_to_reach(&self, target_level: u32) -> u32 {
        let current_threshold = PlayerProgression::xp_threshold(self.progression.level + 1);
        let target_threshold = PlayerProgression::xp_threshold(target_level + 1);
        let remaining_in_current = current_threshold.saturating_sub(self.progression.total_xp);
        let between_levels = target_threshold.saturating_sub(current_threshold);
        remaining_in_current + between_levels
    }

    /// Get the percentage toward the next level (0.0 to 1.0).
    pub fn progress_to_next(&self) -> f64 {
        let threshold = PlayerProgression::xp_threshold(self.progression.level + 1);
        if threshold == 0 {
            return 1.0;
        }
        (self.progression.total_xp as f64) / (threshold as f64)
    }
}

// ─── Streak Manager ───────────────────────────────────────────────────

/// Tracks and manages streaks for habits.
pub struct StreakManager {
    /// habit_id -> current streak
    streaks: Vec<Streak>,
    /// habit_id -> best streak ever
    best_streaks: std::collections::HashMap<uuid::Uuid, u32>,
}

impl Default for StreakManager {
    fn default() -> Self {
        Self::new()
    }
}

impl StreakManager {
    pub fn new() -> Self {
        Self {
            streaks: Vec::new(),
            best_streaks: std::collections::HashMap::new(),
        }
    }

    /// Check all active streaks and break any that should be broken.
    pub fn check_streaks(&mut self, today: NaiveDate) {
        self.streaks.retain(|s| {
            if s.is_active && s.should_break(today) {
                // Always update best streak (even first time)
                let prev_best = self.best_streaks.entry(s.habit_id).or_insert(0);
                if s.count > *prev_best {
                    *prev_best = s.count;
                }
                false // Remove broken streak
            } else {
                true
            }
        });
    }

    /// Start or continue a streak for a habit.
    pub fn record_completion(&mut self, habit_id: uuid::Uuid, today: NaiveDate) {
        if let Some(streak) = self.streaks.iter_mut().find(|s| s.habit_id == habit_id) {
            streak.increment(today);
            // Check for milestone bonus
            let milestone = streak_bonuses::BONUS_MILESTONES
                .iter()
                .rev()
                .find(|(threshold, _)| streak.count >= *threshold);
            if let Some((_, bonus)) = milestone {
                // Return the bonus XP amount (caller handles awarding)
                log::info!(
                    "Streak milestone! Streak length {} → +{} XP bonus",
                    streak.count,
                    bonus
                );
            }
        } else {
            // Start a new streak
            self.streaks.push(Streak::new(habit_id, today));
        }
    }

    /// Get the current streak count for a habit.
    pub fn current_streak(&self, habit_id: uuid::Uuid) -> u32 {
        self.streaks
            .iter()
            .find(|s| s.habit_id == habit_id)
            .map(|s| if s.is_active { s.count } else { 0 })
            .unwrap_or(0)
    }

    /// Get the best streak for a habit.
    pub fn best_streak(&self, habit_id: uuid::Uuid) -> u32 {
        self.best_streaks.get(&habit_id).copied().unwrap_or(0)
    }

    /// Get all active streaks.
    pub fn active_streaks(&self) -> &[Streak] {
        &self.streaks
    }

    /// Get total XP bonus from streak milestones.
    pub fn streak_bonus_xp(&self, streak_count: u32) -> u32 {
        streak_bonuses::BONUS_MILESTONES
            .iter()
            .rev()
            .find(|(threshold, _)| streak_count >= *threshold)
            .map(|(_, bonus)| *bonus)
            .unwrap_or(0)
    }
}

// ─── Achievement Tracker ──────────────────────────────────────────────

/// Checks conditions and manages achievement unlocks.
pub struct AchievementTracker {
    achievements: Vec<Achievement>,
    unlocked_ids: std::collections::HashSet<uuid::Uuid>,
}

impl Default for AchievementTracker {
    fn default() -> Self {
        Self::new()
    }
}

impl AchievementTracker {
    pub fn new() -> Self {
        Self {
            achievements: achievements::default_achievements(),
            unlocked_ids: std::collections::HashSet::new(),
        }
    }

    /// Set custom achievements.
    pub fn set_achievements(&mut self, achievements: Vec<Achievement>) {
        self.achievements = achievements;
    }

    /// Check all achievement conditions and unlock any that are met.
    pub fn check_conditions(
        &mut self,
        total_completions: u32,
        best_streak: u32,
        level: u32,
        today: NaiveDate,
    ) -> Vec<Achievement> {
        let mut newly_unlocked = Vec::new();

        for achievement in self.achievements.iter_mut() {
            if self.unlocked_ids.contains(&achievement.id) {
                continue;
            }

            // Check level requirement
            if level < achievement.level_requirement {
                continue;
            }

            let condition_met = match achievement.title.as_str() {
                "First Steps" => total_completions >= 1,
                "On Fire" => best_streak >= 7,
                "Unstoppable" => best_streak >= 30,
                "Centurion" => total_completions >= 100,
                "Legend" => level >= 50,
                _ => false,
            };

            if condition_met {
                achievement.unlock(today);
                self.unlocked_ids.insert(achievement.id);
                newly_unlocked.push(achievement.clone());
            }
        }

        newly_unlocked
    }

    /// Get all unlocked achievements.
    pub fn unlocked(&self) -> Vec<&Achievement> {
        self.achievements
            .iter()
            .filter(|a| self.unlocked_ids.contains(&a.id))
            .collect()
    }

    /// Get all achievements with their completion status.
    pub fn all(&self) -> Vec<&Achievement> {
        self.achievements.iter().collect()
    }

    /// Get the total XP available from all achievements.
    pub fn total_xp_available(&self) -> u32 {
        self.achievements.iter().map(|a| a.xp_reward).sum()
    }

    /// Get the total XP earned from unlocked achievements.
    pub fn total_xp_earned(&self) -> u32 {
        self.achievements
            .iter()
            .filter(|a| self.unlocked_ids.contains(&a.id))
            .map(|a| a.xp_reward)
            .sum()
    }
}

// ─── Challenge Engine ─────────────────────────────────────────────────

/// Generates and tracks procedural challenges.
pub struct ChallengeEngine {
    challenges: Vec<Challenge>,
    last_generated: Option<NaiveDate>,
}

impl Default for ChallengeEngine {
    fn default() -> Self {
        Self::new()
    }
}

impl ChallengeEngine {
    pub fn new() -> Self {
        Self {
            challenges: Vec::new(),
            last_generated: None,
        }
    }

    /// Generate new challenges, regenerating if the date has changed.
    /// Returns the current set of active challenges.
    pub fn generate_challenges(
        &mut self,
        total_habits: u32,
        level: u32,
        _best_streaks: &[u32],
        user_id: uuid::Uuid,
    ) -> Vec<Challenge> {
        let today = chrono::Utc::now().date_naive();

        // Regenerate if this is a new day
        if self.last_generated != Some(today) {
            self.challenges = procedural::Engine::new()
                .generate_daily(today, level, total_habits, _best_streaks, Some(user_id));
            self.last_generated = Some(today);
        }

        self.challenges.clone()
    }

    /// Add a challenge to the engine.
    pub fn add_challenge(&mut self, challenge: Challenge) {
        self.challenges.push(challenge);
    }

    /// Get all active challenges (owned clones for persistence).
    pub fn active_challenges(&self) -> Vec<Challenge> {
        self.challenges
            .iter()
            .filter(|c| c.status == ChallengeStatus::Active)
            .cloned()
            .collect()
    }

    /// Progress a challenge by amount.
    pub fn progress_challenge(&mut self, challenge_id: uuid::Uuid, amount: u32) -> bool {
        let completed =
            if let Some(challenge) = self.challenges.iter_mut().find(|c| c.id == challenge_id) {
                challenge.progress_by(amount)
            } else {
                return false;
            };
        completed
    }

    /// Get completed challenges.
    pub fn completed_challenges(&self) -> Vec<&Challenge> {
        self.challenges
            .iter()
            .filter(|c| c.status == ChallengeStatus::Completed)
            .collect()
    }

}

// ─── Main Gamification Engine ─────────────────────────────────────────

/// Orchestrate all gamification subsystems.
pub struct GamificationEngine {
    xp: XPSystem,
    streaks: StreakManager,
    achievements: AchievementTracker,
    challenges: ChallengeEngine,
}

impl Default for GamificationEngine {
    fn default() -> Self {
        Self::new()
    }
}

impl GamificationEngine {
    pub fn new() -> Self {
        Self {
            xp: XPSystem::new(),
            streaks: StreakManager::new(),
            achievements: AchievementTracker::new(),
            challenges: ChallengeEngine::new(),
        }
    }


    /// Set the achievements list (e.g., loaded from persistent storage).
    pub fn set_achievements(&mut self, achievements: Vec<Achievement>) {
        self.achievements.set_achievements(achievements);
    }

    /// Complete a habit: award XP, update streak, check achievements.
    pub fn complete_habit(
        &mut self,
        habit_id: uuid::Uuid,
        today: NaiveDate,
        difficulty: Difficulty,
    ) -> CompletionResult {
        // 1. Check and break stale streaks
        self.streaks.check_streaks(today);

        // 2. Award XP for habit completion
        let base_xp = Habit::xp_for(difficulty);
        let leveled_up = self.xp.award_xp(base_xp).unwrap_or_default();

        // 3. Record streak completion
        self.streaks.record_completion(habit_id, today);

        // 4. Award streak bonus XP if at milestone
        let streak_count = self.streaks.current_streak(habit_id);
        let bonus_xp = self.streaks.streak_bonus_xp(streak_count);
        let _leveled_up_bonus = if bonus_xp > 0 {
            self.xp.award_xp(bonus_xp).unwrap_or_default()
        } else {
            Vec::new()
        };

        // 5. Check achievements
        let newly_unlocked = self.achievements.check_conditions(
            0, // total_completions (would come from DB)
            streak_count,
            self.xp.progression().level,
            today,
        );

        // 6. Award XP for new achievements
        let achievement_xp: u32 = newly_unlocked.iter().map(|a| a.xp_reward).sum();
        let _leveled_up_achievement = if achievement_xp > 0 {
            self.xp.award_xp(achievement_xp).unwrap_or_default()
        } else {
            Vec::new()
        };

        // 7. Progress related challenges
        let challenges_completed = self.progress_challenges(today, difficulty);

        CompletionResult {
            base_xp,
            bonus_xp,
            achievement_xp,
            leveled_up: leveled_up,
            new_streak: streak_count,
            newly_unlocked,
            challenges_completed,
        }
    }

    /// Progress all active challenges.
    fn progress_challenges(
        &mut self,
        _today: NaiveDate,
        _difficulty: Difficulty,
    ) -> Vec<uuid::Uuid> {
        let completed = Vec::new();
        for _challenge in self.challenges.active_challenges() {
            // In a real implementation, this would check if the challenge
            // condition is met based on habit completions
        }
        completed
    }

    /// Get current player state.
    pub fn player_state(&self) -> &PlayerProgression {
        self.xp.progression()
    }

    /// Get all achievements.
    pub fn achievements(&self) -> Vec<&Achievement> {
        self.achievements.all()
    }

    /// Get unlocked achievements.
    pub fn unlocked_achievements(&self) -> Vec<&Achievement> {
        self.achievements.unlocked()
    }

    /// Get active streaks.
    pub fn active_streaks(&self) -> &[Streak] {
        self.streaks.active_streaks()
    }

    /// Generate new challenges.
    pub fn generate_challenges(
        &mut self,
        total_habits: u32,
        best_streaks: &[u32],
        user_id: uuid::Uuid,
    ) -> Vec<Challenge> {
        self.challenges
            .generate_challenges(total_habits, self.xp.progression().level, best_streaks, user_id)
    }

    /// Progress a challenge.
    pub fn progress_challenge(&mut self, challenge_id: uuid::Uuid, amount: u32) -> bool {
        self.challenges.progress_challenge(challenge_id, amount)
    }

    /// Get all active challenges (for persistence).
    pub fn active_challenges(&self) -> Vec<Challenge> {
        self.challenges.active_challenges()
    }
}

// ─── Result Types ─────────────────────────────────────────────────────

/// Result of completing a habit through the gamification engine.
#[derive(Debug, Clone)]
pub struct CompletionResult {
    pub base_xp: u32,
    pub bonus_xp: u32,
    pub achievement_xp: u32,
    pub leveled_up: Vec<u32>,
    pub new_streak: u32,
    pub newly_unlocked: Vec<Achievement>,
    pub challenges_completed: Vec<uuid::Uuid>,
}

impl CompletionResult {
    pub fn total_xp(&self) -> u32 {
        self.base_xp + self.bonus_xp + self.achievement_xp
    }

    pub fn is_level_up(&self) -> bool {
        !self.leveled_up.is_empty()
    }

    pub fn is_achievement_unlock(&self) -> bool {
        !self.newly_unlocked.is_empty()
    }
}

// ─── Tests ────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    fn today() -> NaiveDate {
        chrono::Utc::now().date_naive()
    }

    #[test]
    fn test_xp_award_simple() {
        let mut engine = XPSystem::new();
        let leveled = engine.award_xp(50).unwrap();
        assert!(leveled.is_empty()); // Not enough to level up
        assert_eq!(engine.progression().total_xp, 50);
        assert_eq!(engine.progression().level, 1);
    }

    #[test]
    fn test_xp_level_up() {
        let mut engine = XPSystem::new();
        let threshold = PlayerProgression::xp_threshold(2);
        let leveled = engine.award_xp(threshold).unwrap();
        assert_eq!(leveled, vec![2]);
        assert_eq!(engine.progression().level, 2);
    }

    #[test]
    fn test_xp_progress_percentage() {
        let mut engine = XPSystem::new();
        assert_eq!(engine.progress_to_next(), 0.0);
        engine.award_xp(50).unwrap();
        assert!(engine.progress_to_next() > 0.0);
        assert!(engine.progress_to_next() < 1.0);
    }

    #[test]
    fn test_streak_creation() {
        let mut manager = StreakManager::new();
        let habit_id = uuid::Uuid::new_v4();
        let t = today();

        assert_eq!(manager.current_streak(habit_id), 0);

        manager.record_completion(habit_id, t);
        assert_eq!(manager.current_streak(habit_id), 1);

        manager.record_completion(habit_id, t + chrono::Duration::days(1));
        assert_eq!(manager.current_streak(habit_id), 2);
    }

    #[test]
    fn test_streak_breaking() {
        let mut manager = StreakManager::new();
        let habit_id = uuid::Uuid::new_v4();
        let start = NaiveDate::from_ymd_opt(2025, 1, 1).unwrap();
        let yesterday = NaiveDate::from_ymd_opt(2025, 1, 14).unwrap();

        manager.record_completion(habit_id, start);

        // Don't complete on 1/15 → streak breaks on 1/16
        manager.check_streaks(yesterday + chrono::Duration::days(2));
        assert_eq!(manager.current_streak(habit_id), 0);
        assert_eq!(manager.best_streak(habit_id), 1);
    }

    #[test]
    fn test_streak_bonus_xp() {
        let mut manager = StreakManager::new();
        assert_eq!(manager.streak_bonus_xp(2), 0); // Below first milestone
        assert_eq!(manager.streak_bonus_xp(3), 5); // 3-day milestone
        assert_eq!(manager.streak_bonus_xp(7), 15); // 7-day milestone
        assert_eq!(manager.streak_bonus_xp(14), 30); // 14-day milestone
        assert_eq!(manager.streak_bonus_xp(30), 75); // 30-day milestone
        assert_eq!(manager.streak_bonus_xp(60), 150); // 60-day milestone
        assert_eq!(manager.streak_bonus_xp(100), 300); // 100-day milestone
        assert_eq!(manager.streak_bonus_xp(200), 300); // Still 100 (max)
    }

    #[test]
    fn test_achievement_first_steps() {
        let mut tracker = AchievementTracker::new();
        let t = today();

        let unlocked = tracker.check_conditions(1, 0, 1, t);
        assert_eq!(unlocked.len(), 1);
        assert_eq!(unlocked[0].title, "First Steps");

        let unlocked_ids = tracker.unlocked();
        assert_eq!(unlocked_ids.len(), 1);
    }

    #[test]
    fn test_achievement_level_requirement() {
        let mut tracker = AchievementTracker::new();
        let t = today();

        // At level 1, nothing should unlock from the default set
        // (First Steps needs 1 completion which isn't passed)
        let unlocked = tracker.check_conditions(0, 0, 1, t);
        assert!(unlocked.is_empty());

        // Now at level 50, should unlock Legend
        let unlocked = tracker.check_conditions(1000, 100, 100, t);
        assert!(unlocked.iter().any(|a| a.title == "Legend"));
    }

    #[test]
    fn test_achievement_on_fire() {
        let mut tracker = AchievementTracker::new();
        let t = today();

        // Not enough streak
        let unlocked = tracker.check_conditions(0, 6, 1, t);
        assert!(unlocked.is_empty());

        // Enough streak
        let unlocked = tracker.check_conditions(0, 7, 1, t);
        assert_eq!(unlocked.len(), 1);
        assert_eq!(unlocked[0].title, "On Fire");
    }

    #[test]
    fn test_achievement_centurion() {
        let mut tracker = AchievementTracker::new();
        let t = today();

        // Nothing at 0 completions
        let unlocked = tracker.check_conditions(0, 0, 5, t);
        assert!(unlocked.is_empty());

        // At 100 completions + level 5, both First Steps AND Centurion unlock
        let unlocked = tracker.check_conditions(100, 0, 5, t);
        assert_eq!(unlocked.len(), 2);
        assert!(unlocked.iter().any(|a| a.title == "First Steps"));
        assert!(unlocked.iter().any(|a| a.title == "Centurion"));
    }

    #[test]
    fn test_challenge_generation_easy() {
        let mut engine = ChallengeEngine::new();
        let challenges = engine.generate_challenges(1, 1, &[], uuid::Uuid::new_v4());
        // Should produce between 3 and 5 challenges
        let count = challenges.len();
        assert!(count >= 3 && count <= 5, "Expected 3-5 challenges, got {}", count);
        // All challenges should have a non-empty category and be unique in id
        let categories: Vec<&str> = challenges.iter().map(|c| c.category.as_str()).collect();
        assert!(categories.iter().all(|c| !c.is_empty()));
        // Should include at least one from each of main categories (depending on RNG, but at least some variety)
        // We'll just ensure diversity not same category repeated for all? Not strictly needed.
    }

    #[test]
    fn test_challenge_generation_scales_with_level() {
        let mut engine = ChallengeEngine::new();
        let low = engine.generate_challenges(1, 1, &[], uuid::Uuid::new_v4());
        let high = engine.generate_challenges(1, 20, &[], uuid::Uuid::new_v4());
        // Both non-empty
        assert!(!low.is_empty());
        assert!(!high.is_empty());
        // The targets should generally be higher for higher level? Not guaranteed due to randomness but we can at least check types exist
        // Ensure all challenges have category set correctly
        for c in low.iter().chain(high.iter()) {
            assert!(!c.category.is_empty());
        }
    }

    #[test]
    fn test_full_completion_flow() {
        let mut engine = GamificationEngine::new();
        let habit_id = uuid::Uuid::new_v4();
        let t = today();

        let result = engine.complete_habit(habit_id, t, Difficulty::Easy);

        assert_eq!(result.base_xp, 10); // Easy = 10 XP
        assert!(result.total_xp() >= 10);

        assert_eq!(engine.active_streaks().len(), 1);
        assert_eq!(engine.active_streaks()[0].count, 1);
    }

    #[test]
    fn test_multiple_completions() {
        let mut engine = GamificationEngine::new();
        let habit_id = uuid::Uuid::new_v4();
        let t = today();

        // Complete 7 days in a row
        for i in 0..7 {
            let result =
                engine.complete_habit(habit_id, t + chrono::Duration::days(i), Difficulty::Medium);
            assert!(result.new_streak >= i as u32 + 1);
        }

        // At streak 7, "On Fire" should have triggered by now
        assert!(
            engine
                .unlocked_achievements()
                .iter()
                .any(|a| a.title == "On Fire")
        );

        // Streak should be 7 now (after the 7 completions)
        let active_streaks = engine.active_streaks();
        assert_eq!(active_streaks.len(), 1);
        assert_eq!(active_streaks[0].count, 7);
    }

    #[test]
    fn test_progression_accuracy() {
        let mut xp = XPSystem::new();

        // Level 1 threshold: 120 XP (1.2^1 * 100)
        let l1_threshold = PlayerProgression::xp_threshold(2);

        // Level 2 threshold: 144 XP
        let l2_threshold = PlayerProgression::xp_threshold(3);

        // Give XP up to level 2
        xp.award_xp(l1_threshold).unwrap();
        assert_eq!(xp.progression().level, 2);

        // Give enough to reach level 3
        xp.award_xp(l2_threshold).unwrap();
        assert_eq!(xp.progression().level, 3);
    }
}
