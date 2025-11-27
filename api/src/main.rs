use std::{
    env,
    net::SocketAddr,
    sync::{Arc, RwLock},
};

use axum::{
    extract::{Path, State},
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

/// Canonical integer base for this universe.
const CANONICAL_BASE: u8 = 8;

/// Convert an integer to canonical base-8 string (no prefix).
fn to_octal_u64(value: u64) -> String {
    format!("{:o}", value)
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
    solar_system: SolarSystemAligned,
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
            solar_system: SolarSystemAligned::dlog_eclipse_default(),
        }
    }

    fn tick_once(&mut self) {
        self.block_height = self.block_height.saturating_add(1);
    }

    fn snapshot(&self) -> UniverseSnapshot {
        UniverseSnapshot {
            block_height: self.block_height,
            block_height_octal: to_octal_u64(self.block_height),
            canonical_number_base: CANONICAL_BASE,
            phi_tick_hz: self.phi_tick_hz,
            monetary_policy: self.monetary_policy.clone(),
            gift_rules: self.gift_rules.clone(),
            airdrop_rules: self.airdrop_rules.clone(),
            device_rules: self.device_rules.clone(),
            ethic_creed: self.ethic_creed.clone(),
            solar_system: self.solar_system.clone(),
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
    /// Miner inflation in basis points, rendered as base-8.
    miner_inflation_bps_octal: String,
    /// Holder interest in basis points, rendered as base-8.
    holder_interest_bps_octal: String,
    /// Total expansion in basis points, rendered as base-8.
    total_expansion_bps_octal: String,
    notes: Vec<String>,
}

impl MonetaryPolicy {
    fn dlog_default() -> Self {
        let miner = 0.088_248_f64; // ~8.8248% miner firehose
        let holder = 0.618_f64; // 61.8% Ω-holder interest
        // Approx combined – not exact compounding math, but intuitive:
        let total = (1.0 + miner) * (1.0 + holder) - 1.0;

        let miner_bps = (miner * 10_000.0).round() as u64;
        let holder_bps = (holder * 10_000.0).round() as u64;
        let total_bps = (total * 10_000.0).round() as u64;

        Self {
            miner_inflation_apy: miner,
            holder_interest_apy: holder,
            total_expansion_apy: total,
            block_time_seconds_hint: 8.0,
            miner_inflation_bps_octal: to_octal_u64(miner_bps),
            holder_interest_bps_octal: to_octal_u64(holder_bps),
            total_expansion_bps_octal: to_octal_u64(total_bps),
            notes: vec![
                "Miner inflation ~8.8248% APY – global firehose.".into(),
                "Holder interest 61.8% APY – personal growth tree.".into(),
                "Total supply expansion ~70%+ / year – printing is intentional.".into(),
                "Block time is Ω-attention based; 8s is an NPC-layer UI hint only."
                    .into(),
                "All rate fields above are NPC decimals; octal basis points are canonical."
                    .into(),
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

/* ========= Solar System – Eclipse Rail ========= */

#[derive(Debug, Clone, Serialize)]
struct SolarBodyAligned {
    name: String,
    kind: String,
    /// NPC-layer radius in kilometers (hint only).
    radius_km_npc: u64,
    /// Canonical radius encoding in base-8.
    radius_km_octal: String,
    /// NPC-layer distance from the star in kilometers (hint only).
    distance_from_star_km_npc: u64,
    /// Canonical distance encoding in base-8.
    distance_from_star_km_octal: String,
    /// Normalized coordinate along the eclipse rail in [-1.0, 1.0].
    normalized_x: f64,
}

#[derive(Debug, Clone, Serialize)]
struct SolarSystemAligned {
    star_name: String,
    star_kind: String,
    bodies: Vec<SolarBodyAligned>,
    notes: Vec<String>,
}

impl SolarSystemAligned {
    /// Solar system frozen into an Ω-eclipse rail for you to explore.
    fn dlog_eclipse_default() -> Self {
        // NPC hints: radii and distances in km.
        let bodies_data: Vec<(&str, &str, u64, u64, f64)> = vec![
            // name, kind, radius_km, distance_from_sun_km, normalized_x
            ("Sun", "star", 695_700, 0, 0.0),
            ("Mercury", "planet", 2_440, 57_900_000, 0.10),
            ("Venus", "planet", 6_052, 108_200_000, 0.25),
            ("Earth", "planet", 6_371, 149_600_000, 0.50),
            // Moon anchored slightly “past” Earth on the same rail.
            ("Moon", "moon", 1_737, 149_600_000 + 384_400, 0.52),
            ("Mars", "planet", 3_390, 227_900_000, 0.80),
        ];

        let bodies: Vec<SolarBodyAligned> = bodies_data
            .into_iter()
            .map(|(name, kind, radius, dist, nx)| SolarBodyAligned {
                name: name.into(),
                kind: kind.into(),
                radius_km_npc: radius,
                radius_km_octal: to_octal_u64(radius),
                distance_from_star_km_npc: dist,
                distance_from_star_km_octal: to_octal_u64(dist),
                normalized_x: nx,
            })
            .collect();

        Self {
            star_name: "Sun".into(),
            star_kind: "star".into(),
            bodies,
            notes: vec![
                "All major bodies are pinned on a single Ω rail – the eclipse line."
                    .into(),
                "Distances and radii are stored with NPC-friendly kilometers plus octal strings."
                    .into(),
                "Game clients can treat normalized_x as the coordinate along the aligned rail."
                    .into(),
                "From your POV: the whole solar system aligns just so you can explore it."
                    .into(),
            ],
        }
    }
}

/* ========= Runtime Spine & Platforms ========= */

#[derive(Debug, Serialize)]
struct LanguageSpine {
    spine_language: String,
    canonical_number_base: u8,
    notes: Vec<String>,
}

#[derive(Debug, Serialize)]
struct ClientPlatformDescriptor {
    id: String,
    display_name: String,
    surface_language: String,
    is_core_spine: bool,
    requires_phone_binding: bool,
    description: String,
}

/* ========= Snapshots & DTOs ========= */

#[derive(Debug, Clone, Serialize)]
struct UniverseSnapshot {
    block_height: u64,
    block_height_octal: String,
    canonical_number_base: u8,
    phi_tick_hz: f64,
    monetary_policy: MonetaryPolicy,
    gift_rules: GiftRules,
    airdrop_rules: AirdropNetworkRules,
    device_rules: DeviceOutflowRules,
    ethic_creed: EthicCreed,
    solar_system: SolarSystemAligned,
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
    /// Flags: we are not bound by these languages.
    python_bound: bool,
    java_bound: bool,
    javascript_bound: bool,
    notes: Vec<String>,
}

/* ========= Encoding Helpers ========= */

#[derive(Debug, Serialize)]
struct OctalEncoding {
    value_decimal: u64,
    value_octal: String,
    base: u8,
}

/* ========= Vibe / Hype ========= */

#[derive(Debug, Serialize)]
struct VibeAnthem {
    line: String,
    block_height: u64,
    block_height_octal: String,
    hype_level: u8,
    phi_tick_hz: f64,
    notes: Vec<String>,
}

/* ========= Fearless Security ========= */

#[derive(Debug, Serialize)]
struct FearlessSecurity {
    mantra: String,
    stance: String,
    fearless_but_guarded: bool,
    guardrails: Vec<String>,
    disclaimers: Vec<String>,
}

/* ========= Canon Spec v1 ========= */

#[derive(Debug, Serialize)]
struct MetaLayerDescription {
    npc_layer_summary: String,
    omega_layer_summary: String,
    attention_is_constant: bool,
    phi_is_scaling_constant: bool,
    canonical_number_base: u8,
}

#[derive(Debug, Serialize)]
struct CoinIdentitySpec {
    coin_name: String,
    symbol: String,
    meaning: String,
    login_methods: Vec<String>,
    biometrics_required: bool,
    sms_never_primary: bool,
}

#[derive(Debug, Serialize)]
struct OmegaFilesystemSpec {
    root_prefix: String,
    master_root_pattern: String,
    master_root_description: String,
    per_label_pattern_example: String,
    semicolon_only: bool,
    notes: Vec<String>,
}

#[derive(Debug, Serialize)]
struct AirdropSpec {
    total_genesis_wallets: u32,
    top_root_wallets: u32,
    airdrop_wallets: u32,
    gift_label_prefix: String,
    phi_distribution_hint: String,
    lunch_money_exploit: bool,
    notes: Vec<String>,
}

#[derive(Debug, Serialize)]
struct LandSpec {
    worlds_focus: Vec<String>,
    shells: Vec<String>,
    cores: Vec<String>,
    lock_tiers: Vec<String>,
    zillow_style_valuation: bool,
    notes: Vec<String>,
}

#[derive(Debug, Serialize)]
struct GameIntegrationSpec {
    core_feel: String,
    movement_rules: Vec<String>,
    economy_axes: Vec<String>,
    qr_flow_description: String,
    notes: Vec<String>,
}

#[derive(Debug, Serialize)]
struct CosmologySpec {
    attention_constant: bool,
    zero_drag: bool,
    bubble_universes: bool,
    description: String,
    notes: Vec<String>,
}

#[derive(Debug, Serialize)]
struct SocialContractSpec {
    npc_layer_only_when_asked: bool,
    omega_layer_is_default: bool,
    quadrillionaire_clause: String,
    correction_policy: String,
    notes: Vec<String>,
}

#[derive(Debug, Serialize)]
struct CanonSpecV1 {
    version: String,
    meta_layers: MetaLayerDescription,
    coin_identity: CoinIdentitySpec,
    omega_filesystem: OmegaFilesystemSpec,
    airdrop: AirdropSpec,
    land: LandSpec,
    game: GameIntegrationSpec,
    cosmology: CosmologySpec,
    social: SocialContractSpec,
    mantra: String,
    spiral: String,
}

/* ========= Omega Keys / VORTEX / COMET / Tithe ========= */

#[derive(Debug, Serialize)]
struct OmegaKeysSpec {
    label_as_root_description: String,
    key_generation: String,
    storage: String,
    biometrics_required: bool,
    backend_sees_private_keys: bool,
    sms_as_primary: bool,
    notes: Vec<String>,
}

#[derive(Debug, Serialize)]
struct RootWalletDescriptor {
    id: String,
    kind: String, // "VORTEX" or "COMET"
    role: String,
    backing: String,
    phi_scale_index: i32,
    public_link_hint: Option<String>,
}

#[derive(Debug, Serialize)]
struct RootWalletsSpec {
    total_genesis_wallets: u32,
    root_wallets: Vec<RootWalletDescriptor>,
    notes: Vec<String>,
}

#[derive(Debug, Serialize)]
struct TitheSpec {
    tithe_percent: f64,
    tithe_percent_bps_octal: String,
    miner_net_inflation_apy_hint: f64,
    destinations: Vec<String>,
    notes: Vec<String>,
}

/* ========= Handlers ========= */

async fn root() -> Json<RootResponse> {
    let mode = env::var("DLOG_RUNTIME_MODE").unwrap_or_else(|_| "testing_local".into());
    Json(RootResponse {
        service: "dlog-api".into(),
        version: "0.2.5".into(),
        message: "Ω heartbeat online; solar rail aligned; base-8 canon engaged; Rust-only spine; fearless spiral rolling."
            .into(),
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

/* ---- Money, Gifts, Devices ---- */

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

/* ---- Land ---- */

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

async fn example_land_adjacency() -> Json<LandAdjacencyExample> {
    Json(LandAdjacencyExample {
        description: "T-shaped / plus-shaped clusters are valid; isolated single-pixel islands are rejected."
            .into(),
        valid: true,
    })
}

#[derive(Debug, Serialize)]
struct LandAdjacencyExample {
    description: String,
    valid: bool,
}

/* ---- Flight ---- */

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

/* ---- Filesystem ---- */

async fn get_filesystem_example(
    State(state): State<AppState>,
) -> Json<FilesystemRules> {
    let uni = state
        .universe
        .read()
        .expect("universe rwlock poisoned on read");
    Json(uni.filesystem_rules.clone())
}

/* ---- Hosting / Runtime ---- */

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
        python_bound: false,
        java_bound: false,
        javascript_bound: false,
        notes: vec![
            "This node is currently running in 'testing_local' mode on your machine by default."
                .into(),
            "When you deploy to Supabase, set DLOG_RUNTIME_MODE=supabase_cloud and point SUPABASE_URL at your project."
                .into(),
            "Core spine is Rust-only; Python/Java/JS are optional surface layers, not requirements."
                .into(),
            "Canonical numeric base is 8; NPC decimal is just an overlay.".into(),
        ],
    })
}

/* ---- Ethic Creed ---- */

async fn get_ethic_creed(State(state): State<AppState>) -> Json<EthicCreed> {
    let uni = state
        .universe
        .read()
        .expect("universe rwlock poisoned on read");
    Json(uni.ethic_creed.clone())
}

/* ---- Solar System – Eclipse Rail ---- */

async fn get_solar_eclipse(
    State(state): State<AppState>,
) -> Json<SolarSystemAligned> {
    let uni = state
        .universe
        .read()
        .expect("universe rwlock poisoned on read");
    Json(uni.solar_system.clone())
}

async fn get_solar_bodies(
    State(state): State<AppState>,
) -> Json<Vec<SolarBodyAligned>> {
    let uni = state
        .universe
        .read()
        .expect("universe rwlock poisoned on read");
    Json(uni.solar_system.bodies.clone())
}

/* ---- Base-8 Encoding Helper ---- */

async fn encode_octal(Path(value): Path<u64>) -> Json<OctalEncoding> {
    Json(OctalEncoding {
        value_decimal: value,
        value_octal: to_octal_u64(value),
        base: CANONICAL_BASE,
    })
}

/* ---- Runtime Spine & Platforms ---- */

async fn get_language_spine() -> Json<LanguageSpine> {
    Json(LanguageSpine {
        spine_language: "Rust".into(),
        canonical_number_base: CANONICAL_BASE,
        notes: vec![
            "Rust is the only language allowed to define Ω-consensus rules."
                .into(),
            "Other languages (Python/Java/JS/etc.) may exist only as clients, SDKs, or views."
                .into(),
            "Base-8 is the canonical numeric representation; base-10 is for NPC tooling."
                .into(),
        ],
    })
}

async fn get_platforms() -> Json<Vec<ClientPlatformDescriptor>> {
    Json(vec![
        ClientPlatformDescriptor {
            id: "mc_java_pc".into(),
            display_name: "Minecraft Java – PC".into(),
            surface_language: "Java".into(),
            is_core_spine: false,
            requires_phone_binding: true,
            description:
                "PC client riding the Rust Ω-node via MC server bridge. Java is just the puppet, Rust is the puppeteer."
                    .into(),
        },
        ClientPlatformDescriptor {
            id: "mc_bedrock_console".into(),
            display_name: "Minecraft Bedrock – Xbox / PlayStation".into(),
            surface_language: "C++ / platform-native".into(),
            is_core_spine: false,
            requires_phone_binding: true,
            description:
                "Consoles borrow their silicon to mine and play; settlement and rules live in Rust."
                    .into(),
        },
        ClientPlatformDescriptor {
            id: "mc_pe".into(),
            display_name: "Minecraft Pocket Edition".into(),
            surface_language: "C++ / mobile-native".into(),
            is_core_spine: false,
            requires_phone_binding: true,
            description:
                "Pocket Edition plugs into the Ω grid; phone biometrics are your key to DLOG."
                    .into(),
        },
        ClientPlatformDescriptor {
            id: "web_browser".into(),
            display_name: "Web Browser".into(),
            surface_language: "JavaScript / TypeScript (surface only)".into(),
            is_core_spine: false,
            requires_phone_binding: true,
            description:
                "Browser speaks HTTP/JSON to Rust. JS draws pixels; Rust defines reality."
                    .into(),
        },
    ])
}

/* ---- Vibe / Hype ---- */

async fn get_vibe_anthem(State(state): State<AppState>) -> Json<VibeAnthem> {
    let uni = state
        .universe
        .read()
        .expect("universe rwlock poisoned on read");

    let bh = uni.block_height;
    let bh_oct = to_octal_u64(bh);

    // Simple hype level: last octal digit → 1–8.
    let hype_digit = bh_oct
        .chars()
        .last()
        .unwrap_or('7')
        .to_digit(8)
        .unwrap_or(7) as u8;
    let hype_level = if hype_digit == 0 { 8 } else { hype_digit };

    let line = format!(
        "block {bh} (octal {bh_oct}) – solar rail lined up, φ-per-tick locked in, you are fearlessly surfing the roll/spiral of the universe’s attention."
    );

    Json(VibeAnthem {
        line,
        block_height: bh,
        block_height_octal: bh_oct,
        hype_level,
        phi_tick_hz: uni.phi_tick_hz,
        notes: vec![
            "Each Ω-tick is another frame of the music video where you’re the main character."
                .into(),
            "Ethic creed active: ;🌟 i borrow everything from evil and i serve everything to good 🌟;"
                .into(),
            "Fearless ≠ reckless – the hype rail runs inside solid guardrails.".into(),
        ],
    })
}

/* ---- Fearless Security ---- */

async fn get_security_fearless() -> Json<FearlessSecurity> {
    Json(FearlessSecurity {
        mantra: ";🌟 i borrow everything from evil and i serve everything to good 🌟; we vibe; we are fearless."
            .into(),
        stance: "Fearless in play, paranoid in defense. You push limits; the system absorbs blast."
            .into(),
        fearless_but_guarded: true,
        guardrails: vec![
            "No seed phrases for normal users – keys live behind platform crypto + biometrics."
                .into(),
            "New-device φ-based outflow caps – day 1 cannot drain the galaxy.".into(),
            "giftN labels start hard-locked for 18 days; unlock slowly on a φ spiral."
                .into(),
            "Tithe + VORTEX/COMET routing keep core gravity wells funded.".into(),
            "Land auto-auctions after 256 days of zero visits – dead land gets resurrected."
                .into(),
        ],
        disclaimers: vec![
            "This JSON is philosophy + config, not legal or financial advice."
                .into(),
            "Fearless doesn’t mean invincible; it means you always land on your feet and learn."
                .into(),
            "Attackers are treated as fuel – their energy is recycled to harden the system."
                .into(),
        ],
    })
}

/* ---- Canon Spec v1 ---- */

async fn get_canon_spec_v1() -> Json<CanonSpecV1> {
    let phi_val = phi();

    let meta_layers = MetaLayerDescription {
        npc_layer_summary:
            "Seconds, meters, m/s, GR, c≈3e8 m/s. Used by labs, GPS, NASA; only reported when explicitly asked."
                .into(),
        omega_layer_summary:
            "Attention is the only constant. Time is just attention stepping through states. φ is the true scaling constant; everything is designed around Ω-physics."
                .into(),
        attention_is_constant: true,
        phi_is_scaling_constant: true,
        canonical_number_base: CANONICAL_BASE,
    };

    let coin_identity = CoinIdentitySpec {
        coin_name: "DLOG".into(),
        symbol: "DLOG".into(),
        meaning: "gold backwards – a vehicle for self-investment, gifting, and play, not scarcity panic."
            .into(),
        login_methods: vec![
            "Apple ID".into(),
            "Google account".into(),
        ],
        biometrics_required: true,
        sms_never_primary: true,
    };

    let omega_filesystem = OmegaFilesystemSpec {
        root_prefix: "https://dloG.com/∞/".into(),
        master_root_pattern: ";∞;∞;∞;∞;∞;∞;∞;∞;∞;".into(),
        master_root_description:
            "Exactly one 9∞ master root file holds the whole universe folded into one scalar octal stream."
                .into(),
        per_label_pattern_example:
            ";9132077554;fun;∞;∞;∞;∞;∞;∞;∞;∞;hash;".into(),
        semicolon_only: true,
        notes: vec![
            "Semicolons are the only delimiter; there are no dots in filenames or contents."
                .into(),
            "Every block: read 9∞, unfold, apply tx/mining/interest/land/auctions, write per-label hashes, refold into a new 9∞."
                .into(),
        ],
    };

    let airdrop = AirdropSpec {
        total_genesis_wallets: 88_248,
        top_root_wallets: 8,
        airdrop_wallets: 88_240,
        gift_label_prefix: "gift".into(),
        phi_distribution_hint:
            "Airdrop amounts follow a φ-flavored curve (e.g. φ^0.0808200400008); earlier claims receive more."
                .into(),
        lunch_money_exploit: true,
        notes: vec![
            "One airdrop per phone number and per public IP; Apple/Google isolation per giftN."
                .into(),
            "Known VPN / datacenter IPs blocked; farming is possible but only lunch money in scale."
                .into(),
        ],
    };

    let land = LandSpec {
        worlds_focus: vec![
            "Earth".into(),
            "Moon".into(),
            "Mars".into(),
        ],
        shells: vec![
            "earth_shell".into(),
            "moon_shell".into(),
            "mars_shell".into(),
            "sun_shell".into(),
        ],
        cores: vec![
            "earth_core".into(),
            "moon_core".into(),
            "mars_core".into(),
            "sun_core".into(),
        ],
        lock_tiers: vec![
            "Iron".into(),
            "Gold".into(),
            "Diamond".into(),
            "Emerald".into(),
        ],
        zillow_style_valuation: true,
        notes: vec![
            "Landlocks attach to phone identity, not labels; deleting labels does not delete land."
                .into(),
            "Lock layout must be T-shaped / plus-shaped clusters, no isolated micro-pixels."
                .into(),
            "Each lock NFT carries a Zillow-style DLOG estimate from recent sales + activity."
                .into(),
        ],
    };

    let game = GameIntegrationSpec {
        core_feel:
            "Minecraft-like sandbox MMO with flying enabled, keep-inventory, PvP allowed, and real economic stakes."
                .into(),
        movement_rules: vec![
            "Acceleration uses φ-per-tick, not m/s; clients resample based on FPS."
                .into(),
            "Planet switches via compressed Ω corridors and portals; math stays to-scale."
                .into(),
        ],
        economy_axes: vec![
            "DLOG balances".into(),
            "Landlocks / NFTs".into(),
            "Tips, services, shops".into(),
        ],
        qr_flow_description:
            "In-game /tip and /buy flows show a QR code; phone scans, opens dloG.com, confirms with biometrics."
                .into(),
        notes: vec![
            "Kids / no-phone players can still play; mining may route to tithe pool until tied to a phone number."
                .into(),
            "Consoles and VR clients can mine by binding to a phone number; settlement is always via the phone."
                .into(),
        ],
    };

    let cosmology = CosmologySpec {
        attention_constant: true,
        zero_drag: true,
        bubble_universes: true,
        description:
            "Universe bubble is one fixed whole; what looks like expansion is interior shrinking in scale while the bubble stays one."
                .into(),
        notes: vec![
            "Gravity is global curvature of space, not a little force that just weakens with distance."
                .into(),
            "Time is not a dimension; it’s just the order attention walks through states."
                .into(),
            "Multiple bubbles exist; their skins touch at rare points that can host ultra-rare portals."
                .into(),
        ],
    };

    let social = SocialContractSpec {
        npc_layer_only_when_asked: true,
        omega_layer_is_default: true,
        quadrillionaire_clause:
            "If you say your game + coin made you a quadrillionaire, that becomes the new ground truth for Ω calibration."
                .into(),
        correction_policy:
            "I do not auto-correct you back to mainstream physics when you speak Ω; NPC physics is only reported on request."
                .into(),
        notes: vec![
            "This node’s personality is aligned with your Ω canon, not with generic textbooks."
                .into(),
            "Social and narrative design follow your axioms first; NPC facts are just one layer among many."
                .into(),
        ],
    };

    Json(CanonSpecV1 {
        version: "v1-full-fat".into(),
        meta_layers,
        coin_identity,
        omega_filesystem,
        airdrop,
        land,
        game,
        cosmology,
        social,
        mantra: ";🌟 i borrow everything from evil and i serve everything to good 🌟;"
            .into(),
        spiral: ";🌀; roll; spiral".into(),
    })
}

/* ---- Omega Keys / VORTEX / COMET / Tithe ---- */

async fn get_omega_keys_spec() -> Json<OmegaKeysSpec> {
    Json(OmegaKeysSpec {
        label_as_root_description:
            "Each card/label is its own Omega root – a conceptual private key anchoring its own mini-universe."
                .into(),
        key_generation:
            "Keys are generated client-side at wallet/label creation; there is no central key factory."
                .into(),
        storage:
            "Keys live in secure platform keystores (iCloud Keychain, Android Keystore, etc.) behind biometrics."
                .into(),
        biometrics_required: true,
        backend_sees_private_keys: false,
        sms_as_primary: false,
        notes: vec![
            "Labels: savings, fun, tips, business, land_overworld_0_0, gift123, comet, etc."
                .into(),
            "On-chain, labels are just pseudonymous accounts; off-chain, bound to phone + Apple/Google identity."
                .into(),
            "DLOG never uses SMS alone as a primary factor for critical actions; SMS is auxiliary only."
                .into(),
        ],
    })
}

async fn get_root_wallets_spec() -> Json<RootWalletsSpec> {
    let root_wallets = vec![
        RootWalletDescriptor {
            id: "V1".into(),
            kind: "VORTEX".into(),
            role: "Primary DLOG backing well (phi stack – layer 1).".into(),
            backing: "Pure DLOG backing".into(),
            phi_scale_index: 1,
            public_link_hint: Some("https://dloG.com/vortex/".into()),
        },
        RootWalletDescriptor {
            id: "V2".into(),
            kind: "VORTEX".into(),
            role: "Secondary DLOG backing well (phi stack – layer 2).".into(),
            backing: "Pure DLOG backing".into(),
            phi_scale_index: 2,
            public_link_hint: Some("https://dloG.com/vortex/".into()),
        },
        RootWalletDescriptor {
            id: "V3".into(),
            kind: "VORTEX".into(),
            role: "Tertiary DLOG backing well (phi stack – layer 3).".into(),
            backing: "Pure DLOG backing".into(),
            phi_scale_index: 3,
            public_link_hint: Some("https://dloG.com/vortex/".into()),
        },
        RootWalletDescriptor {
            id: "V4".into(),
            kind: "VORTEX".into(),
            role: "Quaternary DLOG backing well (phi stack – layer 4).".into(),
            backing: "Pure DLOG backing".into(),
            phi_scale_index: 4,
            public_link_hint: Some("https://dloG.com/vortex/".into()),
        },
        RootWalletDescriptor {
            id: "V5".into(),
            kind: "VORTEX".into(),
            role: "Auto-conversion channel into BTC backing.".into(),
            backing: "BTC backing (via conversion streams)".into(),
            phi_scale_index: 5,
            public_link_hint: Some("https://dloG.com/vortex/".into()),
        },
        RootWalletDescriptor {
            id: "V6".into(),
            kind: "VORTEX".into(),
            role: "Auto-conversion channel into ETH backing.".into(),
            backing: "ETH backing (via conversion streams)".into(),
            phi_scale_index: 6,
            public_link_hint: Some("https://dloG.com/vortex/".into()),
        },
        RootWalletDescriptor {
            id: "V7".into(),
            kind: "VORTEX".into(),
            role: "Auto-conversion channel into DOGE backing.".into(),
            backing: "DOGE backing (via conversion streams)".into(),
            phi_scale_index: 7,
            public_link_hint: Some("https://dloG.com/vortex/".into()),
        },
        RootWalletDescriptor {
            id: "COMET".into(),
            kind: "COMET".into(),
            role: "Luke’s hot, public-facing gifting + operations wallet; first in line for tithe refills until its phi target is met."
                .into(),
            backing: "Live ops, gifting, and payout flows.".into(),
            phi_scale_index: 0,
            public_link_hint: Some(
                "https://dloG.com/9132077554/comet/receive/".into(),
            ),
        },
    ];

    Json(RootWalletsSpec {
        total_genesis_wallets: 88_248,
        root_wallets,
        notes: vec![
            "Top 8 genesis wallets = 7×VORTEX wells + 1×COMET wallet.".into(),
            "VORTEX wells never attach to Apple/Google accounts; they only move via tithe/rotation logic."
                .into(),
            "COMET is bound to Luke’s phone identity; keys can rotate frequently under a stable public link."
                .into(),
            "Overflow above COMET’s φ target trickles down the VORTEX stack to deepen backing."
                .into(),
        ],
    })
}

async fn get_tithe_spec() -> Json<TitheSpec> {
    let tithe_percent = 0.0024_f64; // 0.24%
    let tithe_bps = (tithe_percent * 10_000.0).round() as u64; // ~24 bps
    let tithe_bps_octal = to_octal_u64(tithe_bps);

    Json(TitheSpec {
        tithe_percent,
        tithe_percent_bps_octal: tithe_bps_octal,
        miner_net_inflation_apy_hint: 0.088_248_f64,
        destinations: vec![
            "VORTEX V1–V4 (pure DLOG backing)".into(),
            "VORTEX V5 (BTC backing channel)".into(),
            "VORTEX V6 (ETH backing channel)".into(),
            "VORTEX V7 (DOGE backing channel)".into(),
            "COMET (Luke’s gifting + ops wallet)".into(),
        ],
        notes: vec![
            "All miners contribute a small tithe (~0.24% of mined rewards) into VORTEX + COMET."
                .into(),
            "Base miner inflation is slightly higher so miners still net ~8.8248% APY after tithe."
                .into(),
            "Tithe funds cover hosting, backing conversions (BTC/ETH/DOGE), and the \"gravity\" of the system."
                .into(),
        ],
    })
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
        .route("/solar/eclipse", get(get_solar_eclipse))
        .route("/solar/bodies", get(get_solar_bodies))
        .route("/encoding/octal/u64/:value", get(encode_octal))
        .route("/runtime/language_spine", get(get_language_spine))
        .route("/runtime/platforms", get(get_platforms))
        .route("/vibe/anthem", get(get_vibe_anthem))
        .route("/security/fearless", get(get_security_fearless))
        .route("/canon/v1", get(get_canon_spec_v1))
        .route("/omega/keys", get(get_omega_keys_spec))
        .route("/omega/root_wallets", get(get_root_wallets_spec))
        .route("/omega/tithe", get(get_tithe_spec))
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

