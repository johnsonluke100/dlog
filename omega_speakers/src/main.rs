use std::collections::HashMap;
use std::env;
use std::f32::consts::PI;
use std::fs;
use std::time::Duration;

use rand::rngs::StdRng;
use rand::{Rng, SeedableRng};
use rodio::{OutputStream, Sink, Source};

#[derive(Debug, Clone)]
struct OmegaConfig {
    omega_root: String,
    control_path: String,
    speaker_path: String,
    sky_stream_path: String,
    rail_hz: f32,
    whoosh_min_hz: f32,
    whoosh_max_hz: f32,
    gain: f32,
    friction: String,
    mode: String,
    height: f32,
    alpha_scale: f32,
}

impl OmegaConfig {
    fn load() -> Self {
        let home = env::var("HOME").unwrap_or_else(|_| ".".to_string());
        let omega_root = env::var("OMEGA_ROOT").unwrap_or_else(|_| format!("{home}/Desktop/dlog"));

        let control_path = format!("{omega_root}/flames/flames;control");
        let control = parse_kv_file(&control_path);

        let friction = control
            .get("friction")
            .map(|s| s.trim().to_lowercase())
            .filter(|s| !s.is_empty())
            .unwrap_or_else(|| "air".to_string());

        let speaker_path = speaker_profile_path(&omega_root, &friction);
        let speaker = parse_kv_file(&speaker_path);

        let height = speaker
            .get("height")
            .or_else(|| control.get("height"))
            .and_then(|s| s.parse::<f32>().ok())
            .unwrap_or(5.0);

        let mode = env::var("OMEGA_SPEAKER_MODE")
            .ok()
            .filter(|s| !s.trim().is_empty())
            .or_else(|| speaker.get("mode").cloned())
            .unwrap_or_else(|| "whoosh_rail".into());

        let rail_hz = env_f32("OMEGA_RAIL_HZ")
            .or_else(|| speaker.get("hz").and_then(|s| s.parse::<f32>().ok()))
            .or_else(|| control.get("hz").and_then(|s| s.parse::<f32>().ok()))
            .unwrap_or(8888.0);

        let gain = env_f32("OMEGA_GAIN")
            .or_else(|| speaker.get("gain").and_then(|s| s.parse::<f32>().ok()))
            .unwrap_or(0.05);

        let (derived_min, derived_max) = derive_whoosh_band(&mode, height);
        let whoosh_min_hz = env_f32("OMEGA_WHOOSH_MIN_HZ")
            .or_else(|| speaker.get("min_hz").and_then(|s| s.parse::<f32>().ok()))
            .unwrap_or(derived_min);
        let mut whoosh_max_hz = env_f32("OMEGA_WHOOSH_MAX_HZ")
            .or_else(|| speaker.get("max_hz").and_then(|s| s.parse::<f32>().ok()))
            .unwrap_or(derived_max);
        if whoosh_max_hz <= whoosh_min_hz {
            whoosh_max_hz = whoosh_min_hz + 64.0;
        }

        let alpha_scale = friction_alpha(&friction);

        Self {
            omega_root,
            control_path,
            speaker_path,
            sky_stream_path: format!("{}/sky/sky;stream", omega_root),
            rail_hz,
            whoosh_min_hz,
            whoosh_max_hz,
            gain,
            friction,
            mode,
            height,
            alpha_scale,
        }
    }
}

fn env_f32(key: &str) -> Option<f32> {
    env::var(key).ok().and_then(|s| s.parse::<f32>().ok())
}

fn parse_kv_file(path: &str) -> HashMap<String, String> {
    let mut out = HashMap::new();
    let Ok(contents) = fs::read_to_string(path) else {
        return out;
    };

    for line in contents.lines() {
        let line = line.trim();
        if line.is_empty() || line.starts_with('#') {
            continue;
        }
        if let Some((k, v)) = line.split_once('=') {
            out.insert(k.trim().to_lowercase(), v.trim().to_string());
        }
    }

    out
}

fn speaker_profile_path(omega_root: &str, friction: &str) -> String {
    let specific = format!("{omega_root}/flames/speaker;{friction}");
    if fs::metadata(&specific).is_ok() {
        return specific;
    }

    let leidenfrost = format!("{omega_root}/flames/speaker;leidenfrost");
    if fs::metadata(&leidenfrost).is_ok() {
        return leidenfrost;
    }

    format!("{omega_root}/flames/speaker;default")
}

fn derive_whoosh_band(mode: &str, height: f32) -> (f32, f32) {
    let clamped_h = height.clamp(0.0, 12.0);
    let (min, span) = match mode.to_ascii_lowercase().as_str() {
        "whoosh_rail" => (180.0 + clamped_h * 48.0, 420.0),
        "hum" => (90.0 + clamped_h * 22.0, 240.0),
        "ring" => (360.0 + clamped_h * 32.0, 520.0),
        _ => (240.0 + clamped_h * 36.0, 360.0),
    };
    (min, min + span.max(120.0))
}

fn friction_alpha(friction: &str) -> f32 {
    match friction {
        "leidenfrost" => 1.1,
        "air" => 0.9,
        "water" => 0.7,
        "stone" => 0.55,
        _ => 0.85,
    }
}

struct OmegaSource {
    sample_rate: u32,
    rail_hz: f32,
    whoosh_min_hz: f32,
    whoosh_max_hz: f32,
    gain: f32,
    alpha_scale: f32,
    t: f32,
    rng: StdRng,
    whoosh_state: f32,
    channel: u8,
}

impl Iterator for OmegaSource {
    type Item = f32;

    fn next(&mut self) -> Option<Self::Item> {
        let dt = 1.0 / self.sample_rate as f32;

        // Update state once per stereo frame (on left channel)
        if self.channel == 0 {
            self.t += dt;

            let noise: f32 = self.rng.gen_range(-1.0..1.0);

            // Rail drives an LFO between whoosh_min and whoosh_max
            let rail_phase = (self.t * self.rail_hz * 2.0 * PI).sin() * 0.5 + 0.5;
            let center_hz =
                self.whoosh_min_hz + (self.whoosh_max_hz - self.whoosh_min_hz) * rail_phase;

            let alpha = ((2.0 * PI * center_hz * dt) * self.alpha_scale)
                .clamp(0.001, 0.99);
            self.whoosh_state = self.whoosh_state * (1.0 - alpha) + noise * alpha;
        }

        let sample = self.whoosh_state * self.gain;

        // Flip channel 0 ↔ 1 (L/R interleave)
        self.channel ^= 1;

        Some(sample)
    }
}

impl Source for OmegaSource {
    fn current_frame_len(&self) -> Option<usize> {
        None
    }

    fn channels(&self) -> u16 {
        2
    }

    fn sample_rate(&self) -> u32 {
        self.sample_rate
    }

    fn total_duration(&self) -> Option<Duration> {
        None
    }
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let config = OmegaConfig::load();

    println!("=== Ω Rust Speaker Engine (Φ Whoosh Rail) ===");
    println!("[+] OMEGA_ROOT     : {}", config.omega_root);
    println!(
        "[+] Control File   : {} (friction={}, height={})",
        config.control_path, config.friction, config.height
    );
    println!(
        "[+] Speaker Profile: {} (mode={})",
        config.speaker_path, config.mode
    );
    println!("[+] Sky Stream     : {}", config.sky_stream_path);
    println!("[+] Rail Hz        : {:.3}", config.rail_hz);
    println!(
        "[+] Whoosh band    : {:.2}–{:.2} Hz",
        config.whoosh_min_hz, config.whoosh_max_hz
    );
    println!(
        "[+] Gain           : {:.4} (alpha x{:.2})",
        config.gain, config.alpha_scale
    );

    // Deterministic 256-bit seed derived from a single 64-bit constant
    let seed_bytes: [u8; 32] = {
        let base: u64 = 0xD10D_8888_u64;
        let mut out = [0u8; 32];
        out[..8].copy_from_slice(&base.to_le_bytes());
        out[8..16].copy_from_slice(&(!base).to_le_bytes());
        out[16..24].copy_from_slice(&(base.rotate_left(13)).to_le_bytes());
        out[24..32].copy_from_slice(&(base.rotate_right(7)).to_le_bytes());
        out
    };

    let rng = StdRng::from_seed(seed_bytes);

    let source = OmegaSource {
        sample_rate: 44_100,
        rail_hz,
        whoosh_min_hz: config.whoosh_min_hz,
        whoosh_max_hz: config.whoosh_max_hz,
        gain: config.gain,
        alpha_scale: config.alpha_scale,
        t: 0.0,
        rng,
        whoosh_state: 0.0,
        channel: 0,
    };

    let (_stream, stream_handle) = OutputStream::try_default()?;
    let sink = Sink::try_new(&stream_handle)?;

    sink.append(source);
    sink.play();

    println!("[Ω] Vortex bed engaged (Ctrl+C to stop)");

    loop {
        std::thread::sleep(Duration::from_secs(3600));
    }
}
