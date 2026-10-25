# System Architecture & Technical Specification

**Project:** WhatsApp Voice Changer (Monorepo)  
**Document ID:** DOC-ARCH-001  
**Status:** Phase 0 Approved / Feasibility Governed  

---

## 1. High-Level Architecture Overview

The system consists of three primary tiers:
1. **Client Tier (Flutter & Android Native):** A high-performance Flutter mobile application targeting Android 15+ (API 35+) with native Kotlin lifecycle integration and a low-latency C++17 / Oboe audio processing engine.
2. **Backend Services Tier (Django REST Framework on AWS EC2):** A scalable, secure Python Django application exposing versioned `/api/v1/` endpoints for authentication, user profiles, device compatibility metadata, diagnostics, support, and entitlement verification.
3. **Data Tier (PostgreSQL on AWS EC2):** A hardened PostgreSQL database bound strictly to `127.0.0.1` on the same EC2 host, with encrypted backups, transactional migrations, and a clear architectural migration path to Amazon RDS.

```mermaid
graph TD
    subgraph Mobile Device (Android 15+)
        A[Flutter UI / Material 3] -->|Platform Channel| B[Kotlin AudioBridge]
        B -->|JNI / Native Binding| C[C++17 Oboe Audio Engine]
        C -->|AAudio / OpenSL ES| D[Physical Microphone Input]
        C -->|DSP: Pitch, Robot, Echo, EQ| E[Processed PCM Buffer]
        E -->|Local AudioTrack| F[Monitoring / Earphones]
        E -->|Opus / OGG File| G[WhatsApp Share Intent / Voice Memo]
        A -->|HTTPS REST API / TLS 1.3| H[Nginx Reverse Proxy]
    end

    subgraph AWS Cloud Infrastructure (EC2 Ubuntu LTS)
        H -->|Unix Socket / Proxy Pass| I[Gunicorn WSGI Server]
        I -->|Python WSGI| J[Django REST Framework /api/v1/]
        J -->|ORM / UNIX Socket / localhost| K[(PostgreSQL Database)]
        L[systemd Services] -->|Process Monitoring| I
        M[Automated Backup Script] -->|Encrypted Dump / Cron| N[Encrypted Local/S3 Storage]
    end

    subgraph CI/CD (GitHub Actions)
        O[Git Push / Release] --> P[Flutter CI: Unit/Widget Tests & Analyze]
        O --> Q[Android Build: Debug APK & Release AAB]
        O --> R[Django CI: Pytest & Migrations]
        O --> S[EC2 Deployment: SSH/Secrets/Systemd/Health Check]
    end
```

---

## 2. Risk Register & Feasibility Gate

| Risk ID | Category | Description | Severity | Likelihood | Mitigation Strategy |
|---|---|---|---|---|---|
| **RSK-01** | Technical | Android audio isolation prevents unrooted apps from injecting audio into WhatsApp live call input. | **Critical** | **Definite (100%)** | **Feasibility Gate Enforcement:** Stop commercial WhatsApp live-call claims. Pivot to WhatsApp Voice Note Studio (`ACTION_SEND`) and in-app VoIP calling experience. Keep subscription payments disabled until feasibility gate criteria are satisfied. |
| **RSK-02** | Compliance | Google Play Store rejection for deceptive marketing if app claims to change live WhatsApp calls without root. | **High** | **High** | Transparent UI/UX clearly stating supported capabilities (voice notes, local monitoring, in-app VoIP). No false claims on store listings. |
| **RSK-03** | Audio / Latency | High round-trip latency (>50ms) causing stuttering or speech disfluency. | **Medium** | **Medium** | Use C++17 with Google Oboe (AAudio backend with exclusive low-latency mode) and block-based ring buffers to achieve <30ms local latency. |
| **RSK-04** | Security | Exposure of PostgreSQL port 5432 or unauthenticated Django endpoints. | **Critical** | **Low** | PostgreSQL bound strictly to localhost (`listen_addresses = 'localhost'`). Security groups allow only ports 443, 80 (redirect), and restricted 22. JWT authentication on all non-public endpoints. |
| **RSK-05** | Privacy | Unintentional recording or cloud transmission of user voice audio. | **Critical** | **Low** | Zero audio transmitted to backend. All DSP executed strictly on-device in native C++. Clear privacy policy and permission rationale. |

---

## 3. Monorepo Directory Structure

The repository is structured as a unified monorepo to ensure cohesive versioning, synchronized testing, and streamlined CI/CD:

```
/home/ubuntu/shubh/
├── .github/
│   └── workflows/
│       ├── flutter-ci.yml       # Pinned Flutter SDK, analyze, widget/unit tests
│       ├── android-build.yml    # JDK 17, Android SDK/NDK, APK & AAB artifacts
│       ├── django-ci.yml        # Python 3.12, linting, Django checks, PostgreSQL tests
│       └── ec2-deploy.yml       # Controlled, secret-driven EC2 deployment & health verify
├── mobile/                      # Complete Flutter application (Android 15+ target)
│   ├── android/                 # Android native project, Kotlin plugins & C++ Oboe engine
│   │   ├── app/
│   │   │   ├── src/main/cpp/    # Native C++ DSP engine (Pitch, Echo, Robot)
│   │   │   │   ├── CMakeLists.txt
│   │   │   │   ├── AudioEngine.cpp
│   │   │   │   └── AudioEngine.h
│   │   │   └── src/main/kotlin/ # Android platform channel & service handlers
│   │   └── build.gradle.kts
│   ├── lib/                     # Flutter Dart code (Material 3 UI)
│   │   ├── main.dart
│   │   ├── src/
│   │   │   ├── audio/           # Native audio controller & DSP bindings
│   │   │   ├── models/          # Data models (VoicePreset, User, Subscription)
│   │   │   ├── screens/         # Dashboard, Studio, Diagnostics, Subscription, Settings
│   │   │   ├── services/        # API client, secure storage, audio service
│   │   │   └── widgets/         # Audio visualizers, level meters, preset cards
│   │   └── pubspec.yaml
│   └── test/                    # Flutter unit & widget tests
├── backend/                     # Django REST Framework application
│   ├── manage.py
│   ├── core/                    # Django project configuration (settings, wsgi, urls)
│   │   ├── settings/
│   │   │   ├── base.py
│   │   │   ├── development.py
│   │   │   └── production.py
│   │   ├── urls.py
│   │   └── wsgi.py
│   ├── apps/
│   │   ├── authentication/      # User auth, JWT token lifecycle
│   │   ├── profiles/            # User profiles & preferences
│   │   ├── subscriptions/       # Tier plans, entitlements, purchase verification
│   │   ├── diagnostics/         # Device/app compatibility metadata & health
│   │   └── support/             # User feedback & ticket management
│   ├── requirements/
│   │   ├── base.txt
│   │   └── production.txt
│   └── tests/                   # Pytest & Django test cases
├── infrastructure/
│   ├── nginx/
│   │   └── whatsapp-voice.conf  # TLS 1.3 reverse proxy configuration
│   ├── systemd/
│   │   └── gunicorn.service     # Systemd service definition for Django backend
│   └── scripts/
│       ├── deploy.sh            # Automated EC2 deployment runner
│       ├── backup.sh            # Automated PostgreSQL encrypted backup
│       └── healthcheck.sh       # Production health & readiness check
├── docs/
│   ├── architecture.md          # This document
│   ├── feasibility-report.md    # Investigation & WhatsApp call proof of feasibility
│   ├── api.md                   # OpenAPI & endpoint specifications
│   ├── database.md              # Schema, migrations, backup & RDS migration plan
│   ├── security.md              # Threat model, permissions, privacy policy
│   ├── deployment.md            # AWS EC2 Ubuntu production deployment guide
│   └── backup-restore.md        # Disaster recovery & database restore procedures
└── README.md                    # Project overview & developer guide
```

---

## 4. Mobile Application Architecture (Flutter + Native Audio)

### 4.1 Native Platform Channel Contract
Flutter communicates with the native Android layer via `MethodChannel` (`com.whatsappvoicechanger/audio`) and `EventChannel` (`com.whatsappvoicechanger/levels`):

- `startProcessing(preset: String, params: Map)`: Initializes Oboe stream, attaches DSP graph, starts real-time loop.
- `stopProcessing()`: Tears down Oboe streams, releases microphone hardware cleanly.
- `setPreset(presetId: String, pitchShift: Double, echoDelayMs: Int, robotFreq: Double)`: Updates DSP parameters atomically in real time without audio glitches.
- `exportVoiceNote(targetApp: String)`: Compresses processed audio buffer to Opus `.ogg` and launches WhatsApp share sheet.
- `getDiagnostics()`: Returns audio route, sample rate, buffer size, latency estimate, and hardware capabilities.

### 4.2 C++17 Native Audio Engine (Oboe)
The audio engine uses the Google Oboe C++ library:
- **Audio Stream Configuration:** `oboe::Direction::Input`, `oboe::AudioFormat::Float`, `oboe::ChannelCount::Mono`, `oboe::PerformanceMode::LowLatency`, `oboe::SharingMode::Exclusive` (or `Shared` fallback).
- **DSP Algorithms:**
  - **Pitch Shifting:** Overlap-Add (OLA) time-domain granular pitch shifting with Hann windowing for near-zero latency.
  - **Robot Voice:** Ring modulation with a tunable carrier frequency (50 Hz - 200 Hz).
  - **Echo / Delay:** Circular delay buffer with adjustable feedback and dampening.
  - **Low / High Pitch:** Parametric biquad shelf filters combined with granular pitch shifting.

---

## 5. Backend Architecture (Django REST Framework on AWS EC2)

### 5.1 Technology Selection
- **Framework:** Django 5.x with Django REST Framework 3.15+.
- **Authentication:** `rest_framework_simplejwt` with short-lived access tokens and refresh rotation.
- **Database:** PostgreSQL 16+ via Django ORM.
- **WSGI / Web Server:** Gunicorn behind Nginx with HTTP/2 and TLS 1.3.

### 5.2 API Module Structure
All API endpoints are versioned under `/api/v1/`:
- `/api/v1/health/`: Unauthenticated health check returning service status, database connectivity, and timestamp.
- `/api/v1/auth/`: Registration, login, token refresh, logout, password reset.
- `/api/v1/profile/`: User profile, audio preferences, saved preset configurations.
- `/api/v1/compatibility/`: Device and Android OS compatibility metadata.
- `/api/v1/subscriptions/`: Available plans, user subscription status, entitlement checks (governed by feasibility gate).
- `/api/v1/support/`: Support tickets, device diagnostics reports (opt-in).

---

## 6. PostgreSQL Database Architecture

- Application database: `whatsapp_voice_db`
- Dedicated user: `wv_app_user` (granted only `SELECT, INSERT, UPDATE, DELETE` on application tables; no superuser privileges).
- Host binding: `localhost` (`127.0.0.1`), unix domain sockets for local Gunicorn.
- Strict isolation: Port 5432 is **never** accessible from the public internet.
- Schema versioning: Automated Django migrations tested in CI against temporary PostgreSQL instances.
- Future migration: Zero-downtime replication to Amazon RDS PostgreSQL using `pg_dump` or AWS DMS when active users exceed single-node capacity.

---

## 7. Security, Privacy & Zero-Knowledge Audio Policy

1. **Audio Privacy:** Audio captured by the microphone is processed **exclusively on-device** in native RAM. No live audio samples, buffers, or recordings are ever transmitted to the Django backend or any third-party cloud.
2. **Data Minimization:** Backend stores only user credentials (bcrypt/argon2 hashed passwords), subscription tokens, and user-customized preset parameters.
3. **Network Security:** HSTS, strict Content-Security-Policy, TLS 1.3, rate-limiting on sensitive endpoints (`django-ratelimit`), and Nginx request shielding.
