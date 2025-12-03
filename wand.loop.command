#!/usr/bin/env bash
set -euo pipefail

# Run wand every N seconds (default 8). Respects env like KUBE_SYNC_SKIP,
# KUBE_CONTEXTS, OMEGA_BANK_PASSPHRASE (via launchctl or this shell).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

SLEEP_SECONDS="${WAND_LOOP_SLEEP:-8}"

trap 'echo "[wand-loop] received interrupt; stopping." >&2; exit 0' INT TERM

echo "[wand-loop] starting; interval=${SLEEP_SECONDS}s (Ctrl+C to stop)" >&2

while true; do
  echo "[wand-loop] running wand @ $(date +"%Y-%m-%d %H:%M:%S")" >&2
  OMEGA_UNLOCK_NONINTERACTIVE=1 KUBE_SYNC_SKIP=1 ./refold.command wand || echo "[wand-loop] wand exited non-zero ($?)" >&2
  # Status-only: avoid restarting/scaling Paper to prevent flapping
  kubectl get endpoints paper-188 || echo "[wand-loop] endpoints fetch failed" >&2
  # Check API paper status (uses run.app URL; adjust if needed)
  curl -s https://dlog-api-679172910792.us-east1.run.app/v1/paper/status || echo "[wand-loop] paper status check failed" >&2
  sleep "$SLEEP_SECONDS"
done
