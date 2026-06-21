---
name: r3-sdd-sync
description: >
    Spec-Driven Development — sync a change's delta specs into the source-of-truth specs, WITHOUT archiving the
    change. Agent-driven intelligent merge. Triggers (EN+ES): "sync specs", "sdd sync", "merge the delta specs",
    "apply specs to main", "sincroniza los specs", "mergea los deltas", "aplica los specs al principal".
user-invocable: true
---

# r3-sdd-sync — merge a change's delta specs into the source specs

Apply a change's delta specs into `openspec/specs/`, in place, by intelligent agent-driven merge. The change stays
active (this does NOT archive it). The merge rules are defined in the auto-loaded rule `sdd-spec-format` — follow them
exactly.

## Steps

### Step 1 — Select the change

If not given, list `openspec/changes/` (excluding `archive/`) and ask which one — do NOT auto-select.

### Step 2 — Find the delta specs

Read every delta spec under `openspec/changes/<slug>/specs/<capability>/spec.md`. If there are none, inform the user
and stop.

### Step 3 — Merge each into the source spec

For each delta, read it AND the matching source spec at `openspec/specs/<capability>/spec.md` (may not exist yet),
then edit the source in place per `sdd-spec-format`:

- **ADDED** → add if absent; update to match if present.
- **MODIFIED** → apply the change; you may apply partial updates (e.g. add one scenario) and **must preserve content
  not mentioned in the delta**.
- **REMOVED** → delete the requirement block.
- **RENAMED** → rename FROM → TO.
- If the source spec does not exist, create it with a `## Purpose` (brief/TBD) and the ADDED requirements.

### Step 4 — Report

Summarize, per capability, what changed. Note the change remains active (archive separately with `r3-sdd-archive`).

## Output Contract

Edits the source specs in place: `openspec/specs/<capability>/spec.md` for each capability the change touches (created if absent). Does NOT move or archive the change.

## Constraints

- Read both the delta and the source before editing. Preserve everything the delta does not mention.
- The merge is **idempotent** — running it twice yields the same result.
- Source specs must never contain delta headers (`## ADDED/MODIFIED/REMOVED/RENAMED`); keep `### Requirement:` inside `## Requirements`.
