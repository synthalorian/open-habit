//! open_habit CLI — A terminal-based habit tracker with gamification.
//!
//! Usage:
//! ```
//!   open-habit add "Meditate" --category mindfulness --difficulty easy
//!   open-habit complete <habit-id>
//!   open-habit list
//!   open-habit achievements
//!   open-habit progress
//! ```

use chrono::Utc;
use clap::{Parser, Subcommand};
use open_habit::GamificationEngine;
use open_habit_db::Database;
use open_habit_shared::*;
use std::path::PathBuf;
use uuid::Uuid;

#[derive(Parser, Debug)]
#[command(name = "open-habit")]
#[command(version, about = "Retro-synthwave habit tracker with gamification")]
struct Cli {
    #[command(subcommand)]
    command: Commands,

    /// Path to the database file
    #[arg(short, long, default_value = "data/open_habit.db")]
    database: PathBuf,
}

#[derive(Subcommand, Debug)]
enum Commands {
    /// List all active habits
    List {
        /// Show all habits including archived
        #[arg(short, long)]
        all: bool,
    },
    /// Add a new habit
    Add {
        /// Name of the habit
        name: String,
        /// Category (e.g., health, learning, mindfulness)
        #[arg(short, long, default_value = "general")]
        category: String,
        /// Difficulty level
        #[arg(short, long, default_value = "easy")]
        difficulty: String,
        /// Frequency
        #[arg(short, long, default_value = "daily")]
        frequency: String,
        /// Description
        #[arg(short, long)]
        description: Option<String>,
    },
    /// Complete a habit
    Complete {
        /// Habit ID
        id: String,
    },
    /// View current progression
    Progress,
    /// View achievements
    Achievements,
    /// View active streaks
    Streaks,
    /// View challenges
    Challenges,
    /// Delete a habit
    Delete {
        /// Habit ID to delete
        id: String,
    },
}

fn main() {
    let cli = Cli::parse();

    // Ensure data directory exists
    if let Some(parent) = cli.database.parent() {
        std::fs::create_dir_all(parent).ok();
    }

    match cli.command {
        Commands::List { all } => cmd_list(&cli.database, all),
        Commands::Add { name, category, difficulty, frequency, description } => {
            cmd_add(&cli.database, &name, &category, &difficulty, &frequency, &description)
        }
        Commands::Complete { id } => cmd_complete(&cli.database, &id),
        Commands::Progress => cmd_progress(&cli.database),
        Commands::Achievements => cmd_achievements(&cli.database),
        Commands::Streaks => cmd_streaks(),
        Commands::Challenges => cmd_challenges(&cli.database),
        Commands::Delete { id } => cmd_delete(&cli.database, &id),
    }
}

fn open_db(path: &PathBuf) -> Database {
    if let Some(parent) = path.parent() {
        let _ = std::fs::create_dir_all(parent);
    }
    Database::open(path).expect("Failed to open database")
}

fn cmd_list(path: &PathBuf, all: bool) {
    let db = open_db(path);
    let habits = if all {
        db.list_habits(None).expect("Failed to list habits")
    } else {
        db.list_habits(Some("active")).expect("Failed to list habits")
    };

    if habits.is_empty() {
        println!("No habits found. Add one with `open-habit add <name>`");
        return;
    }

    println!("Your Habits");
    println!("─────────────────────────────────────────────");
    for habit in &habits {
        let status_icon = match habit.status {
            HabitStatus::Active => "[active]",
            HabitStatus::Archived => "[archived]",
            HabitStatus::Completed => "[done]",
        };
        let diff_icon = match habit.difficulty {
            Difficulty::Easy => "[easy]",
            Difficulty::Medium => "[med]",
            Difficulty::Hard => "[hard]",
            Difficulty::Extreme => "[extreme]",
        };
        let last = habit.last_completed
            .map(|d| d.format("%Y-%m-%d").to_string())
            .unwrap_or("Never".to_string());

        println!(
            "{} {} {}  {} [{}] {}  XP: {} | Streak: {} | Best: {} | Total: {}",
            status_icon,
            habit.name,
            diff_icon,
            habit.category,
            format!("{:?}", habit.frequency),
            last,
            habit.xp_reward,
            habit.current_streak,
            habit.best_streak,
            habit.total_completions
        );
    }
}

fn cmd_add(
    path: &PathBuf,
    name: &str,
    category: &str,
    difficulty: &str,
    frequency: &str,
    description: &Option<String>,
) {
    let diff = match difficulty.to_lowercase().as_str() {
        "easy" => Difficulty::Easy,
        "medium" => Difficulty::Medium,
        "hard" => Difficulty::Hard,
        "extreme" => Difficulty::Extreme,
        _ => Difficulty::Easy,
    };

    let freq = match frequency.to_lowercase().as_str() {
        "daily" => Frequency::Daily,
        "weekly" => Frequency::Weekly,
        "once" => Frequency::Once,
        _ => Frequency::Daily,
    };

    let mut db = open_db(path);
    let habit = Habit::new(name, category, diff, freq);
    db.create_habit(&habit).expect("Failed to create habit");

    let xp_icon = match diff {
        Difficulty::Easy => "10",
        Difficulty::Medium => "25",
        Difficulty::Hard => "50",
        Difficulty::Extreme => "100",
    };

    println!(
        "Habit created: {} [{}] | XP: {} | ID: {}",
        habit.name, habit.category, xp_icon, habit.id
    );
}

fn cmd_complete(path: &PathBuf, id_str: &str) {
    let id: Uuid = match id_str.parse() {
        Ok(u) => u,
        Err(e) => {
            eprintln!("Invalid habit ID: {}", e);
            return;
        }
    };

    let mut db = open_db(path);
    let mut engine = GamificationEngine::new();

    let habit = match db.get_habit(&id) {
        Ok(Some(h)) => h,
        Ok(None) => {
            eprintln!("Habit not found");
            return;
        }
        Err(e) => {
            eprintln!("Database error: {}", e);
            return;
        }
    };

    let today = Utc::now().date_naive();

    // Complete in DB
    let xp = db.complete_habit(&id, today).expect("Failed to complete habit");

    // Gamify
    let result = engine.complete_habit(id, today, habit.difficulty);

    // Record XP
    db.record_xp(xp, "HabitCompletion", Some(&id.to_string()), today).ok();

    println!(
        "Completed: {} | +{} XP",
        habit.name, result.base_xp
    );

    if result.bonus_xp > 0 {
        println!("Streak bonus: +{} XP", result.bonus_xp);
    }

    if result.is_level_up() {
        for level in &result.leveled_up {
            println!("LEVEL UP! You're now level {}!", level);
        }
    }

    if result.is_achievement_unlock() {
        for ach in &result.newly_unlocked {
            println!("Achievement unlocked: {}!", ach.title);
        }
    }

    let player = engine.player_state();
    let progress = engine.active_streaks();
    println!(
        "Level {} | {} XP to next | {} active streaks",
        player.level,
        player.xp_to_next,
        progress.len()
    );
}

fn cmd_progress(path: &PathBuf) {
    let db = open_db(path);
    let engine = GamificationEngine::new();
    let player = engine.player_state();
    let progression = db.get_progression().ok();

    println!("Player Progress");
    println!("─────────────────────────────────────────────");
    println!("Level: {} ({}/{})", player.level, player.total_xp, player.xp_to_next);
    println!(
        "Progression: {:.1}% to next level",
        (player.total_xp as f64 / player.xp_to_next as f64) * 100.0
    );
    println!("Streaks: {}", engine.active_streaks().len());

    if let Some(db_prog) = progression {
        println!("Database: Level {} | {} XP", db_prog.level, db_prog.total_xp);
    }
}

fn cmd_achievements(path: &PathBuf) {
    let db = open_db(path);
    let engine = GamificationEngine::new();
    let achievements = db.list_achievements().expect("Failed to list achievements");

    println!("Achievements");
    println!("─────────────────────────────────────────────");

    for ach in &achievements {
        let icon = if ach.unlocked { "unlocked" } else { "locked" };
        let req_level = if ach.level_requirement > 1 {
            format!(" (Lv{})", ach.level_requirement)
        } else {
            String::new()
        };
        println!(
            " {} {} | {} XP{}",
            icon, ach.title, ach.xp_reward, req_level
        );
    }

    println!(
        "\n{} unlocked",
        achievements.iter().filter(|a| a.unlocked).count()
    );
}

fn cmd_streaks() {
    let engine = GamificationEngine::new();
    let streaks = engine.active_streaks();

    if streaks.is_empty() {
        println!("No active streaks. Complete some habits!");
        return;
    }

    println!("Active Streaks");
    println!("─────────────────────────────────────────────");

    for streak in streaks {
        println!(
            "habit {}: {} days",
            streak.habit_id, streak.count
        );
    }
}

fn cmd_challenges(path: &PathBuf) {
    let db = open_db(path);
    let challenges = db.list_challenges().expect("Failed to list challenges");

    if challenges.is_empty() {
        println!("No challenges available. Complete habits to earn challenges!");
        return;
    }

    println!("Challenges");
    println!("─────────────────────────────────────────────");

    for challenge in &challenges {
        let status_icon = match challenge.status {
            ChallengeStatus::Active => "[active]",
            ChallengeStatus::Completed => "[done]",
            ChallengeStatus::Failed => "[failed]",
        };
        println!(
            " {} {} | {} | {}/{} | XP: {}",
            status_icon, challenge.title, challenge.description,
            challenge.progress, challenge.target, challenge.xp_reward
        );
    }
}

fn cmd_delete(path: &PathBuf, id_str: &str) {
    let id: Uuid = match id_str.parse() {
        Ok(u) => u,
        Err(e) => {
            eprintln!("Invalid habit ID: {}", e);
            return;
        }
    };

    let mut db = open_db(path);
    if db.delete_habit(&id).is_ok() {
        println!("Habit deleted: {}", id);
    } else {
        eprintln!("Failed to delete habit");
    }
}
