# Contributing

## Development
- Use Python 3.11+
- Install dev dependencies: `pip install -e ".[dev]"`
- Enable hooks: `pre-commit install`

## Quality gates
- `ruff check .`
- `black --check .`
- `pytest`

## Pull requests
- Keep PRs small and focused
- Include tests for behavior changes
- Update docs if needed
