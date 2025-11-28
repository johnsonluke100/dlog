use std::env;
use std::process::Command;

fn main() {
    // Prefer OMEGA_SPEAKER_ROOT, fall back to OMEGA_ROOT, then your default path
    let omega_root = env::var("OMEGA_SPEAKER_ROOT")
        .or_else(|_| env::var("OMEGA_ROOT"))
        .unwrap_or_else(|_| "/Users/lj/Desktop/omega_numpy_container".to_string());

    let gain = env::var("OMEGA_GAIN").unwrap_or_else(|_| "0.008082004".to_string());

    println!("=== Ω Rust Speaker Launcher (omega_speakers) ===");
    println!("[+] OMEGA_SPEAKER_ROOT : {omega_root}");
    println!("[+] OMEGA_GAIN         : {gain}");
    println!("[+] delegating to /Users/lj/Desktop/start.command (NPC engine bridge)…");

    let status = Command::new("/Users/lj/Desktop/start.command")
        .status()
        .expect("failed to launch start.command");

    if !status.success() {
        eprintln!("[!] start.command exited with status: {status}");
    }
}
