#!/usr/bin/env bash
#
# refold.command
#
# DLOG / Ω-Physics / Kubernetes orchestrator
# GOLDEN BRICK #4 — “paint + beat”
# -------------------------------------------------------------
# - start.command is STILL dead. We never touch it.
# - dlog.command on Desktop is the only launcher we honor.
#
# New in this brick:
#   * paint         → visual, artsy view of universes.
#   * status extra  → human datetime, base-8 epoch, age.
#   * beat upgraded → actually syncs YAML + Kubernetes + dlog.command.
#
# Existing:
#   * ping, api, scan
#   * kube init/apply/status/logs/port-forward/provider/sync
#   * universe, pair
#   * orbit (safe stub)
# -------------------------------------------------------------

set -euo pipefail

# --- BASIC CONSTANTS ---------------------------------------------------------

SCRIPT_NAME="$(basename "${0}")"

DESKTOP="${HOME}/Desktop"
DLOG_ROOT_DEFAULT="${DESKTOP}/dlog"
DLOG_COMMAND_DEFAULT="${DESKTOP}/dlog.command"

DLOG_ROOT="${DLOG_ROOT:-${DLOG_ROOT_DEFAULT}}"
DLOG_COMMAND="${DLOG_COMMAND:-${DLOG_COMMAND_DEFAULT}}"

UNIVERSE_ROOT="${UNIVERSE_ROOT:-${DLOG_ROOT}/universe}"

KUBE_NAMESPACE_DEFAULT="dlog-universe"
KUBE_NAMESPACE="${KUBE_NAMESPACE:-${KUBE_NAMESPACE_DEFAULT}}"
KUBE_MANIFEST_ROOT="${KUBE_MANIFEST_ROOT:-${DLOG_ROOT}/kube}"

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
  ensure_dlog_command || return 1
  log_info "delegating to dlog.command → $*"
  "${DLOG_COMMAND}" "$@" || return $?
}

# --- UNIVERSE FILE MAPPING --------------------------------------------------
# Format (for now):
#   ;phone;label;epoch;tag;status;
# You can later extend with Ω segments (O1..O8).

universe_file_path() {
  local phone="$1"
  local label="$2"
  ensure_dir "${UNIVERSE_ROOT}/${phone}"
  printf '%s\n' "${UNIVERSE_ROOT}/${phone}/${label};universe"
}

default_universe_payload() {
  local phone="$1"
  local label="$2"
  local now_epoch
  now_epoch="$(date +%s)"
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

# --- TIME & SCALE HELPERS (HUMAN + BASE-8) ---------------------------------

epoch_to_datetime() {
  local epoch="$1"
  if date -r "${epoch}" '+%Y-%m-%d %H:%M:%S' >/dev/null 2>&1; then
    date -r "${epoch}" '+%Y-%m-%d %H:%M:%S'
  elif date -d "@${epoch}" '+%Y-%m-%d %H:%M:%S' >/dev/null 2>&1; then
    date -d "@${epoch}" '+%Y-%m-%d %H:%M:%S'
  else
    printf 'epoch:%s\n' "${epoch}"
  fi
}

humanize_duration() {
  local total="$1"
  if [ "${total}" -lt 0 ] 2>/dev/null; then
    total=0
  fi
  local d h m s
  d=$(( total / 86400 ))
  h=$(( (total % 86400) / 3600 ))
  m=$(( (total % 3600) / 60 ))
  s=$(( total % 60 ))

  local out=""
  if [ "${d}" -gt 0 ]; then out="${out}${d}d "; fi
  if [ "${h}" -gt 0 ]; then out="${out}${h}h "; fi
  if [ "${m}" -gt 0 ]; then out="${out}${m}m "; fi
  if [ "${s}" -gt 0 ] || [ -z "${out}" ]; then out="${out}${s}s"; fi
  printf '%s\n' "${out}"
}

# --- UNIVERSE SCAN ----------------------------------------------------------

cmd_scan() {
  banner "refold.command scan (all universes)"

  ensure_dir "${UNIVERSE_ROOT}"

  local files
  files="$(find "${UNIVERSE_ROOT}" -type f -name '*;universe' 2>/dev/null || true)"

  if [ -z "${files}" ]; then
    log_warn "No universe files found yet. Use 'universe' or 'pair' to seed."
    return 0
  fi

  printf '%-12s %-12s %-12s %-10s %-10s %s\n' \
    "Phone" "Label" "Epoch" "Tag" "State" "File"
  printf '%-12s %-12s %-12s %-10s %-10s %s\n' \
    "------------" "------------" "------------" "----------" "----------" "----------------"

  local f line phone_field label_field epoch_field tag_field status_field _rest
  for f in ${files}; do
    line="$(cat "${f}")"
    IFS=';' read -r _ phone_field label_field epoch_field tag_field status_field _rest <<< "${line}"
    printf '%-12s %-12s %-12s %-10s %-10s %s\n' \
      "${phone_field}" "${label_field}" "${epoch_field}" "${tag_field}" "${status_field}" "${f}"
  done
}

# --- KUBERNETES HELPERS -----------------------------------------------------

detect_kube_provider() {
  if optional_cmd kind; then
    printf 'kind\n'
    return 0
  fi
  if optional_cmd minikube; then
    printf 'minikube\n'
    return 0
  fi
  if optional_cmd kubectl; then
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

kube_check_cluster() {
  ensure_kubectl
  if ! kubectl cluster-info >/dev/null 2>&1; then
    local ctx
    ctx="$(kubectl config current-context 2>/dev/null || echo 'none')"
    log_warn "kubectl is installed, but no reachable cluster."
    log_warn "Current context: ${ctx}"
    log_warn "Start a cluster (kind/minikube/real) or point kubeconfig at a live cluster."
    return 1
  fi
  return 0
}

kube_create_namespace_if_missing() {
  if ! kube_check_cluster; then
    log_warn "Skipping namespace creation because no cluster is reachable yet."
    return 0
  fi

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
  if ! kube_check_cluster; then
    log_warn "No reachable external cluster yet; kube init is a no-op for now."
    return 0
  fi
  log_info "External cluster is reachable; you can use kube apply/status/logs."
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

kube_write_starter_manifest_if_missing() {
  ensure_dir "${KUBE_MANIFEST_ROOT}"
  if ! ls "${KUBE_MANIFEST_ROOT}"/*.yaml >/dev/null 2>&1; then
    local manifest="${KUBE_MANIFEST_ROOT}/hello-universe.yaml"
    log_info "No .yaml manifests found; writing starter file: ${manifest}"
    cat <<'YAML' > "${manifest}"
apiVersion: v1
kind: Namespace
metadata:
  name: dlog-universe
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: dlog-hello
  namespace: dlog-universe
data:
  message: "Welcome to the DLOG Universe (hello-universe.yaml)."
YAML
  fi
}

kube_apply_manifests() {
  kube_write_starter_manifest_if_missing

  if ! kube_check_cluster; then
    log_warn "Cluster not reachable; skipping kubectl apply for now."
    log_warn "Once your cluster is up, re-run: ${SCRIPT_NAME} kube apply"
    return 0
  fi

  banner "Kubernetes: applying manifests"
  kubectl apply -n "${KUBE_NAMESPACE}" -f "${KUBE_MANIFEST_ROOT}"
}

kube_status() {
  if ! kube_check_cluster; then
    log_warn "Cluster not reachable; cannot show Kubernetes status yet."
    return 0
  fi

  banner "Kubernetes: status (namespace=${KUBE_NAMESPACE})"
  kubectl get pods -n "${KUBE_NAMESPACE}" || true
  echo
  kubectl get svc -n "${KUBE_NAMESPACE}" || true
  echo
  kubectl get deployments -n "${KUBE_NAMESPACE}" || true
}

kube_logs() {
  if ! kube_check_cluster; then
    log_warn "Cluster not reachable; cannot fetch logs yet."
    return 0
  fi

  local pod_selector="${1:-}"
  if [ -z "${pod_selector}" ]; then
    die "kube logs requires a pod name or label selector, e.g. 'app=dlog-api'"
  fi
  banner "Kubernetes: logs for selector=${pod_selector}"
  kubectl logs -n "${KUBE_NAMESPACE}" -l "${pod_selector}" --tail=200 || true
}

kube_port_forward() {
  if ! kube_check_cluster; then
    log_warn "Cluster not reachable; cannot port-forward yet."
    return 0
  fi

  local svc="${1:-}"
  local local_port="${2:-8080}"
  local remote_port="${3:-80}"

  if [ -z "${svc}" ]; then
    die "usage: ${SCRIPT_NAME} kube port-forward <service-name> [localPort] [remotePort]"
  fi

  banner "Kubernetes: port-forward → localhost:${local_port} → svc/${svc}:${remote_port}"
  kubectl port-forward -n "${KUBE_NAMESPACE}" "svc/${svc}" "${local_port}:${remote_port}"
}

# --- UNIVERSE → CONFIGMAP YAML ---------------------------------------------

write_universe_configmap_yaml() {
  local phone="$1"
  local label="$2"

  local file
  file="$(universe_file_path "${phone}" "${label}")"
  if [ ! -f "${file}" ]; then
    log_warn "universe file missing for phone=${phone} label=${label}, skipping YAML sync."
    return 0
  fi

  local line
  line="$(cat "${file}")"

  local _dummy phone_field label_field epoch_field tag_field status_field _rest
  IFS=';' read -r _dummy phone_field label_field epoch_field tag_field status_field _rest <<< "${line}"

  ensure_dir "${KUBE_MANIFEST_ROOT}/universe"
  local yaml="${KUBE_MANIFEST_ROOT}/universe/${phone_field}-${label_field}.yaml"

  local raw_escaped="${line//\"/\\\"}"

  cat > "${yaml}" <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: dlog-${phone_field}-${label_field}
  namespace: ${KUBE_NAMESPACE}
data:
  phone: "${phone_field}"
  label: "${label_field}"
  epoch: "${epoch_field}"
  tag: "${tag_field}"
  status: "${status_field}"
  raw: "${raw_escaped}"
EOF

  log_info "wrote universe configmap manifest → ${yaml}"
}

sync_universe_manifests() {
  ensure_dir "${UNIVERSE_ROOT}"
  ensure_dir "${KUBE_MANIFEST_ROOT}/universe"

  local files
  files="$(find "${UNIVERSE_ROOT}" -type f -name '*;universe' 2>/dev/null || true)"

  if [ -z "${files}" ]; then
    log_warn "No universe files found under ${UNIVERSE_ROOT} to sync."
    return 0
  fi

  local f filename label phone
  for f in ${files}; do
    filename="$(basename "${f}")"              # e.g. vortex;universe
    label="${filename%%;*}"                   # e.g. vortex
    phone="$(basename "$(dirname "${f}")")"   # e.g. 9132077554
    write_universe_configmap_yaml "${phone}" "${label}"
  done
}

kube_sync_universe() {
  banner "Kubernetes: syncing universes → ConfigMap manifests"

  sync_universe_manifests

  local universe_dir="${KUBE_MANIFEST_ROOT}/universe"

  if ! ls "${universe_dir}"/*.yaml >/dev/null 2>&1; then
    log_warn "No universe YAML manifests found under ${universe_dir}."
    return 0
  fi

  if ! kube_check_cluster; then
    log_warn "Cluster not reachable; only wrote YAML manifests."
    log_warn "Once your cluster is up, run: ${SCRIPT_NAME} kube sync again."
    return 0
  fi

  log_info "Applying all universe ConfigMaps from: ${universe_dir}"
  kubectl apply -n "${KUBE_NAMESPACE}" -f "${universe_dir}"
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
    sync)
      kube_sync_universe
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
      → Ensure a starter manifest exists, then apply all .yaml files under:
          ${KUBE_MANIFEST_ROOT}

  ${SCRIPT_NAME} kube sync
      → Convert every universe file into a ConfigMap YAML under:
          ${KUBE_MANIFEST_ROOT}/universe
        and, if a cluster is reachable, kubectl apply them.

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

EOF
}

# --- UNIVERSE / STATUS / PAIR ----------------------------------------------

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

  local file
  file="$(write_universe_if_missing "${phone}" "${label}")"
  local line
  line="$(cat "${file}")"

  local _dummy phone_field label_field epoch_field tag_field status_field _rest
  IFS=';' read -r _dummy phone_field label_field epoch_field tag_field status_field _rest <<< "${line}"

  local when octal now age
  when="$(epoch_to_datetime "${epoch_field}")"
  octal="$(printf '%o' "${epoch_field}")"
  now="$(date +%s)"
  age=$(( now - epoch_field ))
  local age_str
  age_str="$(humanize_duration "${age}")"

  printf 'Phone : %s\n' "${phone_field}"
  printf 'Label : %s\n' "${label_field}"
  printf 'Epoch : %s\n' "${epoch_field}"
  printf 'Epoch₈: %s\n' "${octal}"
  printf 'When  : %s\n' "${when}"
  printf 'Age   : %s ago\n' "${age_str}"
  printf 'Tag   : %s\n' "${tag_field}"
  printf 'State : %s\n' "${status_field}"
  echo
  printf 'Raw   : %s\n' "${line}"
}

cmd_pair() {
  local phone="${1:-}"
  if [ -z "${phone}" ]; then
    die "usage: ${SCRIPT_NAME} pair <phone>"
  fi

  banner "Universe pair (vortex + comet) for phone=${phone}"

  local fv fc
  fv="$(write_universe_if_missing "${phone}" "vortex")"
  fc="$(write_universe_if_missing "${phone}" "comet")"

  log_info "vortex universe file: ${fv}"
  log_info "comet  universe file: ${fc}"

  echo "------------------------------------------------------"
  echo "vortex:"
  cat "${fv}"
  echo "------------------------------------------------------"
  echo "comet:"
  cat "${fc}"
  echo "------------------------------------------------------"
}

# --- PAINT (NEW) -----------------------------------------------------------

label_symbol() {
  local lbl_lower
  lbl_lower="$(printf '%s\n' "$1" | tr '[:upper:]' '[:lower:]')"
  case "${lbl_lower}" in
    vortex) printf '●';;
    comet)  printf '○';;
    *)      printf '◆';;
  esac
}

paint_phone() {
  local phone="$1"

  local dir="${UNIVERSE_ROOT}/${phone}"
  if [ ! -d "${dir}" ]; then
    return 0
  fi

  printf 'Phone %s\n' "${phone}"
  printf '------------------------------------------------------\n'

  local f
  for f in "${dir}"/*';universe'; do
    [ -f "${f}" ] || continue
    local line
    line="$(cat "${f}")"
    local _dummy phone_field label_field epoch_field tag_field status_field _rest
    IFS=';' read -r _dummy phone_field label_field epoch_field tag_field status_field _rest <<< "${line}"

    local sym when octal now age age_str
    sym="$(label_symbol "${label_field}")"
    when="$(epoch_to_datetime "${epoch_field}")"
    octal="$(printf '%o' "${epoch_field}")"
    now="$(date +%s)"
    age=$(( now - epoch_field ))
    age_str="$(humanize_duration "${age}")"

    printf '  [%s] %-7s ── tag=%-6s state=%-4s epoch=%-12s (₈=%s) age=%s ago at %s\n' \
      "${sym}" "${label_field}" "${tag_field}" "${status_field}" "${epoch_field}" "${octal}" "${age_str}" "${when}"
  done

  printf '\n'
}

cmd_paint() {
  local phone="${1:-}"

  banner "refold.command paint (universe orbits)"

  ensure_dir "${UNIVERSE_ROOT}"

  if [ -z "${phone}" ]; then
    local dirs
    dirs="$(find "${UNIVERSE_ROOT}" -mindepth 1 -maxdepth 1 -type d 2>/dev/null || true)"
    if [ -z "${dirs}" ]; then
      log_warn "No universes to paint yet. Seed with 'pair' or 'universe'."
      return 0
    fi
    local d
    for d in ${dirs}; do
      paint_phone "$(basename "${d}")"
    done
  else
    paint_phone "${phone}"
  fi
}

# --- BEAT / ORBIT -----------------------------------------------------------

cmd_beat() {
  banner "refold.command beat"

  log_info "1) Syncing universes → kube/universe/*.yaml"
  sync_universe_manifests

  log_info "2) (Optional) Applying to Kubernetes if a cluster is reachable"
  if kube_check_cluster; then
    local universe_dir="${KUBE_MANIFEST_ROOT}/universe"
    if ls "${universe_dir}"/*.yaml >/dev/null 2>&1; then
      kubectl apply -n "${KUBE_NAMESPACE}" -f "${universe_dir}" || log_warn "kubectl apply (beat) exited non-zero."
    else
      log_warn "No universe YAML manifests found under ${universe_dir} (beat)."
    fi
  else
    log_warn "Skipping kubectl apply during beat; no cluster reachable."
  fi

  log_info "3) (Optional) Notifying dlog.command with 'beat'"
  if ensure_dlog_command; then
    if ! call_dlog beat; then
      log_warn "dlog.command beat exited non-zero (or not implemented)."
    fi
  else
    log_warn "dlog.command not present; skipping external beat."
  fi

  echo
  cat <<EOF
Beat complete.

This beat:
  - Re-synced all universes into kube/universe/*.yaml
  - Applied them to Kubernetes if a cluster is reachable
  - Poked dlog.command with "beat" if the new launcher is available

EOF
}

cmd_orbit() {
  local phone="${1:-}"

  banner "refold.command orbit"

  if [ -z "${phone}" ]; then
    cat <<EOF
orbit currently wants an optional phone number, for example:

  ${SCRIPT_NAME} orbit 9132077554

For now it's a visualization hint; paint is the more detailed output.
EOF
    return 0
  fi

  cat <<EOF
Orbit visualization stub for phone=${phone}

Imagine:
  - Each label (vortex, comet, fun, land...) as a satellite.
  - Distances encoded by balance magnitude.
  - Kubernetes Deployments as stable Lagrange points.

Use:
  ${SCRIPT_NAME} paint ${phone}
to see the detailed lines for this phone.

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

  ${SCRIPT_NAME} scan
      → List all universe files in a table (phone/label/epoch/tag/state).

  ${SCRIPT_NAME} paint [phone]
      → Pretty, artsy rendering of universes for all phones or a single phone.

  ${SCRIPT_NAME} kube <subcommand> [args...]
      → Kubernetes helper:
           init, apply, status, logs, port-forward, provider, sync

  ${SCRIPT_NAME} universe <phone> <label>
      → Ensure a universe snapshot exists and print its contents.

  ${SCRIPT_NAME} status <phone> <label>
      → Pretty-print a universe (with datetime, base-8 epoch, age).

  ${SCRIPT_NAME} pair <phone>
      → Seed both vortex + comet universes for the given phone in one shot.

  ${SCRIPT_NAME} beat
      → Heartbeat: sync YAML, apply to Kube (if reachable), ping dlog.command.

  ${SCRIPT_NAME} orbit [phone]
      → Simple orbit hint; pair with 'paint' for full visuals.

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
    scan)
      cmd_scan "$@"
      ;;
    paint)
      cmd_paint "$@"
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
    pair)
      cmd_pair "$@"
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
