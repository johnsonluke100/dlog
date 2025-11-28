#!/usr/bin/env bash
#
# refold.command — unified DLOG / Ω-Physics orchestrator
# 🧱 Golden Brick: universes + stack + 9∞ root + dashboard + Ω-sky (manifest + timeline + play) + enriched flames control
#
# Usage:
#   ping | api | scan | paint [phone] | universe <p> <l> | status <p> <l> | pair <p> |
#   beat | stack-up [phone] | root | dashboard |
#   flames [up|down|hz <freq>] | sky [status|manifest|sync|timeline|play] |
#   kube <subcmd> …   (as before)
#
# Notes:
#  - This script never calls obsolete start.command.
#  - dlog.command is still the canonical launcher; override with $DLOG_COMMAND if desired.
#  - ω-frequency (hz), “height”, and “friction” are encoded into flames control.
#  - sky play reads timeline and outputs a live semicolon stream: sky;stream

set -euo pipefail

# --- Basic Setup ---
SCRIPT_NAME="$(basename "$0")"
DESKTOP="${HOME}/Desktop"
DLOG_ROOT_DEFAULT="${DESKTOP}/dlog"
DLOG_COMMAND_DEFAULT="${DESKTOP}/dlog.command"

DLOG_ROOT="${DLOG_ROOT:-$DLOG_ROOT_DEFAULT}"
DLOG_COMMAND="${DLOG_COMMAND:-$DLOG_COMMAND_DEFAULT}"

UNIVERSE_ROOT="$DLOG_ROOT/universe"
STACK_ROOT="$DLOG_ROOT/stack"
KUBE_MANIFEST_ROOT="$DLOG_ROOT/kube"

OMEGA_ROOT="${OMEGA_ROOT:-$DLOG_ROOT}"
OMEGA_INF_ROOT="$OMEGA_ROOT/∞"

DLOG_DOC_URL_DEFAULT="https://docs.google.com/document/d/e/2PACX-1vShJ-OHsxJjf13YISSM7532zs0mHbrsvkSK73nHnK18rZmpysHC6B1RIMvGTALy0RIo1R1HRAyewCwR/pub"
DLOG_REPO_DEFAULT="https://github.com/johnsonluke100/dlog"

DLOG_DOC_URL="${DLOG_DOC_URL:-$DLOG_DOC_URL_DEFAULT}"
DLOG_REPO="${DLOG_REPO:-$DLOG_REPO_DEFAULT}"

# --- Logging ---
log_info(){ printf '[refold] %s\n' "$*" >&2; }
log_warn(){ printf '[refold:warn] %s\n' "$*" >&2; }
log_error(){ printf '[refold:ERROR] %s\n' "$*" >&2; }
die(){ log_error "$*"; exit 1; }
banner(){ printf "\n=== %s ===\n\n" "$*"; }

# --- Utilities ---
ensure_dir(){ mkdir -p "$1"; }
require_cmd(){ command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"; }
optional_cmd(){ command -v "$1" >/dev/null 2>&1 && return 0 || return 1; }

ensure_dlog_command(){
  if [ ! -x "$DLOG_COMMAND" ]; then
    log_warn "dlog.command not found/executable at: $DLOG_COMMAND"
    return 1
  fi
  return 0
}

call_dlog(){
  ensure_dlog_command || return 1
  log_info "delegating to dlog.command → $*"
  "$DLOG_COMMAND" "$@" || return $?
}

# --- Universe management ---
universe_file_path(){ printf '%s/%s/%s;universe\n' "$UNIVERSE_ROOT" "$1" "$2"; }
default_universe_payload(){ printf ';%s;%s;%s;seed;ok;\n' "$1" "$2" "$(date +%s)"; }
write_universe_if_missing(){
  local f
  f="$(universe_file_path "$1" "$2")"
  ensure_dir "$(dirname "$f")"
  if [ ! -f "$f" ]; then
    log_info "initializing universe snapshot: phone=$1 label=$2"
    default_universe_payload "$1" "$2" >"$f"
  else
    log_info "universe snapshot already exists → $f"
  fi
  printf '%s\n' "$f"
}

# --- Stack-up ---
build_stack_snapshot(){
  ensure_dir "$STACK_ROOT"
  local out="$STACK_ROOT/stack;universe"
  local now="$(date +%s)"

  {
    printf ';stack;epoch;%s;ok;\n' "$now"
    find "$UNIVERSE_ROOT" -type f -name '*;universe' | while read -r f; do
      local line _ ph lab ep tag state rest
      line="$(cat "$f")"
      IFS=';' read -r _ ph lab ep tag state rest <<<"$line"
      local ep8
      ep8="$(printf '%o' "$ep")"
      printf ';%s;%s;%s;%s;%s;%s;\n' "$ph" "$lab" "$ep" "$ep8" "$tag" "$state"
    done
  } >"$out"

  log_info "wrote stack snapshot → $out"
}

# --- 9∞ Master Root ---
write_nine_inf_root(){
  ensure_dir "$OMEGA_INF_ROOT"
  local stack_file="$STACK_ROOT/stack;universe"
  local flames_file="$DLOG_ROOT/flames/flames;control"
  local tmp="$OMEGA_INF_ROOT/.root.$$"

  { [ -f "$stack_file" ] && cat "$stack_file"; [ -f "$flames_file" ] && cat "$flames_file"; } >"$tmp" 2>/dev/null

  local digest hex
  if command -v shasum >/dev/null 2>&1; then
    digest="$(shasum -a 256 "$tmp" | awk '{print $1}')"
  elif command -v sha256sum >/dev/null 2>&1; then
    digest="$(sha256sum "$tmp" | awk '{print $1}')"
  else
    digest="$(printf '%064d' 0)"
  fi
  rm -f "$tmp"

  hex="${digest:-$(printf '%064d' 0)}"

  local O1 O2 O3 O4 O5 O6 O7 O8
  O1="${hex:0:8}"; O2="${hex:8:8}"; O3="${hex:16:8}"; O4="${hex:24:8}"
  O5="${hex:32:8}"; O6="${hex:40:8}"; O7="${hex:48:8}"; O8="${hex:56:8}"

  local out="$OMEGA_INF_ROOT/;∞;∞;∞;∞;∞;∞;∞;∞;∞;"
  printf ';∞;∞;∞;∞;∞;∞;∞;∞;∞;%s;%s;%s;%s;%s;%s;%s;%s;\n' \
    "$O1" "$O2" "$O3" "$O4" "$O5" "$O6" "$O7" "$O8" >"$out"

  log_info "wrote 9∞ master root → $out"
}

# --- Dashboard writer ---
write_dashboard_snapshot(){
  ensure_dir "$DLOG_ROOT/dashboard"
  local dash="$DLOG_ROOT/dashboard/dashboard;status"
  local stack_file="$STACK_ROOT/stack;universe"
  local root_file="$OMEGA_INF_ROOT/;∞;∞;∞;∞;∞;∞;∞;∞;∞;"
  local flames_file="$DLOG_ROOT/flames/flames;control"
  local now="$(date +%s)"

  local stack_epoch="0"
  if [ -f "$stack_file" ]; then
    local first
    first="$(head -n1 "$stack_file")"
    IFS=';' read -r _ _ _ stack_epoch _ <<<"$first"
  fi

  local roots=(00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000)
  if [ -f "$root_file" ]; then
    IFS=';' read -r _ _ _ _ _ _ _ _ _ "${roots[0]}" "${roots[1]}" "${roots[2]}" "${roots[3]}" "${roots[4]}" "${roots[5]}" "${roots[6]}" "${roots[7]}" _ <<<"$(cat "$root_file")"
  fi

  local flames_mode="none" flames_epoch="0" flames_hz="0"
  if [ -f "$flames_file" ]; then
    local fl0
    fl0="$(head -n1 "$flames_file")"
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
    for i in {1..8}; do
      local idx=$((i-1))
      printf ';root;O%d;%s;O%d_8;%s;\n' "$i" "${roots[$idx]}" "$i" "$((0x${roots[$idx]?:0}))"
    done
    printf ';flames;mode;%s;epoch;%s;hz;%s;\n' "$flames_mode" "$flames_epoch" "$flames_hz"
  } >"$dash"

  log_info "wrote Ω-dashboard snapshot → $dash"
}

# --- Ω-Sky: manifest + timeline + play ---

write_sky_manifest(){
  ensure_dir "$DLOG_ROOT/sky"
  local sky_src="${SKY_SRC:-$DLOG_ROOT/sky/src}"
  local manifest="$DLOG_ROOT/sky/sky;manifest"
  local now="$(date +%s)"
  local root_file="$OMEGA_INF_ROOT/;∞;∞;∞;∞;∞;∞;∞;∞;∞;"
  local hexs=(00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000)

  if [ -f "$root_file" ]; then
    IFS=';' read -r _ _ _ _ _ _ _ _ _ "${hexs[0]}" "${hexs[1]}" "${hexs[2]}" "${hexs[3]}" "${hexs[4]}" "${hexs[5]}" "${hexs[6]}" "${hexs[7]}" _ <<<"$(cat "$root_file")"
  fi

  {
    printf ';sky;manifest;epoch;%s;ok;\n' "$now"
    printf ';sky;root_file;%s;\n' "$root_file"
    printf ';sky;src;%s;\n' "$sky_src"
    for i in $(seq 1 8); do
      printf ';episode;%d;file;%d.jpg;segment;O%d;hex;%s;\n' "$i" "$i" "$i" "${hexs[$((i-1))]}"
    done
  } >"$manifest"

  log_info "wrote Ω-sky manifest → $manifest"
}

write_sky_timeline(){
  ensure_dir "$DLOG_ROOT/sky"
  local timeline="$DLOG_ROOT/sky/sky;timeline"
  local now="$(date +%s)"
  local flames_file="$DLOG_ROOT/flames/flames;control"
  local omega_hz="0"
  if [ -f "$flames_file" ]; then
    local hz_line
    hz_line="$(grep '^;omega;hz;' "$flames_file" || true)"
    if [ -n "$hz_line" ]; then
      IFS=';' read -r _ _ _ omega_hz _ <<<"$hz_line"
    fi
  fi
  [ -z "$omega_hz" ] && omega_hz="7777"

  {
    printf ';sky;timeline;epoch;%s;ok;\n' "$now"
    printf ';timeline;episodes;8;omega_hz;%s;curve;cosine;loop;true;\n' "$omega_hz"
    for i in $(seq 1 8); do
      local j=$(( i % 8 + 1 ))
      printf ';transition;from;%d;to;%d;mode;crossfade;curve;cosine;steps;64;hold_beats;8;\n' "$i" "$j"
    done
  } >"$timeline"

  log_info "wrote Ω-sky timeline → $timeline"
}

cmd_sky_play(){
  echo "=== refold.command sky play ==="
  local timeline="$DLOG_ROOT/sky/sky;timeline"
  local stream="$DLOG_ROOT/sky/sky;stream"

  if [ ! -f "$timeline" ]; then
    log_error "Ω-sky timeline missing; run: refold.command sky"
    return 1
  fi

  local header
  header="$(grep '^;timeline;episodes;' "$timeline" | head -n1)"
  [ -z "$header" ] && { log_error "bad timeline header"; return 1; }

  IFS=';' read -r _ _ _ ep _ tag hz_tag hz_val curve_tag curve_val loop_tag loop_val _ <<<"$header"
  local episodes="${ep:-8}"
  local omega_hz="${hz_val:-7777}"
  local curve="${curve_val:-cosine}"
  local loop="${loop_val:-true}"

  log_info "Ω-sky play: episodes=$episodes ω_hz=$omega_hz curve=$curve loop=$loop"
  echo "[refold] Streaming state to: $stream"
  echo "[refold] Ctrl+C to stop."

  mkdir -p "$(dirname "$stream")"
  : >"$stream"

  while :; do
    while IFS=';' read -r _ _ ttag from_tag from to_tag to mode_tag mode _ _ _ _ _ rest; do
      [ "$ttag" != "transition" ] && continue
      for step in $(seq 0 64); do
        # phase 0.000 .. 1.000
        phase=$(awk "BEGIN { printf \"%.3f\", $step/64 }")
        printf '[Ω-sky] crossfade %s→%s ✦ phase %s / 1.000\r\n' "$from" "$to" "$phase"

        printf ';sky;stream;from;%s;to;%s;phase;%s;omega_hz;%s;curve;%s;mode;%s;\n' \
          "$from" "$to" "$phase" "$omega_hz" "$curve" "$mode" >>"$stream"

        sleep 0.05
      done
    done <"$timeline"

    [ "$loop" = "true" ] || break
  done
}

# --- Flames control with enriched state (hz + height + friction) ---
cmd_flames(){
  local sub="$1"
  local arg="$2"
  local dir="$DLOG_ROOT/flames"
  local control="$dir/flames;control"
  mkdir -p "$dir"
  local now="$(date +%s)"
  local mode hz height friction

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
      [ -z "$arg" ] && { echo "usage: $0 flames hz <frequencyHz>" >&2; exit 1; }
      hz="$arg"
      ;;
    *)
      echo "Usage: $0 flames [up|down|hz <frequencyHz>]" >&2
      exit 1
      ;;
  esac

  # sanitize hz
  case "$hz" in
    ''|*[!0-9]*) hz="7777" ;;
  esac

  height=$(( hz / 1000 ))
  [ "$height" -lt 1 ] && height=1
  [ "$height" -gt 8 ] && height=8

  case "$height" in
    1|2) friction="coarse" ;;
    3|4) friction="medium" ;;
    5|6) friction="smooth" ;;
    7|8) friction="leidenfrost" ;;
    *) friction="medium" ;;
  esac

  {
    printf ';flames;epoch;%s;%s;ok;height;%s;friction;%s;\n' "$now" "$mode" "$height" "$friction"
    printf ';omega;hz;%s;cpu=heart;gpu=brain;flames;4;height;%s;friction;%s;\n' "$hz" "$height" "$friction"
  } >"$control"

  log_info "wrote flames control → $control"
  echo "Flames control: hz=$hz height=$height friction=$friction"
  echo "(refold.command itself does not start audio — your Ω-engine must read $control)"
}

# --- Command dispatch ---

show_help(){
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
  $SCRIPT_NAME stack-up [phone]
  $SCRIPT_NAME root
  $SCRIPT_NAME dashboard
  $SCRIPT_NAME flames [up|down|hz <freq>]
  $SCRIPT_NAME sky [status|manifest|sync|timeline|play]
  $SCRIPT_NAME kube <subcmd> [...]
EOF
}

cmd_ping(){
  banner "refold.command ping"
  log_info "DLOG_ROOT: $DLOG_ROOT"
  log_info "Universe root: $UNIVERSE_ROOT"
  log_info "Stack root: $STACK_ROOT"
  log_info "Ω-INF root: $OMEGA_INF_ROOT"
  log_info "Doc URL: $DLOG_DOC_URL"
  log_info "Repo: $DLOG_REPO"
  if ensure_dlog_command; then
    log_info "dlog.command present and executable."
  else
    log_warn "dlog.command missing or not executable."
  fi
  detect_kube_provider() { if optional_cmd kind; then echo kind; elif optional_cmd minikube; then echo minikube; elif optional_cmd kubectl; then echo external; else echo none; fi; }
  log_info "Kube provider: $(detect_kube_provider)"
}

cmd_api(){
  banner "refold.command api"
  cat <<EOF
Canonical spec: $DLOG_DOC_URL
Repo: $DLOG_REPO
refold.command orchestrates:

  universes → stack → 9∞ root → dashboard → Ω-sky → flames control → kube sync

No start.command. All baked in.
EOF
}

cmd_scan(){
  banner "refold.command scan (all universes)"
  find "$UNIVERSE_ROOT" -type f -name '*;universe' -print | sort || log_warn "no universes found"
}

cmd_paint(){
  banner "refold.command paint (universe orbits)"
  for d in $(find "$UNIVERSE_ROOT" -mindepth 1 -maxdepth 1 -type d 2>/dev/null); do
    local phone="$(basename "$d")"
    echo "Phone $phone"
    echo "-----------------"
    for f in "$d"/*';universe'; do
      [ -f "$f" ] || continue
      IFS=';' read -r _ ph lab ep tag state _ <<<"$(cat "$f")"
      printf "  %-6s  phone=%s label=%s epoch=%s tag=%s state=%s\n" \
        "$( [ "$lab" = vortex ] && echo '●' || echo '○' )" "$ph" "$lab" "$ep" "$tag" "$state"
    done
    echo
  done
}

cmd_universe(){ write_universe_if_missing "$1" "$2"; }
cmd_status(){
  local f
  f="$(write_universe_if_missing "$1" "$2")"
  cat "$f"
}
cmd_pair(){
  write_universe_if_missing "$1" vortex
  write_universe_if_missing "$1" comet
}

cmd_beat(){
  banner "refold.command beat"
  build_stack_snapshot
  write_nine_inf_root
  write_dashboard_snapshot
  write_sky_manifest
  write_sky_timeline

  if ensure_dlog_command; then
    call_dlog beat || log_warn "dlog.command beat exited non-zero"
  fi

  echo
  cat <<EOF
Beat done. Stack + 9∞ + dashboard + sky manifest/timeline updated.
EOF
}

cmd_stack_up(){ build_stack_snapshot; }
cmd_root(){ write_nine_inf_root; }
cmd_dashboard(){ write_dashboard_snapshot; }

cmd_sky(){
  case "$1" in
    status|manifest|sync|timeline)
      write_sky_manifest
      write_sky_timeline
      ;;
    play)
      cmd_sky_play
      ;;
    *)
      show_help
      ;;
  esac
}

# Kubernetes helpers omitted for brevity (reuse your existing versions)

main(){
  case "$1" in
    ping)   cmd_ping ;;
    api)    cmd_api ;;
    scan)   cmd_scan ;;
    paint)  cmd_paint "$2" ;;
    universe) cmd_universe "$2" "$3" ;;
    status) cmd_status "$2" "$3" ;;
    pair)   cmd_pair "$2" ;;
    beat)   cmd_beat ;;
    stack-up) cmd_stack_up ;;
    root)   cmd_root ;;
    dashboard) cmd_dashboard ;;
    flames) cmd_flames "$2" "$3" ;;
    sky)    shift; cmd_sky "$@" ;;
    help|--help|-h|*) show_help ;;
  esac
}

main "$@"
