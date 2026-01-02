#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: bootstrap_repo.sh [--force] [--no-git] [--clone <url>] [--dir <path>] [repo_path]

Creates a skills repo layout with autosync hooks.

Options:
  --force    Overwrite existing scripts/hooks
  --no-git   Skip git init/config
  --clone   Clone a repo before setup (uses repo name if --dir not set)
  --dir     Target directory when cloning
USAGE
  exit 1
}

force=0
no_git=0
repo_path=""
clone_url=""

while [ $# -gt 0 ]; do
  case "$1" in
    --force)
      force=1
      shift
      ;;
    --no-git)
      no_git=1
      shift
      ;;
    --clone)
      shift
      if [ $# -eq 0 ]; then
        usage
      fi
      clone_url="$1"
      shift
      ;;
    --clone=*)
      clone_url="${1#--clone=}"
      shift
      ;;
    --dir)
      shift
      if [ $# -eq 0 ]; then
        usage
      fi
      repo_path="$1"
      shift
      ;;
    --dir=*)
      repo_path="${1#--dir=}"
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      if [ -z "$repo_path" ]; then
        repo_path="$1"
        shift
      else
        usage
      fi
      ;;
  esac
done

if [ -n "$clone_url" ]; then
  if ! command -v git >/dev/null 2>&1; then
    echo "git not found; cannot clone" >&2
    exit 1
  fi

  if [ -z "$repo_path" ]; then
    repo_name=$(basename "$clone_url")
    repo_name="${repo_name%.git}"
    if [ -z "$repo_name" ]; then
      echo "unable to derive repo directory from $clone_url" >&2
      exit 1
    fi
    repo_path="$repo_name"
  fi

  if [ -e "$repo_path" ]; then
    if [ -d "$repo_path/.git" ]; then
      echo "repo already exists at $repo_path; omit --clone to use it" >&2
      exit 1
    fi
    if [ -n "$(ls -A "$repo_path" 2>/dev/null)" ]; then
      echo "target not empty: $repo_path" >&2
      exit 1
    fi
  fi

  git clone "$clone_url" "$repo_path"
fi

if [ -z "$repo_path" ]; then
  usage
fi

mkdir -p "$repo_path"
repo_path=$(cd "$repo_path" && pwd)

mkdir -p "$repo_path/skills" "$repo_path/scripts/git-hooks"
if [ -z "$(ls -A "$repo_path/skills" 2>/dev/null)" ]; then
  touch "$repo_path/skills/.gitkeep"
fi

if [ ! -f "$repo_path/scripts/sync-skills.sh" ] || [ "$force" -eq 1 ]; then
  cat <<'SYNC' > "$repo_path/scripts/sync-skills.sh"
#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: sync-skills.sh [--dry-run] [--verbose] [--dest <path>]

Options:
  --dry-run  Print actions without making changes
  --verbose  Print every copy action and keep checks
  --dest     Override the destination skills directory
USAGE
  exit 1
}

dry_run=0
verbose=0
dest_override=""

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)
      dry_run=1
      ;;
    --verbose)
      verbose=1
      ;;
    --dest)
      shift
      if [ $# -eq 0 ]; then
        echo "missing value for --dest" >&2
        usage
      fi
      dest_override="$1"
      ;;
    --dest=*)
      dest_override="${1#--dest=}"
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "unknown option: $1" >&2
      usage
      ;;
  esac
  shift
done

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
skill_root="$repo_root/skills"

if [ -n "$dest_override" ]; then
  codex_skills="$dest_override"
elif [ -n "${CODEX_SKILLS_DIR:-}" ]; then
  codex_skills="$CODEX_SKILLS_DIR"
elif [ -n "${CODEX_HOME:-}" ]; then
  codex_skills="$CODEX_HOME/skills"
else
  codex_skills="$HOME/.codex/skills"
fi

mkdir -p "$codex_skills"

managed_marker=".codex-skill-source"

declare -A seen=()

while IFS= read -r -d '' skill_file; do
  skill_dir=$(dirname "$skill_file")
  skill_name=$(basename "$skill_dir")

  if [ "${seen[$skill_name]+set}" = "set" ]; then
    echo "duplicate skill name $skill_name: $skill_dir (already from ${seen[$skill_name]})" >&2
    continue
  fi

  seen[$skill_name]="$skill_dir"
  dest="$codex_skills/$skill_name"
  marker_path="$dest/$managed_marker"

  if [ -L "$dest" ]; then
    if [ "$dry_run" -eq 1 ]; then
      echo "remove $dest (symlink)"
    else
      rm "$dest"
    fi
  fi

  if [ -e "$dest" ]; then
    if [ ! -d "$dest" ]; then
      echo "skip $dest (not a directory)" >&2
      continue
    fi
    if [ ! -f "$marker_path" ]; then
      echo "skip $dest (not managed by sync)" >&2
      continue
    fi
    if [ "$dry_run" -eq 1 ]; then
      echo "replace $skill_dir -> $dest"
      continue
    fi
    rm -rf "$dest"
  fi

  if [ "$dry_run" -eq 1 ]; then
    echo "copy $skill_dir -> $dest"
  else
    mkdir -p "$dest"
    cp -a "$skill_dir/." "$dest/"
    cat <<EOF > "$marker_path"
managed-by=skills-sync
source=$skill_dir
EOF
    if [ "$verbose" -eq 1 ]; then
      echo "copied $skill_dir -> $dest"
    fi
  fi
done < <(find "$skill_root" -type f -name SKILL.md -print0 | sort -z)

shopt -s nullglob
for entry in "$codex_skills"/*; do
  if [ -L "$entry" ]; then
    link_target=$(readlink -f "$entry" || true)
    case "$link_target" in
      "$skill_root"/*)
        if [ "$dry_run" -eq 1 ]; then
          echo "remove $entry (symlink)"
        else
          rm "$entry"
        fi
        ;;
      *)
        echo "warn: symlinked skill (Codex ignores symlinks): $entry" >&2
        ;;
    esac
    continue
  fi

  if [ -d "$entry" ] && [ -f "$entry/$managed_marker" ]; then
    entry_name=$(basename "$entry")
    if [ "${seen[$entry_name]+set}" != "set" ]; then
      if [ "$dry_run" -eq 1 ]; then
        echo "remove $entry"
      else
        rm -rf "$entry"
      fi
    elif [ "$verbose" -eq 1 ]; then
      echo "ok $entry"
    fi
  fi
done
SYNC
  chmod +x "$repo_path/scripts/sync-skills.sh"
fi

if [ ! -f "$repo_path/scripts/setup.sh" ] || [ "$force" -eq 1 ]; then
  cat <<'SETUP' > "$repo_path/scripts/setup.sh"
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
SETUP
  chmod +x "$repo_path/scripts/setup.sh"
fi

if [ ! -f "$repo_path/scripts/doctor.sh" ] || [ "$force" -eq 1 ]; then
  cat <<'DOCTOR' > "$repo_path/scripts/doctor.sh"
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
DOCTOR
  chmod +x "$repo_path/scripts/doctor.sh"
fi

for hook in post-commit post-merge post-checkout post-rewrite; do
  hook_path="$repo_path/scripts/git-hooks/$hook"
  if [ -f "$hook_path" ] && [ "$force" -ne 1 ]; then
    continue
  fi

  cat <<'HOOK' > "$hook_path"
#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [ -z "$repo_root" ]; then
  exit 0
fi

"$repo_root/scripts/sync-skills.sh"
HOOK
  chmod +x "$hook_path"
done

if [ "$no_git" -eq 0 ]; then
  if command -v git >/dev/null 2>&1; then
    if [ ! -d "$repo_path/.git" ]; then
      git -C "$repo_path" init
    fi

    if [ -d "$repo_path/.git" ]; then
      git -C "$repo_path" config core.hooksPath scripts/git-hooks
    fi
  else
    echo "git not found; skipping git init/config" >&2
  fi
fi

"$repo_path/scripts/sync-skills.sh"

echo "Bootstrapped skills repo at $repo_path"
