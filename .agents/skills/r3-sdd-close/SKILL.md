---
name: r3-sdd-close
description: >
    Spec-Driven Development — close a completed change: fold it into the living source specs by editing them
    directly, then verify integrity via git diff against the change's Spec Impact. Triggers (EN+ES): "close the change",
    "sdd close", "close specs", "fold into the spec", "cierra el cambio", "cerrar el cambio", "actualiza el spec vivo",
    "sincroniza los specs".
user-invocable: true
---

# r3-sdd-close — close a completed change into the living specs

The close of the SDD cycle. Edit the living `.covenant/specs/<capability>/spec.md` **directly** to reflect a
completed change, then **verify integrity via `git diff`**. Git is the diff, history, and conflict engine. Conventions live in `sdd-spec-format` and `sdd-schema`.

## Steps

### Step 1 — Select the change

If not given, list `.covenant/changes/` and ask which one. The change should be implemented (its `tasks.md` all
`- [x]`). Do NOT auto-select.

### Step 2 — Read the change and the living specs

Read the change's `spec.md` (the full requirements it establishes) and its `proposal.md` **`## Spec Impact`** — the
authoritative list of what is added / modified / removed / renamed (with reason + migration for removals). For each
affected capability, read the living `.covenant/specs/<capability>/spec.md` (it may not exist yet).

### Step 3 — Edit the living spec directly

For each affected capability, edit `.covenant/specs/<capability>/spec.md` in place to match the new reality:

- **Added** requirement → insert its full `### Requirement:` block.
- **Modified** requirement → replace the existing block (matched by name/ID), keeping its ID.
- **Removed** requirement → delete its block (its ID is retired, never reused).
- **Renamed** → change the header; keep the body + ID.
- **New capability** → create `.covenant/specs/<capability>/spec.md` from the change's spec (`## Purpose` +
  `## Requirements`).

Do NOT touch requirements the change does not mention. (For a multi-capability change, the change's `spec.md`
groups requirements under `## <Capability>` headings — apply each to its own living spec.)

### Step 4 — Verify integrity via git diff

Run `git diff -- .covenant/specs/` and check it against the change's `## Spec Impact`:

- **Every** requirement/scenario **removed or renamed** in the diff is **accounted for** in `## Spec Impact`. An
  unexplained deletion is almost certainly an accidental drop — **STOP and fix** before continuing.
- The diff matches the intended add/modify set; nothing was lost.
- The living spec still validates (scenario per requirement, unique IDs, valid format/`[[REQ-###]]` refs — see
  `sdd-spec-format`).

For a high-risk or large change, delegate this as an **adversarial review** to a fresh agent: "here is the change's
`## Spec Impact` and `git diff .covenant/specs/` — confirm nothing was lost, the spec is valid, and the change is
faithfully reflected; report any discrepancy." Resolve any finding before continuing.

### Step 5 — Report

Summarize, per capability, what changed (added / modified / removed / renamed). The change folder stays in place as
the numbered record; git history is the record of the spec's evolution.

## Output Contract

Edits the living source specs in place: `.covenant/specs/<capability>/spec.md` for each capability the change
touches (created if absent). Does NOT move the change folder.

## Constraints

- Integrity has two layers: **data (nothing lost) is git** — every prior state is recoverable via history;
  **quality** is the Step 4 verify over the diff. **Never skip Step 4.**
- Edit only what `## Spec Impact` declares; preserve everything else.
- The change stays numbered-in-place; closing it = this edit-and-verify + (when ready) committing the result.
