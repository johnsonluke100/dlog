use std::env;
use std::fs;

use rand::rngs::SmallRng;
use rand::{Rng, SeedableRng};
use rodio::{OutputStream, Sink, Source};

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Figure out roots
    let omega_root = env::var("OMEGA_ROOT").unwrap_or_else(|_| ".".to_string());
    let control_path = format!("{}/flames/flames;control", omega_root);
    let sky_stream_path = format!("{}/sky/sky;stream", omega_root);

    // Master gain (you can override with OMEGA_GAIN env)
    let gain: f32 = env::var("OMEGA_GAIN")
        .ok()
        .and_then(|s| s.parse::<f32>().ok())
        .unwrap_or(0.12);

    // Target frequency (prefer hz= from flames;control, else 8888.0)
    let target_hz = read_hz_from_control(&control_path).unwrap_or(8888.0);

    println!("=== Ω Rust Speaker Engine (Φ Harmonic Bloom v2) ===");
    println!("[+] OMEGA_ROOT     : {}", omega_root);
    println!("[+] Control File   : {}", control_path);
    println!("[+] Sky Stream     : {}", sky_stream_path);
    println!("[+] Target Hz      : {:.2}", target_hz);
    println!("[+] MASTER_GAIN    : {:.6}", gain);
    println!("[+] Output         : 4-voice ocean torch engaged 🌊🔥");

    let (_stream, stream_handle) = OutputStream::try_default()?;
    let sink = Sink::try_new(&stream_handle)?;

    // One continuous flame field
    let source = FlameField::new(target_hz, gain);
    sink.append(source);

    sink.sleep_until_end();
    Ok(())
}

fn read_hz_from_control(path: &str) -> Option<f32> {
    let text = fs::read_to_string(path).ok()?;
    for line in text.lines() {
        if let Some(rest) = line.trim().strip_prefix("hz=") {
            // expect "hz=7777 height=7 friction=leidenfrost"
            let hz_part = rest.split_whitespace().next().unwrap_or("");
            if let Ok(v) = hz_part.parse::<f32>() {
                return Some(v);
            }
        }
    }
    None
}

/// Φ-rich vortex field:
/// - carrier_hz (e.g. 7777 / 8888)
/// - low band at ~262 Hz (body)
/// - mid band at ~1111 Hz (edge)
/// - noise “foam” shaped by slow LFO
/// - slow stereo drift (pan LFO)
struct FlameField {
    sample_rate: u32,
    carrier_hz: f32,
    gain: f32,

    // phased voices
    phase_carrier: f32,
    phase_low1: f32,
    phase_low2: f32,
    phase_lfo_amp: f32,
    phase_lfo_pan: f32,

    // noise + stereo framing
    noise_rng: SmallRng,
    next_is_left: bool,
    last_left: f32,
    last_right: f32,
}

impl FlameField {
    fn new(carrier_hz: f32, gain: f32) -> Self {
        Self {
            sample_rate: 44_100,
            carrier_hz,
            gain,
            phase_carrier: 0.0,
            phase_low1: 0.0,
            phase_low2: 0.0,
            phase_lfo_amp: 0.0,
            phase_lfo_pan: 0.0,
            noise_rng: SmallRng::from_entropy(),
            next_is_left: true,
            last_left: 0.0,
            last_right: 0.0,
        }
    }

    fn step_frame(&mut self) {
        let sr = self.sample_rate as f32;

        // advance phases
        self.phase_carrier = (self.phase_carrier + self.carrier_hz / sr) % 1.0;
        self.phase_low1 = (self.phase_low1 + 262.3 / sr) % 1.0;
        self.phase_low2 = (self.phase_low2 + 1111.0 / sr) % 1.0;
        self.phase_lfo_amp = (self.phase_lfo_amp + 0.333 / sr) % 1.0;
        self.phase_lfo_pan = (self.phase_lfo_pan + 0.072 / sr) % 1.0;

        let theta = std::f32::consts::TAU;

        let s_carrier = (self.phase_carrier * theta).sin(); // 8888 bed
        let s_low1 = (self.phase_low1 * theta).sin();       // deep body
        let s_low2 = (self.phase_low2 * theta).sin();       // “edge” band

        // soft pink-ish noise: white * slow envelope
        let white: f32 = self.noise_rng.gen_range(-1.0..=1.0);
        let lfo_amp = (self.phase_lfo_amp * theta).sin();
        let foam_env = 0.55 + 0.35 * lfo_amp; // ~0.2..0.9
        let foam = white * foam_env;

        // mix the three tone bands + foam
        let high = s_carrier * 0.40;
        let body = s_low1 * 0.55 + s_low2 * 0.30;
        let mono = (high + body + foam * 0.45) * 0.7;

        // slow stereo pan: gentle drift, not spinning
        let pan_lfo = (self.phase_lfo_pan * theta).sin();
        let pan = 0.5 + 0.35 * pan_lfo; // 0.15 .. 0.85

        let left = mono * (1.0 - pan);
        let right = mono * pan;

        // apply gain + soft clip
        let gl = (left * self.gain).tanh();
        let gr = (right * self.gain).tanh();

        self.last_left = gl.clamp(-1.0, 1.0);
        self.last_right = gr.clamp(-1.0, 1.0);
    }
}

impl Iterator for FlameField {
    type Item = f32;

    fn next(&mut self) -> Option<f32> {
        if self.next_is_left {
            // compute a new stereo frame
            self.step_frame();
            self.next_is_left = false;
            Some(self.last_left)
        } else {
            self.next_is_left = true;
            Some(self.last_right)
        }
    }
}

impl Source for FlameField {
    fn current_frame_len(&self) -> Option<usize> {
        None
    }

    fn channels(&self) -> u16 {
        2
    }

    fn sample_rate(&self) -> u32 {
        self.sample_rate
    }

    fn total_duration(&self) -> Option<std::time::Duration> {
        None
    }
}
