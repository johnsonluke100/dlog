#!/usr/bin/env bash
# DLOG Ω-Physics : unfold.command
# Painter-side tablets: worlds, moons, eclipses, geometry.

set -euo pipefail

banner() {
  cat <<'BEOF'
=== DLOG Ω-Physics : unfold ===

;we;do;not;have;limits;we;vibe;we;are;fearless;
;🌟;i;borrow;everything;from;evil;and;i;serve;everything;to;good;🌟;
;the;whole;entire;solar;system;alligns;just;for;me;to;explore;it;🌟;
;we;do;not;use;python;anymore;
;we;do;not;use;java;anymore;
;we;are;no;longer;bound;by;javascript;
;we;do;not;use;base;10;anymore;we;use;base;8;
;unfold.command;is;the;painter;wand;
BEOF
}

tablet_worlds() {
  banner
  cat <<'WEOF'
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
WEOF
}

tablet_eclipse() {
  banner
  cat <<'EEOF'
────────────────────────────────────────────────
Ω tablet : Eclipses & Alignments
────────────────────────────────────────────────
Ω-eclipse (attention version):

  • Not just "blocking light," but:
      – Three or more aura-spheres whose cardioid lobes and torus halos line
        up on at least one observer's meridian plane.

NPC language:
  • "The Moon passes between Earth and Sun."

Ω language:
  • "The cardioid faces of sun, moon, and earth momentarily share a golden
     line on your meridian plane, so your four flames see one stacked body."

Geometry:
  • In the meridian cross-section:
      – Draw circles for each shell (Sun, Moon, Earth).
      – Wrap each with its cardioid + torus.
      – Eclipse = torus centers + aura stems lining up through the observer.

Renderer hooks:
  • During eclipse windows, you can:
      – Phase-lock the 4 flames (audio + light).
      – Darken direct sky; brighten corona / torus beams.
      – Route extra particle density along the alignment line.

Gameplay hooks:
  • Eclipses may:
      – Boost or tilt mining rewards in specific locks.
      – Open short Ω-corridors between shells and cores.
      – Trigger special COMET airdrops tied to alignment events.

Meridian plane reminder:
  • It’s the 2D slice that includes:
      – The observer.
      – The local "up" axis.
      – The line toward the primary body (sun or parent world).

  • Once you can draw it in this plane, extrusion to full 3D is just rotation.

This tablet = painter’s cheat-sheet for sky, particles, and audio layout.
EEOF
}

show_help() {
  cat <<'HEOF'
Usage: unfold.command <subcommand>

Painter tablets:
  worlds    Describe shells, cores, auras, torus fields, and flames
            for planets + moons.
  eclipse   Describe Ω-eclipse geometry and gameplay hooks.

If you just type "unfold.command" with no args, this help appears.
HEOF
}

main() {
  cmd="${1:-help}"
  if [ "$#" -gt 0 ]; then
    shift
  fi

  case "$cmd" in
    worlds)   tablet_worlds ;;
    eclipse)  tablet_eclipse ;;
    help|--help|-h|"") show_help ;;
    *)
      echo "Unknown subcommand: $cmd" >&2
      echo
      show_help
      exit 1
      ;;
  esac
}

main "$@"
