---
name: r3-sdd-bulk-archive
description: >
    Spec-Driven Development — archive several completed changes in one batch, detecting and resolving cross-change
    spec conflicts by checking the codebase. Triggers (EN+ES): "bulk archive", "sdd bulk-archive", "archive
    multiple changes", "archive all completed changes", "archiva varios cambios", "archiva todos los cambios",
    "archivado en lote".
user-invocable: true
---

# r3-sdd-bulk-archive — archive multiple changes at once

Batch-archive completed changes, resolving conflicts where several touch the same capability. Conventions live in
the auto-loaded rules `sdd-schema` and `sdd-spec-format`.

## Steps

### Step 1 — Select changes

List active changes (`openspec/changes/`, excluding `archive/`). Ask the user to multi-select (offer "all"); never
auto-select.

### Step 2 — Gather state per change

For each selected change, read task completion (`- [ ]` vs `- [x]`) and its delta specs (which capabilities, which
`### Requirement:` names).

### Step 3 — Detect and resolve conflicts

Build a `capability → [changes]` map. A conflict = 2+ selected changes touch the same capability. Resolve each by
checking the codebase: if only one is actually implemented, sync that one; if both are, apply in chronological order
(older first, newer wins); if neither is, skip its spec sync and warn.

### Step 4 — Confirm, then execute

**⏸ Batch confirmation** — show the consolidated table (per change: artifacts, tasks, specs, conflicts, and the
conflict resolutions) and ask to confirm the batch. Wait for approval. Then, per change in resolved order: perform the
intelligent spec merge (per `sdd-spec-format`), then `.agents/scripts/sdd.sh archive <slug>`. Isolate failures — if one
archive target already exists, fail that one and continue the rest.

### Step 5 — Report

Summarize archived / skipped / failed, plus the spec-sync outcomes.

## Output Contract

Per archived change: source specs synced, and the change moved to `openspec/changes/archive/YYYY-MM-DD-<slug>/`. Reports per-change success / skip / fail.

## Constraints

- Always prompt for selection; one batch confirmation; never auto-select.
- Resolve same-capability conflicts by codebase evidence before syncing; warn (don't guess) when implementation is missing.
- Each merge is agent-driven and idempotent (see `sdd-spec-format`); `sdd.sh archive` only moves the folder.
