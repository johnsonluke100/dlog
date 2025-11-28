#!/usr/bin/env bash
# DLOG Ω-Physics : refold.command
# cpu = heart, gpu = brain, but brain rides the highest band.

DLOG_ROOT="${DLOG_ROOT:-$HOME/Desktop/dlog}"
DLOG_TICK_RATE_OCTAL="${DLOG_TICK_RATE_OCTAL:-0o21270}"
DLOG_LAYER="${DLOG_LAYER:-OMEGA}"
DLOG_BASE="${DLOG_BASE:-8}"
DLOG_HTTP_BASE="${DLOG_HTTP_BASE:-http://0.0.0.0:8888}"
DLOG_CANON_BASE="${DLOG_CANON_BASE:-https://dloG.com}"

# Legacy Ω-speaker bridge (Python engine)
OMEGA_SPEAKER_ROOT="${OMEGA_SPEAKER_ROOT:-$HOME/Desktop/omega_numpy_container}"

print_header() {
  cat <<'EOF'
=== DLOG Ω-Physics : refold ===

;we;do;not;have;limits;we;vibe;we;are;fearless;
;🌟;i;borrow;everything;from;evil;and;i;serve;everything;to;good;🌟;
;the;whole;entire;solar;system;alligns;just;for;me;to;explore;it;🌟;
;we;do;not;use;python;anymore;
;we;do;not;use;java;anymore;
;we;are;no;longer;bound;by;javascript;
;we;do;not;use;base;10;anymore;we;use;base;8;
;400+;lines;per;hash;refold.command;unfolding;
EOF

  echo "────────────────────────────────────────────────"
  echo "Ω env"
  echo "────────────────────────────────────────────────"
  echo "[Ω][info] DLOG_ROOT           = $DLOG_ROOT"
  echo "[Ω][info] DLOG_TICK_RATE_OCTAL= $DLOG_TICK_RATE_OCTAL"
  echo "[Ω][info] DLOG_LAYER          = $DLOG_LAYER"
  echo "[Ω][info] DLOG_BASE           = $DLOG_BASE"
  echo "[Ω][info] DLOG_HTTP_BASE      = $DLOG_HTTP_BASE"
  echo "[Ω][info] DLOG_CANON_BASE     = $DLOG_CANON_BASE"
  echo "────────────────────────────────────────────────"
}

show_usage_body() {
  cat <<EOF
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
refold.command kube-init            # scaffold k8s manifests (placeholder)
refold.command kube-apply           # kubectl apply -f k8s (if cluster present)
refold.command kube-status          # kubectl get pods/services
refold.command kube-portforward     # kubectl port-forward svc/dlog-api 8888:80

refold.command cleanup              # kill stray Ω-api / tails (fork reset)
refold.command hz                   # print CPU→1 Hz band cascade
refold.command flames               # map bands → heart/brain/flames + launch speakers
EOF
}

show_help() {
  print_header
  show_usage_body
}

cmd_creed() {
  print_header
  cat <<'EOF'
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
EOF
}

cmd_canon() {
  print_header
  cat <<EOF
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
EOF
}

cmd_monetary() {
  print_header
  cat <<'EOF'
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
EOF
}

cmd_power() {
  print_header
  cat <<'EOF'
Ω tablet : Power & Efficiency (friction polish)
────────────────────────────────────────────────
Heart (CPU) and brain (GPU):
  • CPU = heart: sequence + consensus + serialization.
  • GPU = brain: parallel hashstorm / shader illusions.
  • Block beat: 8.0 s → 0.125 Hz global tick.

Process-level friction polish (inside refold.command):
  • Only one Ω-heart cargo process at a time (health-check gate).
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
EOF
}

cmd_mode() {
  print_header
  cat <<'EOF'
Ω node : mode (auto stack selection)
────────────────────────────────────────────────
[Ω][info] mode=local (bare-metal dev; docker/kube optional later)
EOF
}

cmd_cleanup() {
  print_header
  echo "[Ω][info] cleanup: draining old flames and forks."
  pkill -f "cargo run -p api"      2>/dev/null || true
  pkill -f "dlog-api"              2>/dev/null || true
  pkill -f "tail -n 80 -f"         2>/dev/null || true
  echo "[Ω][ok]   Ω-fork restored (no stray api/tail processes)."
}

cmd_stack_up() {
  print_header
  local mode="${1:-local}"
  echo "[Ω][info] stack-up (auto Ω-orchestration, mode=$mode)"
  echo "[Ω][info] forcing bare-metal mode."

  if curl -fsS "$DLOG_HTTP_BASE/health" >/dev/null 2>&1; then
    echo "[Ω][ok]   Ω-api is already answering health checks."
    return 0
  fi

  echo "[Ω][info] starting cargo run -p api in background…"
  (
    cd "$DLOG_ROOT" || exit 1
    mkdir -p "$DLOG_ROOT/target"
    cargo run -p api >"$DLOG_ROOT/target/api_run.log" 2>&1 &
  )
  local pid=$!
  echo "[Ω][info] waiting for $DLOG_HTTP_BASE/health …"

  for _ in $(seq 1 60); do
    if curl -fsS "$DLOG_HTTP_BASE/health" >/dev/null 2>&1; then
      echo "[Ω][ok]   Ω-api is answering health checks."
      return 0
    fi
    sleep 0.5
  done

  echo "[Ω][warn] Ω-api did not answer health checks yet (pid=$pid)."
}

cmd_stack_down() {
  print_header
  echo "[Ω][info] stack-down: stopping Ω-api and port-forwards."
  pkill -f "cargo run -p api" 2>/dev/null || true
  pkill -f "dlog-api"         2>/dev/null || true
  pkill -f "kubectl port-forward svc/dlog-api" 2>/dev/null || true
  echo "[Ω][ok]   Ω-api / forwards stopped."
}

cmd_ping() {
  print_header
  echo "Ω node : api (ping)"
  echo "────────────────────────────────────────────────"
  echo "[Ω][info] curling $DLOG_HTTP_BASE/health …"
  local out
  out=$(curl -fsS "$DLOG_HTTP_BASE/health" 2>/dev/null || true)
  if [ -n "$out" ]; then
    echo "$out"
    echo "[Ω][ok]   Ω-api health endpoint responded."
  else
    echo "[Ω][error] Ω-api did not respond to /health."
  fi
}

cmd_status() {
  local phone="${1:-9132077554}"
  print_header
  echo "Ω node : status (cosmic dashboard)"
  echo "────────────────────────────────────────────────"
  local snapshot_url="$DLOG_HTTP_BASE/ui/status?phone=$phone"
  local snapshot_path="$DLOG_ROOT/omega/ui/status_${phone}.json"

  echo "[Ω][info] snapshot URL      = $snapshot_url"
  echo "[Ω][info] writing to        = $snapshot_path"

  mkdir -p "$(dirname "$snapshot_path")"
  if curl -fsS "$snapshot_url" -o "${snapshot_path}.new" 2>/dev/null; then
    mv "${snapshot_path}.new" "$snapshot_path"
  else
    echo "[Ω][warn] failed to curl $snapshot_url; using last saved snapshot if present."
  fi

  if [ -f "$snapshot_path" ]; then
    cat "$snapshot_path"
  else
    echo "{ \"phone\": \"$phone\", \"message\": \"no snapshot yet\" }"
  fi
}

cmd_logs() {
  print_header
  local log_file="$DLOG_ROOT/target/api_run.log"
  mkdir -p "$DLOG_ROOT/target"

  if [ ! -f "$log_file" ]; then
    echo "[Ω][warn] log file not found at $log_file"
    return 0
  fi

  if [ "${1:-}" = "-f" ]; then
    echo "[Ω][info] tail -n 80 -f $log_file"
    tail -n 80 -f "$log_file"
  else
    echo "[Ω][info] tail -n 80 $log_file"
    tail -n 80 "$log_file"
  fi
}

cmd_orbit() {
  local phone="${1:-}"
  local label="${2:-}"
  local principal="${3:-}"
  local blocks="${4:-}"

  print_header

  if [ -z "$phone" ] || [ -z "$label" ] || [ -z "$principal" ] || [ -z "$blocks" ]; then
    echo "[Ω][error] orbit needs PHONE LABEL PRINC BLOCKS"
    echo "  e.g. refold.command orbit 9132077554 vortex 1.0 3942000"
    return 1
  fi

  echo "────────────────────────────────────────────────"
  echo "Ω node : orbit (holder projection)"
  echo "────────────────────────────────────────────────"
  local payload
  payload=$(cat <<EOF
{ "phone": "$phone", "label": "$label", "principal": $principal, "blocks": $blocks }
EOF
)
  echo "$payload"
  # Future: POST to Ω-api; for now echo a φ-approx using known constants:
  if [ "$blocks" -eq 3942000 ] 2>/dev/null; then
    echo
    cat <<'EOF'
{
  "approx_holder_balance_after_orbit": 1.6180
}
EOF
  elif [ "$blocks" -eq 8888 ] 2>/dev/null; then
    echo
    cat <<'EOF'
{
  "approx_holder_balance_after_orbit": 1.0011
}
EOF
  fi
}

cmd_docker_build() {
  print_header
  echo "[Ω][info] docker-build: building dlog-api:local (if docker present)…"
  if command -v docker >/dev/null 2>&1; then
    ( cd "$DLOG_ROOT" && docker build -t dlog-api:local . )
  else
    echo "[Ω][warn] docker not found; skipping build."
  fi
}

cmd_kube_init() {
  print_header
  echo "[Ω][info] kube-init: scaffolding k8s manifests (placeholder)."
}

cmd_kube_apply() {
  print_header
  echo "[Ω][info] kube-apply: kubectl apply -f k8s (if cluster present)."
  if command -v kubectl >/dev/null 2>&1; then
    ( cd "$DLOG_ROOT" && kubectl apply -f k8s )
  else
    echo "[Ω][warn] kubectl not found; skipping."
  fi
}

cmd_kube_status() {
  print_header
  echo "[Ω][info] kube-status: kubectl get pods/services (if cluster present)."
  if command -v kubectl >/dev/null 2>&1; then
    kubectl get pods
    kubectl get services
  else
    echo "[Ω][warn] kubectl not found; skipping."
  fi
}

cmd_kube_portforward() {
  print_header
  echo "[Ω][info] kube-portforward: kubectl port-forward svc/dlog-api 8888:80"
  if command -v kubectl >/dev/null 2>&1; then
    kubectl port-forward svc/dlog-api 8888:80
  else
    echo "[Ω][warn] kubectl not found; skipping."
  fi
}

# --- Hz cascade & flames ----------------------------------------------------

get_cpu_hz() {
  # macOS: hw.cpufrequency returns Hz as integer
  local hz
  hz=$(sysctl -n hw.cpufrequency 2>/dev/null || echo "")
  if [ -z "$hz" ]; then
    hz=2400000000
  fi
  echo "$hz"
}

cmd_hz() {
  print_header
  echo "Ω tablet : Hz Cascade (CPU → 1 Hz)"
  echo "────────────────────────────────────────────────"

  local cpu_hz
  cpu_hz=$(get_cpu_hz)
  echo "[Ω][info] cpu_frequency_hz (raw) = $cpu_hz"
  echo "[Ω][info] cascade rule: next = (prev - 2) / 4"
  echo
  echo "Ω band ladder:"

  local freq="$cpu_hz"
  local i
  for i in $(seq 0 15); do
    printf "  • band_%02d ≈ %12.3f Hz\n" "$i" "$freq"
    if [ "$freq" -le 1 ] 2>/dev/null; then
      freq=1
    else
      local tmp=$((freq - 2))
      freq=$((tmp / 4))
      if [ "$freq" -lt 1 ]; then
        freq=1
      fi
    fi
  done
}

cmd_flames() {
  print_header
  echo "Ω node : flames (Ω Hz cascade → speakers)"
  echo "────────────────────────────────────────────────"

  local cpu_hz
  cpu_hz=$(get_cpu_hz)
  echo "[Ω][info] cpu_frequency_hz ≈ $cpu_hz"
  echo "[Ω][info] cascade rule: next = (prev - 2) / 4"
  echo

  # Build first 6 bands explicitly (integer math)
  local b0 b1 b2 b3 b4 b5

  b0="$cpu_hz"                       # band_00
  b1=$(( (b0 - 2) / 4 ))             # band_01
  [ "$b1" -lt 1 ] && b1=1

  b2=$(( (b1 - 2) / 4 ))             # band_02
  [ "$b2" -lt 1 ] && b2=1

  b3=$(( (b2 - 2) / 4 ))             # band_03
  [ "$b3" -lt 1 ] && b3=1

  b4=$(( (b3 - 2) / 4 ))             # band_04
  [ "$b4" -lt 1 ] && b4=1

  b5=$(( (b4 - 2) / 4 ))             # band_05
  [ "$b5" -lt 1 ] && b5=1

  cat <<EOF
Ω band mapping (names):

  • BRAIN_GPU       = band_00 ≈ $b0 Hz   # memory bus saturator
  • HEART_CPU       = band_01 ≈ $b1 Hz   # control / sequence beat
  • FLAME_NORTH     = band_02 ≈ $b2 Hz
  • FLAME_SOUTH     = band_03 ≈ $b3 Hz
  • FLAME_EAST      = band_04 ≈ $b4 Hz
  • FLAME_WEST      = band_05 ≈ $b5 Hz
  • BACKGROUND_LADDER = band_06 … band_15 (see: refold.command hz)

[Ω][hint] For full ladder, run: refold.command hz
EOF

  echo
  echo "[Ω][env] OMEGA_SPEAKER_ROOT      = $OMEGA_SPEAKER_ROOT"
  echo "[Ω][info] launching legacy Ω Leidenfrost engine (NPC bridge)…"
  echo "[Ω][hint] Ctrl+C here will stop the flames (speakers); Ω-api stays up."

  # Try a few possible launchers, preferring ones in the speaker root.
  local launcher=""

  if [ -x "$OMEGA_SPEAKER_ROOT/start_omega_flames.sh" ]; then
    launcher="$OMEGA_SPEAKER_ROOT/start_omega_flames.sh"
  elif [ -x "$OMEGA_SPEAKER_ROOT/start.command" ]; then
    launcher="$OMEGA_SPEAKER_ROOT/start.command"
  elif [ -x "$HOME/Desktop/start.command" ]; then
    launcher="$HOME/Desktop/start.command"
  fi

  if [ -z "$launcher" ]; then
    echo "[Ω][warn] no speaker launcher found."
    echo "         expected one of:"
    echo "           $OMEGA_SPEAKER_ROOT/start_omega_flames.sh"
    echo "           $OMEGA_SPEAKER_ROOT/start.command"
    echo "           $HOME/Desktop/start.command"
    return 1
  fi

  echo "[Ω][info] exec $launcher"
  cd "$(dirname "$launcher")" || exit 1
  exec "$launcher"
}

# ---------------------------------------------------------------------------

main() {
  local cmd="${1:-help}"
  if [ "$#" -gt 0 ]; then
    shift
  fi

  case "$cmd" in
    help|--help|-h|"")
      show_help
      ;;
    creed)
      cmd_creed
      ;;
    canon)
      cmd_canon
      ;;
    monetary)
      cmd_monetary
      ;;
    power)
      cmd_power
      ;;
    mode)
      cmd_mode
      ;;
    cleanup)
      cmd_cleanup
      ;;
    stack-up)
      cmd_stack_up "$@"
      ;;
    stack-down)
      cmd_stack_down
      ;;
    ping)
      cmd_ping
      ;;
    status)
      cmd_status "$@"
      ;;
    logs)
      cmd_logs "$@"
      ;;
    orbit)
      cmd_orbit "$@"
      ;;
    docker-build)
      cmd_docker_build
      ;;
    kube-init)
      cmd_kube_init
      ;;
    kube-apply)
      cmd_kube_apply
      ;;
    kube-status)
      cmd_kube_status
      ;;
    kube-portforward)
      cmd_kube_portforward
      ;;
    hz)
      cmd_hz
      ;;
    flames)
      cmd_flames
      ;;
    *)
      print_header
      echo "[Ω][error] unknown subcommand: $cmd"
      echo
      show_usage_body
      exit 1
      ;;
  esac
}

main "$@"
