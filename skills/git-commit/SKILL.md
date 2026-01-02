---
name: git-commit
description: Standardize git commit messages using a consistent convention and guide clean-history workflows. Use when a user asks for commit message suggestions, to enforce a commit style, or to keep history clean by amending small fixes to the previous commit.
---

# Git Commit

## Overview

Use a consistent Conventional Commits style for commit messages and keep history clean when requested. Provide guidance on when to amend the last commit versus creating a new one.

## Commit message convention

Use **Conventional Commits**:

```
<type>(<scope>): <subject>
```

Guidelines:

- **Type**: `feat`, `fix`, `docs`, `refactor`, `chore`, `test`, `ci`, `build`, `perf`, `style`
- **Scope**: optional; **omit scope for single-scope repos**. Use a short noun only when the repo is clearly multi-scope (e.g., `web`, `api`, `cli`).
- **Subject**: imperative, lowercase, no trailing period; aim for <= 72 chars

Examples:

```
feat: add shadcn MCP setup skill
feat(skills): add shadcn MCP setup skill
fix(ui): hide stop button when idle
docs: document skills sync usage
```

## Clean history workflow

Only amend a previous commit **when the user explicitly asks for a clean history** and the change is a small fix to the most recent commit.

Decision checklist:

1. **User asked for clean history?** If no, make a new commit.
2. **Is the change a small fix to the last commit?** If no, make a new commit.
3. **Has the commit been pushed?** If yes, confirm force-push intent before amending.

Recommended commands when amending:

```
git add -A
git commit --amend --no-edit
```

If the message needs updating, replace `--no-edit` with a new Conventional Commit message.

If the user still wants clean history for pushed commits, ask to confirm a force push:

```
git push --force-with-lease
```

## Pre-commit summary and confirmation

Before asking permission to commit or push, output a brief, structured summary that includes:

- **Auto-generated commit message** using the convention above.
- **What changed** with concise bullet points (files and intent).
- **History plan**: new commit vs amend, and whether a force push is required.
- **README check**: confirm the README uses GitHub-flavored Markdown (tables, fenced blocks, callouts) and update it if needed before committing.
- **Verification check**: run lint, static analysis, tests, and coverage *if the project defines them* (e.g., `package.json` scripts, `Makefile`, `pyproject.toml`, or CI docs). Note what was run and any gaps before the commit summary.
- **Redundancy check**: remove redundant text, duplicate examples, and any unused references, files, or folders tied to removed features in the current change.

Ask for explicit confirmation to proceed with commit and, separately, to push.

### Sample output

```
Proposed commit message:
feat(skills): add shadcn MCP setup skill

What changed:
- Added shadcn MCP setup skill documentation at skills/shadcn-mcp/SKILL.md.
- Documented the new skill in README.md.

History plan:
- New commit (no amend).
- No force push required.

Proceed with commit? (yes/no)
```

## When to avoid amending

- The user did not ask for a clean history.
- The change is not a small fix to the latest commit.
- The commit is already pushed and the user did not approve a force push.
