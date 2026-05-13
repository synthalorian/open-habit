use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    response::Json,
    routing::{delete, get, post, put},
    Json as JsonReq, Router,
};
use chrono::Utc;
use open_habit::{GamificationEngine, CompletionResult};
use open_habit_db::Database;
use open_habit_shared::*;
use std::sync::{Arc, RwLock};
use uuid::Uuid;

/// Shared app state
struct AppState {
    db: Arc<RwLock<Database>>,
    engine: Arc<RwLock<GamificationEngine>>,
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::from_default_env()
                .add_directive("open_habit_server=info".into()),
        )
        .init();

    let db = Arc::new(RwLock::new(
        Database::open("data/open_habit.db").expect("Failed to open database"),
    ));
    let engine = Arc::new(RwLock::new(GamificationEngine::new()));

    // Load existing achievements into engine
    let achievements = db.read().unwrap().list_achievements();
    if let Ok(achievements) = achievements {
        engine.write().unwrap().achievements().set_achievements(achievements);
    }

    let state = AppState { db, engine };

    let app = Router::new()
        .route("/habits", get(list_habits).post(create_habit))
        .route("/habits/{id}", get(get_habit).put(update_habit).delete(delete_habit))
        .route("/habits/{id}/complete", post(complete_habit))
        .route("/progression", get(get_progression))
        .route("/xp/record", post(record_xp))
        .route("/achievements", get(list_achievements))
        .route("/streaks", get(list_streaks))
        .route("/challenges", get(list_challenges))
        .with_state(state);

    let addr = "0.0.0.0:3000".to_string();
    tracing::info!("🎹 open_habit server listening on {}", addr);
    axum::serve(
        tokio::net::TcpListener::bind(&addr).await.unwrap(),
        app,
    )
    .await
    .unwrap();
}

// ─── Handlers ─────────────────────────────────────────────────────────

async fn list_habits(State(state): State<AppState>) -> JsonReq<Vec<Habit>> {
    let db = state.db.read().unwrap();
    JsonReq(db.list_habits(None).expect("Failed to list habits"))
}

async fn create_habit(
    State(state): State<AppState>,
    JsonReq(habit): JsonReq<Habit>,
) -> (StatusCode, JsonReq<Habit>) {
    let mut db = state.db.write().unwrap();
    if db.create_habit(&habit).is_ok() {
        (StatusCode::CREATED, JsonReq(habit))
    } else {
        (StatusCode::CONFLICT, JsonReq(habit))
    }
}

async fn get_habit(
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
) -> Result<JsonReq<Habit>, (StatusCode, String)> {
    let db = state.db.read().unwrap();
    db.get_habit(&id)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?
        .map(|h| JsonReq(h))
        .ok_or((StatusCode::NOT_FOUND, "Habit not found".into()))
}

async fn update_habit(
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
    JsonReq(update): JsonReq<serde_json::Value>,
) -> Result<JsonReq<serde_json::Value>, (StatusCode, String)> {
    let mut db = state.db.write().unwrap();
    let name = update.get("name").and_then(|v| v.as_str());
    let description = update.get("description").and_then(|v| v.as_str());
    let status = update.get("status").and_then(|v| v.as_str());
    
    db.update_habit(&id, name, description, status)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    
    let habit = db.get_habit(&id)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    
    Ok(JsonReq(serde_json::to_value(habit.ok_or((StatusCode::NOT_FOUND, "Habit not found".into()))?).map_err(|(_, msg)| (StatusCode::INTERNAL_SERVER_ERROR, msg))?))
}

async fn delete_habit(
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
) -> Result<StatusCode, (StatusCode, String)> {
    let mut db = state.db.write().unwrap();
    db.delete_habit(&id)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    Ok(StatusCode::NO_CONTENT)
}

async fn complete_habit(
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
) -> (StatusCode, JsonReq<serde_json::Value>) {
    let mut db = state.db.write().unwrap();
    let mut engine = state.engine.write().unwrap();
    let today = Utc::now().date_naive();
    
    if let Some(habit) = db.get_habit(&id).ok().flatten() {
        let difficulty = habit.difficulty;
        let xp = db.complete_habit(&id, today).ok().unwrap_or(0);
        let result = engine.complete_habit(id, today, difficulty);
        
        db.record_xp(xp, "HabitCompletion", Some(&id.to_string()), today).ok();
        db.save_streak(&open_habit_shared::Streak {
            habit_id: id,
            count: engine.active_streaks().iter()
                .find(|s| s.habit_id == id)
                .map(|s| s.count)
                .unwrap_or(0),
            started_at: today,
            last_date: today,
            is_active: true,
        }).ok();
        
        (StatusCode::OK, JsonReq(serde_json::json!({
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
        })))
    } else {
        (StatusCode::NOT_FOUND, JsonReq(serde_json::json!({"error": "Habit not found"})))
    }
}

async fn get_progression(State(state): State<AppState>) -> JsonReq<serde_json::Value> {
    let db = state.db.read().unwrap();
    let engine = state.engine.read().unwrap();
    let prog = db.get_progression().ok();
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
    let today = Utc::now().date_naive();
    let mut db = state.db.write().unwrap();
    
    if amount > 0 {
        db.record_xp(amount, "API", None, today).ok();
        JsonReq(serde_json::json!({ "status": "recorded", "amount": amount }))
    } else {
        (StatusCode::BAD_REQUEST, JsonReq(serde_json::json!({"error": "amount required"})))
    }
}

async fn list_achievements(State(state): State<AppState>) -> JsonReq<Vec<Achievement>> {
    let db = state.db.read().unwrap();
    JsonReq(db.list_achievements().expect("Failed to list achievements"))
}

async fn list_streaks(State(state): State<AppState>) -> JsonReq<Vec<open_habit_shared::Streak>> {
    let engine = state.engine.read().unwrap();
    JsonReq(engine.active_streaks().to_vec())
}

async fn list_challenges(State(state): State<AppState>) -> JsonReq<Vec<open_habit_shared::Challenge>> {
    let db = state.db.read().unwrap();
    JsonReq(db.list_challenges().expect("Failed to list challenges"))
}
