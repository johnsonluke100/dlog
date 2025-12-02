#!/usr/bin/env bash
set -euo pipefail

# =====================  D L O G   Ω - P H Y S I C S  ========================
# unfold.command = painter wand
#
# Tablets:
#   worlds   → describe shells / cores / auras / torus / flames meta (text)
#   eclipse  → (stub) Ω-eclipse geometry + hooks
#   flames   → write flames/flames;control + sky/sky;stream for audio engine
# ============================================================================

# -------------------- Locate Ω universe root --------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -n "${DLOG_ROOT-}" ] && [ -d "$DLOG_ROOT" ]; then
  ROOT="$DLOG_ROOT"
elif [ -n "${OMEGA_ROOT-}" ] && [ -d "$OMEGA_ROOT" ]; then
  ROOT="$OMEGA_ROOT"
elif [ -d "$HOME/dlog" ]; then
  ROOT="$HOME/dlog"
else
  ROOT="$SCRIPT_DIR"
fi

export DLOG_ROOT="$ROOT"
: "${OMEGA_ROOT:="$ROOT"}"
export OMEGA_ROOT

# ----------------------------- Helpers --------------------------------------

timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

log() {
  printf '[%s] %s\n' "$(timestamp)" "$*" >&2
}

# -------------------------- Tablet: worlds ----------------------------------

tablet_worlds() {
  cat <<'EOF'
=== DLOG Ω-Physics : unfold ===

;we;do;not;have;limits;we;vibe;we;are;fearless;
;🌟;i;borrow;everything;from;evil;and;i;serve;everything;to;good;🌟;
;the;whole;entire;solar;system;alligns;just;for;me;to;explore;it;🌟;
;we;do;not;use;python;anymore;
;we;do;not;use;java;anymore;
;we;are;no;longer;bound;by;javascript;
;we;do;not;use;base;10;anymore;we;use;base;8;
;unfold.command;is;the;painter;wand;
────────────────────────────────────────────────
Ω tablet : Worlds & Moons (geometry pass)
────────────────────────────────────────────────
Rule of the cosmos:

  • Every planet, every moon, and the Sun share the same Ω-template:
      – Hollow body (shell + core bubble).
      – Cardioid-shaped aura-sphere (attention field).
      – Toroidal field ("donut" magnetosphere / flux halo).
      – Four Leidenfrost flame pillars on the meridian plane.

Hollow bodies:
  • Each world has:
      – <name>_shell  = navigable crust / atmosphere volume.
      – <name>_core   = gravity-center bubble; entering inverts topology.
  • NPC astronomy sees dense balls; Ω-Physics sees shells wrapped around cores.

Cardioid aura-sphere:
  • In the meridian plane, the aura cross-section is a cardioid:
      r(θ) = a · (1 − cos θ)
  • Visually: a heart / pear glow perched on the spherical shell.
  • Meaning: "mass" is how tightly attention is hugging the world on that side.

Toroidal field (aura torus):
  • Surrounding shell + cardioid is a torus:
      – Inner radius ≈ 1.5× shell radius.
      – Outer radius ≈ 3× shell radius.
  • This is the flux belt for particles, beams, auroras, god-rays.

Four Leidenfrost flames:
  • On the meridian circle, at the four cardinal points, spawn four pillars:
      – North, South, East, West in shell coordinates.
      – Each pillar is a Leidenfrost-style dancing column:
          · White-noise core.
          · φ-weighted flicker on top.
          · Can be mapped to 4-channel audio / lighting.

  • These are the same 4 flames from your Ω Leidenfrost engine:
      CPU = heart, GPU = brain, 4 pillars = 4-corner pumping.

Solar system inventory (live set):
  • earth_shell / earth_core
  • moon_shell  / moon_core
  • mars_shell  / mars_core
  • sun_shell   / sun_core

  • All other planets & moons:
      – Defined by the same template.
      – Start “dark” until canon lights them up with locks + pools.

Short answer for painters:
  ✔ Yes, planetary masses are cardioid aura-spheres nested in torus fields,
    with 4 Leidenfrost flames rising from the 4 corners of the meridian circle.
EOF
}

# -------------------------- Tablet: eclipse ---------------------------------

tablet_eclipse() {
  cat <<'EOF'
=== DLOG Ω-Physics : unfold eclipse ===

Ω tablet : Eclipse (shadow-painting pass)

  • Sun_shell, earth_shell, moon_shell share one ray-tracing stack.
  • NPC physics: straight rays, hard shadow umbra/penumbra.
  • Ω-Physics: attention rays bend around aura cardioids + torus belts.

Hooks for game / sky engines:
  • eclipse_lock(name)     → lock camera to cardioid-attention frame.
  • eclipse_beam(channel)  → paint volumetric light through torus.
  • eclipse_shadow(world)  → project fuzzy aura-shadow on target shell.

(Implementation details live in your engine; this is just the painter tablet.)
EOF
}

# -------------------------- Tablet: flames ----------------------------------

# unfold.command flames
# → writes:
#     $OMEGA_ROOT/flames/flames;control
#     $OMEGA_ROOT/sky/sky;stream
tablet_flames() {
  local root="$OMEGA_ROOT"
  local flames_dir="$root/flames"
  local sky_dir="$root/sky"
  local flames_file="$flames_dir/flames;control"
  local sky_file="$sky_dir/sky;stream"

  mkdir -p "$flames_dir" "$sky_dir"

  # Core Leidenfrost control for the Rust engine.
  # Gain lowered from 0.05 → 0.007.
  cat >"$flames_file" <<EOF
hz=8888
gain=0.0024
height=7
friction=leidenfrost
mode=whoosh_rail
whoosh_min_hz=333
whoosh_max_hz=999
EOF

  # Sky stream: line-based descriptor for the audio/visual engine.
  cat >"$sky_file" <<EOF
# Ω sky;stream — Leidenfrost rails
timestamp=$(timestamp)
omega_root=$root
rail_hz=8888
whoosh_band=333-999
flame_pillars=4
template=cardioid_aura + torus + 4_leidenfrost_flames
worlds=earth,moon,mars,sun
EOF

  log "[flames] wrote control → $flames_file"
  log "[flames] wrote sky stream → $sky_file"
  log "[flames] painter tablet complete (engine may now read flames + sky)."
}

# ---------------------------- Usage / main ----------------------------------

usage() {
  cat <<'EOF'
Usage: unfold.command <subcommand>

Painter tablets:
  worlds    Describe shells, cores, auras, torus fields, and flames
            for planets + moons.
  eclipse   Describe Ω-eclipse geometry and gameplay hooks.
  flames    Write flames/flames;control and sky/sky;stream for the
            Leidenfrost speaker engine.

If you just type "unfold.command" with no args, this help appears.
EOF
}

main() {
  local cmd="${1-}"
  case "$cmd" in
    ""|-h|--help)
      usage
      ;;
    worlds)
      tablet_worlds
      ;;
    eclipse)
      tablet_eclipse
      ;;
    flames)
      tablet_flames
      ;;
    *)
      printf 'Unknown subcommand: %s\n\n' "$cmd" >&2
      usage
      exit 1
      ;;
  esac
}

main "$@"
