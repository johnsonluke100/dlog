#!/usr/bin/env bash
set -euo pipefail

PROJECT="dlog-gold"
DOMAIN="dlog.gold"
SERVICE="dlog-gold-app"
REGION="us-central1"

banner() {
  printf '\n=== 🌟 DLOG.GOLD CLOUD (%s) 🌟 ===\n\n' "$1"
}

case "${1-}" in
  status)
    banner "STATUS"
    echo "[dns] dig ${DOMAIN} (A):"
    dig "${DOMAIN}" +short || echo "(dig A failed)"

    echo
    echo "[dns] dig ${DOMAIN} (AAAA):"
    dig AAAA "${DOMAIN}" +short || echo "(dig AAAA failed)"

    echo
    echo "[run] domain-mapping:"
    gcloud beta run domain-mappings describe --domain "${DOMAIN}" \
      --format="value(status.conditions[].type,status.conditions[].status,status.conditions[].message)" \
      || echo "(no mapping yet)"
    ;;
  deploy)
    banner "DEPLOY"
    gcloud config set project "${PROJECT}"
    gcloud config set run/platform managed
    gcloud config set run/region "${REGION}"

    gcloud run deploy "${SERVICE}" \
      --source . \
      --region="${REGION}" \
      --platform=managed \
      --allow-unauthenticated
    ;;
  *)
    cat <<EOF
Usage: ./cloud.command <status|deploy>

  status  – show DNS + Cloud Run domain-mapping status for ${DOMAIN}
  deploy  – build & deploy current dir to Cloud Run (${SERVICE})
EOF
    ;;
esac
