use axum::{routing::{get, post}, Json, Router};
use axum::http::{HeaderMap, StatusCode};
use tokio::net::TcpListener;
use serde::{Deserialize, Serialize};
use spec::{MonetarySpec, PlanetGravityProfile, PLANET_PROFILES, PHI};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[tokio::main]
async fn main() {
    init_tracing();

    let app = Router::new()
        .route("/health", get(health))
        .route("/v1/spec/monetary", get(monetary))
        .route("/v1/spec/planets", get(planets))
        // Bridge for the Minecraft plugin → Rust control loop.
        .route("/tick", post(tick));

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

// === Ω tick bridge ===

#[derive(Debug, Deserialize)]
struct TickRequest {
    #[serde(default)]
    entities: Vec<EntityState>,
}

#[allow(dead_code)]
#[derive(Debug, Deserialize)]
struct EntityState {
    armor_stand_id: String,
    #[serde(default)]
    player_id: Option<String>,
    #[serde(default)]
    world_id: Option<String>,
    #[serde(default)]
    pos: Vec3,
    #[serde(default)]
    vel: Vec3,
    #[serde(default)]
    input: InputState,
}

#[derive(Debug, Deserialize, Default)]
struct InputState {
    #[serde(default)]
    forward: bool,
    #[serde(default)]
    back: bool,
    #[serde(default)]
    left: bool,
    #[serde(default)]
    right: bool,
    #[serde(default)]
    jump: bool,
    #[serde(default)]
    sneak: bool,
}

#[derive(Debug, Deserialize, Serialize, Default, Clone, Copy)]
struct Vec3 {
    #[serde(default)]
    x: f64,
    #[serde(default)]
    y: f64,
    #[serde(default)]
    z: f64,
}

#[derive(Debug, Serialize)]
struct TickResponse {
    updates: Vec<EntityUpdate>,
}

#[derive(Debug, Serialize)]
struct EntityUpdate {
    armor_stand_id: String,
    pos: Vec3,
    vel: Vec3,
}

async fn tick(headers: HeaderMap, axum::extract::Json(req): axum::extract::Json<TickRequest>) -> Result<Json<TickResponse>, StatusCode> {
    // Optional auth: set OMEGA_TICK_TOKEN to require X-Auth-Token header.
    if let Ok(expected) = std::env::var("OMEGA_TICK_TOKEN") {
        let ok = headers
            .get("x-auth-token")
            .and_then(|v| v.to_str().ok())
            .map(|v| v == expected)
            .unwrap_or(false);
        if !ok {
            return Err(StatusCode::UNAUTHORIZED);
        }
    }

    // Simple physics step tuned for the Ω bridge. Replace with richer φ-based logic later.
    const DT: f64 = 0.05; // 20 ticks/sec
    const ACCEL: f64 = 0.08;
    const JUMP_SPEED: f64 = 0.32;
    const GRAVITY: f64 = 0.08;

    let mut updates = Vec::with_capacity(req.entities.len());

    for mut e in req.entities {
        // Apply input -> velocity
        if e.input.forward {
            e.vel.z += ACCEL;
        }
        if e.input.back {
            e.vel.z -= ACCEL;
        }
        if e.input.right {
            e.vel.x += ACCEL;
        }
        if e.input.left {
            e.vel.x -= ACCEL;
        }
        if e.input.jump {
            // naive jump; real impl should check ground contact
            e.vel.y = JUMP_SPEED;
        }
        if e.input.sneak {
            e.vel.y -= ACCEL * 0.5;
        }

        // Gravity
        e.vel.y -= GRAVITY * DT;

        // Integrate
        e.pos.x += e.vel.x * DT;
        e.pos.y += e.vel.y * DT;
        e.pos.z += e.vel.z * DT;

        updates.push(EntityUpdate {
            armor_stand_id: e.armor_stand_id,
            pos: e.pos,
            vel: e.vel,
        });
    }

    Ok(Json(TickResponse { updates }))
}
