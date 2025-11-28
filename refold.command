#!/usr/bin/env bash
#
# refold.command
#
# DLOG / Ω-Physics / Kubernetes orchestrator
# -------------------------------------------------------------
# This script is the “refolder”:
# - It NEVER calls start.command (old Python launcher).
# - It only recognizes dlog.command as the canonical launcher.
# - It knows how to talk about:
#     * ping         → quick health check of the dev universe
#     * api          → local API + URLs overview
#     * kube         → Kubernetes helpers (kind / minikube / external)
#     * universe     → per-phone/per-label universe stubs
#     * status       → pretty-print universe snapshots
#     * beat/orbit   → safe stubs (no more parse errors)
#
# You can extend this file indefinitely. Just keep appending bricks.
# -------------------------------------------------------------

set -euo pipefail

# --- BASIC CONSTANTS ---------------------------------------------------------

SCRIPT_NAME="$(basename "${0}")"

# Desktop assumptions for this Mac:
DESKTOP="${HOME}/Desktop"
DLOG_ROOT_DEFAULT="${DESKTOP}/dlog"
DLOG_COMMAND_DEFAULT="${DESKTOP}/dlog.command"

# Allow overrides via env if you want:
DLOG_ROOT="${DLOG_ROOT:-${DLOG_ROOT_DEFAULT}}"
DLOG_COMMAND="${DLOG_COMMAND:-${DLOG_COMMAND_DEFAULT}}"

# Local universe storage (pure text, no DB, just files)
UNIVERSE_ROOT="${UNIVERSE_ROOT:-${DLOG_ROOT}/universe}"

# Kubernetes defaults
KUBE_NAMESPACE_DEFAULT="dlog-universe"
KUBE_NAMESPACE="${KUBE_NAMESPACE:-${KUBE_NAMESPACE_DEFAULT}}"
KUBE_MANIFEST_ROOT="${KUBE_MANIFEST_ROOT:-${DLOG_ROOT}/kube}"

# Canonical doc + repos (just for echoing, no magic here)
DLOG_DOC_URL_DEFAULT="https://docs.google.com/document/d/e/2PACX-1vShJ-OHsxJjf13YISSM7532zs0mHbrsvkSK73nHnK18rZmpysHC6B1RIMvGTALy0RIo1R1HRAyewCwR/pub"
DLOG_REPO_DEFAULT="https://github.com/johnsonluke100/dlog"
OMEGA_CONTAINER_REPO_DEFAULT="https://github.com/johnsonluke100/minecraft/tree/main/omega_numpy_container"

DLOG_DOC_URL="${DLOG_DOC_URL:-${DLOG_DOC_URL_DEFAULT}}"
DLOG_REPO="${DLOG_REPO:-${DLOG_REPO_DEFAULT}}"
OMEGA_CONTAINER_REPO="${OMEGA_CONTAINER_REPO:-${OMEGA_CONTAINER_REPO_DEFAULT}}"

# --- LOGGING HELPERS --------------------------------------------------------

log_info() {
  printf '[refold] %s\n' "$*" >&2
}

log_warn() {
  printf '[refold:warn] %s\n' "$*" >&2
}

log_error() {
  printf '[refold:ERROR] %s\n' "$*" >&2
}

die() {
  log_error "$*"
  exit 1
}

banner() {
  printf '\n'
  printf '=== %s ===\n' "$*"
  printf '\n'
}

# --- ENV / PATH HELPERS -----------------------------------------------------

ensure_dir() {
  local dir="$1"
  if [ ! -d "${dir}" ]; then
    log_info "creating directory: ${dir}"
    mkdir -p "${dir}"
  fi
}

require_cmd() {
  local cmd="$1"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    die "missing required command: ${cmd}"
  fi
}

optional_cmd() {
  local cmd="$1"
  if command -v "${cmd}" >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

# --- DLOG LAUNCHER AWARENESS -----------------------------------------------

ensure_dlog_command() {
  if [ ! -x "${DLOG_COMMAND}" ]; then
    log_warn "dlog.command not found or not executable at: ${DLOG_COMMAND}"
    log_warn "Make sure the NEW launcher exists and is executable:"
    log_warn "  - No more start.command (old Python launcher)."
    log_warn "  - Use dlog.command from the Desktop as the root."
    return 1
  fi
  return 0
}

call_dlog() {
  # thin wrapper – never call start.command here
  ensure_dlog_command || return 1
  log_info "delegating to dlog.command → $*"
  "${DLOG_COMMAND}" "$@"
}

# --- UNIVERSE FILE MAPPING --------------------------------------------------
# We keep per-universe snapshots as flat semicolon streams.
# No dots in filenames, just like your ∞ filesystem style.

universe_file_path() {
  local phone="$1"
  local label="$2"
  ensure_dir "${UNIVERSE_ROOT}/${phone}"
  # We deliberately avoid dots; use ; and plain text.
  printf '%s\n' "${UNIVERSE_ROOT}/${phone}/${label};universe"
}

# Very simple stub universe line, just so the bricks exist.
# You can mutate the format later to match full Ω segments (O1..O8).
default_universe_payload() {
  local phone="$1"
  local label="$2"
  local now_epoch
  now_epoch="$(date +%s)"
  # ;phone;label;epoch;vortex_or_comet;status;
  printf ';%s;%s;%s;seed;ok;\n' "${phone}" "${label}" "${now_epoch}"
}

write_universe_if_missing() {
  local phone="$1"
  local label="$2"
  local file
  file="$(universe_file_path "${phone}" "${label}")"
  if [ ! -f "${file}" ]; then
    log_info "initializing universe snapshot: phone=${phone} label=${label}"
    default_universe_payload "${phone}" "${label}" > "${file}"
  else
    log_info "universe snapshot already exists → ${file}"
  fi
  printf '%s\n' "${file}"
}

read_universe_or_die() {
  local phone="$1"
  local label="$2"
  local file
  file="$(universe_file_path "${phone}" "${label}")"
  if [ ! -f "${file}" ]; then
    die "universe file missing for phone=${phone} label=${label} at ${file}"
  fi
  cat "${file}"
}

# --- KUBERNETES HELPERS -----------------------------------------------------

detect_kube_provider() {
  # Echo one of: kind, minikube, external, none
  if optional_cmd kind; then
    printf 'kind\n'
    return 0
  fi

  if optional_cmd minikube; then
    printf 'minikube\n'
    return 0
  fi

  if optional_cmd kubectl; then
    # No local cluster helpers, but kubectl exists → external cluster
    printf 'external\n'
    return 0
  fi

  printf 'none\n'
  return 0
}

ensure_kubectl() {
  if ! command -v kubectl >/dev/null 2>&1; then
    die "kubectl not found. Install kubectl before using kube commands."
  fi
}

kube_create_namespace_if_missing() {
  ensure_kubectl
  if kubectl get namespace "${KUBE_NAMESPACE}" >/dev/null 2>&1; then
    log_info "Kubernetes namespace already exists: ${KUBE_NAMESPACE}"
  else
    log_info "creating Kubernetes namespace: ${KUBE_NAMESPACE}"
    kubectl create namespace "${KUBE_NAMESPACE}"
  fi
}

kube_init_kind() {
  require_cmd kind
  local cluster_name="dlog-universe"
  if kind get clusters | grep -q "^${cluster_name}$"; then
    log_info "kind cluster already exists: ${cluster_name}"
  else
    banner "Kubernetes: creating kind cluster (${cluster_name})"
    kind create cluster --name "${cluster_name}"
  fi
}

kube_init_minikube() {
  require_cmd minikube
  local profile="dlog-universe"
  banner "Kubernetes: starting minikube profile (${profile})"
  minikube start -p "${profile}"
}

kube_init_external() {
  banner "Kubernetes: external cluster"
  log_info "Assuming kubeconfig already points at the desired cluster."
}

kube_init() {
  local provider
  provider="$(detect_kube_provider)"

  case "${provider}" in
    kind)
      kube_init_kind
      ;;
    minikube)
      kube_init_minikube
      ;;
    external)
      kube_init_external
      ;;
    none)
      die "no Kubernetes tooling detected (kind/minikube/kubectl)."
      ;;
  esac

  kube_create_namespace_if_missing
  ensure_dir "${KUBE_MANIFEST_ROOT}"
  log_info "Kubernetes manifests directory: ${KUBE_MANIFEST_ROOT}"
  log_info "You can drop .yaml files in there and run: ${SCRIPT_NAME} kube apply"
}

kube_apply_manifests() {
  ensure_kubectl
  if [ ! -d "${KUBE_MANIFEST_ROOT}" ]; then
    die "Kubernetes manifest directory missing: ${KUBE_MANIFEST_ROOT}"
  fi

  if ! ls "${KUBE_MANIFEST_ROOT}"/*.yaml >/dev/null 2>&1; then
    log_warn "No .yaml files found under ${KUBE_MANIFEST_ROOT}"
    log_warn "Create manifests first, then re-run: ${SCRIPT_NAME} kube apply"
    return 0
  fi

  banner "Kubernetes: applying manifests"
  kubectl apply -n "${KUBE_NAMESPACE}" -f "${KUBE_MANIFEST_ROOT}"
}

kube_status() {
  ensure_kubectl
  banner "Kubernetes: status (namespace=${KUBE_NAMESPACE})"
  kubectl get pods -n "${KUBE_NAMESPACE}" || true
  echo
  kubectl get svc -n "${KUBE_NAMESPACE}" || true
  echo
  kubectl get deployments -n "${KUBE_NAMESPACE}" || true
}

kube_logs() {
  ensure_kubectl
  local pod_selector="${1:-}"
  if [ -z "${pod_selector}" ]; then
    die "kube logs requires a pod name or label selector, e.g. 'api' or 'app=dlog-api'"
  fi
  banner "Kubernetes: logs for selector=${pod_selector}"
  kubectl logs -n "${KUBE_NAMESPACE}" -l "${pod_selector}" --tail=200 || true
}

kube_port_forward() {
  ensure_kubectl
  local svc="${1:-}"
  local local_port="${2:-8080}"
  local remote_port="${3:-80}"

  if [ -z "${svc}" ]; then
    die "usage: ${SCRIPT_NAME} kube port-forward <service-name> [localPort] [remotePort]"
  fi

  banner "Kubernetes: port-forward → localhost:${local_port} → svc/${svc}:${remote_port}"
  kubectl port-forward -n "${KUBE_NAMESPACE}" "svc/${svc}" "${local_port}:${remote_port}"
}

cmd_kube() {
  local subcommand="${1:-help}"
  shift || true

  case "${subcommand}" in
    init)
      kube_init
      ;;
    apply)
      kube_apply_manifests
      ;;
    status)
      kube_status
      ;;
    logs)
      kube_logs "$@"
      ;;
    port-forward|pf)
      kube_port_forward "$@"
      ;;
    provider)
      banner "Kubernetes: provider detection"
      detect_kube_provider
      ;;
    help|-h|--help|"")
      banner "refold.command kube help"
      cat <<EOF
Usage:
  ${SCRIPT_NAME} kube init
      → Detect provider (kind/minikube/external) and ensure namespace.

  ${SCRIPT_NAME} kube apply
      → Apply all .yaml manifests under: ${KUBE_MANIFEST_ROOT}

  ${SCRIPT_NAME} kube status
      → Show pods/services/deployments in namespace: ${KUBE_NAMESPACE}

  ${SCRIPT_NAME} kube logs <label_selector>
      → Tail logs for pods with given label selector (e.g. app=dlog-api).

  ${SCRIPT_NAME} kube port-forward <service-name> [localPort] [remotePort]
      → Forward localhost:localPort to service/service-name:remotePort.

  ${SCRIPT_NAME} kube provider
      → Print detected provider: kind|minikube|external|none
EOF
      ;;
    *)
      die "unknown kube subcommand: ${subcommand}"
      ;;
  esac
}

# --- PING / API OVERVIEW ----------------------------------------------------

cmd_ping() {
  banner "refold.command ping"

  log_info "Desktop:      ${DESKTOP}"
  log_info "DLOG_ROOT:    ${DLOG_ROOT}"
  log_info "UNIVERSE_ROOT:${UNIVERSE_ROOT}"
  log_info "KUBE_NS:      ${KUBE_NAMESPACE}"
  log_info "KUBE_MANIFEST:${KUBE_MANIFEST_ROOT}"
  log_info "DLOG_DOC_URL: ${DLOG_DOC_URL}"
  log_info "DLOG_REPO:    ${DLOG_REPO}"

  if ensure_dlog_command; then
    log_info "dlog.command is present and executable."
  else
    log_warn "dlog.command is missing or not executable."
  fi

  local provider
  provider="$(detect_kube_provider)"
  log_info "Kubernetes provider detected: ${provider}"

  log_info "Ping complete."
}

cmd_api() {
  banner "refold.command api"

  cat <<EOF
API / Universe Endpoints (conceptual; this script just prints them):

  Canonical Ω-spec document:
    ${DLOG_DOC_URL}

  GitHub Repos:
    DLOG / chain / app:        ${DLOG_REPO}
    Omega container (legacy):  ${OMEGA_CONTAINER_REPO}

Local Dev Expectations:

  - dlog.command on Desktop is the ONLY launcher we respect now.
    (start.command is obsolete and should not be used.)

  - refold.command is for:
      * orchestration,
      * Kubernetes helper verbs,
      * simple per-phone/per-label universe snapshots.

  - You can map Kubernetes services to friendly URLs via ingress:
      * https://dlog.local/∞/
      * https://dlog.local/9132077554/comet/status/
      * etc.

If you wire Kubernetes ingress + TLS, you can make the browser
see the same universe that refold.command is echoing here.

EOF
}

# --- UNIVERSE / STATUS COMMANDS --------------------------------------------

cmd_universe() {
  local phone="${1:-}"
  local label="${2:-}"

  if [ -z "${phone}" ] || [ -z "${label}" ]; then
    die "usage: ${SCRIPT_NAME} universe <phone> <label>"
  fi

  banner "Universe refold for phone=${phone} label=${label}"

  local file
  file="$(write_universe_if_missing "${phone}" "${label}")"

  log_info "Universe file: ${file}"
  log_info "Contents:"
  echo "------------------------------------------------------"
  cat "${file}"
  echo "------------------------------------------------------"
  log_info "You can extend this record format to hold Ω segments (O1..O8)."
}

cmd_status() {
  local phone="${1:-}"
  local label="${2:-}"

  if [ -z "${phone}" ] || [ -z "${label}" ]; then
    die "usage: ${SCRIPT_NAME} status <phone> <label>"
  fi

  banner "Universe status for phone=${phone} label=${label}"

  local line
  line="$(read_universe_or_die "${phone}" "${label}")"

  # Very basic parsing: ;phone;label;epoch;tag;status;
  # We don't enforce structure strictly; we just split on ;.
  IFS=';' read -r _ phone_field label_field epoch_field tag_field status_field _rest <<< "${line}"

  printf 'Phone : %s\n' "${phone_field}"
  printf 'Label : %s\n' "${label_field}"
  printf 'Epoch : %s\n' "${epoch_field}"
  printf 'Tag   : %s\n' "${tag_field}"
  printf 'State : %s\n' "${status_field}"
  echo
  printf 'Raw   : %s\n' "${line}"
}

# --- BEAT / ORBIT (SAFE STUBS, NO PARSE ERRORS) ----------------------------

cmd_beat() {
  banner "refold.command beat"
  cat <<EOF
Beat is now a SAFE stub.

Previously, this may have been wired into some experimental parser that
threw errors. For now, beat just acknowledges the request so your logs
stay clean.

You can later repurpose "beat" as:
  - a single-block refold tick,
  - a heartbeat that syncs DLOG state into Kubernetes ConfigMaps,
  - or a phi-flavored mining/metronome pulse.

EOF
}

cmd_orbit() {
  local phone="${1:-}"

  banner "refold.command orbit"

  if [ -z "${phone}" ]; then
    cat <<EOF
orbit currently wants an optional phone number, for example:

  ${SCRIPT_NAME} orbit 9132077554

Right now this is a pure visualization stub. No parsers, no errors.

Ideas for future use:
  - Visualize all active labels around a phone as "orbits".
  - Use Kubernetes namespaces/pods as orbital shells.
  - Print phi-scaled radii based on balances and locks.

EOF
    return 0
  fi

  cat <<EOF
Orbit visualization stub for phone=${phone}

Imagine:
  - Each label (vortex, comet, fun, land...) as a satellite.
  - Distances encoded by balance magnitude.
  - Kubernetes Deployments as stable Lagrange points.

This stub does not parse or compute anything yet; it only prints
conceptual text so your CLI stays peaceful.

EOF
}

# --- HELP / MAIN DISPATCH ---------------------------------------------------

show_help() {
  banner "refold.command help"
  cat <<EOF
Usage:
  ${SCRIPT_NAME} ping
      → Quick health check (paths, dlog.command presence, Kube provider).

  ${SCRIPT_NAME} api
      → Print canonical URLs + dev expectations.

  ${SCRIPT_NAME} kube <subcommand> [args...]
      → Kubernetes helper:
           init, apply, status, logs, port-forward, provider

  ${SCRIPT_NAME} universe <phone> <label>
      → Ensure a universe snapshot exists and print its contents.
         Example:
           ${SCRIPT_NAME} universe 9132077554 vortex
           ${SCRIPT_NAME} universe 9132077554 comet

  ${SCRIPT_NAME} status <phone> <label>
      → Pretty-print the parsed fields for a given universe snapshot.

  ${SCRIPT_NAME} beat
      → Safe stub (no parse errors). Future heartbeat hook.

  ${SCRIPT_NAME} orbit [phone]
      → Safe stub (no parse errors). Future orbit visualization hook.

Notes:
  - This script never calls start.command.
  - dlog.command is assumed to live on the Desktop and is the
    new canonical launcher. You can change it with \$DLOG_COMMAND.

EOF
}

main() {
  local cmd="${1:-help}"
  shift || true

  case "${cmd}" in
    help|-h|--help)
      show_help
      ;;
    ping)
      cmd_ping "$@"
      ;;
    api)
      cmd_api "$@"
      ;;
    kube|kubernetes)
      cmd_kube "$@"
      ;;
    universe)
      cmd_universe "$@"
      ;;
    status)
      cmd_status "$@"
      ;;
    beat)
      cmd_beat "$@"
      ;;
    orbit)
      cmd_orbit "$@"
      ;;
    *)
      log_error "unknown command: ${cmd}"
      show_help
      exit 1
      ;;
  esac
}

main "$@"
