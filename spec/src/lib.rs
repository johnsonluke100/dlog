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


//
// Ω-Physics planetary gravity profile + φ constant.
// This is deliberately minimal and can be extended later without
// breaking the public interface.
//

/// Golden ratio, used as Ω scaling constant.
pub const PHI: f64 = 1.618_033_988_749_894;

#[derive(Clone, Copy, Debug, serde::Serialize, serde::Deserialize)]
pub struct PlanetGravityProfile {
    /// Symbolic key for this body, e.g. "sun", "earth", "moon", "mars".
    pub key: &'static str,
    /// Approx surface gravity in m/s² in NPC-physics terms.
    pub surface_gravity_mps2: f64,
    /// Approx shell radius in meters for the hollow sphere shell.
    pub shell_radius_m: f64,
    /// Approx core radius in meters for the inner hollow-sphere boundary.
    pub core_radius_m: f64,
}

/// Minimal Ω planet table for the API layer.
/// You can extend this list as the simulation grows.
pub const PLANET_PROFILES: &[PlanetGravityProfile] = &[
    PlanetGravityProfile {
        key: "sun",
        surface_gravity_mps2: 274.0,
        shell_radius_m: 695_700_000.0,
        core_radius_m: 0.2 * 695_700_000.0,
    },
    PlanetGravityProfile {
        key: "earth",
        surface_gravity_mps2: 9.806_65,
        shell_radius_m: 6_371_000.0,
        core_radius_m: 3_500_000.0,
    },
    PlanetGravityProfile {
        key: "moon",
        surface_gravity_mps2: 1.62,
        shell_radius_m: 1_737_100.0,
        core_radius_m: 1_000_000.0,
    },
    PlanetGravityProfile {
        key: "mars",
        surface_gravity_mps2: 3.711,
        shell_radius_m: 3_389_500.0,
        core_radius_m: 1_800_000.0,
    },
];
