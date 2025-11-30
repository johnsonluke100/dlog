#!/usr/bin/env bash
#
# refold.command — Ω-stream orchestration for DLOG
#   ping    → show environment
#   beat    → update stack, 9∞, dashboard, sky, kube
#   flames  → write flame control file (default 8888 Hz)
#   deploy  → build + deploy Rust HTTP gateway to Cloud Run
#   domains → status/map of dlog.gold / goldengold.gold / nedlog.gold
#   rails   → sample anycast IPs into Ω-rails bands
#   shields → Cloud Armor soft shield (once / watch)
#   flow    → ping → beat → flames → deploy → domains → rails
#
# Usage examples:
#   ~/Desktop/refold.command ping
#   ~/Desktop/refold.command beat
#   ~/Desktop/refold.command flames           # 8888 Hz default
#   ~/Desktop/refold.command flames hz 7777   # custom Hz
#   ~/Desktop/refold.command deploy
#   ~/Desktop/refold.command domains status
#   ~/Desktop/refold.command domains map
#   ~/Desktop/refold.command rails
#   BACKEND_SERVICE="dlog-gold-backend" ~/Desktop/refold.command shields once
#   BACKEND_SERVICE="dlog-gold-backend" ~/Desktop/refold.command shields watch
#   ~/Desktop/refold.command flow
#

set -euo pipefail

########################################
# Core environment
########################################

DESKTOP="${HOME}/Desktop"
DLOG_ROOT="${DLOG_ROOT:-${DESKTOP}/dlog}"

STACK_ROOT="${STACK_ROOT:-${DLOG_ROOT}/stack}"
OMEGA_ROOT="${OMEGA_ROOT:-${DLOG_ROOT}}"
KUBE_MANIFEST="${KUBE_MANIFEST:-${DLOG_ROOT}/kube}"
OMEGA_INF_ROOT="${OMEGA_INF_ROOT:-${DLOG_ROOT}/∞}"

PROJECT_ID="${PROJECT_ID:-dlog-gold}"
RUN_REGION="${RUN_REGION:-us-central1}"
RUN_PLATFORM="${RUN_PLATFORM:-managed}"
CLOUD_RUN_SERVICE="${CLOUD_RUN_SERVICE:-dlog-gold-app}"

# Cloud Armor
POLICY_NAME="${POLICY_NAME:-dlog-gold-armor}"
BACKEND_SERVICE_DEFAULT="dlog-gold-backend"
BACKEND_SERVICE="${BACKEND_SERVICE:-}"

# Domains we care about
DOMAINS=("dlog.gold" "goldengold.gold" "nedlog.gold")

########################################
# Helpers
########################################

ts() {
  date +"%Y-%m-%d %H:%M:%S"
}

log() {
  printf '[%s] %s\n' "$(ts)" "$*" >&2
}

soft() {
  # Run command, but don’t kill the whole script on failure.
  # Prints stderr if something goes wrong.
  if ! "$@"; then
    log "[soft] command failed (rc=$?) → $*"
    return 1
  fi
}

require_cmd() {
  local c
  for c in "$@"; do
    if ! command -v "$c" >/dev/null 2>&1; then
      echo "Missing required command: $c" >&2
      exit 1
    fi
  done
}

ensure_dirs() {
  mkdir -p "$STACK_ROOT" \
           "$DLOG_ROOT/dashboard" \
           "$DLOG_ROOT/sky" \
           "$DLOG_ROOT/flames" \
           "$OMEGA_INF_ROOT"
}

########################################
# ping
########################################

sub_ping() {
  ensure_dirs
  cat <<EOF
Desktop:          $DESKTOP
DLOG_ROOT:        $DLOG_ROOT
OMEGA_ROOT:       $OMEGA_ROOT
STACK_ROOT:       $STACK_ROOT
UNIVERSE_NS:      dlog-universe
KUBE_MANIFEST:    $KUBE_MANIFEST
Ω-INF-ROOT:       $OMEGA_INF_ROOT
PROJECT_ID:       $PROJECT_ID
RUN_REGION:       $RUN_REGION
RUN_PLATFORM:     $RUN_PLATFORM
CLOUD_RUN_SERVICE:$CLOUD_RUN_SERVICE
BACKEND_SERVICE:  ${BACKEND_SERVICE:-<unset>}
EOF
}

########################################
# beat — stack + dashboard + 9∞ + kube
########################################

sub_beat() {
  ensure_dirs
  local epoch
  epoch="$(date +%s)"

  # Stack snapshot
  local stack_file="$STACK_ROOT/stack;universe"
  {
    printf ';stack;epoch;%s;ok;\n' "$epoch"
    printf ';phone;label;epoch;epoch8;tag;status;\n'
  } >"$stack_file"
  log "[beat] wrote stack snapshot → $stack_file"

  # 9∞ master root
  local master_root="$OMEGA_INF_ROOT/9∞.txt"
  {
    printf 'epoch=%s\n' "$epoch"
    printf 'root=9∞\n'
    printf 'project=%s\n' "$PROJECT_ID"
    printf 'region=%s\n' "$RUN_REGION"
  } >"$master_root"
  log "[beat] wrote 9∞ master root → $master_root"

  # Dashboard snapshot
  local dash_file="$DLOG_ROOT/dashboard/dashboard;status"
  {
    printf ';dashboard;epoch;%s;\n' "$epoch"
    printf ';project;%s;region;%s;service;%s;\n' \
      "$PROJECT_ID" "$RUN_REGION" "$CLOUD_RUN_SERVICE"
  } >"$dash_file"
  log "[beat] wrote Ω-dashboard snapshot → $dash_file"

  # Sky manifest + timeline (very lightweight)
  local sky_manifest="$DLOG_ROOT/sky/sky;manifest"
  local sky_timeline="$DLOG_ROOT/sky/sky;timeline"
  printf ';sky;epoch;%s;status;ok;\n' "$epoch" >"$sky_manifest"
  printf '%s;beat;ok;\n' "$epoch" >>"$sky_timeline"
  log "[beat] wrote Ω-sky manifest & timeline → $DLOG_ROOT/sky"

  # Apply kube universe manifests (if present)
  if [ -d "$KUBE_MANIFEST/universe" ]; then
    log "[beat] applying universe manifests → $KUBE_MANIFEST/universe (namespace dlog-universe)"
    soft kubectl apply -n dlog-universe -f "$KUBE_MANIFEST/universe"
  else
    log "[beat] kube/universe missing; skipping kubectl apply."
  fi

  log "[beat] complete (stack + dashboard + 9∞)."
}

########################################
# flames — write flame control file
########################################

sub_flames() {
  ensure_dirs
  local hz="8888"
  local height="7"
  local friction="leidenfrost"

  # Allow: refold.command flames hz 7777
  if [ "${1-}" = "hz" ] && [ -n "${2-}" ]; then
    hz="$2"
  fi

  local control="$DLOG_ROOT/flames/flames;control"
  {
    printf 'hz=%s\n' "$hz"
    printf 'height=%s\n' "$height"
    printf 'friction=%s\n' "$friction"
  } >"$control"

  echo "Flames control: hz=$hz height=$height friction=$friction"
  echo "(refold.command itself does not start audio — your Ω-engine must read $control)"
}

########################################
# deploy — Cloud Run build + deploy
########################################

sub_deploy() {
  ensure_dirs
  require_cmd gcloud

  cat <<EOF
=== 🚀 refold.command deploy (Cloud Run) ===
[deploy] project:  $PROJECT_ID
[deploy] region:   $RUN_REGION
[deploy] service:  $CLOUD_RUN_SERVICE
[deploy] root:     $DLOG_ROOT
EOF

  gcloud config set core/project "$PROJECT_ID" >/dev/null
  gcloud config set run/platform "$RUN_PLATFORM" >/dev/null
  gcloud config set run/region "$RUN_REGION" >/dev/null

  log "[deploy] building container (Dockerfile) + deploying to Cloud Run…"
  gcloud run deploy "$CLOUD_RUN_SERVICE" \
    --source "$DLOG_ROOT" \
    --region "$RUN_REGION" \
    --platform "$RUN_PLATFORM" \
    --allow-unauthenticated

  echo "Service URL: $(gcloud run services describe "$CLOUD_RUN_SERVICE" \
      --region "$RUN_REGION" \
      --format='value(status.url)')"

  echo "[deploy] ✅ Cloud Run deploy complete."
  echo "[deploy] tip: $0 domains status"
}

########################################
# domains — status + mapping
########################################

dns_block() {
  local domain="$1"
  echo "── $domain ─────────────────────────────"
  echo "[dns] A:"
  dig +short "$domain" A || true
  echo
  echo "[dns] AAAA:"
  dig +short "$domain" AAAA || true
  echo
}

domains_status_one() {
  local domain="$1"
  dns_block "$domain"

  echo "[run] domain-mapping conditions:"
  if ! gcloud beta run domain-mappings describe --domain "$domain" \
        --region "$RUN_REGION" >/tmp/refold_domain_"$domain".yml 2>/tmp/refold_domain_"$domain".err; then
    if grep -q "NOT_FOUND" /tmp/refold_domain_"$domain".err; then
      echo "  (no domain-mapping found for $domain in $RUN_REGION)"
      echo "  error: $(cat /tmp/refold_domain_"$domain".err)"
    else
      echo "  (error while describing domain-mapping)"
      cat /tmp/refold_domain_"$domain".err
    fi
  else
    # Use gcloud’s format to keep it compact
    gcloud beta run domain-mappings describe --domain "$domain" \
      --region "$RUN_REGION" \
      --format="table(status.conditions[].type,status.conditions[].status,status.conditions[].message)" \
      || true
  fi
  echo
}

sub_domains_status() {
  require_cmd gcloud dig
  echo "=== 🌐 DLOG DOMAINS – status (DNS + certs) ==="
  gcloud config set core/project "$PROJECT_ID" >/dev/null
  gcloud config set run/platform "$RUN_PLATFORM" >/dev/null
  gcloud config set run/region "$RUN_REGION" >/dev/null

  for d in "${DOMAINS[@]}"; do
    domains_status_one "$d"
  done
}

sub_domains_map() {
  require_cmd gcloud
  echo "=== 🌐 refold.command domains map ==="
  gcloud config set core/project "$PROJECT_ID" >/dev/null
  gcloud config set run/platform "$RUN_PLATFORM" >/dev/null
  gcloud config set run/region "$RUN_REGION" >/dev/null

  for d in "${DOMAINS[@]}"; do
    echo
    echo "── $d ─────────────────────────────"
    if [ "$d" = "dlog.gold" ]; then
      echo "[refold] domain-mapping already exists for $d (primary)"
      continue
    fi

    if gcloud beta run domain-mappings describe --domain "$d" \
          --region "$RUN_REGION" >/dev/null 2>&1; then
      echo "[refold] domain-mapping already exists for $d"
      continue
    fi

    echo "[refold] creating domain-mapping for $d → service $CLOUD_RUN_SERVICE…"
    if ! gcloud beta run domain-mappings create \
          --service "$CLOUD_RUN_SERVICE" \
          --domain "$d" \
          --region "$RUN_REGION"; then
      echo "[refold] ⚠️ could not create domain-mapping for $d"
      echo "        - this usually means the domain is not yet verified for project $PROJECT_ID"
      echo "        - or another project has already claimed it"
    fi
  done
}

########################################
# rails — Ω IP bands from anycast
########################################

sub_rails() {
  ensure_dirs
  require_cmd dig

  echo "=== 🌀 refold.command rails (Ω IP bands) ==="

  local epoch rail_hz
  epoch="$(date +%s)"
  rail_hz="8888"

  # pull A/AAAA for dlog.gold (primary)
  local v4_list=()
  local v6_list=()

  while IFS= read -r ip; do
    [ -n "$ip" ] && v4_list+=("$ip")
  done < <(dig +short dlog.gold A || true)

  while IFS= read -r ip; do
    [ -n "$ip" ] && v6_list+=("$ip")
  done < <(dig +short dlog.gold AAAA || true)

  # Compose 8 rails: 4x IPv4 + 4x IPv6 (or <none> when missing)
  local rails=()
  local i
  for i in {0..3}; do
    rails+=("${v4_list[$i]:-<none>}")
  done
  for i in {0..3}; do
    rails+=("${v6_list[$i]:-<none>}")
  done

  printf '[rails] epoch=%s railHz=%s bands=8\n' "$epoch" "$rail_hz"
  for i in "${!rails[@]}"; do
    printf '[rails] band%02d → %s\n' "$i" "${rails[$i]}"
  done

  local rails_file="$STACK_ROOT/rails;omega"
  {
    printf 'epoch=%s railHz=%s bands=8\n' "$epoch" "$rail_hz"
    for i in "${!rails[@]}"; do
      printf 'band%02d=%s\n' "$i" "${rails[$i]}"
    done
  } >>"$rails_file"

  echo "[rails] appended snapshot → $rails_file"
}

########################################
# shields — Cloud Armor soft guard
########################################

ensure_policy() {
  require_cmd gcloud
  gcloud config set core/project "$PROJECT_ID" >/dev/null
  gcloud config set compute/region "$RUN_REGION" >/dev/null

  echo "[armor] ensuring security policy $POLICY_NAME exists…"
  if ! gcloud compute security-policies describe "$POLICY_NAME" >/dev/null 2>&1; then
    gcloud compute security-policies create "$POLICY_NAME" \
      --description="DLOG GOLD soft perimeter (harden later)" || true
  fi

  echo "[armor] ensuring soft allow-all rule 1000 exists…"
  if ! gcloud compute security-policies rules describe 1000 \
        --security-policy="$POLICY_NAME" >/dev/null 2>&1; then
    # NOTE: no --global here; that caused the previous error.
    gcloud compute security-policies rules create 1000 \
      --security-policy="$POLICY_NAME" \
      --priority=1000 \
      --action=allow \
      --description="soft allow-all (Ω default – we can tighten later)" \
      --src-ip-ranges="*" || true
  else
    # Update description in case we tweak later
    gcloud compute security-policies rules update 1000 \
      --security-policy="$POLICY_NAME" \
      --description="soft allow-all (Ω default – we can tighten later)" \
      --src-ip-ranges="*" \
      --action=allow || true
  fi
}

attach_policy_to_backend() {
  local backend="${BACKEND_SERVICE:-$BACKEND_SERVICE_DEFAULT}"

  if [ -z "$backend" ]; then
    echo "[armor] BACKEND_SERVICE not set; skipping backend attachment."
    return 0
  fi

  echo "[armor] attaching policy $POLICY_NAME to backend-service $backend…"
  # backend-services are global; here --global is valid.
  soft gcloud compute backend-services update "$backend" \
    --security-policy="$POLICY_NAME" \
    --global
}

sub_shields_once() {
  echo "=== 🛡️ refold.command shields once ==="
  ensure_policy
  attach_policy_to_backend
}

compact_domain_line() {
  local domain="$1"
  local ready cert
  ready="$(gcloud beta run domain-mappings describe --domain "$domain" \
            --region "$RUN_REGION" \
            --format="value(status.conditions[?type='Ready'].status)" 2>/dev/null || echo '?')"
  cert="$(gcloud beta run domain-mappings describe --domain "$domain" \
            --region "$RUN_REGION" \
            --format="value(status.conditions[?type='CertificateProvisioned'].status)" 2>/dev/null || echo '?')"

  printf '%s: Ready=%s Cert=%s\n' "$domain" "${ready:-?}" "${cert:-?}"
}

sub_shields_watch() {
  local backend="${BACKEND_SERVICE:-$BACKEND_SERVICE_DEFAULT}"

  cat <<EOF
=== 🛡️ refold.command shields watch (8s resets) ===
project:   $PROJECT_ID
region:    $RUN_REGION
service:   $CLOUD_RUN_SERVICE
backend:   ${backend:-<unset>}
policy:    $POLICY_NAME

Every 8 seconds:
  - Re-assert Cloud Armor policy + rule 1000
  - Try to attach policy to BACKEND_SERVICE (if it exists)
  - Refresh Ω-rails from static anycast IPs
  - Print a compact domain/cert snapshot

Ctrl+C any time. The Ω-shields keep humming at 8888 Hz.
EOF

  while true; do
    echo
    log "[shields] --- heartbeat ---"
    ensure_policy
    attach_policy_to_backend
    sub_rails
    echo "[shields] domains:"
    for d in "${DOMAINS[@]}"; do
      compact_domain_line "$d"
    done
    sleep 8
  done
}

########################################
# flow — everything in one pulse
########################################

sub_flow() {
  cat <<EOF
=== 🌊 refold.command flow (ping → beat → flames → deploy → domains → rails) ===
EOF
  sub_ping
  echo
  sub_beat
  echo
  sub_flames
  echo
  sub_deploy
  echo
  sub_domains_status
  echo
  sub_rails
  echo
  echo "[flow] done. You can now run, if desired:"
  echo "  export BACKEND_SERVICE=\"${BACKEND_SERVICE_DEFAULT}\"  # once LB backend exists"
  echo "  $0 shields watch"
}

########################################
# main dispatcher
########################################

cmd="${1-}"

case "$cmd" in
  ping)
    sub_ping
    ;;
  beat)
    sub_beat
    ;;
  flames)
    shift || true
    sub_flames "$@"
    ;;
  deploy)
    sub_deploy
    ;;
  domains)
    sub="${2-status}"
    case "$sub" in
      status|"")
        sub_domains_status
        ;;
      map)
        sub_domains_map
        ;;
      *)
        echo "Unknown domains subcommand: $sub" >&2
        exit 1
        ;;
    esac
    ;;
  rails)
    sub_rails
    ;;
  shields)
    sub="${2-}"
    case "$sub" in
      once)
        sub_shields_once
        ;;
      watch)
        sub_shields_watch
        ;;
      *)
        echo "Usage: $0 shields {once|watch}" >&2
        exit 1
        ;;
    esac
    ;;
  flow)
    sub_flow
    ;;
  ""|help|-h|--help)
    cat <<EOF
Usage: $0 <command> [args...]

Commands:
  ping                Show Ω-environment
  beat                Stack + 9∞ + dashboard + sky + kube
  flames [hz N]       Write flame control (default 8888 Hz)
  deploy              Build + deploy Cloud Run service
  domains status      Show DNS + domain-mapping status
  domains map         Ensure domain-mappings exist (where possible)
  rails               Sample anycast IPs into 8 Ω-rails
  shields once        Ensure Cloud Armor policy + attach to backend
  shields watch       Continuous shields + rails + domain snapshot
  flow                ping → beat → flames → deploy → domains → rails
EOF
    ;;
  *)
    echo "Unknown command: $cmd" >&2
    echo "Try: $0 help" >&2
    exit 1
    ;;
esac
