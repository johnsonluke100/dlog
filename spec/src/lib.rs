// spec/src/lib.rs
//
// Shared types / models for the dlog universe:
// - Labels, balances, land locks
// - Node config
// - Planets + φ-gravity profiles
// - Ω filesystem helpers (label universe path)

use serde::{Deserialize, Serialize};

/// BlockHeight represents the chain height.
pub type BlockHeight = u64;

/// A simple label identifier: phone number + label name.
/// This is how we refer to a "slice" of the universe belonging to a person.
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
/// This will get richer as we expand the land system.
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

/// Simple transfer transaction placeholder; will grow over time
/// into the full transaction set for dlog.
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

/// LabelUniversePath encodes the Ω filesystem path for a (phone, label)
/// universe file. It follows the pattern:
/// ;phone;label;∞;∞;∞;∞;∞;∞;∞;∞;hash;
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LabelUniversePath {
    pub phone: String,
    pub label: String,
    pub path: String,
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
