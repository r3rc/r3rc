---
name: r3-sdd-onboard
description: >
    Spec-Driven Development — guided tutorial: walk a first-time user through one complete real cycle (explore →
    new → proposal → specs → design → tasks → apply → archive) on their own codebase, teaching the workflow.
    Triggers (EN+ES): "onboard me to sdd", "sdd tutorial", "teach me the sdd workflow", "walk me through sdd",
    "enséñame el flujo sdd", "tutorial de sdd", "guíame por sdd", "cómo uso sdd".
user-invocable: true
---

# r3-sdd-onboard — guided tutorial through one full SDD cycle

Teach the r3 SDD workflow by doing one small, real change end to end, with EXPLAIN → DO → SHOW → PAUSE narration.
Conventions live in the auto-loaded rules `sdd-schema` and `sdd-spec-format`.

## Steps

### Step 1 — Welcome and pick a small real task

Explain the cycle briefly (~15 min). Scan the codebase for a genuinely small win (TODO/FIXME, an untested function,
missing validation; `git log` for recent context) and propose 3-4 options with `file:line`. Keep scope tiny; let the
user pick or narrow.

### Step 2 — Walk the cycle, pausing at transitions

For the chosen task, go through the phases, narrating each:

1. **Explore** (briefly investigate) → PAUSE.
2. **New** — `r3-sdd-init` if needed, then `.agents/scripts/sdd.ps1 new <slug>`; SHOW the scaffolded folder.
3. **Proposal** — draft Why/What Changes/Capabilities/Impact → PAUSE for approval.
4. **Specs** — write the delta spec (`### Requirement:` / `#### Scenario:` per `sdd-spec-format`).
5. **Design** — full when warranted, else a one-line note (always create the file).
6. **Tasks** — checkboxed `- [ ] N.M` → PAUSE before implementing.
7. **Apply** — implement each task, flipping `- [ ]` → `- [x]`.
8. **Archive** — `r3-sdd-archive` (sync specs, then move to the dated archive); SHOW the result.

### Step 3 — Recap

Recap the cycle and list the `r3-sdd-*` skills (propose, explore, apply, sync, archive, new, continue, ff, verify,
bulk-archive). Suggest `r3-sdd-propose` for their next real change.

## Constraints

- Teach on a REAL task in the user's codebase — no toy examples.
- EXPLAIN → DO → SHOW → PAUSE at key transitions; pause for approval before specs-driven implementation, but don't over-pause.
- Allow graceful exit at any point (point to `r3-sdd-continue` / `r3-sdd-apply`).
