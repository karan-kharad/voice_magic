# API Specification — WhatsApp Voice Changer Backend

**Version:** 1.0.0  
**Base URL:** `https://api.voicechanger.internal/api/v1`  
**Authentication:** Bearer JWT (`Authorization: Bearer <access_token>`)  

---

## 1. Global Response Envelope & Error Format

All API responses follow a uniform JSON structure.

### Success Response
```json
{
  "success": true,
  "data": { ... },
  "message": "Operation completed successfully.",
  "timestamp": "2026-10-25T07:00:00Z"
}
```

### Error Response
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid payload provided.",
    "details": [
      {
        "field": "email",
        "issue": "Enter a valid email address."
      }
    ]
  },
  "timestamp": "2026-10-25T07:00:00Z"
}
```

---

## 2. Endpoints Summary

### 2.1 Health & Readiness
| Method | Endpoint | Auth Required | Description |
|---|---|---|---|
| `GET` | `/api/v1/health/` | No | System health check (Database, Redis/Cache, Disk) |

#### Response: `200 OK`
```json
{
  "success": true,
  "data": {
    "status": "healthy",
    "database": "connected",
    "version": "1.0.0",
    "environment": "production"
  },
  "timestamp": "2026-10-25T07:00:00Z"
}
```

---

### 2.2 Authentication & Authorization

#### `POST /api/v1/auth/register/`
Create a new user account.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123!",
  "first_name": "Jane",
  "last_name": "Doe"
}
```

**Response: `201 Created`**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "e2a39281-9b1b-4171-897b-231a4a499318",
      "email": "user@example.com",
      "first_name": "Jane",
      "last_name": "Doe",
      "created_at": "2026-10-25T07:00:00Z"
    },
    "tokens": {
      "access": "eyJhbGciOi...",
      "refresh": "eyJhbGciOi..."
    }
  },
  "message": "User registered successfully."
}
```

#### `POST /api/v1/auth/login/`
Authenticate user with credentials and issue tokens.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123!"
}
```

**Response: `200 OK`**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "e2a39281-9b1b-4171-897b-231a4a499318",
      "email": "user@example.com"
    },
    "tokens": {
      "access": "eyJhbGciOi...",
      "refresh": "eyJhbGciOi..."
    }
  }
}
```

#### `POST /api/v1/auth/refresh/`
Refresh an expired access token using a valid refresh token.

**Request Body:**
```json
{
  "refresh": "eyJhbGciOi..."
}
```

---

### 2.3 User Profile & Audio Preferences

#### `GET /api/v1/profile/`
Retrieve the current authenticated user's profile and audio preferences.

**Headers:** `Authorization: Bearer <access_token>`

**Response: `200 OK`**
```json
{
  "success": true,
  "data": {
    "id": "e2a39281-9b1b-4171-897b-231a4a499318",
    "email": "user@example.com",
    "preferred_preset": "robot",
    "custom_presets": [
      {
        "id": "preset-01",
        "name": "Darth Vader Deep",
        "pitch_shift": -6.5,
        "echo_delay_ms": 30,
        "robot_freq": 120.0
      }
    ],
    "created_at": "2026-10-25T07:00:00Z"
  }
}
```

#### `PUT /api/v1/profile/preferences/`
Update audio preferences and custom preset settings.

---

### 2.4 Device & Application Compatibility

#### `GET /api/v1/compatibility/check/`
Check whether the user's Android device and OS version support low-latency Oboe processing and voice note features.

**Query Parameters:**
- `android_version`: `15`
- `device_model`: `Pixel 9 Pro`
- `target_app`: `whatsapp`

**Response: `200 OK`**
```json
{
  "success": true,
  "data": {
    "supported": true,
    "features": {
      "realtime_local_dsp": true,
      "low_latency_oboe": true,
      "whatsapp_voice_note_export": true,
      "in_app_voip_calling": true,
      "whatsapp_live_call_injection": false
    },
    "technical_notice": "Standard Android security isolates live WhatsApp calls. Real-time voice effects work in Voice Note Studio and In-App Calls.",
    "min_recommended_buffer_size": 192
  }
}
```

---

### 2.5 Subscriptions & Entitlements (Feasibility Governed)

> [!IMPORTANT]
> In accordance with the Project Feasibility Gate, paid subscription purchasing is disabled until recipient-side live call feasibility is certified or the product is officially launched on the approved Voice Note & In-App VoIP pivot.

#### `GET /api/v1/subscriptions/plans/`
List available plans.

**Response: `200 OK`**
```json
{
  "success": true,
  "data": {
    "commercial_status": "development_preview",
    "plans": [
      {
        "id": "tier_free",
        "name": "Community Tier",
        "price_cents": 0,
        "currency": "USD",
        "features": [
          "Standard Pitch Shifter",
          "Robot Voice Effect",
          "WhatsApp Voice Note Share"
        ]
      },
      {
        "id": "tier_pro_monthly",
        "name": "Voice Changer Pro (Preview)",
        "price_cents": 499,
        "currency": "USD",
        "is_active": false,
        "features": [
          "All DSP Effects",
          "HD Opus Encoding",
          "Unlimited Voice Notes",
          "In-App VoIP Calling"
        ]
      }
    ]
  }
}
```

#### `GET /api/v1/subscriptions/entitlements/`
Check server-validated entitlements for the user. Never relies on client-side state flags alone.

---

### 2.6 Support & Diagnostics

#### `POST /api/v1/support/tickets/`
Submit a support request or bug report.

**Request Body:**
```json
{
  "subject": "Audio glitch on Bluetooth headset",
  "category": "audio_latency",
  "description": "Noticeable latency when connected to Sony WH-1000XM5.",
  "device_metadata": {
    "android_sdk": 35,
    "device_model": "Pixel 9",
    "audio_route": "BLUETOOTH_SCO",
    "sample_rate": 48000
  }
}
```
