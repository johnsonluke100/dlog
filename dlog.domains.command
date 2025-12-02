#!/usr/bin/env bash
set -euo pipefail

PROJECT="dlog-gold"
REGION="us-central1"
SERVICE="dlog-gold-app"
DOMAINS=("dlog.gold" "goldengold.gold" "nedlog.gold" "locks.gold" "minepool.gold")

subcmd="${1:-status}"

resolve_host() {
  local host="$1"
  python3 - <<'PY' "$host"
import socket, sys
target = sys.argv[1]
try:
    socket.gethostbyname(target)
except OSError:
    raise SystemExit(1)
PY
}

require_cloud_dns() {
  local failed=0
  for host in cloudresourcemanager.googleapis.com run.googleapis.com container.googleapis.com; do
    if ! resolve_host "$host"; then
      echo "[net] DNS lookup failed for $host" >&2
      failed=1
    fi
  done
  if (( failed )); then
    echo "[net] Cloud DNS unreachable—run ~/dlog/refold.command netcheck after fixing VPN/DNS." >&2
    return 1
  fi
  return 0
}

if ! require_cloud_dns; then
  exit 1
fi

gcloud config set core/project "$PROJECT" >/dev/null
gcloud config set run/platform managed >/dev/null
gcloud config set run/region "$REGION" >/dev/null

case "$subcmd" in
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
      gcloud beta run domain-mappings describe --domain "$domain" \
        --format="table(status.conditions[].type,status.conditions[].status,status.conditions[].message)"
    done
    ;;

  *)
    echo "Usage: $0 {status|map}"
    exit 1
    ;;
esac
