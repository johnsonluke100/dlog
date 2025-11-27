use axum::{
    extract::{Query, State},
    routing::{get, post},
    Json, Router,
};
use dlog_core::init_universe;
use dlog_corelib::{UniverseError, UniverseState};
use dlog_spec::{
    AccessGrant, AccessRole, Address, Amount, AirdropNetworkRules, BlockHeight, DeviceLimitsRules,
    FlightLawConfig, GenesisConfig, GiftRules, LabelUniverseHash, LabelUniverseKey, LandAuctionRules,
    LandGridCoord, LandLock, LandTier, MonetaryPolicy, OmegaFilesystemSnapshot, OmegaMasterRoot,
    PlanetId, SolarSystemConfig,
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
    // This is the "real-world tick" you talked about:
    //   - One block ≈ one attention sweep through the active universe.
    //   - Here we approximate it as once every 8 seconds.
    //
    // The internal PHI_TICK_HZ is free to be much higher for micro-steps;
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
