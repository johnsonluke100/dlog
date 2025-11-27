//! DLOG Ω-universe shared spec types.
//!
//! Pure data: no IO, no networking, just the shapes of the universe:
//! - φ and monetary policy
//! - planets + φ-per-tick gravity profiles
//! - label / identity IDs
//! - land lock metadata
//! - Ω filesystem semicolon paths (;...;∞;∞;...)

use serde::{Deserialize, Serialize};
use std::fmt;

pub mod constants {
    //! Core Ω constants — φ and yearly factors.

    /// The golden ratio φ (double precision).
    pub const PHI: f64 = 1.618_033_988_749_894_f64;

    /// Blocks per "attention year" (approx 3.9M), stored as an octal literal.
    ///
    /// `0o16701140` (octal) = `3_900_000` (decimal).
    pub const BLOCKS_PER_ATTENTION_YEAR: u64 = 0o16701140;

    /// Miner annual inflation factor (~8.8248%).
    pub const MINER_YEARLY_FACTOR: f64 = 1.088_248_f64;

    /// Holder annual interest factor (≈ φ = 1.618…).
    pub const HOLDER_YEARLY_FACTOR: f64 = PHI;
}

pub mod ids {
    //! Identity + label IDs.

    /// Labels live at (phone_e164, label_name).
    ///
    /// Example: ("+19132077554", "comet"), ("+1913...", "gift123")
    #[derive(Clone, Debug, Eq, PartialEq, Hash, Serialize, Deserialize)]
    pub struct LabelId {
        pub phone_e164: String,
        pub label: String,
    }
}

pub mod cosmos {
    //! Planets, φ-per-tick gravity profiles, and global Ω-cosmology hooks.

    /// Which world / hollow body we’re talking about.
    #[derive(Clone, Copy, Debug, Serialize, Deserialize, Eq, PartialEq, Hash)]
    pub enum PlanetId {
        Earth,
        Moon,
        Mars,
        Sun,
    }

    /// φ exponents controlling acceleration & fall on a planet.
    #[derive(Clone, Copy, Debug, Serialize, Deserialize)]
    pub struct PhiGravityProfile {
        /// φ exponent used when the player accelerates while flying.
        pub flight_exp: f64,
        /// φ exponent used when the player falls back toward stillness.
        pub fall_exp: f64,
    }

    /// Gravity profile + name for a planet.
    #[derive(Clone, Copy, Debug, Serialize, Deserialize)]
    pub struct PlanetGravityProfile {
        pub id: PlanetId,
        pub name: &'static str,
        pub phi: PhiGravityProfile,
    }

    // NOTE: These exponents can be tuned later. For now:
    // - Earth = baseline φ^1
    // - Moon  = lighter feel (φ^0.5)
    // - Mars  = slightly lighter than Earth
    // - Sun   = heavier "plasma" gravity
    pub const EARTH_PROFILE: PlanetGravityProfile = PlanetGravityProfile {
        id: PlanetId::Earth,
        name: "earth",
        phi: PhiGravityProfile {
            flight_exp: 1.0,
            fall_exp: 1.0,
        },
    };

    pub const MOON_PROFILE: PlanetGravityProfile = PlanetGravityProfile {
        id: PlanetId::Moon,
        name: "moon",
        phi: PhiGravityProfile {
            flight_exp: 0.5,
            fall_exp: 0.5,
        },
    };

    pub const MARS_PROFILE: PlanetGravityProfile = PlanetGravityProfile {
        id: PlanetId::Mars,
        name: "mars",
        phi: PhiGravityProfile {
            flight_exp: 0.8,
            fall_exp: 0.8,
        },
    };

    pub const SUN_PROFILE: PlanetGravityProfile = PlanetGravityProfile {
        id: PlanetId::Sun,
        name: "sun",
        phi: PhiGravityProfile {
            flight_exp: 1.3,
            fall_exp: 1.3,
        },
    };

    /// All known planet gravity profiles.
    pub const PLANET_PROFILES: [PlanetGravityProfile; 4] = [
        EARTH_PROFILE,
        MOON_PROFILE,
        MARS_PROFILE,
        SUN_PROFILE,
    ];

    /// Get the φ-gravity profile for a given planet.
    pub fn profile(id: PlanetId) -> PlanetGravityProfile {
        match id {
            PlanetId::Earth => EARTH_PROFILE,
            PlanetId::Moon => MOON_PROFILE,
            PlanetId::Mars => MARS_PROFILE,
            PlanetId::Sun => SUN_PROFILE,
        }
    }

    impl fmt::Display for PlanetId {
        fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
            let s = match self {
                PlanetId::Earth => "earth",
                PlanetId::Moon => "moon",
                PlanetId::Mars => "mars",
                PlanetId::Sun => "sun",
            };
            f.write_str(s)
        }
    }
}

pub mod money {
    //! Monetary policy: miner + holder fire.
    use crate::constants::*;

    /// Encodes the Ω monetary policy in one struct for the API.
    #[derive(Clone, Debug, Serialize, Deserialize)]
    pub struct MonetarySpec {
        pub miner_yearly_factor: f64,
        pub holder_yearly_factor: f64,
        pub blocks_per_attention_year: u64,
    }

    impl Default for MonetarySpec {
        fn default() -> Self {
            Self {
                miner_yearly_factor: MINER_YEARLY_FACTOR,
                holder_yearly_factor: HOLDER_YEARLY_FACTOR,
                blocks_per_attention_year: BLOCKS_PER_ATTENTION_YEAR,
            }
        }
    }

    /// Holder compounding factor for a single block / attention-tick.
    pub fn per_block_holder_factor() -> f64 {
        HOLDER_YEARLY_FACTOR.powf(1.0 / BLOCKS_PER_ATTENTION_YEAR as f64)
    }

    /// Miner compounding factor for a single block / attention-tick.
    pub fn per_block_miner_factor() -> f64 {
        MINER_YEARLY_FACTOR.powf(1.0 / BLOCKS_PER_ATTENTION_YEAR as f64)
    }
}

pub mod omega_fs {
    //! Ω filesystem paths — everything under https://dloG.com/∞/
    use crate::ids::LabelId;

    /// What kind of Ω file a path represents.
    #[derive(Clone, Debug, Serialize, Deserialize)]
    pub enum OmegaFileKind {
        /// The single 9∞ Master Root file.
        MasterRoot9Inf,
        /// A per-label universe hash file (;phone;label;…;hash;).
        LabelUniverseHash,
    }

    /// An Ω filesystem path with semantic meaning.
    #[derive(Clone, Debug, Serialize, Deserialize)]
    pub struct OmegaFsPath {
        pub raw: String,
        pub kind: OmegaFileKind,
    }

    /// The canonical 9∞ root path.
    pub const MASTER_ROOT_PATH: &str = ";∞;∞;∞;∞;∞;∞;∞;∞;∞;";

    /// Convenience constructor for the 9∞ master root path.
    pub fn master_root() -> OmegaFsPath {
        OmegaFsPath {
            raw: MASTER_ROOT_PATH.to_string(),
            kind: OmegaFileKind::MasterRoot9Inf,
        }
    }

    /// Build the per-label universe hash path:
    /// ;<phone>;<label>;∞;∞;∞;∞;∞;∞;∞;∞;hash;
    pub fn label_hash_path(label: &LabelId) -> OmegaFsPath {
        let raw = format!(
            ";{};{};∞;∞;∞;∞;∞;∞;∞;∞;hash;",
            label.phone_e164, label.label
        );
        OmegaFsPath {
            raw,
            kind: OmegaFileKind::LabelUniverseHash,
        }
    }
}

pub mod land {
    //! Land locks, tiers, and metadata.
    use crate::cosmos::PlanetId;

    /// Lock tiers — grid footprints scale roughly ×10 per tier.
    #[derive(Clone, Copy, Debug, Serialize, Deserialize)]
    pub enum LockTier {
        Iron,
        Gold,
        Diamond,
        Emerald,
    }

    /// Identity of a specific land lock column.
    #[derive(Clone, Debug, Serialize, Deserialize)]
    pub struct LandLockId {
        pub world: PlanetId,
        pub tier: LockTier,
        /// Grid origin x (overworld / shell coordinates).
        pub origin_x: i64,
        /// Grid origin z (overworld / shell coordinates).
        pub origin_z: i64,
    }

    /// Metadata for auctions, Zillow-style value, etc.
    #[derive(Clone, Debug, Serialize, Deserialize)]
    pub struct LandLockMetadata {
        pub owner_phone_e164: String,
        pub created_at_block: u64,
        pub last_visited_block: u64,
        pub zillow_estimate_dlog: f64,
    }
}

// Re-export the most useful pieces at the crate root for convenience.
pub use constants::*;
pub use cosmos::*;
pub use ids::*;
pub use land::*;
pub use money::*;
pub use omega_fs::*;
