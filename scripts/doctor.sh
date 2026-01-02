#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
skill_root="$repo_root/skills"

if [ -n "${CODEX_SKILLS_DIR:-}" ]; then
  codex_skills="$CODEX_SKILLS_DIR"
elif [ -n "${CODEX_HOME:-}" ]; then
  codex_skills="$CODEX_HOME/skills"
else
  codex_skills="$HOME/.codex/skills"
fi

issues=0

fail() {
  echo "error: $*" >&2
  issues=1
}

warn() {
  echo "warn: $*" >&2
}

info() {
  echo "$*"
}

if [ ! -x "$repo_root/scripts/sync-skills.sh" ]; then
  fail "missing or not executable: $repo_root/scripts/sync-skills.sh"
fi

if [ ! -d "$skill_root" ]; then
  fail "missing skills directory: $skill_root"
fi

for hook in post-commit post-merge post-checkout post-rewrite; do
  hook_path="$repo_root/scripts/git-hooks/$hook"
  if [ ! -x "$hook_path" ]; then
    fail "missing or not executable hook: $hook_path"
  fi
done

if command -v git >/dev/null 2>&1; then
  if [ -d "$repo_root/.git" ]; then
    hooks_path=$(git -C "$repo_root" config --get core.hooksPath || true)
    if [ "$hooks_path" != "scripts/git-hooks" ]; then
      fail "core.hooksPath not set to scripts/git-hooks (current: ${hooks_path:-unset})"
    fi
  else
    warn "no .git directory at $repo_root"
  fi
else
  warn "git not found; skipping hook config check"
fi

declare -A names=()
dup=0
while IFS= read -r -d '' skill_file; do
  skill_dir=$(dirname "$skill_file")
  skill_name=$(basename "$skill_dir")
  if [ "${names[$skill_name]+set}" = "set" ]; then
    warn "duplicate skill name $skill_name: $skill_dir (already from ${names[$skill_name]})"
    dup=1
  else
    names[$skill_name]="$skill_dir"
  fi
done < <(find "$skill_root" -type f -name SKILL.md -print0 | sort -z)

if [ "$dup" -eq 1 ]; then
  issues=1
fi

if [ -d "$codex_skills" ]; then
  shopt -s nullglob
  for entry in "$codex_skills"/*; do
    if [ -L "$entry" ]; then
      warn "symlinked skill (Codex ignores symlinks): $entry"
      issues=1
    fi
  done
else
  warn "codex skills dir missing: $codex_skills"
fi

info "dry-run sync:"
if ! "$repo_root/scripts/sync-skills.sh" --dry-run --verbose; then
  issues=1
fi

if [ "$issues" -ne 0 ]; then
  fail "doctor found issues"
  exit 1
fi

info "doctor: ok"
