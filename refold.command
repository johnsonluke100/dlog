#!/usr/bin/env bash
#
# ===================== Ω refold.command =====================
# DLOG / Ω-physics conductor
# -------------------------------------------------------------
# This file is the "one switchboard" for:
#   - Ω-stack beats, sky, flames, speakers
#   - dlog.gold / goldengold.gold / nedlog.gold domains
#   - Cloud Run deploys (dlog-gold-app)
#   - Shields (Cloud Armor hook, placeholder-safe)
#
# Philosophy:
#   - No hard limits
#   - Scripts are friendly, verbose, and reversible
#   - Everything important is idempotent (safe to re-run)
# =============================================================

set -euo pipefail

# ------------------ GLOBAL DEFAULTS ---------------------------

DLOG_ROOT="${DLOG_ROOT:-$HOME/Desktop/dlog}"
OMEGA_ROOT="${OMEGA_ROOT:-$DLOG_ROOT}"

PROJECT_ID="${PROJECT_ID:-dlog-gold}"
RUN_REGION="${RUN_REGION:-us-central1}"
RUN_PLATFORM="managed"

CLOUD_RUN_SERVICE="${CLOUD_RUN_SERVICE:-dlog-gold-app}"

# Trio of domains you own / are wiring
DOMAINS=(
  "dlog.gold"
  "goldengold.gold"
  "nedlog.gold"
)

# Flames + sky files
FLAMES_DIR="$DLOG_ROOT/flames"
SKY_DIR="$DLOG_ROOT/sky"
STACK_DIR="$DLOG_ROOT/stack"
DASHBOARD_DIR="$DLOG_ROOT/dashboard"
KUBE_DIR="$DLOG_ROOT/kube"
OMEGA_INF="$DLOG_ROOT/∞"

# Used by various bits
TIMESTAMP() {
  date +"%Y-%m-%d %H:%M:%S"
}

log() {
  # log "label" "message"
  # or log "message"
  if [ "$#" -eq 1 ]; then
    printf '[%s] %s\n' "$(TIMESTAMP)" "$1"
  else
    local tag="$1"; shift
    printf '[%s] [%s] %s\n' "$(TIMESTAMP)" "$tag" "$*"
  fi
}

need() {
  # require a binary to be installed
  local bin="$1"
  if ! command -v "$bin" >/dev/null 2>&1; then
    log "MISS" "Need '$bin' in PATH but it's not installed."
    return 1
  fi
}

# ------------------ ENV / PING -------------------------------

cmd_ping() {
  echo "=== refold.command ping ==="
  echo "Desktop:      $HOME/Desktop"
  echo "DLOG_ROOT:    $DLOG_ROOT"
  echo "OMEGA_ROOT:   $OMEGA_ROOT"
  echo "STACK_ROOT:   $STACK_DIR"
  echo "UNIVERSE_NS:  dlog-universe"
  echo "KUBE_MANIFEST:$KUBE_DIR"
  echo "Ω-INF-ROOT:   $OMEGA_INF"
  echo "PROJECT_ID:   $PROJECT_ID"
  echo "RUN_REGION:   $RUN_REGION"
  echo "RUN_PLATFORM: $RUN_PLATFORM"
}

# ------------------ BEAT / STACK -----------------------------

cmd_beat() {
  echo "=== refold.command beat ==="

  mkdir -p "$STACK_DIR" "$DASHBOARD_DIR" "$SKY_DIR" "$OMEGA_INF"

  local epoch
  epoch="$(date +%s)"

  # 1) stack snapshot
  local stack_file="$STACK_DIR/stack;universe"
  {
    echo ";stack;epoch;$epoch;ok;"
    echo ";phone;label;epoch;epoch8;tag;status;"
  } > "$stack_file"
  log "beat" "wrote stack snapshot → $stack_file"

  # 2) 9∞ master root
  local root_dir="$OMEGA_INF/;∞;∞;∞;∞;∞;∞;∞;∞;∞;"
  mkdir -p "$root_dir"
  echo ";9∞;epoch;$epoch;" > "$root_dir/9∞.txt"
  log "beat" "wrote 9∞ master root → $root_dir"

  # 3) dashboard snapshot
  local dash_file="$DASHBOARD_DIR/dashboard;status"
  {
    echo ";dashboard;epoch;$epoch;status;ok;"
  } > "$dash_file"
  log "beat" "wrote Ω-dashboard snapshot → $dash_file"

  # 4) sky manifest & timeline
  local manifest="$SKY_DIR/sky;manifest"
  local timeline="$SKY_DIR/sky;timeline"
  echo ";sky;epoch;$epoch;episodes;8;" > "$manifest"
  echo ";sky;timeline;epoch;$epoch;curve;cosine;" > "$timeline"
  log "beat" "wrote Ω-sky manifest & timeline → $SKY_DIR"

  # 5) apply kube manifests if present
  if [ -d "$KUBE_DIR/universe" ] && command -v kubectl >/dev/null 2>&1; then
    log "beat" "Kubernetes provider detected: external (kubectl present)"
    kubectl apply -n dlog-universe -f "$KUBE_DIR/universe" || \
      log "beat" "kubectl apply failed (universe) – continuing"
  else
    log "beat" "no kube universe manifests found or kubectl missing (skip apply)"
  fi

  # 6) poke dlog.command beat (if present)
  if [ -x "$HOME/Desktop/dlog.command" ]; then
    log "beat" "delegating to dlog.command → beat"
    "$HOME/Desktop/dlog.command" beat || \
      log "beat" "dlog.command beat returned non-zero (safe to ignore)"
  fi

  echo "Beat complete."
  echo
  echo "This beat:"
  echo "  - Updated Ω-stack snapshot  → $stack_file"
  echo "  - Updated 9∞ master root    → $root_dir"
  echo "  - Updated Ω-dashboard       → $dash_file"
  echo "  - Updated Ω-sky manifest    → $manifest"
}

# ------------------ FLAMES CONTROL ---------------------------

cmd_flames() {
  # Usage:
  #   refold.command flames
  #   refold.command flames hz 8888
  local hz="8888"

  if [ "${1:-}" = "hz" ] && [ "${2:-}" != "" ]; then
    hz="$2"
    shift 2 || true
  fi

  mkdir -p "$FLAMES_DIR"
  local file="$FLAMES_DIR/flames;control"

  {
    echo "hz=$hz"
    echo "height=7"
    echo "friction=leidenfrost"
  } > "$file"

  echo "[refold] wrote flames control → $file"
  echo "Flames control: hz=$hz height=7 friction=leidenfrost"
  echo "(refold.command itself does not start audio — your Ω-engine must read $file)"
}

# ------------------ SKY LOG PLAYBACK -------------------------

cmd_sky() {
  local sub="${1:-play}"
  shift || true

  case "$sub" in
    play)
      cmd_sky_play "$@"
      ;;
    tail)
      cmd_sky_tail "$@"
      ;;
    *)
      echo "Usage: $0 sky {play|tail}"
      return 1
      ;;
  esac
}

cmd_sky_play() {
  echo "=== refold.command sky play ==="

  mkdir -p "$SKY_DIR"
  local stream="$SKY_DIR/sky;stream"

  # simulate a loggy crossfade engine; this is log-only, no audio
  : > "$stream"
  log "Ω-sky" "Streaming state to: $stream"
  log "Ω-sky" "episodes=8 ω_hz=7777 curve=cosine loop=true"

  # simple loop to print fake crossfades
  local i=1
  local from=1
  local to=2
  while [ $i -le 64 ]; do
    local phase
    phase=$(printf "%.3f" "$(echo "$i / 64" | bc -l 2>/dev/null || echo 0)")
    printf "[Ω-sky] crossfade %d→%d ✦ phase %s / 1.000\n" "$from" "$to" "$phase"
    echo "crossfade;$from;$to;$phase" >> "$stream"
    i=$((i + 1))
    if [ "$i" -gt 64 ]; then
      i=1
      from=$(( (from % 8) + 1 ))
      to=$(( (from % 8) + 1 ))
    fi
    sleep 0.02
  done
}

cmd_sky_tail() {
  echo "=== refold.command sky tail ==="
  local stream="$SKY_DIR/sky;stream"
  if [ ! -f "$stream" ]; then
    echo "[sky] no stream file at $stream"
    return 1
  fi
  tail -f "$stream"
}

# ------------------ SPEAKERS (Ω audio bed) -------------------

cmd_speakers() {
  echo "=== refold.command speakers ==="
  echo "[refold] Ω-speakers: invoking cargo run -p omega_speakers"
  cd "$DLOG_ROOT"
  if ! command -v cargo >/dev/null 2>&1; then
    echo "[speakers] cargo not installed; cannot run omega_speakers"
    return 1
  fi

  # Let environment drive RAIL / WHOOSH if you export them
  export OMEGA_RAIL_HZ="${OMEGA_RAIL_HZ:-8888}"
  export OMEGA_WHOOSH_MIN_HZ="${OMEGA_WHOOSH_MIN_HZ:-333}"
  export OMEGA_WHOOSH_MAX_HZ="${OMEGA_WHOOSH_MAX_HZ:-999}"

  cargo run -p omega_speakers
}

# ------------------ DOMAINS (status + map) -------------------

_domains_describe() {
  local domain="$1"

  gcloud beta run domain-mappings describe \
    --domain "$domain" \
    2>/tmp/refold-domain-"$domain".err || return 1
}

_domains_print_conditions() {
  local domain="$1"

  if ! _domains_describe "$domain" >/tmp/refold-domain-"$domain".yaml; then
    local err
    err="$(cat /tmp/refold-domain-"$domain".err || true)"
    echo "  (no domain-mapping found for $domain in $RUN_REGION)"
    if [ -n "$err" ]; then
      echo "  error: $err"
    fi
    return
  fi

  python3 - << 'EOF' 2>/dev/null || cat /tmp/refold-domain-'"$domain"'.yaml
import sys, yaml, textwrap
data = yaml.safe_load(sys.stdin.read())
conds = data.get("status", {}).get("conditions", [])
if not conds:
    print("  (no conditions on domain-mapping)")
    sys.exit(0)
types   = [c.get("type") for c in conds]
status  = [c.get("status") for c in conds]
message = [c.get("message") for c in conds]
print("TYPE                                                   STATUS                    MESSAGE")
print(f"{types!r:<55}  {status!r:<24}  {message!r}")
EOF
}

cmd_domains_status() {
  echo "=== 🌐 DLOG DOMAINS – status (DNS + certs) ==="
  gcloud config set project "$PROJECT_ID" >/dev/null
  gcloud config set run/platform "$RUN_PLATFORM" >/dev/null
  gcloud config set run/region "$RUN_REGION" >/dev/null

  need dig || true
  need gcloud || true

  for domain in "${DOMAINS[@]}"; do
    echo
    echo "── $domain ─────────────────────────────"

    # DNS A
    echo "[dns] A:"
    if command -v dig >/dev/null 2>&1; then
      dig +short "$domain" || true
    else
      echo "  (dig not installed)"
    fi
    echo

    # DNS AAAA
    echo "[dns] AAAA:"
    if command -v dig >/dev/null 2>&1; then
      dig AAAA +short "$domain" || true
    else
      echo "  (dig not installed)"
    fi
    echo

    # Cloud Run domain-mapping conditions
    echo "[run] domain-mapping conditions:"
    _domains_print_conditions "$domain"
  done
}

cmd_domains_map() {
  echo "=== 🌐 refold.command domains map ==="
  gcloud config set project "$PROJECT_ID" >/dev/null
  gcloud config set run/platform "$RUN_PLATFORM" >/dev/null
  gcloud config set run/region "$RUN_REGION" >/dev/null

  for domain in "${DOMAINS[@]}"; do
    echo
    echo "── $domain ─────────────────────────────"
    # Try describe first; if exists, skip
    if gcloud beta run domain-mappings describe --domain "$domain" \
          >/dev/null 2>&1; then
      echo "[refold] domain-mapping already exists for $domain"
      continue
    fi

    echo "[refold] creating domain-mapping for $domain → service $CLOUD_RUN_SERVICE…"
    if gcloud beta run domain-mappings create \
          --service "$CLOUD_RUN_SERVICE" \
          --domain "$domain" \
          --region "$RUN_REGION"; then
      echo "[refold] ✓ created domain-mapping for $domain"
    else
      echo "[refold] ⚠️ could not create domain-mapping for $domain"
      echo "        - this usually means the domain is not yet verified for project $PROJECT_ID"
      echo "        - or another project has already claimed it"
    fi
  done
}

cmd_domains() {
  local sub="${1:-status}"
  shift || true

  case "$sub" in
    status)
      cmd_domains_status "$@"
      ;;
    map)
      cmd_domains_map "$@"
      ;;
    *)
      echo "Usage: $0 domains {status|map}"
      return 1
      ;;
  esac
}

# ------------------ DEPLOY (Cloud Run) -----------------------

cmd_deploy() {
  echo "=== 🚀 refold.command deploy (Cloud Run) ==="

  local project="$PROJECT_ID"
  local region="$RUN_REGION"
  local service="$CLOUD_RUN_SERVICE"
  local root="$DLOG_ROOT"

  echo "[deploy] project:  $project"
  echo "[deploy] region:   $region"
  echo "[deploy] service:  $service"
  echo "[deploy] root:     $root"

  cd "$root" || {
    echo "[deploy] ❌ cannot cd into $root"
    return 1
  }

  gcloud config set project "$project"
  gcloud config set run/platform "$RUN_PLATFORM"
  gcloud config set run/region "$region"

  echo "[deploy] building container (Dockerfile) and pushing to Cloud Run…"

  if ! gcloud run deploy "$service" \
          --source . \
          --region "$region" \
          --platform "$RUN_PLATFORM" \
          --allow-unauthenticated; then
    local rc=$?
    echo "[deploy] ❌ gcloud run deploy failed (exit $rc)"
    return "$rc"
  fi

  echo "[deploy] ✅ Cloud Run deploy complete."
  echo "[deploy] tip: $0 domains status"
}

# ------------------ SHIELDS (Cloud Armor hook) ---------------

cmd_shields() {
  echo "=== 🛡️ refold.command shields (Cloud Armor + ingress hook) ==="

  gcloud config set project "$PROJECT_ID" >/dev/null
  gcloud config set compute/region "$RUN_REGION" >/dev/null
  gcloud config set run/region "$RUN_REGION" >/dev/null

  local policy_name="dlog-gold-armor"
  local backend="${BACKEND_SERVICE:-}"

  # 1) security policy
  echo "[armor] ensuring security policy $policy_name exists…"
  if ! gcloud compute security-policies describe "$policy_name" \
        --global >/dev/null 2>&1; then
    gcloud compute security-policies create "$policy_name" \
      --description="Ω-shield for dlog.gold / goldengold.gold / nedlog.gold" \
      --global || true
  fi

  # 2) allow-all rule as a soft default
  echo "[armor] ensuring allow-all rule 1000 exists (soft default)…"
  if ! gcloud compute security-policies rules describe 1000 \
        --security-policy "$policy_name" \
        --global >/dev/null 2>&1; then
    gcloud compute security-policies rules create 1000 \
      --security-policy "$policy_name" \
      --global \
      --description="soft allow-all (to be hardened later)" \
      --action=allow \
      --src-ip-ranges="*"
  else
    gcloud compute security-policies rules update 1000 \
      --security-policy "$policy_name" \
      --global \
      --description="soft allow-all (to be hardened later)" \
      --action=allow \
      --src-ip-ranges="*"
  fi

  if [ -z "$backend" ]; then
    echo "[armor] BACKEND_SERVICE not set – not attaching policy."
    echo "[armor]   export BACKEND_SERVICE=\"your-backend-name\"  # e.g. dlog-gold-backend"
    echo "[armor]   then run: $0 shields"
    return 0
  fi

  echo "[armor] attaching $policy_name to backend-service $backend…"
  if ! gcloud compute backend-services update "$backend" \
        --security-policy "$policy_name" \
        --global; then
    echo "[armor] ⚠️ could not attach policy to backend-service '$backend'"
    echo "[armor]   check: gcloud compute backend-services list --global"
    return 1
  fi

  echo "[armor] ✅ shields raised for backend-service $backend"
}

# ------------------ HELP / DISPATCH --------------------------

cmd_help() {
  cat << EOF
Usage: $0 <command> [args...]

Core Ω commands:
  ping                       Show current Ω/dlog environment
  beat                       Update stack, 9∞ root, dashboard, sky manifests
  flames [hz N]              Write flames;control (default 8888 Hz)
  sky play                   Fake Ω-sky crossfade log to sky;stream
  sky tail                   Tail the sky;stream file
  speakers                   Run omega_speakers via cargo

Domains:
  domains status             Show DNS + Cloud Run domain-mapping status
  domains map                Ensure domain-mappings exist for:
                             dlog.gold, goldengold.gold, nedlog.gold

Cloud:
  deploy                     Deploy \$CLOUD_RUN_SERVICE from \$DLOG_ROOT to Cloud Run
  shields                    Ensure Cloud Armor policy + (optionally) attach to backend

Environment variables you can set:
  DLOG_ROOT                  Root of dlog workspace (default: ~/Desktop/dlog)
  PROJECT_ID                 GCP project id (default: dlog-gold)
  RUN_REGION                 Cloud Run region (default: us-central1)
  CLOUD_RUN_SERVICE          Cloud Run service name (default: dlog-gold-app)
  BACKEND_SERVICE            HTTPS LB backend-service for shields command
  OMEGA_RAIL_HZ              Timing rail frequency for speakers (default: 8888)
  OMEGA_WHOOSH_MIN_HZ        Min whoosh frequency (default: 333)
  OMEGA_WHOOSH_MAX_HZ        Max whoosh frequency (default: 999)
EOF
}

main() {
  local cmd="${1:-help}"
  if [ "$#" -gt 0 ]; then shift || true; fi

  case "$cmd" in
    ping)       cmd_ping "$@" ;;
    beat)       cmd_beat "$@" ;;
    flames)     cmd_flames "$@" ;;
    sky)        cmd_sky "$@" ;;
    speakers)   cmd_speakers "$@" ;;

    domains)    cmd_domains "$@" ;;
    deploy)     cmd_deploy "$@" ;;
    shields)    cmd_shields "$@" ;;

    help|-h|--help)
                cmd_help ;;
    *)
      echo "Unknown command: $cmd"
      echo
      cmd_help
      return 1
      ;;
  esac
}

main "$@"
