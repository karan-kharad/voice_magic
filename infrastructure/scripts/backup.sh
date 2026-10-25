#!/usr/bin/env bash
# ==============================================================================
# Automated Encrypted Backup Script for PostgreSQL Database
# ==============================================================================
set -euo pipefail

BACKUP_DIR="/var/backups/postgresql"
TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)
DB_NAME="whatsapp_voice"
DB_USER="wv_app_user"
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.sql.gz"
ENCRYPTED_FILE="${BACKUP_FILE}.gpg"
KEY_FILE="/etc/whatsapp-voice/backup.key"
RETENTION_DAYS=14

mkdir -p "${BACKUP_DIR}"
chmod 700 "${BACKUP_DIR}"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting automated database backup for ${DB_NAME}..."

# Export compressed dump stream
PGPASSWORD="${POSTGRES_PASSWORD:-}" pg_dump -h 127.0.0.1 -U "${DB_USER}" -d "${DB_NAME}" --no-owner --clean | gzip -9 > "${BACKUP_FILE}"

# Encrypt archive with GPG AES-256
if [ -f "${KEY_FILE}" ]; then
    gpg --symmetric --cipher-algo AES256 --batch --passphrase-file "${KEY_FILE}" -o "${ENCRYPTED_FILE}" "${BACKUP_FILE}"
    rm -f "${BACKUP_FILE}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Encrypted backup generated: ${ENCRYPTED_FILE}"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: Backup key file not found at ${KEY_FILE}. Archive left unencrypted."
fi

# Remove backups older than retention window
find "${BACKUP_DIR}" -name "${DB_NAME}_*.sql.gz*" -mtime "+${RETENTION_DAYS}" -exec rm -f {} \;

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backup maintenance completed successfully."
