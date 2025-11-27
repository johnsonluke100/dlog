//! Core logic for the DLOG / Ω universe state machine.

use dlog_spec::{AccountState, Address, Amount, PlanetId, UniverseConfig, UniverseSnapshot};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use thiserror::Error;

/// Errors that can occur when mutating universe state.
#[derive(Debug, Error)]
pub enum UniverseError {
    #[error("insufficient balance")]
    InsufficientBalance,
    #[error("unknown account")]
    UnknownAccount,
}

/// Mutable universe state kept in memory.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UniverseState {
    pub height: u64,
    pub accounts: HashMap<Address, AccountState>,
    pub config: UniverseConfig,
}

impl UniverseState {
    pub fn new(config: UniverseConfig) -> Self {
        Self {
            height: 0,
            accounts: HashMap::new(),
            config,
        }
    }

    pub fn snapshot(&self) -> UniverseSnapshot {
        UniverseSnapshot {
            height: self.height,
            accounts: self.accounts.clone(),
        }
    }

    pub fn upsert_account(&mut self, account: AccountState) {
        self.accounts.insert(account.address.clone(), account);
    }

    fn account_mut(&mut self, addr: &Address) -> Result<&mut AccountState, UniverseError> {
        self.accounts.get_mut(addr).ok_or(UniverseError::UnknownAccount)
    }

    pub fn transfer(
        &mut self,
        from: &Address,
        to: &Address,
        amount: Amount,
    ) -> Result<(), UniverseError> {
        if amount.dlog == 0 {
            return Ok(());
        }

        {
            let from_acc = self.account_mut(from)?;
            if from_acc.balance.dlog < amount.dlog {
                return Err(UniverseError::InsufficientBalance);
            }
            from_acc.balance = from_acc.balance.saturating_sub(amount);
        }

        {
            let to_acc = self
                .accounts
                .entry(to.clone())
                .or_insert(AccountState {
                    address: to.clone(),
                    planet: PlanetId::EarthShell,
                    balance: Amount::ZERO,
                });
            to_acc.balance = to_acc.balance.saturating_add(amount);
        }

        Ok(())
    }

    /// Apply one phi-based holder-interest tick to all balances.
    ///
    /// This approximates 61.8% APY by compounding every phi-tick.
    pub fn apply_interest_tick(&mut self) {
        // For now, use a simple approximation: one tiny growth per "block".
        // APY = (1 + r)^(ticks_per_year) - 1 ≈ 0.618
        // We can refine this later with a real formula or table.
        let ticks_per_year = self.config.phi_tick_hz * 3600.0 * 24.0 * 365.0;
        let base = 1.618_f64;
        let r_per_year = base - 1.0; // ~0.618
        let r_per_tick = r_per_year / ticks_per_year.max(1.0);

        for account in self.accounts.values_mut() {
            let before = account.balance.dlog as f64;
            let after = before * (1.0 + r_per_tick);
            account.balance.dlog = after.round() as u128;
        }
    }

    /// Advance one "block"/attention tick.
    pub fn tick_block(&mut self) {
        self.height = self.height.saturating_add(1);
        self.apply_interest_tick();
    }
}
