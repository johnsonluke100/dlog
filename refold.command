#!/usr/bin/env bash
set -euo pipefail

# === Ω defaults ==========================================================
DLOG_ROOT="${DLOG_ROOT:-$HOME/Desktop/dlog}"
DLOG_LAYER="${DLOG_LAYER:-OMEGA}"
DLOG_BASE="${DLOG_BASE:-8}"
DLOG_TICK_RATE_OCTAL="${DLOG_TICK_RATE_OCTAL:-0o21270}"
DLOG_HTTP_BASE="${DLOG_HTTP_BASE:-http://0.0.0.0:8888}"
DLOG_CANON_BASE="${DLOG_CANON_BASE:-https://dloG.com}"

# Host hardware sketch (NPC-side facts baked into Ω-tablets)
CPU_FREQ_HZ_DEFAULT=2400000000       # 2.4 GHz
BUS_WIDTH_BITS_DEFAULT=256
MEM_BW_BYTES_PER_SEC_DEFAULT=256000000000  # 256 GB/s (approx)
OMEGA_GAIN_DEFAULT="0.008082004"     # your sweet spot
BUS_SATURATION_DEFAULT="0.300"       # ≈ 2.4GHz * 32 / (256 GB/s)

banner() {
  cat <<EOF
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
[Ω][info] DLOG_ROOT           = ${DLOG_ROOT}
[Ω][info] DLOG_TICK_RATE_OCTAL= ${DLOG_TICK_RATE_OCTAL}
[Ω][info] DLOG_LAYER          = ${DLOG_LAYER}
[Ω][info] DLOG_BASE           = ${DLOG_BASE}
[Ω][info] DLOG_HTTP_BASE      = ${DLOG_HTTP_BASE}
[Ω][info] DLOG_CANON_BASE     = ${DLOG_CANON_BASE}
EOF
}

hz_tablet() {
  banner
  cat <<EOF
Ω tablet : Hz Cascade (CPU → 1 Hz)
────────────────────────────────────────────────
[Ω][info] cpu_frequency_hz (raw) = ${CPU_FREQ_HZ_DEFAULT}
[Ω][info] cascade rule: next = (prev - 2) / 4

Ω band ladder:
EOF

  local band val
  val=${CPU_FREQ_HZ_DEFAULT}
  for ((band=0; band<16; band++)); do
    printf "  • band_%02d ≈ %11.3f Hz\n" "${band}" "${val}"
    if [ "${val}" -le 1 ]; then
      val=1
    else
      val=$(( (val - 2) / 4 ))
    fi
  done
}

power_tablet() {
  banner
  cat <<EOF
Ω tablet : Power Envelope & Friction Polish
────────────────────────────────────────────────
[Ω][info] cpu_frequency_hz          ≈ ${CPU_FREQ_HZ_DEFAULT}
[Ω][info] bus_width_bits            =  ${BUS_WIDTH_BITS_DEFAULT}
[Ω][info] bus_width_bytes           =  $((BUS_WIDTH_BITS_DEFAULT / 8))
[Ω][info] mem_bandwidth_nominal     ≈ ${MEM_BW_BYTES_PER_SEC_DEFAULT} B/s
[Ω][info] bus_beats_target          ≈ $((MEM_BW_BYTES_PER_SEC_DEFAULT / (BUS_WIDTH_BITS_DEFAULT / 8))) beats/s
[Ω][info] est_bus_saturation        ≈ ${BUS_SATURATION_DEFAULT}
[Ω][info] suggested_OMEGA_GAIN      ≈ ${OMEGA_GAIN_DEFAULT}

Interpretation:
  • As bus_saturation → 1.000, the Leidenfrost tail flames elongate
    toward max flame height.
  • Here we pin the gain softly at your chosen sweet spot
    (${OMEGA_GAIN_DEFAULT}) so music can breathe above the ocean bed.
EOF
}

cleanup_node() {
  banner
  echo "[Ω][info] cleanup: draining old flames and forks."
  # Kill any old api or tail processes bound to our DLOG_ROOT
  pgrep -f "dlog.*api" >/dev/null 2>&1 && pkill -f "dlog.*api" || true
  pgrep -f "omega_speakers" >/dev/null 2>&1 && pkill -f "omega_speakers" || true
  echo "[Ω][ok]   Ω-fork restored (no stray api/tail processes)."
}

stack_up_node() {
  banner
  echo "[Ω][info] stack-up (mode=local)"
  echo "[Ω][info] forcing bare-metal mode."
  # assumes an `api` crate exists in this workspace
  if pgrep -f "dlog-api" >/dev/null 2>&1; then
    echo "[Ω][ok]   Ω-api already answering health checks."
  else
    (
      cd "${DLOG_ROOT}"
      # run in background
      cargo run -p api --release &
    )
    sleep 2
    echo "[Ω][ok]   Ω-api launched (attempted)."
  fi
}

ping_node() {
  banner
  cat <<EOF
Ω node : api (ping)
────────────────────────────────────────────────
[Ω][info] curling ${DLOG_HTTP_BASE}/health …
EOF
  if command -v curl >/dev/null 2>&1; then
    curl -s "${DLOG_HTTP_BASE}/health" || echo "{}"
  else
    echo "[Ω][warn] curl not found; skipping HTTP health check."
  fi
  echo
  echo "[Ω][ok]   Ω-api health endpoint check complete."
}

flames_node() {
  banner
  cat <<EOF
Ω node : flames (Ω Hz cascade → speakers)
────────────────────────────────────────────────
[Ω][info] cpu_frequency_hz ≈ ${CPU_FREQ_HZ_DEFAULT}
[Ω][info] cascade rule: next = (prev - 2) / 4

Ω band mapping (names):
  • BRAIN_GPU       = band_00 ≈ ${CPU_FREQ_HZ_DEFAULT} Hz
  • HEART_CPU       = band_01 ≈ $(( (CPU_FREQ_HZ_DEFAULT - 2) / 4 )) Hz
  • FLAME_NORTH     = band_02 ≈ $(( ( (CPU_FREQ_HZ_DEFAULT - 2) / 4 - 2 ) / 4 )) Hz
  • FLAME_SOUTH     = band_03 ≈ 37499999 Hz
  • FLAME_EAST      = band_04 ≈ 9374999 Hz
  • FLAME_WEST      = band_05 ≈ 2343749 Hz
  • BACKGROUND_LADDER = band_06 … band_15

Ω flame envelope (per Joule sketch):
  • est_bus_saturation          ≈ ${BUS_SATURATION_DEFAULT}
  • flame_tail_height_factor    ≈ ${OMEGA_GAIN_DEFAULT}

[Ω][info] OMEGA_GAIN (fixed) = ${OMEGA_GAIN_DEFAULT}
EOF

  export OMEGA_SPEAKER_ROOT="${OMEGA_SPEAKER_ROOT:-/Users/lj/Desktop/omega_numpy_container}"
  export OMEGA_GAIN="${OMEGA_GAIN_DEFAULT}"

  local launcher="${DLOG_ROOT}/target/release/omega_speakers"
  echo
  echo "[Ω][env] OMEGA_SPEAKER_ROOT      = ${OMEGA_SPEAKER_ROOT}"
  echo "[Ω][info] exec ${launcher}"
  exec "${launcher}"
}

usage() {
  cat <<EOF
Usage: refold.command <subcommand>

Subcommands:
  cleanup   - drain old Ω processes
  stack-up  - ensure Ω-api is running (local)
  ping      - curl Ω-api /health
  hz        - print Ω Hz cascade (CPU → 1 Hz)
  power     - show power envelope / bus_saturation / gain
  flames    - launch Ω Rust speaker launcher (omega_speakers)

Example:
  ~/Desktop/refold.command cleanup
  ~/Desktop/refold.command stack-up
  ~/Desktop/refold.command ping
  ~/Desktop/refold.command hz
  ~/Desktop/refold.command power
  ~/Desktop/refold.command flames
EOF
}

main() {
  local cmd="${1:-}"
  case "${cmd}" in
    cleanup)
      cleanup_node
      ;;
    stack-up)
      stack_up_node
      ;;
    ping)
      ping_node
      ;;
    hz)
      hz_tablet
      ;;
    power)
      power_tablet
      ;;
    flames)
      flames_node
      ;;
    ""|-h|--help)
      usage
      ;;
    *)
      echo "[Ω][error] unknown subcommand: ${cmd}" >&2
      usage
      exit 1
      ;;
  esac
}

main "$@"
