use axum::{
    extract::State,
    routing::{get, post},
    Json, Router,
};
use dlog_core::init_universe;
use dlog_corelib::{UniverseError, UniverseState};
use dlog_spec::{Address, Amount};
use serde::{Deserialize, Serialize};
use std::{
    net::SocketAddr,
    sync::{Arc, Mutex},
};
use tracing_subscriber::EnvFilter;

#[derive(Clone)]
struct AppState {
    universe: Arc<Mutex<UniverseState>>,
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

#[tokio::main]
async fn main() {
    // Logging / tracing
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::from_default_env().add_directive("dlog_api=info".parse().unwrap()))
        .init();

    // For now just bind to 127.0.0.1:8888; same as dlog.toml.
    let addr: SocketAddr = "127.0.0.1:8888".parse().expect("valid socket addr");

    let universe = init_universe();
    let state = AppState {
        universe: Arc::new(Mutex::new(universe)),
    };

    let app = Router::new()
        .route("/health", get(health))
        .route("/height", get(height))
        .route("/transfer", post(transfer))
        .with_state(state);

    tracing::info!("dlog-api listening on http://{addr}");
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
