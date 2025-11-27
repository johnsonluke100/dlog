// corelib/src/lib.rs
//
// Universe state machine placeholder.
//
// - In-memory maps for label balances.
// - Simple transfer logic.
// - Snapshot folding that increments a height counter.

use std::collections::HashMap;

use serde::{Deserialize, Serialize};
use spec::{Balance, LabelId, SpecError, TransferTx, UniverseSnapshot};

/// UniverseState (temporary, in-memory only).
#[derive(Debug, Default, Clone, Serialize, Deserialize)]
pub struct UniverseState {
    /// Balance per label.
    pub balances: HashMap<LabelId, Balance>,
    /// The last known snapshot, if any.
    pub last_snapshot: Option<UniverseSnapshot>,
}

impl UniverseState {
    /// Create a new empty universe state.
    pub fn new() -> Self {
        Self {
            balances: HashMap::new(),
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
    /// For now we just bump the height and store a simple string as the root.
    pub fn fold_snapshot(&mut self) -> UniverseSnapshot {
        let new_height = self
            .last_snapshot
            .as_ref()
            .map(|s| s.height + 1)
            .unwrap_or(0);

        let snapshot = UniverseSnapshot {
            height: new_height,
            master_root: format!(";∞;height;{};", new_height),
            timestamp_ms: Self::current_timestamp_ms(),
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
}
