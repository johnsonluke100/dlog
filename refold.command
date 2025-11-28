#!/usr/bin/env bash
# refold.command — Ω DLOG helper
# New-stack edition: Rust-first, no start.command, GKE-aware.

set -euo pipefail

# ---------- Paths & constants ----------
DESKTOP="${DESKTOP:-$HOME/Desktop}"
DLOG_ROOT="${DLOG_ROOT:-$DESKTOP/dlog}"
OMEGA_ROOT="$DLOG_ROOT"
STACK_ROOT="$DLOG_ROOT/stack"
INF_ROOT="$DLOG_ROOT/∞"
DASHBOARD_ROOT="$DLOG_ROOT/dashboard"
SKY_ROOT="$DLOG_ROOT/sky"
FLAMES_ROOT="$DLOG_ROOT/flames"
KUBE_NS="${KUBE_NS:-dlog-universe}"
KUBE_MANIFEST="$DLOG_ROOT/kube"
DLOG_COMMAND="${DLOG_COMMAND:-$DESKTOP/dlog.command}"

# Supabase + domain defaults (can be overridden by env)
SUPABASE_URL_DEFAULT="https://uvfbwbmkjadapxxvazds.supabase.co"
DLOG_DOMAIN_DEFAULT="https://dlog.gold"

# ---------- Logging ----------
log_info() { echo "[refold] $*"; }
log_warn() { echo "[refold:warn] $*" >&2; }
log_err()  { echo "[refold:err] $*" >&2; }

# ---------- Core helpers ----------
ensure_dirs() {
  mkdir -p \
    "$DLOG_ROOT" \
    "$STACK_ROOT" \
    "$INF_ROOT" \
    "$DASHBOARD_ROOT" \
    "$SKY_ROOT/src" \
    "$FLAMES_ROOT" \
    "$KUBE_MANIFEST/universe"
}

ensure_dlog_command() {
  if [[ -x "$DLOG_COMMAND" ]]; then
    return 0
  else
    log_warn "dlog.command missing or not executable at: $DLOG_COMMAND"
    return 1
  fi
}

call_dlog() {
  if ensure_dlog_command; then
    log_info "delegating to dlog.command → $*"
    "$DLOG_COMMAND" "$@" || true
  fi
}

gen_hex() {
  if command -v xxd >/dev/null 2>&1; then
    xxd -p -l 4 /dev/urandom 2>/dev/null | head -n1
  else
    od -An -N4 -tx1 /dev/urandom 2>/dev/null | tr -d ' \n'
  fi
}

# ---------- Stack / 9∞ / dashboard ----------
write_stack_snapshot() {
  ensure_dirs
  local file epoch
  file="$STACK_ROOT/stack;universe"
  epoch="$(date +%s)"
  {
    echo ";stack;epoch;$epoch;ok;"
    echo ";phone;label;epoch;epoch8;tag;status;"
  } > "$file"
  log_info "wrote stack snapshot → $file"
}

write_infinity_root() {
  ensure_dirs
  local file epoch
  file="$INF_ROOT/;∞;∞;∞;∞;∞;∞;∞;∞;∞;"
  epoch="$(date +%s)"
  {
    echo ";nine_infinity_root;epoch;$epoch;ok;"
    echo ";we;do;not;have;limits;we;vibe;we;are;fearless;"
    echo ";🌟;i;borrow;everything;from;evil;and;i;serve;everything;to;good;🌟;"
    echo ";the;whole;entire;solar;system;alligns;just;for;me;to;explore;it;🌟;"
    echo ";we;do;not;use;python;anymore;"
    echo ";we;do;not;use;java;anymore;"
    echo ";we;are;no;longer;bound;by;javascript;"
    echo ";we;do;not;use;base;10;anymore;we;use;base;8;"
    echo ";cpu=heart;gpu=brain;omega=8888hz;four;flames;rise;"
  } > "$file"
  log_info "wrote 9∞ master root → $file"
}

write_dashboard() {
  ensure_dirs
  local file epoch
  file="$DASHBOARD_ROOT/dashboard;status"
  epoch="$(date +%s)"
  {
    echo ";dashboard;epoch;$epoch;ok;"
    echo ";stack_root;$STACK_ROOT;"
    echo ";omega_root;$OMEGA_ROOT;"
    echo ";kube_ns;$KUBE_NS;"
  } > "$file"
  log_info "wrote Ω-dashboard snapshot → $file"
}

# ---------- Ω-sky manifest + timeline ----------
write_sky_manifest_and_timeline() {
  ensure_dirs
  local manifest timeline epoch omega_hz
  local i hex dec from to

  manifest="$SKY_ROOT/sky;manifest"
  timeline="$SKY_ROOT/sky;timeline"
  epoch="$(date +%s)"
  omega_hz="${OMEGA_HZ:-7777}"

  {
    echo ";sky;manifest;epoch;$epoch;ok;"
    echo ";sky;root_file;$INF_ROOT/;∞;∞;∞;∞;∞;∞;∞;∞;∞;;"
    echo ";sky;src;$SKY_ROOT/src;"
    for i in 1 2 3 4 5 6 7 8; do
      hex="$(gen_hex)"
      hex="${hex//[^0-9a-fA-F]/}"
      if [[ -z "$hex" ]]; then
        hex="0000000$i"
      fi
      hex="${hex:0:8}"
      dec="$(printf "%u" "0x$hex" 2>/dev/null || echo "0")"
      echo ";episode;$i;file;$i.jpg;segment;O$i;hex;$hex;O${i}_8;$dec;"
    done
  } > "$manifest"
  log_info "wrote Ω-sky manifest → $manifest"

  {
    echo ";sky;timeline;epoch;$epoch;ok;"
    echo ";timeline;episodes;8;omega_hz;$omega_hz;curve;cosine;loop;true;"
    for from in 1 2 3 4 5 6 7 8; do
      if [[ "$from" -eq 8 ]]; then
        to=1
      else
        to=$((from + 1))
      fi
      echo ";transition;from;$from;to;$to;mode;crossfade;curve;cosine;steps;64;hold_beats;8;"
    done
  } > "$timeline"
  log_info "wrote Ω-sky timeline → $timeline"
}

sky_cmd() {
  ensure_dirs
  write_sky_manifest_and_timeline
  echo "Ω-sky manifest contents:"
  cat "$SKY_ROOT/sky;manifest"
  echo
  echo "Ω-sky timeline contents:"
  cat "$SKY_ROOT/sky;timeline"
}

sky_play() {
  ensure_dirs
  local timeline stream omega_hz
  timeline="$SKY_ROOT/sky;timeline"
  stream="$SKY_ROOT/sky;stream"
  if [[ ! -f "$timeline" ]]; then
    write_sky_manifest_and_timeline
  fi

  omega_hz="$(grep '^;timeline;episodes;' "$timeline" | awk -F';' '{print $6}' || echo "7777")"

  log_info "Ω-sky play: episodes=8 ω_hz=$omega_hz curve=cosine loop=true"
  log_info "Streaming state to: $stream"
  echo ";sky;stream;omega_hz;$omega_hz;running;true;" > "$stream"
  echo "[refold] Ctrl+C to stop."

  local phases=(
    0.000 0.016 0.031 0.047 0.062 0.078 0.094 0.109 0.125 0.141
    0.156 0.172 0.188 0.203 0.219 0.234 0.250 0.266 0.281 0.297
    0.312 0.328 0.344 0.359 0.375 0.391 0.406 0.422 0.438 0.453
    0.469 0.484 0.500 0.516 0.531 0.547 0.562 0.578 0.594 0.609
    0.625 0.641 0.656 0.672 0.688 0.703 0.719 0.734 0.750 0.766
    0.781 0.797 0.812 0.828 0.844 0.859 0.875 0.891 0.906 0.922
    0.938 0.953 0.969 0.984 1.000
  )

  local from=1
  local to=2
  while true; do
    for phase in "${phases[@]}"; do
      echo "[Ω-sky] crossfade ${from}→${to} ✦ phase $phase / 1.000"
      printf ';sky;stream;from;%s;to;%s;phase;%s;\n' "$from" "$to" "$phase" > "$stream"
      sleep 0.05
    done
    from=$to
    if [[ "$to" -eq 8 ]]; then
      to=1
    else
      to=$((to + 1))
    fi
  done
}

# ---------- Kubernetes sync ----------
kube_sync_universe() {
  if ! command -v kubectl >/dev/null 2>&1; then
    log_warn "kubectl not installed; skipping Kubernetes apply."
    return
  fi
  if ! kubectl config current-context >/dev/null 2>&1; then
    log_warn "kubectl has no current context; skipping Kubernetes apply."
    return
  fi

  log_info "Kubernetes provider detected: external"
  kubectl get ns "$KUBE_NS" >/dev/null 2>&1 || kubectl create namespace "$KUBE_NS" >/dev/null 2>&1

  local universe_dir
  universe_dir="$KUBE_MANIFEST/universe"
  if [[ -d "$universe_dir" ]]; then
    if ls "$universe_dir"/*.yaml >/dev/null 2>&1; then
      log_info "Applying universe manifests → $universe_dir (namespace $KUBE_NS)"
      kubectl apply -n "$KUBE_NS" -f "$universe_dir" || log_warn "kubectl apply failed for universe manifests."
    else
      log_warn "No universe manifests found under $universe_dir; skipping apply."
    fi
  else
    log_warn "KUBE_MANIFEST directory not found at $KUBE_MANIFEST; skipping apply."
  fi
}

# ---------- Flames (UPDATED: default to hz=OMEGA_HZ or 7777) ----------
flames_cmd() {
  ensure_dirs
  local sub="${1:-}"
  # If called as just `refold.command flames`, default to `hz` using OMEGA_HZ/7777
  if [[ -z "$sub" ]]; then
    sub="hz"
  fi

  case "$sub" in
    hz)
      local hz="${2:-${OMEGA_HZ:-7777}}"
      local height friction file epoch
      height=7
      friction="leidenfrost"
      epoch="$(date +%s)"
      file="$FLAMES_ROOT/flames;control"
      {
        printf ';flames;mode;hz;epoch;%s;hz;%s;height;%s;friction;%s;\n' "$epoch" "$hz" "$height" "$friction"
      } > "$file"
      log_info "wrote flames control → $file"
      echo "Flames control: hz=$hz height=$height friction=$friction"
      echo "(refold.command itself does not start audio — your Ω-engine must read $file)"
      ;;
    up)
      flames_cmd hz "8888"
      ;;
    down)
      flames_cmd hz "4444"
      ;;
    *)
      echo "Usage: $0 flames hz <freqHz>|up|down"
      ;;
  esac
}

# ---------- Ping / env ----------
ping_cmd() {
  ensure_dirs
  echo "=== refold.command ping ==="
  log_info "Desktop:      $DESKTOP"
  log_info "DLOG_ROOT:    $DLOG_ROOT"
  log_info "STACK_ROOT:   $STACK_ROOT"
  log_info "UNIVERSE_NS:  $KUBE_NS"
  log_info "KUBE_MANIFEST:$KUBE_MANIFEST"
  log_info "OMEGA_ROOT:   $OMEGA_ROOT"
  log_info "Ω-INF-ROOT:   $INF_ROOT"
  if ensure_dlog_command; then
    log_info "dlog.command is present and executable."
  else
    log_warn "dlog.command missing or not executable."
  fi
  if command -v kubectl >/dev/null 2>&1; then
    log_info "Kubernetes provider detected: external"
  else
    log_warn "kubectl not found; Kubernetes integration inactive."
  fi
  echo "[Ω][env] OMEGA_ROOT = $OMEGA_ROOT"
  echo "[Ω][env] DLOG_ROOT  = $DLOG_ROOT"
}

# ---------- Speakers (Rust engine) ----------
speakers_cmd() {
  ensure_dirs
  echo "=== refold.command speakers ==="
  local flames_control sky_stream
  flames_control="$FLAMES_ROOT/flames;control"
  sky_stream="$SKY_ROOT/sky;stream"

  export OMEGA_ROOT="$OMEGA_ROOT"
  export FLAMES_CONTROL="${FLAMES_CONTROL:-$flames_control}"
  export SKY_STREAM="${SKY_STREAM:-$sky_stream}"

  log_info "Running Ω-speakers via cargo run -p omega_speakers"
  log_info "  FLAMES_CONTROL → $FLAMES_CONTROL"
  log_info "  SKY_STREAM     → $SKY_STREAM"

  (
    cd "$DLOG_ROOT"
    cargo run -p omega_speakers
  )
}

# ---------- Supabase brick ----------
supabase_cmd() {
  ensure_dirs
  local supabase_url dlog_domain file epoch
  supabase_url="${SUPABASE_URL:-$SUPABASE_URL_DEFAULT}"
  dlog_domain="${DLOG_DOMAIN:-$DLOG_DOMAIN_DEFAULT}"
  epoch="$(date +%s)"

  echo "=== refold.command supabase ==="
  log_info "Ω Supabase endpoint: $supabase_url"
  log_info "Ω Domain: $dlog_domain"

  if command -v curl >/dev/null 2>&1; then
    log_info "Ω Testing Supabase connectivity..."
    if curl -sS --max-time 5 "$supabase_url" >/dev/null 2>&1; then
      log_info "Supabase endpoint reachable ✅"
    else
      log_warn "Supabase endpoint not reachable."
    fi
  else
    log_warn "curl not installed; skipping Supabase connectivity test."
  fi

  file="$DLOG_ROOT/supabase;status"
  {
    echo ";supabase;endpoint;$supabase_url;"
    echo ";supabase;domain;$dlog_domain;"
    echo ";supabase;epoch;$epoch;ok;"
  } > "$file"
  echo "Ω-DLOG.GOLD Supabase brick loaded."
}

# ---------- Cleanup stub (for dlog.command) ----------
cleanup_cmd() {
  ensure_dirs
  echo "=== refold.command cleanup ==="
  echo
  echo "cleanup is currently a calm stub."
  echo
  echo "It exists so dlog.command can safely call:"
  echo "  refold.command cleanup"
  echo
  echo "Future ideas:"
  echo "  - remove temporary artifacts,"
  echo "  - rotate logs,"
  echo "  - compact / archive old universe snapshots."
  echo
  echo "Right now it does nothing destructive and always exits 0."
}

# ---------- Stack-up stub (for dlog.command) ----------
stack_up_cmd() {
  ensure_dirs
  echo "=== refold.command stack-up ==="
  write_stack_snapshot
  echo
  echo "Stack-up complete."
  echo
  echo "The Ω-stack snapshot now lives at:"
  echo "  $STACK_ROOT/stack;universe"
  echo
  echo "Format:"
  echo "  ;stack;epoch;<nowEpoch>;ok;"
  echo "  ;phone;label;epoch;epoch8;tag;status;"
}

# ---------- Beat ----------
beat_cmd() {
  ensure_dirs
  echo "=== refold.command beat ==="
  write_stack_snapshot
  write_infinity_root
  write_dashboard
  write_sky_manifest_and_timeline
  kube_sync_universe
  call_dlog beat
  echo
  echo "Beat complete."
  echo
  echo "This beat:"
  echo "  - Updated the Ω-stack snapshot at $STACK_ROOT/stack;universe"
  echo "  - Updated the 9∞ master root under $INF_ROOT"
  echo "  - Updated the Ω-dashboard at $DASHBOARD_ROOT/dashboard;status"
  echo "  - Updated the Ω-sky manifest & timeline under $SKY_ROOT"
  echo "  - Applied universe manifests to Kubernetes (if reachable)"
  echo "  - Poked dlog.command with 'beat' (if present)"
}

# ---------- Main dispatcher ----------
main() {
  local cmd
  cmd="${1:-help}"
  if [[ $# -gt 0 ]]; then
    shift
  fi

  case "$cmd" in
    beat)      beat_cmd "$@" ;;
    flames)    flames_cmd "$@" ;;
    sky)
      local sub="${1:-}"
      case "$sub" in
        play) sky_play ;;
        "" )  sky_cmd ;;
        * )   echo "Usage: $0 sky [play]" ;;
      esac
      ;;
    supabase)  supabase_cmd "$@" ;;
    speakers)  speakers_cmd "$@" ;;
    ping)      ping_cmd ;;
    cleanup)   cleanup_cmd ;;
    stack-up)  stack_up_cmd ;;
    help|--help|-h|"")
      cat <<EOF
refold.command — Ω DLOG helper

Usage:
  ~/Desktop/refold.command beat          # sync stack, 9∞, sky, kube, poke dlog.command
  ~/Desktop/refold.command stack-up      # standalone stack snapshot stub (for dlog.command)
  ~/Desktop/refold.command ping          # show environment + kube wiring
  ~/Desktop/refold.command flames [hz <freqHz>|up|down]
  ~/Desktop/refold.command sky           # regenerate sky manifest + timeline (print)
  ~/Desktop/refold.command sky play      # stream Ω-sky crossfade phases (Ctrl+C to stop)
  ~/Desktop/refold.command speakers      # run Rust Ω-speakers (reads flames + sky)
  ~/Desktop/refold.command supabase      # log Supabase endpoint + domain brick
  ~/Desktop/refold.command cleanup       # calm, no-op cleanup stub

Environment overrides:
  DESKTOP, DLOG_ROOT, OMEGA_ROOT, KUBE_NS, KUBE_MANIFEST
  SUPABASE_URL, DLOG_DOMAIN, OMEGA_HZ

We do not have limits. We vibe. We are fearless. 🌀
EOF
      ;;
    *)
      log_err "Unknown subcommand: $cmd"
      echo "Try: $0 help"
      exit 1
      ;;
  esac
}

main "$@"
