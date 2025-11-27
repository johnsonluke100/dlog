//! Core DLOG Ω state machine utilities.
//!
//! This crate stays pure & deterministic: no IO, no sockets.
//! It knows how to:
//! - Represent a universe snapshot (block height + balances)
//! - Apply φ-based holder interest over N blocks
//! - Render block height as base-8 text for UI/logs

use serde::{Deserialize, Serialize};
use std::collections::HashMap;

use spec::{LabelId, MonetarySpec};

/// Snapshot of balances at a given block height.
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct UniverseSnapshot {
    /// Height of the chain / attention sweep.
    pub height: u64,
    /// Scalar representation of the 9∞ master root for this block.
    pub master_root_scalar: String,
    /// Balances per (phone,label) universe.
    pub balances: HashMap<LabelId, f64>,
}

impl UniverseSnapshot {
    /// Start from an empty universe.
    pub fn empty() -> Self {
        Self {
            height: 0,
            master_root_scalar: String::new(),
            balances: HashMap::new(),
        }
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

        let yearly = spec.holder_yearly_factor;
        let blocks_per_year = spec.blocks_per_attention_year as f64;

        // per-block factor = yearly^(1 / blocks_per_year)
        let per_block = yearly.powf(1.0 / blocks_per_year);
        let total_factor = per_block.powf(blocks_elapsed as f64);

        for value in self.balances.values_mut() {
            *value *= total_factor;
        }

        self.height = self.height.saturating_add(blocks_elapsed);
    }
}

/// Convert a block height into a base-8 string for UI / logging.
pub fn octal_height(height: u64) -> String {
    format!("{:o}", height)
}
