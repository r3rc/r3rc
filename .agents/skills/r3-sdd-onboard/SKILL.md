---
name: r3-sdd-onboard
description: >
    Spec-Driven Development — guided tutorial: walk a first-time user through one complete real cycle (explore →
    new → proposal → spec → design → tasks → apply → close) on their own codebase, teaching the workflow.
    Triggers (EN+ES): "onboard me to sdd", "sdd tutorial", "teach me the sdd workflow", "walk me through sdd",
    "enséñame el flujo sdd", "tutorial de sdd", "guíame por sdd", "cómo uso sdd".
user-invocable: true
---

# r3-sdd-onboard — guided tutorial through one full SDD cycle

Teach the r3 SDD workflow by doing one small, real change end to end, with EXPLAIN → DO → SHOW → PAUSE narration.
Conventions live in `sdd-schema`, `sdd-spec-format`, and `sdd-domain-format`.

## Steps

### Step 1 — Welcome and pick a small real task

Explain the cycle briefly (~15 min). Scan the codebase for a genuinely small win (TODO/FIXME, an untested function,
missing validation; `git log` for recent context) and propose 3-4 options with `file:line`. Keep scope tiny; let the
user pick or narrow.

### Step 2 — Walk the cycle, pausing at transitions

For the chosen task, go through the phases, narrating each:

1. **Explore** (briefly investigate) → PAUSE.
2. **Scaffold** — `r3-sdd-init` if needed (creates `.covenant/` + the constitution), then `.agents/scripts/sdd.ps1 new <slug>`; SHOW the folder.
3. **Proposal** — draft Why/What Changes/Capabilities/Spec Impact/Impact → PAUSE for approval.
4. **Spec** — write the full self-contained `spec.md`: complete `### Requirement:` blocks (`**ID**: REQ-###` + `#### Scenario:` GWT), per `sdd-spec-format`.
5. **Design** — a `## Constitution Check` (gate vs the constitution) + a `## Domain Model` when domain data is involved; full depth when warranted, else a one-line note.
6. **Tasks** — phase/slice structure with an Independent Test per slice. **⏸ Approve before implementing** — present the plan; wait for the user's go-ahead.
7. **Analyze** — `r3-sdd-analyze` (read-only coverage + consistency) before building.
8. **Apply** — implement each task (under strict-TDD when the constitution mandates it), flipping `- [ ]` → `- [x]`.
9. **Verify** — `r3-sdd-verify` (implementation vs spec) → PAUSE.
10. **Close** — `r3-sdd-close` (edit the living `specs/<cap>/spec.md` directly + verify via `git diff`); the numbered change folder stays as the record. SHOW the result.

### Step 3 — Recap

Recap the cycle and list the `r3-sdd-*` skills: **init · propose · scaffold · continue · fast-forward · explore ·
analyze · checklist · apply · verify · close · reconcile · onboard**. Suggest
`r3-sdd-propose` for their next real change.

## Constraints

- Teach on a REAL task in the user's codebase — no toy examples.
- EXPLAIN → DO → SHOW → PAUSE at key transitions; pause for approval before specs-driven implementation, but don't over-pause.
- Allow graceful exit at any point (point to `r3-sdd-continue` / `r3-sdd-apply`).
