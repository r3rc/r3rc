---
name: r3-project-add
description: >
    Add a project repository to the workspace. Clones the repo into the workspace root,
    registers it in .gitignore, creates a minimal CLAUDE.md so the project inherits the
    workspace agent configuration.
    Use when the user says "add project", "clone project", "agrega el proyecto", or provides
    a Git URL they want to work on within this workspace.
allowed-tools: [Bash, Read]
user-invocable: true
---

# r3-project-add

Clone a project repository into the workspace and wire it up to inherit the agent configuration.

## Arguments

```
/r3-project-add <git-url> [name]
```

- `<git-url>` — Required. HTTPS or SSH Git URL of the project repository.
- `[name]` — Optional. Local directory name. Defaults to the repository name derived from the URL.

## Steps

### Step 1 — Run the script

```bash
.agents/scripts/projects.ps1 add <url> [name]
```

The script handles cloning, `.gitignore` registration, `CLAUDE.md` creation, and the workspace wiring (symlinks, `.mcp.json`) automatically.

### Step 2 — Confirm

Relay the script's output to the user. On error, surface the exact message without rephrasing it.

## Constraints

- Never run git commands directly — always go through `projects.ps1`.
- Never use `--depth` — project repos are for active development, not reference reading.
- Do not register the project in `.agents/registry.json` — that registry is for read-only reference sources only.
