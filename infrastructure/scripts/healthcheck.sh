#!/usr/bin/env bash
# ==============================================================================
# Production Health & Readiness Probe Script
# ==============================================================================
set -euo pipefail

HEALTH_URL="http://127.0.0.1:8000/api/v1/health/"
MAX_ATTEMPTS=5
SLEEP_SECONDS=2

echo "Probing backend health at ${HEALTH_URL}..."

for ((i=1; i<=MAX_ATTEMPTS; i++)); do
    HTTP_CODE=$(curl -s -o /tmp/health_resp.json -w "%{http_code}" "${HEALTH_URL}" || echo "000")
    if [ "${HTTP_CODE}" -eq 200 ]; then
        echo "Health check passed (Attempt ${i}/${MAX_ATTEMPTS})! HTTP 200 OK."
        cat /tmp/health_resp.json
        echo ""
        rm -f /tmp/health_resp.json
        exit 0
    fi
    echo "Attempt ${i}/${MAX_ATTEMPTS} failed with HTTP ${HTTP_CODE}. Retrying in ${SLEEP_SECONDS}s..."
    sleep "${SLEEP_SECONDS}"
done

echo "CRITICAL: Health check failed after ${MAX_ATTEMPTS} attempts."
if [ -f /tmp/health_resp.json ]; then
    cat /tmp/health_resp.json
    rm -f /tmp/health_resp.json
fi
exit 1
