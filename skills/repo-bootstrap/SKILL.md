---
name: repo-bootstrap
description: Create or bootstrap GitHub repos: init git, set About/topics, style README headers/badges, and push.
---

# Repo Bootstrap

## Overview

Use this skill when a user wants to create a GitHub repo, bootstrap an existing folder with git, or wire up README structure, badges, About text, topics, and push.

## Workflow

### 1. Confirm repo details

Gather: repo name, visibility, description/About text, topics, desired README title/tagline, badge targets (repo slug), and whether to push existing code or create an empty repo.

### 2. Create the GitHub repo (if needed)

Use `gh` (network required):

```bash
gh repo create <name> --public|--private --description "<about>"
```

If the user wants to push current code:

```bash
gh repo create <name> --public|--private --description "<about>" --source . --push
```

### 3. Initialize git (if missing)

If the directory is not a git repo, ask to run:

```bash
git init
```

If this is the first commit, use a meaningful Conventional Commit message (avoid "initial commit" unless requested).

### 4. Update README and repo metadata

- Update README headers/badges to match the repo name/slug.
- Keep the README structure tight: title, one-line summary, requirements, install, usage, and troubleshooting.
- Use GitHub-flavored Markdown elements (tables, fenced code, callouts).
- Set topics and About text (sorted topics preferred) with:

```bash
gh repo edit <owner>/<repo> --description "<about>" --add-topic <topic>
```

### 5. Push

If the repo is local-only:

```bash
git remote add origin <url>
git push -u origin main
```

If amending a pushed commit, ask before `git push --force-with-lease`.
