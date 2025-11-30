#!/usr/bin/env bash
#
# ===================== Ω refold.command =====================
# DLOG / Ω-physics conductor – dlog.gold ∞ rails
# -------------------------------------------------------------
# This is your one-switchboard for:
#   - Ω-stack beats, flames, sky, speakers
#   - dlog.gold / goldengold.gold / nedlog.gold domains
#   - Cloud Run deploys (dlog-gold-app)
#   - Shields (Cloud Armor) – once + watch loops
#   - Ω-rails: 8 static IPs as 8 band rails
#   - flow: one-button streaming pulse
#
# No half measures. No limits.
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

# Files / dirs
FLAMES_DIR="$DLOG_ROOT/flames"
SKY_DIR="$DLOG_ROOT/sky"
STACK_DIR="$DLOG_ROOT/stack"
DASHBOARD_DIR="$DLOG_ROOT/dashboard"
KUBE_DIR="$DLOG_ROOT/kube"
OMEGA_INF="$DLOG_ROOT/∞"

# ------------------ UTILITIES --------------------------------

TIMESTAMP() {
  date +"%Y-%m-%d %H:%M:%S"
}

log() {
  # log "msg"   OR   log "TAG" "msg"
  if [ "$#" -eq 1 ]; then
    printf '[%s] %s\n' "$(TIMESTAMP)" "$1"
  else
    local tag="$1"; shift
    printf '[%s] [%s] %s\n' "$(TIMESTAMP)" "$tag" "$*"
  fi
}

need() {
  local bin="$1"
  if ! command -v "$bin" >/dev/null 2>&1; then
    log "MISS" "Need '$bin' in PATH but it's not installed."
    return 1
  fi
}

# ------------------ PING --------------------------------------

cmd_ping() {
  echo "=== refold.command ping ==="
  printf 'Desktop:          %s\n'  "$HOME/Desktop"
  printf 'DLOG_ROOT:        %s\n'  "$DLOG_ROOT"
  printf 'OMEGA_ROOT:       %s\n'  "$OMEGA_ROOT"
  printf 'STACK_ROOT:       %s\n'  "$STACK_DIR"
  printf 'UNIVERSE_NS:      %s\n'  "dlog-universe"
  printf 'KUBE_MANIFEST:    %s\n'  "$KUBE_DIR"
  printf 'Ω-INF-ROOT:       %s\n'  "$OMEGA_INF"
  printf 'PROJECT_ID:       %s\n'  "$PROJECT_ID"
  printf 'RUN_REGION:       %s\n'  "$RUN_REGION"
  printf 'RUN_PLATFORM:     %s\n'  "$RUN_PLATFORM"
  printf 'CLOUD_RUN_SERVICE:%s\n'  "$CLOUD_RUN_SERVICE"
  printf 'BACKEND_SERVICE:  %s\n'  "${BACKEND_SERVICE:-<unset>}"
}

# ------------------ BEAT / STACK ------------------------------

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

  # 2) 9∞ master root – single file
  local root_file="$OMEGA_INF/9∞.txt"
  {
    echo ";9∞;epoch;$epoch;"
    echo ";omega;root;ok;"
  } > "$root_file"
  log "beat" "wrote 9∞ master root → $root_file"

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
    log "beat" "applying universe manifests → $KUBE_DIR/universe (namespace dlog-universe)"
    kubectl apply -n dlog-universe -f "$KUBE_DIR/universe" || \
      log "beat" "kubectl apply failed (universe) – continuing"
  else
    log "beat" "no kube universe manifests found or kubectl missing (skip apply)"
  fi

  log "beat" "complete (stack + dashboard + 9∞)."
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
    play) cmd_sky_play "$@" ;;
    tail) cmd_sky_tail "$@" ;;
    *)    echo "Usage: $0 sky {play|tail}"; return 1 ;;
  esac
}

cmd_sky_play() {
  echo "=== refold.command sky play ==="

  mkdir -p "$SKY_DIR"
  local stream="$SKY_DIR/sky;stream"

  : > "$stream"
  log "Ω-sky" "Streaming state to: $stream"
  log "Ω-sky" "episodes=8 ω_hz=7777 curve=cosine loop=true"

  local i=1
  local from=1
  local to=2
  while [ $i -le 256 ]; do
    local phase
    phase=$(printf "%.3f" "$(echo "$i / 256" | bc -l 2>/dev/null || echo 0)")
    printf "[Ω-sky] crossfade %d→%d ✦ phase %s / 1.000\n" "$from" "$to" "$phase"
    echo "crossfade;$from;$to;$phase" >> "$stream"
    i=$((i + 1))
    if [ "$i" -gt 256 ]; then
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

  export OMEGA_RAIL_HZ="${OMEGA_RAIL_HZ:-8888}"
  export OMEGA_WHOOSH_MIN_HZ="${OMEGA_WHOOSH_MIN_HZ:-333}"
  export OMEGA_WHOOSH_MAX_HZ="${OMEGA_WHOOSH_MAX_HZ:-999}"

  cargo run -p omega_speakers
}

# ------------------ DOMAINS (status + map) -------------------

cmd_domains_status() {
  echo "=== 🌐 DLOG DOMAINS – status (DNS + certs) ==="
  gcloud config set project "$PROJECT_ID" >/dev/null
  gcloud config set run/platform "$RUN_PLATFORM" >/dev/null
  gcloud config set run/region "$RUN_REGION" >/dev/null

  for domain in "${DOMAINS[@]}"; do
    echo
    echo "── $domain ─────────────────────────────"

    echo "[dns] A:"
    if command -v dig >/dev/null 2>&1; then
      dig +short "$domain" || true
    else
      echo "  (dig not installed)"
    fi
    echo

    echo "[dns] AAAA:"
    if command -v dig >/dev/null 2>&1; then
      dig AAAA +short "$domain" || true
    else
      echo "  (dig not installed)"
    fi
    echo

    echo "[run] domain-mapping conditions (raw):"
    if ! gcloud beta run domain-mappings describe \
          --domain "$domain"; then
      echo "  (no domain-mapping found for $domain in $RUN_REGION)"
    fi
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
      echo "        - either it is not verified for $PROJECT_ID"
      echo "        - or another project owns the mapping"
    fi
  done
}

cmd_domains() {
  local sub="${1:-status}"
  shift || true
  case "$sub" in
    status) cmd_domains_status "$@" ;;
    map)    cmd_domains_map   "$@" ;;
    *)      echo "Usage: $0 domains {status|map}"; return 1 ;;
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

  cd "$root" || { echo "[deploy] ❌ cannot cd into $root"; return 1; }

  gcloud config set project "$project"
  gcloud config set run/platform "$RUN_PLATFORM"
  gcloud config set run/region "$region"

  echo "[deploy] building container (Dockerfile) + deploying to Cloud Run…"

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

# ------------------ Ω RAILS (8 static IP bands) --------------

_rails_collect_ips() {
  # Focus rails on dlog.gold (shared anycast IPs)
  local domain="dlog.gold"

  local v4_list=()
  local v6_list=()

  if command -v dig >/dev/null 2>&1; then
    while IFS= read -r line; do
      [ -n "${line:-}" ] && v4_list+=("$line")
    done < <(dig +short "$domain" 2>/dev/null || true)

    while IFS= read -r line; do
      [ -n "${line:-}" ] && v6_list+=("$line")
    done < <(dig AAAA +short "$domain" 2>/dev/null || true)
  fi

  # Print as: v4|ip and v6|ip for caller to parse
  local ip
  for ip in "${v4_list[@]:-}"; do
    [ -n "${ip:-}" ] && echo "v4|$ip"
  done
  for ip in "${v6_list[@]:-}"; do
    [ -n "${ip:-}" ] && echo "v6|$ip"
  done
}

cmd_rails() {
  echo "=== 🌀 refold.command rails (Ω IP bands) ==="
  mkdir -p "$STACK_DIR"

  local epoch
  epoch="$(date +%s)"
  local rails_file="$STACK_DIR/rails;omega"

  local v4=()
  local v6=()
  local kind ip

  while IFS='|' read -r kind ip; do
    [ -z "${ip:-}" ] && continue
    if [ "$kind" = "v4" ]; then
      v4+=("$ip")
    elif [ "$kind" = "v6" ]; then
      v6+=("$ip")
    fi
  done < <(_rails_collect_ips)

  # We want exactly 8 rails: 0-3 v4, 4-7 v6
  local rails=()
  local i
  for ((i=0;i<4;i++)); do
    rails+=("${v4[$i]:-<none>}")
  done
  for ((i=0;i<4;i++)); do
    rails+=("${v6[$i]:-<none>}")
  done

  echo "[rails] epoch=$epoch railHz=${OMEGA_RAIL_HZ:-8888} bands=8"
  for i in "${!rails[@]}"; do
    printf "[rails] band%02d → %s\n" "$i" "${rails[$i]}"
  done

  {
    printf "epoch=%s rail_hz=%s bands=8\n" "$epoch" "${OMEGA_RAIL_HZ:-8888}"
    for i in "${!rails[@]}"; do
      printf "band=%02d ip=%s\n" "$i" "${rails[$i]}"
    done
  } >> "$rails_file"
  echo "[rails] appended snapshot → $rails_file"
}

# ------------------ SHIELDS (Cloud Armor) --------------------

_shields_core() {
  local backend="${BACKEND_SERVICE:-}"
  local policy_name="dlog-gold-armor"

  gcloud config set project "$PROJECT_ID"         >/dev/null
  gcloud config set compute/region "$RUN_REGION"  >/dev/null || true

  echo "[armor] ensuring security policy $policy_name exists…"
  if ! gcloud compute security-policies describe "$policy_name" \
        --global >/dev/null 2>&1; then
    gcloud compute security-policies create "$policy_name" \
      --description="Ω-shield for dlog.gold / goldengold.gold / nedlog.gold" \
      --global || true
  fi

  echo "[armor] ensuring soft allow-all rule 1000 exists…"
  if ! gcloud compute security-policies rules describe 1000 \
        --security-policy "$policy_name" >/dev/null 2>&1; then
    if ! gcloud compute security-policies rules create 1000 \
            --security-policy "$policy_name" \
            --description="soft allow-all (to be hardened later)" \
            --action=allow \
            --src-ip-ranges="*"; then
      log "armor-rule-create" "command failed (rc=$?)"
    fi
  else
    if ! gcloud compute security-policies rules update 1000 \
            --security-policy "$policy_name" \
            --description="soft allow-all (to be hardened later)" \
            --action=allow \
            --src-ip-ranges="*"; then
      log "armor-rule-update" "command failed (rc=$?)"
    fi
  fi

  if [ -z "$backend" ]; then
    echo "[armor] BACKEND_SERVICE not set – not attaching policy."
    echo "[armor]   export BACKEND_SERVICE=\"your-backend-name\"  # e.g. dlog-gold-backend"
    return 0
  fi

  echo "[armor] attaching $policy_name → backend-service $backend…"
  if ! gcloud compute backend-services update "$backend" \
        --security-policy "$policy_name" \
        --global; then
    log "armor-attach" "could not attach policy to backend-service '$backend'"
    log "armor-attach" "check: gcloud compute backend-services list --global"
  else
    echo "[armor] ✅ shields raised for backend-service $backend"
  fi
}

_shields_print_snapshot() {
  echo
  echo "[shields] Ω snapshot @ $(TIMESTAMP)"
  local domain

  for domain in "dlog.gold" "goldengold.gold" "nedlog.gold"; do
    printf "  %s: " "$domain"
    if gcloud beta run domain-mappings describe --domain "$domain" \
          >/tmp/refold-domain-"$domain".yaml 2>/dev/null; then
      local ready cert
      ready="$(grep -A1 'type: Ready' /tmp/refold-domain-"$domain".yaml 2>/dev/null | awk '/status:/ {print $2}' | tr -d '"')"
      cert="$(grep -A1 'type: CertificateProvisioned' /tmp/refold-domain-"$domain".yaml 2>/dev/null | awk '/status:/ {print $2}' | tr -d '"')"
      printf "Ready=%s Cert=%s\n" "${ready:-?}" "${cert:-?}"
    else
      printf "no-mapping\n"
    fi
  done
}

cmd_shields_once() {
  echo "=== 🛡️ refold.command shields once ==="
  _shields_core
  cmd_rails   # paint IP rails once when you raise shields
}

cmd_shields_watch() {
  echo "=== 🛡️ refold.command shields watch (8s resets) ==="
  local backend="${BACKEND_SERVICE:-<unset>}"
  local policy="dlog-gold-armor"

  echo "project:   $PROJECT_ID"
  echo "region:    $RUN_REGION"
  echo "service:   $CLOUD_RUN_SERVICE"
  echo "backend:   $backend"
  echo "policy:    $policy"
  echo
  echo "Every 8 seconds:"
  echo "  - Re-assert Cloud Armor policy + rule 1000"
  echo "  - Try to attach policy to BACKEND_SERVICE (if it exists)"
  echo "  - Refresh Ω-rails from static anycast IPs"
  echo "  - Print a compact domain/cert snapshot"
  echo
  echo "Ctrl+C any time. The Ω-shields keep humming at 8888 Hz."

  while true; do
    echo
    log "shields" "--- heartbeat ---"
    _shields_core
    cmd_rails
    _shields_print_snapshot
    sleep 8
  done
}

cmd_shields() {
  local sub="${1:-once}"
  shift || true
  case "$sub" in
    once)  cmd_shields_once "$@" ;;
    watch) cmd_shields_watch "$@" ;;
    *)
      echo "Usage: $0 shields {once|watch}"
      return 1
      ;;
  esac
}

# ------------------ FLOW (one-button stream) -----------------

cmd_flow() {
  echo "=== 🌊 refold.command flow (ping → beat → flames → deploy → domains → rails) ==="

  cmd_ping
  echo
  cmd_beat
  echo
  cmd_flames hz 8888
  echo
  cmd_deploy
  echo
  cmd_domains_status
  echo
  cmd_rails

  echo
  echo "[flow] done. You can now run:"
  echo "  export BACKEND_SERVICE=\"dlog-gold-backend\"  # once LB backend exists"
  echo "  $0 shields watch"
}

# ------------------ HELP / DISPATCH --------------------------

cmd_help() {
  cat << EOF
Usage: $0 <command> [args...]

Core Ω commands:
  ping                       Show current Ω / dlog environment
  beat                       Update stack, 9∞ root, dashboard, sky manifests
  flames [hz N]              Write flames;control (default 8888 Hz)
  sky play                   Fake Ω-sky crossfade log to sky;stream
  sky tail                   Tail the sky;stream file
  speakers                   Run omega_speakers via cargo

Domains:
  domains status             Show DNS + Cloud Run domain-mapping status (raw)
  domains map                Ensure domain-mappings exist for:
                             dlog.gold, goldengold.gold, nedlog.gold

Cloud / Deploy:
  deploy                     Deploy \$CLOUD_RUN_SERVICE from \$DLOG_ROOT to Cloud Run

Shields / Rails:
  rails                      Snapshot Ω IP rails from dlog.gold (8 bands)
  shields once               Ensure Cloud Armor policy + rule, attach backend
  shields watch              8s heartbeat: policy, backend, rails, domain snapshot

Flow:
  flow                       ping → beat → flames 8888 → deploy → domains → rails

Environment knobs:
  DLOG_ROOT                  Root of dlog workspace (default: ~/Desktop/dlog)
  PROJECT_ID                 GCP project id (default: dlog-gold)
  RUN_REGION                 Cloud Run region (default: us-central1)
  CLOUD_RUN_SERVICE          Cloud Run service name (default: dlog-gold-app)
  BACKEND_SERVICE            HTTPS LB backend-service (for shields attach)
  OMEGA_RAIL_HZ              Timing rail frequency (default: 8888)
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
    rails)      cmd_rails "$@" ;;
    shields)    cmd_shields "$@" ;;
    flow)       cmd_flow "$@" ;;

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
