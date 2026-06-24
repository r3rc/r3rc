---
name: r3-sources-restore
description: >
    Re-clone missing source stores and re-create missing symlinks from the registry.
    Use after moving to a new machine, when the user says "restore sources",
    "restaura los sources", "bootstrap sources", "los sources no están descargados",
    or when registered sources are missing on disk.
allowed-tools: [Bash, Read]
user-invocable: true
---

# r3-sources-restore — Bootstrap registered sources on a fresh machine

Re-create the local state (`~/.r3/sources/` stores and `.agents/sources/` symlinks) for
sources already registered in `.agents/registry.json`. Idempotent — anything already
present is left untouched.

## Arguments

```
/r3-sources-restore [name]
```

- `[name]` — Optional. Name of a specific source (matches `name` field in `.agents/registry.json`). If omitted, restores all registered sources.

## Steps

### Step 1 — Load registry

Read `.agents/registry.json`. If it does not exist or `sources` is empty, report that there is nothing to restore and suggest `/r3-sources-link` to register sources first.

### Step 2 — Run the script

```bash
# All sources in the context (per --project <name> / --workspace / CWD)
.agents/scripts/sources.ps1 restore [--project <name> | --workspace]

# Single source
.agents/scripts/sources.ps1 restore <name> [--project <name> | --workspace]
```

The script clones missing stores (honoring the registry's `shallow` flag), re-creates missing symlinks, and skips anything already present.

### Step 3 — Report

Relay the script's output to the user as-is. If any source failed to clone, surface the exact error line without rephrasing it. Mention that full clones (e.g. large repos registered with `--full`) may take a while.

## Constraints

- Never run git commands directly — always go through `sources.ps1`.
- Never modify `.agents/registry.json` — restore only re-creates local state from it.
- Never delete or overwrite an existing store or symlink. If a path exists but is wrong (e.g. a regular directory where the symlink should be), report it and let the user decide.
