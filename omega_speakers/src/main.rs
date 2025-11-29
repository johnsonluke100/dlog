use std::env;
use std::f32::consts::PI;
use std::time::Duration;

use rand::rngs::StdRng;
use rand::{Rng, SeedableRng};
use rodio::{OutputStream, Sink, Source};

struct OmegaSource {
    sample_rate: u32,
    rail_hz: f32,
    whoosh_min_hz: f32,
    whoosh_max_hz: f32,
    gain: f32,
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

            let alpha = (2.0 * PI * center_hz * dt).min(0.99);
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
    let home = env::var("HOME").unwrap_or_else(|_| ".".to_string());
    let omega_root = env::var("OMEGA_ROOT").unwrap_or_else(|_| format!("{home}/Desktop/dlog"));

    let control_file = format!("{omega_root}/flames/flames;control");
    let sky_stream = format!("{omega_root}/sky/sky;stream");

    let rail_hz = env::var("OMEGA_RAIL_HZ")
        .ok()
        .and_then(|s| s.parse::<f32>().ok())
        .unwrap_or(8888.0);

    let whoosh_min_hz = env::var("OMEGA_WHOOSH_MIN_HZ")
        .ok()
        .and_then(|s| s.parse::<f32>().ok())
        .unwrap_or(333.0);

    let whoosh_max_hz = env::var("OMEGA_WHOOSH_MAX_HZ")
        .ok()
        .and_then(|s| s.parse::<f32>().ok())
        .unwrap_or(999.0);

    let gain = env::var("OMEGA_GAIN")
        .ok()
        .and_then(|s| s.parse::<f32>().ok())
        .unwrap_or(0.05);

    println!("=== Ω Rust Speaker Engine (Φ Whoosh Rail) ===");
    println!("[+] OMEGA_ROOT     : {omega_root}");
    println!("[+] Control File   : {control_file}");
    println!("[+] Sky Stream     : {sky_stream}");
    println!("[+] Rail Hz        : {rail_hz}");
    println!("[+] Whoosh band    : {whoosh_min_hz}–{whoosh_max_hz} Hz");
    println!("[+] Gain           : {gain}");

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
        whoosh_min_hz,
        whoosh_max_hz,
        gain,
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
