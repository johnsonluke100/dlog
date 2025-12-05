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
use spec::{
    Anchor, Barrier, InputState, MonetarySpec, PlanetGravityProfile, Pose, RenderEntity, SimTickRequest,
    SimTickResponse, SimView, UiOverlay, Vec3, PLANET_PROFILES, PHI,
};
use std::{
    net::SocketAddr,
    path::PathBuf,
    sync::Arc,
    time::{Duration, SystemTime, UNIX_EPOCH},
};
use tokio::{
    io::{AsyncReadExt, AsyncWriteExt},
    net::{TcpListener, TcpStream},
    time::timeout,
};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[derive(Clone)]
struct AppState {
    paper_addr: SocketAddr,
    sim_state_path: Arc<PathBuf>,
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

        let sim_state_path = std::env::var("SIM_STATE_PATH")
            .map(PathBuf::from)
            .unwrap_or_else(|_| PathBuf::from("/tmp/omega-sim-state.json"));

        Self {
            paper_addr,
            sim_state_path: Arc::new(sim_state_path),
        }
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
        .route("/v1/sim/tick", post(sim_tick))
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
            "/v1/sim/tick",
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

// === Ω sim tick (Cloud Run + GCS bucket state) ===

#[derive(Debug, Serialize, Deserialize)]
struct SimState {
    tick: u64,
    players: Vec<PlayerSnapshot>,
}

impl Default for SimState {
    fn default() -> Self {
        Self {
            tick: 0,
            players: Vec::new(),
        }
    }
}

#[derive(Debug, Serialize, Deserialize)]
struct PlayerSnapshot {
    player_id: String,
    pose: Pose,
    last_inputs: InputState,
}

async fn sim_tick(
    State(state): State<AppState>,
    Json(req): Json<SimTickRequest>,
) -> Result<Json<SimTickResponse>, StatusCode> {
    let mut sim = read_sim_state(&state.sim_state_path)
        .await
        .map_err(|err| {
            tracing::warn!("[sim] failed to read state: {}", err);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    sim.tick = sim.tick.wrapping_add(1);
    upsert_player(&mut sim, &req);

    write_sim_state(&state.sim_state_path, &sim)
        .await
        .map_err(|err| {
            tracing::warn!("[sim] failed to write state: {}", err);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    let view = build_view(&sim, &req);
    let server_time_ms = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_millis() as u64)
        .unwrap_or(0);

    Ok(Json(SimTickResponse {
        tick: sim.tick,
        state_version: format!("tick-{}", sim.tick),
        server_time_ms,
        view,
    }))
}

fn upsert_player(sim: &mut SimState, req: &SimTickRequest) {
    if let Some(existing) = sim
        .players
        .iter_mut()
        .find(|p| p.player_id == req.player_id)
    {
        existing.pose = req.pose;
        existing.last_inputs = req.inputs.clone();
        return;
    }

    sim.players.push(PlayerSnapshot {
        player_id: req.player_id.clone(),
        pose: req.pose,
        last_inputs: req.inputs.clone(),
    });
}

fn build_view(sim: &SimState, req: &SimTickRequest) -> SimView {
    let mut view = SimView::default();

    view.anchors.push(Anchor {
        id: "omega-root".to_string(),
        kind: "origin".to_string(),
        pos: Vec3 { x: 0.0, y: 64.0, z: 0.0 },
    });

    for player in &sim.players {
        view.entities.push(RenderEntity {
            id: format!("player-{}", player.player_id),
            kind: "player-shadow".to_string(),
            pos: player.pose.pos,
            yaw: player.pose.yaw,
            pitch: player.pose.pitch,
        });
    }

    // Minimal barrier hint at spawn platform; clients can render a 3x3 pad.
    view.barriers.push(Barrier {
        min: Vec3 { x: -1.0, y: 64.0, z: -1.0 },
        max: Vec3 { x: 1.0, y: 64.0, z: 1.0 },
    });

    view.ui = UiOverlay {
        title: "Ω void terminal".to_string(),
        hotbar: vec![
            "You are in the shared Ω simulation".to_string(),
            format!("Tick {}", sim.tick),
            format!("You reported: ({:.2},{:.2},{:.2})", req.pose.pos.x, req.pose.pos.y, req.pose.pos.z),
        ],
    };

    view
}

async fn read_sim_state(path: &PathBuf) -> Result<SimState, std::io::Error> {
    match tokio::fs::read(path).await {
        Ok(bytes) => {
            let parsed = serde_json::from_slice::<SimState>(&bytes).unwrap_or_default();
            Ok(parsed)
        }
        Err(err) if err.kind() == std::io::ErrorKind::NotFound => Ok(SimState::default()),
        Err(err) => Err(err),
    }
}

async fn write_sim_state(path: &PathBuf, sim: &SimState) -> Result<(), std::io::Error> {
    if let Some(parent) = path.parent() {
        tokio::fs::create_dir_all(parent).await?;
    }
    let data = serde_json::to_vec_pretty(sim).unwrap();
    tokio::fs::write(path, data).await
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

#[cfg(test)]
mod tests {
    use super::*;
    use axum::Json;
    use std::net::Ipv4Addr;
    use tempfile::tempdir;

    fn test_state(path: PathBuf) -> AppState {
        AppState {
            paper_addr: SocketAddr::from((Ipv4Addr::LOCALHOST, 25565)),
            sim_state_path: Arc::new(path),
        }
    }

    #[tokio::test]
    async fn sim_tick_persists_and_builds_view() {
        let dir = tempdir().unwrap();
        let state_path = dir.path().join("sim.json");
        let state = test_state(state_path.clone());

        let req = SimTickRequest {
            player_id: "player-1".to_string(),
            pose: Pose {
                pos: Vec3 { x: 1.0, y: 64.0, z: 2.0 },
                yaw: 90.0,
                pitch: 0.0,
            },
            ..Default::default()
        };

        let resp = sim_tick(State(state.clone()), Json(req.clone()))
            .await
            .expect("ok");
        let body: SimTickResponse = resp.0;
        assert_eq!(body.tick, 1);
        assert_eq!(body.view.entities.len(), 1);
        assert_eq!(body.view.entities[0].pos.x, 1.0);

        // Second tick should increment and persist state on disk.
        let resp2 = sim_tick(State(state.clone()), Json(req))
            .await
            .expect("ok");
        let body2: SimTickResponse = resp2.0;
        assert_eq!(body2.tick, 2);

        // Verify persisted file reflects tick 2.
        let disk_bytes = tokio::fs::read(state_path).await.unwrap();
        let disk_state: SimState = serde_json::from_slice(&disk_bytes).unwrap();
        assert_eq!(disk_state.tick, 2);
        assert_eq!(disk_state.players.len(), 1);
    }
}
