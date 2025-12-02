#!/usr/bin/env bash
set -euo pipefail

PROJECT="dlog-gold"
DOMAINS=("dlog.gold" "goldengold.gold" "nedlog.gold" "locks.gold" "minepool.gold")
SERVICE="dlog-gold-app"
REGION="us-east1"

banner() {
  printf '\n=== 🌟 DLOG.GOLD CLOUD (%s) 🌟 ===\n\n' "$1"
}

case "${1-}" in
  status)
    banner "STATUS"
    for domain in "${DOMAINS[@]}"; do
      echo "--- ${domain} ---"
      echo "[dns] dig ${domain} (A):"
      dig "${domain}" +short || echo "(dig A failed)"

      echo
      echo "[dns] dig ${domain} (AAAA):"
      dig AAAA "${domain}" +short || echo "(dig AAAA failed)"

      echo
      echo "[run] domain-mapping:"
      gcloud beta run domain-mappings describe --domain "${domain}" \
        --format="value(status.conditions[].type,status.conditions[].status,status.conditions[].message)" \
        || echo "(no mapping yet)"
      echo
    done
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
      --allow-unauthenticated \
      --port=8080
    ;;
  *)
    cat <<EOF
Usage: ./cloud.command <status|deploy>

  status  – show DNS + Cloud Run domain-mapping status for ${DOMAINS[*]}
  deploy  – build & deploy current dir to Cloud Run (${SERVICE}, ${REGION})
EOF
    ;;
esac
