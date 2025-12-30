# API Contract (v0.1)

This document defines the public HTTP contract for **django-authkit**.
The goal is to support **both**:
- **Session auth** (web): cookie-based sessions with CSRF.
- **JWT auth** (API/mobile): access + refresh tokens.

All endpoints are **versioned** under `/api/v1/` for JSON APIs.
Session endpoints are exposed under `/api/v1/auth/session/*` as JSON for consistency (you can also mount HTML views later).

---

## Conventions

### Base URL
- JSON API: `/api/v1`
- Auth routes: `/api/v1/auth/*`

### Content type
- Requests: `Content-Type: application/json`
- Responses: `application/json` unless otherwise specified.

### Response envelope (consistent)
All JSON responses follow one of these shapes:

**Success**
```json
{
  "data": { },
  "meta": { },
  "error": null
}
```

**Error**
```json
{
  "data": null,
  "meta": { },
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input.",
    "details": {
      "field": ["message"]
    }
  }
}
```

### Pagination
Not used in v0.1 for auth endpoints.

### Authentication
- Session endpoints: cookie `sessionid` + CSRF for unsafe methods
- JWT endpoints: `Authorization: Bearer <access>`

### Standard error codes
- `VALIDATION_ERROR` (400)
- `AUTH_FAILED` (401) — invalid credentials/token
- `FORBIDDEN` (403)
- `NOT_FOUND` (404)
- `CONFLICT` (409) — e.g., email already used (if configured to be conflict)
- `RATE_LIMITED` (429)
- `SERVER_ERROR` (500)

---

## Data models (logical)

### User (public representation)
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "is_active": true,
  "is_email_verified": false,
  "created_at": "2025-12-31T00:00:00Z",
  "updated_at": "2025-12-31T00:00:00Z"
}
```

### Tokens (JWT mode)
```json
{
  "access": "<jwt-access>",
  "refresh": "<jwt-refresh>",
  "expires_in": 900
}
```

---

## Endpoints

### 1) Register
`POST /api/v1/auth/register`

Creates a user and (optionally) issues tokens/session depending on configuration.

**Request**
```json
{
  "email": "user@example.com",
  "password": "Str0ngPassw0rd!",
  "name": "Optional"
}
```

**Responses**
- `201 Created`
```json
{
  "data": {
    "user": { "id": "uuid", "email": "user@example.com", "is_email_verified": false },
    "tokens": { "access": "...", "refresh": "...", "expires_in": 900 }
  },
  "meta": {},
  "error": null
}
```
- `400` validation error
- `409` conflict if email already exists (configurable; can be 400)

---

### 2) Login (JWT)
`POST /api/v1/auth/login`

Issues access/refresh tokens.

**Request**
```json
{
  "email": "user@example.com",
  "password": "Str0ngPassw0rd!"
}
```

**Response**
- `200 OK`
```json
{
  "data": {
    "user": { "id": "uuid", "email": "user@example.com", "is_email_verified": true },
    "tokens": { "access": "...", "refresh": "...", "expires_in": 900 }
  },
  "meta": {},
  "error": null
}
```
- `401` `AUTH_FAILED`

---

### 3) Token Refresh
`POST /api/v1/auth/token/refresh`

**Request**
```json
{ "refresh": "<jwt-refresh>" }
```

**Response**
- `200 OK`
```json
{
  "data": {
    "tokens": { "access": "...", "refresh": "...", "expires_in": 900 }
  },
  "meta": {},
  "error": null
}
```

Notes:
- If refresh rotation enabled, a new refresh token is returned.
- If blacklist enabled, old refresh tokens are invalidated.

---

### 4) Logout
`POST /api/v1/auth/logout`

JWT mode: invalidates refresh token (blacklist) if enabled.
Session mode: logs out current session.

**Request (JWT mode)**
```json
{ "refresh": "<jwt-refresh>" }
```

**Response**
- `200 OK`
```json
{
  "data": { "ok": true },
  "meta": {},
  "error": null
}
```

---

### 5) Current user
`GET /api/v1/auth/me`

**Auth**
- Session cookie OR Bearer JWT.

**Response**
- `200 OK`
```json
{
  "data": { "user": { "id": "uuid", "email": "user@example.com" } },
  "meta": {},
  "error": null
}
```
- `401` if unauthenticated

---

### 6) Change password
`POST /api/v1/auth/password/change`

**Auth** required.

**Request**
```json
{
  "old_password": "OldPassw0rd!",
  "new_password": "NewStr0ngPassw0rd!"
}
```

**Response**
- `200 OK`
```json
{ "data": { "ok": true }, "meta": {}, "error": null }
```
- `400` validation
- `401` auth failed (wrong old password)

---

### 7) Password reset request
`POST /api/v1/auth/password/reset/request`

Sends an email with a reset token (if configured).

**Request**
```json
{ "email": "user@example.com" }
```

**Response**
- `200 OK` (always returns ok to avoid account enumeration)
```json
{ "data": { "ok": true }, "meta": {}, "error": null }
```

---

### 8) Password reset confirm
`POST /api/v1/auth/password/reset/confirm`

**Request**
```json
{
  "uid": "base64-uid-or-user-id",
  "token": "reset-token",
  "new_password": "NewStr0ngPassw0rd!"
}
```

**Response**
- `200 OK`
```json
{ "data": { "ok": true }, "meta": {}, "error": null }
```
- `400` invalid/expired token

---

### 9) Email verification request
`POST /api/v1/auth/email/verify/request`

**Auth** optional (configurable). Often used after register.

**Request**
```json
{ "email": "user@example.com" }
```

**Response**
- `200 OK`
```json
{ "data": { "ok": true }, "meta": {}, "error": null }
```

---

### 10) Email verification confirm
`POST /api/v1/auth/email/verify/confirm`

**Request**
```json
{
  "uid": "base64-uid-or-user-id",
  "token": "verify-token"
}
```

**Response**
- `200 OK`
```json
{ "data": { "ok": true }, "meta": {}, "error": null }
```
- `400` invalid/expired token

---

## Session JSON endpoints (optional)

These exist to make session auth accessible via JSON clients (SPA). For classic HTML forms, you can mount Django templates later.

### Session login
`POST /api/v1/auth/session/login`

**Request**
```json
{ "email": "user@example.com", "password": "Str0ngPassw0rd!" }
```

**Response**
- `200 OK`
```json
{ "data": { "ok": true, "user": { "id": "uuid", "email": "user@example.com" } }, "meta": {}, "error": null }
```

Notes:
- Sets `sessionid` cookie.
- CSRF: client must obtain CSRF token for subsequent unsafe requests.

### Session logout
`POST /api/v1/auth/session/logout`

**Response**
- `200 OK`
```json
{ "data": { "ok": true }, "meta": {}, "error": null }
```

---

## Social login (Google/GitHub)

### Social login (code exchange)
`POST /api/v1/auth/social/{provider}/login`
Where `{provider}` is one of: `google`, `github`.

**Request**
```json
{
  "code": "<oauth-authorization-code>",
  "redirect_uri": "https://your-app.example.com/oauth/callback"
}
```

**Response**
- `200 OK`
```json
{
  "data": {
    "user": { "id": "uuid", "email": "user@example.com", "is_email_verified": true },
    "tokens": { "access": "...", "refresh": "...", "expires_in": 900 }
  },
  "meta": { "provider": "google" },
  "error": null
}
```

Notes:
- Account linking policy is configurable:
  - link by verified email
  - create new user if not found
  - optionally require email verification for linking
- Session mode may set cookies instead of returning tokens (configurable).

---

## Security notes (baseline)
- All endpoints subject to throttling (per-IP and optionally per-identifier).
- Avoid user enumeration:
  - reset/verify requests always return `{ok:true}`.
- CSRF required for session unsafe methods.
- JWT refresh rotation and blacklist recommended for production.
