#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: enable_hooks.sh [repo_path]

Enables autosync hooks for an existing skills repo.
Defaults to the current directory if no path is provided.
USAGE
  exit 1
}

repo_path="${1:-.}"

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
fi

if [ ! -d "$repo_path" ]; then
  echo "repo not found: $repo_path" >&2
  exit 1
fi

repo_path=$(cd "$repo_path" && pwd)

if [ ! -f "$repo_path/scripts/sync-skills.sh" ]; then
  echo "missing scripts/sync-skills.sh in $repo_path" >&2
  echo "run bootstrap_repo.sh to create the repo layout" >&2
  exit 1
fi

if command -v git >/dev/null 2>&1; then
  if [ -d "$repo_path/.git" ]; then
    git -C "$repo_path" config core.hooksPath scripts/git-hooks
  else
    echo "no .git directory in $repo_path; skipping hooks" >&2
  fi
else
  echo "git not found; skipping hooks setup" >&2
fi

"$repo_path/scripts/sync-skills.sh"
