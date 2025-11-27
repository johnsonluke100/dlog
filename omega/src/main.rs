//! Omega Phi 8888 Hz "Leidenfrost Flame Engine" in Rust.
//!
//! This is the Rust replacement for your old `omega_numpy_container`:
//! - Reads OMEGA_ROOT
//! - Prints the Omega banners
//! - Ticks in a tight loop at ~phi tick rate
//! - Does NOT do audio yet; it's an endless tuning fork heartbeat.

use anyhow::Result;
use clap::Parser;
use dlog_spec::{PHI, PHI_TICK_HZ};
use std::env;
use std::time::{Duration, Instant};

#[derive(Debug, Parser)]
#[command(
    name = "dlog-omega",
    about = "Omega Phi 8888 Hz Leidenfrost Flame Engine (Rust)"
)]
struct Args {
    /// Tick rate in Hz (default matches PHI_TICK_HZ)
    #[arg(long, default_value_t = PHI_TICK_HZ)]
    phi_tick_hz: f64,

    /// Planet gravity exponent baseline (phi^k per tick)
    #[arg(long, default_value_t = 4.0)]
    gravity_phi_exponent: f64,
}

fn main() -> Result<()> {
    let args = Args::parse();

    let omega_root = env::var("OMEGA_ROOT").unwrap_or_else(|_| ".".to_string());

    println!("=== Omega Phi 8888 Hz Leidenfrost Flame Engine (Rust) ===");
    println!("[+] OMEGA_ROOT : {omega_root}");
    println!("[+] PHI        : {PHI}");
    println!(
        "[+] phi_tick_hz: {} (requested), default = {}",
        args.phi_tick_hz, PHI_TICK_HZ
    );
    println!(
        "[+] gravity    : phi^{} per tick (baseline, per-planet can override)",
        args.gravity_phi_exponent
    );
    println!("=== ENDLESS TUNING FORK, WARM + PRESENCE (RUST) ===");

    let tick_duration_ns = if args.phi_tick_hz <= 0.0 {
        0.0
    } else {
        1_000_000_000.0 / args.phi_tick_hz
    };

    let tick_duration = if tick_duration_ns <= 0.0 {
        Duration::from_millis(1)
    } else {
        Duration::from_nanos(tick_duration_ns as u64)
    };

    let mut ticks: u64 = 0;
    let mut last_log = Instant::now();
    let mut last_tick = Instant::now();

    loop {
        let now = Instant::now();
        if now < last_tick + tick_duration {
            let remaining = (last_tick + tick_duration).saturating_duration_since(now);
            std::thread::sleep(remaining);
        }
        last_tick = Instant::now();
        ticks = ticks.wrapping_add(1);

        if ticks % 8_888 == 0 || last_log.elapsed() >= Duration::from_secs(8) {
            println!(
                "[omega] ticks={} phi_tick_hz≈{:.3} gravity_phi_exponent={}",
                ticks, args.phi_tick_hz, args.gravity_phi_exponent
            );
            last_log = Instant::now();
        }
    }
}
