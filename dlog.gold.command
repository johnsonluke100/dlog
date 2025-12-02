#!/usr/bin/env bash
set -euo pipefail

PROJECT="dlog-gold"
SERVICE="dlog-gold-app"
REGION="us-central1"

DOMAIN="${1:-dlog.gold}"

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

echo
echo "=== 🌀 DLOG DOMAINS – frictionless cert watcher 🌀 ==="
echo "Target domain: ${DOMAIN}"
echo

require_cloud_dns

# Align gcloud context
gcloud config set project "${PROJECT}" >/dev/null
gcloud config set run/platform managed >/dev/null
gcloud config set run/region "${REGION}" >/dev/null

echo "[dns] A records for ${DOMAIN}:"
dig "${DOMAIN}" +short || echo "(dig A failed)"
echo
echo "[dns] AAAA records for ${DOMAIN}:"
dig AAAA "${DOMAIN}" +short || echo "(dig AAAA failed)"
echo

echo "[run] Current domain-mapping conditions:"
gcloud beta run domain-mappings describe --domain "${DOMAIN}" \
  --format="table(status.conditions[].type,status.conditions[].status,status.conditions[].message)" \
  || {
    echo "⚠️  No domain mapping yet for ${DOMAIN}"
    exit 1
  }

echo
echo "=== 🧪 Watching for Ready=True + CertificateProvisioned=True ==="
echo "(Ctrl+C any time – the universe keeps working either way)"
echo

while :; do
  READY=$(gcloud beta run domain-mappings describe --domain "${DOMAIN}" \
    --format='value(status.conditions[?type="Ready"].status)' 2>/dev/null || echo "")
  CERT=$(gcloud beta run domain-mappings describe --domain "${DOMAIN}" \
    --format='value(status.conditions[?type="CertificateProvisioned"].status)' 2>/dev/null || echo "")

  TS=$(date +"%H:%M:%S")
  echo "[${TS}] Ready=${READY:-?}  Cert=${CERT:-?}"

  if [[ "${READY}" == "True" && "${CERT}" == "True" ]]; then
    echo
    echo "🟢 dlog.gold is FULLY LIVE on Cloud Run → https://${DOMAIN}"
    echo "   (service: ${SERVICE} @ region: ${REGION})"
    echo
    break
  fi

  sleep 15
done
