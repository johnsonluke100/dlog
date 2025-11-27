//! High-level coordination helpers between the Omega engine and the universe state.

use dlog_corelib::UniverseState;
use dlog_spec::UniverseConfig;

/// Initialize a default universe state for a single node.
pub fn init_universe() -> UniverseState {
    UniverseState::new(UniverseConfig::default())
}
