# --- Ω-SPEAKERS ENGINE -------------------------------------------------
cmd_speakers() {
  local action="${1:-run}"
  local crate="omega_speakers"

  local desktop="${DESKTOP:-$HOME/Desktop}"
  local dlog_root="${DLOG_ROOT:-$desktop/dlog}"
  local flames_control="$dlog_root/flames/flames;control"
  local sky_stream="$dlog_root/sky/sky;stream"

  if [[ ! -d "$dlog_root" ]]; then
    log_warn "DLOG_ROOT not found at: $dlog_root"
    return 1
  fi

  if [[ ! -d "$dlog_root/$crate" ]]; then
    log_warn "Ω-speakers crate missing at: $dlog_root/$crate"
    log_warn "Hint: cd $dlog_root && cargo new $crate --bin"
    return 1
  fi

  pushd "$dlog_root" >/dev/null
  case "$action" in
    build)
      log_info "Building Ω-speakers via cargo build…"
      OMEGA_ROOT="$dlog_root" \
      DLOG_ROOT="$dlog_root" \
      FLAMES_CONTROL="$flames_control" \
      SKY_STREAM="$sky_stream" \
      cargo build -p "$crate"
      ;;
    run|start)
      log_info "Running Ω-speakers via cargo run -p $crate"
      log_info "  FLAMES_CONTROL → $flames_control"
      log_info "  SKY_STREAM     → $sky_stream"
      log_info "Ctrl+C will stop the Ω-engine."
      OMEGA_ROOT="$dlog_root" \
      DLOG_ROOT="$dlog_root" \
      FLAMES_CONTROL="$flames_control" \
      SKY_STREAM="$sky_stream" \
      cargo run -p "$crate"
      ;;
    *)
      log_warn "Unknown speakers action: $action"
      log_warn "Use: speakers run | speakers build"
      ;;
  esac
  popd >/dev/null
}

# --- add to main case near bottom ---
  speakers)
    shift
    cmd_speakers "$@"
    ;;
