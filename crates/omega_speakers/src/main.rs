use std::f32::consts::PI;
use std::time::{Duration, Instant};

fn env_var_f32(name: &str, default: f32) -> f32 {
    std::env::var(name)
        .ok()
        .and_then(|s| s.parse::<f32>().ok())
        .unwrap_or(default)
}

fn main() -> Result<(), anyhow::Error> {
    let omega_gain = env_var_f32("OMEGA_GAIN", 0.008082004);
    let target_hz = env_var_f32("OMEGA_TARGET_HZ", 8888.0);

    println!("=== Omega Phi 8888 Hz Leidenfrost Flame Engine (Rust) ===");
    println!("[+] OMEGA_GAIN  : {omega_gain}");
    println!("[+] TARGET_HZ   : {target_hz}");
    if let Ok(session) = std::env::var("OMEGA_SESSION") {
        println!("[+] SESSION     : {session}");
    }

    let host = cpal::default_host();
    let device = host
        .default_output_device()
        .ok_or_else(|| anyhow::anyhow!("no output device available"))?;
    let mut supported_config = device
        .default_output_config()
        .map_err(|e| anyhow::anyhow!("no default output config: {e}"))?;
    let sample_format = supported_config.sample_format();
    let config: cpal::StreamConfig = supported_config.clone().into();

    println!(
        "[+] Audio stream @ {} Hz, {} channels",
        config.sample_rate.0, config.channels
    );

    let stream = match sample_format {
        cpal::SampleFormat::F32 => build_stream::<f32>(&device, &config, target_hz, omega_gain)?,
        cpal::SampleFormat::I16 => build_stream::<i16>(&device, &config, target_hz, omega_gain)?,
        cpal::SampleFormat::U16 => build_stream::<u16>(&device, &config, target_hz, omega_gain)?,
        _ => return Err(anyhow::anyhow!("unsupported sample format")),
    };

    stream.play()?;
    println!("[+] Audio stream is live. Ctrl+C to stop.");

    // Endless run; refold.command controls the lifecycle.
    loop {
        std::thread::sleep(Duration::from_secs(60));
    }
}

fn build_stream<T>(
    device: &cpal::Device,
    config: &cpal::StreamConfig,
    target_hz: f32,
    gain: f32,
) -> Result<cpal::Stream, anyhow::Error>
where
    T: cpal::Sample + cpal::FromSample<f32>,
{
    let channels = config.channels as usize;
    let sample_rate = config.sample_rate.0 as f32;

    let mut phase: f32 = 0.0;
    let two_pi = 2.0 * PI;
    let phase_inc = two_pi * target_hz / sample_rate;

    let start = Instant::now();
    let err_fn = |e| eprintln!("[audio][error] {e}");

    let stream = device.build_output_stream(
        config,
        move |data: &mut [T], _| {
            let t = start.elapsed().as_secs_f32();
            // Very soft slow breathing envelope on top of gain
            let env = 0.5 + 0.5 * (0.25 * t).sin();
            let amp = gain * env;

            for frame in data.chunks_mut(channels) {
                let sample = (phase.sin() * amp) as f32;
                phase += phase_inc;
                if phase > two_pi {
                    phase -= two_pi;
                }

                // 4-flame illusion: L/R slight offsets
                let left = sample * 0.9;
                let right = sample * 1.1;

                if frame.len() >= 2 {
                    frame[0] = T::from_sample(left);
                    frame[1] = T::from_sample(right);
                } else {
                    frame[0] = T::from_sample(sample);
                }
            }
        },
        err_fn,
        None,
    )?;

    Ok(stream)
}
