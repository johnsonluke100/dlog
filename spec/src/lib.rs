// spec/src/lib.rs
//
// Shared types / models for the dlog universe:
// - Labels, balances, land locks
// - Node config
// - Planets + φ-gravity profiles
// - Ω filesystem helpers (label universe path)
// - Tick tuning model (how φ-ticks map to client frames)
// - Minecraft bridge types (players + servers)

use serde::{Deserialize, Serialize};

/// BlockHeight represents the chain height.
pub type BlockHeight = u64;

/// A simple label identifier: phone number + label name.
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct LabelId {
    /// Phone number as a string, e.g. "9132077554".
    pub phone: String,
    /// Label name, e.g. "fun", "gift1", "comet".
    pub label: String,
}

/// Basic balance representation in smallest integer units.
#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub struct Balance {
    /// Raw amount in smallest integer units.
    pub amount: u128,
}

/// Simple representation of a land lock.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LandLock {
    pub id: String,
    pub owner_phone: String,
    pub world: String,   // e.g. "earth_shell", "moon_core"
    pub tier: String,    // "iron" | "gold" | "diamond" | "emerald"
    pub x: i64,
    pub z: i64,
    pub size: i32,       // footprint width (square) in blocks/chunks
    pub zillow_estimate_amount: u128,
}

/// UniverseSnapshot represents a folded summary of the universe state.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UniverseSnapshot {
    pub height: BlockHeight,
    /// Encoded 9∞ master root as a string.
    pub master_root: String,
    /// Milliseconds since epoch from the NPC layer.
    pub timestamp_ms: i64,
}

/// Simple transfer transaction placeholder.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TransferTx {
    pub from: LabelId,
    pub to: LabelId,
    pub amount: u128,
}

/// Configuration for a single node in the dlog universe.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NodeConfig {
    pub node_name: String,
    pub bind_addr: String,
    pub public_url: Option<String>,
    pub phi_tick_rate: f64,
}

impl Default for NodeConfig {
    fn default() -> Self {
        Self {
            node_name: "dlog-node-default".to_string(),
            bind_addr: "0.0.0.0:8080".to_string(),
            public_url: None,
            phi_tick_rate: 1000.0,
        }
    }
}

/// Simple view for returning a balance over the API.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BalanceView {
    pub label: LabelId,
    pub balance: Balance,
}

/// PlanetSpec describes a planet's Ω-physics gravity via φ exponents.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlanetSpec {
    /// Stable identifier, e.g. "earth", "moon", "mars".
    pub id: String,
    /// Human-readable name.
    pub name: String,
    /// Dimension name for the shell world, e.g. "earth_shell".
    pub shell_world: String,
    /// Dimension name for the core world, e.g. "earth_core".
    pub core_world: String,
    /// φ exponent for "falling" acceleration on this planet.
    pub phi_power_fall: f64,
    /// φ exponent for "flying" acceleration on this planet.
    pub phi_power_fly: f64,
}

/// PhiGravityProfile = concrete φ^? results for a planet.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PhiGravityProfile {
    pub planet_id: String,
    pub phi_power_fall: f64,
    pub phi_power_fly: f64,
    /// Computed φ^phi_power_fall.
    pub g_fall: f64,
    /// Computed φ^phi_power_fly.
    pub g_fly: f64,
}

/// Tick tuning result for a client on a given planet.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TickTuning {
    /// Planet id, e.g. "earth".
    pub planet_id: String,
    /// Client frames per second (e.g. 60, 144, 1000).
    pub client_fps: f64,
    /// Server φ-tick rate from NodeConfig (conceptual physics heartbeat).
    pub server_phi_tick_rate: f64,
    /// How many φ-ticks we conceptually traverse per rendered frame.
    pub ticks_per_frame: f64,
    /// Planet φ exponents for fall/fly.
    pub phi_power_fall: f64,
    pub phi_power_fly: f64,
    /// Raw φ^power values.
    pub g_fall: f64,
    pub g_fly: f64,
    /// Effective delta per frame (what you plug into your velocity integrator).
    pub effective_delta_fall_per_frame: f64,
    pub effective_delta_fly_per_frame: f64,
}

/// LabelUniversePath encodes the Ω filesystem path for a (phone, label)
/// universe file. It follows the pattern:
/// ;phone;label;∞;∞;∞;∞;∞;∞;∞;∞;hash;
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LabelUniversePath {
    pub phone: String,
    pub label: String,
    pub path: String,
}

/// Minimal Minecraft client identifier.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct McClientId {
    /// Minecraft player UUID as a string.
    pub player_uuid: String,
}

/// Request from a Minecraft client to register / tune itself.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct McRegisterRequest {
    pub player_uuid: String,
    pub nickname: Option<String>,
    /// Planet id, e.g. "earth", "moon".
    pub planet_id: String,
    /// World name as seen in the server, e.g. "world", "earth_shell".
    pub world: String,
    /// Client frames per second (as measured by the plugin).
    pub client_fps: f64,
}

/// Response to /mc/register.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct McRegisterResponse {
    pub ok: bool,
    pub error: Option<String>,
    /// φ tick tuning for this client on this planet.
    pub tuning: Option<TickTuning>,
}

/// Type of Minecraft server node (vortex-style).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum McServerKind {
    /// Velocity proxy (front door).
    Velocity,
    /// Bungee / lobby level.
    Lobby,
    /// Actual gameplay world (Paper/Spigot).
    World,
    /// Geyser / Bedrock bridge or equivalent.
    BedrockProxy,
    /// Anything else or experimental.
    Other,
}

/// Request to register a Minecraft server node in the topology.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct McServerRegistrationRequest {
    /// Unique id for this server (can be host:port, or logical name).
    pub server_id: String,
    /// Human-readable label, e.g. "vortex-proxy", "lobby-1", "earth-shell-01".
    pub label: String,
    /// Kind of server (Velocity, Lobby, World, BedrockProxy, Other).
    pub kind: McServerKind,
    /// IP or host (if available).
    pub host: Option<String>,
    /// Port (if available).
    pub port: Option<u16>,
    /// Optional extra JSON metadata (e.g. current TPS, player count).
    pub metadata: Option<String>,
}

/// Server record stored in the universe.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct McServerRecord {
    pub server_id: String,
    pub label: String,
    pub kind: McServerKind,
    pub host: Option<String>,
    pub port: Option<u16>,
    pub metadata: Option<String>,
    pub last_seen_ms: i64,
}

/// Response to /mc/server_register.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct McServerRegistrationResponse {
    pub ok: bool,
    pub error: Option<String>,
    pub server: Option<McServerRecord>,
}

/// Errors that can occur when we apply high-level actions.
#[derive(Debug, thiserror::Error)]
pub enum SpecError {
    #[error("insufficient balance")]
    InsufficientBalance,
    #[error("unknown label: {0:?}")]
    UnknownLabel(LabelId),
    #[error("invalid amount")]
    InvalidAmount,
    #[error("generic: {0}")]
    Generic(String),
}
