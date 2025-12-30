# Settings Contract (v0.1)

All settings are prefixed with `AUTHKIT_`.

This package is designed to be **config-driven**:
- Projects can enable/disable features without forking.
- Advanced features are exposed as hooks (callables), with safe defaults.

---

## Core toggles

### `AUTHKIT_MODES`
- Type: `list[str]`
- Default: `["session", "jwt"]`
- Allowed values: `"session"`, `"jwt"`

Controls which authentication modes are enabled.

---

## User/identity

### `AUTHKIT_IDENTITY_FIELD`
- Type: `str`
- Default: `"email"`
- Allowed: `"email"` (v0.1)
- Notes: username support may be added later via additional config.

### `AUTHKIT_REQUIRE_EMAIL_VERIFICATION`
- Type: `bool`
- Default: `True`
If `True`, certain policies may restrict access or token issuance until verified (configurable).

---

## JWT (SimpleJWT adapter)

### `AUTHKIT_JWT_ENABLED`
- Type: `bool`
- Default: `True`
Convenience toggle. If `False`, JWT endpoints return 404 (or are not mounted).

### `AUTHKIT_JWT_ACCESS_TTL_SECONDS`
- Type: `int`
- Default: `900` (15 minutes)

### `AUTHKIT_JWT_REFRESH_TTL_SECONDS`
- Type: `int`
- Default: `2592000` (30 days)

### `AUTHKIT_JWT_ROTATE_REFRESH_TOKENS`
- Type: `bool`
- Default: `True`

### `AUTHKIT_JWT_BLACKLIST_AFTER_ROTATION`
- Type: `bool`
- Default: `True`

### `AUTHKIT_JWT_ISSUER`
- Type: `str | None`
- Default: `None`

---

## Session mode

### `AUTHKIT_SESSION_ENABLED`
- Type: `bool`
- Default: `True`

### `AUTHKIT_SESSION_JSON_ENDPOINTS_ENABLED`
- Type: `bool`
- Default: `True`
If `True`, `/api/v1/auth/session/*` endpoints are exposed.

---

## Social login

### `AUTHKIT_SOCIAL_ENABLED`
- Type: `bool`
- Default: `True`

### `AUTHKIT_SOCIAL_PROVIDERS`
- Type: `list[str]`
- Default: `["google", "github"]`

### Provider credentials

#### Google
- `AUTHKIT_GOOGLE_CLIENT_ID` (required if google enabled)
- `AUTHKIT_GOOGLE_CLIENT_SECRET` (required)
- `AUTHKIT_GOOGLE_TOKEN_URL` default: `https://oauth2.googleapis.com/token`
- `AUTHKIT_GOOGLE_USERINFO_URL` default: `https://openidconnect.googleapis.com/v1/userinfo`

#### GitHub
- `AUTHKIT_GITHUB_CLIENT_ID` (required if github enabled)
- `AUTHKIT_GITHUB_CLIENT_SECRET` (required)
- `AUTHKIT_GITHUB_TOKEN_URL` default: `https://github.com/login/oauth/access_token`
- `AUTHKIT_GITHUB_USER_URL` default: `https://api.github.com/user`
- `AUTHKIT_GITHUB_EMAILS_URL` default: `https://api.github.com/user/emails`

### Linking policy

#### `AUTHKIT_SOCIAL_LINKING_POLICY`
- Type: `str`
- Default: `"link_by_verified_email"`
- Allowed:
  - `"link_by_verified_email"`: link if provider reports verified email (or email verified via provider rules)
  - `"link_by_email"`: link by email regardless of provider verification (riskier)
  - `"always_create"`: always create a new user (no linking)

#### `AUTHKIT_SOCIAL_REQUIRE_VERIFIED_EMAIL`
- Type: `bool`
- Default: `True`
If `True`, login fails if provider email is not verified/confirmed (when provider supports it).

---

## Email delivery

### `AUTHKIT_EMAIL_SENDER`
- Type: `str`
- Default: `"no-reply@example.com"`

### `AUTHKIT_EMAIL_BACKEND`
- Type: `str` (dotted path) or callable
- Default: `"authkit.adapters.email_django.DjangoEmailBackend"` (planned)
Projects can replace with SendGrid/Mailgun/etc.

---

## Throttling / rate limits (baseline)

### `AUTHKIT_THROTTLE_ENABLED`
- Type: `bool`
- Default: `True`

### `AUTHKIT_THROTTLE_RATES`
- Type: `dict[str, str]`
- Default:
  - `"login": "10/min"`
  - `"register": "5/min"`
  - `"password_reset": "5/min"`
  - `"social": "10/min"`

Implementation uses DRF throttling classes (planned).

---

## Hooks (future-facing)

Hooks are callables (or dotted paths) invoked by the domain layer.

### `AUTHKIT_RISK_EVALUATOR`
- Type: callable
- Default: no-op allow
Signature (planned):
`(request, identity: str, context: dict) -> dict`
Return example:
```python
{"allow": True, "reason": None}
```

### `AUTHKIT_TENANT_RESOLVER`
- Type: callable
- Default: returns None
Signature (planned):
`(request) -> dict | None`

### `AUTHKIT_MFA_PROVIDER`
- Type: callable
- Default: no-op (not enforced)
Signature (planned):
`(user, request) -> dict`
Return example:
```python
{"required": False, "method": None}
```

### `AUTHKIT_SSO_REGISTRY`
- Type: object/callable
- Default: empty
Purpose: register future SSO providers (SAML/OIDC) without changing core.

---

## Mounting URLs

Projects include:
- `path("api/v1/auth/", include("authkit.api.urls"))`

Optionally, projects can mount classic HTML session views later.

---

## Notes
- Defaults are conservative and may require explicit provider secrets in production.
- Any missing required provider credentials should fail fast on startup (planned).
