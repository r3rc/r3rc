---
name: r3-sdd-archive
description: >
    Spec-Driven Development — archive a completed change: optionally sync its delta specs into the source specs,
    then move the change folder into the dated archive. Triggers (EN+ES): "archive the change", "sdd archive",
    "finalize the change", "archiva el cambio", "finaliza el cambio", "cierra el cambio", "mover a archive".
user-invocable: true
---

# r3-sdd-archive — finalize and archive a completed change

Finish a change: sync its specs into the source of truth, then move it to `openspec/changes/archive/`. Conventions
live in the auto-loaded rules `sdd-schema` and `sdd-spec-format`.

## Steps

### Step 1 — Select the change

If not given, list `openspec/changes/` (excluding `archive/`) and ask which one — do NOT auto-select.

### Step 2 — Check task completion

Read `tasks.md` and count `- [ ]` (incomplete) vs `- [x]` (complete). If there is no `tasks.md`, proceed. If any are
incomplete: **⏸ Incomplete tasks** — show the count of unchecked tasks and ask whether to archive anyway. Wait for the
user's go/no-go; don't block once they confirm.

### Step 3 — Assess and sync delta specs

If the change has delta specs under `specs/`, compare each with its source spec. **⏸ Sync choice** — present the
per-capability summary of what would change and the options _sync now (recommended)_ / _archive without syncing_. Wait
for the user's choice. On _sync_, perform the intelligent merge per `sdd-spec-format` (the `r3-sdd-sync` procedure)
before moving on.

### Step 4 — Move to the archive

Run `.agents/scripts/sdd.sh archive <slug>` from the project root (or set `SDD_OPENSPEC_DIR`). It moves
`openspec/changes/<slug>/` to `openspec/changes/archive/YYYY-MM-DD-<slug>/` (it fails if that target already exists).

### Step 5 — Report

Confirm: specs synced (or not), and the archive location.

## Output Contract

- Source specs `openspec/specs/<capability>/spec.md` updated (when synced).
- The change folder moved to `openspec/changes/archive/YYYY-MM-DD-<slug>/`.

## Constraints

- The archive is an immutable audit trail — never edit archived changes.
- The spec merge is done by the agent (Step 3) BEFORE the move; `sdd.sh archive` only relocates the folder.
- Do not block on warnings — inform, confirm, proceed.
