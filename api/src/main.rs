use axum::{
    extract::State,
    routing::{get, post},
    Json, Router,
};
use dlog_core::init_universe;
use dlog_corelib::{UniverseError, UniverseState};
use dlog_spec::{Address, Amount};
use dlog_sky::SkyTimeline;
use serde::{Deserialize, Serialize};
use std::{
    net::SocketAddr,
    sync::{Arc, Mutex},
    time::{SystemTime, UNIX_EPOCH},
};
use tracing_subscriber::EnvFilter;

#[derive(Clone)]
struct AppState {
    universe: Arc<Mutex<UniverseState>>,
    sky: Arc<Mutex<SkyTimeline>>,
}

#[derive(Serialize)]
struct HealthResponse {
    status: &'static str,
}

#[derive(Serialize)]
struct HeightResponse {
    height: u64,
}

#[derive(Deserialize)]
struct TransferRequest {
    from_phone: String,
    from_label: String,
    to_phone: String,
    to_label: String,
    amount_dlog: u128,
}

#[derive(Serialize)]
struct TransferResponse {
    ok: bool,
    error: Option<String>,
}

#[derive(Serialize)]
struct SkyCurrentResponse {
    tick: u64,
    slide_id: u32,
    path: String,
    duration_ticks: u64,
}

#[tokio::main]
async fn main() {
    // Logging / tracing
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::from_default_env().add_directive("dlog_api=info".parse().unwrap()))
        .init();

    // For now just bind to 127.0.0.1:8888; same as dlog.toml.
    let addr: SocketAddr = "127.0.0.1:8888".parse().expect("valid socket addr");

    // Universe + sky init
    let universe = init_universe();
    let tick_hz = universe.config.phi_tick_hz;

    let state = AppState {
        universe: Arc::new(Mutex::new(universe)),
        sky: Arc::new(Mutex::new(SkyTimeline::default_eight())),
    };

    let app = Router::new()
        .route("/health", get(health))
        .route("/height", get(height))
        .route("/transfer", post(transfer))
        .route("/sky/current", get(sky_current))
        .with_state(state);

    tracing::info!("dlog-api listening on http://{addr} (phi_tick_hz={tick_hz})");
    axum::Server::bind(&addr)
        .serve(app.into_make_service())
        .await
        .expect("server to run");
}

async fn health() -> Json<HealthResponse> {
    Json(HealthResponse { status: "ok" })
}

async fn height(State(state): State<AppState>) -> Json<HeightResponse> {
    let universe = state.universe.lock().expect("universe lock poisoned");
    Json(HeightResponse {
        height: universe.height,
    })
}

async fn transfer(
    State(state): State<AppState>,
    Json(req): Json<TransferRequest>,
) -> Json<TransferResponse> {
    let mut universe = state.universe.lock().expect("universe lock poisoned");

    let from = Address {
        phone: req.from_phone,
        label: req.from_label,
    };
    let to = Address {
        phone: req.to_phone,
        label: req.to_label,
    };
    let amount = Amount::new(req.amount_dlog);

    let result = universe.transfer(&from, &to, amount);

    let (ok, error) = match result {
        Ok(()) => (true, None),
        Err(e) => (
            false,
            Some(match e {
                UniverseError::InsufficientBalance => "insufficient_balance".to_string(),
                UniverseError::UnknownAccount => "unknown_account".to_string(),
            }),
        ),
    };

    Json(TransferResponse { ok, error })
}

async fn sky_current(State(state): State<AppState>) -> Json<SkyCurrentResponse> {
    let universe = state.universe.lock().expect("universe lock poisoned");
    let tick_hz = universe.config.phi_tick_hz;
    drop(universe);

    // Use wall-clock to pick a frame: ticks = seconds * phi_tick_hz.
    let now = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default();
    let ticks = (now.as_secs_f64() * tick_hz).floor() as u64;

    let sky = state.sky.lock().expect("sky lock poisoned");
    let slide = sky
        .slide_at_tick(ticks)
        .cloned()
        .unwrap_or_else(|| dlog_spec::SkyShowConfig::default_eight().slides[0].clone());

    Json(SkyCurrentResponse {
        tick: ticks,
        slide_id: slide.id,
        path: slide.path,
        duration_ticks: slide.duration_ticks,
    })
}
