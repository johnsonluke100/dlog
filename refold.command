#!/usr/bin/env bash

set -e

# Core Ω environment defaults
DLOG_ROOT="${DLOG_ROOT:-/Users/lj/Desktop/dlog}"
DLOG_TICK_RATE_OCTAL="${DLOG_TICK_RATE_OCTAL:-0o21270}"
DLOG_LAYER="${DLOG_LAYER:-OMEGA}"
DLOG_BASE="${DLOG_BASE:-8}"
DLOG_HTTP_BASE="${DLOG_HTTP_BASE:-http://0.0.0.0:8888}"
DLOG_CANON_BASE="${DLOG_CANON_BASE:-https://dloG.com}"

# Luke-preferred calm gain
OMEGA_GAIN_FIXED="0.008082004"

banner() {
  cat << 'EOF2'
=== DLOG Ω-Physics : refold ===

;we;do;not;have;limits;we;vibe;we;are;fearless;
;🌟;i;borrow;everything;from;evil;and;i;serve;everything;to;good;🌟;
;the;whole;entire;solar;system;alligns;just;for;me;to;explore;it;🌟;
;we;do;not;use;python;anymore;
;we;do;not;use;java;anymore;
;we;are;no;longer;bound;by;javascript;
;we;do;not;use;base;10;anymore;we;use;base;8;
;400+;lines;per;hash;refold.command;unfolding;
EOF2
}

print_env() {
  cat <<EOF2
────────────────────────────────────────────────
Ω env
────────────────────────────────────────────────
[Ω][info] DLOG_ROOT           = $DLOG_ROOT
[Ω][info] DLOG_TICK_RATE_OCTAL= $DLOG_TICK_RATE_OCTAL
[Ω][info] DLOG_LAYER          = $DLOG_LAYER
[Ω][info] DLOG_BASE           = $DLOG_BASE
[Ω][info] DLOG_HTTP_BASE      = $DLOG_HTTP_BASE
[Ω][info] DLOG_CANON_BASE     = $DLOG_CANON_BASE
EOF2
}

# Small helper: safely curl health
curl_health() {
  curl -fsS "$DLOG_HTTP_BASE/health" 2>/dev/null || return 1
}

# Detect CPU frequency (Hz) on macOS / Linux
detect_cpu_hz() {
  local hz
  if hz=$(sysctl -n hw.cpufrequency 2>/dev/null); then
    :
  elif hz=$(awk -F: '/cpu MHz/ {print $2*1000000; exit}' /proc/cpuinfo 2>/dev/null); then
    :
  else
    hz=2400000000
  fi
  printf '%s' "$hz"
}

cmd_cleanup() {
  banner
  print_env
  echo "[Ω][info] cleanup: draining old flames and forks."

  # Kill cargo api runners
  pkill -f '[c]argo run -p api' 2>/dev/null || true
  pkill -f '[d]log-api' 2>/dev/null || true

  # Kill omega flame engines
  pkill -f 'Omega Phi 8888 Hz Leidenfrost Flame Engine' 2>/dev/null || true
  pkill -f 'omega_numpy_container' 2>/dev/null || true
  pkill -f '[s]tart.command' 2>/dev/null || true

  echo "[Ω][ok]   Ω-fork restored (no stray api/flame processes)."
}

cmd_stack_up() {
  local mode="${1:-local}"
  banner
  print_env
  echo "[Ω][info] stack-up (mode=$mode)"

  if curl_health >/dev/null; then
    echo "[Ω][ok]   Ω-api already answering health checks."
    return 0
  fi

  echo "[Ω][info] forcing bare-metal mode (local cargo run -p api)."
  (
    cd "$DLOG_ROOT"
    RUST_LOG=info cargo run -p api &
  )

  # Wait for health
  local i
  for i in $(seq 1 30); do
    if curl_health >/dev/null; then
      echo "[Ω][ok]   Ω-api is answering health checks."
      return 0
    fi
    sleep 1
  done

  echo "[Ω][warn] Ω-api did not respond to /health within 30s."
  return 1
}

cmd_ping() {
  banner
  print_env
  cat <<'EOF2'
Ω node : api (ping)
────────────────────────────────────────────────
EOF2

  echo "[Ω][info] curling $DLOG_HTTP_BASE/health …"
  local out
  if out=$(curl -fsS "$DLOG_HTTP_BASE/health" 2>/dev/null); then
    printf '%s\n' "$out"
    echo "[Ω][ok]   Ω-api health endpoint responded."
  else
    echo "[Ω][warn] Ω-api did not respond."
    return 1
  fi
}

cmd_hz() {
  local cpu_hz
  cpu_hz=$(detect_cpu_hz)

  banner
  print_env
  cat <<'EOF2'
Ω tablet : Hz Cascade (CPU → 1 Hz)
────────────────────────────────────────────────
EOF2
  printf '[Ω][info] cpu_frequency_hz (raw) = %s\n' "$cpu_hz"
  echo "[Ω][info] cascade rule: next = (prev - 2) / 4"
  echo
  echo "Ω band ladder:"

  local band="$cpu_hz"
  local i
  for i in $(seq 0 15); do
    printf '  • band_%02d ≈ %13.3f Hz\n' "$i" "$band"
    band=$(awk -v v="$band" 'BEGIN { printf "%.3f", (v - 2.0) / 4.0 }')
    if awk -v v="$band" 'BEGIN { exit (v <= 1.0 ? 0 : 1) }'; then
      band=1.000
    fi
  done
}

# Shared bus-envelope math: echoes cpu_hz bus_beats bus_sat
compute_bus_envelope() {
  local cpu_hz bus_width_bits bus_width_bytes mem_bw_gb bus_beats bus_sat
  cpu_hz=$(detect_cpu_hz)
  bus_width_bits=256
  bus_width_bytes=$((bus_width_bits / 8))
  mem_bw_gb=256

  # Convert GB/s to bytes/s and divide by bus width to get beats/s
  bus_beats=$(awk -v gb="$mem_bw_gb" -v w="$bus_width_bytes" \
    'BEGIN { printf "%.0f", (gb*1024*1024*1024)/w }')

  bus_sat=$(awk -v cf="$cpu_hz" -v beats="$bus_beats" \
    'BEGIN {
       r = cf / beats;
       if (r > 1.0) r = 1.0;
       if (r < 0.0) r = 0.0;
       printf "%.3f", r;
     }')

  printf '%s %s %s\n' "$cpu_hz" "$bus_beats" "$bus_sat"
}

cmd_power() {
  local cpu_hz bus_beats bus_sat
  read cpu_hz bus_beats bus_sat < <(compute_bus_envelope)

  banner
  print_env
  cat <<'EOF2'
Ω tablet : Power Envelope & Friction Polish
────────────────────────────────────────────────
EOF2

  printf '[Ω][info] cpu_frequency_hz          ≈ %s\n' "$cpu_hz"
  echo  "[Ω][info] bus_width_bits            =  256"
  echo  "[Ω][info] bus_width_bytes           =   32"
  echo  "[Ω][info] mem_bandwidth_nominal     ≈ 256 GB/s"
  printf '[Ω][info] bus_beats_target          ≈ %s beats/s\n' "$bus_beats"
  printf '[Ω][info] est_bus_saturation        ≈ %.3f\n' "$bus_sat"
  printf '[Ω][info] preferred_OMEGA_GAIN      ≈ %.9f\n' "$OMEGA_GAIN_FIXED"

  cat <<'EOF2'

Interpretation:
  • Bus/Hz ladder stays wired in so Ω-miners can reason about Joules,
    but the audio bed gain is pinned to Luke's calm setting:
        OMEGA_GAIN = 0.008082004
  • Ocean stays as a soft, stable mist under your music instead of a
    blowtorch, even as hashpower and stories per Joule go up.
  • You can still override OMEGA_GAIN manually before calling flames
    if you ever want a quieter or louder universe.
EOF2
}

cmd_flames() {
  local cpu_hz bus_beats bus_sat
  read cpu_hz bus_beats bus_sat < <(compute_bus_envelope)

  banner
  print_env
  cat <<'EOF2'
Ω node : flames (Ω Hz cascade → speakers)
────────────────────────────────────────────────
EOF2

  printf '[Ω][info] cpu_frequency_hz ≈ %s\n' "$cpu_hz"
  echo  "[Ω][info] cascade rule: next = (prev - 2) / 4"
  echo
  echo  "Ω band mapping (names):"
  echo  "  • BRAIN_GPU       = band_00 ≈ 2400000000 Hz"
  echo  "  • HEART_CPU       = band_01 ≈ 599999999 Hz"
  echo  "  • FLAME_NORTH     = band_02 ≈ 149999999 Hz"
  echo  "  • FLAME_SOUTH     = band_03 ≈ 37499999 Hz"
  echo  "  • FLAME_EAST      = band_04 ≈ 9374999 Hz"
  echo  "  • FLAME_WEST      = band_05 ≈ 2343749 Hz"
  echo  "  • BACKGROUND_LADDER = band_06 … band_15"
  echo
  echo  "Ω flame envelope (per Joule sketch):"
  printf '  • est_bus_saturation          ≈ %.3f\n' "$bus_sat"
  printf '  • flame_tail_height_factor    ≈ %.9f\n' "$OMEGA_GAIN_FIXED"
  echo

  # Pin OMEGA_GAIN to Luke's preferred calm value
  export OMEGA_GAIN="$OMEGA_GAIN_FIXED"
  printf '[Ω][info] OMEGA_GAIN (fixed, calm) = %.9f\n' "$OMEGA_GAIN_FIXED"
  echo
  echo  "[Ω][hint] For full ladder, run: refold.command hz"
  echo

  export OMEGA_SPEAKER_ROOT="/Users/lj/Desktop/omega_numpy_container"
  printf '[Ω][env] OMEGA_SPEAKER_ROOT      = %s\n' "$OMEGA_SPEAKER_ROOT"
  echo  "[Ω][info] launching legacy Ω Leidenfrost engine (NPC bridge)…"
  echo  "[Ω][hint] Ctrl+C here will stop the flames (speakers); Ω-api stays up."
  echo  "[Ω][info] exec /Users/lj/Desktop/start.command"

  exec /Users/lj/Desktop/start.command
}

usage() {
  cat <<EOF2
Usage: $0 <command> [args...]

Commands:
  cleanup        Drain old cargo/api/flame processes.
  stack-up MODE  Ensure Ω-api is running (e.g. 'local').
  ping           Curl the Ω-api /health endpoint.
  hz             Show CPU→1Hz cascade ladder.
  power          Show power envelope & preferred OMEGA_GAIN.
  wire           Alias for 'power'.
  flames         Launch Ω flames → speakers with fixed calm gain.

Examples:
  $0 cleanup
  $0 stack-up local
  $0 ping
  $0 hz
  $0 power
  $0 flames
EOF2
}

main() {
  local cmd="${1:-help}"
  shift || true
  case "$cmd" in
    cleanup)   cmd_cleanup "$@" ;;
    stack-up)  cmd_stack_up "$@" ;;
    ping)      cmd_ping "$@" ;;
    hz)        cmd_hz "$@" ;;
    power)     cmd_power "$@" ;;
    wire)      cmd_power "$@" ;;
    flames)    cmd_flames "$@" ;;
    help|--help|-h) usage ;;
    *)
      echo "[Ω][warn] unknown command: $cmd"
      usage
      return 1
      ;;
  esac
}

main "$@"
