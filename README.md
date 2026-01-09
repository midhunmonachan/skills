<h1 align="center">Codex CLI Skills</h1>

<p align="center">Codex CLI skills with autosync hooks and maintained skill catalog.</p>

<p align="center">
  <img src="https://img.shields.io/github/last-commit/midhunmonachan/skills" alt="Last commit" />
  <img src="https://img.shields.io/github/repo-size/midhunmonachan/skills" alt="Repo size" />
  <img src="https://img.shields.io/github/languages/top/midhunmonachan/skills" alt="Top language" />
  <img src="https://img.shields.io/github/issues/midhunmonachan/skills" alt="Issues" />
</p>

<p align="center">
  <a href="#requirements">Requirements</a> •
  <a href="#quick-start-codex-cli-only">Quick start</a> •
  <a href="#example-prompts">Example prompts</a> •
  <a href="#available-skills">Available skills</a>
</p>

---

## Requirements

> [!WARNING]
> Tested on Ubuntu 24.04; may work on other modern Linux distros.
> Requires the Codex CLI, bash 4+, and git.

## Quick start (Codex CLI only)

1. Install the bootstrap skill (from inside Codex CLI):

   ```bash
   $skill-installer --repo midhunmonachan/skills --path skills/skills-sync
   ```

2. Restart Codex CLI after installing the skill.

3. Run the skill:

   ```bash
   $skills-sync
   ```

4. Follow the prompts to choose one:

- Full clone of this repo (default URL: `https://github.com/midhunmonachan/skills.git`)
- Selective skills install (no clone)
- Fresh empty skills repo
- Existing repo setup

## Example prompts

```text
$skills-sync Create repo at ~/projects/skills.
$skills-sync Install only skills-sync.
$skills-sync Use existing repo at ~/projects/skills.
$shadcn-mcp Set up the shadcn MCP server.
$git-commit Commit and push.
$repo-bootstrap Create a GitHub repo and push local code.
$skills-improve Improve a skill from my last task.
```

> [!TIP]
> Prefix prompts with `$skill-name` to force a specific Codex CLI skill.

## Available skills

| Skill | Description |
| --- | --- |
| `skills-sync` | Bootstrap or maintain a skills repo with autosync hooks for `~/.codex/skills`. |
| `shadcn-mcp` | Install and configure the shadcn MCP server for Codex CLI. |
| `git-commit` | Standardize commit messages and guide clean-history amendments when requested. |
| `repo-bootstrap` | Create GitHub repos, set About/topics, and push local code. |
| `skills-improve` | Capture and apply continuous improvements to Codex CLI skills. |
