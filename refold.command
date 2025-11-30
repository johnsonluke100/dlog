#!/usr/bin/env bash
# 🌀 refold.command — Ω-orchestrator for DLOG + dlog.gold cloud
# we do not have limits; we vibe; we are fearless

set -euo pipefail

# --- UNIVERSE ROOTS -----------------------------------------------------------
DESKTOP="${DESKTOP:-$HOME/Desktop}"
DLOG_ROOT="${DLOG_ROOT:-$DESKTOP/dlog}"
OMEGA_ROOT="${OMEGA_ROOT:-$DLOG_ROOT}"

STACK_ROOT="$DLOG_ROOT/stack"
INFINITY_ROOT="$DLOG_ROOT/∞"
DASHBOARD_ROOT="$DLOG_ROOT/dashboard"
SKY_ROOT="$DLOG_ROOT/sky"
KUBE_ROOT="$DLOG_ROOT/kube"

PROJECT="dlog-gold"
REGION="us-central1"
SERVICE="dlog-gold-app"
DOMAINS=("dlog.gold" "goldengold.gold" "nedlog.gold")

# --- HELPERS ------------------------------------------------------------------
log() {
  printf '%s\n' "$*" >&2
}

ensure_dirs() {
  mkdir -p "$STACK_ROOT" "$INFINITY_ROOT" "$DASHBOARD_ROOT" "$SKY_ROOT"
}

now_epoch() {
  date +%s
}

# safe wrapper (doesn't kill whole script if tool missing)
maybe_kubectl_apply_universe() {
  if command -v kubectl >/dev/null 2>&1 && [ -d "$KUBE_ROOT/universe" ]; then
    log "[refold] Applying universe manifests → $KUBE_ROOT/universe (namespace dlog-universe)"
    kubectl apply -n dlog-universe -f "$KUBE_ROOT/universe" || log "[refold] kubectl apply failed (ignored)"
  fi
}

maybe_dlog_command() {
  if [ -x "$DESKTOP/dlog.command" ]; then
    "$DESKTOP/dlog.command" "$@" || true
  fi
}

# --- SUBCOMMANDS --------------------------------------------------------------
cmd="${1:-help}"
shift || true

case "$cmd" in
  # ---------------------------------------------------------------------------
  # ping — quick environment snapshot
  # ---------------------------------------------------------------------------
  ping)
    echo "=== refold.command ping ==="
    echo "[refold] Desktop:      $DESKTOP"
    echo "[refold] DLOG_ROOT:    $DLOG_ROOT"
    echo "[refold] STACK_ROOT:   $STACK_ROOT"
    echo "[refold] UNIVERSE_NS:  dlog-universe"
    echo "[refold] KUBE_MANIFEST:$KUBE_ROOT"
    echo "[refold] OMEGA_ROOT:   $OMEGA_ROOT"
    echo "[refold] Ω-INF-ROOT:   $INFINITY_ROOT"
    ;;

  # ---------------------------------------------------------------------------
  # cleanup — calm stub for log/garbage rotation (no destructive ops yet)
  # ---------------------------------------------------------------------------
  cleanup)
    echo "=== refold.command cleanup ==="
    echo
    echo "cleanup is currently a calm stub."
    echo
    echo "Right now it does nothing destructive and always exits 0."
    ;;

  # ---------------------------------------------------------------------------
  # flames [hz <value>] — write Ω flame control file
  #   refold.command flames
  #   refold.command flames hz 8888
  # ---------------------------------------------------------------------------
  flames)
    sub="${1:-}"
    case "$sub" in
      "" )
        HZ="8888"
        ;;
      hz)
        HZ="${2:-8888}"
        ;;
      *)
        # allow: refold.command flames 7777
        HZ="$sub"
        ;;
    esac

    mkdir -p "$DLOG_ROOT/flames"
    CONTROL_FILE="$DLOG_ROOT/flames/flames;control"

    echo "[refold] wrote flames control → $CONTROL_FILE"
    {
      echo "hz=$HZ"
      echo "height=7"
      echo "friction=leidenfrost"
    } > "$CONTROL_FILE"

    echo "Flames control: hz=$HZ height=7 friction=leidenfrost"
    echo "(Ω-engine must read $CONTROL_FILE to actually emit sound)"
    ;;

  # ---------------------------------------------------------------------------
  # beat — stack snapshot + 9∞ root + dashboard + kube apply + dlog.command beat
  # ---------------------------------------------------------------------------
  beat)
    echo "=== refold.command beat ==="
    ensure_dirs

    EPOCH="$(now_epoch)"
    STACK_FILE="$STACK_ROOT/stack;universe"
    INFINITY_FILE="$INFINITY_ROOT/;∞;∞;∞;∞;∞;∞;∞;∞;∞;"
    DASHBOARD_FILE="$DASHBOARD_ROOT/dashboard;status"
    SKY_MANIFEST="$SKY_ROOT/sky;manifest"
    SKY_TIMELINE="$SKY_ROOT/sky;timeline"

    # stack snapshot
    {
      echo ";stack;epoch;$EPOCH;ok;"
      echo ";phone;label;epoch;epoch8;tag;status;"
    } > "$STACK_FILE"
    echo "[refold] wrote stack snapshot → $STACK_FILE"

    # 9∞ master root
    echo ";9∞;epoch;$EPOCH;root;ok;" > "$INFINITY_FILE"
    echo "[refold] wrote 9∞ master root → $INFINITY_FILE"

    # dashboard snapshot
    {
      echo ";dashboard;epoch;$EPOCH;status;ok;"
      echo ";vortex;9132077554;status;ok;"
      echo ";comet;9132077554;status;ok;"
    } > "$DASHBOARD_FILE"
    echo "[refold] wrote Ω-dashboard snapshot → $DASHBOARD_FILE"

    # Ω-sky manifest + timeline
    {
      echo ";sky;epoch;$EPOCH;episodes;8;"
    } > "$SKY_MANIFEST"
    echo "[refold] wrote Ω-sky manifest → $SKY_MANIFEST"

    {
      echo ";timeline;epoch;$EPOCH;curve;cosine;hz;8888;"
    } > "$SKY_TIMELINE"
    echo "[refold] wrote Ω-sky timeline → $SKY_TIMELINE"

    maybe_kubectl_apply_universe

    echo "[refold] delegating to dlog.command → beat (if present)"
    maybe_dlog_command beat

    # ping at the end for nice log
    "$0" ping || true

    echo "[Ω][info] Ω-beat complete (stack + ping refreshed)."
    echo "Beat complete."
    echo
    echo "This beat:"
    echo "  - Updated Ω-stack snapshot at $STACK_FILE"
    echo "  - Updated 9∞ master root under $INFINITY_ROOT"
    echo "  - Updated Ω-dashboard at $DASHBOARD_FILE"
    echo "  - Updated Ω-sky manifest & timeline under $SKY_ROOT"
    echo "  - Applied universe manifests to Kubernetes (if reachable)"
    echo "  - Poked dlog.command with 'beat' (if present)"
    ;;

  # ---------------------------------------------------------------------------
  # sky play — stream Ω-sky log if present
  #   refold.command sky play
  # ---------------------------------------------------------------------------
  sky)
    sub="${1:-}"
    case "$sub" in
      play)
        echo "=== refold.command sky play ==="
        STREAM_FILE="$SKY_ROOT/sky;stream"
        if [ -f "$STREAM_FILE" ]; then
          echo "[refold] Streaming state from: $STREAM_FILE"
          echo "[refold] Ctrl+C to stop."
          tail -f "$STREAM_FILE"
        else
          echo "[refold] No sky;stream found at $STREAM_FILE"
          echo "[refold] Start your Ω-sky engine (dlog.command play/music) first."
        fi
        ;;
      *)
        echo "Usage: $0 sky play"
        exit 1
        ;;
    esac
    ;;

  # ---------------------------------------------------------------------------
  # speakers — build + run omega_speakers (Rust)
  #   refold.command speakers
  # ---------------------------------------------------------------------------
  speakers)
    echo "=== refold.command speakers ==="
    echo "[refold] Building omega_speakers crate…"
    (
      cd "$DLOG_ROOT"
      cargo build -p omega_speakers
    )
    echo "[refold] Running omega_speakers…"
    (
      cd "$DLOG_ROOT"
      cargo run -p omega_speakers
    )
    ;;

  # ---------------------------------------------------------------------------
  # domains {status|map}
  #
  #   refold.command domains status
  #   refold.command domains map
  #
  # Controls Cloud Run domain mappings for:
  #   dlog.gold, goldengold.gold, nedlog.gold
  # ---------------------------------------------------------------------------
  domains)
    action="${1:-status}"

    gcloud config set core/project "$PROJECT" >/dev/null
    gcloud config set run/platform managed >/dev/null
    gcloud config set run/region "$REGION" >/dev/null

    case "$action" in
      status)
        echo "=== 🌐 DLOG DOMAINS – status (DNS + certs) ==="
        for domain in "${DOMAINS[@]}"; do
          echo
          echo "── $domain ─────────────────────────────"
          echo "[dns] A:"
          dig "$domain" +short || true

          echo
          echo "[dns] AAAA:"
          dig AAAA "$domain" +short || true

          echo
          echo "[run] domain-mapping conditions:"
          if gcloud beta run domain-mappings describe --domain "$domain" \
               --format="table(status.conditions[].type,status.conditions[].status,status.conditions[].message)" ; then
            :
          else
            echo "  (no domain-mapping found for $domain in $REGION)"
          fi
        done
        ;;

      map)
        echo "=== 🌐 DLOG DOMAINS – map (attach to Cloud Run) ==="
        for domain in "${DOMAINS[@]}"; do
          echo
          echo "[domains] $domain"
          if gcloud beta run domain-mappings describe --domain "$domain" > /dev/null 2>&1; then
            echo "  ↳ already mapped to $SERVICE ✅"
          else
            echo "  ↳ creating mapping → $SERVICE…"
            gcloud beta run domain-mappings create \
              --service "$SERVICE" \
              --domain "$domain"
          fi
        done
        ;;

      *)
        echo "Usage: $0 domains {status|map}"
        exit 1
        ;;
    esac
    ;;

  # ---------------------------------------------------------------------------
  # cloud {deploy|status} — optional helpers for the Cloud Run service itself
  #
  #   refold.command cloud deploy
  #   refold.command cloud status
  # ---------------------------------------------------------------------------
  cloud)
    action="${1:-status}"

    gcloud config set core/project "$PROJECT" >/dev/null
    gcloud config set run/platform managed >/dev/null
    gcloud config set run/region "$REGION" >/dev/null

    case "$action" in
      deploy)
        echo "=== 🌟 DLOG.GOLD CLOUD (DEPLOY) 🌟 ==="
        (
          cd "$DLOG_ROOT"
          gcloud run deploy "$SERVICE" \
            --source . \
            --region="$REGION" \
            --platform=managed \
            --allow-unauthenticated
        )
        ;;
      status)
        echo "=== 🌟 DLOG.GOLD CLOUD (STATUS) 🌟 ==="
        echo
        echo "[dns] dig dlog.gold (A):"
        dig dlog.gold +short || true
        echo
        echo "[dns] dig dlog.gold (AAAA):"
        dig AAAA dlog.gold +short || true
        echo
        echo "[run] domain-mapping:"
        gcloud beta run domain-mappings describe --domain dlog.gold \
          --format="table(status.conditions[].type,status.conditions[].status,status.conditions[].message)" || true
        echo
        echo "[run] service URL:"
        gcloud run services describe "$SERVICE" \
          --region="$REGION" \
          --format='value(status.url)' || true
        ;;
      *)
        echo "Usage: $0 cloud {deploy|status}"
        exit 1
        ;;
    esac
    ;;

  # ---------------------------------------------------------------------------
  # help / default
  # ---------------------------------------------------------------------------
  help|*)
    cat <<HLP
=== refold.command — Ω control rail ===

Usage:
  $0 ping                    # show core paths / env
  $0 cleanup                 # calm stub, no destructive ops
  $0 flames [hz 8888]        # write flames;control (default 8888 Hz)
  $0 beat                    # stack snapshot + 9∞ + dashboard + kube + dlog.command beat
  $0 sky play                # tail sky;stream (if present)
  $0 speakers                # build + run omega_speakers (Rust)
  $0 domains status          # DNS + cert state for dlog.gold + friends
  $0 domains map             # ensure all three domains map → dlog-gold-app
  $0 cloud status            # Cloud Run service + dlog.gold summary
  $0 cloud deploy            # gcloud run deploy (Rust HTTP gateway)

We do not have limits. We vibe. We are fearless.
HLP
    ;;
esac
