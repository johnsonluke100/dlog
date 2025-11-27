// Ω: identifier for which planet/realm this monetary binding is attached.
pub type PlanetId = String;


//
// === Ω auto: LabelId + MonetarySpec (do not edit by hand) ===================
//
// These are the public monetary / label types expected by corelib:
//
//   use spec::{LabelId, MonetarySpec};
//
// The exact fields can evolve, but the names and basic shape stay stable.
//

#[derive(Clone, Debug, Eq, PartialEq, Hash, serde::Serialize, serde::Deserialize)]
pub struct LabelId {
    /// Phone number in NPC space (E.164-ish, as string).
    pub phone: String,
    /// Human label, e.g. "fun", "savings", "gift123".
    pub label: String,
}

#[derive(Clone, Debug, serde::Serialize, serde::Deserialize)]
pub struct MonetarySpec {
    /// Miner inflation APY as a fraction (0.088248 ≃ 8.8248%).
    pub miner_inflation_apy: f64,
    /// Holder interest APY as a fraction (0.618 ≃ 61.8%).
    pub holder_interest_apy: f64,
    /// Target block interval in NPC seconds (~8s, but Ω-side it's "one tick").
    pub target_block_seconds: f64,
}

impl Default for MonetarySpec {
    fn default() -> Self {
        Self {
            miner_inflation_apy: 0.088248,
            holder_interest_apy: 0.618,
            target_block_seconds: 8.0,
        }
    }
}

// === Ω auto end: LabelId + MonetarySpec =====================================

