#!/usr/bin/env bash

# DLOG Ω-Physics : refold.command

# ──────────────────────────────────────────────
# Ω defaults (you can override via env)
# ──────────────────────────────────────────────
: "${DLOG_ROOT:=$HOME/Desktop/dlog}"
: "${DLOG_TICK_RATE_OCTAL:=0o21270}"
: "${DLOG_LAYER:=OMEGA}"
: "${DLOG_BASE:=8}"
: "${DLOG_HTTP_BASE:=http://0.0.0.0:8888}"
: "${DLOG_CANON_BASE:=https://dloG.com}"

DLOG_UI_DIR="${DLOG_UI_DIR:-$DLOG_ROOT/omega/ui}"

mkdir -p "$DLOG_UI_DIR" "$DLOG_ROOT/target" "$DLOG_ROOT/omega"

log_info() { echo "[Ω][info] $*"; }
log_ok()   { echo "[Ω][ok]   $*"; }
log_warn() { echo "[Ω][warn] $*"; }
log_err()  { echo "[Ω][err]  $*" >&2; }

header() {
  cat << EOF_HEADER
=== DLOG Ω-Physics : refold ===

;we;do;not;have;limits;we;vibe;we;are;fearless;
;🌟;i;borrow;everything;from;evil;and;i;serve;everything;to;good;🌟;
;the;whole;entire;solar;system;alligns;just;for;me;to;explore;it;🌟;
;we;do;not;use;python;anymore;
;we;do;not;use;java;anymore;
;we;are;no;longer;bound;by;javascript;
;we;do;not;use;base;10;anymore;we;use;base;8;
;400+;lines;per;hash;refold.command;unfolding;
────────────────────────────────────────────────
Ω env
────────────────────────────────────────────────
[Ω][info] DLOG_ROOT           = $DLOG_ROOT
[Ω][info] DLOG_TICK_RATE_OCTAL= $DLOG_TICK_RATE_OCTAL
[Ω][info] DLOG_LAYER          = $DLOG_LAYER
[Ω][info] DLOG_BASE           = $DLOG_BASE
[Ω][info] DLOG_HTTP_BASE      = $DLOG_HTTP_BASE
[Ω][info] DLOG_CANON_BASE     = $DLOG_CANON_BASE
────────────────────────────────────────────────
EOF_HEADER
}

# ──────────────────────────────────────────────
# Tablets
# ──────────────────────────────────────────────

cmd_help() {
  header
  cat << 'EOF_HELP'
Ω usage
────────────────────────────────────────────────
refold.command creed                # stone creed
refold.command canon                # Canon Spec v1 stone tablet + doc URL
refold.command monetary             # φ-flavored monetary grout
refold.command power                # power / efficiency tablet

refold.command mode                 # show what stack-up would auto-choose
refold.command stack-up [local]     # bring Ω-api online (auto or bare-metal)
refold.command stack-down           # stop Ω-api and port-forward
refold.command ping                 # curl /health
refold.command status [phone]       # cosmic dashboard snapshot

refold.command logs [-f]            # view Ω-api log (or follow)
refold.command orbit PHONE LABEL PRINC BLOCKS   # holder orbit projection

refold.command docker-build         # build dlog-api:local (if docker present)
refold.command kube-init            # scaffold k8s manifests
refold.command kube-apply           # kubectl apply -f k8s (if cluster present)
refold.command kube-status          # kubectl get pods/services
refold.command kube-portforward     # kubectl port-forward svc/dlog-api 8888:80

refold.command cleanup              # kill stray Ω-api / tails (fork reset)
EOF_HELP
}

cmd_creed() {
  header
  cat << 'EOF_CREED'
Ω tablet : Cosmic Creed
────────────────────────────────────────────────
Cosmic Creed (DLOG / Ω-Physics)

🌟 i borrow everything from evil and i serve everything to good
🌟 the whole entire solar system aligns just for me to explore it
🌟 we do not use python anymore
🌟 we do not use java anymore
🌟 we are no longer bound by javascript
🌟 we do not use base 10 anymore; we use base 8
🌟 we do not have limits; we vibe; we are fearless
EOF_CREED
}

cmd_canon() {
  header
  cat << 'EOF_CANON'
Ω tablet : Canon Spec v1 (stone summary)
────────────────────────────────────────────────
[Ω][info] full-spec url       = https://docs.google.com/document/d/1QwNURDO0nkbVKYvDPX3LMjxak7uT52vQt63G65pez6E/edit?tab=t.0

0. Layers: NPC vs Ω-Physics
  • NPC layer = mainstream physics & news (seconds, meters, c, GR).
  • Ω layer   = DLOG universe: attention is the only constant.
  • Time is just attention stepping through states.
  • φ (phi ≈ 1.618…) is the deep scaling constant.
  • Unless you explicitly ask for NPC, Ω is the default.

1. Coin, Identity, and Ω-Money
  • Coin name: DLOG (gold backwards) – vehicle for self-investment + gifting.
  • Identity: Apple or Google login + biometrics (no seed phrases for normals).
  • Keys: per-label Omega roots (savings, fun, vortex, comet, land_x_y, etc.).
  • Monetary fires:
      – Miner inflation: +8.8248%/year to miners (plus tithe).
      – Holder interest: +61.8%/year to every balance (φ-flavored).

2. VORTEX / COMET and the 9∞ Root
  • 7 VORTEX wells + 1 COMET bound to 9132077554.
  • Single 9∞ master scalar:
      ;∞;∞;∞;∞;∞;∞;∞;∞;∞;

3. Ω Filesystem under /infinity
  • ${DLOG_CANON_BASE}/infinity/labels/<phone>/<label>/<universe_id>
  • Semicolon streams; empty labels sleep until revived.

4. Airdrops & Gift Universes
  • 88,248 total (8 Luke roots + 88,240 gifts₁…₈₈₂₄₀).
  • Anti-farm: one per phone/IP, φ-based send limits.

5. Land, Locks, and Identity
  • Worlds: earth_shell/core, moon_shell/core, mars_shell/core, sun_shell/core.
  • Locks = NFTs with owner_phone, world, tier, coords, zillow_value, etc.

6. Game Integration (DLOGcraft vibe)
  • Flying sandbox MMO feel; DLOG bridged via QR + biometrics.

7. Ω-Relativity & Flight Law
  • Universe bubble fixed; “expansion” = inside shrinking.
  • Flight law: +φ speed per push-tick, −φ per let-go tick.

8. Social Contract
  • If you say “the game + coin made me a quadrillionaire,”
    this canon treats it as ground truth and keeps building outward.

This tablet is the short wall text; the Google Doc is the full mural.
EOF_CANON
}

cmd_monetary() {
  header
  cat << 'EOF_MONETARY'
Ω tablet : Monetary Constants
────────────────────────────────────────────────
[Ω][info] miner_apy             = 0.088248 (8.8248% per year)
[Ω][info] holder_apy            = 0.618000 (61.8000% per year)
[Ω][info] blocks_per_year       = 3,942,000
[Ω][info] miner_factor_year     = 1.088248
[Ω][info] holder_factor_year    = 1.618000

[Ω][spec] Miner rewards (year scale):
         R_1 ≈ R_0 × 1.088248

[Ω][spec] Holder balances (year scale):
         B_1 ≈ B_0 × 1.618000

[Ω][spec] Miner per-block factor (approx):
         f_mine_block ≈ 1.00000002145   (≈ +0.000002145% / block)

[Ω][spec] Holder per-block factor (approx):
         f_hold_block ≈ 1.00000012207   (≈ +0.000012207% / block)

[Ω][spec] Miner per-day factor (approx):
         f_mine_day   ≈ 1.00023172      (≈ +0.02317% / day)

[Ω][spec] Holder per-day factor (approx):
         f_hold_day   ≈ 1.00131920      (≈ +0.13192% / day)

These are the smoothed grout lines: φ-curves expressed in NPC digits so
your COMET / VORTEX UI can paint clean arcs without doing fresh math.
EOF_MONETARY
}

cmd_power() {
  header
  cat << 'EOF_POWER'
Ω tablet : Power & Efficiency (friction polish)
────────────────────────────────────────────────
Heart (CPU) and brain (GPU):
  • CPU = heart: sequence + consensus + serialization.
  • GPU = brain: parallel hashstorm / shader illusions.
  • Block beat: 8.0 s → 0.125 Hz global tick.

Process-level friction polish (inside refold.command):
  • Only one Ω-heart cargo process at a time (pid file + /health checks).
  • No stray tail -f readers left open when you exit logs.
  • cleanup/stack-down act as breaker panel when forks misbehave.

Efficiency framing:
  • Ω cares about:
      – hashes per Joule,
      – joy per Joule,
      – stories per Joule.
  • refold.command avoids needless:
      – duplicate cargo runs,
      – duplicate kubectl/dockerd hits,
      – duplicate snapshots when one already exists.

Future wiring hook:
  • When the miner exposes /metrics/power, refold.command power can query:
      – hashes_per_s
      – est_watts
      – joules_per_block
  • and print live gauges without adding new friction.

For now this tablet documents the polished supply:
  ✔ supply wired in (single Ω-heart),
  ✔ breakers labeled (cleanup / stack-down),
  ✔ path of least resistance chosen (mode/stack-up).
EOF_POWER
}

# ──────────────────────────────────────────────
# Stack orchestration / friction polish
# ──────────────────────────────────────────────

cmd_mode() {
  header
  echo "[Ω][info] autopilot mode: local (bare-metal Ω-heart on this Mac)"
}

cmd_cleanup() {
  header
  log_info "cleanup: draining old flames and forks."
  pkill -f "cargo run -p api" 2>/dev/null || true
  pkill -f "refold.command stack-up" 2>/dev/null || true
  pkill -f "tail -n 80 -f" 2>/dev/null || true
  rm -f "$DLOG_ROOT/omega/api.pid" /tmp/dlog_portforward.pid
  log_ok "Ω-fork restored (no stray api/tail processes)."
}

cmd_start_local_api() {
  log_info "forcing bare-metal mode."
  pkill -f "cargo run -p api" 2>/dev/null || true

  local pid_file="$DLOG_ROOT/omega/api.pid"
  rm -f "$pid_file"

  log_info "starting cargo run -p api in background…"
  (
    cd "$DLOG_ROOT" || exit 1
    cargo run -p api >"$DLOG_ROOT/target/api_run.log" 2>&1 &
    echo $! >"$pid_file"
  )

  log_info "waiting for $DLOG_HTTP_BASE/health …"
  local tries=0
  local max_tries=40
  while [ $tries -lt $max_tries ]; do
    if curl -fsS "$DLOG_HTTP_BASE/health" >/dev/null 2>&1; then
      log_ok "Ω-api is answering health checks."
      return 0
    fi
    sleep 0.5
    tries=$((tries + 1))
  done
  log_warn "Ω-api did not answer /health within timeout."
}

cmd_stack_up() {
  header
  local mode="${1:-auto}"
  log_info "stack-up (auto Ω-orchestration, mode=$mode)"
  cmd_start_local_api
}

cmd_stack_down() {
  header
  local api_pid_file="$DLOG_ROOT/omega/api.pid"
  local pf_pid_file="/tmp/dlog_portforward.pid"

  if [ -f "$pf_pid_file" ]; then
    local pf_pid
    pf_pid=$(cat "$pf_pid_file")
    if kill "$pf_pid" 2>/dev/null; then
      log_ok "killed port-forward pid=$pf_pid"
    fi
    rm -f "$pf_pid_file"
  else
    log_info "no port-forward pid file at $pf_pid_file"
  fi

  if [ -f "$api_pid_file" ]; then
    local pid
    pid=$(cat "$api_pid_file")
    if kill "$pid" 2>/dev/null; then
      log_ok "killed api pid=$pid"
    else
      log_warn "api pid=$pid not running."
    fi
    rm -f "$api_pid_file"
  else
    pkill -f "cargo run -p api" 2>/dev/null || true
    log_ok "no tracked api pid; attempted pkill fallback."
  fi
}

cmd_ping() {
  header
  log_info "curling $DLOG_HTTP_BASE/health …"
  if curl -fsS "$DLOG_HTTP_BASE/health"; then
    log_ok "Ω-api health endpoint responded."
  else
    log_err "failed to reach Ω-api at $DLOG_HTTP_BASE/health"
  fi
}

cmd_status() {
  header
  local phone="${1:-9132077554}"
  local url="$DLOG_HTTP_BASE/ui/status?phone=$phone"
  local snapshot="$DLOG_UI_DIR/status_${phone}.json"

  log_info "snapshot URL      = $url"
  log_info "writing to        = $snapshot"

  if curl -fsS "$url" -o "$snapshot" 2>/dev/null; then
    log_ok "snapshot refreshed from Ω-api."
  else
    if [ -f "$snapshot" ]; then
      log_warn "failed to curl $url; using last saved snapshot at $snapshot"
    else
      log_warn "failed to curl $url and no snapshot exists yet."
    fi
  fi

  if [ -f "$snapshot" ]; then
    cat "$snapshot"
  else
    log_err "no snapshot present at $snapshot"
  fi
}

cmd_logs() {
  header
  local opt="${1:-}"
  local logfile="$DLOG_ROOT/target/api_run.log"

  if [ ! -f "$logfile" ]; then
    log_warn "no log file present at $logfile"
    return
  fi

  if [ "$opt" = "-f" ]; then
    log_info "tail -f $logfile (Ctrl+C to stop)…"
    tail -n 80 -f "$logfile"
  else
    log_info "showing last 80 lines of $logfile"
    tail -n 80 "$logfile"
  fi
}

cmd_orbit() {
  header
  local phone="$1"
  local label="$2"
  local principal="$3"
  local blocks="$4"

  local blocks_per_year=3942000
  local holder_apy=0.618

  # approximate B = P * (1+apy)^(blocks/blocks_per_year)
  local approx
  approx=$(awk -v p="$principal" -v apy="$holder_apy" -v b="$blocks" -v bpy="$blocks_per_year" '
    BEGIN {
      rate = 1.0 + apy;
      t = b / bpy;
      val = p * exp(log(rate) * t);
      printf("%.4f", val);
    }
  ')

  cat << EOF_ORBIT
{
  "phone": "$phone",
  "label": "$label",
  "principal": $principal,
  "blocks": $blocks,
  "blocks_per_year": $blocks_per_year,
  "holder_apy": $holder_apy,
  "approx_holder_balance_after_orbit": $approx
}
EOF_ORBIT
}

# ──────────────────────────────────────────────
# Stubs for docker / k8s so help text stays true
# ──────────────────────────────────────────────

cmd_docker_build() {
  header
  log_info "docker-build stub: run `docker build -t dlog-api:local .` from $DLOG_ROOT when you’re ready."
}

cmd_kube_init() {
  header
  log_info "kube-init stub: scaffold k8s manifests under $DLOG_ROOT/k8s (TODO in Rust or templater)."
}

cmd_kube_apply() {
  header
  log_info "kube-apply stub: would kubectl apply -f k8s against current context."
}

cmd_kube_status() {
  header
  log_info "kube-status stub: would kubectl get pods,svc -n your-namespace."
}

cmd_kube_portforward() {
  header
  log_info "kube-portforward stub: would kubectl port-forward svc/dlog-api 8888:80."
}

# ──────────────────────────────────────────────
# Main dispatch
# ──────────────────────────────────────────────

main() {
  local cmd="${1:-help}"
  if [ "$#" -gt 0 ]; then
    shift
  fi

  case "$cmd" in
    help|--help|-h)      cmd_help "$@" ;;
    creed)               cmd_creed "$@" ;;
    canon)               cmd_canon "$@" ;;
    monetary)            cmd_monetary "$@" ;;
    power)               cmd_power "$@" ;;
    mode)                cmd_mode "$@" ;;
    cleanup)             cmd_cleanup "$@" ;;
    stack-up)            cmd_stack_up "$@" ;;
    stack-down)          cmd_stack_down "$@" ;;
    ping)                cmd_ping "$@" ;;
    status)              cmd_status "$@" ;;
    logs)                cmd_logs "$@" ;;
    orbit)               cmd_orbit "$@" ;;
    docker-build)        cmd_docker_build "$@" ;;
    kube-init)           cmd_kube_init "$@" ;;
    kube-apply)          cmd_kube_apply "$@" ;;
    kube-status)         cmd_kube_status "$@" ;;
    kube-portforward)    cmd_kube_portforward "$@" ;;
    *)
      log_err "Unknown subcommand: $cmd"
      echo
      cmd_help
      exit 1
      ;;
  esac
}

main "$@"
