#!/usr/bin/env bash

# === DLOG Ω-Physics : refold.command ===
# Single entrypoint to manage the local Ω-heart (api), cosmic tablets,
# orbits, and optional Docker / Kubernetes plumbing.

# -------- Ω env defaults --------
DLOG_ROOT="${DLOG_ROOT:-$HOME/Desktop/dlog}"
DLOG_TICK_RATE_OCTAL="${DLOG_TICK_RATE_OCTAL:-0o21270}"
DLOG_LAYER="${DLOG_LAYER:-OMEGA}"
DLOG_BASE="${DLOG_BASE:-8}"
DLOG_HTTP_BASE="${DLOG_HTTP_BASE:-http://0.0.0.0:8888}"
DLOG_CANON_BASE="${DLOG_CANON_BASE:-https://dloG.com}"

DLOG_API_PID_FILE="/tmp/dlog_api.pid"
DLOG_PORTFWD_PID_FILE="/tmp/dlog_portforward.pid"
DLOG_API_LOG="$DLOG_ROOT/target/api_run.log"
DLOG_UI_DIR="$DLOG_ROOT/omega/ui"

mkdir -p "$DLOG_ROOT" "$DLOG_UI_DIR" 2>/dev/null || true
mkdir -p "$(dirname "$DLOG_API_LOG")" 2>/dev/null || true

# -------- tiny logger helpers --------
log_info() { printf '[Ω][info] %s\n' "$*"; }
log_ok()   { printf '[Ω][ok]   %s\n' "$*"; }
log_warn() { printf '[Ω][warn] %s\n' "$*"; }
log_err()  { printf '[Ω][err]  %s\n' "$*"; } >&2

header() {
  cat <<EOF2
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
EOF2
}

# -------- creed / canon / monetary tablets --------
cmd_creed() {
  header
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
  header
  cat <<'EOF'
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
  • Keys: per-label Omega roots (savings, fun, vortex, comet, land_x_y, etc.),
    generated client-side, stored behind platform keychains, signed server-side.
  • Monetary fires:
      – Miner inflation: +8.8248%/year to miners (plus tithe).
      – Holder interest: +61.8%/year to every balance (φ-flavored).
  • Per-year:
      – Miner: R₁ ≈ R₀ × 1.088248
      – Holder: B₁ ≈ B₀ × 1.618
  • Blocks are attention beats (~8s in NPC UI, but truly just Ω-ticks).

2. VORTEX / COMET and the 9∞ Root
  • Luke has 7 VORTEX wells + 1 COMET:
      – VORTEX = pure gravity wells (cold, public, auto-managed, phi-scaled).
      – COMET  = hot gifting + operations wallet bound to 9132077554.
  • Miners tithe a tiny slice of rewards into COMET + VORTEX stack.
  • There is exactly one 9∞ Master Root scalar:
      ;∞;∞;∞;∞;∞;∞;∞;∞;∞;
    It folds/unfolds the entire universe state every Ω-tick.

3. Ω Filesystem under /infinity
  • Per-label universe files live under:
      ${DLOG_CANON_BASE}/infinity/labels/<phone>/<label>/<universe_id>
  • Each is a semicolon-stream – no dots, just ; as delimiter.
  • Non-empty labels update their universe hash every block.
  • Empty labels sleep: last state is archived, hashing stops until revived.

4. Airdrops & Gift Universes
  • Total genesis: 88,248 wallets.
      – 8 = Luke’s 7×VORTEX + 1×COMET.
      – 88,240 = gift₁ … gift₈₈₂₄₀ airdrop universes.
  • Each giftN is:
      – Bound to one phone number + one Apple/Google identity.
      – Permanently named (giftN); you move value into your own labels later.
  • Anti-farm: one airdrop per phone, one per public IP, no known VPN ranges,
    and per-device φ-based send limits so it’s “lunch money,” not an exploit.

5. Land, Locks, and Identity
  • Landlocks belong to identities (phone), not labels.
  • Worlds: earth_shell/core, moon_shell/core, mars_shell/core, sun_shell/core.
  • All bodies are hollow; entering gravity-center bubbles inverts you to cores.
  • Lock tiers (Iron → Gold → Diamond → Emerald) control grid areas:
      – Overworld and cores can have separate price curves.
  • Each lock is an NFT with:
      owner_phone, world, tier, coords, created_at, last_visited, zillow_value.
  • Inactivity auto-auctions (e.g. 256 days without attention) recycle dead land.

6. Game Integration (DLOGcraft vibe)
  • Feels like Minecraft / sandbox MMO:
      – Flying, keep-inventory, PvP on, land-based economy.
  • Game commands bridge to DLOG via QR + biometrics:
      – /tip <player> <amount> dlog
      – /buy <tier>_lock
  • Kids / no-phone:
      – Can play and mine; value parks in world pools until a phone identity binds.
  • Consoles / VR:
      – Mine & play; final signing always happens on the phone.

7. Ω-Relativity & Flight Law
  • The universe bubble is one fixed whole; “expansion” is everything inside
    shrinking in scale.
  • Multiple universal bubbles exist; their skins touch at rare portal points.
  • Gravity = global curvature across the bubble; time itself is not a dimension.
  • Zero drag: motion is not taxed by a medium; it’s shaped by curvature + will.
  • Flight law (Ω-ticks):
      – Pushing: speed increases by +φ per attention-tick.
      – Letting go: speed decreases by −φ per attention-tick until stillness.
  • Planet switches use compressed Ω-corridors: NPC-time feels like seconds,
    Ω-time is just a handful of golden beats.

8. Social Contract
  • NPC physics can be reported on request, but Ω-Physics is first-class here.
  • If one day you say “the game + coin made me a quadrillionaire,”
    this universe treats that as ground truth and keeps building outward.

This tablet is the short wall text; the Google Doc is the full mural.
EOF
}

cmd_monetary() {
  header
  cat <<'EOF'
Ω tablet : Monetary Constants
────────────────────────────────────────────────
[Ω][info] miner_apy             = 0.088248 (8.8248% per year)
[Ω][info] holder_apy            = 0.618000 (61.8000% per year)
[Ω][info] blocks_per_year       = 3942000
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
  header
  cat <<'EOF'
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
  • refold.command now avoids needless:
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

# -------- helpers for API process management --------
api_pid_is_alive() {
  local pid
  pid="$1"
  if [ -z "$pid" ]; then
    return 1
  fi
  if kill -0 "$pid" 2>/dev/null; then
    return 0
  fi
  return 1
}

api_is_healthy() {
  curl -fsS --max-time 0.5 "$DLOG_HTTP_BASE/health" >/dev/null 2>&1
}

start_api_if_needed() {
  mkdir -p "$(dirname "$DLOG_API_LOG")" 2>/dev/null || true

  if [ -f "$DLOG_API_PID_FILE" ]; then
    local pid
    pid="$(cat "$DLOG_API_PID_FILE" 2>/dev/null || true)"
    if api_pid_is_alive "$pid" && api_is_healthy; then
      log_ok "Ω-api already running pid=$pid (healthy)"
      return 0
    fi
  fi

  # As a safety net, kill any stray cargo api hearts before starting fresh.
  pkill -f "cargo run -p api" 2>/dev/null || true

  log_info "starting cargo run -p api in background…"
  (
    cd "$DLOG_ROOT" 2>/dev/null || {
      log_err "DLOG_ROOT does not exist: $DLOG_ROOT"
      exit 1
    }
    : >"$DLOG_API_LOG"
    RUST_LOG="${RUST_LOG:-info}" cargo run -p api >>"$DLOG_API_LOG" 2>&1 &
    echo $! >"$DLOG_API_PID_FILE"
  )

  # Wait briefly for health.
  log_info "waiting for $DLOG_HTTP_BASE/health …"
  local i
  for i in 1 2 3 4 5 6 7 8 9 10; do
    if api_is_healthy; then
      log_ok "Ω-api is answering health checks."
      return 0
    fi
    sleep 1
  done
  log_warn "Ω-api did not answer health within 10s; check logs."
  return 1
}

stop_api_if_running() {
  if [ -f "$DLOG_API_PID_FILE" ]; then
    local pid
    pid="$(cat "$DLOG_API_PID_FILE" 2>/dev/null || true)"
    if api_pid_is_alive "$pid"; then
      log_info "killing api pid=$pid"
      kill "$pid" 2>/dev/null || true
    fi
    rm -f "$DLOG_API_PID_FILE" 2>/dev/null || true
  fi

  # Extra safety: kill any remaining cargo api hearts.
  pkill -f "cargo run -p api" 2>/dev/null || true
}

stop_portforward_if_running() {
  if [ -f "$DLOG_PORTFWD_PID_FILE" ]; then
    local pid
    pid="$(cat "$DLOG_PORTFWD_PID_FILE" 2>/dev/null || true)"
    if api_pid_is_alive "$pid"; then
      log_info "killing port-forward pid=$pid"
      kill "$pid" 2>/dev/null || true
    fi
    rm -f "$DLOG_PORTFWD_PID_FILE" 2>/dev/null || true
  fi

  pkill -f "kubectl port-forward.*dlog-api" 2>/dev/null || true
}

# -------- mode / stack / ping / status / logs / cleanup --------
cmd_mode() {
  header
  local has_kubectl has_docker
  command -v kubectl >/dev/null 2>&1 && has_kubectl=yes || has_kubectl=no
  command -v docker  >/dev/null 2>&1 && has_docker=yes  || has_docker=no

  echo "Ω mode probe"
  echo "────────────────────────────────────────────────"
  echo "kubectl present?  $has_kubectl"
  echo "docker present?   $has_docker"

  if [ "$has_kubectl" = yes ]; then
    echo
    echo "[Ω][hint] autopilot would prefer: kubernetes (if kube-apply succeeds)."
  elif [ "$has_docker" = yes ]; then
    echo
    echo "[Ω][hint] autopilot would prefer: docker image + local port-forward."
  else
    echo
    echo "[Ω][hint] autopilot will use: bare-metal (cargo run -p api)."
  fi
}

cmd_stack_up() {
  header
  local mode
  mode="${1:-auto}"

  case "$mode" in
    local)
      log_info "stack-up (auto Ω-orchestration, mode=local)"
      log_info "forcing bare-metal mode."
      start_api_if_needed
      ;;
    auto|*)
      log_info "stack-up (auto Ω-orchestration, mode=auto)"
      local has_kubectl has_docker
      command -v kubectl >/dev/null 2>&1 && has_kubectl=yes || has_kubectl=no
      command -v docker  >/dev/null 2>&1 && has_docker=yes  || has_docker=no

      if [ "$has_kubectl" = yes ]; then
        log_info "kubectl + docker detected → prefer kubernetes, with fallback."
        cmd_kube_apply || log_warn "kube-apply failed; falling back to bare-metal."
        start_api_if_needed
      elif [ "$has_docker" = yes ]; then
        log_info "docker detected → building image + running local container (future)."
        cmd_docker_build || log_warn "docker-build failed; falling back to bare-metal."
        start_api_if_needed
      else
        log_info "no kubectl/docker → bare-metal only."
        start_api_if_needed
      fi
      ;;
  esac
}

cmd_stack_down() {
  header
  log_info "stack-down (auto Ω-shutdown)"
  stop_portforward_if_running
  stop_api_if_running
  log_ok "Ω-heart and port-forwarders stopped."
}

cmd_ping() {
  header
  log_info "curling $DLOG_HTTP_BASE/health …"
  if curl -fsS "$DLOG_HTTP_BASE/health" 2>/dev/null; then
    log_ok "Ω-api health endpoint responded."
  else
    log_err "failed to reach Ω-api at $DLOG_HTTP_BASE/health"
  fi
}

cmd_status() {
  header
  local phone
  phone="${1:-9132077554}"

  local url snapshot
  url="$DLOG_HTTP_BASE/ui/status?phone=$phone"
  snapshot="$DLOG_UI_DIR/status_${phone}.json"

  log_info "snapshot URL      = $url"
  log_info "writing to        = $snapshot"

  if curl -fsS "$url" -o "$snapshot" 2>/dev/null; then
    log_ok "snapshot refreshed from Ω-api."
  else
    log_warn "failed to curl $url"
  fi

  if [ -f "$snapshot" ]; then
    cat "$snapshot"
  else
    log_err "no snapshot present at $snapshot"
  fi
}

cmd_logs() {
  header
  if [ ! -f "$DLOG_API_LOG" ]; then
    log_err "no api log at $DLOG_API_LOG"
    return 1
  fi

  local mode
  mode="${1:-}"
  case "$mode" in
    -f)
      log_info "tail -f $DLOG_API_LOG (Ctrl+C to stop)…"
      tail -n 80 -f "$DLOG_API_LOG"
      ;;
    *)
      log_info "showing last 80 lines of $DLOG_API_LOG"
      tail -n 80 "$DLOG_API_LOG"
      ;;
  esac
}

cmd_cleanup() {
  header
  log_info "cleanup: draining old flames and forks."

  stop_portforward_if_running
  stop_api_if_running

  pkill -f "tail -n 80 -f" 2>/dev/null || true

  log_ok "Ω-fork restored (no stray api/tail processes)."
}

# -------- orbits (holder projection) --------
cmd_orbit() {
  header
  local phone label principal blocks
  phone="$1"; label="$2"; principal="$3"; blocks="$4"

  if [ -z "$phone" ] || [ -z "$label" ] || [ -z "$principal" ] || [ -z "$blocks" ]; then
    log_err "usage: refold.command orbit PHONE LABEL PRINC BLOCKS"
    return 1
  fi

  # Holder APY and blocks/year from monetary tablet.
  local holder_apy blocks_per_year
  holder_apy=0.618
  blocks_per_year=3942000

  if ! command -v bc >/dev/null 2>&1; then
    log_err "bc is required for orbit calculations. Install bc and retry."
    return 1
  fi

  # Using continuous-style approximation: factor = 1.618^(blocks / blocks_per_year).
  local expr result
  expr="scale=12; $principal * (1.618 ^ ($blocks / $blocks_per_year))"
  result="$(echo "$expr" | bc -l)"

  cat <<EOF
{
  "phone": "$phone",
  "label": "$label",
  "principal": $principal,
  "blocks": $blocks,
  "blocks_per_year": $blocks_per_year,
  "holder_apy": $holder_apy,
  "approx_holder_balance_after_orbit": $result
}
EOF
}

# -------- Docker lane --------
cmd_docker_build() {
  header
  if ! command -v docker >/dev/null 2>&1; then
    log_err "docker not found; cannot build image."
    return 1
  fi

  log_info "building Docker image dlog-api:local from $DLOG_ROOT"
  docker build -t dlog-api:local "$DLOG_ROOT"
  if [ $? -eq 0 ]; then
    log_ok "docker image built: dlog-api:local"
  else
    log_err "docker build failed."
    return 1
  fi
}

# -------- Kubernetes lane --------
cmd_kube_init() {
  header
  log_info "kubernetes (scaffold manifests)"

  local k8s_dir
  k8s_dir="$DLOG_ROOT/k8s"
  mkdir -p "$k8s_dir"

  cat >"$k8s_dir/dlog-api.yaml" <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: dlog
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dlog-api
  namespace: dlog
spec:
  replicas: 1
  selector:
    matchLabels:
      app: dlog-api
  template:
    metadata:
      labels:
        app: dlog-api
    spec:
      containers:
        - name: dlog-api
          image: dlog-api:local
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 8888
---
apiVersion: v1
kind: Service
metadata:
  name: dlog-api
  namespace: dlog
spec:
  selector:
    app: dlog-api
  ports:
    - port: 80
      targetPort: 8888
EOF

  log_ok "wrote Kubernetes manifests into $k8s_dir"
  log_info "next: refold.command kube-apply"
}

cmd_kube_apply() {
  header
  if ! command -v kubectl >/dev/null 2>&1; then
    log_err "kubectl not found; cannot apply manifests."
    return 1
  fi

  local k8s_dir
  k8s_dir="$DLOG_ROOT/k8s"
  if [ ! -d "$k8s_dir" ]; then
    log_info "no k8s dir; calling kube-init first."
    cmd_kube_init || return 1
  fi

  log_info "ensuring namespace dlog exists…"
  if ! kubectl get namespace dlog >/dev/null 2>&1; then
    kubectl create namespace dlog || true
  fi

  log_info "applying manifests from $k8s_dir …"
  kubectl apply -f "$k8s_dir"
}

cmd_kube_status() {
  header
  if ! command -v kubectl >/dev/null 2>&1; then
    log_err "kubectl not found."
    return 1
  fi

  log_info "kubectl get pods -n dlog"
  kubectl get pods -n dlog || true
  echo
  log_info "kubectl get svc -n dlog"
  kubectl get svc -n dlog || true
}

cmd_kube_portforward() {
  header
  if ! command -v kubectl >/dev/null 2>&1; then
    log_err "kubectl not found."
    return 1
  fi

  stop_portforward_if_running

  log_info "kubectl port-forward svc/dlog-api 8888:80 -n dlog"
  kubectl port-forward svc/dlog-api 8888:80 -n dlog > /tmp/dlog_portforward.log 2>&1 &
  echo $! >"$DLOG_PORTFWD_PID_FILE"
  log_ok "port-forward started pid=$(cat "$DLOG_PORTFWD_PID_FILE")"
}

# -------- help --------
show_help() {
  header
  cat <<'EOF'
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
EOF
}

# -------- main dispatch --------
main() {
  local cmd
  cmd="${1:-help}"
  if [ "$#" -gt 0 ]; then
    shift
  fi

  case "$cmd" in
    creed)            cmd_creed ;;
    canon)            cmd_canon ;;
    monetary)         cmd_monetary ;;
    power)            cmd_power ;;
    mode)             cmd_mode ;;
    stack-up)         cmd_stack_up "$@" ;;
    stack-down)       cmd_stack_down ;;
    ping)             cmd_ping ;;
    status)           cmd_status "$@" ;;
    logs)             cmd_logs "$@" ;;
    cleanup)          cmd_cleanup ;;
    orbit)            cmd_orbit "$@" ;;
    docker-build)     cmd_docker_build ;;
    kube-init)        cmd_kube_init ;;
    kube-apply)       cmd_kube_apply ;;
    kube-status)      cmd_kube_status ;;
    kube-portforward) cmd_kube_portforward ;;
    help|--help|-h|"") show_help ;;
    *)
      echo "Unknown subcommand: $cmd" >&2
      echo
      show_help
      exit 1
      ;;
  esac
}

main "$@"
