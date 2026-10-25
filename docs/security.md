# Security, Privacy & Platform Compliance Specification

**Document ID:** DOC-SEC-001  
**Status:** Approved  
**Compliance Standards:** Google Play Developer Program Policies, GDPR, OWASP Top 10, Least Privilege  

---

## 1. Threat Model & Mitigations

| Threat | Impact | Risk Level | Architectural Mitigation |
|---|---|---|---|
| **Rogue Audio Interception / Eavesdropping** | Compromise of user privacy | Critical | Microphone capture occurs **exclusively in native C++ RAM buffers**. Samples are processed in-place and immediately discarded after playback/export. Zero audio buffers are saved to disk or transmitted over the network. |
| **Database Exposure via Internet** | Data leak of user credentials | Critical | PostgreSQL binds solely to `127.0.0.1`. AWS Security Group blocks port 5432 unconditionally. |
| **Credential & Token Theft** | Account takeover | High | Passwords hashed using PBKDF2/SHA256 with random salt. Mobile app stores JWT tokens in Android Keystore-backed `EncryptedSharedPreferences`. Refresh tokens are rotated on each use. |
| **API Denial of Service / Abuse** | Outage or resource exhaustion | Medium | Nginx rate limits at the edge (10 req/s on `/api/`, 3 req/min on `/auth/`). Django uses `django-ratelimit` for endpoint-level protection. |
| **Privilege Escalation on Server** | Host compromise | Critical | Gunicorn and Django run under an unprivileged `www-data` system account. Sudo access is strictly restricted. |
| **Deceptive App Listing Rejection** | Google Play ban | Critical | Strict adherence to the Feasibility Gate: app does not claim to alter live third-party telephone/VoIP calls without root. Clear UX for Voice Note Studio and In-App VoIP. |

---

## 2. Android Security & Permissions Model

### 2.1 Principle of Least Privilege
The mobile application declares and requests only the minimal Android permissions necessary for operation:

```xml
<!-- Required for audio capture in Voice Studio -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />

<!-- Required for dynamic routing between speaker, earpiece, and wired/BT headsets -->
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />

<!-- Required for background processing notifications on Android 13+ (API 33+) -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- Required for network API communication with Django backend -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<!-- Explicitly excluded: No CALL_PHONE, No READ_CALL_LOG, No BIND_ACCESSIBILITY_SERVICE -->
```

### 2.2 Foreground Service & Android 14/15 Compliance
On Android 14+ (API 34) and Android 15 (API 35), foreground services that capture audio require explicit service type declaration:
```xml
<service
    android:name=".services.AudioService"
    android:foregroundServiceType="microphone"
    android:exported="false" />
```
The service immediately stops capture and releases the microphone hardware when the user pauses processing or exits the studio.

---

## 3. Server Hardening & Infrastructure Security

### 3.1 AWS EC2 Security Group Rules
| Protocol | Port | Source | Destination | Purpose |
|---|---|---|---|---|
| TCP | 443 | `0.0.0.0/0` | EC2 Instance | Public HTTPS (Production API) |
| TCP | 80 | `0.0.0.0/0` | EC2 Instance | HTTP to HTTPS 301 Permanent Redirect & ACME TLS |
| TCP | 22 | `Trusted Admin IP / VPN` | EC2 Instance | Restricted SSH access using Ed25519 keys only |
| TCP | 5432 | **DENIED (No Rule)** | **DROP** | PostgreSQL never accessible from public internet |

### 3.2 Linux System Hardening
- Automatic security updates enabled via `unattended-upgrades`.
- Root SSH login disabled (`PermitRootLogin no`).
- Password-based SSH authentication disabled (`PasswordAuthentication no`).
- UFW firewall active:
  ```bash
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow 22/tcp
  ufw allow 80/tcp
  ufw allow 443/tcp
  ufw enable
  ```

---

## 4. Cryptography & Secret Management

1. **In-Transit Security:** All network requests enforce TLS 1.3 with forward secrecy ciphers (`TLS_AES_256_GCM_SHA384`, `TLS_CHACHA20_POLY1305_SHA256`). HSTS enabled with `max-age=31536000; includeSubDomains; preload`.
2. **Secrets Storage:** Production secrets (`DJANGO_SECRET_KEY`, `POSTGRES_PASSWORD`, `JWT_SIGNING_KEY`) are stored in `/etc/whatsapp-voice/environment` with permissions `0600` owned by `root:www-data`. **Never committed to Git or logged in CI/CD.**
3. **Database Encryption at Rest:** Database filesystem encrypted using AWS EBS General Purpose SSD (gp3) with AWS KMS-managed keys.
