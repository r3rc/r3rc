---
name: r3-sdd-reconcile
description: >
    Spec-Driven Development — brownfield gap-close: assess existing code against a change's spec/design/tasks and
    APPEND the remaining work as tasks. For code that drifted from the spec, or adopting SDD on existing code.
    Triggers (EN+ES): "reconcile", "sdd reconcile", "converge", "close the gaps", "brownfield", "alinea el código con el spec",
    "cierra las brechas", "adopta sdd en código existente".
user-invocable: true
---

# r3-sdd-reconcile — brownfield gap-close

OPTIONAL. Runs AFTER an implementation exists. Read-only on spec/design; **append-only** on `tasks.md`. Reuses
`r3-sdd-verify`'s conformance diagnosis and turns gaps into tasks. Conventions: `sdd-schema`, `sdd-spec-format`.

## Steps

### Step 1 — Select the change + scope

Pick the change; derive the source files in scope from `design.md` / `tasks.md` plus the requirements.

### Step 2 — Assess code vs artifacts (read-only)

For each `REQ-###` and scenario, find the implementing code and classify the gap:
**missing** (no implementation) · **partial** (incomplete) · **contradicts** (code disagrees with the spec) ·
**unrequested** (code with no backing requirement). For legacy code, capture current behavior with
approval/snapshot tests before proposing changes.

### Step 3 — Append gap-closing tasks

For each actionable gap, append a task to `tasks.md` under a new `## Phase: Convergence` group:
`- [ ] N.M <imperative> ([[REQ-###]]) <gap-type>`. If the implementation is already complete, leave `tasks.md`
byte-identical.

### Step 4 — Report

A findings table (`REQ | Gap type | Severity | Evidence | Remaining work`) + how many tasks were appended.

## Output Contract

- `tasks.md` — appended `## Phase: Convergence` tasks (append-only; never edits existing tasks). Byte-identical if complete.

## Constraints

- Read-only on spec/design; append-only on tasks. Never edits requirements or existing tasks.
- Optional / specialized (brownfield); not a core greenfield step.
