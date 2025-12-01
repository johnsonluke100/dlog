mod omega;

use axum::{
    extract::State,
    routing::{get, post},
    Json, Router,
};
use omega::{FrameAck, FrameEnvelope, HandshakeRequest, HandshakeResponse, OmegaGateway};
use serde::Serialize;
use std::{env, net::SocketAddr, sync::Arc};
use tokio::net::TcpListener;
use tracing::{error, info};

#[derive(Clone)]
struct AppState {
    gateway: Arc<OmegaGateway>,
}

#[derive(Debug, Serialize)]
struct RootResponse<'a> {
    status: &'a str,
    motd: &'a str,
    endpoints: &'a [&'a str],
}

#[derive(Debug, Serialize)]
struct HealthResponse {
    status: &'static str,
    gateway_id: String,
    boot_ms: i64,
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .with_target(false)
        .with_level(true)
        .init();

    // Cloud Run injects PORT; default to 8080 for local runs
    let port: u16 = env::var("PORT")
        .ok()
        .and_then(|p| p.parse().ok())
        .unwrap_or(8080);

    let state = AppState {
        gateway: Arc::new(OmegaGateway::new()),
    };

    let app = Router::new()
        .route("/", get(root))
        .route("/health", get(health))
        .route("/omega/handshake", post(handshake))
        .route("/omega/frame", post(frame))
        .with_state(state);

    let addr = SocketAddr::from(([0, 0, 0, 0], port));
    info!("dlog.gold Ω-edge listening on http://{addr}");

    let listener = TcpListener::bind(addr)
        .await
        .expect("failed to bind TCP listener");

    if let Err(err) = axum::serve(listener, app).await {
        error!("server error: {err}");
    }
}

async fn root() -> Json<RootResponse<'static>> {
    Json(RootResponse {
        status: "online",
        motd: "HTTP-3 shell → HTTP-4 kernel bridge",
        endpoints: &["GET /health", "POST /omega/handshake", "POST /omega/frame"],
    })
}

async fn health(State(state): State<AppState>) -> Json<HealthResponse> {
    Json(HealthResponse {
        status: "ok",
        gateway_id: state.gateway.id().to_string(),
        boot_ms: state.gateway.boot_ms(),
    })
}

async fn handshake(
    State(state): State<AppState>,
    Json(payload): Json<HandshakeRequest>,
) -> Json<HandshakeResponse> {
    let response = state.gateway.handle_handshake(payload);
    Json(response)
}

async fn frame(
    State(state): State<AppState>,
    Json(payload): Json<FrameEnvelope>,
) -> Json<FrameAck> {
    let response = state.gateway.handle_frame(payload);
    Json(response)
}
