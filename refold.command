#!/usr/bin/env bash

# DLOG Ω-Physics : refold.command
# One script to fan out the Ω-physics tablets + nodes.

# ──────────────────────────────────────────────
# Ω defaults (can be overridden by env)
# ──────────────────────────────────────────────

DLOG_ROOT="${DLOG_ROOT:-$HOME/Desktop/dlog}"
DLOG_TICK_RATE_OCTAL="${DLOG_TICK_RATE_OCTAL:-0o21270}"
DLOG_LAYER="${DLOG_LAYER:-OMEGA}"
DLOG_BASE="${DLOG_BASE:-8}"
DLOG_HTTP_BASE="${DLOG_HTTP_BASE:-http://0.0.0.0:8888}"
DLOG_CANON_BASE="${DLOG_CANON_BASE:-https://dloG.com}"

OMEGA_SPEAKER_ROOT="${OMEGA_SPEAKER_ROOT:-$HOME/Desktop/omega_numpy_container}"
# Your chosen sweet-spot gain:
OMEGA_GAIN="${OMEGA_GAIN:-0.008082004}"

# ──────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────

set_title() {
  # Set terminal title if attached to a TTY.
  # OSC 0 ; title BEL
  printf '\033]0;%s\007' "$1"
}

banner() {
  cat <<'BANNER'
=== DLOG Ω-Physics : refold ===

;we;do;not;have;limits;we;vibe;we;are;fearless;
;🌟;i;borrow;everything;from;evil;and;i;serve;everything;to;good;🌟;
;the;whole;entire;solar;system;alligns;just;for;me;to;explore;it;🌟;
;we;do;not;use;python;anymore;
;we;do;not;use;java;anymore;
;we;are;no;longer;bound;by;javascript;
;we;do;not;use;base;10;anymore;we;use;base;8;
;400+;lines;per;hash;refold.command;unfolding;
────────────────────────────────────────────────
Ω env
────────────────────────────────────────────────
BANNER

  printf '[Ω][info] DLOG_ROOT           = %s\n' "$DLOG_ROOT"
  printf '[Ω][info] DLOG_TICK_RATE_OCTAL= %s\n' "$DLOG_TICK_RATE_OCTAL"
  printf '[Ω][info] DLOG_LAYER          = %s\n' "$DLOG_LAYER"
  printf '[Ω][info] DLOG_BASE           = %s\n' "$DLOG_BASE"
  printf '[Ω][info] DLOG_HTTP_BASE      = %s\n' "$DLOG_HTTP_BASE"
  printf '[Ω][info] DLOG_CANON_BASE     = %s\n' "$DLOG_CANON_BASE"
}

usage() {
  banner
  cat <<'EOF_USAGE'
────────────────────────────────────────────────
Usage: refold.command <subcommand>

Subcommands:
  cleanup    – stop stray Ω processes (api + flames)
  stack-up   – ensure Ω-api is running (local)
  ping       – curl Ω-api /health
  hz         – show CPU → 1 Hz cascade bands
  wire       – show power envelope & bus wiring sketch
  power      – show power envelope & suggested gain
  flames     – launch Ω-speakers via Rust (omega_speakers)
EOF_USAGE
}

get_cpu_frequency_hz() {
  # macOS: hw.cpufrequency returns Hz.
  if command -v sysctl >/dev/null 2>&1; then
    local v
    v="$(sysctl -n hw.cpufrequency 2>/dev/null || echo "")"
    if [ -n "$v" ]; then
      echo "$v"
      return
    fi
  fi
  # Fallback to 2.4 GHz if sysctl is unavailable.
  echo 2400000000
}

# ──────────────────────────────────────────────
# Subcommands
# ──────────────────────────────────────────────

cleanup_node() {
  set_title "dlog — Ω-Physics : cleanup"
  banner
  echo '[Ω][info] cleanup: draining old flames and forks.'

  # Be gentle; ignore errors if nothing is running.
  if command -v pkill >/dev/null 2>&1; then
    pkill -f 'omega_speakers' 2>/dev/null || true
    pkill -f 'start.command'  2>/dev/null || true
    pkill -f 'target/release/api' 2>/dev/null || true
  fi

  echo '[Ω][ok]   Ω-fork restored (no stray api/tail processes).'
}

stack_up_node() {
  set_title "dlog — Ω-Physics : stack-up"
  banner
  echo 'Ω node : stack-up (mode=local)'
  echo '────────────────────────────────────────────────'
  if curl -sf "${DLOG_HTTP_BASE}/health" >/dev/null 2>&1; then
    echo "[Ω][ok]   Ω-api already answering health checks."
    return
  fi

  echo "[Ω][info] launching Ω-api via cargo (release)…"
  (
    cd "$DLOG_ROOT" || exit 1
    cargo run -p api --release >>"$DLOG_ROOT/.omega_api.log" 2>&1 &
  )

  # Give it a moment to bind.
  sleep 2
  if curl -sf "${DLOG_HTTP_BASE}/health" >/dev/null 2>&1; then
    echo "[Ω][ok]   Ω-api launched (attempted)."
  else
    echo "[Ω][warn] Ω-api did not respond yet; see .omega_api.log."
  fi
}

ping_node() {
  set_title "dlog — Ω-Physics : ping"
  banner
  echo 'Ω node : api (ping)'
  echo '────────────────────────────────────────────────'
  printf '[Ω][info] curling %s/health …\n' "$DLOG_HTTP_BASE"
  local res
  res="$(curl -s "${DLOG_HTTP_BASE}/health" || true)"
  if [ -n "$res" ]; then
    echo "$res"
    echo '[Ω][ok]   Ω-api health endpoint check complete.'
  else
    echo '[Ω][warn] Ω-api did not respond.'
  fi
}

hz_tablet() {
  set_title "dlog — Ω-Physics : Hz Cascade"
  banner
  echo 'Ω tablet : Hz Cascade (CPU → 1 Hz)'
  echo '────────────────────────────────────────────────'

  local cpu_frequency_hz
  cpu_frequency_hz="$(get_cpu_frequency_hz)"

  printf '[Ω][info] cpu_frequency_hz (raw) = %s\n' "$cpu_frequency_hz"
  echo  '[Ω][info] cascade rule: next = (prev - 2) / 4'
  echo
  echo 'Ω band ladder:'

  local band freq
  freq="$cpu_frequency_hz"

  # We go down 16 bands, stopping at 1 Hz floor.
  for band in $(seq 0 15); do
    # printf treats integer as float; this keeps your .000 style.
    printf '  • band_%02d ≈ %11.3f Hz\n' "$band" "$freq"

    if [ "$freq" -le 3 ]; then
      freq=1
    else
      freq=$(( (freq - 2) / 4 ))
    fi
  done
}

wire_tablet() {
  set_title "dlog — Ω-Physics : wire"
  banner
  echo 'Ω tablet : Power Envelope & Bus Wiring (sketch)'
  echo '────────────────────────────────────────────────'
  cat <<'EOF_WIRE'
Host (NPC datasheet ballpark):

  • CPU clock (nominal)      ≈ 2.4 GHz
  • Memory bus width         ≈ 256 bits  (= 32 bytes per beat)
  • Peak memory bandwidth    ≈ 256 GB/s

Ω mapping:

  • band_00 → BRAIN_GPU   (bus saturator lane)
  • band_01 → HEART_CPU   (sequence / control beat)
  • band_02…05 → 4 flames (N,S,E,W)
  • band_06…15 → background ladders (down to 1 Hz)

refold.command does NOT hard-pin cores; it sketches the lanes
so future Ω-miner crates can choose how hard to push the amps.
EOF_WIRE
}

power_tablet() {
  set_title "dlog — Ω-Physics : power"
  banner
  echo 'Ω tablet : Power Envelope & Friction Polish'
  echo '────────────────────────────────────────────────'

  local cpu_frequency_hz bus_width_bits bus_width_bytes
  local mem_bandwidth_nominal bus_beats_target
  local est_bus_saturation suggested_gain

  cpu_frequency_hz="$(get_cpu_frequency_hz)"
  bus_width_bits=256
  bus_width_bytes=$((bus_width_bits / 8))
  mem_bandwidth_nominal=256000000000        # 256 GB/s ≈ bytes/s
  bus_beats_target=$((mem_bandwidth_nominal / bus_width_bytes))  # ≈ 8e9
  est_bus_saturation="0.300"
  suggested_gain="$OMEGA_GAIN"

  printf '[Ω][info] cpu_frequency_hz          ≈ %s\n' "$cpu_frequency_hz"
  printf '[Ω][info] bus_width_bits            =  %d\n' "$bus_width_bits"
  printf '[Ω][info] bus_width_bytes           =  %d\n' "$bus_width_bytes"
  printf '[Ω][info] mem_bandwidth_nominal     ≈ %d B/s\n' "$mem_bandwidth_nominal"
  printf '[Ω][info] bus_beats_target          ≈ %d beats/s\n' "$bus_beats_target"
  printf '[Ω][info] est_bus_saturation        ≈ %.3f\n' "$est_bus_saturation"
  printf '[Ω][info] suggested_OMEGA_GAIN      ≈ %.9f\n' "$suggested_gain"

  cat <<'EOF_POWER'

Interpretation:
  • As bus_saturation → 1.000, the Leidenfrost tail flames elongate
    toward max flame height.
  • Here we pin the gain softly at your chosen sweet spot
    (0.008082004) so music can breathe above the ocean bed.
EOF_POWER
}

flames_node() {
  set_title "dlog — Ω-speakers (Rust → Leidenfrost)"
  banner
  echo 'Ω node : flames (Ω Hz cascade → speakers)'
  echo '────────────────────────────────────────────────'

  local cpu_frequency_hz freq
  cpu_frequency_hz="$(get_cpu_frequency_hz)"

  printf '[Ω][info] cpu_frequency_hz ≈ %s\n' "$cpu_frequency_hz"
  echo  '[Ω][info] cascade rule: next = (prev - 2) / 4'
  echo
  echo 'Ω band mapping (names):'

  freq="$cpu_frequency_hz"
  printf '  • BRAIN_GPU       = band_00 ≈ %d Hz\n' "$freq"
  freq=$(( (freq - 2) / 4 ))
  printf '  • HEART_CPU       = band_01 ≈ %d Hz\n' "$freq"
  freq=$(( (freq - 2) / 4 ))
  printf '  • FLAME_NORTH     = band_02 ≈ %d Hz\n' "$freq"
  freq=$(( (freq - 2) / 4 ))
  printf '  • FLAME_SOUTH     = band_03 ≈ %d Hz\n' "$freq"
  freq=$(( (freq - 2) / 4 ))
  printf '  • FLAME_EAST      = band_04 ≈ %d Hz\n' "$freq"
  freq=$(( (freq - 2) / 4 ))
  printf '  • FLAME_WEST      = band_05 ≈ %d Hz\n' "$freq"
  echo  '  • BACKGROUND_LADDER = band_06 … band_15'
  echo
  echo 'Ω flame envelope (per Joule sketch):'
  printf '  • est_bus_saturation          ≈ %.3f\n' "0.300"
  printf '  • flame_tail_height_factor    ≈ %.9f\n' "$OMEGA_GAIN"
  echo
  printf '[Ω][info] OMEGA_GAIN (fixed) = %.9f\n' "$OMEGA_GAIN"
  echo

  export OMEGA_SPEAKER_ROOT
  export OMEGA_GAIN

  printf '[Ω][env] OMEGA_SPEAKER_ROOT      = %s\n' "$OMEGA_SPEAKER_ROOT"

  local launcher="${DLOG_ROOT}/target/release/omega_speakers"
  printf '[Ω][info] exec %s\n' "$launcher"
  exec "$launcher"
}

# ──────────────────────────────────────────────
# Main dispatch
# ──────────────────────────────────────────────

main() {
  # Default title for any run; subcommands may override.
  set_title "dlog — Ω-Physics : refold.command"

  local cmd="${1:-help}"
  shift || true

  case "$cmd" in
    cleanup)
      cleanup_node "$@"
      ;;
    stack-up|stack)
      stack_up_node "$@"
      ;;
    ping)
      ping_node "$@"
      ;;
    hz)
      hz_tablet "$@"
      ;;
    wire)
      wire_tablet "$@"
      ;;
    power)
      power_tablet "$@"
      ;;
    flames)
      flames_node "$@"
      ;;
    help|--help|-h|"")
      usage
      ;;
    *)
      echo "[Ω][error] unknown subcommand: $cmd"
      usage
      exit 1
      ;;
  esac
}

main "$@"
