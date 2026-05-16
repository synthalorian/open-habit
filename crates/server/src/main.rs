use axum::{
    Json as JsonReq, Router,
    extract::{Path, State},
    http::StatusCode,
    routing::{get, post, put},
};
use chrono::Utc;
use open_habit::GamificationEngine;
use open_habit_db::DatabaseClient;
use open_habit_shared::*;
use open_habit_shared::{default_stats, PlayerStat};
use std::sync::{Arc, RwLock};
use tracing_subscriber::filter::Directive;
use uuid::Uuid;

/// Shared app state
#[derive(Clone)]
struct AppState {
    db: Arc<DatabaseClient>,
    engine: Arc<RwLock<GamificationEngine>>,
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::from_default_env()
                .add_directive("open_habit_server=info".parse::<Directive>().unwrap()),
        )
        .init();

    let db = Arc::new(
        DatabaseClient::new("data/open_habit.db".to_string())
            .expect("Failed to create DB client"),
    );
    let engine = Arc::new(RwLock::new(GamificationEngine::new()));

    // Load existing achievements into engine
    let achievements = db.list_achievements();
    if let Ok(achievements) = achievements {
        engine.write().unwrap().set_achievements(achievements);
    }

    let state = AppState { db, engine };

    let app = Router::new()
        .route("/habits", get(list_habits).post(create_habit))
        .route(
            "/habits/{id}",
            get(get_habit).put(update_habit).delete(delete_habit),
        )
        .route("/habits/{id}/complete", post(complete_habit))
        .route("/progression", get(get_progression))
        .route("/xp/record", post(record_xp))
        .route("/achievements", get(list_achievements))
        .route("/streaks", get(list_streaks))
        .route("/challenges", get(list_challenges))
        .route("/challenges/{id}/progress", post(progress_challenge))
        .route("/stats", get(list_stats))
        .route("/stats/create", post(create_stat))
        .route("/stats/{id}", put(update_stat).delete(delete_stat))
        .route("/stats/defaults", get(get_default_stats))
        .with_state(state);

    let addr = "0.0.0.0:3000".to_string();
    tracing::info!("🎹 open_habit server listening on {}", addr);
    axum::serve(tokio::net::TcpListener::bind(&addr).await.unwrap(), app)
        .await
        .unwrap();
}

// ─── Handlers ─────────────────────────────────────────────────────────

async fn list_habits(State(state): State<AppState>) -> JsonReq<Vec<Habit>> {
    JsonReq(state.db.list_habits(None).expect("Failed to list habits"))
}

async fn create_habit(
    State(state): State<AppState>,
    JsonReq(habit): JsonReq<Habit>,
) -> (StatusCode, JsonReq<Habit>) {
    if state.db.create_habit(habit.clone()).is_ok() {
        (StatusCode::CREATED, JsonReq(habit))
    } else {
        (StatusCode::CONFLICT, JsonReq(habit))
    }
}

async fn get_habit(
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
) -> Result<JsonReq<Habit>, (StatusCode, String)> {
    state
        .db
        .get_habit(id.to_string())
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?
        .map(|h| JsonReq(h))
        .ok_or((StatusCode::NOT_FOUND, "Habit not found".into()))
}

async fn update_habit(
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
    JsonReq(update): JsonReq<serde_json::Value>,
) -> Result<JsonReq<serde_json::Value>, (StatusCode, String)> {
    let name = update.get("name").and_then(|v| v.as_str()).map(|s| s.to_string());
    let description = update.get("description").and_then(|v| v.as_str()).map(|s| s.to_string());
    let status = update.get("status").and_then(|v| v.as_str()).map(|s| s.to_string());

    state.db.update_habit(id.to_string(), name, description, status)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    let habit = state.db.get_habit(id.to_string())
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(JsonReq(
        serde_json::to_value(habit.ok_or((StatusCode::NOT_FOUND, "Habit not found".into()))?)
            .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?,
    ))
}

async fn delete_habit(
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
) -> Result<StatusCode, (StatusCode, String)> {
    state.db.delete_habit(id.to_string())
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    Ok(StatusCode::NO_CONTENT)
}

async fn complete_habit(
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
) -> (StatusCode, JsonReq<serde_json::Value>) {
    let mut engine = state.engine.write().unwrap();
    let today = Utc::now().date_naive();

    if let Some(habit) = state.db.get_habit(id.to_string()).ok().flatten() {
        let difficulty = habit.difficulty;
        let xp = state.db.complete_habit(id.to_string()).ok().unwrap_or(0);
        let result = engine.complete_habit(id, today, difficulty);

        state.db.record_xp(xp).ok();
        let streak = Streak {
            habit_id: id,
            count: engine
                .active_streaks()
                .iter()
                .find(|s| s.habit_id == id)
                .map(|s| s.count)
                .unwrap_or(0),
            started_at: today,
            last_date: today,
            is_active: true,
        };
        state.db.save_streak(&streak).ok();

        (
            StatusCode::OK,
            JsonReq(serde_json::json!({
                "xp_awarded": result.base_xp,
                "bonus_xp": result.bonus_xp,
                "achievement_xp": result.achievement_xp,
                "total_xp": result.total_xp(),
                "streak": result.new_streak,
                "levelled_up": result.leveled_up,
                "new_achievements": result.newly_unlocked.iter().map(|a| serde_json::json!({
                    "title": a.title,
                    "xp": a.xp_reward,
                    "icon": a.icon,
                })).collect::<Vec<_>>(),
            })),
        )
    } else {
        (
            StatusCode::NOT_FOUND,
            JsonReq(serde_json::json!({"error": "Habit not found"})),
        )
    }
}

async fn get_progression(State(state): State<AppState>) -> JsonReq<serde_json::Value> {
    let prog = state.db.get_progression().ok();
    let engine = state.engine.read().unwrap();
    let player = engine.player_state();

    JsonReq(serde_json::json!({
        "total_xp": player.total_xp,
        "level": player.level,
        "xp_to_next": player.xp_to_next,
        "progress": engine.active_streaks().len(),
        "streaks": engine.active_streaks().iter().map(|s| {
            serde_json::json!({"habit_id": s.habit_id, "count": s.count, "is_active": s.is_active})
        }).collect::<Vec<_>>(),
        "database": prog.map(|p| serde_json::json!({
            "total_xp": p.total_xp,
            "level": p.level,
            "xp_to_next": p.xp_to_next,
        })),
    }))
}

async fn record_xp(
    State(state): State<AppState>,
    JsonReq(req): JsonReq<serde_json::Value>,
) -> (StatusCode, JsonReq<serde_json::Value>) {
    let amount = req.get("amount").and_then(|v| v.as_u64()).unwrap_or(0) as u32;

    if amount > 0 {
        state.db.record_xp(amount).ok();
        (
            StatusCode::OK,
            JsonReq(serde_json::json!({ "status": "recorded", "amount": amount })),
        )
    } else {
        (
            StatusCode::BAD_REQUEST,
            JsonReq(serde_json::json!({"error": "amount required"})),
        )
    }
}

async fn list_achievements(State(state): State<AppState>) -> JsonReq<Vec<Achievement>> {
    JsonReq(state.db.list_achievements().expect("Failed to list achievements"))
}

async fn list_streaks(State(state): State<AppState>) -> JsonReq<Vec<open_habit_shared::Streak>> {
    JsonReq(state.db.list_streaks().expect("Failed to list streaks"))
}

async fn list_challenges(
    State(state): State<AppState>,
) -> JsonReq<Vec<open_habit_shared::Challenge>> {
    JsonReq(state.db.list_challenges().expect("Failed to list challenges"))
}

async fn progress_challenge(
    State(state): State<AppState>,
    Path(challenge_id): Path<Uuid>,
    JsonReq(payload): JsonReq<serde_json::Value>,
) -> (StatusCode, JsonReq<serde_json::Value>) {
    let amount = payload
        .get("amount")
        .and_then(|v| v.as_u64())
        .map(|a| a as u32)
        .unwrap_or(1);

    // Mutably lock engine and progress the challenge
    let mut engine = state.engine.write().unwrap();
    let progressed = engine.progress_challenge(challenge_id, amount);

    // Persist all active challenges after mutation
    let challenges = engine.active_challenges();
    if state.db.save_challenges(&challenges).is_err() {
        return (
            StatusCode::INTERNAL_SERVER_ERROR,
            JsonReq(serde_json::json!({"error": "Failed to save challenges"})),
        );
    }

    // Return the updated challenge if found
    if let Some(challenge) = challenges.iter().find(|c| c.id == challenge_id) {
        let status = if challenge.status == ChallengeStatus::Completed {
            StatusCode::OK
        } else {
            StatusCode::ACCEPTED
        };
        (
            status,
            JsonReq(serde_json::json!({
                "challenge": serde_json::json!({
                    "id": challenge.id,
                    "title": challenge.title,
                    "progress": challenge.progress,
                    "target": challenge.target,
                    "status": challenge.status,
                    "xp_reward": challenge.xp_reward,
                }),
                "completed": challenge.status == ChallengeStatus::Completed,
                "amount_added": amount,
            })),
        )
    } else {
        (
            StatusCode::NOT_FOUND,
            JsonReq(serde_json::json!({"error": "Challenge not found"})),
        )
    }
}

// ─── Stats Handlers ─────────────────────────────────────────────────

async fn list_stats(State(state): State<AppState>) -> JsonReq<Vec<PlayerStat>> {
    JsonReq(state.db.list_stats().expect("Failed to list stats"))
}

async fn get_default_stats() -> JsonReq<Vec<PlayerStat>> {
    JsonReq(default_stats::defaults())
}

async fn create_stat(
    State(state): State<AppState>,
    JsonReq(stat): JsonReq<PlayerStat>,
) -> (StatusCode, JsonReq<PlayerStat>) {
    if state.db.upsert_stat(&stat).is_ok() {
        (StatusCode::CREATED, JsonReq(stat))
    } else {
        (StatusCode::CONFLICT, JsonReq(stat))
    }
}

async fn update_stat(
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
    JsonReq(payload): JsonReq<serde_json::Value>,
) -> Result<JsonReq<PlayerStat>, (StatusCode, String)> {
    // Fetch existing stat, merge updates, save
    let stats = state.db.list_stats().map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    let existing = stats.into_iter().find(|s| s.id == id)
        .ok_or((StatusCode::NOT_FOUND, "Stat not found".into()))?;

    let mut updated = existing.clone();
    if let Some(name) = payload.get("name").and_then(|v| v.as_str()) {
        updated.name = name.to_string();
    }
    if let Some(icon) = payload.get("icon").and_then(|v| v.as_str()) {
        updated.icon = icon.to_string();
    }
    if let Some(color) = payload.get("color").and_then(|v| v.as_str()) {
        updated.color = color.to_string();
    }
    if let Some(mappings) = payload.get("category_mappings").and_then(|v| v.as_str()) {
        updated.category_mappings = mappings.to_string();
    }

    state.db.upsert_stat(&updated)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    Ok(JsonReq(updated))
}

async fn delete_stat(
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
) -> Result<StatusCode, (StatusCode, String)> {
    state.db.delete_stat(id.to_string())
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    Ok(StatusCode::NO_CONTENT)
}
