//! Core DLOG Ω state machine utilities.
//!
//! This crate stays pure & deterministic: no IO, no sockets.
//! It knows how to:
//! - Represent a universe snapshot (block height + balances)
//! - Apply φ-based holder interest over N blocks
//! - Render block height as base-8 text for UI/logs

mod shaless;

use serde::{Deserialize, Serialize};
use std::collections::HashMap;

use shaless::master_root_for;
use spec::{LabelId, MonetarySpec};

/// Snapshot of balances at a given block height.
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct UniverseSnapshot {
    /// Height of the chain / attention sweep.
    pub height: u64,
    /// sha-less Infinity-base representation of the 9∞ master root.
    pub master_root_infinity: String,
    /// Balances per (phone,label) universe.
    pub balances: HashMap<LabelId, f64>,
}

impl UniverseSnapshot {
    /// Start from an empty universe.
    pub fn empty() -> Self {
        let mut snapshot = Self {
            height: 0,
            balances: HashMap::new(),
            master_root_infinity: String::new(),
        };
        snapshot.refresh_master_root();
        snapshot
    }

    /// Apply φ-based holder interest over `blocks_elapsed` blocks.
    ///
    /// This directly mirrors the MonetarySpec:
    /// - holder_yearly_factor ≈ φ
    /// - blocks_per_attention_year ≈ 3.9M (octal literal in spec)
    pub fn apply_holder_interest(&mut self, blocks_elapsed: u64, spec: &MonetarySpec) {
        if blocks_elapsed == 0 {
            return;
        }

        let yearly = 1.0 + spec.holder_interest_apy;
        let blocks_per_year = (365.0 * 24.0 * 60.0 * 60.0) / spec.target_block_seconds;

        // per-block factor = yearly^(1 / blocks_per_year)
        let per_block = yearly.powf(1.0 / blocks_per_year);
        let total_factor = per_block.powf(blocks_elapsed as f64);

        for value in self.balances.values_mut() {
            *value *= total_factor;
        }

        self.height = self.height.saturating_add(blocks_elapsed);
        self.refresh_master_root();
    }

    fn refresh_master_root(&mut self) {
        self.master_root_infinity = master_root_for(self.height, &self.balances);
    }
}

/// Convert a block height into a base-8 string for UI / logging.
pub fn octal_height(height: u64) -> String {
    format!("{:o}", height)
}
