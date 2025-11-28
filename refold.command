# === Ω-SPEAKERS BRICK ====================================================
cmd_speakers() {
  local action="${1:-run}"
  local crate="omega_speakers"
  local flames_control="$FLAMES_ROOT/flames;control"
  local sky_stream="$SKY_ROOT/sky;stream"
  local bridge="$DESKTOP/start.command"

  if [[ ! -d "$DLOG_ROOT/$crate" ]]; then
    log_warn "Ω-speakers crate missing → $DLOG_ROOT/$crate"
    log_warn "Run: cd $DLOG_ROOT && cargo new $crate --bin"
    return 1
  fi

  # --- NPC Bridge auto-rebuild ------------------------------------------
  if [[ ! -f "$bridge" ]]; then
    log_warn "Missing $bridge — creating minimal bridge..."
    cat > "$bridge" <<'EOF'
#!/bin/bash
# === Ω-NPC Engine Bridge ===
# Triggered by omega_speakers to relay events or sound state.

echo "[Ω-NPC Bridge] Linking Ω-speakers with DLOG.GOLD universe..."
echo "[Ω-NPC Bridge] $(date)"
exit 0
EOF
    chmod +x "$bridge"
  fi
  # ----------------------------------------------------------------------

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
      log_info "Running Ω-speakers via cargo run -p $crate"
      log_info "  FLAMES_CONTROL → $flames_control"
      log_info "  SKY_STREAM     → $sky_stream"
      log_info "  NPC_BRIDGE     → $bridge"
      OMEGA_ROOT="$DLOG_ROOT" \
      DLOG_ROOT="$DLOG_ROOT" \
      FLAMES_CONTROL="$flames_control" \
      SKY_STREAM="$sky_stream" \
      NPC_BRIDGE="$bridge" \
      cargo run -p "$crate"
      ;;
    *)
      log_warn "Unknown speakers action: $action"
      ;;
  esac
  popd >/dev/null
}
