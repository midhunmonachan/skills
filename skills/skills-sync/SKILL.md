---
name: skills-sync
description: Bootstrap or maintain a Codex skills repo with auto-sync to ~/.codex/skills; use when setting up a shared skills repository, onboarding new clones, or enabling autosync hooks for skills under skills/.
---

# Skills Sync

## Overview

Create a skills repository layout that auto-syncs each skill folder containing a
SKILL.md into ~/.codex/skills by copying files. Run the setup scripts yourself and
guide the user through an interactive flow; do not ask the user to run scripts
manually.

## Quick start

1. Ask which mode the user wants:
   - Full clone (default repo URL if not provided)
   - Selective skills (install a subset without cloning)
   - Fresh empty repo
   - Existing repo setup
2. Ask for the repo URL (if cloning) and target directory (optional).
3. Ask for a skill list if the user chooses selective install.
4. Run the scripts and installers yourself based on the chosen mode.

## Workflow

1. Confirm the desired mode and inputs (URL, path, skill list).
2. Run the appropriate command(s) for that mode.
3. Report what was created and where the repo or skills live.
4. If selective skills were installed, remind the user to restart Codex.

## Modes

### Full clone (recommended)

- Run:
  - `bash ~/.codex/skills/skills-sync/scripts/bootstrap_repo.sh --clone <repo-url>`
  - Add `--dir <path>` if the user specifies a destination.

### Selective skills (no clone)

- Ask which skills to install. If they want a list, fetch it from the repo:
  - `curl -s https://api.github.com/repos/<owner>/<repo>/contents/skills`
  - Use `gh api` for private repos if needed.
- Install each skill:
  - `$skill-installer --repo <owner>/<repo> --path skills/<skill-name>`
- Remind the user to restart Codex.

### Fresh empty repo

- Run:
  - `bash ~/.codex/skills/skills-sync/scripts/bootstrap_repo.sh /path/to/repo`

### Existing repo setup

- Run one of:
  - `/path/to/repo/scripts/setup.sh` (preferred)
  - `bash ~/.codex/skills/skills-sync/scripts/enable_hooks.sh /path/to/repo`

### Diagnose repo

- Run:
  - `/path/to/repo/scripts/doctor.sh`

## Repo layout created

- `skills/` for skills tracked in the repo
- `scripts/sync-skills.sh` to copy skills into `~/.codex/skills`
- `scripts/git-hooks/` with hooks that run `sync-skills.sh`
- `scripts/setup.sh` onboarding script for clones
- `scripts/doctor.sh` diagnostics for hooks, duplicates, and unsupported symlinks

## Notes

- Hooks include `post-commit`, `post-merge`, `post-checkout`, and `post-rewrite`.
- The sync script copies directories that contain a `SKILL.md`.
- If a name already exists in `~/.codex/skills` and is not managed by the sync script, it is skipped with a warning.
- Set `CODEX_SKILLS_DIR` (or `CODEX_HOME`) to sync into a different skills directory, or pass `--dest`.
- `sync-skills.sh` supports `--dry-run`, `--verbose`, and `--dest` for safe previews and overrides.
- Do not instruct users to run scripts manually; run them on their behalf.
- This skill is standalone: you can install only this skill and bootstrap your own repo.

## Resources

### scripts/

- `bootstrap_repo.sh`: creates repo layout, hooks, setup script, and runs sync.
- `enable_hooks.sh`: enables hooks and runs sync for existing repos.
