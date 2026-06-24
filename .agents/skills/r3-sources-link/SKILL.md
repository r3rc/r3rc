---
name: r3-sources-link
description: >
    Clone a Git repository as a read-only reference source: stores it in ~/.r3/sources/,
    symlinks it under .agents/sources/, and registers it in .agents/registry.json. Use when
    the user says "add source", "register this repo as a source", "registralo como source",
    "agrega la libreria como referencia", or provides a Git URL of a library they want to
    consult locally instead of fetching docs from the internet.
allowed-tools: [Bash, Read]
user-invocable: true
---

# r3-sources-link

Clone a Git repository into `.agents/sources/<name>/` and register it in `.agents/registry.json`.

## Arguments

```
/r3-sources-link <git-url> [name] [--branch <branch>] [--full]
```

- `<git-url>` — Required. HTTPS or SSH Git URL.
- `[name]` — Optional alias. Defaults to the repository name extracted from the URL (last path segment, no `.git`).
- `[--branch <branch>]` — Optional. Defaults to the remote's default branch.
- `[--full]` — Optional. Full clone. Default is shallow (`--depth=1`).

## Steps

### Step 1 — Parse arguments

Extract URL, name, branch, and clone depth from user input.

### Step 2 — Run the script

```bash
.agents/scripts/sources.ps1 link <url> [name] [--branch <branch>] [--full] [--project <name> | --workspace]
```

The script handles name derivation, duplicate detection, cloning, and registration automatically. The clone
**store is global** (`~/.r3/sources`); the symlink + `registry.json` entry land in the **resolved context**
(`--project <name>` / `--workspace` / CWD — see the sources section in `AGENTS.md`).

### Step 3 — Confirm

Relay the script's output to the user. On error, surface the exact message without rephrasing it.

## Constraints

- Never run git commands directly — always go through `sources.ps1`.
- Never modify files inside `.agents/sources/<name>/`. These are read-only mirrors.
- Never push, force-pull with rebase, or alter remote history.
- If the script fails (auth error, network issue, wrong URL), report the exact error and stop. Do not retry silently.
