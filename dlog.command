#!/usr/bin/env bash
set -euo pipefail

# =======================  D L O G   L A U N C H E R  ========================
# Speaker Vortex launcher:
#   - Uses unfold.command (painter tablets) to prep worlds + flames + sky.
#   - Launches omega_speakers Rust engine (speaker + mic).
#   - No refold.command involvement (refold is only for golden bricks).
# ============================================================================

# -------------------- Locate the DLOG universe root -------------------------

if [ -n "${DLOG_ROOT-}" ] && [ -d "$DLOG_ROOT" ]; then
  ROOT="$DLOG_ROOT"
elif [ -d "$HOME/dlog" ]; then
  ROOT="$HOME/dlog"
else
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [ -d "$SCRIPT_DIR" ]; then
    ROOT="$SCRIPT_DIR"
  else
    echo "[dlog.command] Could not find DLOG root at \$DLOG_ROOT or ~/dlog." >&2
    exit 1
  fi
fi

cd "$ROOT"

export DLOG_ROOT="$ROOT"
export OMEGA_ROOT="$ROOT"

# --------------------------- Banner / Vortex UI -----------------------------

cat <<'EOF'

∞*!∞*!∞*!∞*!∞*!∞*!∞*!∞*!∞*!
   D L O G   U N I V E R S E
    S P E A K E R   V O R T E X
∞*!∞*!∞*!∞*!∞*!∞*!∞*!∞*!∞*!

  unfold.command → paints:
      worlds  = geometry / shells / auras / torus / flames meta
      flames  = flames/flames;control + sky/sky;stream

  omega_speakers → drives speaker + mic using:

      $OMEGA_ROOT/flames/flames;control
      $OMEGA_ROOT/sky/sky;stream

EOF

# ------------------ Talk to unfold.command (painter tablets) ----------------

if [ -x "./unfold.command" ]; then
  echo "[dlog.command] asking unfold.command to (re)paint worlds…"
  ./unfold.command worlds || echo "[dlog.command] warning: unfold worlds step failed (continuing)…"

  echo "[dlog.command] asking unfold.command to (re)paint flames + sky…"
  ./unfold.command flames || echo "[dlog.command] warning: unfold flames step failed (continuing)…"
else
  echo "[dlog.command] WARNING: ./unfold.command not found or not executable." >&2
  echo "[dlog.command]          Expecting painter tablets to be able to write:" >&2
  echo "                     - flames/flames;control" >&2
  echo "                     - sky/sky;stream" >&2
fi

# ------------------------ Ensure base directories exist ---------------------

mkdir -p "$OMEGA_ROOT/flames" "$OMEGA_ROOT/sky"

# ------------------------- Launch omega_speakers ----------------------------

if [ ! -d "$ROOT/omega_speakers" ]; then
  echo "[dlog.command] ERROR: omega_speakers crate not found at $ROOT/omega_speakers" >&2
  echo "[dlog.command]        Make sure your Rust audio engine lives there." >&2
  exit 1
fi

echo
echo "[dlog.command] launching omega_speakers (Leidenfrost speaker + mic)…"
echo "[dlog.command] DLOG_ROOT = $DLOG_ROOT"
echo "[dlog.command] OMEGA_ROOT = $OMEGA_ROOT"
echo

cd "$ROOT/omega_speakers"
cargo run --release
