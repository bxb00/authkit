
# django-authkit

Reusable, production-grade authentication kit for Django:
- Session auth (web)
- JWT auth (API/mobile)
- Social login (Google, GitHub)
- Extensible hooks for 2FA, enterprise SSO, multi-tenant, and risk policies

> Status: scaffolding (v0.1.0). APIs and modules will be added incrementally with test coverage.

## Goals
- Clean architecture, config-driven, minimal magic
- Consistent API responses and centralized error handling
- Security-first defaults with extensibility points

## Development setup
```bash
python -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
pre-commit install
pytest
ruff check .
black --check .
