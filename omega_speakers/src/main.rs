use std::env;
use std::process::Command;

fn set_terminal_title(title: &str) {
    // ANSI escape: OSC 0 ; title BEL
    // Most terminals (Terminal.app, iTerm2, etc.) respect this.
    print!("\x1b]0;{title}\x07");
}

fn main() {
    // Title: directory-ish name + Ω flavor + Rust launcher tag
    set_terminal_title("dlog — Ω-speakers (Rust launcher)");

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
