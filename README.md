# Skills Repo

Shared Codex skills repo with autosync hooks.

## Requirements

> [!WARNING]
> Tested on Ubuntu 24.04; may work on other modern Linux distros.
> Requires the Codex CLI, bash 4+, and git.

## Quick start (Codex only)

### Install the bootstrap skill (from inside Codex)

```
$skill-installer --repo midhunmonachan/skills --path skills/skills-sync
```

Restart Codex after installing the skill.

### Run the skill

```
$skills-sync
```

Follow the prompts to choose one:

- Full clone of this repo (default URL: `https://github.com/midhunmonachan/skills.git`)
- Selective skills install (no clone)
- Fresh empty skills repo
- Existing repo setup

## Example prompts

- "Clone the full repo into `~/projects/skills`."
- "Install only `skills-sync` from `midhunmonachan/skills`."
- "Create a new empty skills repo at `~/projects/my-skills`."

## Available skills

| Skill | Description |
| --- | --- |
| `skills-sync` | Bootstrap or maintain a skills repo with autosync hooks for `~/.codex/skills`. |
| `shadcn-mcp` | Install and configure the shadcn MCP server for Codex. |
