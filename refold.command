# === Ω-SPEAKERS BRICK ====================================================
cmd_speakers() {
  local action="${1:-run}"
  local crate="omega_speakers"
  local flames_control="$FLAMES_ROOT/flames;control"
  local sky_stream="$SKY_ROOT/sky;stream"

  if [[ ! -d "$DLOG_ROOT/$crate" ]]; then
    log_warn "Ω-speakers crate missing → $DLOG_ROOT/$crate"
    log_warn "Run: cd $DLOG_ROOT && cargo new $crate --bin"
    return 1
  fi

  pushd "$DLOG_ROOT" >/dev/null
  case "$action" in
    build)
      log_info "Building Ω-speakers via cargo build..."
      OMEGA_ROOT="$DLOG_ROOT" \
      DLOG_ROOT="$DLOG_ROOT" \
      FLAMES_CONTROL="$flames_control" \
      SKY_STREAM="$sky_stream" \
      cargo build -p "$crate"
      ;;
    run|start)
      log_info "Running Ω-speakers (self-contained Ω engine)"
      log_info "  FLAMES_CONTROL → $flames_control"
      log_info "  SKY_STREAM     → $sky_stream"

      OMEGA_ROOT="$DLOG_ROOT" \
      DLOG_ROOT="$DLOG_ROOT" \
      FLAMES_CONTROL="$flames_control" \
      SKY_STREAM="$sky_stream" \
      cargo run -p "$crate" --release
      ;;
    *)
      log_warn "Unknown speakers action: $action"
      ;;
  esac
  popd >/dev/null
}
