// spec/src/lib.rs
//
// Shared types / models for the dlog universe.

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

//
// Ω-monetary spec: auto-added by refold.command
// This keeps corelib happy with spec::MonetarySpec while staying faithful
// to the DLOG design (miner inflation + holder interest + φ-tuned block time).

/// Ω-monetary parameters for a given DLOG universe.
/// Values are expressed as fractional rates (0.088248 = 8.8248%).
#[derive(Clone, Copy, Debug, serde::Serialize, serde::Deserialize)]
pub struct MonetarySpec {
    /// Annual miner inflation (e.g. 0.088248 for 8.8248%).
    pub annual_miner_inflation: f64,
    /// Annual holder interest (e.g. 0.618 for 61.8%).
    pub annual_holder_interest: f64,
    /// Target human-facing block time in seconds (approximate).
    pub target_block_time_seconds: f64,
    /// Numeric base for Ω accounting (should be 8 in DLOG).
    pub numeric_base: u32,
}

impl MonetarySpec {
    /// Create a new monetary spec with explicit parameters.
    pub const fn new(
        annual_miner_inflation: f64,
        annual_holder_interest: f64,
        target_block_time_seconds: f64,
        numeric_base: u32,
    ) -> Self {
        Self {
            annual_miner_inflation,
            annual_holder_interest,
            target_block_time_seconds,
            numeric_base,
        }
    }

    /// Canonical DLOG mainnet Ω-physics monetary spec.
    pub fn dlog_mainnet() -> Self {
        Self::new(0.088_248, 0.618, 8.0, 8)
    }
}

impl Default for MonetarySpec {
    fn default() -> Self {
        Self::dlog_mainnet()
    }
}

/// Binding between a planet and a monetary spec.
/// This is mostly a convenience for corelib/api layers.
#[derive(Clone, Copy, Debug, serde::Serialize, serde::Deserialize)]
pub struct PlanetMonetaryBinding {
    pub planet: PlanetId,
    pub spec: MonetarySpec,
}

impl std::fmt::Display for PlanetMonetaryBinding {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "{}(miner={:.4}%, holder={:.4}%, base={}, ~{}s)",
            self.planet,
            self.spec.annual_miner_inflation * 100.0,
            self.spec.annual_holder_interest * 100.0,
            self.spec.numeric_base,
            self.spec.target_block_time_seconds,
        )
    }
}

/// Canonical Ω-physics monetary spec constant.
pub const DLOG_MAINNET_SPEC: MonetarySpec = MonetarySpec {
    annual_miner_inflation: 0.088_248,
    annual_holder_interest: 0.618,
    target_block_time_seconds: 8.0,
    numeric_base: 8,
};

