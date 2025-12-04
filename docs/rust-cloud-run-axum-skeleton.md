# Rust Cloud Run service (Axum) skeleton for `/v1/events/*`

Minimal Axum + serde service you can deploy to Cloud Run. It accepts events from the Paper 1.8.8 plugin (`/v1/events/tip`, `/v1/events/join`), authenticates with a shared token, and is structured to plug in Cloud SQL (Postgres) and GCS writes for the Ω filesystem.

## Cargo manifest (example)
```toml
[package]
name = "dlog-api"
version = "0.1.0"
edition = "2021"

[dependencies]
axum = { version = "0.7", features = ["macros"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
tokio = { version = "1", features = ["macros", "rt-multi-thread"] }
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["fmt", "env-filter"] }
hyper = { version = "1", features = ["full"] }
tower = "0.4"
tower-http = { version = "0.5", features = ["trace", "cors"] }
uuid = { version = "1", features = ["v4", "serde"] }
chrono = { version = "0.4", features = ["serde"] }
anyhow = "1"
thiserror = "1"

# Optional for Cloud SQL (via connection string/proxy) and GCS
tokio-postgres = { version = "0.7", features = ["with-uuid-1", "with-chrono-0_4"] }
deadpool-postgres = { version = "0.12", features = ["serde"] }
bb8 = "0.8"
gcp_auth = "0.9"
google-cloud-storage = { version = "0.12", features = ["rustls-tls"] }
```

## Environment
- `PORT` (Cloud Run sets it; default to 8080 locally)
- `FRONTEND_TOKEN` (shared secret with the Paper plugin; check `X-Frontend-Token`)
- `DATABASE_URL` (Postgres, likely via Cloud SQL Proxy: `postgres://user:pass@127.0.0.1:5432/db`)
- `GCS_BUCKET` (bucket for Ω files; e.g., `dlog-omega-root`)

## `src/main.rs` (skeleton)
```rust
use axum::{
    extract::State,
    http::{HeaderMap, StatusCode},
    routing::post,
    Json, Router,
};
use serde::{Deserialize, Serialize};
use std::net::SocketAddr;
use tracing::{error, info};

#[derive(Clone)]
struct AppState {
    frontend_token: String,
    // Add db pool and storage client here when wiring real deps.
    // db: deadpool_postgres::Pool,
    // gcs: google_cloud_storage::client::Client,
}

#[derive(Deserialize)]
#[serde(tag = "type")]
enum EventRequest {
    #[serde(rename = "tip")]
    Tip(TipEvent),
    #[serde(rename = "join")]
    Join(JoinEvent),
}

#[derive(Deserialize)]
struct TipEvent {
    from_player_uuid: String,
    to_player_uuid: String,
    amount: String,
    world: String,
    server_label: String,
}

#[derive(Deserialize)]
struct JoinEvent {
    player_uuid: String,
    world: String,
}

#[derive(Serialize)]
struct EventResponse {
    ok: bool,
    message: String,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .init();

    let port = std::env::var("PORT").unwrap_or_else(|_| "8080".into());
    let addr: SocketAddr = format!("0.0.0.0:{port}").parse()?;

    let frontend_token =
        std::env::var("FRONTEND_TOKEN").expect("FRONTEND_TOKEN must be set");

    let state = AppState {
        frontend_token,
    };

    let app = Router::new()
        .route("/v1/events/tip", post(handle_tip))
        .route("/v1/events/join", post(handle_join))
        .with_state(state);

    info!("listening on {addr}");
    axum::Server::bind(&addr)
        .serve(app.into_make_service())
        .await?;
    Ok(())
}

async fn handle_tip(
    State(state): State<AppState>,
    headers: HeaderMap,
    Json(payload): Json<TipEvent>,
) -> Result<Json<EventResponse>, (StatusCode, String)> {
    authorize(&state, &headers)?;

    // TODO: validate amount, check limits, write ledger to DB, enqueue Ω FS update.
    info!(
        "[tip] from={} to={} amount={} world={} label={}",
        payload.from_player_uuid,
        payload.to_player_uuid,
        payload.amount,
        payload.world,
        payload.server_label
    );

    Ok(Json(EventResponse {
        ok: true,
        message: "tip accepted".into(),
    }))
}

async fn handle_join(
    State(state): State<AppState>,
    headers: HeaderMap,
    Json(payload): Json<JoinEvent>,
) -> Result<Json<EventResponse>, (StatusCode, String)> {
    authorize(&state, &headers)?;

    info!("[join] player={} world={}", payload.player_uuid, payload.world);

    Ok(Json(EventResponse {
        ok: true,
        message: "join recorded".into(),
    }))
}

fn authorize(state: &AppState, headers: &HeaderMap) -> Result<(), (StatusCode, String)> {
    let incoming = headers
        .get("X-Frontend-Token")
        .and_then(|v| v.to_str().ok())
        .unwrap_or("");
    if incoming != state.frontend_token {
        return Err((StatusCode::UNAUTHORIZED, "bad token".into()));
    }
    Ok(())
}
```

## Dockerfile (Cloud Run)
```dockerfile
FROM rust:1.75-slim AS builder
WORKDIR /app
COPY Cargo.toml Cargo.lock ./
COPY src ./src
RUN apt-get update && apt-get install -y pkg-config libssl-dev && \
    cargo build --release

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /app/target/release/dlog-api /usr/local/bin/dlog-api
ENV PORT=8080
CMD ["/usr/local/bin/dlog-api"]
```

If you use the Cloud SQL Auth Proxy sidecar, add it in the final stage and start both processes with a tiny supervisor script. Otherwise, point `DATABASE_URL` at the proxy endpoint provided by Cloud Run (see Cloud SQL connector docs).

## Cloud Run deploy (example)
```
gcloud builds submit --tag gcr.io/PROJECT_ID/dlog-api
gcloud run deploy dlog-api \
  --image gcr.io/PROJECT_ID/dlog-api \
  --platform managed \
  --region REGION \
  --allow-unauthenticated \
  --set-env-vars FRONTEND_TOKEN=... \
  --set-env-vars DATABASE_URL=... \
  --set-env-vars GCS_BUCKET=dlog-omega-root
```

Lock down ingress (internal and Cloud Load Balancer) if you do not want public HTTP; restrict by IP or require IAM auth.

## Wiring to Cloud SQL and GCS (sketch)
- **Cloud SQL (Postgres)**: run the Cloud SQL Auth Proxy as a sidecar or use the Cloud SQL connector; set `DATABASE_URL` to `postgres://user:pass@127.0.0.1:5432/db`. Add a `deadpool_postgres` pool in `AppState` and perform ledger writes inside handlers.
- **GCS**: create a `google_cloud_storage::client::Client` in `AppState`. For Ω FS updates, write objects like `∞/;∞;∞;∞;∞;∞;∞;∞;∞;∞;` (9∞ root) and per-label files `;phone;label;∞;∞;∞;∞;∞;∞;∞;∞;hash;`. Ensure the Cloud Run service account has `storage.objectAdmin` scoped to the bucket.

## Security notes
- Always check `X-Frontend-Token`.
- Consider adding an `X-Server-Label` and validating against an allowlist.
- Set reasonable timeouts on HTTP clients if you fan out from this service.
- If public, add a basic rate limit (tower-http) or put Cloud Armor in front.

## Local dev
- Run `cargo run` with `FRONTEND_TOKEN=dev` and hit `http://localhost:8080/v1/events/tip` with a JSON body matching the Paper plugin.
- Use `PORT=8080 FRONTEND_TOKEN=dev cargo run` for parity with Cloud Run expectations.
