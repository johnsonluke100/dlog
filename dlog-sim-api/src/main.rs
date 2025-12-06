mod gcs;
mod model;
mod sim;

use axum::extract::State;
use axum::http::StatusCode;
use axum::routing::{get, post};
use axum::{Json, Router};
use gcs::OmegaStorage;
use model::{
    BlockAction, BlockEvent, BlockState, BlockUpdate, ChunkSnapshot, TickRequest, TickResponse,
};
use sim::PlayerState;
use std::collections::HashMap;
use std::net::SocketAddr;
use tracing::{info, warn};
use tracing_subscriber::EnvFilter;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::from_default_env())
        .init();

    let port: u16 = std::env::var("PORT")
        .ok()
        .and_then(|p| p.parse().ok())
        .unwrap_or(8080);

    let storage = OmegaStorage::new_from_env().await?;

    let app = Router::new()
        .route("/health", get(health))
        .route("/v1/sim/tick", post(sim_tick))
        .with_state(storage);

    let addr = SocketAddr::from(([0, 0, 0, 0], port));
    info!("listening on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}

async fn health() -> &'static str {
    "ok"
}

async fn sim_tick(
    State(storage): State<OmegaStorage>,
    Json(req): Json<TickRequest>,
) -> Result<Json<TickResponse>, (StatusCode, String)> {
    let player_uuid = req.player_uuid.clone();

    let current_state: PlayerState = match storage.load_player_state(&player_uuid).await {
        Ok(Some(state)) => state,
        Ok(None) => PlayerState::default(),
        Err(err) => {
            warn!("[sim] failed to load state for {}: {}", player_uuid, err);
            return Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                "failed to load player state".to_string(),
            ));
        }
    };

    let (next_state, mut response) = sim::advance(current_state, &req);

    if let Err(err) = persist_block_updates(&storage, &req, next_state.universe_tick, &mut response).await
    {
        warn!("[sim] block persistence failed for {}: {}", player_uuid, err);
        return Err((
            StatusCode::INTERNAL_SERVER_ERROR,
            "failed to persist block updates".to_string(),
        ));
    }

    if let Err(err) = storage.save_player_state(&player_uuid, &next_state).await {
        warn!("[sim] failed to write state for {}: {}", player_uuid, err);
        return Err((
            StatusCode::INTERNAL_SERVER_ERROR,
            "failed to persist state".to_string(),
        ));
    }

    Ok(Json(response))
}

async fn persist_block_updates(
    storage: &OmegaStorage,
    req: &TickRequest,
    tick: u64,
    response: &mut TickResponse,
) -> anyhow::Result<()> {
    if req.block_updates.is_empty() {
        return Ok(());
    }

    let mut per_chunk: HashMap<(i64, i64), Vec<BlockUpdate>> = HashMap::new();
    for update in &req.block_updates {
        let (cx, cz) = chunk_coords(update.x, update.z);
        per_chunk.entry((cx, cz)).or_default().push(update.clone());
    }

    for ((cx, cz), updates) in per_chunk {
        let mut chunk = storage.load_chunk(cx, cz).await?;
        let events = apply_updates_to_chunk(&mut chunk, &updates, tick);
        storage.save_chunk(&chunk).await?;
        storage.append_block_events(cx, cz, &events).await?;
        response.chunks.push(chunk);
    }

    Ok(())
}

fn apply_updates_to_chunk(
    chunk: &mut ChunkSnapshot,
    updates: &[BlockUpdate],
    tick: u64,
) -> Vec<BlockEvent> {
    let mut events = Vec::new();
    if updates.is_empty() {
        return events;
    }

    let mut touched = false;
    for update in updates {
        touched = true;
        match update.action {
            BlockAction::Place => {
                upsert_block(chunk, update, tick);
            }
            BlockAction::Break => {
                remove_block(chunk, update);
            }
        }

        events.push(BlockEvent {
            tick,
            x: update.x,
            y: update.y,
            z: update.z,
            block: update.block.clone(),
            action: update.action,
        });
    }

    if touched {
        chunk.version = chunk.version.wrapping_add(1);
    }

    events
}

fn upsert_block(chunk: &mut ChunkSnapshot, update: &BlockUpdate, tick: u64) {
    if let Some(existing) = chunk
        .blocks
        .iter_mut()
        .find(|b| b.x == update.x && b.y == update.y && b.z == update.z)
    {
        existing.block = update.block.clone();
        existing.last_tick = tick;
        return;
    }

    chunk.blocks.push(BlockState {
        x: update.x,
        y: update.y,
        z: update.z,
        block: update.block.clone(),
        last_tick: tick,
    });
}

fn remove_block(chunk: &mut ChunkSnapshot, update: &BlockUpdate) {
    chunk
        .blocks
        .retain(|b| !(b.x == update.x && b.y == update.y && b.z == update.z));
}

fn chunk_coords(x: i64, z: i64) -> (i64, i64) {
    (x.div_euclid(16), z.div_euclid(16))
}
