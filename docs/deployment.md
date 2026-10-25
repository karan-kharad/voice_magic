# AWS EC2 Docker Production Deployment Guide

**Stack:** Docker Compose (Nginx + Gunicorn/Django 5 + PostgreSQL 16) on AWS EC2 Ubuntu LTS  
**Target Architecture:** Multi-container isolated environment with automated CI/CD deployment  

---

## 1. Architecture Overview (Docker Compose)

```mermaid
graph TD
    subgraph Host Internet
        A[Client HTTPS Request] -->|Port 443 / 80| B[Nginx Container]
    end

    subgraph Docker Bridge Network: frontend_net
        B -->|Reverse Proxy :8000| C[Django Backend Container]
        B -->|Static Volume /app/staticfiles| D[(Static Files Volume)]
    end

    subgraph Docker Internal Network: backend_net (Isolated)
        C -->|PostgreSQL :5432| E[(PostgreSQL 16 Alpine Container)]
        E -->|Data Persistence| F[(PostgreSQL Data Volume)]
    end
```

> [!NOTE]
> **PostgreSQL Isolation:** Port 5432 is **never** published to the EC2 host or the public internet. It exists strictly within the private `backend_net` Docker bridge.

---

## 2. One-Click EC2 Docker Setup

Connect to your EC2 instance via SSH:
```bash
ssh -i your-ec2-key.pem ubuntu@your-ec2-public-ip
```

Clone the repository and run the automated bootstrap script:
```bash
git clone https://github.com/your-org/whatsapp-voice-changer.git /var/www/whatsapp-voice
cd /var/www/whatsapp-voice

# Run the Docker setup script
sudo bash infrastructure/scripts/setup-docker-ec2.sh
```

---

## 3. Starting Backend & Database in Docker

1. **Configure Environment Variables:**
   ```bash
   cp .env.example .env
   nano .env
   ```
   Fill in your production secrets:
   ```ini
   DJANGO_SECRET_KEY=generate_a_strong_random_secret_key_here
   DJANGO_ALLOWED_HOSTS=your-ec2-domain.com,your-ec2-public-ip,localhost
   POSTGRES_DB=whatsapp_voice
   POSTGRES_USER=wv_app_user
   POSTGRES_PASSWORD=generate_a_strong_postgres_password_here
   ```

2. **Launch with Docker Compose:**
   ```bash
   docker compose up -d --build
   ```

3. **Verify Running Containers:**
   ```bash
   docker compose ps
   ```
   Expected output:
   ```
   NAME                  IMAGE                  COMMAND                  SERVICE   STATUS              PORTS
   wv_postgres_db        postgres:16-alpine     "docker-entrypoint.s…"   db        Up (healthy)        
   wv_django_backend     whatsapp-voice-backend "/app/docker-entrypo…"   backend   Up                  8000/tcp
   wv_nginx_proxy        nginx:alpine           "/docker-entrypoint.…"   nginx     Up                  0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp
   ```

4. **Verify Health Endpoint:**
   ```bash
   curl http://localhost/api/v1/health/
   ```
   Expected response:
   ```json
   {
     "success": true,
     "data": {
       "status": "healthy",
       "database": "healthy",
       "version": "1.0.0"
     }
   }
   ```

---

## 4. Mobile App Build via GitHub Actions

The Android mobile application is built automatically in the cloud using GitHub Actions:
- **Workflow File:** `.github/workflows/android-build.yml`
- **Triggers:**
  - On push to `main` (changes in `mobile/**`)
  - **Manual Trigger (`workflow_dispatch`):** Go to GitHub > **Actions** > **Android Build & Artifacts** > **Run workflow**.
- **Downloadable Artifacts:**
  - `app-debug-apk`: Instant installable testing APK.
  - `app-release-aab`: Signed bundle ready for Google Play distribution.
