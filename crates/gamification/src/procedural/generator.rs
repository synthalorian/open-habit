use crate::procedural::rng::SeededRng;
use open_habit_shared::{Challenge, ChallengeType, Difficulty};
use chrono::NaiveDate;


/// Determine number of daily challenges based on player level.
fn generate_count(level: u32) -> usize {
    match level {
        1..=3 => 3,   // starter: 3 challenges
        4..=7 => 4,   // mid: 4 challenges
        _ => 5,       // high level: 5 challenges
    }
}


/// Challenge template with flexible target scaling.
#[derive(Debug, Clone)]
pub struct Template {
    pub title: &'static str,
    pub description: &'static str,
    pub category: &'static str,
    /// Base target before scaling (e.g., 1, 5, 10).
    pub base_target: u32,
    /// How target scales with player level (linear: target = base * multiplier).
    pub level_multiplier: f32,
    /// Minimum target regardless of level.
    pub min_target: u32,
    /// Maximum target cap.
    pub max_target: u32,
    /// Preferred difficulty tag (only for hints, not stored).
    pub _difficulty_hint: Difficulty,
}

/// Collection of challenge templates across categories.
static TEMPLATES: &[Template] = &[
    // ── Physical ───────────────────────────────────────────────────────
    Template {
        title: "Push-up Set",
        description: "Complete a set of push-ups. Form matters more than speed.",
        category: "physical",
        base_target: 10,
        level_multiplier: 1.0,
        min_target: 5,
        max_target: 100,
        _difficulty_hint: Difficulty::Medium,
    },
    Template {
        title: "Cardio Burst",
        description: "Get your heart rate up for 5 minutes straight.",
        category: "physical",
        base_target: 1,
        level_multiplier: 1.0,
        min_target: 1,
        max_target: 1,
        _difficulty_hint: Difficulty::Medium,
    },
    Template {
        title: "Stretch Routine",
        description: "Full-body stretch for at least 10 minutes.",
        category: "physical",
        base_target: 1,
        level_multiplier: 1.0,
        min_target: 1,
        max_target: 1,
        _difficulty_hint: Difficulty::Easy,
    },

    // ── Mental ─────────────────────────────────────────────────────────
    Template {
        title: "Reading Session",
        description: "Read at least 10 pages of any book.",
        category: "mental",
        base_target: 10,
        level_multiplier: 1.0,
        min_target: 5,
        max_target: 50,
        _difficulty_hint: Difficulty::Easy,
    },
    Template {
        title: "Meditation",
        description: "Sit quietly and focus on your breath for 5 minutes.",
        category: "mental",
        base_target: 5,
        level_multiplier: 1.0,
        min_target: 1,
        max_target: 1,
        _difficulty_hint: Difficulty::Easy,
    },
    Template {
        title: "Learn Something New",
        description: "Spend 15 minutes learning a new skill or concept.",
        category: "mental",
        base_target: 15,
        level_multiplier: 1.0,
        min_target: 5,
        max_target: 30,
        _difficulty_hint: Difficulty::Medium,
    },

    // ── Social ──────────────────────────────────────────────────────────
    Template {
        title: "Reconnect",
        description: "Reach out to a friend or family member you haven't spoken to recently.",
        category: "social",
        base_target: 1,
        level_multiplier: 1.0,
        min_target: 1,
        max_target: 1,
        _difficulty_hint: Difficulty::Easy,
    },
    Template {
        title: "Random Act of Kindness",
        description: "Do something kind for someone without expecting anything in return.",
        category: "social",
        base_target: 1,
        level_multiplier: 1.0,
        min_target: 1,
        max_target: 1,
        _difficulty_hint: Difficulty::Easy,
    },

    // ── Creative ────────────────────────────────────────────────────────
    Template {
        title: "Free Write",
        description: "Write freely for 10 minutes — no editing, just flow.",
        category: "creative",
        base_target: 10,
        level_multiplier: 1.0,
        min_target: 5,
        max_target: 30,
        _difficulty_hint: Difficulty::Medium,
    },
    Template {
        title: "Sketch Something",
        description: "Draw anything — a still life, a doodle, a character.",
        category: "creative",
        base_target: 1,
        level_multiplier: 1.0,
        min_target: 1,
        max_target: 3,
        _difficulty_hint: Difficulty::Easy,
    },

    // ── Health ──────────────────────────────────────────────────────────
    Template {
        title: "Hydrate",
        description: "Drink at least 8oz of water.",
        category: "health",
        base_target: 1,
        level_multiplier: 1.0,
        min_target: 1,
        max_target: 3,
        _difficulty_hint: Difficulty::Easy,
    },
    Template {
        title: "Early to Bed",
        description: "Get to bed at a reasonable hour (by 11pm or earlier).",
        category: "health",
        base_target: 1,
        level_multiplier: 1.0,
        min_target: 1,
        max_target: 1,
        _difficulty_hint: Difficulty::Easy,
    },

    // ── Weird ───────────────────────────────────────────────────────────
    Template {
        title: "Digital Detox Hour",
        description: "Spend one hour completely offline — no phones, no screens.",
        category: "weird",
        base_target: 1,
        level_multiplier: 1.0,
        min_target: 1,
        max_target: 1,
        _difficulty_hint: Difficulty::Hard,
    },
    Template {
        title: "Learn a Useless Fact",
        description: "Discover and memorize one completely useless but interesting fact.",
        category: "weird",
        base_target: 1,
        level_multiplier: 1.0,
        min_target: 1,
        max_target: 1,
        _difficulty_hint: Difficulty::Easy,
    },
];

/// Build a challenge from a template using level-based scaling.
pub fn build_challenge_from_template(
    template: &Template,
    rng: &mut SeededRng,
    level: u32,
    date: NaiveDate,
) -> Challenge {
    // Scale target with level: base * multiplier * (1 + level * 0.05)
    let mut scaled = (template.base_target as f32
        * template.level_multiplier
        * (1.0 + level as f32 * 0.05))
        .round() as u32;
    // Add some randomness (±10%)
    let variance = (scaled as f32 * 0.1).round() as i32;
    scaled = (scaled as i32 + rng.gen_range(-variance, variance + 1)).max(template.min_target as i32) as u32;
    scaled = scaled.min(template.max_target);

    let mut challenge = Challenge::with_category(
        template.title,
        template.description,
        ChallengeType::Streak(scaled),
        25, // base XP, could vary by category/difficulty later
        template.category.to_string(),
    );

    // Set expiration to end of day
    challenge.expires_at = Some(date);
    challenge
}

/// Generate a set of daily challenges.
pub fn generate_daily(
    rng: &mut SeededRng,
    level: u32,
    _total_habits: u32,
    _best_streaks: &[u32],
) -> Vec<Challenge> {
    // Pick 3–5 random templates (weighted by category diversity)
    let mut templates = Vec::new();
    let num_challenges = generate_count(level) as u32;

    // Shuffle templates for random sampling
    let mut shuffled: Vec<&Template> = TEMPLATES.iter().collect();
    rng.shuffle(&mut shuffled);

    // Take first N unique categories
    let mut seen = std::collections::HashSet::new();
    for tmpl in shuffled {
        if seen.len() >= num_challenges as usize {
            break;
        }
        if seen.insert(tmpl.category) {
            templates.push(tmpl.clone());
        }
    }

    let date = chrono::Utc::now().date_naive();

    templates
        .into_iter()
        .map(|tmpl| build_challenge_from_template(&tmpl, rng, level, date))
        .collect()
}
