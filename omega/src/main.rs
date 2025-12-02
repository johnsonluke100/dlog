//! Omega Phi 8888 Hz "Leidenfrost Flame Engine" in Rust.
//!
//! This is the Rust replacement for your old `omega_numpy_container`:
//! - Reads OMEGA_ROOT
//! - Prints the Omega banners
//! - Ticks in a tight loop at ~phi tick rate
//! - Does NOT do audio yet; it's an endless tuning fork heartbeat.

use anyhow::{bail, Context, Result};
use clap::{Parser, Subcommand};
use dlog_spec::{PHI, PHI_TICK_HZ};
use std::env;
use std::process::{Command as ProcessCommand, Stdio};
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

    /// Optional limit on ticks before exiting (handy for CI)
    #[arg(long)]
    ticks: Option<u64>,

    #[command(subcommand)]
    command: Option<Command>,
}

#[derive(Debug, Subcommand)]
enum Command {
    /// Invoke the shell wand chain (refold.command wand)
    Wand {
        /// Path to refold.command (default: ./refold.command)
        #[arg(long, default_value = "./refold.command")]
        refold: String,

        /// Extra args to pass through after `wand`
        #[arg(trailing_var_arg = true)]
        args: Vec<String>,
    },
}

fn main() -> Result<()> {
    let args = Args::parse();

    if let Some(Command::Wand { refold, args: wand_args }) = &args.command {
        return run_wand(refold, wand_args);
    }

    run_engine(args.phi_tick_hz, args.gravity_phi_exponent, args.ticks)
}

fn run_engine(phi_tick_hz: f64, gravity_phi_exponent: f64, tick_limit: Option<u64>) -> Result<()> {
    let omega_root = env::var("OMEGA_ROOT").unwrap_or_else(|_| ".".to_string());

    println!("=== Omega Phi 8888 Hz Leidenfrost Flame Engine (Rust) ===");
    println!("[+] OMEGA_ROOT : {omega_root}");
    println!("[+] PHI        : {PHI}");
    println!(
        "[+] phi_tick_hz: {} (requested), default = {}",
        phi_tick_hz, PHI_TICK_HZ
    );
    println!(
        "[+] gravity    : phi^{} per tick (baseline, per-planet can override)",
        gravity_phi_exponent
    );
    println!("=== ENDLESS TUNING FORK, WARM + PRESENCE (RUST) ===");

    let tick_duration_ns = if phi_tick_hz <= 0.0 {
        0.0
    } else {
        1_000_000_000.0 / phi_tick_hz
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
                ticks, phi_tick_hz, gravity_phi_exponent
            );
            last_log = Instant::now();
        }

        if let Some(limit) = tick_limit {
            if ticks >= limit {
                println!(
                    "[omega] tick limit reached ({}); exiting cleanly.",
                    tick_limit.unwrap_or_default()
                );
                break;
            }
        }
    }

    Ok(())
}

fn run_wand(refold: &str, args: &[String]) -> Result<()> {
    let mut cmd = ProcessCommand::new(refold);
    cmd.arg("wand");
    cmd.args(args);
    cmd.stdin(Stdio::inherit());
    cmd.stdout(Stdio::inherit());
    cmd.stderr(Stdio::inherit());

    let status = cmd.status().with_context(|| format!("failed to spawn {}", refold))?;
    if !status.success() {
        bail!("wand exited with status {}", status);
    }

    Ok(())
}
