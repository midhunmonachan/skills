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
