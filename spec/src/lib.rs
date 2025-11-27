//! Shared types and constants for the DLOG / Ω universe.
//!
//! This also carries the "descriptor" side for sky / slideshow state,
//! while the heavy lifting is done in the `dlog-sky` crate.

use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// Golden ratio constant.
pub const PHI: f64 = 1.618_033_988_75;

/// Default phi tick rate used by the Omega engine (Hz).
pub const PHI_TICK_HZ: f64 = 8_888.0;

/// Generic block height.
pub type BlockHeight = u64;

/// Address = (phone, label)
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, Hash)]
pub struct Address {
    pub phone: String,
    pub label: String,
}

/// Planet / world identity. Shell vs core mirrors your hollow-sphere design.
#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, Hash)]
pub enum PlanetId {
    EarthShell,
    EarthCore,
    MoonShell,
    MoonCore,
    MarsShell,
    MarsCore,
    SunShell,
    SunCore,
}

/// Simple amount representation in base DLOG units.
#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, PartialOrd, Ord)]
pub struct Amount {
    pub dlog: u128,
}

impl Amount {
    pub const ZERO: Amount = Amount { dlog: 0 };

    pub fn new(dlog: u128) -> Self {
        Self { dlog }
    }

    pub fn saturating_add(self, other: Amount) -> Amount {
        Amount {
            dlog: self.dlog.saturating_add(other.dlog),
        }
    }

    pub fn saturating_sub(self, other: Amount) -> Amount {
        Amount {
            dlog: self.dlog.saturating_sub(other.dlog),
        }
    }
}

/// One account in the universe.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AccountState {
    pub address: Address,
    pub planet: PlanetId,
    pub balance: Amount,
}

/// Per-planet gravity exponent relative to PHI, e.g. phi^k per tick.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlanetGravity {
    pub planet: PlanetId,
    pub phi_exponent: f64,
}

/// Universe config reflecting your Ω-spec knobs.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UniverseConfig {
    /// Base phi tick rate (Hz) used by the engine.
    pub phi_tick_hz: f64,
    /// Default gravity exponent for planets that don't override it.
    pub default_gravity_phi_exponent: f64,
    /// Planet-specific overrides.
    pub planet_gravity: Vec<PlanetGravity>,
}

impl Default for UniverseConfig {
    fn default() -> Self {
        Self {
            phi_tick_hz: PHI_TICK_HZ,
            default_gravity_phi_exponent: 4.0,
            planet_gravity: vec![],
        }
    }
}

/// Simple in-memory universe snapshot.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UniverseSnapshot {
    pub height: BlockHeight,
    pub accounts: HashMap<Address, AccountState>,
}

//////////////////////////////////////////
// Sky descriptor side (ported from `sky`)
//////////////////////////////////////////

/// One slide in a sky slideshow, referencing an image path and duration.
///
/// Think of this as the "ProcessedImage" / "SlideshowFrame" pairing
/// from your SkyLighting Java world, but stripped to metadata only.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SkySlideRef {
    pub id: u32,
    /// Relative path, e.g. "slides/1.jpg"
    pub path: String,
    /// How many phi-ticks this slide should be displayed.
    pub duration_ticks: u64,
}

/// A sky show (slideshow) bound to a label / world key.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SkyShowConfig {
    pub name: String,
    pub slides: Vec<SkySlideRef>,
}

impl SkyShowConfig {
    /// Convenience: make a default 8-frame show: 1.jpg..8.jpg,
    /// each shown for the same duration.
    pub fn default_eight() -> Self {
        let duration_ticks = 8_888; // one second at 8_888 Hz as a starting point
        let mut slides = Vec::new();
        for id in 1u32..=8 {
            slides.push(SkySlideRef {
                id,
                path: format!("slides/{}.jpg", id),
                duration_ticks,
            });
        }
        Self {
            name: "default_eight".to_string(),
            slides,
        }
    }
}
