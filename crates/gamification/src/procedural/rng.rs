use chrono::NaiveDate;
use rand::{SeedableRng, Rng, seq::SliceRandom};
use rand::rngs::StdRng;
use std::hash::{DefaultHasher, Hasher};
use uuid::Uuid;

/// Seeded random number generator that produces deterministic sequences.
///
/// Seed is derived from the date (YYYY-MM-DD) and an optional user ID.
/// Same inputs yield identical RNG state across runs.
pub struct SeededRng(StdRng);

impl SeededRng {
    /// Create a new SeededRng from a date and optional user identifier.
    pub fn from_date(date: NaiveDate, user_id: Option<Uuid>) -> Self {
        let mut hasher = DefaultHasher::new();
        // Hash the date string
        hasher.write(date.format("%Y-%m-%d").to_string().as_bytes());
        // Include user_id if provided
        if let Some(uid) = user_id {
            hasher.write(uid.as_hyphenated().to_string().as_bytes());
        }
        let hash = hasher.finish();
        // StdRng can be seeded from a u64 via seed_from_u64
        let rng = StdRng::seed_from_u64(hash);
        SeededRng(rng)
    }

    /// Generate a random number in the range [low, high).
    pub fn gen_range(&mut self, low: i32, high: i32) -> i32 {
        self.0.gen_range(low..high)
    }

    /// Generate a random boolean with the given probability (0.0 - 1.0).
    #[allow(dead_code)]
    pub fn gen_bool(&mut self, probability: f64) -> bool {
        self.0.gen_bool(probability)
    }

    /// Shuffle a slice in place.
    pub fn shuffle<T>(&mut self, slice: &mut [T]) {
        slice.shuffle(&mut self.0);
    }

    /// Consume and produce next u32.
    #[allow(dead_code)]
    pub fn next_u32(&mut self) -> u32 {
        use rand::distributions::Standard;
        self.0.sample(Standard)
    }
}
