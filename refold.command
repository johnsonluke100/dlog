#!/usr/bin/env bash
#
# refold.command
#
# DLOG / Ω-Physics / Kubernetes orchestrator
# GOLDEN BRICK — universes + stack + 9∞ root + flames + Ω-dashboard + Ω-sky (manifest + timeline)
#
# Ground rules:
#   - start.command is dead. We never touch it.
#   - dlog.command on Desktop is the canonical launcher.
#   - We speak in semicolons and base-8, not base-10.
#
# Canon:
#   DLOG spec: https://docs.google.com/document/d/e/2PACX-1vShJ-OHsxJjf13YISSM7532zs0mHbrsvkSK73nHnK18rZmpysHC6B1RIMvGTALy0RIo1R1HRAyewCwR/pub
#
# Commands:
#   ping          → show paths, doc URL, repo
#   api           → print canonical URLs + expectations
#   scan          → enumerate universes
#   paint [phone] → orbit view (vortex ● / comet ○)
#   kube ...      → init/apply/sync/status/logs/port-forward
#   universe p l  → ensure universe snapshot exists
#   status p l    → pretty-print one universe
#   pair p        → seed vortex + comet
#   beat          → 1 beat = sync YAML + stack + 9∞ + dashboard + sky + poke dlog
#   orbit [phone] → stub orbit hint
#   cleanup       → safe stub
#   stack-up [p]  → flattened Ω stack
#   root          → 9∞ master root writer
#   dashboard     → Ω-dashboard snapshot
#   flames ...    → control file (up/down/hz) for audio engines
#   sky ...       → Ω-sky manifest + timeline (cosine crossfade ring)
#
# All golden bricks are encoded here so you don’t have to touch any other files. ∞🌀

set -euo pipefail

# --- BASIC CONSTANTS --------------------------------------------------------

SCRIPT_NAME="$(basename "${0}")"

DESKTOP="${HOME}/Desktop"
DLOG_ROOT_DEFAULT="${DESKTOP}/dlog"
DLOG_COMMAND_DEFAULT="${DESKTOP}/dlog.command"

DLOG_ROOT="${DLOG_ROOT:-${DLOG_ROOT_DEFAULT}}"
DLOG_COMMAND="${DLOG_COMMAND:-${DLOG_COMMAND_DEFAULT}}"

UNIVERSE_ROOT="${UNIVERSE_ROOT:-${DLOG_ROOT}/universe}"
STACK_ROOT="${STACK_ROOT:-${DLOG_ROOT}/stack}"

KUBE_NAMESPACE_DEFAULT="dlog-universe"
KUBE_NAMESPACE="${KUBE_NAMESPACE:-${KUBE_NAMESPACE_DEFAULT}}"
KUBE_MANIFEST_ROOT="${KUBE_MANIFEST_ROOT:-${DLOG_ROOT}/kube}"

DLOG_DOC_URL_DEFAULT="https://docs.google.com/document/d/e/2PACX-1vShJ-OHsxJjf13YISSM7532zs0mHbrsvkSK73nHnK18rZmpysHC6B1RIMvGTALy0RIo1R1HRAyewCwR/pub"
DLOG_REPO_DEFAULT="https://github.com/johnsonluke100/dlog"
OMEGA_CONTAINER_REPO_DEFAULT="https://github.com/johnsonluke100/minecraft/tree/main/omega_numpy_container"

DLOG_DOC_URL="${DLOG_DOC_URL:-${DLOG_DOC_URL_DEFAULT}}"
DLOG_REPO="${DLOG_REPO:-${DLOG_REPO_DEFAULT}}"
OMEGA_CONTAINER_REPO="${OMEGA_CONTAINER_REPO:-${OMEGA_CONTAINER_REPO_DEFAULT}}"

# Ω filesystem roots
OMEGA_ROOT="${OMEGA_ROOT:-${DLOG_ROOT}}"
OMEGA_INF_ROOT="${OMEGA_INF_ROOT:-${OMEGA_ROOT}/∞}"

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
# Format:
#   ;phone;label;epoch;tag;status;

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

# --- TIME & SCALE HELPERS ---------------------------------------------------

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

  local f line phone_field label_field epoch_field tag_field status_field _rest _
  for f in ${files}; do
    [ -f "${f}" ] || continue
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

  local _ phone_field label_field epoch_field tag_field status_field _rest
  IFS=';' read -r _ phone_field label_field epoch_field tag_field status_field _rest <<< "${line}"

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
    [ -f "${f}" ] || continue
    filename="$(basename "${f}")"
    label="${filename%%;*}"
    phone="$(basename "$(dirname "${f}")")"
    write_universe_configmap_yaml "${phone}" "${label}"
  done
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
      banner "Kubernetes: syncing universes → ConfigMap manifests"
      sync_universe_manifests
      kube_apply_manifests
      ;;
    provider)
      banner "refold.command kube provider"
      detect_kube_provider
      ;;
    help|-h|--help|"")
      banner "refold.command kube help"
      cat <<EOF
Usage:
  ${SCRIPT_NAME} kube init
  ${SCRIPT_NAME} kube apply
  ${SCRIPT_NAME} kube sync
  ${SCRIPT_NAME} kube status
  ${SCRIPT_NAME} kube logs <label_selector>
  ${SCRIPT_NAME} kube port-forward <service-name> [localPort] [remotePort]
  ${SCRIPT_NAME} kube provider
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
  log_info "STACK_ROOT:   ${STACK_ROOT}"
  log_info "KUBE_NS:      ${KUBE_NAMESPACE}"
  log_info "KUBE_MANIFEST:${KUBE_MANIFEST_ROOT}"
  log_info "DLOG_DOC_URL: ${DLOG_DOC_URL}"
  log_info "DLOG_REPO:    ${DLOG_REPO}"
  log_info "OMEGA_ROOT:   ${OMEGA_ROOT}"
  log_info "Ω-INF-ROOT:   ${OMEGA_INF_ROOT}"

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
Canonical Ω-spec document:
  ${DLOG_DOC_URL}

GitHub Repos:
  DLOG / chain / app:        ${DLOG_REPO}
  Omega container (legacy):  ${OMEGA_CONTAINER_REPO}

refold.command:
  - Orchestrator for universes, stacks, flames, 9∞ root, Ω-sky, and Kubernetes sync.
  - Never calls start.command. Only dlog.command.
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

  local _ phone_field label_field epoch_field tag_field status_field _rest
  IFS=';' read -r _ phone_field label_field epoch_field tag_field status_field _rest <<< "${line}"

  local when octal now age age_str
  when="$(epoch_to_datetime "${epoch_field}")"
  octal="$(printf '%o' "${epoch_field}")"
  now="$(date +%s)"
  age=$(( now - epoch_field ))
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

# --- PAINT (UNIVERSE ORBITS) -----------------------------------------------

label_symbol() {
  local lbl_lower
  lbl_lower="$(printf '%s\n' "$1" | tr '[:upper:]' '[:lower:]')"
  case "${lbl_lower}" in
    vortex) echo "●" ;;
    comet)  echo "○" ;;
    *)      echo "◆" ;;
  esac
}

paint_phone() {
  local phone="$1"
  local dir="${UNIVERSE_ROOT}/${phone}"

  if [ ! -d "${dir}" ]; then
    return 0
  fi

  echo "Phone ${phone}"
  echo "------------------------------------------------------"

  local f line _ phone_field label_field epoch_field tag_field status_field _rest
  for f in "${dir}"/*';universe'; do
    [ -f "${f}" ] || continue
    line="$(cat "${f}")"
    IFS=';' read -r _ phone_field label_field epoch_field tag_field status_field _rest <<< "${line}"

    local sym when octal now age age_str
    sym="$(label_symbol "${label_field}")"
    when="$(epoch_to_datetime "${epoch_field}")"
    octal="$(printf '%o' "${epoch_field}")"
    now="$(date +%s)"
    age=$(( now - epoch_field ))
    age_str="$(humanize_duration "${age}")"

    echo "  [${sym}] ${label_field}  tag=${tag_field} state=${status_field} epoch=${epoch_field} (8=${octal}) age=${age_str} ago at ${when}"
  done

  echo
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

# --- STACK-UP ---------------------------------------------------------------

build_stack_snapshot() {
  local phone_filter="${1:-}"

  ensure_dir "${STACK_ROOT}"
  ensure_dir "${UNIVERSE_ROOT}"

  local out="${STACK_ROOT}/stack;universe"
  local now_epoch
  now_epoch="$(date +%s)"
  local found=0
  local files=""

  if [ -n "${phone_filter}" ] && [ -d "${UNIVERSE_ROOT}/${phone_filter}" ]; then
    files="$(find "${UNIVERSE_ROOT}/${phone_filter}" -type f -name '*;universe' 2>/dev/null || true)"
    if [ -z "${files}" ]; then
      files="$(find "${UNIVERSE_ROOT}" -type f -name '*;universe' 2>/dev/null || true)"
    fi
  else
    files="$(find "${UNIVERSE_ROOT}" -type f -name '*;universe' 2>/dev/null || true)"
  fi

  {
    printf ';stack;epoch;%s;ok;\n' "${now_epoch}"

    if [ -n "${files}" ]; then
      local f line _ phone_field label_field epoch_field tag_field status_field _rest octal
      for f in ${files}; do
        [ -f "${f}" ] || continue
        line="$(cat "${f}")"
        IFS=';' read -r _ phone_field label_field epoch_field tag_field status_field _rest <<< "${line}"
        octal="$(printf '%o' "${epoch_field}")"
        printf ';%s;%s;%s;%s;%s;%s;\n' \
          "${phone_field}" "${label_field}" "${epoch_field}" "${octal}" "${tag_field}" "${status_field}"
        found=$((found+1))
      done
    fi
  } > "${out}"

  log_info "wrote stack snapshot → ${out} (universes=${found})"
}

cmd_stack_up() {
  local phone="${1:-}"

  banner "refold.command stack-up"

  if [ -z "${phone}" ]; then
    build_stack_snapshot
  else
    build_stack_snapshot "${phone}"
  fi

  cat <<EOF
Stack-up complete.

The Ω-stack snapshot now lives at:

  ${STACK_ROOT}/stack;universe

Format:
  ;stack;epoch;<nowEpoch>;ok;
  ;phone;label;epoch;epoch8;tag;status;

dlog.command (and any Ω-physics engines) can read this file
as the single "flattened" view of all universes.

EOF
}

# --- 9∞ MASTER ROOT WRITER --------------------------------------------------

write_nine_inf_root() {
  ensure_dir "${OMEGA_INF_ROOT}"

  local stack_file="${STACK_ROOT}/stack;universe"
  local flames_file="${DLOG_ROOT}/flames/flames;control"
  local tmp="${OMEGA_INF_ROOT}/.root_build.$$"

  {
    if [ -f "${stack_file}" ]; then cat "${stack_file}"; fi
    if [ -f "${flames_file}" ]; then cat "${flames_file}"; fi
  } > "${tmp}" 2>/dev/null || true

  local digest=""
  if [ -s "${tmp}" ]; then
    if command -v shasum >/dev/null 2>&1; then
      digest="$(shasum -a 256 "${tmp}" | awk '{print $1}')"
    elif command -v sha256sum >/dev/null 2>&1; then
      digest="$(sha256sum "${tmp}" | awk '{print $1}')"
    elif command -v openssl >/dev/null 2>&1; then
      digest="$(openssl dgst -sha256 "${tmp}" | awk '{print $2}')"
    else
      digest="0000000000000000000000000000000000000000000000000000000000000000"
    fi
  else
    digest="0000000000000000000000000000000000000000000000000000000000000000"
  fi
  rm -f "${tmp}"

  digest="${digest:-0000000000000000000000000000000000000000000000000000000000000000}"

  local O1 O2 O3 O4 O5 O6 O7 O8
  O1="${digest:0:8}"
  O2="${digest:8:8}"
  O3="${digest:16:8}"
  O4="${digest:24:8}"
  O5="${digest:32:8}"
  O6="${digest:40:8}"
  O7="${digest:48:8}"
  O8="${digest:56:8}"

  local root_file="${OMEGA_INF_ROOT}/;∞;∞;∞;∞;∞;∞;∞;∞;∞;"
  printf ';∞;∞;∞;∞;∞;∞;∞;∞;∞;%s;%s;%s;%s;%s;%s;%s;%s;\n' \
    "${O1}" "${O2}" "${O3}" "${O4}" "${O5}" "${O6}" "${O7}" "${O8}" > "${root_file}"

  log_info "wrote 9∞ master root → ${root_file}"
}

cmd_root() {
  banner "refold.command root (9∞ master)"

  write_nine_inf_root

  local root_file="${OMEGA_INF_ROOT}/;∞;∞;∞;∞;∞;∞;∞;∞;∞;"
  if [ -f "${root_file}" ]; then
    printf '9∞ Master Root contents:\n\n'
    cat "${root_file}"
    echo
  else
    log_warn "9∞ master root file not found at: ${root_file}"
  fi
}

# --- Ω DASHBOARD WRITER -----------------------------------------------------

write_dashboard_snapshot() {
  ensure_dir "${DLOG_ROOT}/dashboard"

  local dash="${DLOG_ROOT}/dashboard/dashboard;status"
  local now_epoch
  now_epoch="$(date +%s)"

  local stack_file="${STACK_ROOT}/stack;universe"
  local stack_epoch="0"

  if [ -f "${stack_file}" ]; then
    local line _k1 _k2 _k3 _rest
    line="$(head -n1 "${stack_file}" || true)"
    IFS=';' read -r _k1 _k2 _k3 stack_epoch _rest <<< "${line}"
  fi

  local root_file="${OMEGA_INF_ROOT}/;∞;∞;∞;∞;∞;∞;∞;∞;∞;"
  local O1 O2 O3 O4 O5 O6 O7 O8
  local O1_8 O2_8 O3_8 O4_8 O5_8 O6_8 O7_8 O8_8

  O1="00000000"; O2="00000000"; O3="00000000"; O4="00000000"
  O5="00000000"; O6="00000000"; O7="00000000"; O8="00000000"
  O1_8="0"; O2_8="0"; O3_8="0"; O4_8="0"; O5_8="0"; O6_8="0"; O7_8="0"; O8_8="0"

  if [ -f "${root_file}" ]; then
    local rline _ a b c d e f g h i
    rline="$(cat "${root_file}")"
    IFS=';' read -r _ a b c d e f g h i O1 O2 O3 O4 O5 O6 O7 O8 _ <<< "${rline}"
    O1="${O1:-00000000}"
    O2="${O2:-00000000}"
    O3="${O3:-00000000}"
    O4="${O4:-00000000}"
    O5="${O5:-00000000}"
    O6="${O6:-00000000}"
    O7="${O7:-00000000}"
    O8="${O8:-00000000}"

    O1_8="$(printf '%o' "0x${O1}" 2>/dev/null || echo 0)"
    O2_8="$(printf '%o' "0x${O2}" 2>/dev/null || echo 0)"
    O3_8="$(printf '%o' "0x${O3}" 2>/dev/null || echo 0)"
    O4_8="$(printf '%o' "0x${O4}" 2>/dev/null || echo 0)"
    O5_8="$(printf '%o' "0x${O5}" 2>/dev/null || echo 0)"
    O6_8="$(printf '%o' "0x${O6}" 2>/dev/null || echo 0)"
    O7_8="$(printf '%o' "0x${O7}" 2>/dev/null || echo 0)"
    O8_8="$(printf '%o' "0x${O8}" 2>/dev/null || echo 0)"
  fi

  local flames_file="${DLOG_ROOT}/flames/flames;control"
  local flames_mode="none"
  local flames_epoch="0"
  local flames_hz="0"

  if [ -f "${flames_file}" ]; then
    local fline _x1 _x2 _x3 _rest
    fline="$(head -n1 "${flames_file}" || true)"
    IFS=';' read -r _x1 _x2 _x3 flames_epoch flames_mode _rest <<< "${fline}"
    flames_mode="${flames_mode:-none}"
    flames_epoch="${flames_epoch:-0}"

    local oline
    oline="$(grep '^;omega;hz;' "${flames_file}" 2>/dev/null || true)"
    if [ -n "${oline}" ]; then
      # Example: ;omega;hz;7777;cpu=heart;gpu=brain;flames;4;
      local _s0 _tag _key _val _rest2
      IFS=';' read -r _s0 _tag _key _val _rest2 <<< "${oline}"
      flames_hz="${_val:-0}"
    fi
  fi

  {
    printf ';dashboard;epoch;%s;ok;\n' "${now_epoch}"
    printf ';stack;epoch;%s;\n' "${stack_epoch}"
    printf ';root;O1;%s;O1_8;%s;\n' "${O1}" "${O1_8}"
    printf ';root;O2;%s;O2_8;%s;\n' "${O2}" "${O2_8}"
    printf ';root;O3;%s;O3_8;%s;\n' "${O3}" "${O3_8}"
    printf ';root;O4;%s;O4_8;%s;\n' "${O4}" "${O4_8}"
    printf ';root;O5;%s;O5_8;%s;\n' "${O5}" "${O5_8}"
    printf ';root;O6;%s;O6_8;%s;\n' "${O6}" "${O6_8}"
    printf ';root;O7;%s;O7_8;%s;\n' "${O7}" "${O7_8}"
    printf ';root;O8;%s;O8_8;%s;\n' "${O8}" "${O8_8}"
    printf ';flames;mode;%s;epoch;%s;hz;%s;\n' "${flames_mode}" "${flames_epoch}" "${flames_hz}"
  } > "${dash}"

  log_info "wrote Ω-dashboard snapshot → ${dash}"
}

cmd_dashboard() {
  banner "refold.command dashboard"

  write_dashboard_snapshot

  local dash="${DLOG_ROOT}/dashboard/dashboard;status"
  if [ -f "${dash}" ]; then
    printf 'Ω-dashboard contents:\n\n'
    cat "${dash}"
    echo
  else
    log_warn "dashboard;status not found at: ${dash}"
  fi
}

# --- Ω-SKY MANIFEST ---------------------------------------------------------

write_sky_manifest() {
  local sky_root="${SKY_ROOT:-${DLOG_ROOT}/sky}"
  local sky_src="${SKY_SRC:-${sky_root}/src}"

  ensure_dir "${sky_root}"

  local manifest="${sky_root}/sky;manifest"
  local now_epoch
  now_epoch="$(date +%s)"

  local root_file="${OMEGA_INF_ROOT}/;∞;∞;∞;∞;∞;∞;∞;∞;∞;"
  local O1 O2 O3 O4 O5 O6 O7 O8

  O1="00000000"; O2="00000000"; O3="00000000"; O4="00000000"
  O5="00000000"; O6="00000000"; O7="00000000"; O8="00000000"

  if [ -f "${root_file}" ]; then
    local rline _ a b c d e f g h i
    rline="$(cat "${root_file}")"
    IFS=';' read -r _ a b c d e f g h i O1 O2 O3 O4 O5 O6 O7 O8 _ <<< "${rline}"
    O1="${O1:-00000000}"
    O2="${O2:-00000000}"
    O3="${O3:-00000000}"
    O4="${O4:-00000000}"
    O5="${O5:-00000000}"
    O6="${O6:-00000000}"
    O7="${O7:-00000000}"
    O8="${O8:-00000000}"
  fi

  local images=()
  local idx ext candidate found
  for idx in 1 2 3 4 5 6 7 8; do
    found=0
    for ext in jpg jpeg png JPG JPEG PNG; do
      candidate="${sky_src}/${idx}.${ext}"
      if [ -f "${candidate}" ]; then
        images+=("$(basename "${candidate}")")
        found=1
        break
      fi
    done
    if [ "${found}" -eq 0 ]; then
      images+=("missing")
    fi
  done

  local segments=( "${O1}" "${O2}" "${O3}" "${O4}" "${O5}" "${O6}" "${O7}" "${O8}" )

  {
    printf ';sky;manifest;epoch;%s;ok;\n' "${now_epoch}"
    printf ';sky;root_file;%s;\n' "${root_file}"
    printf ';sky;src;%s;\n' "${sky_src}"

    local i ep file seg hex
    for i in 0 1 2 3 4 5 6 7; do
      ep=$((i+1))
      file="${images[$i]}"
      seg="O${ep}"
      hex="${segments[$i]}"
      printf ';episode;%d;file;%s;segment;%s;hex;%s;\n' "${ep}" "${file}" "${seg}" "${hex}"
    done
  } > "${manifest}"

  log_info "wrote Ω-sky manifest → ${manifest}"
}

# --- Ω-SKY TIMELINE (COSINE CROSSFADE RING) --------------------------------

write_sky_timeline() {
  local sky_root="${SKY_ROOT:-${DLOG_ROOT}/sky}"
  local sky_src="${SKY_SRC:-${sky_root}/src}"

  ensure_dir "${sky_root}"

  local timeline="${sky_root}/sky;timeline"
  local now_epoch
  now_epoch="$(date +%s)"

  # Pull current omega_hz from flames control (if present).
  local flames_file="${DLOG_ROOT}/flames/flames;control"
  local omega_hz="0"

  if [ -f "${flames_file}" ]; then
    local oline
    oline="$(grep '^;omega;hz;' "${flames_file}" 2>/dev/null || true)"
    if [ -n "${oline}" ]; then
      # Example line:
      #   ;omega;hz;7777;cpu=heart;gpu=brain;flames;4;
      local _s0 _tag _key _val _rest
      IFS=';' read -r _s0 _tag _key _val _rest <<< "${oline}"
      omega_hz="${_val:-0}"
    fi
  fi

  # We assume episodes 1..8 exist conceptually.
  local episodes=()
  local idx
  for idx in 1 2 3 4 5 6 7 8; do
    episodes+=("${idx}")
  done
  local count=${#episodes[@]}
  local loop="true"
  local curve="cosine"   # easing hint for fluid crossfades

  {
    printf ';sky;timeline;epoch;%s;ok;\n' "${now_epoch}"
    printf ';timeline;episodes;%s;omega_hz;%s;curve;%s;loop;%s;\n' \
      "${count}" "${omega_hz}" "${curve}" "${loop}"

    local i from to
    for i in "${!episodes[@]}"; do
      from="${episodes[$i]}"
      if [ "$((i+1))" -lt "${count}" ]; then
        to="${episodes[$((i+1))]}"
      else
        to="${episodes[0]}"
      fi

      # Crossfade with 64 micro-steps, 8-beat hold, cosine curve for smoothness
      printf ';transition;from;%s;to;%s;mode;crossfade;curve;%s;steps;64;hold_beats;8;\n' \
        "${from}" "${to}" "${curve}"
    done
  } > "${timeline}"

  log_info "wrote Ω-sky timeline → ${timeline}"
}

cmd_sky() {
  local sub="${1:-status}"

  banner "refold.command sky"

  case "${sub}" in
    status|manifest|sync|timeline)
      write_sky_manifest
      write_sky_timeline

      local manifest="${DLOG_ROOT}/sky/sky;manifest"
      local timeline="${DLOG_ROOT}/sky/sky;timeline"

      if [ -f "${manifest}" ]; then
        printf 'Ω-sky manifest contents:\n\n'
        cat "${manifest}"
        echo
      else
        log_warn "sky;manifest not found at: ${manifest}"
      fi

      if [ -f "${timeline}" ]; then
        printf 'Ω-sky timeline contents:\n\n'
        cat "${timeline}"
        echo
      else
        log_warn "sky;timeline not found at: ${timeline}"
      fi
      ;;
    *)
      cat <<EOF
Usage:
  ${SCRIPT_NAME} sky           → regenerate + print Ω-sky manifest + timeline
  ${SCRIPT_NAME} sky status    → same as above
  ${SCRIPT_NAME} sky manifest  → same as above
  ${SCRIPT_NAME} sky sync      → same as above
  ${SCRIPT_NAME} sky timeline  → same as above

Semantics:
  - Looks for images under: \${SKY_SRC:-\${DLOG_ROOT}/sky/src}
  - Uses 1..8 .jpg/.jpeg/.png files as episodes 1..8.
  - Binds each episode to Ω segments O1..O8 from the 9∞ master root.
  - Builds a smooth crossfade loop 1→2→…→8→1
    with 64-step transitions and 8-beat holds,
    tuned to \`omega_hz\` from flames control,
    using a cosine easing curve for fluidity (curve=cosine).

EOF
      ;;
  esac
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

  log_info "3) Updating stack snapshot (stack-up)"
  build_stack_snapshot

  log_info "4) Updating 9∞ master root"
  write_nine_inf_root

  log_info "5) Updating Ω-dashboard snapshot"
  write_dashboard_snapshot

  log_info "6) Updating Ω-sky manifest"
  write_sky_manifest

  log_info "7) Updating Ω-sky timeline"
  write_sky_timeline

  log_info "8) (Optional) Notifying dlog.command with 'beat'"
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
  - Updated the Ω-stack snapshot at ${STACK_ROOT}/stack;universe
  - Updated the 9∞ master root under ${OMEGA_INF_ROOT}
  - Updated the Ω-dashboard at ${DLOG_ROOT}/dashboard/dashboard;status
  - Updated the Ω-sky manifest at ${DLOG_ROOT}/sky/sky;manifest
  - Updated the Ω-sky timeline at ${DLOG_ROOT}/sky/sky;timeline
  - Poked dlog.command with "beat" if the new launcher is available

EOF
}

cmd_orbit() {
  local phone="${1:-}"

  banner "refold.command orbit"

  if [ -z "${phone}" ]; then
    cat <<EOF
orbit can take an optional phone number, for example:

  ${SCRIPT_NAME} orbit 9132077554

For now it's a simple hint; use 'paint' for full visuals.
EOF
    return 0
  fi

  cat <<EOF
Orbit visualization stub for phone=${phone}

Use:
  ${SCRIPT_NAME} paint ${phone}
to see detailed lines for this phone.

EOF
}

# --- CLEANUP (STUB) ---------------------------------------------------------

cmd_cleanup() {
  banner "refold.command cleanup"

  cat <<EOF
cleanup is currently a calm stub.

It exists so dlog.command can safely call:

  ${SCRIPT_NAME} cleanup

Future ideas:
  - remove temporary artifacts,
  - rotate logs,
  - compact / archive old universe snapshots.

Right now it does nothing destructive and always exits 0.

EOF
}

# --- FLAMES (CONTROL SURFACE) ----------------------------------------------

cmd_flames() {
  local sub="${1:-status}"

  banner "refold.command flames"

  case "${sub}" in
    status)
      cat <<EOF
Ω-speakers / flames status (stub)

refold.command does not start audio itself.
dlog.command (and your Rust omega_speakers binary) are responsible
for actual sound generation.

This command is safe and side-effect free unless you call:

  ${SCRIPT_NAME} flames up
  ${SCRIPT_NAME} flames down
  ${SCRIPT_NAME} flames hz <frequencyHz>

Those only write a semicolon control file under:

  ${DLOG_ROOT}/flames/flames;control

EOF
      ;;
    up)
      ensure_dir "${DLOG_ROOT}/flames"
      local control="${DLOG_ROOT}/flames/flames;control"
      local now_epoch
      now_epoch="$(date +%s)"
      {
        printf ';flames;epoch;%s;up;ok;\n' "${now_epoch}"
        printf ';omega;hz;8888;cpu=heart;gpu=brain;flames;4;\n'
      } > "${control}"
      log_info "wrote flames control → ${control}"
      cat <<EOF
Flames "up" control written.

This does NOT start audio by itself.
Your omega_speakers / Ω-engine can watch:

  ${control}

and interpret the semicolon lines however it wants.

EOF
      ;;
    down)
      ensure_dir "${DLOG_ROOT}/flames"
      local control="${DLOG_ROOT}/flames/flames;control"
      local now_epoch
      now_epoch="$(date +%s)"
      {
        printf ';flames;epoch;%s;down;ok;\n' "${now_epoch}"
      } > "${control}"
      log_info "wrote flames control → ${control}"
      cat <<EOF
Flames "down" control written.

Engines watching the control file can treat this as:
  - fade gain to 0, or
  - safely shut off all tones.

EOF
      ;;
    hz)
      local hz="${2:-}"
      if [ -z "${hz}" ]; then
        die "usage: ${SCRIPT_NAME} flames hz <frequencyHz>"
      fi
      ensure_dir "${DLOG_ROOT}/flames"
      local control="${DLOG_ROOT}/flames/flames;control"
      local now_epoch
      now_epoch="$(date +%s)"
      {
        printf ';flames;epoch;%s;hz;ok;\n' "${now_epoch}"
        printf ';omega;hz;%s;cpu=heart;gpu=brain;flames;4;\n' "${hz}"
      } > "${control}"
      log_info "wrote flames control → ${control}"
      cat <<EOF
Flames frequency control written for hz=${hz}.

refold.command still does not start audio.
Rust omega_speakers (or any Ω-engine) can read:

  ${control}

and re-tune itself accordingly.

EOF
      ;;
    *)
      cat <<EOF
flames subcommand not yet implemented: ${sub}

Supported:

  ${SCRIPT_NAME} flames
  ${SCRIPT_NAME} flames status
  ${SCRIPT_NAME} flames up
  ${SCRIPT_NAME} flames down
  ${SCRIPT_NAME} flames hz <frequencyHz>

All are safe (no direct audio), and only write a control file under:

  ${DLOG_ROOT}/flames/flames;control

EOF
      ;;
  esac
}

# --- HELP / MAIN DISPATCH ---------------------------------------------------

show_help() {
  banner "refold.command help"
  cat <<EOF
Usage:
  ${SCRIPT_NAME} ping
  ${SCRIPT_NAME} api
  ${SCRIPT_NAME} scan
  ${SCRIPT_NAME} paint [phone]
  ${SCRIPT_NAME} kube <subcommand> [args...]
  ${SCRIPT_NAME} universe <phone> <label>
  ${SCRIPT_NAME} status <phone> <label>
  ${SCRIPT_NAME} pair <phone>
  ${SCRIPT_NAME} beat
  ${SCRIPT_NAME} orbit [phone]
  ${SCRIPT_NAME} cleanup
  ${SCRIPT_NAME} stack-up [phone]
  ${SCRIPT_NAME} root
  ${SCRIPT_NAME} dashboard
  ${SCRIPT_NAME} flames [status|up|down|hz <freq>]
  ${SCRIPT_NAME} sky [status|manifest|sync|timeline]

Notes:
  - This script never calls start.command.
  - dlog.command is assumed to live on the Desktop and is the
    new canonical launcher (override via \$DLOG_COMMAND).
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
    cleanup)
      cmd_cleanup "$@"
      ;;
    stack-up)
      cmd_stack_up "$@"
      ;;
    root)
      cmd_root "$@"
      ;;
    dashboard)
      cmd_dashboard "$@"
      ;;
    flames)
      cmd_flames "$@"
      ;;
    sky)
      cmd_sky "$@"
      ;;
    *)
      log_error "unknown command: ${cmd}"
      show_help
      exit 1
      ;;
  esac
}

main "$@"
