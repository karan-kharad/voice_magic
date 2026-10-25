# Database Backup, Disaster Recovery & Restoration Guide

**Document ID:** DOC-OPS-002  
**Target:** PostgreSQL Database on AWS EC2 (`whatsapp_voice`)  
**Objective:** RPO < 24 Hours, RTO < 30 Minutes  

---

## 1. Automated Encrypted Backup Workflow

The automated backup script `/var/www/whatsapp-voice/infrastructure/scripts/backup.sh` executes nightly:

### Script Capabilities
1. Dumps the database using `pg_dump` in custom directory/binary format.
2. Compresses the dump stream with `gzip -9`.
3. Encrypts the archive using GnuPG AES-256 symmetric cipher with key stored in root-only keystore.
4. Generates a SHA-256 checksum for data integrity verification.
5. Deletes local backup archives older than 14 days.
6. (Optional) Synchronizes encrypted archive to an AWS S3 bucket with Object Lock / Versioning enabled.

### Testing Backup Execution Manually
```bash
sudo /var/www/whatsapp-voice/infrastructure/scripts/backup.sh
```

---

## 2. Disaster Recovery & Database Restoration

Follow this tested step-by-step procedure in case of data corruption, accidental deletion, or host failure.

### Step 1: Stop Application Ingress
Prevent concurrent writes during restoration:
```bash
sudo systemctl stop gunicorn
```

### Step 2: Locate and Decrypt the Target Backup Archive
```bash
cd /var/backups/postgresql

# List available backups
ls -lh whatsapp_voice_*.sql.gz.gpg

# Decrypt the chosen backup (e.g. yesterday's 03:00 UTC dump)
gpg --decrypt --batch --passphrase-file /etc/whatsapp-voice/backup.key \
    -o restore_target.sql.gz \
    whatsapp_voice_2026-10-24_030001.sql.gz.gpg
```

### Step 3: Terminate Active Connections & Recreate Database
```bash
sudo -u postgres psql << EOF
SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'whatsapp_voice';
DROP DATABASE IF EXISTS whatsapp_voice;
CREATE DATABASE whatsapp_voice OWNER wv_app_user;
GRANT ALL PRIVILEGES ON DATABASE whatsapp_voice TO wv_app_user;
EOF
```

### Step 4: Stream Decompressed SQL into PostgreSQL
```bash
gunzip -c restore_target.sql.gz | sudo -u postgres psql -d whatsapp_voice
```

### Step 5: Clean Up Decrypted Artifacts
```bash
shred -u restore_target.sql.gz
```

### Step 6: Verify Database Integrity & Start Gunicorn
```bash
# Verify row counts and tables exist
sudo -u postgres psql -d whatsapp_voice -c "\dt"

# Restart application
sudo systemctl start gunicorn
sudo systemctl status gunicorn

# Execute health probe
curl -f http://127.0.0.1:8000/api/v1/health/
```
