#!/usr/bin/env bash
#
# ===================== Ω refold.command v4 =====================
# DLOG / Ω-physics conductor
# -------------------------------------------------------------
# This is your single switchboard for:
#   - Ω-stack beats, flames, sky logs, speakers
#   - dlog.gold / goldengold.gold / nedlog.gold domains
#   - Cloud Run deploys (dlog-gold-app)
#   - Shields: Cloud Armor policy + optional LB backend hook
#   - Shields watch: 8s “heartbeat” that never panics on errors
#
# Core principles:
#   - No hard limits
#   - Scripts are friendly + replayable
#   - Failure should log, not nuke the whole universe
# =============================================================

# NOTE: deliberately *not* using `set -e` globally anymore.
# We want per-command error handling so watch loops don't bail.

set -u  # undefined vars are still errors

# ------------------ GLOBAL DEFAULTS ---------------------------

DLOG_ROOT="${DLOG_ROOT:-$HOME/Desktop/dlog}"
OMEGA_ROOT="${OMEGA_ROOT:-$DLOG_ROOT}"

PROJECT_ID="${PROJECT_ID:-dlog-gold}"
RUN_REGION="${RUN_REGION:-us-central1}"
RUN_PLATFORM="managed"

CLOUD_RUN_SERVICE="${CLOUD_RUN_SERVICE:-dlog-gold-app}"

# Trio of domains in the Ω-orbit
DOMAINS=(
  "dlog.gold"
  "goldengold.gold"
  "nedlog.gold"
)

# Paths
FLAMES_DIR="$DLOG_ROOT/flames"
SKY_DIR="$DLOG_ROOT/sky"
STACK_DIR="$DLOG_ROOT/stack"
DASHBOARD_DIR="$DLOG_ROOT/dashboard"
KUBE_DIR="$DLOG_ROOT/kube"
OMEGA_INF="$DLOG_ROOT/∞"

# ------------------ UTILITIES ---------------------------

TIMESTAMP() {
  date +"%Y-%m-%d %H:%M:%S"
}

log() {
  # log "msg"
  # log "TAG" "msg"
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
    log "MISS" "Need '$bin' in PATH but it is not installed."
    return 1
  fi
}

# safe-run helper — never kills the script
# sr "TAG" cmd args...
sr() {
  local tag="$1"; shift || true
  if [ "$#" -eq 0 ]; then
    log "$tag" "no command provided to sr()"
    return 1
  fi
  "$@" >/tmp/refold-"$tag".out 2>/tmp/refold-"$tag".err
  local rc=$?
  if [ $rc -ne 0 ]; then
    log "$tag" "command failed (rc=$rc)"
    local err
    err="$(cat /tmp/refold-"$tag".err 2>/dev/null || true)"
    [ -n "$err" ] && log "$tag" "stderr: $err"
  fi
  cat /tmp/refold-"$tag".out 2>/dev/null || true
  return 0
}

# ------------------ PING ---------------------------

cmd_ping() {
  echo "=== refold.command ping ==="
  echo "Desktop:          $HOME/Desktop"
  echo "DLOG_ROOT:        $DLOG_ROOT"
  echo "OMEGA_ROOT:       $OMEGA_ROOT"
  echo "STACK_ROOT:       $STACK_DIR"
  echo "UNIVERSE_NS:      dlog-universe"
  echo "KUBE_MANIFEST:    $KUBE_DIR"
  echo "Ω-INF-ROOT:       $OMEGA_INF"
  echo "PROJECT_ID:       $PROJECT_ID"
  echo "RUN_REGION:       $RUN_REGION"
  echo "RUN_PLATFORM:     $RUN_PLATFORM"
  echo "CLOUD_RUN_SERVICE:$CLOUD_RUN_SERVICE"
  echo "BACKEND_SERVICE:  ${BACKEND_SERVICE:-<unset>}"
}

# ------------------ BEAT / STACK ---------------------------

cmd_beat() {
  echo "=== refold.command beat ==="

  mkdir -p "$STACK_DIR" "$DASHBOARD_DIR" "$SKY_DIR" "$OMEGA_INF"

  local epoch
  epoch="$(date +%s)"

  # stack snapshot
  local stack_file="$STACK_DIR/stack;universe"
  {
    echo ";stack;epoch;$epoch;ok;"
    echo ";phone;label;epoch;epoch8;tag;status;"
  } > "$stack_file"
  log "beat" "wrote stack snapshot → $stack_file"

  # 9∞ master root
  local root_dir="$OMEGA_INF/;∞;∞;∞;∞;∞;∞;∞;∞;∞;"
  mkdir -p "$root_dir"
  echo ";9∞;epoch;$epoch;" > "$root_dir/9∞.txt"
  log "beat" "wrote 9∞ master root → $root_dir"

  # dashboard
  local dash_file="$DASHBOARD_DIR/dashboard;status"
  {
    echo ";dashboard;epoch;$epoch;status;ok;"
  } > "$dash_file"
  log "beat" "wrote Ω-dashboard snapshot → $dash_file"

  # sky manifest & timeline
  local manifest="$SKY_DIR/sky;manifest"
  local timeline="$SKY_DIR/sky;timeline"
  echo ";sky;epoch;$epoch;episodes;8;" > "$manifest"
  echo ";sky;timeline;epoch;$epoch;curve;cosine;" > "$timeline"
  log "beat" "wrote Ω-sky manifest & timeline → $SKY_DIR"

  # kubectl universe apply (soft)
  if [ -d "$KUBE_DIR/universe" ] && command -v kubectl >/dev/null 2>&1; then
    log "beat" "applying universe manifests → $KUBE_DIR/universe (namespace dlog-universe)"
    sr "kubectl-universe" kubectl apply -n dlog-universe -f "$KUBE_DIR/universe"
  else
    log "beat" "no kube/universe or no kubectl; skipping apply"
  fi

  log "beat" "complete (stack + dashboard + 9∞)."
}

# ------------------ FLAMES ---------------------------

cmd_flames() {
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

# ------------------ SKY ---------------------------

cmd_sky() {
  local sub="${1:-play}"
  shift || true

  case "$sub" in
    play) cmd_sky_play "$@";;
    tail) cmd_sky_tail "$@";;
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

  : > "$stream"
  log "Ω-sky" "Streaming state to: $stream"
  log "Ω-sky" "episodes=8 ω_hz=7777 curve=cosine loop=true"

  local from=1
  local to=2
  local step=0
  while [ $step -lt 64 ]; do
    step=$((step + 1))
    # cheap float approx
    local phase
    phase=$(printf "%.3f" "$(awk "BEGIN {print $step/64.0}")")
    printf "[Ω-sky] crossfade %d→%d ✦ phase %s / 1.000\n" "$from" "$to" "$phase"
    echo "crossfade;$from;$to;$phase" >> "$stream"
    sleep 0.02
    if [ "$step" -eq 64 ]; then
      step=0
      from=$(( (from % 8) + 1 ))
      to=$(( (from % 8) + 1 ))
    fi
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

# ------------------ SPEAKERS ---------------------------

cmd_speakers() {
  echo "=== refold.command speakers ==="
  cd "$DLOG_ROOT" || { echo "[speakers] cannot cd to $DLOG_ROOT"; return 1; }

  need cargo || { echo "[speakers] cargo missing"; return 1; }

  export OMEGA_RAIL_HZ="${OMEGA_RAIL_HZ:-8888}"
  export OMEGA_WHOOSH_MIN_HZ="${OMEGA_WHOOSH_MIN_HZ:-333}"
  export OMEGA_WHOOSH_MAX_HZ="${OMEGA_WHOOSH_MAX_HZ:-999}"

  echo "[speakers] RAIL=$OMEGA_RAIL_HZ WHOOSH=$OMEGA_WHOOSH_MIN_HZ–$OMEGA_WHOOSH_MAX_HZ"
  cargo run -p omega_speakers
}

# ------------------ DOMAINS (status + map) -------------------

_domains_describe_raw() {
  local domain="$1"
  gcloud beta run domain-mappings describe \
    --domain "$domain"
}

_domains_print_conditions() {
  local domain="$1"

  if ! _domains_describe_raw "$domain" >"/tmp/refold-domain-$domain.yaml" 2>"/tmp/refold-domain-$domain.err"; then
    local err
    err="$(cat "/tmp/refold-domain-$domain.err" 2>/dev/null || true)"
    echo "  (no domain-mapping found for $domain in $RUN_REGION)"
    [ -n "$err" ] && echo "  error: $err"
    return
  fi

  python3 - "$domain" << 'EOF' 2>/dev/null || cat "/tmp/refold-domain-$domain.yaml"
import sys, yaml
domain = sys.argv[1]
data = yaml.safe_load(sys.stdin.read())
conds = data.get("status", {}).get("conditions", [])
if not conds:
    print("  (no conditions on domain-mapping)")
    raise SystemExit
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

    if gcloud beta run domain-mappings describe --domain "$domain" >/dev/null 2>&1; then
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
      echo "        - domain not verified in this project or claimed elsewhere"
    fi
  done
}

cmd_domains() {
  local sub="${1:-status}"
  shift || true
  case "$sub" in
    status) cmd_domains_status "$@";;
    map)    cmd_domains_map "$@";;
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

  if ! cd "$root"; then
    echo "[deploy] ❌ cannot cd into $root"
    return 1
  fi

  gcloud config set project "$project" >/dev/null
  gcloud config set run/platform "$RUN_PLATFORM" >/dev/null
  gcloud config set run/region "$region" >/dev/null

  echo "[deploy] building container (Dockerfile) + deploying to Cloud Run…"

  if ! gcloud run deploy "$service" \
          --source . \
          --region "$region" \
          --platform "$RUN_PLATFORM" \
          --allow-unauthenticated; then
    local rc=$?
    echo "[deploy] ❌ gcloud run deploy failed (rc=$rc)"
    return "$rc"
  fi

  echo "[deploy] ✅ Cloud Run deploy complete."
  echo "[deploy] tip: $0 domains status"
}

# ------------------ SHIELDS (Cloud Armor) --------------------

# internal helper – do NOT exit on errors
_shields_ensure_policy_and_rule() {
  local policy_name="$1"

  gcloud config set project "$PROJECT_ID" >/dev/null
  gcloud config set compute/region "$RUN_REGION" >/dev/null

  # 1) Policy
  echo "[armor] ensuring security policy $policy_name exists…"
  if ! gcloud compute security-policies describe "$policy_name" --global >/dev/null 2>&1; then
    sr "armor-policy-create" gcloud compute security-policies create "$policy_name" \
      --description="Ω-shield for dlog.gold / goldengold.gold / nedlog.gold" \
      --global
  fi

  # 2) Rule 1000
  echo "[armor] ensuring soft allow-all rule 1000 exists…"
  if gcloud compute security-policies rules describe 1000 \
        --security-policy "$policy_name" \
        --global >/dev/null 2>&1; then
    # Update it (non-fatal if fails)
    sr "armor-rule-update" gcloud compute security-policies rules update 1000 \
      --security-policy "$policy_name" \
      --global \
      --description="soft allow-all (to be hardened later)" \
      --action=allow \
      --src-ip-ranges="*"
  else
    # Create it
    sr "armor-rule-create" gcloud compute security-policies rules create 1000 \
      --security-policy "$policy_name" \
      --global \
      --description="soft allow-all (to be hardened later)" \
      --action=allow \
      --src-ip-ranges="*"
  fi
}

_shields_attach_backend() {
  local policy_name="$1"
  local backend="${BACKEND_SERVICE:-}"

  if [ -z "$backend" ]; then
    echo "[armor] BACKEND_SERVICE not set – skipping backend attachment."
    echo "[armor]   export BACKEND_SERVICE=\"your-backend-name\"   # e.g. dlog-gold-backend"
    return 0
  fi

  echo "[armor] trying to attach $policy_name to backend-service $backend…"

  # Check backend exists first (avoid nasty errors)
  if ! gcloud compute backend-services describe "$backend" --global >/dev/null 2>&1; then
    echo "[armor] backend-service '$backend' does not exist yet (0 items in list is normal if you haven't created an HTTPS LB)."
    echo "[armor] Run this again after your global external HTTPS LB is set up."
    return 0
  fi

  sr "armor-backend-update" gcloud compute backend-services update "$backend" \
    --security-policy "$policy_name" \
    --global
}

_shields_lock_run_ingress() {
  # optional: lock Cloud Run to internal / LB only in future
  # For now, we just print current ingress.
  local service="$CLOUD_RUN_SERVICE"
  local region="$RUN_REGION"

  echo "[run] (preview) ingress status for $service:"
  sr "run-ingress-get" gcloud run services describe "$service" \
    --region "$region" \
    --format="value(spec.template.metadata.annotations.\"run.googleapis.com/ingress\")"
}

cmd_shields_once() {
  local policy_name="dlog-gold-armor"

  _shields_ensure_policy_and_rule "$policy_name"
  _shields_attach_backend "$policy_name"
  _shields_lock_run_ingress
  echo "[armor] shields once() done."
}

cmd_shields_watch() {
  local policy_name="dlog-gold-armor"

  echo "=== 🛡️ refold.command shields watch (8s resets) ==="
  echo "project:   $PROJECT_ID"
  echo "region:    $RUN_REGION"
  echo "service:   $CLOUD_RUN_SERVICE"
  echo "backend:   ${BACKEND_SERVICE:-<unset>}"
  echo "policy:    $policy_name"
  echo
  echo "Every 8 seconds:"
  echo "  - Re-assert Cloud Armor policy + rule 1000"
  echo "  - Try to attach policy to BACKEND_SERVICE (if it exists)"
  echo "  - Print a compact domain/cert snapshot"
  echo
  echo "Ctrl+C any time. The Ω-shields keep humming at 8888 Hz."

  while true; do
    echo
    echo "[$(TIMESTAMP)] --- shields heartbeat ---"

    _shields_ensure_policy_and_rule "$policy_name"
    _shields_attach_backend "$policy_name"

    # Short domains snapshot (no YAML parsing, just statuses)
    gcloud config set project "$PROJECT_ID" >/dev/null
    gcloud config set run/region "$RUN_REGION" >/dev/null
    for domain in "${DOMAINS[@]}"; do
      local ready="?"
      local cert="?"
      local msg=""

      if _domains_describe_raw "$domain" >"/tmp/refold-domain-$domain.yaml" 2>"/tmp/refold-domain-$domain.err"; then
        ready="$(python3 - "$domain" << 'EOF' 2>/dev/null || echo '?'
import sys, yaml
dom = sys.argv[1]
data = yaml.safe_load(sys.stdin.read())
conds = data.get("status", {}).get("conditions", [])
r = [c for c in conds if c.get("type") == "Ready"]
print(r[0].get("status") if r else "?")
EOF
)"
        cert="$(python3 - "$domain" << 'EOF' 2>/dev/null || echo '?'
import sys, yaml
dom = sys.argv[1]
data = yaml.safe_load(sys.stdin.read())
conds = data.get("status", {}).get("conditions", [])
r = [c for c in conds if c.get("type") == "CertificateProvisioned"]
print(r[0].get("status") if r else "?")
EOF
)"
      else
        msg="$(cat "/tmp/refold-domain-$domain.err" 2>/dev/null || true)"
      fi

      echo "[watch] $domain → Ready=$ready Cert=$cert ${msg:+| $msg}"
    done

    sleep 8
  done
}

cmd_shields() {
  local sub="${1:-once}"
  shift || true
  case "$sub" in
    once|apply) cmd_shields_once "$@";;
    watch)       cmd_shields_watch "$@";;
    *)
      echo "Usage: $0 shields {once|watch}"
      return 1
      ;;
  esac
}

# ------------------ HELP / DISPATCH --------------------------

cmd_help() {
  cat << EOF
Usage: $0 <command> [args...]

Core Ω:
  ping                       Show current Ω/dlog environment
  beat                       Update stack, 9∞ root, dashboard, sky manifest
  flames [hz N]              Write flames;control (default 8888 Hz)
  sky play                   Fake Ω-sky crossfade log → sky;stream
  sky tail                   Tail sky;stream
  speakers                   Run omega_speakers via cargo

Domains:
  domains status             Show DNS + Cloud Run domain-mapping status
  domains map                Ensure mappings exist for:
                               dlog.gold, goldengold.gold, nedlog.gold

Cloud:
  deploy                     Build + deploy \$CLOUD_RUN_SERVICE from \$DLOG_ROOT to Cloud Run
  shields once               Ensure Cloud Armor policy + optional backend attach
  shields watch              8s heartbeat to re-assert shields + print domain Ready/Cert

Env vars:
  DLOG_ROOT                  Default: ~/Desktop/dlog
  PROJECT_ID                 Default: dlog-gold
  RUN_REGION                 Default: us-central1
  CLOUD_RUN_SERVICE          Default: dlog-gold-app
  BACKEND_SERVICE            HTTPS LB backend (optional for now)
  OMEGA_RAIL_HZ              Default: 8888
  OMEGA_WHOOSH_MIN_HZ        Default: 333
  OMEGA_WHOOSH_MAX_HZ        Default: 999
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
