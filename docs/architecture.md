# Architecture (v0.1)

This document describes **django-authkit** at a high level.

---

## Goals
- Reusable Django app installable via pip.
- Support **session** and **JWT** auth simultaneously.
- Provide **social login** (Google, GitHub) in v1.
- Offer extension hooks for:
  - 2FA (future)
  - Enterprise SSO (SAML/OIDC) (future)
  - Multi-tenant resolution (future)
  - Risk/device policies (future)
- Maintain strict boundaries to keep codebase maintainable.

---

## Non-goals (v0.1)
- Full enterprise SAML/OIDC implementation
- Complete multi-tenant framework
- Advanced device fingerprinting / risk engine
- 2FA implementation (only hooks/contracts)

---

## Package layout (planned)

`src/authkit/`
- `apps.py` — Django app config
- `settings.py` — config loader + defaults
- `api/`
  - `serializers.py` — request validation
  - `views.py` — DRF views
  - `urls.py` — versioned routes
- `domain/`
  - `services.py` — business logic (register/login/linking)
  - `tokens.py` — token interface (issue/refresh/invalidate)
  - `emails.py` — email interface (verify/reset)
- `adapters/`
  - `jwt_simplejwt.py` — SimpleJWT adapter
  - `session_django.py` — Django session adapter
  - `oauth_google.py` — Google adapter
  - `oauth_github.py` — GitHub adapter
- `hooks/`
  - `types.py` — protocol/typing for hooks
  - `defaults.py` — no-op hook implementations
- `events.py` — signals + audit event names
- `errors.py` — centralized error model + codes
- `logging.py` — log helpers
- `models.py` — optional models for tokens/audit (minimal)

---

## Runtime flow (JWT mode)

1. `Register/Login endpoint` receives request
2. Serializer validates input and normalizes identity
3. Domain service:
   - authenticates credentials / creates user
   - runs hooks (risk evaluation, tenant resolution if enabled)
   - issues tokens via token adapter
4. API returns standardized response envelope

---

## Runtime flow (Session mode)

1. `Session login endpoint` validates credentials
2. Calls Django auth/session adapter to create a session
3. CSRF enforcement for unsafe methods
4. API returns standardized response envelope and sets cookies

---

## Social login flow (OAuth code exchange)

1. Client obtains an authorization `code` from provider
2. `POST /social/{provider}/login` exchanges `code` -> provider token/userinfo
3. Domain service:
   - finds or creates a user
   - links identities per configured policy
   - issues session/JWT as configured
4. Standard response is returned

---

## Extension points (hooks)

Hooks are configured in Django settings as callables or dotted paths. v0.1 ships no-op defaults.
Planned hooks:
- `RISK_EVALUATOR(request, identity) -> RiskDecision`
- `TENANT_RESOLVER(request) -> TenantContext | None`
- `MFA_CHALLENGE_PROVIDER(user, request) -> MfaResult` (future)
- `SSO_PROVIDER_REGISTRY` (future)

Principle: **keep hooks small and composable**. The core should not depend on enterprise features.

---

## Error handling

- One error model with codes + human-readable message.
- Field errors under `error.details`.
- No leaking of sensitive state in auth failures.
- Consistent HTTP statuses.

---

## Logging & auditing

- Structured logs (JSON-friendly) with event names:
  - `auth.register.success`
  - `auth.login.success`
  - `auth.login.failed`
  - `auth.logout`
  - `auth.password.reset.requested`
  - `auth.email.verify.sent`
- Optional audit table can be enabled to persist events.

---

## Why this is not over-engineered

- Single reusable Django app, not microservices.
- Minimal adapters only where external coupling exists (JWT, OAuth, email).
- Hooks are no-ops by default; advanced features stay out of the critical path.
- Clear boundaries (api/domain/adapters) prevent “god modules” without adding unnecessary layers.
