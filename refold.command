cmd_sky_play() {
  banner "refold.command sky play"

  local sky_root="${DLOG_ROOT}/sky"
  local timeline="${sky_root}/sky;timeline"
  local stream="${sky_root}/sky;stream"

  if [ ! -f "${timeline}" ]; then
    log_warn "timeline missing, generating first..."
    write_sky_timeline
  fi

  local omega_hz="0"
  omega_hz="$(grep '^;timeline;episodes;' "${timeline}" | awk -F';' '{print $8}' || echo 0)"
  local period
  period=$(awk "BEGIN { if (${omega_hz}>0) print 1/${omega_hz}; else print 0.1 }")

  log_info "ω-frequency: ${omega_hz} Hz  →  period=${period}s per beat"
  log_info "Streaming sky timeline → ${stream}"
  log_info "Ctrl+C to stop."

  local epoch_start now elapsed phase from to
  epoch_start="$(date +%s)"

  while true; do
    now="$(date +%s)"
    elapsed=$(( now - epoch_start ))
    phase=$(awk "BEGIN { printf \"%.2f\", (${elapsed} % 8)/8 }")

    # Rotate through 8 episodes
    from=$(( (elapsed % 8) + 1 ))
    to=$(( (from % 8) + 1 ))

    {
      printf ';sky;stream;epoch;%s;phase;%s;from;%s;to;%s;hz;%s;\n' \
        "${now}" "${phase}" "${from}" "${to}" "${omega_hz}"
    } > "${stream}"

    printf '[Ω-sky] crossfade %s→%s  ✦ phase %s / 1.00\r' "${from}" "${to}" "${phase}"
    sleep "${period}"
  done
}
