#!/usr/bin/env bash
# ============================================================
# refold.command — Ω-physics + Cloud Run + domains + shields
# with 8-second self-healing security resets
# ============================================================
# Entry points (run from anywhere, usually in ~/Desktop/dlog):
#
#   ~/Desktop/refold.command ping
#   ~/Desktop/refold.command beat
#   ~/Desktop/refold.command flames [hz 8888]
#   ~/Desktop/refold.command sky play
#
#   ~/Desktop/refold.command deploy
#   ~/Desktop/refold.command domains status
#   ~/Desktop/refold.command domains map
#
#   BACKEND_SERVICE="dlog-gold-backend" ~/Desktop/refold.command shields
#   BACKEND_SERVICE="dlog-gold-backend" ~/Desktop/refold.command shields watch
#
# ============================================================

set -euo pipefail

# ---------- core env -------------------------------------------------

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DLOG_ROOT="${DLOG_ROOT:-$HOME/Desktop/dlog}"
OMEGA_ROOT="${OMEGA_ROOT:-$DLOG_ROOT}"

PROJECT_ID="${PROJECT_ID:-dlog-gold}"
RUN_REGION="${RUN_REGION:-us-central1}"
RUN_PLATFORM="${RUN_PLATFORM:-managed}"

CLOUD_RUN_SERVICE="${CLOUD_RUN_SERVICE:-dlog-gold-app}"

export DLOG_ROOT OMEGA_ROOT PROJECT_ID RUN_REGION RUN_PLATFORM CLOUD_RUN_SERVICE

# Domains in this Ω-universe
DLOG_DOMAINS=("dlog.gold" "goldengold.gold" "nedlog.gold")

# ---------- helpers --------------------------------------------------

_log() {
  local now
  now="$(date '+%Y-%m-%d %H:%M:%S')"
  printf '[%s] %s\n' "$now" "$*"
}

_have() {
  command -v "$1" >/dev/null 2>&1
}

_ensure_gcloud_context() {
  gcloud config set core/project    "$PROJECT_ID" >/dev/null 2>&1 || true
  gcloud config set run/platform    "$RUN_PLATFORM" >/dev/null 2>&1 || true
  gcloud config set run/region      "$RUN_REGION" >/dev/null 2>&1 || true
}

# ---------- Ω: ping / beat / flames / sky ----------------------------

_refold_ping() {
  cat <<EOF
=== refold.command ping ===
Desktop:         $HOME/Desktop
DLOG_ROOT:       $DLOG_ROOT
OMEGA_ROOT:      $OMEGA_ROOT
STACK_ROOT:      $DLOG_ROOT/stack
UNIVERSE_NS:     dlog-universe
KUBE_MANIFEST:   $DLOG_ROOT/kube
Ω-INF-ROOT:      $DLOG_ROOT/∞
PROJECT_ID:      $PROJECT_ID
RUN_REGION:      $RUN_REGION
RUN_PLATFORM:    $RUN_PLATFORM
CLOUD_RUN_SERVICE: $CLOUD_RUN_SERVICE
EOF
}

_refold_beat() {
  local now epoch
  now="$(date '+%Y-%m-%d %H:%M:%S')"
  epoch="$(date +%s)"

  mkdir -p "$DLOG_ROOT/stack" "$DLOG_ROOT/∞" "$DLOG_ROOT/dashboard" "$DLOG_ROOT/sky"

  local stack_file="$DLOG_ROOT/stack/stack;universe"
  printf ';stack;epoch;%s;ok;\n' "$epoch" > "$stack_file"
  _log "[beat] wrote stack snapshot → $stack_file"

  local inf_master="$DLOG_ROOT/∞/;∞;∞;∞;∞;∞;∞;∞;∞;∞;"
  : > "$inf_master"
  _log "[beat] wrote 9∞ master root → $inf_master"

  local dash_file="$DLOG_ROOT/dashboard/dashboard;status"
  cat > "$dash_file" <<EOF
;dashboard;epoch;$epoch;status;ok;
;project;$PROJECT_ID;region;$RUN_REGION;service;$CLOUD_RUN_SERVICE;
EOF
  _log "[beat] wrote Ω-dashboard snapshot → $dash_file"

  if _have kubectl && [ -d "$DLOG_ROOT/kube/universe" ]; then
    _log "[beat] applying universe manifests → $DLOG_ROOT/kube/universe (namespace dlog-universe)"
    kubectl apply -n dlog-universe -f "$DLOG_ROOT/kube/universe" || true
  fi

  if [ -x "$DLOG_ROOT/dlog.command" ]; then
    _log "[beat] delegating to dlog.command → beat"
    "$DLOG_ROOT/dlog.command" beat || true
  fi

  _log "[beat] complete (stack + dashboard + 9∞)."
}

_refold_flames() {
  # Usage:
  #   refold.command flames          → default 8888
  #   refold.command flames 7777     → set directly
  #   refold.command flames hz 8888  → explicit keyword
  local hz="8888"

  if [[ "${1:-}" == "hz" ]]; then
    hz="${2:-8888}"
  elif [[ -n "${1:-}" ]]; then
    hz="$1"
  fi

  mkdir -p "$DLOG_ROOT/flames"
  local control="$DLOG_ROOT/flames/flames;control"

  cat > "$control" <<EOF
hz=$hz
height=7
friction=leidenfrost
EOF

  echo "[refold] wrote flames control → $control"
  echo "Flames control: hz=$hz height=7 friction=leidenfrost"
  echo "(refold.command itself does not start audio — your Ω-engine must read $control)"
}

_refold_sky_play() {
  local stream="$DLOG_ROOT/sky/sky;stream"
  mkdir -p "$(dirname "$stream")"

  _log "[Ω-sky] Streaming state to: $stream"
  echo "omega_hz=7777 episodes=8 curve=cosine loop=true" > "$stream"
  _log "[Ω-sky] episodes=8 ω_hz=7777 curve=cosine loop=true"
  echo "[Ω-sky] crossfade 1→2 ✦ phase 0.000 / 1.000"

  local from=1
  local to=2
  local phase

  while true; do
    phase=0.0
    while (( $(echo "$phase < 1.001" | bc -l) )); do
      printf '[Ω-sky] crossfade %d→%d ✦ phase %.3f / 1.000\n' "$from" "$to" "$phase"
      phase=$(echo "$phase + 0.016" | bc -l)
      sleep 0.016 2>/dev/null || sleep 0.02
    done
    from=$to
    to=$(( (to % 8) + 1 ))
  done
}

# ---------- Cloud Run deploy ----------------------------------------

_refold_deploy() {
  _ensure_gcloud_context

  cat <<EOF
=== 🚀 refold.command deploy (Cloud Run) ===
[deploy] project:  $PROJECT_ID
[deploy] region:   $RUN_REGION
[deploy] service:  $CLOUD_RUN_SERVICE
[deploy] root:     $DLOG_ROOT
EOF

  (
    cd "$DLOG_ROOT"
    gcloud run deploy "$CLOUD_RUN_SERVICE" \
      --source . \
      --region "$RUN_REGION" \
      --platform "$RUN_PLATFORM" \
      --allow-unauthenticated
  )

  echo "[deploy] ✅ Cloud Run deploy complete."
  echo "[deploy] tip: ~/Desktop/refold.command domains status"
}

# ---------- Domains: status / map -----------------------------------

_refold_domains_status() {
  _ensure_gcloud_context
  echo "=== 🌐 DLOG DOMAINS – status (DNS + certs) ==="

  local domain
  for domain in "${DLOG_DOMAINS[@]}"; do
    echo
    echo "── $domain ─────────────────────────────"

    echo "[dns] A:"
    if _have dig; then
      dig +short "$domain" A || true
    else
      echo "  (dig not installed)"
    fi
    echo

    echo "[dns] AAAA:"
    if _have dig; then
      dig +short "$domain" AAAA || true
    else
      echo "  (dig not installed)"
    fi
    echo

    echo "[run] domain-mapping conditions:"
    if gcloud beta run domain-mappings describe --domain "$domain" \
         --region "$RUN_REGION" \
         --format='table(status.conditions[].type,status.conditions[].status,status.conditions[].message)' \
         >/dev/null 2>&1; then
      gcloud beta run domain-mappings describe --domain "$domain" \
        --region "$RUN_REGION" \
        --format='table(status.conditions[].type,status.conditions[].status,status.conditions[].message)'
    else
      echo "  (no domain-mapping found for $domain in $RUN_REGION)"
    fi
  done
}

_refold_domains_map() {
  _ensure_gcloud_context
  echo "=== 🌐 refold.command domains map ==="
  echo

  local domain
  for domain in "${DLOG_DOMAINS[@]}"; do
    echo "── $domain ─────────────────────────────"
    if gcloud beta run domain-mappings describe --domain "$domain" \
         --region "$RUN_REGION" >/dev/null 2>&1; then
      echo "[refold] domain-mapping already exists for $domain"
      echo
      continue
    fi

    echo "[refold] creating domain-mapping for $domain → service $CLOUD_RUN_SERVICE…"
    if gcloud beta run domain-mappings create \
         --service "$CLOUD_RUN_SERVICE" \
         --domain "$domain" \
         --region "$RUN_REGION"; then
      echo "[refold] ✅ created domain-mapping for $domain"
    else
      echo "[refold] ⚠️ could not create domain-mapping for $domain"
      echo "        - this usually means the domain is not yet verified for project $PROJECT_ID"
      echo "        - or another project/account has already claimed it"
    fi
    echo
  done
}

# ---------- Shields: Cloud Armor + ingress lock ---------------------
# 8-second reset loop lives here.

_refold_shields_once() {
  _ensure_gcloud_context

  local backend="${BACKEND_SERVICE:-}"
  if [[ -z "$backend" ]]; then
    cat <<EOF
[armor] ⚠️ BACKEND_SERVICE is not set.

Export your HTTPS LB backend name first, e.g.:

  export BACKEND_SERVICE="dlog-gold-backend"
  ~/Desktop/refold.command shields

You can inspect existing backends with:
  gcloud compute backend-services list --global
EOF
    return 1
  fi

  local policy="dlog-gold-armor"

  # We deliberately do *not* let a single failure kill the loop.
  set +e

  if gcloud compute security-policies describe "$policy" >/dev/null 2>&1; then
    _log "[armor] security policy $policy already exists."
  else
    _log "[armor] creating security policy $policy…"
    gcloud compute security-policies create "$policy" \
      --description="DLOG.gold shield – layer 7 filter (Ω-physics)"
  fi

  # Soft allow-all rule 1000 (to be tuned later)
  if gcloud compute security-policies rules list \
        --security-policy="$policy" \
        --format='value(priority)' | grep -q '^1000$'; then
    _log "[armor] rule 1000 already present (soft allow-all)."
  else
    _log "[armor] creating rule 1000 (soft allow-all)…"
    gcloud compute security-policies rules create 1000 \
      --security-policy="$policy" \
      --expression="true" \
      --action=allow
  fi

  _log "[armor] attaching policy $policy to backend-service $backend…"
  gcloud compute backend-services update "$backend" \
    --security-policy="$policy" \
    --global

  _log "[armor] tightening Cloud Run ingress (internal-and-cloud-load-balancing)…"
  gcloud run services update "$CLOUD_RUN_SERVICE" \
    --ingress internal-and-cloud-load-balancing \
    --region "$RUN_REGION" \
    --platform="$RUN_PLATFORM"

  # Optional: show a tiny status snapshot for vibes
  _log "[armor] snapshot:"
  gcloud compute backend-services describe "$backend" \
    --global \
    --format='value(securityPolicy)' 2>/dev/null | sed 's/^/[armor]   /' || true

  set -e
}

_refold_shields() {
  local mode="${1:-once}"

  case "$mode" in
    once)
      echo "=== 🛡️ refold.command shields (single pass) ==="
      _refold_shields_once
      echo "[armor] shields pass complete."
      ;;
    watch)
      echo "=== 🛡️ refold.command shields watch (8s reset loop) ==="
      echo "[armor] BACKEND_SERVICE=${BACKEND_SERVICE:-<unset>}"
      echo "[armor] CLOUD_RUN_SERVICE=$CLOUD_RUN_SERVICE"
      echo "[armor] project=$PROJECT_ID region=$RUN_REGION"
      echo
      echo "[armor] Every 8 seconds:"
      echo "        - ensure security policy exists"
      echo "        - ensure rule 1000 exists"
      echo "        - reattach policy to backend"
      echo "        - re-lock Cloud Run ingress"
      echo
      echo "(Ctrl+C any time to stop — universe keeps your last config.)"
      echo

      local cycle=0
      while true; do
        cycle=$((cycle + 1))
        _log "[armor] === cycle $cycle (8s reset) ==="
        if ! _refold_shields_once; then
          _log "[armor] cycle $cycle had errors (check logs above)."
        else
          _log "[armor] cycle $cycle ok."
        fi
        sleep 8
      done
      ;;
    *)
      echo "[armor] Unknown shields mode: $mode"
      echo "Usage:"
      echo "  BACKEND_SERVICE=\"dlog-gold-backend\" ~/Desktop/refold.command shields"
      echo "  BACKEND_SERVICE=\"dlog-gold-backend\" ~/Desktop/refold.command shields watch"
      return 1
      ;;
  esac
}

# ---------- dispatcher ----------------------------------------------

_refold_help() {
  cat <<EOF
Usage: refold.command <subcommand> [args...]

Ω-core:
  ping                    Show detected paths + project context
  beat                    Refresh stack/dashboard/9∞ and poke universe
  flames [hz N]           Write flames control (default 8888)
  sky play                Run Ω-sky crossfade log (Ctrl+C to stop)

Cloud:
  deploy                  Build + deploy dlog-gold-app to Cloud Run

Domains:
  domains status          Show DNS A/AAAA + domain-mapping conditions
  domains map             Ensure domain-mappings exist (if verified)

Shields (Cloud Armor + ingress):
  shields                 Single shields pass (no loop)
  shields once            Same as 'shields'
  shields watch           8-second reset loop

All shields commands require BACKEND_SERVICE, e.g.:

  export BACKEND_SERVICE="dlog-gold-backend"
  ~/Desktop/refold.command shields watch
EOF
}

main() {
  local cmd="${1:-help}"
  shift || true

  case "$cmd" in
    ping)         _refold_ping "$@" ;;
    beat)         _refold_beat "$@" ;;
    flames)       _refold_flames "$@" ;;
    sky)
      case "${1:-}" in
        play) shift || true; _refold_sky_play "$@" ;;
        *) _refold_help ;;
      esac
      ;;
    deploy)       _refold_deploy "$@" ;;
    domains)
      case "${1:-}" in
        status) shift || true; _refold_domains_status "$@" ;;
        map)    shift || true; _refold_domains_map "$@" ;;
        *)      _refold_help ;;
      esac
      ;;
    shields)
      # shields [once|watch]
      _refold_shields "${1:-once}"
      ;;
    help|-h|--help|"") _refold_help ;;
    *)
      echo "Unknown subcommand: $cmd"
      echo
      _refold_help
      exit 1
      ;;
  esac
}

main "$@"
