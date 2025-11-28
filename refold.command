#!/usr/bin/env bash
#
# refold.command — DLOG / Ω-Physics orchestrator
# next beautiful golden brick: flames + stack + 9∞ root + dashboard + Ω-sky + kube stubs
#
# This script:
#   - NEVER calls start.command (obsolete)
#   - Assumes dlog.command is the new launcher on Desktop (override via $DLOG_COMMAND)
#   - Uses base-8 flavors where it’s cute (epochs, roots)
#

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
DESKTOP="${HOME}/Desktop"

DLOG_ROOT="${DLOG_ROOT:-$DESKTOP/dlog}"
DLOG_COMMAND="${DLOG_COMMAND:-$DESKTOP/dlog.command}"

UNIVERSE_ROOT="$DLOG_ROOT/universe"
STACK_ROOT="$DLOG_ROOT/stack"
KUBE_MANIFEST_ROOT="${KUBE_MANIFEST_ROOT:-$DLOG_ROOT/kube}"
KUBE_NS="${KUBE_NS:-dlog-universe}"

OMEGA_ROOT="${OMEGA_ROOT:-$DLOG_ROOT}"
OMEGA_INF_ROOT="$OMEGA_ROOT/∞"

DLOG_DOC_URL="${DLOG_DOC_URL:-https://docs.google.com/document/d/e/2PACX-1vShJ-OHsxJjf13YISSM7532zs0mHbrsvkSK73nHnK18rZmpysHC6B1RIMvGTALy0RIo1R1HRAyewCwR/pub}"
DLOG_REPO="${DLOG_REPO:-https://github.com/johnsonluke100/dlog}"

# ---------- logging helpers ----------

log_info()  { printf '[refold] %s\n'     "$*" >&2; }
log_warn()  { printf '[refold:warn] %s\n' "$*" >&2; }
log_error() { printf '[refold:ERROR] %s\n' "$*" >&2; }
die()       { log_error "$*"; exit 1; }

banner()    { printf '\n=== %s ===\n\n' "$*"; }

ensure_dir() { mkdir -p "$1"; }

optional_cmd() { command -v "$1" >/dev/null 2>&1; }

ensure_dlog_command() {
  if [ ! -x "$DLOG_COMMAND" ]; then
    log_warn "dlog.command not found or not executable at: $DLOG_COMMAND"
    return 1
  fi
  return 0
}

call_dlog() {
  ensure_dlog_command || return 1
  log_info "delegating to dlog.command → $*"
  "$DLOG_COMMAND" "$@" || return $?
}

# ---------- tiny helpers ----------

epoch_to_octal() {
  # prints epoch in base-8
  local e="${1:-0}"
  printf '%o' "$e"
}

format_age() {
  local diff="${1:-0}"
  if [ "$diff" -lt 60 ]; then
    printf '%ss ago' "$diff"
  else
    local m=$(( diff / 60 ))
    local s=$(( diff % 60 ))
    printf '%dm %ds ago' "$m" "$s"
  fi
}

format_when() {
  local e="${1:-0}"
  # macOS date -r, fine for your machine
  date -r "$e" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || printf 'epoch=%s' "$e"
}

# ---------- universe management ----------

universe_file_path() {
  local phone="$1" label="$2"
  printf '%s/%s/%s;universe\n' "$UNIVERSE_ROOT" "$phone" "$label"
}

default_universe_payload() {
  local phone="$1" label="$2"
  local now epoch tag state
  now="$(date +%s)"
  epoch="$now"
  tag="seed"
  state="ok"
  printf ';%s;%s;%s;%s;%s;\n' "$phone" "$label" "$epoch" "$tag" "$state"
}

ensure_universe_file() {
  local phone="$1" label="$2"
  local f
  f="$(universe_file_path "$phone" "$label")"
  ensure_dir "$(dirname "$f")"
  if [ ! -f "$f" ]; then
    log_info "initializing universe snapshot: phone=$phone label=$label"
    default_universe_payload "$phone" "$label" >"$f"
  else
    log_info "universe snapshot already exists → $f"
  fi
  printf '%s\n' "$f"
}

cmd_universe() {
  local phone="${1:-}" label="${2:-}"
  [ -z "$phone" ] && die "Usage: $SCRIPT_NAME universe <phone> <label>"
  [ -z "$label" ] && die "Usage: $SCRIPT_NAME universe <phone> <label>"
  ensure_universe_file "$phone" "$label" | xargs cat
}

cmd_status() {
  local phone="${1:-}" label="${2:-}"
  [ -z "$phone" ] && die "Usage: $SCRIPT_NAME status <phone> <label>"
  [ -z "$label" ] && die "Usage: $SCRIPT_NAME status <phone> <label>"

  local f line _ p l e tag state
  f="$(ensure_universe_file "$phone" "$label")"
  line="$(cat "$f")"
  IFS=';' read -r _ p l e tag state _ <<<"$line"

  local now epoch8 when age
  now="$(date +%s)"
  epoch8="$(epoch_to_octal "$e")"
  when="$(format_when "$e")"
  age="$(format_age $(( now - e )))"

  printf "Phone : %s\n" "$p"
  printf "Label : %s\n" "$l"
  printf "Epoch : %s\n" "$e"
  printf "Epoch₈: %s\n" "$epoch8"
  printf "When  : %s\n" "$when"
  printf "Age   : %s\n" "$age"
  printf "Tag   : %s\n" "$tag"
  printf "State : %s\n\n" "$state"
  printf "Raw   : %s\n" "$line"
}

cmd_pair() {
  local phone="${1:-}"
  [ -z "$phone" ] && die "Usage: $SCRIPT_NAME pair <phone>"

  local vf cf
  vf="$(ensure_universe_file "$phone" vortex)"
  cf="$(ensure_universe_file "$phone" comet)"

  echo "------------------------------------------------------"
  echo "vortex:"
  cat "$vf"
  echo "------------------------------------------------------"
  echo "comet:"
  cat "$cf"
  echo "------------------------------------------------------"
}

cmd_scan() {
  banner "refold.command scan (all universes)"

  printf "Phone        Label        Epoch        Tag        State      File\n"
  printf "------------ ------------ ------------ ---------- ---------- ----------------\n"

  find "$UNIVERSE_ROOT" -type f -name '*;universe' 2>/dev/null | sort | while read -r f; do
    local line _ phone label epoch tag state
    line="$(cat "$f")"
    IFS=';' read -r _ phone label epoch tag state _ <<<"$line"
    printf "%-12s %-12s %-12s %-10s %-10s %s\n" \
      "$phone" "$label" "$epoch" "$tag" "$state" "$f"
  done || true
}

cmd_paint() {
  local phone_filter="${1:-}"

  banner "refold.command paint (universe orbits)"

  if [ -n "$phone_filter" ]; then
    echo "Phone $phone_filter"
    echo "------------------------------------------------------"
  fi

  local now
  now="$(date +%s)"

  find "$UNIVERSE_ROOT" -type f -name '*;universe' 2>/dev/null | sort | while read -r f; do
    local line _ phone label epoch tag state
    line="$(cat "$f")"
    IFS=';' read -r _ phone label epoch tag state _ <<<"$line"

    if [ -n "$phone_filter" ] && [ "$phone" != "$phone_filter" ]; then
      continue
    fi

    local epoch8 when age marker
    epoch8="$(epoch_to_octal "$epoch")"
    when="$(format_when "$epoch")"
    age="$(format_age $(( now - epoch )) )"
    marker="○"
    [ "$label" = "vortex" ] && marker="●"

    printf "  [%s] %s  tag=%s state=%s epoch=%s (8=%s) age=%s at %s\n" \
      "$marker" "$label" "$tag" "$state" "$epoch" "$epoch8" "$age" "$when"
  done
}

# ---------- stack snapshot ----------

build_stack_snapshot() {
  ensure_dir "$STACK_ROOT"
  local out="$STACK_ROOT/stack;universe"
  local now
  now="$(date +%s)"

  {
    printf ';stack;epoch;%s;ok;\n' "$now"
    find "$UNIVERSE_ROOT" -type f -name '*;universe' 2>/dev/null | sort | while read -r f; do
      local line _ phone label epoch tag state
      line="$(cat "$f")"
      IFS=';' read -r _ phone label epoch tag state _ <<<"$line"
      local epoch8
      epoch8="$(epoch_to_octal "$epoch")"
      printf ';%s;%s;%s;%s;%s;%s;\n' "$phone" "$label" "$epoch" "$epoch8" "$tag" "$state"
    done
  } >"$out"

  log_info "wrote stack snapshot → $out"
}

# ---------- 9∞ master root ----------

write_nine_inf_root() {
  ensure_dir "$OMEGA_INF_ROOT"
  local stack_file="$STACK_ROOT/stack;universe"
  local flames_file="$DLOG_ROOT/flames/flames;control"
  local tmp="$OMEGA_INF_ROOT/.root.$$"

  { [ -f "$stack_file" ] && cat "$stack_file"; [ -f "$flames_file" ] && cat "$flames_file"; } >"$tmp" 2>/dev/null || true

  local digest
  if optional_cmd shasum; then
    digest="$(shasum -a 256 "$tmp" | awk '{print $1}')"
  elif optional_cmd sha256sum; then
    digest="$(sha256sum "$tmp" | awk '{print $1}')"
  else
    digest="$(printf '%064d' 0)"
  fi
  rm -f "$tmp"

  [ -z "$digest" ] && digest="$(printf '%064d' 0)"

  local hex="$digest"
  local O1 O2 O3 O4 O5 O6 O7 O8
  O1="${hex:0:8}"
  O2="${hex:8:8}"
  O3="${hex:16:8}"
  O4="${hex:24:8}"
  O5="${hex:32:8}"
  O6="${hex:40:8}"
  O7="${hex:48:8}"
  O8="${hex:56:8}"

  local out="$OMEGA_INF_ROOT/;∞;∞;∞;∞;∞;∞;∞;∞;∞;"
  printf ';∞;∞;∞;∞;∞;∞;∞;∞;∞;%s;%s;%s;%s;%s;%s;%s;%s;\n' \
    "$O1" "$O2" "$O3" "$O4" "$O5" "$O6" "$O7" "$O8" >"$out"

  log_info "wrote 9∞ master root → $out"
}

# ---------- dashboard snapshot ----------

write_dashboard_snapshot() {
  ensure_dir "$DLOG_ROOT/dashboard"
  local dash="$DLOG_ROOT/dashboard/dashboard;status"
  local stack_file="$STACK_ROOT/stack;universe"
  local root_file="$OMEGA_INF_ROOT/;∞;∞;∞;∞;∞;∞;∞;∞;∞;"
  local flames_file="$DLOG_ROOT/flames/flames;control"
  local now
  now="$(date +%s)"

  local stack_epoch="0"
  if [ -f "$stack_file" ]; then
    local first
    first="$(head -n 1 "$stack_file")"
    IFS=';' read -r _ _ _ stack_epoch _ <<<"$first"
  fi

  # Initialise 8 root segments to 0
  local roots=(00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000)
  if [ -f "$root_file" ]; then
    local line r1 r2 r3 r4 r5 r6 r7 r8
    line="$(cat "$root_file")"
    # ;∞;∞;∞;∞;∞;∞;∞;∞;∞;O1;O2;O3;O4;O5;O6;O7;O8;
    IFS=';' read -r _ _ _ _ _ _ _ _ _ r1 r2 r3 r4 r5 r6 r7 r8 _ <<<"$line"
    roots=( "$r1" "$r2" "$r3" "$r4" "$r5" "$r6" "$r7" "$r8" )
  fi

  local flames_mode="none" flames_epoch="0" flames_hz="0"
  if [ -f "$flames_file" ]; then
    local fl0
    fl0="$(head -n 1 "$flames_file")"
    IFS=';' read -r _ _ _ flames_epoch flames_mode _ <<<"$fl0"
    local hz_line
    hz_line="$(grep '^;omega;hz;' "$flames_file" || true)"
    if [ -n "$hz_line" ]; then
      IFS=';' read -r _ _ _ flames_hz _ <<<"$hz_line"
    fi
  fi

  {
    printf ';dashboard;epoch;%s;ok;\n' "$now"
    printf ';stack;epoch;%s;\n' "$stack_epoch"
    local i
    for i in $(seq 1 8); do
      local idx=$(( i - 1 ))
      local hex="${roots[$idx]}"
      [ -z "$hex" ] && hex="00000000"
      # convert hex → dec → octal
      local dec="$((16#$hex))"
      local oct
      oct="$(printf '%o' "$dec")"
      printf ';root;O%d;%s;O%d_8;%s;\n' "$i" "$hex" "$i" "$oct"
    done
    printf ';flames;mode;%s;epoch;%s;hz;%s;\n' "$flames_mode" "$flames_epoch" "$flames_hz"
  } >"$dash"

  log_info "wrote Ω-dashboard snapshot → $dash"
}

# ---------- Ω-sky manifest + timeline + play ----------

write_sky_manifest() {
  ensure_dir "$DLOG_ROOT/sky"
  local sky_src="${SKY_SRC:-$DLOG_ROOT/sky/src}"
  local manifest="$DLOG_ROOT/sky/sky;manifest"
  local now
  now="$(date +%s)"
  local root_file="$OMEGA_INF_ROOT/;∞;∞;∞;∞;∞;∞;∞;∞;∞;"

  local hexs=(00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000)
  if [ -f "$root_file" ]; then
    local line r1 r2 r3 r4 r5 r6 r7 r8
    line="$(cat "$root_file")"
    IFS=';' read -r _ _ _ _ _ _ _ _ _ r1 r2 r3 r4 r5 r6 r7 r8 _ <<<"$line"
    hexs=( "$r1" "$r2" "$r3" "$r4" "$r5" "$r6" "$r7" "$r8" )
  fi

  {
    printf ';sky;manifest;epoch;%s;ok;\n' "$now"
    printf ';sky;root_file;%s;\n' "$root_file"
    printf ';sky;src;%s;\n' "$sky_src"
    local i
    for i in $(seq 1 8); do
      printf ';episode;%d;file;%d.jpg;segment;O%d;hex;%s;\n' \
        "$i" "$i" "$i" "${hexs[$((i-1))]}"
    done
  } >"$manifest"

  log_info "wrote Ω-sky manifest → $manifest"
}

write_sky_timeline() {
  ensure_dir "$DLOG_ROOT/sky"
  local timeline="$DLOG_ROOT/sky/sky;timeline"
  local now
  now="$(date +%s)"
  local flames_file="$DLOG_ROOT/flames/flames;control"
  local omega_hz="7777"

  if [ -f "$flames_file" ]; then
    local hz_line
    hz_line="$(grep '^;omega;hz;' "$flames_file" || true)"
    if [ -n "$hz_line" ]; then
      local _tag
      IFS=';' read -r _ _ _ omega_hz _ <<<"$hz_line"
      [ -z "$omega_hz" ] && omega_hz="7777"
    fi
  fi

  {
    printf ';sky;timeline;epoch;%s;ok;\n' "$now"
    printf ';timeline;episodes;8;omega_hz;%s;curve;cosine;loop;true;\n' "$omega_hz"
    local i
    for i in $(seq 1 8); do
      local j=$(( i % 8 + 1 ))
      printf ';transition;from;%d;to;%d;mode;crossfade;curve;cosine;steps;64;hold_beats;8;\n' "$i" "$j"
    done
  } >"$timeline"

  log_info "wrote Ω-sky timeline → $timeline"
}

cmd_sky_play() {
  echo "=== refold.command sky play ==="

  local sky_root="${SKY_ROOT:-${DLOG_ROOT}/sky}"
  local timeline="${sky_root}/sky;timeline"
  local stream="${sky_root}/sky;stream"

  if [ ! -f "$timeline" ]; then
    log_error "Ω-sky timeline missing; run: refold.command sky"
    return 1
  fi

  # Header we expect:
  # ;timeline;episodes;8;omega_hz;7777;curve;cosine;loop;true;
  local header
  header="$(grep '^;timeline;episodes;' "$timeline" | head -n 1 || true)"
  if [ -z "$header" ]; then
    log_error "Ω-sky timeline header missing (no ;timeline;episodes; line)"
    return 1
  fi

  local tag1 tag2 tag3 tag4 tag5
  local episodes omega_hz curve loop
  IFS=';' read -r _ tag1 tag2 episodes tag3 omega_hz tag4 curve tag5 loop _ <<<"$header"

  [ -z "$episodes" ] && episodes=8
  [ -z "$omega_hz" ] && omega_hz=7777
  [ -z "$curve" ] && curve=cosine
  [ -z "$loop" ] && loop=true

  log_info "Ω-sky play: episodes=${episodes} ω_hz=${omega_hz} curve=${curve} loop=${loop}"
  echo "[refold] Streaming state to: ${stream}"
  echo "[refold] Ctrl+C to stop."

  mkdir -p "$sky_root"
  : > "$stream"

  # Loop over transitions, streaming crossfade phases
  while :; do
    while IFS=';' read -r _ kind key_from from key_to to key_mode mode key_curve t_curve key_steps steps key_hold hold _; do
      [ "$kind" != "transition" ] && continue

      [ -z "$t_curve" ] && t_curve="$curve"
      case "$steps" in
        ''|*[!0-9]*) steps=64 ;;
      esac

      local s phase
      for (( s=0; s<=steps; s++ )); do
        phase="$(awk "BEGIN { printf \"%.3f\", $s/$steps }")"

        printf '[Ω-sky] crossfade %s→%s ✦ phase %s / 1.000\r\n' "$from" "$to" "$phase"

        printf ';sky;stream;from;%s;to;%s;phase;%s;omega_hz;%s;curve;%s;mode;%s;\n' \
          "$from" "$to" "$phase" "$omega_hz" "$t_curve" "$mode" >>"$stream"

        sleep 0.05
      done
    done < "$timeline"

    [ "$loop" = "true" ] || break
  done
}

cmd_sky() {
  local sub="${1:-}"
  case "$sub" in
    ""|status|manifest|sync|timeline)
      write_sky_manifest
      write_sky_timeline
      local manifest="$DLOG_ROOT/sky/sky;manifest"
      local timeline="$DLOG_ROOT/sky/sky;timeline"
      echo "Ω-sky manifest contents:"
      cat "$manifest"
      echo
      echo "Ω-sky timeline contents:"
      cat "$timeline"
      ;;
    play)
      cmd_sky_play
      ;;
    *)
      log_error "Unknown sky subcommand: $sub"
      ;;
  esac
}

# ---------- flames control ----------

cmd_flames() {
  local sub="${1:-}"
  local arg="${2:-}"
  local dir="$DLOG_ROOT/flames"
  local control="$dir/flames;control"
  ensure_dir "$dir"
  local now
  now="$(date +%s)"

  local mode hz
  case "$sub" in
    ""|"up")
      mode="up"
      hz="${arg:-8888}"
      ;;
    "down")
      mode="down"
      hz="${arg:-0}"
      ;;
    "hz")
      mode="hz"
      [ -z "$arg" ] && die "Usage: $SCRIPT_NAME flames hz <frequencyHz>"
      hz="$arg"
      ;;
    *)
      die "Usage: $SCRIPT_NAME flames [up|down|hz <frequencyHz>]"
      ;;
  esac

  case "$hz" in
    ''|*[!0-9]*) hz="7777" ;;
  esac

  local height friction
  height=$(( hz / 1000 ))
  [ "$height" -lt 1 ] && height=1
  [ "$height" -gt 8 ] && height=8

  case "$height" in
    1|2) friction="coarse" ;;
    3|4) friction="medium" ;;
    5|6) friction="smooth" ;;
    7|8) friction="leidenfrost" ;;
    *)   friction="medium" ;;
  esac

  {
    printf ';flames;epoch;%s;%s;ok;height;%s;friction;%s;\n' "$now" "$mode" "$height" "$friction"
    printf ';omega;hz;%s;cpu=heart;gpu=brain;flames;4;height;%s;friction;%s;\n' "$hz" "$height" "$friction"
  } >"$control"

  log_info "wrote flames control → $control"
  echo "Flames control: hz=$hz height=$height friction=$friction"
  echo "(refold.command itself does not start audio — your Ω-engine must read $control)"
}

# ---------- kube helpers (light stubs) ----------

kube_detect_provider() {
  if optional_cmd kind; then
    echo "kind"
  elif optional_cmd minikube; then
    echo "minikube"
  elif optional_cmd kubectl; then
    echo "external"
  else
    echo "none"
  fi
}

kube_sync_universes() {
  ensure_dir "$KUBE_MANIFEST_ROOT/universe"
  local outdir="$KUBE_MANIFEST_ROOT/universe"

  find "$UNIVERSE_ROOT" -type f -name '*;universe' 2>/dev/null | sort | while read -r f; do
    local line _ phone label epoch tag state
    line="$(cat "$f")"
    IFS=';' read -r _ phone label epoch tag state _ <<<"$line"
    local name="${phone}-${label}"
    local yaml="$outdir/${name}.yaml"
    {
      printf 'apiVersion: v1\nkind: ConfigMap\nmetadata:\n'
      printf '  name: dlog-universe-%s-%s\n' "$phone" "$label"
      printf '  namespace: %s\n' "$KUBE_NS"
      printf 'data:\n'
      printf '  universe: "%s"\n' "$line"
    } >"$yaml"
    log_info "wrote universe configmap manifest → $yaml"
  done
}

kube_apply_all() {
  if ! optional_cmd kubectl; then
    log_warn "kubectl not installed; skipping kube apply."
    return
  fi
  if ! kubectl config current-context >/dev/null 2>&1; then
    log_warn "kubectl is installed, but no reachable cluster."
    return
  fi
  log_info "applying manifests from $KUBE_MANIFEST_ROOT"
  kubectl apply -f "$KUBE_MANIFEST_ROOT" || log_warn "kubectl apply failed"
}

cmd_kube() {
  local sub="${1:-}"
  case "$sub" in
    provider)
      echo "Kubernetes provider: $(kube_detect_provider)"
      ;;
    sync)
      kube_sync_universes
      ;;
    apply)
      kube_apply_all
      ;;
    *)
      die "Usage: $SCRIPT_NAME kube [provider|sync|apply]"
      ;;
  esac
}

# ---------- beat / ping / api / root / dashboard ----------

cmd_ping() {
  banner "refold.command ping"
  log_info "Desktop:      $DESKTOP"
  log_info "DLOG_ROOT:    $DLOG_ROOT"
  log_info "UNIVERSE_ROOT:$UNIVERSE_ROOT"
  log_info "STACK_ROOT:   $STACK_ROOT"
  log_info "Ω-INF-ROOT:   $OMEGA_INF_ROOT"
  log_info "KUBE_NS:      $KUBE_NS"
  log_info "KUBE_MANIFEST:$KUBE_MANIFEST_ROOT"
  log_info "DLOG_DOC_URL: $DLOG_DOC_URL"
  log_info "DLOG_REPO:    $DLOG_REPO"
  if ensure_dlog_command; then
    log_info "dlog.command is present and executable."
  else
    log_warn "dlog.command missing or not executable."
  fi
  log_info "Kubernetes provider detected: $(kube_detect_provider)"
}

cmd_api() {
  banner "refold.command api"
  cat <<EOF
Canonical spec: $DLOG_DOC_URL
Repo: $DLOG_REPO

refold.command orchestrates:
  universes → stack → 9∞ master root → dashboard → Ω-sky (manifest/timeline/stream) → flames control → kube manifests

No start.command. dlog.command is the new canonical launcher.
EOF
}

cmd_stack_up() {
  build_stack_snapshot
}

cmd_root() {
  write_nine_inf_root
  local root_file="$OMEGA_INF_ROOT/;∞;∞;∞;∞;∞;∞;∞;∞;∞;"
  echo "9∞ Master Root contents:"
  [ -f "$root_file" ] && cat "$root_file"
}

cmd_dashboard() {
  write_dashboard_snapshot
  local dash="$DLOG_ROOT/dashboard/dashboard;status"
  echo "Ω-dashboard contents:"
  [ -f "$dash" ] && cat "$dash"
}

cmd_beat() {
  banner "refold.command beat"
  build_stack_snapshot
  write_nine_inf_root
  write_dashboard_snapshot
  write_sky_manifest
  write_sky_timeline
  kube_sync_universes || true
  # kube_apply_all is intentionally not automatic; keep it calm

  if ensure_dlog_command; then
    call_dlog beat || log_warn "dlog.command beat exited non-zero (or not implemented)."
  fi

  echo
  cat <<EOF
Beat complete.

This beat:
  - Updated stack snapshot at $STACK_ROOT/stack;universe
  - Updated 9∞ master root under $OMEGA_INF_ROOT
  - Updated Ω-dashboard at $DLOG_ROOT/dashboard/dashboard;status
  - Updated Ω-sky manifest + timeline under $DLOG_ROOT/sky
  - Synced universes to kube manifests under $KUBE_MANIFEST_ROOT/universe
  - Poked dlog.command with "beat" if available
EOF
}

# ---------- help / main ----------

show_help() {
  banner "refold.command help"
  cat <<EOF
Usage:
  $SCRIPT_NAME ping
  $SCRIPT_NAME api
  $SCRIPT_NAME scan
  $SCRIPT_NAME paint [phone]
  $SCRIPT_NAME universe <phone> <label>
  $SCRIPT_NAME status <phone> <label>
  $SCRIPT_NAME pair <phone>
  $SCRIPT_NAME beat
  $SCRIPT_NAME stack-up
  $SCRIPT_NAME root
  $SCRIPT_NAME dashboard
  $SCRIPT_NAME flames [up|down|hz <freq>]
  $SCRIPT_NAME sky [status|manifest|sync|timeline|play]
  $SCRIPT_NAME kube [provider|sync|apply]
EOF
}

main() {
  local cmd="${1:-}"
  case "$cmd" in
    ping)       cmd_ping ;;
    api)        cmd_api ;;
    scan)       cmd_scan ;;
    paint)      cmd_paint "${2:-}" ;;
    universe)   cmd_universe "${2:-}" "${3:-}" ;;
    status)     cmd_status  "${2:-}" "${3:-}" ;;
    pair)       cmd_pair    "${2:-}" ;;
    beat)       cmd_beat ;;
    stack-up)   cmd_stack_up ;;
    root)       cmd_root ;;
    dashboard)  cmd_dashboard ;;
    flames)     cmd_flames "${2:-}" "${3:-}" ;;
    sky)        cmd_sky "${2:-}" ;;
    kube)       cmd_kube "${2:-}" ;;
    help|--help|-h|"") show_help ;;
    *)
      log_error "Unknown command: $cmd"
      show_help
      exit 1
      ;;
  esac
}

main "$@"
