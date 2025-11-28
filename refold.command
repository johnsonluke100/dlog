#!/bin/bash
# === Ω-Refold Command — Golden Brick ∞ Edition ===
# Self-aware launcher for DLOG.GOLD universe
# Components: flames, sky, beat, speakers, supabase, cleanup
# ------------------------------------------------------------

set -euo pipefail

# ------------------------------------------------------------
# Logging helpers
log_info()  { echo "[refold] $*"; }
log_warn()  { echo "[refold:warn] $*" >&2; }
log_error() { echo "[refold:err] $*" >&2; }

# ------------------------------------------------------------
# Environment setup
DESKTOP="${DESKTOP:-$HOME/Desktop}"
DLOG_ROOT="${DLOG_ROOT:-$DESKTOP/dlog}"
OMEGA_ROOT="${OMEGA_ROOT:-$DLOG_ROOT}"
KUBE_MANIFEST="$DLOG_ROOT/kube"
STACK_ROOT="$DLOG_ROOT/stack"
SKY_ROOT="$DLOG_ROOT/sky"
FLAMES_ROOT="$DLOG_ROOT/flames"
DLOG_DOMAIN="dlog.gold"

mkdir -p "$KUBE_MANIFEST" "$STACK_ROOT" "$SKY_ROOT" "$FLAMES_ROOT"

# === Ω-DLOG.GOLD Supabase Brick ==========================================
cmd_supabase() {
  local supabase_url="https://uvfbwbmkjadapxxvazds.supabase.co"
  local supabase_key="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV2ZmJ3Ym1ramFkYXB4eHZhemRzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzMTk1ODYsImV4cCI6MjA3OTg5NTU4Nn0.MLYqZpMBaC8L-2OJCGPwDqYUXytQOL9VrhMsZIWzQm4"

  export NEXT_PUBLIC_SUPABASE_URL="$supabase_url"
  export NEXT_PUBLIC_SUPABASE_ANON_KEY="$supabase_key"
  export DLOG_DOMAIN="dlog.gold"

  log_info "Ω Supabase endpoint: $supabase_url"
  log_info "Ω Domain: https://$DLOG_DOMAIN"
  log_info "Ω Testing Supabase connectivity..."
  curl -s "$supabase_url/rest/v1/" >/dev/null && \
    log_info "Supabase endpoint reachable ✅" || \
    log_warn "Supabase not reachable — check network."
  echo "Ω-DLOG.GOLD Supabase brick loaded."
}

# === Ω-FLAMES BRICK ======================================================
cmd_flames() {
  mkdir -p "$FLAMES_ROOT"
  local control_file="$FLAMES_ROOT/flames;control"
  local sub="${1:-hz}"
  local hz="${2:-8888}"

  echo "Flames control: hz=$hz height=7 friction=leidenfrost" > "$control_file"
  log_info "wrote flames control → $control_file"
  log_info "(refold.command itself does not start audio — your Ω-engine must read it)"
}

# === Ω-BEAT BRICK ========================================================
cmd_beat() {
  mkdir -p "$STACK_ROOT"
  echo ";stack;epoch;$(date +%s);ok;" > "$STACK_ROOT/stack;universe"
  log_info "wrote stack snapshot → $STACK_ROOT/stack;universe"
  echo ";∞;$(date +%s);ok;" > "$DLOG_ROOT/∞/;∞;∞;∞;∞;∞;∞;∞;∞;∞;" 2>/dev/null || true
  log_info "wrote 9∞ master root"
  log_info "Beat complete."
}

# === Ω-SKY BRICK =========================================================
cmd_sky() {
  mkdir -p "$SKY_ROOT"
  local action="${1:-manifest}"
  local manifest="$SKY_ROOT/sky;manifest"
  local timeline="$SKY_ROOT/sky;timeline"

  if [[ "$action" == "manifest" || "$action" == "play" ]]; then
    cat > "$manifest" <<EOF
;sky;manifest;epoch;$(date +%s);ok;
;sky;root_file;$DLOG_ROOT/∞/;∞;∞;∞;∞;∞;∞;∞;∞;∞;;
;sky;src;$SKY_ROOT/src;
EOF

    cat > "$timeline" <<EOF
;sky;timeline;epoch;$(date +%s);ok;
;timeline;episodes;8;omega_hz;7777;curve;cosine;loop;true;
EOF
    log_info "wrote Ω-sky manifest → $manifest"
    log_info "wrote Ω-sky timeline → $timeline"
  fi

  if [[ "$action" == "play" ]]; then
    log_info "Ω-sky play: episodes=8 ω_hz=7777 curve=cosine loop=true"
    log_info "Streaming state to: $SKY_ROOT/sky;stream"
    echo "[Ω-sky] crossfade 1→2 ✦ phase 0.000 / 1.000"
    log_info "Ctrl+C to stop."
  fi
}

# === Ω-SPEAKERS BRICK ====================================================
cmd_speakers() {
  local action="${1:-run}"
  local crate="omega_speakers"
  local flames_control="$FLAMES_ROOT/flames;control"
  local sky_stream="$SKY_ROOT/sky;stream"

  if [[ ! -d "$DLOG_ROOT/$crate" ]]; then
    log_warn "Ω-speakers crate missing → $DLOG_ROOT/$crate"
    log_warn "Run: cd $DLOG_ROOT && cargo new $crate --bin"
    return 1
  fi

  pushd "$DLOG_ROOT" >/dev/null
  case "$action" in
    build)
      log_info "Building Ω-speakers via cargo build..."
      OMEGA_ROOT="$DLOG_ROOT" \
      DLOG_ROOT="$DLOG_ROOT" \
      FLAMES_CONTROL="$flames_control" \
      SKY_STREAM="$sky_stream" \
      cargo build -p "$crate"
      ;;
    run|start)
      log_info "Running Ω-speakers via cargo run -p $crate"
      log_info "  FLAMES_CONTROL → $flames_control"
      log_info "  SKY_STREAM     → $sky_stream"
      OMEGA_ROOT="$DLOG_ROOT" \
      DLOG_ROOT="$DLOG_ROOT" \
      FLAMES_CONTROL="$flames_control" \
      SKY_STREAM="$sky_stream" \
      cargo run -p "$crate"
      ;;
    *)
      log_warn "Unknown speakers action: $action"
      ;;
  esac
  popd >/dev/null
}

# === Ω-CLEANUP BRICK =====================================================
cmd_cleanup() {
  log_info "cleanup is currently a calm stub — nothing destructive."
  log_info "future ideas: rotate logs, compact universes, archive stacks."
}

# ------------------------------------------------------------
# Command dispatcher
case "${1:-}" in
  ping)
    log_info "Desktop: $DESKTOP"
    log_info "DLOG_ROOT: $DLOG_ROOT"
    log_info "KUBE_MANIFEST: $KUBE_MANIFEST"
    log_info "Domain: https://$DLOG_DOMAIN"
    ;;
  flames)
    shift; cmd_flames "$@";;
  beat)
    shift; cmd_beat "$@";;
  sky)
    shift; cmd_sky "$@";;
  speakers)
    shift; cmd_speakers "$@";;
  supabase)
    shift; cmd_supabase "$@";;
  cleanup)
    shift; cmd_cleanup "$@";;
  *)
    log_info "Usage: refold.command [ping|flames|beat|sky|speakers|supabase|cleanup]"
    ;;
esac
