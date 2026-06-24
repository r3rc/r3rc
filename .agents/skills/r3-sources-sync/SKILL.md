---
name: r3-sources-sync
description: >
    Update one or all registered reference sources to their latest remote state. Use when
    the user says "sync sources", "update the sources", "actualiza los sources", "trae lo
    ultimo de <source>", or when a registered source looks stale or unpopulated.
allowed-tools: [Bash, Read]
user-invocable: true
---

# r3-sources-sync

Update locally cloned sources under `.agents/sources/` to their latest remote state.

## Arguments

```
/r3-sources-sync [name]
```

- `[name]` — Optional. Name of a specific source (matches `name` field in `.agents/registry.json`). If omitted, syncs all registered sources.

## Steps

### Step 1 — Load registry

Read `.agents/registry.json`. If it does not exist or `sources` is empty, report the gap and suggest running `/r3-sources-link` first.

### Step 2 — Resolve targets

- If `[name]` is given: find the matching entry. If not found, report and stop.
- If no name given: use all entries in `sources`.

### Step 3 — Run the script

```bash
# All sources in the context (per --project <name> / --workspace / CWD)
.agents/scripts/sources.ps1 sync [--project <name> | --workspace]

# Single source
.agents/scripts/sources.ps1 sync <name> [--project <name> | --workspace]
```

The script handles shallow vs. full logic, missing-on-disk detection, and ff-only conflict reporting automatically.

### Step 4 — Report

Relay the script's output to the user as-is. If any source failed, surface the exact error line without rephrasing it.

## Constraints

- Never run git commands directly — always go through `sources.ps1`.
- Never re-clone a source automatically. If a re-clone is needed, tell the user to run `/r3-sources-link`.
- Never force-reset without explicit user confirmation.
