#!/usr/bin/env bash
# DLOG Ω-Physics : refold.command
# cpu=heart; gpu=brain; omega=8888hz; four;flames;rise;

set -euo pipefail
IFS=$'\n\t'

# ─────────────────────────────────────────────────
# Ω root discovery
# ─────────────────────────────────────────────────
_dlog_default_root="$HOME/Desktop/dlog"

if [[ -n "${DLOG_ROOT:-}" ]]; then
  DLOG_ROOT="$DLOG_ROOT"
else
  _script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
  if [[ -f "$_script_dir/dlog.toml" ]]; then
    DLOG_ROOT="$_script_dir"
  else
    DLOG_ROOT="$_dlog_default_root"
  fi
fi
export DLOG_ROOT

: "${DLOG_TICK_RATE_OCTAL:=0o21270}"
: "${DLOG_LAYER:=OMEGA}"
: "${DLOG_BASE:=8}"
: "${DLOG_HTTP_BASE:=http://0.0.0.0:8888}"
: "${DLOG_CANON_BASE:=https://dloG.com}"

mkdir -p "$DLOG_ROOT/target"

# default bridge to your old python flame engine (NPC bridge)
: "${OMEGA_SPEAKER_ROOT:=$HOME/Desktop/omega_numpy_container}"

# ─────────────────────────────────────────────────
# Ω header / env
# ─────────────────────────────────────────────────
omega_header() {
  cat << 'EOF'
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
EOF
  echo "[Ω][info] DLOG_ROOT           = $DLOG_ROOT"
  echo "[Ω][info] DLOG_TICK_RATE_OCTAL= $DLOG_TICK_RATE_OCTAL"
  echo "[Ω][info] DLOG_LAYER          = $DLOG_LAYER"
  echo "[Ω][info] DLOG_BASE           = $DLOG_BASE"
  echo "[Ω][info] DLOG_HTTP_BASE      = $DLOG_HTTP_BASE"
  echo "[Ω][info] DLOG_CANON_BASE     = $DLOG_CANON_BASE"
  echo "────────────────────────────────────────────────"
}

omega_usage() {
  cat << 'EOF'
Ω usage
────────────────────────────────────────────────
refold.command creed                # stone creed
refold.command canon                # Canon Spec v1 stone tablet + doc URL
refold.command monetary             # φ-flavored monetary grout
refold.command power                # power / efficiency tablet
refold.command hz                   # Ω Hz cascade ladder (CPU → 1 Hz)
refold.command flames               # map bands to 4 flames + launch speakers

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
EOF
}

# ─────────────────────────────────────────────────
# Ω helper: CPU Hz → bands
# ─────────────────────────────────────────────────
get_cpu_hz() {
  if [[ -n "${DLOG_CPU_HZ:-}" ]]; then
    echo "$DLOG_CPU_HZ"
    return 0
  fi

  if command -v sysctl >/dev/null 2>&1; then
    local hz
    hz="$(sysctl -n hw.cpufrequency 2>/dev/null || true)"
    if [[ -n "$hz" ]]; then
      echo "$hz"
      return 0
    fi
  fi

  # fallback for your 2.4 GHz i9
  echo "2400000000"
}

build_hz_bands() {
  # prints one band per line: "index hz"
  local cpu_hz="$1"
  local hz="$cpu_hz"
  local idx=0

  while [[ "$hz" -ge 1 ]]; do
    echo "$idx $hz"
    if [[ "$hz" -eq 1 ]]; then
      break
    fi
    hz=$(( (hz - 2) / 4 ))
    idx=$((idx + 1))
  done
}

# ─────────────────────────────────────────────────
# tablets
# ─────────────────────────────────────────────────
cmd_creed() {
  omega_header
  cat << 'EOF'
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
  omega_header
  cat << 'EOF'
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
  omega_header
  cat << 'EOF'
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
  omega_header
  cat << 'EOF'
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
EOF
}

# ─────────────────────────────────────────────────
# Ω Hz cascade + flames
# ─────────────────────────────────────────────────
cmd_hz() {
  omega_header
  echo "Ω tablet : Hz Cascade (CPU → 1 Hz)"
  echo "────────────────────────────────────────────────"

  local cpu_hz
  cpu_hz="$(get_cpu_hz)"
  echo "[Ω][info] cpu_frequency_hz (raw) = $cpu_hz"
  echo "[Ω][info] cascade rule: next = (prev - 2) / 4"
  echo
  echo "Ω band ladder:"
  build_hz_bands "$cpu_hz" | while read -r idx hz; do
    printf "  • band_%02d ≈ %s Hz\n" "$idx" "$hz"
  done
}

cmd_flames() {
  omega_header
  echo "Ω node : flames (Ω Hz cascade → speakers)"
  echo "────────────────────────────────────────────────"

  local cpu_hz
  cpu_hz="$(get_cpu_hz)"
  echo "[Ω][info] cpu_frequency_hz ≈ $cpu_hz"
  echo "[Ω][info] cascade rule: next = (prev - 2) / 4"
  echo

  # collect bands into a bash array
  local line idx hz
  local -a bands=()
  while read -r line; do
    idx="${line%% *}"
    hz="${line#* }"
    bands[idx]="$hz"
  done < <(build_hz_bands "$cpu_hz")

  local total="${#bands[@]}"
  echo "Ω band mapping (names):"
  if (( total >= 6 )); then
    printf "  • HEART_CPU       = band_00 ≈ %s Hz\n" "${bands[0]}"
    printf "  • BRAIN_GPU       = band_01 ≈ %s Hz\n" "${bands[1]}"
    printf "  • FLAME_NORTH     = band_02 ≈ %s Hz\n" "${bands[2]}"
    printf "  • FLAME_SOUTH     = band_03 ≈ %s Hz\n" "${bands[3]}"
    printf "  • FLAME_EAST      = band_04 ≈ %s Hz\n" "${bands[4]}"
    printf "  • FLAME_WEST      = band_05 ≈ %s Hz\n" "${bands[5]}"
  fi

  if (( total > 6 )); then
    printf "  • BACKGROUND_LADDER = band_06 … band_%02d\n" $((total - 1))
  fi

  echo
  echo "[Ω][hint] For full ladder, run: refold.command hz"
  echo

  echo "[Ω][env] OMEGA_SPEAKER_ROOT      = $OMEGA_SPEAKER_ROOT"
  if [[ ! -d "$OMEGA_SPEAKER_ROOT" ]]; then
    echo "[Ω][warn] speaker root not found; expected a clone of omega_numpy_container."
    echo "[Ω][hint] clone your old engine there or set OMEGA_SPEAKER_ROOT to another path."
    return 0
  fi

  echo "[Ω][info] launching legacy Ω Leidenfrost engine (NPC bridge)…"
  echo "[Ω][hint] Ctrl+C here will stop the flames (speakers); Ω-api stays up."

  if [[ -x "$HOME/Desktop/start.command" ]]; then
    "$HOME/Desktop/start.command"
  elif [[ -x "$OMEGA_SPEAKER_ROOT/start.command" ]]; then
    "$OMEGA_SPEAKER_ROOT/start.command"
  elif [[ -x "$OMEGA_SPEAKER_ROOT/start.sh" ]]; then
    "$OMEGA_SPEAKER_ROOT/start.sh"
  else
    echo "[Ω][warn] no start.command/start.sh found; launch your engine manually."
  fi
}

# ─────────────────────────────────────────────────
# Ω mode / stack / api
# ─────────────────────────────────────────────────
cmd_mode() {
  omega_header
  echo "Ω node : mode (auto-choice)"
  echo "────────────────────────────────────────────────"
  echo "[Ω][info] chosen_mode          = local"
  echo "[Ω][hint] export DLOG_MODE=docker|kube later if you want alt wiring."
}

cmd_cleanup() {
  omega_header
  echo "[Ω][info] cleanup: draining old flames and forks."
  pkill -f "cargo run -p api"        2>/dev/null || true
  pkill -f "dlog-api:local"         2>/dev/null || true
  pkill -f "tail -n 80 -f"          2>/dev/null || true
  rm -f "$DLOG_ROOT/target/api_pid"
  echo "[Ω][ok]   Ω-fork restored (no stray api/tail processes)."
}

cmd_stack_up() {
  omega_header
  echo "[Ω][info] stack-up (auto Ω-orchestration, mode=local)"
  echo "[Ω][info] forcing bare-metal mode."

  local url="$DLOG_HTTP_BASE/health"

  if curl -fsS "$url" >/dev/null 2>&1; then
    echo "[Ω][ok]   Ω-api is already answering health checks."
    return 0
  fi

  echo "[Ω][info] starting cargo run -p api in background…"
  (
    cd "$DLOG_ROOT"
    nohup cargo run -p api >>"$DLOG_ROOT/target/api_run.log" 2>&1 &
    echo $! > "$DLOG_ROOT/target/api_pid"
  )

  echo "[Ω][info] waiting for $url …"
  local tries=30
  while (( tries > 0 )); do
    if curl -fsS "$url" >/dev/null 2>&1; then
      echo "[Ω][ok]   Ω-api is answering health checks."
      return 0
    fi
    sleep 1
    tries=$((tries - 1))
  done

  echo "[Ω][warn] Ω-api health did not respond in time."
}

cmd_stack_down() {
  omega_header
  echo "[Ω][info] stack-down: stopping Ω-api + port-forward"
  pkill -f "cargo run -p api"              2>/dev/null || true
  pkill -f "dlog-api:local"               2>/dev/null || true
  pkill -f "kubectl port-forward.*dlog"   2>/dev/null || true
  rm -f "$DLOG_ROOT/target/api_pid"
  echo "[Ω][ok]   Ω-api stopped (as far as refold.command can see)."
}

cmd_ping() {
  omega_header
  echo "Ω node : api (ping)"
  echo "────────────────────────────────────────────────"
  local url="$DLOG_HTTP_BASE/health"
  echo "[Ω][info] curling $url …"
  if curl -fsS "$url"; then
    echo "[Ω][ok]   Ω-api health endpoint responded."
  else
    echo "[Ω][warn] Ω-api health endpoint did not respond."
  fi
}

cmd_status() {
  omega_header
  echo "Ω node : status (cosmic dashboard)"
  echo "────────────────────────────────────────────────"
  local phone="${1:-9132077554}"
  local url="$DLOG_HTTP_BASE/ui/status?phone=$phone"
  local out="$DLOG_ROOT/omega/ui/status_${phone}.json"

  echo "[Ω][info] snapshot URL      = $url"
  echo "[Ω][info] writing to        = $out"
  mkdir -p "$(dirname "$out")"

  if curl -fsS "$url" -o "$out.tmp" 2>/dev/null; then
    mv "$out.tmp" "$out"
  else
    echo "[Ω][warn] failed to curl $url; using last saved snapshot at $out"
  fi

  if [[ -f "$out" ]]; then
    cat "$out"
  else
    echo "[Ω][warn] no snapshot file found yet."
  fi
}

cmd_logs() {
  omega_header
  echo "Ω node : logs (Ω-api)"
  echo "────────────────────────────────────────────────"
  local follow="${1:-}"
  local log="$DLOG_ROOT/target/api_run.log"

  if [[ ! -f "$log" ]]; then
    echo "[Ω][warn] log file not found at $log"
    return 0
  fi

  if [[ "$follow" == "-f" || "$follow" == "follow" ]]; then
    echo "[Ω][info] tail -n 80 -f $log"
    tail -n 80 -f "$log"
  else
    echo "[Ω][info] tail -n 80 $log"
    tail -n 80 "$log"
  fi
}

cmd_orbit() {
  omega_header
  echo "Ω node : orbit (holder projection)"
  echo "────────────────────────────────────────────────"
  local phone="${1:-}"
  local label="${2:-}"
  local principal="${3:-}"
  local blocks="${4:-}"

  if [[ -z "$phone" || -z "$label" || -z "$principal" || -z "$blocks" ]]; then
    echo "[Ω][error] usage: refold.command orbit PHONE LABEL PRINC BLOCKS"
    return 1
  fi

  local url="$DLOG_HTTP_BASE/ui/orbit?phone=$phone&label=$label&principal=$principal&blocks=$blocks"
  echo "[Ω][info] curling $url"
  if ! curl -fsS "$url"; then
    echo "[Ω][warn] orbit calculation failed (check Ω-api)."
  fi
}

# ─────────────────────────────────────────────────
# Docker / kube stubs
# ─────────────────────────────────────────────────
cmd_docker_build() {
  omega_header
  echo "Ω node : docker-build (dlog-api:local)"
  echo "────────────────────────────────────────────────"
  if ! command -v docker >/dev/null 2>&1; then
    echo "[Ω][warn] docker not found on PATH; skipping."
    return 0
  fi
  ( cd "$DLOG_ROOT" && docker build -t dlog-api:local . )
}

cmd_kube_init() {
  omega_header
  echo "Ω node : kube-init (scaffold manifests)"
  echo "────────────────────────────────────────────────"
  echo "[Ω][hint] placeholder – add your k8s yaml under $DLOG_ROOT/k8s"
}

cmd_kube_apply() {
  omega_header
  echo "Ω node : kube-apply (kubectl apply -f k8s)"
  echo "────────────────────────────────────────────────"
  if ! command -v kubectl >/dev/null 2>&1; then
    echo "[Ω][warn] kubectl not found on PATH; skipping."
    return 0
  fi
  ( cd "$DLOG_ROOT" && kubectl apply -f k8s )
}

cmd_kube_status() {
  omega_header
  echo "Ω node : kube-status (get pods/services)"
  echo "────────────────────────────────────────────────"
  if ! command -v kubectl >/dev/null 2>&1; then
    echo "[Ω][warn] kubectl not found on PATH; skipping."
    return 0
  fi
  kubectl get pods
  kubectl get svc
}

cmd_kube_portforward() {
  omega_header
  echo "Ω node : kube-portforward (svc/dlog-api → 8888:80)"
  echo "────────────────────────────────────────────────"
  if ! command -v kubectl >/dev/null 2>&1; then
    echo "[Ω][warn] kubectl not found on PATH; skipping."
    return 0
  fi
  kubectl port-forward svc/dlog-api 8888:80
}

# ─────────────────────────────────────────────────
# main dispatch
# ─────────────────────────────────────────────────
main() {
  local sub="${1:-help}"
  shift || true

  case "$sub" in
    help|-h|--help)      omega_header; omega_usage ;;
    creed)               cmd_creed ;;
    canon)               cmd_canon ;;
    monetary)            cmd_monetary ;;
    power)               cmd_power ;;
    hz)                  cmd_hz ;;
    flames)              cmd_flames ;;

    mode)                cmd_mode ;;
    stack-up)           cmd_stack_up "$@" ;;
    stack-down)          cmd_stack_down ;;
    ping)                cmd_ping ;;
    status)              cmd_status "$@" ;;
    logs)                cmd_logs "$@" ;;
    orbit)               cmd_orbit "$@" ;;

    docker-build)        cmd_docker_build ;;
    kube-init)           cmd_kube_init ;;
    kube-apply)          cmd_kube_apply ;;
    kube-status)         cmd_kube_status ;;
    kube-portforward)    cmd_kube_portforward ;;

    cleanup)             cmd_cleanup ;;

    *)
      omega_header
      echo "[Ω][error] unknown subcommand '$sub'"
      omega_usage
      return 1
      ;;
  esac
}

main "$@"
