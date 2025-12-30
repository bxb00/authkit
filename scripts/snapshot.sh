#!/usr/bin/env bash
set -euo pipefail

OUT="docs/dev_snapshot.md"

{
  echo "# Dev Snapshot"
  echo
  echo "Generated (UTC): $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo
  echo "## Git status"
  echo '```'
  git status
  echo '```'
  echo
  echo "## Recent commits"
  echo '```'
  git --no-pager log --oneline --decorate -20
  echo '```'
  echo
  echo "## Branches"
  echo '```'
  git branch -vv
  echo '```'
  echo
  echo "## Remote branches"
  echo '```'
  git branch -r
  echo '```'
  echo
  echo "## Diff stat (working tree vs HEAD)"
  echo '```'
  git diff --stat
  echo '```'
  echo
  echo "## Staged diff stat (index vs HEAD)"
  echo '```'
  git diff --cached --stat
  echo '```'
  echo
  echo "## Repository tree (top-level)"
  echo '```'
  ls -la
  echo '```'
} > "$OUT"

echo "Wrote $OUT"
