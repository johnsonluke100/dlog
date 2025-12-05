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
/// Default φ tick rate in Hz (Omega Leidenfrost heartbeat).
pub const PHI_TICK_HZ: f64 = 8_888.0;

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

//
// Sky (slideshow) spec — minimal for API exposure
//

#[derive(Clone, Debug, serde::Serialize, serde::Deserialize)]
pub struct SkySlideRef {
    pub id: String,
    pub duration_ticks: u64,
}

#[derive(Clone, Debug, serde::Serialize, serde::Deserialize)]
pub struct SkyShowConfig {
    pub slides: Vec<SkySlideRef>,
}

impl SkyShowConfig {
    pub fn default_eight() -> Self {
        // Eight slides, each 888 ticks by default.
        let mut slides = Vec::with_capacity(8);
        for i in 0..8 {
            slides.push(SkySlideRef {
                id: format!("slide-{}", i + 1),
                duration_ticks: 888,
            });
        }
        SkyShowConfig { slides }
    }
}

//
// Ω simulation API (shared tick/view contract)
//

/// 3D vector used for positions and velocities.
#[derive(Clone, Copy, Debug, serde::Serialize, serde::Deserialize, Default)]
pub struct Vec3 {
    pub x: f64,
    pub y: f64,
    pub z: f64,
}

/// Player pose reported by the client.
#[derive(Clone, Copy, Debug, serde::Serialize, serde::Deserialize, Default)]
pub struct Pose {
    pub pos: Vec3,
    pub yaw: f32,
    pub pitch: f32,
}

/// Raw input flags from the client.
#[derive(Clone, Debug, serde::Serialize, serde::Deserialize, Default)]
pub struct InputState {
    pub forward: bool,
    pub back: bool,
    pub left: bool,
    pub right: bool,
    pub jump: bool,
    pub sneak: bool,
}

/// Request from Paper client to the Ω sim endpoint.
#[derive(Clone, Debug, serde::Serialize, serde::Deserialize, Default)]
pub struct SimTickRequest {
    pub player_id: String,
    #[serde(default)]
    pub pose: Pose,
    #[serde(default)]
    pub inputs: InputState,
    #[serde(default)]
    pub client_time_ms: Option<u64>,
}

/// One logical render anchor (e.g., origin, planets).
#[derive(Clone, Debug, serde::Serialize, serde::Deserialize)]
pub struct Anchor {
    pub id: String,
    pub kind: String,
    pub pos: Vec3,
}

/// Entity to render (armor stand, particle anchor, etc).
#[derive(Clone, Debug, serde::Serialize, serde::Deserialize)]
pub struct RenderEntity {
    pub id: String,
    pub kind: String,
    pub pos: Vec3,
    pub yaw: f32,
    pub pitch: f32,
}

/// Barrier/collision hint for the client.
#[derive(Clone, Debug, serde::Serialize, serde::Deserialize, Default)]
pub struct Barrier {
    pub min: Vec3,
    pub max: Vec3,
}

/// UI overlay hints (hotbar/action bar, titles).
#[derive(Clone, Debug, serde::Serialize, serde::Deserialize, Default)]
pub struct UiOverlay {
    #[serde(default)]
    pub title: String,
    #[serde(default)]
    pub hotbar: Vec<String>,
}

/// View slice returned to the client.
#[derive(Clone, Debug, serde::Serialize, serde::Deserialize, Default)]
pub struct SimView {
    #[serde(default)]
    pub anchors: Vec<Anchor>,
    #[serde(default)]
    pub entities: Vec<RenderEntity>,
    #[serde(default)]
    pub barriers: Vec<Barrier>,
    #[serde(default)]
    pub ui: UiOverlay,
}

/// Response from the Ω sim endpoint.
#[derive(Clone, Debug, serde::Serialize, serde::Deserialize)]
pub struct SimTickResponse {
    pub tick: u64,
    pub state_version: String,
    pub server_time_ms: u64,
    pub view: SimView,
}
