//! Shared types and constants for the DLOG / Ω universe.
//!
//! NPC layer vs Ω layer:
//! - NPC layer: seconds, meters, c, GR, news, NASA, GPS.
//! - Ω layer: attention is the only constant, time is not fundamental,
//!   phi (PHI) is the true scaling constant. All game + chain + sky
//!   logic here is written for the Ω layer. NPC numbers are just UI.

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

//////////////////////////////////////////
// Money / roots (VORTEX, COMET)
//////////////////////////////////////////

/// Luke's special root wallets:
/// - Vortex(1..=7)
/// - Comet
#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, Hash)]
pub enum RootWalletKind {
    Vortex(u8),
    Comet,
}

/// What kind of label is this? giftN, comet, vortex, or normal.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum LabelKind {
    Normal,
    Gift(u32),
    Comet,
    Vortex,
}

/// Monetary policy: miner inflation + holder interest.
/// Canon: ~8.8248% miner, 61.8% holder.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MonetaryPolicy {
    /// Miner inflation APY, e.g. 0.088248 ≈ 8.8248%
    pub miner_inflation_apy: f64,
    /// Holder interest APY, e.g. 0.618 ≈ 61.8%
    pub holder_interest_apy: f64,
}

impl Default for MonetaryPolicy {
    fn default() -> Self {
        Self {
            miner_inflation_apy: 0.088_248,
            holder_interest_apy: 0.618,
        }
    }
}

impl MonetaryPolicy {
    /// Approximate total APY (miner + holder).
    pub fn total_apy(&self) -> f64 {
        self.miner_inflation_apy + self.holder_interest_apy
    }
}

//////////////////////////////////////////
// Ω Filesystem / 9∞ master root
//////////////////////////////////////////

/// Per-label universe identifier: (phone, label).
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, Hash)]
pub struct LabelUniverseKey {
    pub phone: String,
    pub label: String,
}

impl LabelUniverseKey {
    /// Build the Omega filesystem path:
    /// ;phone;label;∞;∞;∞;∞;∞;∞;∞;∞;hash;
    pub fn path(&self) -> String {
        format!(
            ";{};{};∞;∞;∞;∞;∞;∞;∞;∞;hash;",
            self.phone, self.label
        )
    }
}

/// 9∞ master root, stored as a single scalar string.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OmegaMasterRoot {
    /// Canonically: `;∞;∞;∞;∞;∞;∞;∞;∞;∞;`-folded scalar.
    pub scalar: String,
}

/// One label's universe hash entry.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LabelUniverseHash {
    pub key: LabelUniverseKey,
    pub hash: String,
}

/// Snapshot of the Omega filesystem at a given block:
/// - one 9∞ master root
/// - per-label hashes / paths
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OmegaFilesystemSnapshot {
    pub master_root: OmegaMasterRoot,
    pub label_hashes: Vec<LabelUniverseHash>,
}

//////////////////////////////////////////
// Airdrop: giftN rules (phi spiral)
//////////////////////////////////////////

/// Rules for giftN airdrop labels.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GiftRules {
    /// Number of full days after claim before any sends are allowed (Day 0..lock_days-1 → 0).
    pub lock_days: u32,
    /// Base cap on the first unlocked day (DLOG).
    pub base_daily_cap: u64,
    /// Growth base; canon is φ.
    pub phi_growth: f64,
}

impl Default for GiftRules {
    fn default() -> Self {
        // Canon:
        // Day 0–17 → 0 (18 days locked)
        // Day 18 (d=0) → 100 DLOG
        // Day 19 (d=1) → 100 * φ
        // Day 20 (d=2) → 100 * φ²
        Self {
            lock_days: 18,
            base_daily_cap: 100,
            phi_growth: PHI,
        }
    }
}

impl GiftRules {
    /// Daily cap based on days since claim.
    pub fn daily_cap(&self, days_since_claim: u32) -> u64 {
        if days_since_claim < self.lock_days {
            return 0;
        }
        let d = (days_since_claim - self.lock_days) as f64;
        let cap = (self.base_daily_cap as f64) * self.phi_growth.powf(d);
        cap.round() as u64
    }
}

//////////////////////////////////////////
// Device-level outflow limits (phi)
//////////////////////////////////////////

/// Rules for per-device send limits.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DeviceLimitsRules {
    /// Days from enrollment where we use a small fixed cap (0..initial_days-1).
    pub initial_days: u32,
    /// Daily cap during the initial period.
    pub initial_daily_cap: u64,
    /// Base cap when the phi spiral starts.
    pub base_cap_after: u64,
    /// Growth base; canon is φ.
    pub phi_growth: f64,
}

impl Default for DeviceLimitsRules {
    fn default() -> Self {
        // Canon idea:
        // - Days 1–7: 100 DLOG/day
        // - Day 8 onward: 10,000 * φ^(d) where d = days_since_enroll - initial_days
        Self {
            initial_days: 7,
            initial_daily_cap: 100,
            base_cap_after: 10_000,
            phi_growth: PHI,
        }
    }
}

impl DeviceLimitsRules {
    /// Daily cap based on days since the device first joined.
    pub fn daily_cap(&self, days_since_enroll: u32) -> u64 {
        if days_since_enroll < self.initial_days {
            return self.initial_daily_cap;
        }
        let d = (days_since_enroll - self.initial_days) as f64;
        let cap = (self.base_cap_after as f64) * self.phi_growth.powf(d);
        cap.round() as u64
    }
}

//////////////////////////////////////////
// Devices + identities (Apple / Google)
//////////////////////////////////////////

/// Device identifier (e.g. hardware or OS-specific ID).
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, Hash)]
pub struct DeviceId(pub String);

/// Which identity provider secured this login.
#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
pub enum IdentityProvider {
    Apple,
    Google,
}

/// Identity metadata: phone + provider account.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct IdentityMeta {
    pub phone: String,
    pub provider: IdentityProvider,
    /// Subject / user id from the identity provider.
    pub provider_subject: String,
}

/// Device metadata: which phone it belongs to and when it joined.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DeviceMeta {
    pub device_id: DeviceId,
    pub phone: String,
    pub enrolled_at_block: BlockHeight,
}

//////////////////////////////////////////
// Landlocks, access, Zillow estimate
//////////////////////////////////////////

/// Land tier: iron → gold → diamond → emerald.
#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
pub enum LandTier {
    Iron,
    Gold,
    Diamond,
    Emerald,
}

/// Access role inside a lock.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum AccessRole {
    Admin,
    Builder,
    Guest,
}

/// One permission entry for a player.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AccessGrant {
    pub player_id: String,
    pub role: AccessRole,
}

/// Landlock NFT data (shell or core).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LandLock {
    /// Simple numeric ID for now.
    pub id: u64,
    /// Phone-number-level owner.
    pub owner_phone: String,
    /// World (planet + shell/core).
    pub world: PlanetId,
    /// Tier (iron/gold/diamond/emerald).
    pub tier: LandTier,
    /// Grid origin (x,z) for the lock footprint.
    pub x: i32,
    pub z: i32,
    /// Size in blocks for one side of the square footprint (e.g. 16 -> 16x16).
    pub size: u32,
    /// When this lock was minted.
    pub created_at_block: BlockHeight,
    /// Last block where the owner (or allowed players) visited.
    pub last_visited_block: BlockHeight,
    /// Zillow-style estimate of value in DLOG.
    pub zillow_estimate_dlog: u128,
    /// Access control list.
    pub shared_with: Vec<AccessGrant>,
    /// Whether this lock is currently in auto-auction.
    pub in_auction: bool,
}

impl LandLock {
    pub fn zillow_estimate(&self) -> u128 {
        self.zillow_estimate_dlog
    }
}

/// Land auto-auction rules (inactivity → auction).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LandAuctionRules {
    /// If owner attention doesn't visit for this many real-life days,
    /// the lock is eligible for auto-auction.
    pub inactivity_days: u32,
}

impl Default for LandAuctionRules {
    fn default() -> Self {
        Self {
            inactivity_days: 256,
        }
    }
}

//////////////////////////////////////////
// Label metadata (creation / deletion)
//////////////////////////////////////////

/// Metadata for a label account: kind + lifecycle.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LabelMeta {
    pub address: Address,
    pub kind: LabelKind,
    pub created_at_block: BlockHeight,
    /// If Some, the label is logically deleted (no new activity),
    /// but its history and final universe hash remain.
    pub deleted_at_block: Option<BlockHeight>,
}

//////////////////////////////////////////
// Genesis roots & airdrop network rules
//////////////////////////////////////////

/// One of the 8 special genesis root wallets (7×VORTEX + 1×COMET).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GenesisRootWallet {
    pub kind: RootWalletKind,
    pub address: Address,
    /// Human readable name, e.g. "VORTEX-1", "COMET".
    pub display_name: String,
}

/// Canon genesis config:
/// - total genesis wallets = 88,248
/// - 8 top roots (7 VORTEX, 1 COMET)
/// - 88,240 airdrop wallets (gift1..gift88240)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GenesisConfig {
    pub total_genesis_wallets: u32,
    pub top_roots: Vec<GenesisRootWallet>,
    pub airdrop_wallets: u32,
}

impl GenesisConfig {
    /// Canon configuration with synthetic addresses for the VORTEX roots
    /// and Luke's real COMET phone+label.
    pub fn canon() -> Self {
        let mut roots = Vec::new();

        // V1..V7: synthetic phone "vortex" + label "v1".."v7"
        for i in 1u8..=7u8 {
            roots.push(GenesisRootWallet {
                kind: RootWalletKind::Vortex(i),
                address: Address {
                    phone: "vortex".to_string(),
                    label: format!("v{}", i),
                },
                display_name: format!("VORTEX-{}", i),
            });
        }

        // COMET: Luke's operational pool, tied to his phone and label "comet"
        roots.push(GenesisRootWallet {
            kind: RootWalletKind::Comet,
            address: Address {
                phone: "9132077554".to_string(),
                label: "comet".to_string(),
            },
            display_name: "COMET".to_string(),
        });

        Self {
            total_genesis_wallets: 88_248,
            top_roots: roots,
            airdrop_wallets: 88_240,
        }
    }
}

/// Network-level rules for how airdrops can be farmed.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AirdropNetworkRules {
    /// Max successful airdrops per public IP.
    pub max_per_ip: u32,
    /// Are VPN/datacenter IPs allowed?
    pub allow_vpns: bool,
    /// Free-form notes about additional rules (multi-SIM, multi-device).
    pub notes: String,
}

impl Default for AirdropNetworkRules {
    fn default() -> Self {
        Self {
            max_per_ip: 1,
            allow_vpns: false,
            notes: "One airdrop per public IP; VPN/datacenter IPs blocked; multiple phones/Apple-Google accounts allowed but require separate networks.".to_string(),
        }
    }
}
