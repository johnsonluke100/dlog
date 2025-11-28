use std::fs;
use std::path::PathBuf;
use std::time::{Duration, Instant};
use std::thread;
use std::f32::consts::PI;

use rodio::{OutputStream, Sink, buffer::SamplesBuffer};

// === Ω Utilities =========================================================

fn read_control_file(path: &PathBuf) -> (f32, f32) {
    let mut hz: f32 = 7777.0;
    let mut gain: f32 = 0.0080;
    if let Ok(content) = fs::read_to_string(path) {
        for line in content.lines() {
            if let Some(v) = line.strip_prefix("hz=") {
                if let Ok(parsed) = v.trim().parse::<f32>() {
                    hz = parsed;
                }
            }
            if let Some(v) = line.strip_prefix("gain=") {
                if let Ok(parsed) = v.trim().parse::<f32>() {
                    gain = parsed;
                }
            }
        }
    }
    (hz, gain)
}

fn read_sky_phase(path: &PathBuf) -> f32 {
    if let Ok(content) = fs::read_to_string(path) {
        if let Some(line) = content.lines().find(|l| l.contains("phase")) {
            if let Some(val) = line.split_whitespace().last() {
                if let Ok(parsed) = val.parse::<f32>() {
                    return parsed;
                }
            }
        }
    }
    0.0
}

// === Ω Audio: Golden Harmonic Field ======================================

fn make_phi_bloom(freq: f32, amp: f32, pan: f32, dur: Duration, rate: u32) -> SamplesBuffer<f32> {
    const PHI: f32 = 1.6180339887;
    let voices = [
        (1.0, 1.0),
        (PHI, 0.6),
        (PHI.powf(2.0), 0.4),
        (PHI.powf(3.0), 0.3),
    ];

    let total = (dur.as_secs_f32() * rate as f32) as usize;
    let mut left = Vec::with_capacity(total);
    let mut right = Vec::with_capacity(total);

    let pan_l = (1.0 - pan) * 0.5;
    let pan_r = (1.0 + pan) * 0.5;

    for n in 0..total {
        let t = n as f32 / rate as f32;
        let mut s = 0.0;
        for (mult, vol) in voices {
            s += (2.0 * PI * freq * mult * t).sin() * amp * vol;
        }
        left.push(s * pan_l);
        right.push(s * pan_r);
    }

    // interleave L+R
    let mut data = Vec::with_capacity(total * 2);
    for i in 0..total {
        data.push(left[i]);
        data.push(right[i]);
    }

    SamplesBuffer::new(2, rate, data)
}

// === Ω Main ===============================================================

fn main() {
    let omega_root = std::env::var("OMEGA_ROOT").unwrap_or_else(|_| ".".into());
    let control_path = PathBuf::from(format!("{}/flames/flames;control", omega_root));
    let sky_path = PathBuf::from(format!("{}/sky/sky;stream", omega_root));

    println!("=== Ω Rust Speaker Engine (Φ Harmonic Bloom) ===");
    println!("[+] OMEGA_ROOT     : {}", omega_root);
    println!("[+] Control File   : {}", control_path.display());
    println!("[+] Sky Stream     : {}", sky_path.display());
    println!("[+] Output         : 4-voice golden field engaged ✨🌀");

    let (_stream, handle) = OutputStream::try_default().expect("No output stream");
    let sink = Sink::try_new(&handle).expect("No sink");

    let mut last_hz = 0.0;
    let mut last_gain = 0.0;
    let mut last_phase = 0.0;
    let start = Instant::now();

    loop {
        let (hz, gain) = read_control_file(&control_path);
        let phase = read_sky_phase(&sky_path);

        let mod_hz = hz * (1.0 + phase * 0.002);
        let mod_gain = gain * (1.0 + (phase * 0.5));
        let pan = (phase.cos() * 2.0 - 1.0).clamp(-1.0, 1.0);

        if (mod_hz - last_hz).abs() > 0.1
            || (mod_gain - last_gain).abs() > 0.0001
            || (phase - last_phase).abs() > 0.001
        {
            last_hz = mod_hz;
            last_gain = mod_gain;
            last_phase = phase;

            println!(
                "[Ω] t={:.2?} hz={:.2} gain={:.5} phase={:.3} pan={:.3} Φ-bloom",
                start.elapsed(),
                mod_hz,
                mod_gain,
                phase,
                pan
            );

            let wave = make_phi_bloom(mod_hz, mod_gain, pan, Duration::from_millis(400), 44100);
            sink.append(wave);
        }

        thread::sleep(Duration::from_millis(250));
    }
}
