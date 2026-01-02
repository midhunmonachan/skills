#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

if command -v git >/dev/null 2>&1; then
  if [ -d "$repo_root/.git" ]; then
    git -C "$repo_root" config core.hooksPath scripts/git-hooks
  fi
else
  echo "git not found; skipping hooks setup" >&2
fi

"$repo_root/scripts/sync-skills.sh" "$@"
