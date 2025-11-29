use std::env;
use std::time::{Duration, Instant};

use rand::Rng;
use rand::SeedableRng;
use rand::rngs::StdRng;
use rodio::{OutputStream, Sink, Source};

fn env_f32(key: &str, default: f32) -> f32 {
    env::var(key)
        .ok()
        .and_then(|s| s.parse::<f32>().ok())
        .unwrap_or(default)
}

const VOICES: usize = 4;

struct OmegaSource {
    sample_rate: u32,
    rail_hz: f32,
    omega_gain: f32,

    whoosh_min_hz: f32,
    whoosh_max_hz: f32,
    whoosh_freq: f32,
    whoosh_target_freq: f32,
    whoosh_phases: [f32; VOICES],
    whoosh_detune: [f32; VOICES],

    rail_phase: f32,
    t: f64,
    whoosh_change_interval: f32,
    whoosh_time_since_change: f32,

    rng: StdRng,
    start: Instant,
    last_log: Instant,
}

impl OmegaSource {
    fn new(
        sample_rate: u32,
        rail_hz: f32,
        omega_gain: f32,
        whoosh_min_hz: f32,
        whoosh_max_hz: f32,
    ) -> Self {
        // Deterministic 32-byte seed built from a 64-bit constant
        let base = 0xD10D_8888_u64.to_le_bytes();
        let mut seed = [0u8; 32];
        for i in 0..4 {
            seed[i * 8..(i + 1) * 8].copy_from_slice(&base);
        }
        let mut rng = StdRng::from_seed(seed);

        let init_freq = rng.gen_range(whoosh_min_hz..whoosh_max_hz);
        let mut detune = [1.0f32; VOICES];
        for d in detune.iter_mut() {
            *d = rng.gen_range(0.9..1.1);
        }
        let now = Instant::now();

        Self {
            sample_rate,
            rail_hz,
            omega_gain,
            whoosh_min_hz,
            whoosh_max_hz,
            whoosh_freq: init_freq,
            whoosh_target_freq: init_freq,
            whoosh_phases: [0.0; VOICES],
            whoosh_detune: detune,
            rail_phase: 0.0,
            t: 0.0,
            whoosh_change_interval: 4.0,
            whoosh_time_since_change: 0.0,
            rng,
            start: now,
            last_log: now,
        }
    }
}

impl Iterator for OmegaSource {
    type Item = f32;

    fn next(&mut self) -> Option<f32> {
        let dt = 1.0 / self.sample_rate as f32;
        self.t += dt as f64;

        // timing rail at rail_hz (8888 by default)
        self.rail_phase += self.rail_hz * dt;
        if self.rail_phase >= 1.0 {
            self.rail_phase -= 1.0;
        }
        let rail = (2.0 * std::f32::consts::PI * self.rail_phase).sin();

        // whoosh band 333–999 Hz, gently wandering
        self.whoosh_time_since_change += dt;
        if self.whoosh_time_since_change >= self.whoosh_change_interval {
            self.whoosh_time_since_change = 0.0;
            self.whoosh_target_freq = self
                .rng
                .gen_range(self.whoosh_min_hz..self.whoosh_max_hz);
        }

        // glide slowly toward new target so it feels alive, not steppy
        let glide = 0.002;
        self.whoosh_freq += (self.whoosh_target_freq - self.whoosh_freq) * glide;

        // 4 detuned voices around the whoosh frequency
        let mut whoosh_sum = 0.0f32;
        for i in 0..VOICES {
            self.whoosh_phases[i] += self.whoosh_freq * self.whoosh_detune[i] * dt;
            if self.whoosh_phases[i] >= 1.0 {
                self.whoosh_phases[i] -= 1.0;
            }
            whoosh_sum += (2.0 * std::f32::consts::PI * self.whoosh_phases[i]).sin();
        }
        whoosh_sum /= VOICES as f32;

        // noise to make it "blowtorch / ocean" instead of pure tone
        let noise: f32 = self.rng.gen_range(-1.0..1.0);
        let whoosh = whoosh_sum * 0.5 + noise * 0.5;

        // mix rail + whoosh bed
        let sample = self.omega_gain * (rail * 0.25 + whoosh * 0.75);

        // periodic status log like the old python engine
        let now = Instant::now();
        if now.duration_since(self.last_log) >= Duration::from_secs(1) {
            self.last_log = now;
            let t_sec = now.duration_since(self.start).as_secs_f32();
            println!(
                "[Ω] t={:6.2}s rail={:7.2}Hz whoosh≈{:7.2}Hz gain={:.6}",
                t_sec, self.rail_hz, self.whoosh_freq, self.omega_gain
            );
        }

        Some(sample)
    }
}

impl Source for OmegaSource {
    fn current_frame_len(&self) -> Option<usize> {
        None
    }

    fn channels(&self) -> u16 {
        1
    }

    fn sample_rate(&self) -> u32 {
        self.sample_rate
    }

    fn total_duration(&self) -> Option<std::time::Duration> {
        None
    }
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let omega_root = env::var("OMEGA_ROOT").unwrap_or_else(|_| ".".to_string());
    let control_file = format!("{}/flames/flames;control", omega_root);
    let sky_stream = format!("{}/sky/sky;stream", omega_root);

    let rail_hz = env_f32("OMEGA_RAIL_HZ", 8888.0);
    let whoosh_min_hz = env_f32("OMEGA_WHOOSH_MIN_HZ", 333.0);
    let whoosh_max_hz = env_f32("OMEGA_WHOOSH_MAX_HZ", 999.0);
    let omega_gain = env_f32("OMEGA_GAIN", 0.04);

    println!("=== Ω Rust Speaker Engine (Φ Harmonic Bloom) ===");
    println!("[+] OMEGA_ROOT     : {}", omega_root);
    println!("[+] Control File   : {}", control_file);
    println!("[+] Sky Stream     : {}", sky_stream);
    println!("[+] Rail Hz        : {:.2}", rail_hz);
    println!(
        "[+] Whoosh Band    : {:.2} .. {:.2} Hz",
        whoosh_min_hz, whoosh_max_hz
    );
    println!("[+] Gain           : {:.6}", omega_gain);
    println!("[+] Output         : 4-voice golden field engaged ✨🌀");

    let (_stream, stream_handle) = OutputStream::try_default()?;
    let sink = Sink::try_new(&stream_handle)?;

    let sample_rate = 44_100u32;
    let src = OmegaSource::new(sample_rate, rail_hz, omega_gain, whoosh_min_hz, whoosh_max_hz);

    sink.append(src);
    sink.sleep_until_end();

    Ok(())
}
