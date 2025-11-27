use axum::{
    extract::{Query, State},
    routing::{get, post},
    Json, Router,
};
use dlog_core::init_universe;
use dlog_corelib::{UniverseError, UniverseState};
use dlog_spec::{
    AccessGrant, AccessRole, Address, Amount, AirdropNetworkRules, BlockHeight, DeviceLimitsRules,
    FlightLawConfig, GenesisConfig, GiftRules, LabelUniverseHash, LabelUniverseKey,
    LandAuctionRules, LandGridCoord, LandLock, LandTier, MonetaryPolicy, OmegaFilesystemSnapshot,
    OmegaMasterRoot, PlanetId, SolarSystemConfig,
};
use dlog_sky::SkyTimeline;
use serde::{Deserialize, Serialize};
use std::{
    net::SocketAddr,
    sync::{Arc, Mutex},
    time::{SystemTime, UNIX_EPOCH},
};
use tokio::time::{interval, Duration};
use tracing_subscriber::EnvFilter;

const PHI: f64 = 1.618_033_988_749_895_f64;

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

#[derive(Serialize)]
struct TickOnceResponse {
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

#[derive(Serialize)]
struct MoneyPolicyResponse {
    policy: MonetaryPolicy,
    approx_total_apy: f64,
}

#[derive(Serialize)]
struct GiftRulesResponse {
    rules: GiftRules,
    examples: Vec<GiftCapExample>,
}

#[derive(Serialize)]
struct GiftCapExample {
    days_since_claim: u32,
    daily_cap_dlog: u64,
}

#[derive(Deserialize)]
struct GiftCapQuery {
    days_since_claim: u32,
}

#[derive(Serialize)]
struct GiftCapResponse {
    days_since_claim: u32,
    daily_cap_dlog: u64,
}

#[derive(Deserialize)]
struct DeviceCapQuery {
    days_since_enroll: u32,
}

#[derive(Serialize)]
struct DeviceCapResponse {
    days_since_enroll: u32,
    daily_cap_dlog: u64,
}

#[derive(Serialize)]
struct GenesisRootsResponse {
    genesis: GenesisConfig,
    airdrop_network: AirdropNetworkRules,
}

#[derive(Serialize)]
struct OmegaRootResponse {
    height: BlockHeight,
    snapshot: OmegaFilesystemSnapshot,
}

#[derive(Serialize)]
struct AirdropNetworkResponse {
    rules: AirdropNetworkRules,
}

#[derive(Serialize)]
struct LandAuctionRulesResponse {
    rules: LandAuctionRules,
}

#[derive(Serialize)]
struct SolarSystemResponse {
    system: SolarSystemConfig,
}

#[derive(Serialize)]
struct FlightLawResponse {
    law: FlightLawConfig,
}

#[derive(Serialize)]
struct LandAdjacencyExampleResponse {
    a: LandGridCoord,
    b: LandGridCoord,
    c: LandGridCoord,
    ab_adjacent: bool,
    ac_adjacent: bool,
}

#[derive(Serialize)]
struct PlanetGravityRow {
    planet: String,
    phi_exponent: f64,
    accel_per_tick: f64,
    accel_per_frame_60fps: f64,
    accel_per_frame_144fps: f64,
    accel_per_frame_1000fps: f64,
}

#[derive(Serialize)]
struct PlanetGravityTableResponse {
    phi: f64,
    server_ticks_per_second: f64,
    rows: Vec<PlanetGravityRow>,
}

/// One Leidenfrost flame channel (north/east/south/west) in Ω-space.
#[derive(Serialize)]
struct FlameChannel {
    /// Human name: "north", "east", "south", "west".
    name: String,
    /// 0..3 index for the channel.
    index: u8,
    /// 3D position in some local Ω-space (e.g. above the player / world).
    position: [f32; 3],
    /// Phase in radians (φ-driven, time-based).
    phase: f64,
    /// Normalized intensity in [0,1] (for audio gain, shader brightness, etc.).
    intensity: f32,
}

/// Full Ω flames snapshot.
#[derive(Serialize)]
struct OmegaFlamesResponse {
    phi: f64,
    tick_hz: f64,
    channels: Vec<FlameChannel>,
}

/// Query for /flight/tuning
#[derive(Deserialize)]
struct FlightTuningQuery {
    /// Client FPS, e.g. 60, 120, 144, 1000.
    fps: f64,
    /// Planet key, e.g. "earth_shell", "moon_shell", "mars_shell", "sun_shell".
    planet: String,
}

/// Response for /flight/tuning
#[derive(Serialize)]
struct FlightTuningResponse {
    phi: f64,
    server_ticks_per_second: f64,
    fps: f64,
    planet: String,
    /// φ-exponent used for this planet.
    phi_exponent: f64,
    /// Acceleration per server tick (1000 Hz basis).
    accel_per_tick: f64,
    /// Acceleration per rendered frame on this client.
    accel_per_frame: f64,
    /// Suggested "ticks per frame" factor (for clients that want to simulate server ticks).
    suggested_ticks_per_frame: f64,
}

/// Platform kinds for clients that can attach to the DLOG universe.
#[derive(Serialize)]
#[serde(rename_all = "snake_case")]
enum ClientPlatform {
    JavaPc,
    BedrockMobile,
    Xbox,
    Playstation,
    Web,
}

/// Implementation status for each platform.
#[derive(Serialize)]
#[serde(rename_all = "snake_case")]
enum ClientStatus {
    NotReady,
    Prototype,
    Alpha,
    Live,
}

/// One row in the clients manifest.
#[derive(Serialize)]
struct ClientCapability {
    platform: ClientPlatform,
    status: ClientStatus,
    supports_dlog_tips: bool,
    supports_land_locks: bool,
    supports_crossplay: bool,
    notes: String,
}

/// Response for GET /clients
#[derive(Serialize)]
struct ClientsResponse {
    phi: f64,
    heartbeat_hz: f64,
    entries: Vec<ClientCapability>,
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .with_env_filter(
            EnvFilter::from_default_env().add_directive("dlog_api=info".parse().unwrap()),
        )
        .init();

    let addr: SocketAddr = "127.0.0.1:8888".parse().expect("valid socket addr");

    let universe = init_universe();
    let tick_hz = universe.config.phi_tick_hz;

    let state = AppState {
        universe: Arc::new(Mutex::new(universe)),
        sky: Arc::new(Mutex::new(SkyTimeline::default_eight())),
    };

    // -----------------------------
    // Background block ticker (Ω heartbeat)
    // -----------------------------
    //
    // This is the "real-world tick":
    //   - One block ≈ one attention sweep through the active universe.
    //   - Here we approximate it as once every 8 seconds.
    //
    // The internal PHI_TICK_HZ can be much higher for micro-steps;
    // this ticker is the big block heartbeat.
    let ticker_state = state.clone();
    let block_interval_secs = 8.0; // block ≈ 8 seconds, human-friendly

    tokio::spawn(async move {
        let mut iv = interval(Duration::from_secs_f64(block_interval_secs));
        loop {
            iv.tick().await;
            let mut universe = ticker_state
                .universe
                .lock()
                .expect("universe lock poisoned (ticker)");
            universe.tick_block();
            let h = universe.height;
            drop(universe);
            tracing::info!("Ω heartbeat: advanced universe to height={}", h);
        }
    });

    let app = Router::new()
        .route("/health", get(health))
        .route("/height", get(height))
        .route("/tick/once", post(tick_once))
        .route("/transfer", post(transfer))
        .route("/sky/current", get(sky_current))
        .route("/policy/money", get(money_policy))
        .route("/airdrop/gift/rules", get(gift_rules))
        .route("/airdrop/gift/daily_cap", get(gift_daily_cap))
        .route("/airdrop/network", get(airdrop_network))
        .route("/device/daily_cap", get(device_daily_cap))
        .route("/land/example_lock", get(land_example_lock))
        .route("/land/auction/rules", get(land_auction_rules))
        .route("/land/adjacent_example", get(land_adjacency_example))
        .route("/genesis/roots", get(genesis_roots))
        .route("/omega/root", get(omega_root))
        .route("/solar/system", get(solar_system))
        .route("/flight/law", get(flight_law))
        .route("/flight/planet_gravity_table", get(planet_gravity_table))
        .route("/flight/tuning", get(flight_tuning))
        .route("/omega/flames", get(omega_flames))
        .route("/clients", get(clients_manifest))
        .with_state(state);

    tracing::info!(
        "dlog-api listening on http://{addr} (phi_tick_hz={} | block_interval≈{}s)",
        tick_hz,
        block_interval_secs
    );
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

async fn tick_once(State(state): State<AppState>) -> Json<TickOnceResponse> {
    let mut universe = state.universe.lock().expect("universe lock poisoned");
    universe.tick_block();
    let height = universe.height;
    Json(TickOnceResponse { height })
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

async fn money_policy() -> Json<MoneyPolicyResponse> {
    let policy = MonetaryPolicy::default();
    Json(MoneyPolicyResponse {
        approx_total_apy: policy.total_apy(),
        policy,
    })
}

async fn gift_rules() -> Json<GiftRulesResponse> {
    let rules = GiftRules::default();
    let examples = vec![0_u32, 1, 17, 18, 19, 20, 30]
        .into_iter()
        .map(|d| GiftCapExample {
            days_since_claim: d,
            daily_cap_dlog: rules.daily_cap(d),
        })
        .collect();

    Json(GiftRulesResponse { rules, examples })
}

async fn gift_daily_cap(Query(q): Query<GiftCapQuery>) -> Json<GiftCapResponse> {
    let rules = GiftRules::default();
    let cap = rules.daily_cap(q.days_since_claim);
    Json(GiftCapResponse {
        days_since_claim: q.days_since_claim,
        daily_cap_dlog: cap,
    })
}

async fn airdrop_network() -> Json<AirdropNetworkResponse> {
    let rules = AirdropNetworkRules::default();
    Json(AirdropNetworkResponse { rules })
}

async fn device_daily_cap(Query(q): Query<DeviceCapQuery>) -> Json<DeviceCapResponse> {
    let rules = DeviceLimitsRules::default();
    let cap = rules.daily_cap(q.days_since_enroll);
    Json(DeviceCapResponse {
        days_since_enroll: q.days_since_enroll,
        daily_cap_dlog: cap,
    })
}

async fn land_example_lock() -> Json<LandLock> {
    let lock = LandLock {
        id: 1,
        owner_phone: "9132077554".to_string(),
        world: PlanetId::EarthShell,
        tier: LandTier::Emerald,
        x: 0,
        z: 0,
        size: 16,
        created_at_block: 0,
        last_visited_block: 0,
        zillow_estimate_dlog: 1_000_000,
        shared_with: vec![AccessGrant {
            player_id: "friend_player_id".to_string(),
            role: AccessRole::Builder,
        }],
        in_auction: false,
    };
    Json(lock)
}

async fn land_auction_rules() -> Json<LandAuctionRulesResponse> {
    let rules = LandAuctionRules::default();
    Json(LandAuctionRulesResponse { rules })
}

async fn land_adjacency_example() -> Json<LandAdjacencyExampleResponse> {
    let a = LandGridCoord { x: 0, z: 0 };
    let b = LandGridCoord { x: 1, z: 0 }; // shares edge with a
    let c = LandGridCoord { x: 2, z: 2 }; // not adjacent to a
    let ab_adjacent = a.is_adjacent_to(&b);
    let ac_adjacent = a.is_adjacent_to(&c);

    Json(LandAdjacencyExampleResponse {
        a,
        b,
        c,
        ab_adjacent,
        ac_adjacent,
    })
}

async fn genesis_roots() -> Json<GenesisRootsResponse> {
    let genesis = GenesisConfig::canon();
    let network = AirdropNetworkRules::default();
    Json(GenesisRootsResponse {
        genesis,
        airdrop_network: network,
    })
}

async fn omega_root(State(state): State<AppState>) -> Json<OmegaRootResponse> {
    let universe = state.universe.lock().expect("universe lock poisoned");
    let height = universe.height;

    let master_root = OmegaMasterRoot {
        scalar: ";∞;∞;∞;∞;∞;∞;∞;∞;∞;".to_string(),
    };

    let comet_key = LabelUniverseKey {
        phone: "9132077554".to_string(),
        label: "comet".to_string(),
    };
    let fun_key = LabelUniverseKey {
        phone: "9132077554".to_string(),
        label: "fun".to_string(),
    };

    let label_hashes = vec![
        LabelUniverseHash {
            key: comet_key,
            hash: "omega_hash_comet_v1".to_string(),
        },
        LabelUniverseHash {
            key: fun_key,
            hash: "omega_hash_fun_v1".to_string(),
        },
    ];

    let snapshot = OmegaFilesystemSnapshot {
        master_root,
        label_hashes,
    };

    Json(OmegaRootResponse { height, snapshot })
}

async fn solar_system() -> Json<SolarSystemResponse> {
    let system = SolarSystemConfig::canon();
    Json(SolarSystemResponse { system })
}

async fn flight_law() -> Json<FlightLawResponse> {
    let law = FlightLawConfig::canon();
    Json(FlightLawResponse { law })
}

async fn planet_gravity_table() -> Json<PlanetGravityTableResponse> {
    // Canonical Ω "real-world" tick rate:
    // server-side heartbeat is pegged at 1000 Hz.
    let server_tps = 1000.0_f64;

    let make_row = |planet: &str, phi_exponent: f64| {
        let accel_per_tick = PHI.powf(phi_exponent);
        let accel_per_frame_60 = accel_per_tick * (server_tps / 60.0);
        let accel_per_frame_144 = accel_per_tick * (server_tps / 144.0);
        let accel_per_frame_1000 = accel_per_tick * (server_tps / 1000.0);

        PlanetGravityRow {
            planet: planet.to_string(),
            phi_exponent,
            accel_per_tick,
            accel_per_frame_60fps: accel_per_frame_60,
            accel_per_frame_144fps: accel_per_frame_144,
            accel_per_frame_1000fps: accel_per_frame_1000,
        }
    };

    // Lore picks (φ^?-per-tick per planet):
    // - Sun_shell: heaviest pull
    // - Earth_shell: baseline 1.0
    // - Moon_shell: floaty
    // - Mars_shell: between Moon and Earth
    let rows = vec![
        make_row("Sun_shell", 1.5),
        make_row("Earth_shell", 1.0),
        make_row("Moon_shell", 0.4),
        make_row("Mars_shell", 0.8),
    ];

    Json(PlanetGravityTableResponse {
        phi: PHI,
        server_ticks_per_second: server_tps,
        rows,
    })
}

/// Δv / frame tuning for a client given FPS + planet.
///
/// This is the bridge you described:
/// - Server has a canonical tick rate (1000 Hz basis).
/// - Each planet has a φ^k-per-tick gravity / flight scale.
/// - Each client asks: "I run at N FPS; how much accel per frame should I use so it *feels* like Ω?"
async fn flight_tuning(Query(q): Query<FlightTuningQuery>) -> Json<FlightTuningResponse> {
    // Canonical "real-world" server tick rate for flight math.
    let server_tps = 1000.0_f64;

    let fps = if q.fps <= 0.0 { 60.0 } else { q.fps };

    // Map string → φ exponent. We keep it simple and mirror the table.
    let (planet_key, phi_exponent) = match q.planet.to_lowercase().as_str() {
        "earth" | "earth_shell" => ("earth_shell".to_string(), 1.0),
        "moon" | "moon_shell" => ("moon_shell".to_string(), 0.4),
        "mars" | "mars_shell" => ("mars_shell".to_string(), 0.8),
        "sun" | "sun_shell" => ("sun_shell".to_string(), 1.5),
        other => (other.to_string(), 1.0),
    };

    // Accel per server tick at 1000 Hz.
    let accel_per_tick = PHI.powf(phi_exponent);

    // If a client simulates exactly server_tps / fps ticks per rendered frame,
    // this is the factor they'd multiply by in their integration.
    let suggested_ticks_per_frame = server_tps / fps;
    let accel_per_frame = accel_per_tick * suggested_ticks_per_frame;

    Json(FlightTuningResponse {
        phi: PHI,
        server_ticks_per_second: server_tps,
        fps,
        planet: planet_key,
        phi_exponent,
        accel_per_tick,
        accel_per_frame,
        suggested_ticks_per_frame,
    })
}

/// Ω flames endpoint: 4 phi-synced channels, straight up in 3D.
/// This is the Rust reflection of your old omega_numpy_container's four flames.
async fn omega_flames(State(state): State<AppState>) -> Json<OmegaFlamesResponse> {
    let universe = state.universe.lock().expect("universe lock poisoned");
    let tick_hz = universe.config.phi_tick_hz;
    drop(universe);

    let now = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default();
    let t = now.as_secs_f64();

    let two_pi = std::f64::consts::PI * 2.0;

    // Channel layout: four cardinal flames around the observer, all pointing "up":
    let defs: &[(u8, &str, [f32; 3])] = &[
        (0, "north", [0.0, 1.0, -1.0]),
        (1, "east", [1.0, 1.0, 0.0]),
        (2, "south", [0.0, 1.0, 1.0]),
        (3, "west", [-1.0, 1.0, 0.0]),
    ];

    let mut channels = Vec::with_capacity(defs.len());
    for (idx, name, pos) in defs.iter().copied() {
        // φ-driven phase: time * PHI plus quarter-turn offsets per channel.
        let phase = two_pi * (t * PHI + (idx as f64) / 4.0);
        // Fold sin wave into [0,1] as intensity.
        let intensity = ((phase.sin() + 1.0) * 0.5) as f32;

        channels.push(FlameChannel {
            name: name.to_string(),
            index: idx,
            position: pos,
            phase,
            intensity,
        });
    }

    Json(OmegaFlamesResponse {
        phi: PHI,
        tick_hz,
        channels,
    })
}

/// Clients manifest: describes Java/Bedrock/Xbox/Playstation/Web support.
///
/// Right now: everything is "not_ready" (truthful),
/// but the node itself knows what species of clients it intends to serve.
async fn clients_manifest(State(state): State<AppState>) -> Json<ClientsResponse> {
    let universe = state.universe.lock().expect("universe lock poisoned");
    let tick_hz = universe.config.phi_tick_hz;
    drop(universe);

    let entries = vec![
        ClientCapability {
            platform: ClientPlatform::JavaPc,
            status: ClientStatus::NotReady,
            supports_dlog_tips: false,
            supports_land_locks: false,
            supports_crossplay: false,
            notes: "Minecraft Java plugin planned (Paper/Spigot bridge into DLOG node).".to_string(),
        },
        ClientCapability {
            platform: ClientPlatform::BedrockMobile,
            status: ClientStatus::NotReady,
            supports_dlog_tips: false,
            supports_land_locks: false,
            supports_crossplay: false,
            notes: "Bedrock/mobile via existing proxy stack + DLOG QR flows (future).".to_string(),
        },
        ClientCapability {
            platform: ClientPlatform::Xbox,
            status: ClientStatus::NotReady,
            supports_dlog_tips: false,
            supports_land_locks: false,
            supports_crossplay: false,
            notes: "Console entry via Bedrock path + phone biometrics (future).".to_string(),
        },
        ClientCapability {
            platform: ClientPlatform::Playstation,
            status: ClientStatus::NotReady,
            supports_dlog_tips: false,
            supports_land_locks: false,
            supports_crossplay: false,
            notes: "Same pattern as Xbox: Bedrock-style client + QR/web pairing (future).".to_string(),
        },
        ClientCapability {
            platform: ClientPlatform::Web,
            status: ClientStatus::NotReady,
            supports_dlog_tips: false,
            supports_land_locks: false,
            supports_crossplay: false,
            notes: "Browser/WebGL client that talks directly to dlog-api over HTTPS (future)."
                .to_string(),
        },
    ];

    Json(ClientsResponse {
        phi: PHI,
        heartbeat_hz: tick_hz,
        entries,
    })
}
