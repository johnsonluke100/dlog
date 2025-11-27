// corelib/src/lib.rs
//
// Universe state machine + φ-gravity + Ω filesystem helpers + landlocks + tick tuning.
//
// - In-memory maps for label balances.
// - Simple transfer logic.
// - Snapshot folding that increments a height counter,
//   with a 9∞-style master_root string.
// - Planet list and φ^?-per-tick gravity profiles.
// - LabelUniversePath constructor for Ω paths.
// - Land lock registry in-memory.
// - compute_tick_tuning to map server φ-ticks → client frames.

use std::collections::HashMap;

use serde::{Deserialize, Serialize};
use spec::{
    Balance, BlockHeight, LabelId, LabelUniversePath, LandLock, PhiGravityProfile, PlanetSpec,
    SpecError, TickTuning, TransferTx, UniverseSnapshot,
};

/// PHI = golden ratio, used as the Ω scaling constant.
pub const PHI: f64 = 1.618_033_988_749_895_f64;

/// UniverseState (temporary, in-memory only).
#[derive(Debug, Default, Clone, Serialize, Deserialize)]
pub struct UniverseState {
    /// Balance per label.
    pub balances: HashMap<LabelId, Balance>,
    /// Registered land locks.
    pub land_locks: Vec<LandLock>,
    /// The last known snapshot, if any.
    pub last_snapshot: Option<UniverseSnapshot>,
}

impl UniverseState {
    /// Create a new empty universe state.
    pub fn new() -> Self {
        Self {
            balances: HashMap::new(),
            land_locks: Vec::new(),
            last_snapshot: None,
        }
    }

    /// Get current balance for a label; returns zero if absent.
    pub fn balance_of(&self, label: &LabelId) -> Balance {
        self.balances
            .get(label)
            .copied()
            .unwrap_or(Balance { amount: 0 })
    }

    /// Set balance for a label.
    pub fn set_balance(&mut self, label: LabelId, balance: Balance) {
        self.balances.insert(label, balance);
    }

    /// Apply a simple transfer transaction.
    ///
    /// Placeholder for now; later we integrate:
    /// - holder interest
    /// - miner inflation
    /// - tithe flows
    /// - device / label limits
    pub fn apply_transfer(&mut self, tx: &TransferTx) -> Result<(), SpecError> {
        if tx.amount == 0 {
            return Err(SpecError::InvalidAmount);
        }

        let from_balance = self.balance_of(&tx.from);
        if from_balance.amount < tx.amount {
            return Err(SpecError::InsufficientBalance);
        }

        let to_balance = self.balance_of(&tx.to);

        let new_from = Balance {
            amount: from_balance.amount - tx.amount,
        };
        let new_to = Balance {
            amount: to_balance.amount + tx.amount,
        };

        self.set_balance(tx.from.clone(), new_from);
        self.set_balance(tx.to.clone(), new_to);

        Ok(())
    }

    /// Fold the current state into a UniverseSnapshot.
    /// We bump the height and encode a 9∞-style master root.
    pub fn fold_snapshot(&mut self) -> UniverseSnapshot {
        let new_height: BlockHeight = self
            .last_snapshot
            .as_ref()
            .map(|s| s.height + 1)
            .unwrap_or(0);

        let timestamp_ms = Self::current_timestamp_ms();
        let master_root = Self::encode_master_root(new_height, timestamp_ms);

        let snapshot = UniverseSnapshot {
            height: new_height,
            master_root,
            timestamp_ms,
        };

        self.last_snapshot = Some(snapshot.clone());
        snapshot
    }

    fn current_timestamp_ms() -> i64 {
        use std::time::{SystemTime, UNIX_EPOCH};
        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default();
        now.as_millis() as i64
    }

    /// Encode the 9∞ master root string for a given height/timestamp.
    ///
    /// Pattern:
    /// ;∞;∞;∞;∞;∞;∞;∞;∞;∞;height;<H>;time;<T>;
    fn encode_master_root(height: BlockHeight, timestamp_ms: i64) -> String {
        format!(
            ";∞;∞;∞;∞;∞;∞;∞;∞;∞;height;{};time;{};",
            height, timestamp_ms
        )
    }

    /// Immutable view of all land locks.
    pub fn all_land_locks(&self) -> &[LandLock] {
        &self.land_locks
    }

    /// Return all land locks, optionally filtered by world.
    pub fn locks_by_world(&self, world: Option<&str>) -> Vec<LandLock> {
        match world {
            Some(w) => self
                .land_locks
                .iter()
                .filter(|l| l.world == w)
                .cloned()
                .collect(),
            None => self.land_locks.clone(),
        }
    }

    /// Mint a new land lock into the universe.
    ///
    /// If `lock.id` is empty, we assign a simple deterministic id
    /// based on world/x/z/tier.
    pub fn mint_lock(&mut self, mut lock: LandLock) -> LandLock {
        if lock.id.is_empty() {
            lock.id = format!("{}:{}:{}:{}", lock.world, lock.x, lock.z, lock.tier);
        }
        self.land_locks.push(lock.clone());
        lock
    }
}

/// Default Ω planets with φ exponents for fall and fly.
///
/// You can tune these exponents to feel right in-game.
/// Rough sketch:
/// - Earth: baseline.
/// - Moon: softer fall, snappier fly.
/// - Mars: somewhere in between, more drift.
/// - Sun: extreme (mostly for lore / special zones).
pub fn default_planets() -> Vec<PlanetSpec> {
    vec![
        PlanetSpec {
            id: "earth".to_string(),
            name: "Earth".to_string(),
            shell_world: "earth_shell".to_string(),
            core_world: "earth_core".to_string(),
            phi_power_fall: 2.0,
            phi_power_fly: 1.0,
        },
        PlanetSpec {
            id: "moon".to_string(),
            name: "Moon".to_string(),
            shell_world: "moon_shell".to_string(),
            core_world: "moon_core".to_string(),
            phi_power_fall: 1.0,
            phi_power_fly: 0.5,
        },
        PlanetSpec {
            id: "mars".to_string(),
            name: "Mars".to_string(),
            shell_world: "mars_shell".to_string(),
            core_world: "mars_core".to_string(),
            phi_power_fall: 1.5,
            phi_power_fly: 0.8,
        },
        PlanetSpec {
            id: "sun".to_string(),
            name: "Sun".to_string(),
            shell_world: "sun_shell".to_string(),
            core_world: "sun_core".to_string(),
            phi_power_fall: 3.0,
            phi_power_fly: 2.0,
        },
    ]
}

/// Compute the φ^?-per-tick gravity profile for a given planet id.
pub fn compute_phi_gravity(planet_id: &str) -> Option<PhiGravityProfile> {
    let planets = default_planets();
    let planet = planets.into_iter().find(|p| p.id == planet_id)?;
    let g_fall = PHI.powf(planet.phi_power_fall);
    let g_fly = PHI.powf(planet.phi_power_fly);

    Some(PhiGravityProfile {
        planet_id: planet.id,
        phi_power_fall: planet.phi_power_fall,
        phi_power_fly: planet.phi_power_fly,
        g_fall,
        g_fly,
    })
}

/// Build the canonical Ω filesystem path for a (phone, label) universe file.
///
/// Pattern:
/// ;phone;label;∞;∞;∞;∞;∞;∞;∞;∞;hash;
pub fn label_universe_path(phone: &str, label: &str) -> LabelUniversePath {
    let path = format!(
        ";{};{};∞;∞;∞;∞;∞;∞;∞;∞;hash;",
        phone, label
    );

    LabelUniversePath {
        phone: phone.to_string(),
        label: label.to_string(),
        path,
    }
}

/// Compute how server φ-ticks map into client frames for a given planet.
///
/// - `phi_tick_rate` = conceptual server ticks per second from config.
/// - `client_fps`    = frames per second on the client.
/// - `planet_id`     = which planet's φ-exponents to use.
///
/// Returns a TickTuning that the game client can plug directly into its
/// per-frame velocity integration.
pub fn compute_tick_tuning(
    phi_tick_rate: f64,
    client_fps: f64,
    planet_id: &str,
) -> Option<TickTuning> {
    if client_fps <= 0.0 {
        return None;
    }

    let profile = compute_phi_gravity(planet_id)?;

    // Conceptually, how many φ-ticks do we traverse per rendered frame?
    let ticks_per_frame = phi_tick_rate / client_fps;

    let effective_delta_fall_per_frame = profile.g_fall * ticks_per_frame;
    let effective_delta_fly_per_frame = profile.g_fly * ticks_per_frame;

    Some(TickTuning {
        planet_id: profile.planet_id.clone(),
        client_fps,
        server_phi_tick_rate: phi_tick_rate,
        ticks_per_frame,
        phi_power_fall: profile.phi_power_fall,
        phi_power_fly: profile.phi_power_fly,
        g_fall: profile.g_fall,
        g_fly: profile.g_fly,
        effective_delta_fall_per_frame,
        effective_delta_fly_per_frame,
    })
}
