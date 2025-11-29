#!/usr/bin/env bash
set -euo pipefail

# === Ω refold.command : DLOG Ω-Physics sidecar ===
# Subcommands:
#   flames [hz <freq>|up|down]
#   beat
#   sky play
#   ping
#   speakers

log() {
  printf '[refold] %s\n' "$*"
}

warn() {
  printf '[refold:warn] %s\n' "$*" >&2
}

err() {
  printf '[refold:err] %s\n' "$*" >&2
}

init_paths() {
  # Desktop + DLOG_ROOT
  local home
  home="${HOME:-$PWD}"
  DESKTOP="${DESKTOP:-"$home/Desktop"}"
  DLOG_ROOT="${DLOG_ROOT:-"$DESKTOP/dlog"}"

  STACK_ROOT="${STACK_ROOT:-"$DLOG_ROOT/stack"}"
  UNIVERSE_NS="${UNIVERSE_NS:-dlog-universe}"
  KUBE_MANIFEST="${KUBE_MANIFEST:-"$DLOG_ROOT/kube"}"
  OMEGA_ROOT="${OMEGA_ROOT:-"$DLOG_ROOT"}"
  OMEGA_INF_ROOT="${OMEGA_INF_ROOT:-"$DLOG_ROOT/∞"}"

  STACK_FILE="$STACK_ROOT/stack;universe"
  INFINITY_DIR="$OMEGA_INF_ROOT/;∞;∞;∞;∞;∞;∞;∞;∞;∞;"
  DASHBOARD_FILE="$DLOG_ROOT/dashboard/dashboard;status"
  SKY_MANIFEST="$DLOG_ROOT/sky/sky;manifest"
  SKY_TIMELINE="$DLOG_ROOT/sky/sky;timeline"
  SKY_STREAM="$DLOG_ROOT/sky/sky;stream"
  FLAMES_CONTROL="$DLOG_ROOT/flames/flames;control"

  mkdir -p "$STACK_ROOT" "$OMEGA_INF_ROOT" "$DLOG_ROOT/dashboard" \
           "$DLOG_ROOT/sky" "$DLOG_ROOT/flames"
}

write_stack_snapshot() {
  init_paths
  local now epoch8
  now="$(date +%s)"
  epoch8="$(printf '%o\n' "$now")"

  cat > "$STACK_FILE" << EOF_SNAP
;stack;epoch;$now;ok;
;phone;label;epoch;$epoch8;tag;ok;
EOF_SNAP

  log "wrote stack snapshot → $STACK_FILE"
}

write_infinity_root() {
  init_paths
  mkdir -p "$INFINITY_DIR" || true
  echo ';∞;root;9∞;master;ok;' > "$INFINITY_DIR/∞;root;master"
  log "wrote 9∞ master root → $INFINITY_DIR"
}

write_dashboard() {
  init_paths
  local now
  now="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  cat > "$DASHBOARD_FILE" << EOF_DASH
;dashboard;status;epoch;$(date +%s);at;$now;ok;
EOF_DASH
  log "wrote Ω-dashboard snapshot → $DASHBOARD_FILE"
}

write_sky_files() {
  init_paths
  local now
  now="$(date +%s)"
  cat > "$SKY_MANIFEST" << EOF_SKY_M
;sky;episodes;8;omega_hz;${OMEGA_HZ:-8888};curve;cosine;loop;true;
EOF_SKY_M
  cat > "$SKY_TIMELINE" << EOF_SKY_T
;sky;timeline;epoch;$now;episodes;8;status;ok;
EOF_SKY_T
  log "wrote Ω-sky manifest → $SKY_MANIFEST"
  log "wrote Ω-sky timeline → $SKY_TIMELINE"
}

apply_kube_universe() {
  init_paths
  if command -v kubectl >/dev/null 2>&1 && [ -d "$KUBE_MANIFEST/universe" ]; then
    log "Kubernetes provider detected: external"
    log "Applying universe manifests → $KUBE_MANIFEST/universe (namespace $UNIVERSE_NS)"
    if ! kubectl apply -f "$KUBE_MANIFEST/universe" -n "$UNIVERSE_NS"; then
      warn "kubectl apply failed (universe manifests)"
    fi
  else
    warn "kubectl or universe manifests not present; skipping kube apply"
  fi
}

cmd_ping() {
  init_paths
  echo "=== refold.command ping ==="
  log "Desktop:      $DESKTOP"
  log "DLOG_ROOT:    $DLOG_ROOT"
  log "STACK_ROOT:   $STACK_ROOT"
  log "UNIVERSE_NS:  $UNIVERSE_NS"
  log "KUBE_MANIFEST:$KUBE_MANIFEST"
  log "OMEGA_ROOT:   $OMEGA_ROOT"
  log "Ω-INF-ROOT:   $OMEGA_INF_ROOT"

  if [ -x "$DESKTOP/dlog.command" ]; then
    log "dlog.command is present and executable."
  else
    warn "dlog.command is missing or not executable at $DESKTOP/dlog.command"
  fi
}

cmd_cleanup() {
  echo "=== refold.command cleanup ==="
  cat << 'EOF_CLEAN'
cleanup is currently a calm stub.

It exists so dlog.command can safely call:
  refold.command cleanup

Future ideas:
  - remove temporary artifacts,
  - rotate logs,
  - compact / archive old universe snapshots.

Right now it does nothing destructive and always exits 0.
EOF_CLEAN
}

cmd_stack_up() {
  echo "=== refold.command stack-up ==="
  write_stack_snapshot
  echo
  echo "Stack-up complete."
  echo
  echo "The Ω-stack snapshot now lives at:"
  echo "  $STACK_FILE"
  echo
  cat << 'EOF_FORMAT'
Format:
  ;stack;epoch;<nowEpoch>;ok;
  ;phone;label;epoch;epoch8;tag;status;
EOF_FORMAT
}

cmd_flames() {
  init_paths
  echo "=== refold.command flames ==="

  # Default Omega frequency
  local base_hz
  base_hz="${OMEGA_HZ:-8888}"

  local hz="$base_hz"

  if [ "${1:-}" = "hz" ] && [ "${2:-}" != "" ]; then
    hz="$2"
  elif [ "${1:-}" = "up" ]; then
    hz=$(( base_hz + 111 ))
  elif [ "${1:-}" = "down" ]; then
    hz=$(( base_hz - 111 ))
  fi

  export OMEGA_HZ="$hz"

  cat > "$FLAMES_CONTROL" << EOF_FLAME
;flames;hz;$hz;height;7;friction;leidenfrost;
EOF_FLAME

  log "wrote flames control → $FLAMES_CONTROL"
  printf 'Flames control: hz=%s height=7 friction=leidenfrost\n' "$hz"
  printf '(refold.command itself does not start audio — your Ω-engine must read %s)\n' "$FLAMES_CONTROL"
}

cmd_sky_play() {
  init_paths
  local hz episodes
  hz="${OMEGA_HZ:-8888}"
  episodes=8

  log "Ω-sky play: episodes=$episodes ω_hz=$hz curve=cosine loop=true"
  log "Streaming state to: $SKY_STREAM"
  log "Ctrl+C to stop."

  # Simple log-only crossfade simulator (for vibes).
  local from=1
  local to=2
  local phase
  while true; do
    phase=0
    while [ "$phase" -le 1000 ]; do
      printf '[Ω-sky] crossfade %d→%d ✦ phase %.3f / 1.000\n' \
        "$from" "$to" "$(printf '%0.3f' "$(echo "$phase / 1000" | bc -l 2>/dev/null || echo 0)")"
      phase=$(( phase + 16 ))
      sleep 0.03
    done
    from=$to
    to=$(( to + 1 ))
    if [ "$to" -gt "$episodes" ]; then
      from=episodes
      to=1
    fi
  done
}

cmd_beat() {
  echo "=== refold.command beat ==="
  write_stack_snapshot
  write_infinity_root
  write_dashboard
  write_sky_files
  apply_kube_universe

  # Delegate to dlog.command if present
  init_paths
  if [ -x "$DESKTOP/dlog.command" ]; then
    log "delegating to dlog.command → beat"
    "$DESKTOP/dlog.command" beat || warn "dlog.command beat returned non-zero"
  fi

  cmd_cleanup
  cmd_stack_up
  cmd_ping || warn "ping returned non-zero"

  cat << 'EOF_BEAT_DONE'
[Ω][info] Ω-beat complete (stack + ping refreshed).
Beat complete.

This beat:
  - Updated the Ω-stack snapshot at /Users/lj/Desktop/dlog/stack/stack;universe
  - Updated the 9∞ master root under /Users/lj/Desktop/dlog/∞
  - Updated the Ω-dashboard at /Users/lj/Desktop/dlog/dashboard/dashboard;status
  - Updated the Ω-sky manifest & timeline under /Users/lj/Desktop/dlog/sky
  - Applied universe manifests to Kubernetes (if reachable)
  - Poked dlog.command with 'beat' (if present)
EOF_BEAT_DONE
}

cmd_speakers() {
  init_paths
  echo "=== refold.command speakers ==="
  log "Ω-speakers: writing omega_speakers/src/main.rs for 8888 rail + 333–999 whoosh…"

  mkdir -p "$DLOG_ROOT/omega_speakers/src"

  cat > "$DLOG_ROOT/omega_speakers/src/main.rs" << 'EOF_RS'
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
EOF_RS

  log "Building omega_speakers crate…"
  if (cd "$DLOG_ROOT" && cargo build -p omega_speakers); then
    log "Launching omega_speakers (Rust vortex bed)…"
    (
      cd "$DLOG_ROOT"
      OMEGA_ROOT="$DLOG_ROOT" \
      OMEGA_RAIL_HZ="${OMEGA_RAIL_HZ:-8888}" \
      OMEGA_WHOOSH_MIN_HZ="${OMEGA_WHOOSH_MIN_HZ:-333}" \
      OMEGA_WHOOSH_MAX_HZ="${OMEGA_WHOOSH_MAX_HZ:-999}" \
      ./target/debug/omega_speakers &
    )
  else
    err "cargo build failed for omega_speakers"
    return 1
  fi
}

usage() {
  cat << 'EOF_USAGE'
Usage: refold.command <subcommand> [args]

Subcommands:
  flames [hz <freq>|up|down]   Tune Ω-flames control file (default 8888 Hz)
  beat                         Write stack/dashboard/sky + kube apply + ping
  sky play                     Log-only Ω-sky crossfade loop (Ctrl+C to stop)
  ping                         Show Ω-paths / environment
  speakers                     Patch + build + run omega_speakers vortex bed
EOF_USAGE
}

main() {
  if [ "$#" -lt 1 ]; then
    usage
    exit 1
  fi

  local cmd="$1"
  shift || true

  case "$cmd" in
    flames)     cmd_flames "$@" ;;
    beat)       cmd_beat ;;
    sky)
      case "${1:-}" in
        play) shift; cmd_sky_play "$@" ;;
        *) usage; exit 1 ;;
      esac
      ;;
    ping)       cmd_ping ;;
    speakers)   cmd_speakers ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
