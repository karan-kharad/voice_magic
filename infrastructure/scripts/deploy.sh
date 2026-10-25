#!/usr/bin/env bash
# ==============================================================================
# Deployment Script for WhatsApp Voice Changer Backend on AWS EC2
# Usage: ./deploy.sh [BRANCH_OR_TAG]
# ==============================================================================
set -euo pipefail

APP_DIR="/var/www/whatsapp-voice/backend"
VENV_DIR="${APP_DIR}/venv"
LOG_FILE="/var/log/whatsapp-voice/deploy_$(date +%Y%m%d_%H%M%S).log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE}"
}

log "Starting deployment sequence..."

if [ ! -d "${APP_DIR}" ]; then
    log "ERROR: Target directory ${APP_DIR} does not exist!"
    exit 1
fi

cd "${APP_DIR}"

log "Pulling latest changes from repository..."
git fetch --all --tags
TARGET="${1:-origin/main}"
git checkout -f "${TARGET}"
git pull --ff-only || true

log "Activating virtual environment and installing dependencies..."
if [ ! -d "${VENV_DIR}" ]; then
    python3 -m venv "${VENV_DIR}"
fi
"${VENV_DIR}/bin/pip" install --upgrade pip setuptools wheel
"${VENV_DIR}/bin/pip" install -r requirements/production.txt

log "Running Django database migrations..."
"${VENV_DIR}/bin/python" manage.py migrate --noinput

log "Collecting static assets..."
"${VENV_DIR}/bin/python" manage.py collectstatic --noinput

log "Validating Django deployment settings..."
"${VENV_DIR}/bin/python" manage.py check --deploy

log "Reloading Gunicorn systemd service..."
sudo systemctl reload-or-restart gunicorn

log "Performing health check verification..."
sleep 2
if /var/www/whatsapp-voice/infrastructure/scripts/healthcheck.sh; then
    log "Deployment completed successfully! Health check passed."
else
    log "CRITICAL ERROR: Health check failed! Investigate logs immediately."
    exit 1
fi
