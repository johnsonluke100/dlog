#!/usr/bin/env bash
set -euo pipefail

# === Core paths ============================================================
DESKTOP="${DESKTOP:-$HOME/Desktop}"
DLOG_ROOT="${DLOG_ROOT:-$DESKTOP/dlog}"
STACK_ROOT="$DLOG_ROOT/stack"
OMEGA_ROOT="$DLOG_ROOT"
INF_ROOT="$DLOG_ROOT/∞"
KUBE_ROOT="$DLOG_ROOT/kube"
UNIVERSE_NS="${UNIVERSE_NS:-dlog-universe}"

tag="[refold]"

# === Helpers ===============================================================
now_epoch() {
  date +%s
}

ensure_dirs() {
  mkdir -p "$DLOG_ROOT" "$STACK_ROOT" "$DLOG_ROOT/dashboard" "$DLOG_ROOT/sky" "$INF_ROOT"
}

write_stack_snapshot() {
  ensure_dirs
  epoch="$(now_epoch)"
  stack_file="$STACK_ROOT/stack;universe"
  {
    echo ";stack;epoch;$epoch;ok;"
    echo ";phone;label;epoch;epoch8;tag;status;"
  } > "$stack_file"
  echo "$tag wrote stack snapshot → $stack_file"
}

write_infinity_root() {
  ensure_dirs
  root_path="$INF_ROOT/;∞;∞;∞;∞;∞;∞;∞;∞;∞;"
  mkdir -p "$root_path" || true
  echo "$tag wrote 9∞ master root → $root_path"
}

write_dashboard_snapshot() {
  ensure_dirs
  dash_file="$DLOG_ROOT/dashboard/dashboard;status"
  epoch="$(now_epoch)"
  {
    echo ";dashboard;epoch;$epoch;ok;"
    echo ";vortex;9132077554;status;ok;"
    echo ";comet;9132077554;status;ok;"
  } > "$dash_file"
  echo "$tag wrote Ω-dashboard snapshot → $dash_file"
}

write_sky_manifest() {
  ensure_dirs
  manifest="$DLOG_ROOT/sky/sky;manifest"
  timeline="$DLOG_ROOT/sky/sky;timeline"
  epoch="$(now_epoch)"
  {
    echo ";sky;episodes;8;"
    echo ";omega;rail;${OMEGA_RAIL_HZ:-8888};"
  } > "$manifest"

  {
    echo ";sky;epoch;$epoch;curve;cosine;loop;true;"
  } > "$timeline"

  echo "$tag wrote Ω-sky manifest → $manifest"
  echo "$tag wrote Ω-sky timeline → $timeline"
}

apply_kube_universe() {
  if command -v kubectl >/dev/null 2>&1; then
    echo "$tag Kubernetes provider detected: external"
    universe_dir="$KUBE_ROOT/universe"
    if [ -d "$universe_dir" ]; then
      echo "$tag Applying universe manifests → $universe_dir (namespace $UNIVERSE_NS)"
      if ! kubectl apply -f "$universe_dir" -n "$UNIVERSE_NS"; then
        echo "[refold:warn] kubectl apply failed (safe to ignore for now)"
      fi
    else
      echo "$tag No kube/universe manifests at $universe_dir"
    fi
  else
    echo "$tag Kubernetes provider: none (kubectl not found)"
  fi
}

poke_dlog_command() {
  dlog_cmd="$DESKTOP/dlog.command"
  if [ -x "$dlog_cmd" ]; then
    echo "$tag delegating to dlog.command → beat"
    if ! "$dlog_cmd" beat; then
      echo "[refold:warn] dlog.command beat exited non-zero"
    fi
  fi
}

# === Subcommand dispatch ====================================================
subcommand="${1:-help}"
if [ "$#" -gt 0 ]; then
  shift
fi

case "$subcommand" in
  help)
    cat <<TXT
refold.command — Ω-Physics launcher

Usage:
  $0 help
  $0 ping
  $0 flames [hz <freqHz>]
  $0 beat
  $0 sky play
  $0 speakers

Notes:
  - flames: writes control file for Ω-speakers (default 8888 Hz).
  - beat: snapshots stack, sky, kube, and pokes dlog.command beat.
  - sky play: prints the crossfade log + writes to sky;stream (Ctrl+C to stop).
  - speakers: patches + builds + runs omega_speakers (Rust).
TXT
    ;;

  ping)
    ensure_dirs
    echo "=== refold.command ping ==="
    echo "$tag Desktop:      $DESKTOP"
    echo "$tag DLOG_ROOT:    $DLOG_ROOT"
    echo "$tag STACK_ROOT:   $STACK_ROOT"
    echo "$tag UNIVERSE_NS:  $UNIVERSE_NS"
    echo "$tag KUBE_MANIFEST:$KUBE_ROOT"
    echo "$tag OMEGA_ROOT:   $OMEGA_ROOT"
    echo "$tag Ω-INF-ROOT:   $INF_ROOT"
    dlog_cmd="$DESKTOP/dlog.command"
    if [ -x "$dlog_cmd" ]; then
      echo "$tag dlog.command is present and executable."
    else
      echo "$tag dlog.command not found or not executable."
    fi
    if command -v kubectl >/dev/null 2>&1; then
      echo "$tag Kubernetes provider detected: external"
    else
      echo "$tag Kubernetes provider: none (kubectl not found)"
    fi
    ;;

  flames)
    # Usage: refold.command flames [hz <freqHz>]
    hz=""
    if [ "${1:-}" = "hz" ]; then
      shift || true
      hz="${1:-}"
    fi

    if [ -z "$hz" ]; then
      hz="${OMEGA_HZ:-8888}"
    fi

    ensure_dirs
    flames_dir="$DLOG_ROOT/flames"
    mkdir -p "$flames_dir"
    control_file="$flames_dir/flames;control"

    {
      echo "hz=$hz"
      echo "height=7"
      echo "friction=leidenfrost"
    } > "$control_file"

    echo "$tag wrote flames control → $control_file"
    echo "Flames control: hz=$hz height=7 friction=leidenfrost"
    echo "(refold.command itself does not start audio — your Ω-engine must read $control_file)"
    ;;

  beat)
    echo "=== refold.command beat ==="
    write_stack_snapshot
    write_infinity_root
    write_dashboard_snapshot
    write_sky_manifest
    apply_kube_universe
    poke_dlog_command

    cat <<TXT
Beat complete.

This beat:
  - Updated the Ω-stack snapshot at $STACK_ROOT/stack;universe
  - Updated the 9∞ master root under $INF_ROOT
  - Updated the Ω-dashboard at $DLOG_ROOT/dashboard/dashboard;status
  - Updated the Ω-sky manifest & timeline under $DLOG_ROOT/sky
  - Applied universe manifests to Kubernetes (if reachable)
  - Poked dlog.command with 'beat' (if present)
TXT
    ;;

  sky)
    action="${1:-play}"
    if [ "$action" != "play" ]; then
      echo "[refold:err] sky: unknown action '$action'"
      exit 1
    fi

    ensure_dirs
    stream="$DLOG_ROOT/sky/sky;stream"
    : > "$stream"
    omega_hz="${OMEGA_RAIL_HZ:-8888}"

    echo "$tag Ω-sky play: episodes=8 ω_hz=$omega_hz curve=cosine loop=true"
    echo "$tag Streaming state to: $stream"
    echo "$tag Ctrl+C to stop."

    ep=1
    next_ep=2
    steps=62
    step=0
    while true; do
      phase_num=$step
      phase_den=$steps
      phase=$(awk "BEGIN { printf \"%.3f\", $phase_num / $phase_den }")
      printf "[Ω-sky] crossfade %d→%d ✦ phase %s / 1.000\n" "$ep" "$next_ep" "$phase"
      printf "%d %d %s\n" "$ep" "$next_ep" "$phase" >> "$stream"

      step=$((step + 1))
      if [ "$step" -gt "$steps" ]; then
        step=0
        ep=$next_ep
        next_ep=$(( (ep % 8) + 1 ))
      fi
      sleep 0.016
    done
    ;;

  speakers)
    echo "=== refold.command speakers ==="
    echo "$tag Ω-speakers: patching omega_speakers/src/main.rs for 8888 rail + 333–999 whoosh…"

    SRC="$DLOG_ROOT/omega_speakers/src/main.rs"
    mkdir -p "$(dirname "$SRC")"

    cat > "$SRC" <<'RUST'
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
RUST

    echo "$tag Building omega_speakers crate…"
    (
      cd "$DLOG_ROOT" && \
      cargo build -p omega_speakers
    ) || {
      echo "[refold:err] cargo build failed for omega_speakers"; exit 1;
    }

    echo "$tag Launching omega_speakers (dev profile)…"
    export OMEGA_ROOT="$DLOG_ROOT"
    export OMEGA_RAIL_HZ="${OMEGA_RAIL_HZ:-8888}"
    export OMEGA_WHOOSH_MIN_HZ="${OMEGA_WHOOSH_MIN_HZ:-333}"
    export OMEGA_WHOOSH_MAX_HZ="${OMEGA_WHOOSH_MAX_HZ:-999}"
    export OMEGA_GAIN="${OMEGA_GAIN:-0.04}"

    "$DLOG_ROOT/target/debug/omega_speakers"
    ;;

  stack-up)
    echo "=== refold.command stack-up ==="
    write_stack_snapshot
    cat <<TXT
Stack-up complete.

The Ω-stack snapshot now lives at:
  $STACK_ROOT/stack;universe

Format:
  ;stack;epoch;<nowEpoch>;ok;
  ;phone;label;epoch;epoch8;tag;status;
TXT
    ;;

  cleanup)
    echo "=== refold.command cleanup ==="
    echo
    echo "cleanup is currently a calm stub."
    echo
    echo "It exists so dlog.command can safely call:"
    echo "  refold.command cleanup"
    echo
    echo "Future ideas:"
    echo "  - remove temporary artifacts,"
    echo "  - rotate logs,"
    echo "  - compact / archive old universe snapshots."
    echo
    echo "Right now it does nothing destructive and always exits 0."
    ;;

  *)
    echo "[refold:err] Unknown subcommand: $subcommand"
    echo "Try: $0 help"
    exit 1
    ;;
esac
