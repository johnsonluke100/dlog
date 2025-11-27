use std::{
    env,
    net::SocketAddr,
    sync::{Arc, RwLock},
};

use axum::{
    extract::State,
    routing::{get, post},
    Json, Router,
};
use serde::Serialize;
use tower_http::cors::CorsLayer;
use tracing::info;

/// Golden ratio – core Ω constant.
fn phi() -> f64 {
    1.618_033_988_749_894_8_f64
}

/* ========= Core App State ========= */

#[derive(Clone)]
struct AppState {
    universe: SharedUniverse,
    phi_tick_hz: f64,
}

type SharedUniverse = Arc<RwLock<UniverseInner>>;

#[derive(Debug)]
struct UniverseInner {
    block_height: u64,
    phi_tick_hz: f64,
    monetary_policy: MonetaryPolicy,
    gift_rules: GiftRules,
    airdrop_rules: AirdropNetworkRules,
    device_rules: DeviceOutflowRules,
    land_rules: LandRules,
    flight_rules: FlightRules,
    filesystem_rules: FilesystemRules,
    ethic_creed: EthicCreed,
}

impl UniverseInner {
    fn new() -> Self {
        let phi_val = phi();

        Self {
            block_height: 0,
            // “Real world” server heartbeat hint; client can sub-sample at FPS.
            phi_tick_hz: 1000.0,
            monetary_policy: MonetaryPolicy::dlog_default(),
            gift_rules: GiftRules::dlog_default(phi_val),
            airdrop_rules: AirdropNetworkRules::dlog_default(),
            device_rules: DeviceOutflowRules::dlog_default(phi_val),
            land_rules: LandRules::dlog_default(),
            flight_rules: FlightRules::dlog_default(phi_val),
            filesystem_rules: FilesystemRules::dlog_default(),
            ethic_creed: EthicCreed::dlog_default(),
        }
    }

    fn tick_once(&mut self) {
        self.block_height = self.block_height.saturating_add(1);
    }

    fn snapshot(&self) -> UniverseSnapshot {
        UniverseSnapshot {
            block_height: self.block_height,
            phi_tick_hz: self.phi_tick_hz,
            monetary_policy: self.monetary_policy.clone(),
            gift_rules: self.gift_rules.clone(),
            airdrop_rules: self.airdrop_rules.clone(),
            device_rules: self.device_rules.clone(),
            ethic_creed: self.ethic_creed.clone(),
        }
    }
}

/* ========= Monetary Policy ========= */

#[derive(Debug, Clone, Serialize)]
struct MonetaryPolicy {
    miner_inflation_apy: f64,
    holder_interest_apy: f64,
    total_expansion_apy: f64,
    block_time_seconds_hint: f64,
    notes: Vec<String>,
}

impl MonetaryPolicy {
    fn dlog_default() -> Self {
        let miner = 0.088_248_f64; // ~8.8248% miner firehose
        let holder = 0.618_f64; // 61.8% Ω-holder interest
        // Approx combined – not exact compounding math, but intuitive:
        let total = (1.0 + miner) * (1.0 + holder) - 1.0;

        Self {
            miner_inflation_apy: miner,
            holder_interest_apy: holder,
            total_expansion_apy: total,
            block_time_seconds_hint: 8.0,
            notes: vec![
                "Miner inflation ~8.8248% APY – global firehose.".into(),
                "Holder interest 61.8% APY – personal growth tree.".into(),
                "Total supply expansion ~70%+ / year – printing is intentional.".into(),
                "Block time is Ω-attention based; 8s is a UI hint only.".into(),
            ],
        }
    }
}

/* ========= Gift & Airdrop Rules ========= */

#[derive(Debug, Clone, Serialize)]
struct GiftRules {
    initial_lock_days: u32,
    unlock_phi_base: f64,
    starting_daily_cap_dlog: f64,
    notes: Vec<String>,
}

impl GiftRules {
    fn dlog_default(phi_val: f64) -> Self {
        Self {
            initial_lock_days: 18,
            unlock_phi_base: phi_val,
            starting_daily_cap_dlog: 100.0,
            notes: vec![
                "giftN labels are hard-locked for the first 18 full days.".into(),
                "After unlock, daily send cap grows ~100 * φ^d.".into(),
                "Gifts are lunch-money level on day 18; scale up if you actually stick around."
                    .into(),
            ],
        }
    }

    /// Example daily cap for day offset d (d = 0 on first unlock day).
    fn example_daily_cap(&self, d: u32) -> f64 {
        let d_f = d as f64;
        self.starting_daily_cap_dlog * self.unlock_phi_base.powf(d_f)
    }
}

#[derive(Debug, Clone, Serialize)]
struct AirdropNetworkRules {
    one_per_phone: bool,
    one_per_public_ip: bool,
    apple_google_required: bool,
    sms_required: bool,
    vpn_blocked: bool,
    exploit_flavor: String,
    notes: Vec<String>,
}

impl AirdropNetworkRules {
    fn dlog_default() -> Self {
        Self {
            one_per_phone: true,
            one_per_public_ip: true,
            apple_google_required: true,
            sms_required: true,
            vpn_blocked: true,
            exploit_flavor: "Lunch money only; farming is possible but mildly annoying."
                .into(),
            notes: vec![
                "Exactly one airdrop per unique phone number.".into(),
                "Exactly one airdrop per public IP address.".into(),
                "Apple/Google sign-in plus SMS verification per giftN.".into(),
                "Known VPN / datacenter IPs blocked from airdrop endpoint.".into(),
            ],
        }
    }
}

/* ========= Device Outflow Rules ========= */

#[derive(Debug, Clone, Serialize)]
struct DeviceOutflowRules {
    first_week_cap_per_day: f64,
    phi_base_after_day_8: f64,
    big_send_pending_days: u32,
    notes: Vec<String>,
}

impl DeviceOutflowRules {
    fn dlog_default(phi_val: f64) -> Self {
        Self {
            first_week_cap_per_day: 100.0,
            phi_base_after_day_8: phi_val,
            big_send_pending_days: 8,
            notes: vec![
                "Days 1–7 on a new device: max 100 DLOG/day total outflow.".into(),
                "Day 8+: cap jumps to ~10,000 DLOG/day and grows on a φ spiral."
                    .into(),
                "Large sends from brand-new devices can be held pending ~8 days."
                    .into(),
            ],
        }
    }
}

/* ========= Land / Lock Rules ========= */

#[derive(Debug, Clone, Serialize)]
struct LandTier {
    name: String,
    footprint_relative: f64,
    base_cost_dlog: f64,
}

#[derive(Debug, Clone, Serialize)]
struct LandRules {
    tiers: Vec<LandTier>,
    inactivity_days_before_auction: u32,
    notes: Vec<String>,
}

impl LandRules {
    fn dlog_default() -> Self {
        Self {
            tiers: vec![
                LandTier {
                    name: "Iron".into(),
                    footprint_relative: 1.0,
                    base_cost_dlog: 1_000.0,
                },
                LandTier {
                    name: "Gold".into(),
                    footprint_relative: 10.0,
                    base_cost_dlog: 10_000.0,
                },
                LandTier {
                    name: "Diamond".into(),
                    footprint_relative: 100.0,
                    base_cost_dlog: 100_000.0,
                },
                LandTier {
                    name: "Emerald".into(),
                    footprint_relative: 1_000.0,
                    base_cost_dlog: 1_000_000.0,
                },
            ],
            inactivity_days_before_auction: 256,
            notes: vec![
                "Locks attach to identity (phone number), not labels.".into(),
                "Each lock owns a full column above/below in its grid cell.".into(),
                "Locks must touch other locks (edge/corner adjacency, no random pixels)."
                    .into(),
                "After 256 days of no visits, a lock can enter auto-auction.".into(),
            ],
        }
    }
}

/* ========= Flight / Gravity Rules ========= */

#[derive(Debug, Clone, Serialize)]
struct PlanetGravity {
    body: String,
    kind: String,
    phi_exponent: f32,
    approx_surface_g: f32,
    flight_accel_phi_per_tick: f32,
}

#[derive(Debug, Clone, Serialize)]
struct FlightRules {
    phi_per_tick: f64,
    planets: Vec<PlanetGravity>,
    notes: Vec<String>,
}

impl FlightRules {
    fn dlog_default(phi_val: f64) -> Self {
        let phi_f = phi_val as f32;

        let planets = vec![
            PlanetGravity {
                body: "Earth".into(),
                kind: "planet".into(),
                phi_exponent: 2.0,
                approx_surface_g: 9.81,
                flight_accel_phi_per_tick: phi_f.powf(2.0),
            },
            PlanetGravity {
                body: "Moon".into(),
                kind: "moon".into(),
                phi_exponent: 1.0,
                approx_surface_g: 1.62,
                flight_accel_phi_per_tick: phi_f.powf(1.0),
            },
            PlanetGravity {
                body: "Mars".into(),
                kind: "planet".into(),
                phi_exponent: 1.5,
                approx_surface_g: 3.71,
                flight_accel_phi_per_tick: phi_f.powf(1.5),
            },
            PlanetGravity {
                body: "Sun".into(),
                kind: "star".into(),
                phi_exponent: 3.0,
                approx_surface_g: 274.0,
                flight_accel_phi_per_tick: phi_f.powf(3.0),
            },
        ];

        Self {
            phi_per_tick: phi_val,
            planets,
            notes: vec![
                "Player acceleration is φ^k per tick depending on the body.".into(),
                "Clients can resample ticks based on FPS so it feels smooth everywhere."
                    .into(),
                "Shells and cores are linked via hypercube inversion bubbles.".into(),
            ],
        }
    }
}

/* ========= Filesystem Rules ========= */

#[derive(Debug, Clone, Serialize)]
struct FilesystemRules {
    nine_infinity_root_path: String,
    label_hash_path_example: String,
    notes: Vec<String>,
}

impl FilesystemRules {
    fn dlog_default() -> Self {
        Self {
            nine_infinity_root_path:
                "https://dloG.com/∞/;∞;∞;∞;∞;∞;∞;∞;∞;∞;".into(),
            label_hash_path_example:
                "https://dloG.com/∞/;9132077554;fun;∞;∞;∞;∞;∞;∞;∞;∞;hash;".into(),
            notes: vec![
                "Exactly one 9∞ master root file – holds the whole folded universe."
                    .into(),
                "Per-label universe files live at ;phone;label;∞;∞;∞;∞;∞;∞;∞;∞;hash;"
                    .into(),
                "All contents are semicolon-separated streams; no dots.".into(),
            ],
        }
    }
}

/* ========= Ethic / Magic-Mirror Creed ========= */

#[derive(Debug, Clone, Serialize)]
struct EthicCreed {
    motto: String,
    polarity: String,
    description: String,
    notes: Vec<String>,
}

impl EthicCreed {
    fn dlog_default() -> Self {
        Self {
            motto: ";🌟 i borrow everything from evil and i serve everything to good 🌟;"
                .into(),
            polarity: "transmutation".into(),
            description: "Anything tagged as \"evil\" is just raw potential. The system's job is to borrow that energy, transmute it, and serve the result to good, to players, and to the world."
                .into(),
            notes: vec![
                "No worship of evil – only recycling of its energy to serve good."
                    .into(),
                "Abuse, scams, and harm get reflected and drained, not amplified."
                    .into(),
                "This creed is Ω-law, not NPC-law; it shapes how we design rewards, penalties, and social gameplay."
                    .into(),
            ],
        }
    }
}

/* ========= Snapshots & DTOs ========= */

#[derive(Debug, Clone, Serialize)]
struct UniverseSnapshot {
    block_height: u64,
    phi_tick_hz: f64,
    monetary_policy: MonetaryPolicy,
    gift_rules: GiftRules,
    airdrop_rules: AirdropNetworkRules,
    device_rules: DeviceOutflowRules,
    ethic_creed: EthicCreed,
}

#[derive(Debug, Serialize)]
struct HealthResponse {
    status: String,
    message: String,
}

#[derive(Debug, Serialize)]
struct RootResponse {
    service: String,
    version: String,
    message: String,
    mode_hint: String,
}

/* ========= Hosting / Runtime Config ========= */

#[derive(Debug, Serialize)]
struct HostingRuntimeConfig {
    mode: String,
    supabase_project_url: Option<String>,
    supabase_anon_key_present: bool,
    server_bind: String,
    api_base_url_hint: String,
    notes: Vec<String>,
}

/* ========= Handlers ========= */

async fn root() -> Json<RootResponse> {
    let mode = env::var("DLOG_RUNTIME_MODE").unwrap_or_else(|_| "testing_local".into());
    Json(RootResponse {
        service: "dlog-api".into(),
        version: "0.1.0".into(),
        message: "Ω heartbeat online; star slid onto a new rail.".into(),
        mode_hint: mode,
    })
}

async fn health() -> Json<HealthResponse> {
    Json(HealthResponse {
        status: "ok".into(),
        message: "Ω-physics node is alive on this machine.".into(),
    })
}

async fn universe_snapshot(State(state): State<AppState>) -> Json<UniverseSnapshot> {
    let uni = state
        .universe
        .read()
        .expect("universe rwlock poisoned on read");
    Json(uni.snapshot())
}

async fn tick_once(State(state): State<AppState>) -> Json<UniverseSnapshot> {
    {
        let mut uni = state
            .universe
            .write()
            .expect("universe rwlock poisoned on write");
        uni.tick_once();
        info!("Ω tick -> height {}", uni.block_height);
    }

    let uni = state
        .universe
        .read()
        .expect("universe rwlock poisoned on read");
    Json(uni.snapshot())
}

async fn get_money_policy(State(state): State<AppState>) -> Json<MonetaryPolicy> {
    let uni = state
        .universe
        .read()
        .expect("universe rwlock poisoned on read");
    Json(uni.monetary_policy.clone())
}

async fn get_gift_rules(State(state): State<AppState>) -> Json<GiftRules> {
    let uni = state
        .universe
        .read()
        .expect("universe rwlock poisoned on read");
    Json(uni.gift_rules.clone())
}

#[derive(Debug, Serialize)]
struct GiftDailyCapExample {
    day_offset: u32,
    daily_cap_dlog: f64,
}

async fn example_gift_daily_cap(State(state): State<AppState>) -> Json<GiftDailyCapExample> {
    let uni = state
        .universe
        .read()
        .expect("universe rwlock poisoned on read");
    let d = 0;
    let cap = uni.gift_rules.example_daily_cap(d);
    Json(GiftDailyCapExample {
        day_offset: d,
        daily_cap_dlog: cap,
    })
}

async fn get_airdrop_rules(
    State(state): State<AppState>,
) -> Json<AirdropNetworkRules> {
    let uni = state
        .universe
        .read()
        .expect("universe rwlock poisoned on read");
    Json(uni.airdrop_rules.clone())
}

async fn get_device_rules(State(state): State<AppState>) -> Json<DeviceOutflowRules> {
    let uni = state
        .universe
        .read()
        .expect("universe rwlock poisoned on read");
    Json(uni.device_rules.clone())
}

#[derive(Debug, Serialize)]
struct LandExampleLock {
    world: String,
    tier: String,
    base_cost_dlog: f64,
    inactivity_days_before_auction: u32,
}

async fn example_land_lock(State(state): State<AppState>) -> Json<LandExampleLock> {
    let uni = state
        .universe
        .read()
        .expect("universe rwlock poisoned on read");
    let emerald = uni
        .land_rules
        .tiers
        .iter()
        .find(|t| t.name == "Emerald")
        .cloned()
        .unwrap_or_else(|| uni.land_rules.tiers.last().unwrap().clone());

    Json(LandExampleLock {
        world: "earth_shell".into(),
        tier: emerald.name,
        base_cost_dlog: emerald.base_cost_dlog,
        inactivity_days_before_auction: uni.land_rules.inactivity_days_before_auction,
    })
}

#[derive(Debug, Serialize)]
struct LandAuctionRules {
    inactivity_days_before_auction: u32,
    notes: Vec<String>,
}

async fn get_land_auction_rules(
    State(state): State<AppState>,
) -> Json<LandAuctionRules> {
    let uni = state
        .universe
        .read()
        .expect("universe rwlock poisoned on read");

    Json(LandAuctionRules {
        inactivity_days_before_auction: uni.land_rules.inactivity_days_before_auction,
        notes: uni.land_rules.notes.clone(),
    })
}

#[derive(Debug, Serialize)]
struct LandAdjacencyExample {
    description: String,
    valid: bool,
}

async fn example_land_adjacency() -> Json<LandAdjacencyExample> {
    Json(LandAdjacencyExample {
        description: "T-shaped / plus-shaped clusters are valid; isolated single-pixel islands are rejected."
            .into(),
        valid: true,
    })
}

#[derive(Debug, Serialize)]
struct FlightLawSummary {
    phi_per_tick: f64,
    notes: Vec<String>,
}

async fn get_flight_law(State(state): State<AppState>) -> Json<FlightLawSummary> {
    let uni = state
        .universe
        .read()
        .expect("universe rwlock poisoned on read");
    Json(FlightLawSummary {
        phi_per_tick: uni.flight_rules.phi_per_tick,
        notes: uni.flight_rules.notes.clone(),
    })
}

async fn get_planet_table(State(state): State<AppState>) -> Json<Vec<PlanetGravity>> {
    let uni = state
        .universe
        .read()
        .expect("universe rwlock poisoned on read");
    Json(uni.flight_rules.planets.clone())
}

async fn get_filesystem_example(
    State(state): State<AppState>,
) -> Json<FilesystemRules> {
    let uni = state
        .universe
        .read()
        .expect("universe rwlock poisoned on read");
    Json(uni.filesystem_rules.clone())
}

async fn get_hosting_runtime() -> Json<HostingRuntimeConfig> {
    let mode = env::var("DLOG_RUNTIME_MODE").unwrap_or_else(|_| "testing_local".into());
    let supabase_url =
        env::var("SUPABASE_URL").ok();
    let supabase_anon_present =
        env::var("SUPABASE_ANON_KEY").is_ok();

    // Defaults for local dev on your Mac.
    let bind_host = env::var("DLOG_BIND").unwrap_or_else(|_| "127.0.0.1".into());
    let bind_port = env::var("DLOG_PORT").unwrap_or_else(|_| "8888".into());
    let bind = format!("{bind_host}:{bind_port}");
    let api_base = format!("http://{bind}");

    Json(HostingRuntimeConfig {
        mode,
        supabase_project_url: supabase_url,
        supabase_anon_key_present: supabase_anon_present,
        server_bind: bind,
        api_base_url_hint: api_base,
        notes: vec![
            "This node is currently running in 'testing_local' mode on your machine by default."
                .into(),
            "When you deploy to Supabase, set DLOG_RUNTIME_MODE=supabase_cloud and point SUPABASE_URL at your project."
                .into(),
            "For now, everything is self-contained: Rust, Axum, CORS, Ω state – all on your Mac."
                .into(),
        ],
    })
}

async fn get_ethic_creed(State(state): State<AppState>) -> Json<EthicCreed> {
    let uni = state
        .universe
        .read()
        .expect("universe rwlock poisoned on read");
    Json(uni.ethic_creed.clone())
}

/* ========= Bootstrap ========= */

#[tokio::main]
async fn main() {
    setup_tracing();

    let universe = Arc::new(RwLock::new(UniverseInner::new()));
    let phi_tick_hz = 1000.0;

    let state = AppState {
        universe,
        phi_tick_hz,
    };

    let bind_host =
        env::var("DLOG_BIND").unwrap_or_else(|_| "127.0.0.1".into());
    let bind_port =
        env::var("DLOG_PORT").unwrap_or_else(|_| "8888".into());

    let addr: SocketAddr = format!("{bind_host}:{bind_port}")
        .parse()
        .expect("invalid DLOG_BIND/DLOG_PORT combination");

    let app = Router::new()
        .route("/", get(root))
        .route("/health", get(health))
        .route("/universe/snapshot", get(universe_snapshot))
        .route("/tick/once", post(tick_once))
        .route("/money/policy", get(get_money_policy))
        .route("/gift/rules", get(get_gift_rules))
        .route("/gift/daily_cap/example", get(example_gift_daily_cap))
        .route("/airdrop/network", get(get_airdrop_rules))
        .route("/device/outflow", get(get_device_rules))
        .route("/land/example_lock", get(example_land_lock))
        .route("/land/auction_rules", get(get_land_auction_rules))
        .route("/land/adjacency_example", get(example_land_adjacency))
        .route("/flight/law", get(get_flight_law))
        .route("/flight/planet_table", get(get_planet_table))
        .route("/filesystem/example_label", get(get_filesystem_example))
        .route("/hosting/runtime", get(get_hosting_runtime))
        .route("/ethic/creed", get(get_ethic_creed))
        .with_state(state)
        // Very loose CORS for local dev; lock this down later.
        .layer(CorsLayer::very_permissive());

    info!("dlog-api listening on http://{addr}");
    axum::serve(
        tokio::net::TcpListener::bind(addr)
            .await
            .expect("failed to bind TCP listener"),
        app,
    )
    .await
    .expect("server error");
}

fn setup_tracing() {
    // Simple stdout logger; uses RUST_LOG if you set it.
    let _ = tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "info".into()),
        )
        .try_init();
}

