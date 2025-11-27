use axum::{routing::get, Json, Router};
use tokio::net::TcpListener;
use serde::Serialize;
use spec::{MonetarySpec, PlanetGravityProfile, PLANET_PROFILES, PHI};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[tokio::main]
async fn main() {
    init_tracing();

    let app = Router::new()
        .route("/health", get(health))
        .route("/v1/spec/monetary", get(monetary))
        .route("/v1/spec/planets", get(planets));

    // 8888 here is just a human-friendly port; underneath it's all bits anyway.
    let addr = std::net::SocketAddr::from(([0, 0, 0, 0], 8888));
    tracing::info!("dlog Ω-api listening on http://{addr}");

    let listener = TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

fn init_tracing() {
    let env_filter = std::env::var("RUST_LOG").unwrap_or_else(|_| "info,hyper=warn".to_string());

    let fmt_layer = tracing_subscriber::fmt::layer()
        .with_target(false)
        .with_line_number(true);

    tracing_subscriber::registry()
        .with(tracing_subscriber::EnvFilter::new(env_filter))
        .with(fmt_layer)
        .init();
}

async fn health() -> Json<serde_json::Value> {
    Json(serde_json::json!({
        "status": "ok",
        "phi": PHI,
        "message": "Ω-heartbeat online"
    }))
}

async fn monetary() -> Json<MonetarySpec> {
    Json(MonetarySpec::default())
}

#[derive(Serialize)]
struct PlanetsResponse {
    planets: Vec<PlanetGravityProfile>,
}

async fn planets() -> Json<PlanetsResponse> {
    Json(PlanetsResponse {
        planets: PLANET_PROFILES.to_vec(),
    })
}
