cmd_sky_play() {
  banner "refold.command sky play"

  local sky_root="${SKY_ROOT:-${DLOG_ROOT}/sky}"
  local timeline="${sky_root}/sky;timeline"
  local stream="${sky_root}/sky;stream"

  # Make sure timeline exists and is fresh.
  if [ ! -f "${timeline}" ]; then
    log_warn "Ω-sky timeline missing; regenerating via write_sky_timeline..."
    write_sky_manifest
    write_sky_timeline
  fi

  # Header example:
  # ;sky;timeline;epoch;1764315620;ok;
  # ;timeline;episodes;8;omega_hz;7777;curve;cosine;loop;true;
  local header episodes omega_hz curve loop

  header="$(grep '^;timeline;episodes;' "${timeline}" 2>/dev/null || true)"
  if [ -z "${header}" ]; then
    log_warn "Ω-sky timeline header missing; regenerating."
    write_sky_manifest
    write_sky_timeline
    header="$(grep '^;timeline;episodes;' "${timeline}" 2>/dev/null || true)"
  fi

  # Field map (semicolon-separated):
  #  1: ""        2: timeline   3: episodes 4: 8
  #  5: omega_hz  6: 7777       7: curve    8: cosine
  #  9: loop     10: true
  episodes="$(printf '%s\n' "${header}" | awk -F';' '{print $4}')"
  omega_hz="$(printf '%s\n' "${header}" | awk -F';' '{print $6}')"
  curve="$(printf '%s\n' "${header}" | awk -F';' '{print $8}')"
  loop="$(printf '%s\n' "${header}" | awk -F';' '{print $10}')"

  [ -z "${episodes}" ] && episodes=8
  [ -z "${omega_hz}" ] && omega_hz=7777
  [ -z "${curve}" ] && curve=cosine
  [ -z "${loop}" ] && loop=true

  # Map ω to a safe CLI update period:
  # - use 1/ω if it's not insane
  # - clamp to a reasonable minimum to avoid burning CPU
  local period
  if printf '%s\n' "${omega_hz}" | grep -Eq '^[0-9]+$' && [ "${omega_hz}" -gt 0 ] 2>/dev/null; then
    period="$(awk "BEGIN { p = 1/${omega_hz}; if (p < 0.02) p = 0.02; print p }")"
  else
    period="0.1"
  fi

  log_info "Ω-sky play: episodes=${episodes} ω_hz=${omega_hz} curve=${curve} loop=${loop}"

  local tick=0
  local from to phase now

  while true; do
    # transition index [0..episodes-1]
    from=$(( (tick % episodes) + 1 ))
    to=$(( (from % episodes) + 1 ))

    # 64-step phase within the current transition, emitted as 0.000–0.984
    phase="$(awk "BEGIN { printf \"%.3f\", (${tick} % 64)/64 }")"
    now="$(date +%s)"

    {
      printf ';sky;stream;epoch;%s;from;%s;to;%s;phase;%s;omega_hz;%s;curve;%s;\n' \
        "${now}" "${from}" "${to}" "${phase}" "${omega_hz}" "${curve}"
    } > "${stream}"

    # Single-line HUD on stderr
    printf '[Ω-sky] crossfade %s→%s ✦ phase %s / 1.000\r' "${from}" "${to}" "${phase}" >&2

    tick=$((tick+1))
    sleep "${period}"
  done
}
