use axum::{
    extract::State,
    extract::ws::{Message, WebSocket, WebSocketUpgrade},
    http::{HeaderMap, StatusCode},
    response::IntoResponse,
    routing::{get, post},
    Json, Router,
};
use futures::{SinkExt, StreamExt};
use serde::{Deserialize, Serialize};
use spec::{MonetarySpec, PlanetGravityProfile, PLANET_PROFILES, PHI};
use std::{net::SocketAddr, time::Duration};
use tokio::{
    io::{AsyncReadExt, AsyncWriteExt},
    net::{TcpListener, TcpStream},
    time::timeout,
};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[derive(Clone)]
struct AppState {
    paper_addr: SocketAddr,
}

impl AppState {
    fn from_env() -> Self {
        let host = std::env::var("PAPER_HOST").unwrap_or_else(|_| "127.0.0.1".to_string());
        let port = std::env::var("PAPER_PORT")
            .ok()
            .and_then(|p| p.parse::<u16>().ok())
            .unwrap_or(25565);

        let paper_addr = format!("{host}:{port}")
            .parse::<SocketAddr>()
            .expect("valid PAPER_HOST + PAPER_PORT");

        Self { paper_addr }
    }
}

#[tokio::main]
async fn main() {
    init_tracing();

    let state = AppState::from_env();

    let app = Router::new()
        .route("/", get(root))
        .route("/health", get(health))
        .route("/v1/hypercube/summary", get(hypercube))
        .route("/v1/spec/monetary", get(monetary))
        .route("/v1/spec/planets", get(planets))
        .route("/v1/paper/status", get(paper_status))
        .route("/ws/paper", get(ws_paper))
        // Bridge for the Minecraft plugin → Rust control loop.
        .route("/tick", post(tick))
        .with_state(state.clone());

    // 8888 here is just a human-friendly port; underneath it's all bits anyway.
    let addr = listen_addr();
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

async fn root(State(state): State<AppState>) -> Json<serde_json::Value> {
    Json(serde_json::json!({
        "status": "ok",
        "phi": PHI,
        "message": "Ω-heartbeat online",
        "paper_backend": state.paper_addr.to_string(),
        "endpoints": [
            "/health",
            "/v1/hypercube/summary",
            "/v1/spec/monetary",
            "/v1/spec/planets",
            "/v1/paper/status",
            "/ws/paper",
            "/tick"
        ]
    }))
}

async fn health() -> Json<serde_json::Value> {
    Json(serde_json::json!({
        "status": "ok",
        "phi": PHI,
        "message": "Ω-heartbeat online"
    }))
}

fn listen_addr() -> SocketAddr {
    let port = std::env::var("PORT")
        .ok()
        .and_then(|p| p.parse::<u16>().ok())
        .unwrap_or(8888);

    SocketAddr::from(([0, 0, 0, 0], port))
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

// === Hypercube summary ===

#[derive(Serialize)]
struct HypercubeSummary {
    title: &'static str,
    sections: Vec<SummarySection>,
}

#[derive(Serialize)]
struct SummarySection {
    heading: &'static str,
    points: &'static [&'static str],
}

async fn hypercube() -> Json<HypercubeSummary> {
    Json(HypercubeSummary {
        title: "DLOG / Ω-Physics / Golden Wallet / Canon Spec v3 (hypercube summary)",
        sections: vec![
            SummarySection {
                heading: "Meta layers",
                points: &[
                    "NPC layer uses mainstream physics (seconds, meters) only when explicitly asked.",
                    "Ω layer is default: attention-driven time, phi as the core constant, base-8 rhythms.",
                ],
            },
            SummarySection {
                heading: "Coin and identity",
                points: &[
                    "DLOG is for self-investment and play, not fear-based scarcity.",
                    "Login via Apple or Google with biometrics; keys stay in device keystores; server sees signatures only.",
                    "No seed phrases for normal flows; SMS is never the only factor for critical moves.",
                ],
            },
            SummarySection {
                heading: "Golden Wallet Stack",
                points: &[
                    "Backed by three golden rivers (XAUT, BTC, DOGE) spread across 256 keys each.",
                    "Infinity Bank with Double Infinity Shield so no single actor can drain backing.",
                    "Luke is lore-level wealthy; focus is safe sharing and play.",
                ],
            },
            SummarySection {
                heading: "Monetary policy",
                points: &[
                    "Holder interest ~61.8% APY; miner inflation ~8.8248% APY; combined ~70% yearly expansion.",
                    "Per-block factors use phi curves; supply is intentionally expansive.",
                    "Blocks track attention cycles; humans can approximate as ~8 seconds.",
                ],
            },
            SummarySection {
                heading: "VORTEX, COMET, labels",
                points: &[
                    "Seven VORTEX wells plus one COMET wallet form the top genesis set (88,248 wallets total).",
                    "Labels map to phone numbers off-chain; each label is an Omega root with its own key.",
                    "Miners pay a small tithe to fill COMET; overflow flows into VORTEX wells.",
                ],
            },
            SummarySection {
                heading: "Filesystem",
                points: &[
                    "Universe encoded via 9∞ master root; each block unfolds and refolds state.",
                    "Per-label files use semicolon-delimited segments; dots are avoided in filenames and contents.",
                ],
            },
            SummarySection {
                heading: "Airdrops and gifts",
                points: &[
                    "88,248 genesis wallets; user airdrops decay on a phi curve.",
                    "Anti-farm: one per phone, Apple/Google ID, and public IP; VPN/datacenter IPs blocked.",
                    "Gifts are locked ~17 days; sending unlocks with phi-shaped limits after day 18.",
                ],
            },
            SummarySection {
                heading: "Land and game feel",
                points: &[
                    "Hollow planets (Earth, Moon, Mars, Sun) with shell/core inversion teleports.",
                    "Lock tiers: iron, gold, diamond, emerald; inactivity ~256 days triggers auction.",
                    "Movement mixes Minecraft sandbox with CS:GO bhop/surf tuned by phi exponents per planet.",
                ],
            },
            SummarySection {
                heading: "Hosting and rails",
                points: &[
                    "Each static IP is eight Omega rails; scaling adds rails (attention lanes).",
                    "Rust-first workspace with spec/corelib/core/api as anchors; refold.command reshapes the tree.",
                ],
            },
        ],
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

// === Paper shim (HTTP/WS bridge) ===

async fn paper_status(State(state): State<AppState>) -> Json<serde_json::Value> {
    let addr = state.paper_addr;
    let online = timeout(Duration::from_secs(2), TcpStream::connect(addr))
        .await
        .ok()
        .and_then(|res| res.ok())
        .is_some();

    Json(serde_json::json!({
        "address": addr.to_string(),
        "online": online,
    }))
}

async fn ws_paper(
    State(state): State<AppState>,
    ws: WebSocketUpgrade,
) -> impl IntoResponse {
    let addr = state.paper_addr;
    ws.on_upgrade(move |socket| handle_ws(socket, addr))
}

async fn handle_ws(socket: WebSocket, paper_addr: SocketAddr) {
    tracing::info!("ws bridge connecting to Paper backend at {}", paper_addr);

    match TcpStream::connect(paper_addr).await {
        Ok(backend) => {
            if let Err(err) = pipe_ws_to_tcp(socket, backend).await {
                tracing::warn!("ws bridge error: {}", err);
            }
        }
        Err(err) => {
            tracing::warn!("failed to connect to Paper backend {}: {}", paper_addr, err);
        }
    }
}

async fn pipe_ws_to_tcp(
    socket: WebSocket,
    backend: TcpStream,
) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    let (mut ws_tx, mut ws_rx) = socket.split();
    let (mut tcp_reader, mut tcp_writer) = backend.into_split();

    let to_tcp = async {
        while let Some(msg) = ws_rx.next().await {
            let msg = msg?;
            match msg {
                Message::Binary(bytes) => {
                    tcp_writer.write_all(&bytes).await?;
                }
                Message::Text(text) => {
                    tcp_writer.write_all(text.as_bytes()).await?;
                    tcp_writer.write_all(b"\n").await?;
                }
                Message::Close(_) => break,
                Message::Ping(_) | Message::Pong(_) => {}
            }
        }
        let _ = tcp_writer.shutdown().await;
        Ok::<(), Box<dyn std::error::Error + Send + Sync>>(())
    };

    let to_ws = async {
        let mut buf = [0u8; 4096];
        loop {
            let n = tcp_reader.read(&mut buf).await?;
            if n == 0 {
                break;
            }
            ws_tx.send(Message::Binary(buf[..n].to_vec())).await?;
        }
        let _ = ws_tx.send(Message::Close(None)).await;
        Ok::<(), Box<dyn std::error::Error + Send + Sync>>(())
    };

    tokio::select! {
        res = to_tcp => { res?; }
        res = to_ws => { res?; }
    }

    Ok(())
}
