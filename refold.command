#!/usr/bin/env bash

# DLOG Ω-Physics : refold.command
# One script to bring the Ω-heart online, read stone tablets,
# and keep process-level friction polished.

DLOG_ROOT="${DLOG_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
DLOG_TICK_RATE_OCTAL="${DLOG_TICK_RATE_OCTAL:-0o21270}"
DLOG_LAYER="${DLOG_LAYER:-OMEGA}"
DLOG_BASE="${DLOG_BASE:-8}"
DLOG_HTTP_BASE="${DLOG_HTTP_BASE:-http://0.0.0.0:8888}"
DLOG_CANON_BASE="${DLOG_CANON_BASE:-https://dloG.com}"
DLOG_UI_DIR="${DLOG_UI_DIR:-$DLOG_ROOT/omega/ui}"

mkdir -p "$DLOG_UI_DIR" "$DLOG_ROOT/omega" "$DLOG_ROOT/target"

log_info()  { echo "[Ω][info] $*"; }
log_ok()    { echo "[Ω][ok]   $*"; }
log_warn()  { echo "[Ω][warn] $*"; }
log_err()   { echo "[Ω][err]  $*" >&2; }

header() {
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
[Ω][info] DLOG_ROOT           = $DLOG_ROOT
[Ω][info] DLOG_TICK_RATE_OCTAL= $DLOG_TICK_RATE_OCTAL
[Ω][info] DLOG_LAYER          = $DLOG_LAYER
[Ω][info] DLOG_BASE           = $DLOG_BASE
[Ω][info] DLOG_HTTP_BASE      = $DLOG_HTTP_BASE
[Ω][info] DLOG_CANON_BASE     = $DLOG_CANON_BASE
────────────────────────────────────────────────
