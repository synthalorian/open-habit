//! PlayerStats persistence — RPG-style stats that level up from habits.
//!
//! Each stat maps to one or more habit categories. Completing habits in those
//! categories awards XP to the stats. Users can customize, rename, and create
//! their own stats.

use chrono::Utc;
use open_habit_shared::{default_stats, PlayerStat};
use rusqlite::{params, Connection};
use uuid::Uuid;

use crate::{DBError, DBResult};

/// Insert or update a player stat.
pub fn upsert_stat(conn: &Connection, stat: &PlayerStat) -> DBResult<()> {
    conn.execute(
        r#"INSERT INTO player_stats (id, name, value, level, xp_in_stat, xp_to_next, icon, color, category_mappings, created_at)
           VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10)
           ON CONFLICT(id) DO UPDATE SET
               name = excluded.name,
               value = excluded.value,
               level = excluded.level,
               xp_in_stat = excluded.xp_in_stat,
               xp_to_next = excluded.xp_to_next,
               icon = excluded.icon,
               color = excluded.color,
               category_mappings = excluded.category_mappings"#,
        params![
            stat.id.to_string(),
            stat.name,
            stat.value,
            stat.level,
            stat.xp_in_stat,
            stat.xp_to_next,
            stat.icon,
            stat.color,
            stat.category_mappings,
            stat.created_at.to_string(),
        ],
    )?;
    Ok(())
}

/// Get all player stats.
pub fn list_stats(conn: &Connection) -> DBResult<Vec<PlayerStat>> {
    let mut stmt = conn.prepare(
        "SELECT id, name, value, level, xp_in_stat, xp_to_next, icon, color, category_mappings, created_at FROM player_stats ORDER BY level DESC, name"
    )?;
    let rows = stmt.query_map([], |row| {
        Ok(PlayerStat {
            id: Uuid::parse_str(&row.get::<_, String>(0)?)
                .map_err(|e| rusqlite::Error::ToSqlConversionFailure(Box::new(e)))?,
            name: row.get(1)?,
            value: row.get(2)?,
            level: row.get(3)?,
            xp_in_stat: row.get(4)?,
            xp_to_next: row.get(5)?,
            icon: row.get(6)?,
            color: row.get(7)?,
            category_mappings: row.get(8)?,
            created_at: row
                .get::<_, String>(9)?
                .parse()
                .map_err(|e| rusqlite::Error::ToSqlConversionFailure(Box::new(e)))?,
        })
    })?;
    let mut stats = Vec::new();
    for row in rows {
        stats.push(row?);
    }
    Ok(stats)
}

/// Initialize the player_stats table.
pub fn initialize_table(conn: &Connection) -> DBResult<()> {
    conn.execute_batch(
        r#"
        CREATE TABLE IF NOT EXISTS player_stats (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            value REAL NOT NULL DEFAULT 1.0,
            level INTEGER NOT NULL DEFAULT 1,
            xp_in_stat INTEGER NOT NULL DEFAULT 0,
            xp_to_next INTEGER NOT NULL DEFAULT 120,
            icon TEXT NOT NULL DEFAULT '⭐',
            color TEXT NOT NULL DEFAULT '#FF9B71',
            category_mappings TEXT NOT NULL DEFAULT '[]',
            created_at TEXT NOT NULL
        );
        "#,
    )?;

    // Seed default stats if table is empty
    let count: i64 = conn.query_row("SELECT COUNT(*) FROM player_stats", [], |row| row.get(0))?;
    if count == 0 {
        for stat in default_stats::defaults() {
            upsert_stat(conn, &stat)?;
        }
    }

    Ok(())
}

/// Delete a player stat by ID.
pub fn delete_stat(conn: &Connection, id: &str) -> DBResult<()> {
    conn.execute("DELETE FROM player_stats WHERE id = ?1", params![id])?;
    Ok(())
}