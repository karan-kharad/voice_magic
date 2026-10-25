# WhatsApp Voice Changer — Complete Monorepo

[![Flutter CI](https://github.com/org/whatsapp-voice-changer/actions/workflows/flutter-ci.yml/badge.svg)](.github/workflows/flutter-ci.yml)
[![Android Build](https://github.com/org/whatsapp-voice-changer/actions/workflows/android-build.yml/badge.svg)](.github/workflows/android-build.yml)
[![Django CI](https://github.com/org/whatsapp-voice-changer/actions/workflows/django-ci.yml/badge.svg)](.github/workflows/django-ci.yml)
[![EC2 Deploy](https://github.com/org/whatsapp-voice-changer/actions/workflows/ec2-deploy.yml/badge.svg)](.github/workflows/ec2-deploy.yml)

> [!CAUTION]
> **CRITICAL FEASIBILITY GATE STATUS: NO-GO ON UNROOTED WHATSAPP LIVE-CALL INJECTION**  
> Comprehensive line-by-line inspection of reference repository `papergray/MicUp` and real-device testing demonstrate that unrooted Android applications **cannot** replace another application's live microphone input. Standard Android `AudioTrack` playback set to `MODE_IN_COMMUNICATION` provides local headphone monitoring only; WhatsApp captures directly from the physical microphone.  
> **Approved Pivot:** WhatsApp Voice Note / Audio Memo Studio (`ACTION_SEND`) and In-App VoIP Calling. Paid subscriptions remain disabled until certified. See [`docs/feasibility-report.md`](docs/feasibility-report.md).

---

## 1. Monorepo Structure

```
whatsapp-voice-changer/
├── mobile/                   # Flutter Application (Target Android 15+)
│   ├── android/              # Native Android (Kotlin + C++17 Oboe DSP Engine)
│   ├── lib/                  # Dart UI & State Management (Material 3)
│   └── test/                 # Flutter Unit & Widget Tests
├── backend/                  # Django REST Framework Backend
│   ├── apps/                 # Auth, Profiles, Subscriptions, Diagnostics, Support
│   ├── core/                 # Settings (base, dev, prod), WSGI, URLs
│   ├── requirements/         # Version-pinned Python dependencies
│   └── tests/                # Pytest & Django ORM integration tests
├── infrastructure/           # Production Infrastructure Configurations
│   ├── nginx/                # TLS 1.3 reverse proxy & rate limiting
│   ├── systemd/              # Gunicorn process manager service unit
│   └── scripts/              # Deploy, Backup, and Healthcheck shell scripts
├── docs/                     # Specifications & Architecture Documentation
│   ├── feasibility-report.md # In-depth technical feasibility & WhatsApp test results
│   ├── architecture.md       # High-level architecture, diagrams & risk register
│   ├── api.md                # OpenAPI REST API documentation & envelopes
│   ├── database.md           # PostgreSQL schema, security & RDS migration plan
│   ├── security.md           # Threat model, permissions & zero-knowledge audio policy
│   ├── deployment.md         # AWS EC2 Ubuntu production deployment instructions
│   └── backup-restore.md     # Disaster recovery & database restore runbook
└── .github/workflows/        # Automated GitHub Actions Workflows
    ├── flutter-ci.yml        # Flutter analyze & tests
    ├── android-build.yml     # Debug APK & Signed Release AAB build
    ├── django-ci.yml         # Python tests with PostgreSQL service container
    └── ec2-deploy.yml        # Controlled deployment to AWS EC2
```

---

## 2. Technology Stack

- **Mobile Client:** Flutter 3.24+, Dart 3.5+, Kotlin, C++17, Google Oboe (low-latency AAudio).
- **Backend:** Python 3.12, Django 5.1+, Django REST Framework, SimpleJWT.
- **Database:** PostgreSQL 16+ bound to `127.0.0.1` on AWS EC2 (port 5432 never exposed publicly).
- **Web & Process Server:** Nginx 1.24+ with TLS 1.3 & HTTP/2, Gunicorn 22.0+.
- **Hosting & Cloud:** AWS EC2 (Ubuntu 24.04 LTS), EBS encrypted volumes, Least-Privilege IAM.
- **CI/CD:** GitHub Actions with pinned tools, artifact retention, and protected environments.

---

## 3. Quick Start & Development

### Backend (Local Development)
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements/base.txt
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```

### Mobile (Flutter)
```bash
cd mobile
flutter pub get
flutter run
```

---

## 4. Documentation Index

- Detailed Feasibility Analysis & Audit: [`docs/feasibility-report.md`](docs/feasibility-report.md)
- System Architecture & Diagrams: [`docs/architecture.md`](docs/architecture.md)
- REST API Reference: [`docs/api.md`](docs/api.md)
- Database Design & RDS Migration: [`docs/database.md`](docs/database.md)
- Security & Privacy Policies: [`docs/security.md`](docs/security.md)
- Production EC2 Deployment: [`docs/deployment.md`](docs/deployment.md)
- Backup & Disaster Recovery: [`docs/backup-restore.md`](docs/backup-restore.md)
