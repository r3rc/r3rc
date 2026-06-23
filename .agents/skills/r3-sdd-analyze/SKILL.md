---
name: r3-sdd-analyze
description: >
    Spec-Driven Development — analyze a change BEFORE implementing: a read-only coverage + consistency check
    across spec, tasks, and the constitution (requirement↔task coverage, ambiguity, conflicts, constitution
    alignment, cross-capability ripple). Triggers (EN+ES): "analyze the change", "sdd analyze", "coverage check",
    "check consistency", "analiza el cambio", "revisa cobertura", "chequea consistencia antes de implementar".
user-invocable: true
---

# r3-sdd-analyze — pre-implementation coverage & consistency

A read-only, agent-driven analysis run AFTER `tasks` and BEFORE `apply`. Distinct from `r3-sdd-verify` (post-build,
against the implementation): analyze checks the **artifacts** are coherent and complete before any code is written.
Writes NO files — emits a report. Conventions: `sdd-schema`, `sdd-spec-format`, `sdd-domain-format`.

## Steps

### Step 1 — Select the change

If not given, list active changes that have a `tasks.md` and ask which one. Do NOT auto-select.

### Step 2 — Build the inventories

Read the change's `proposal.md`, `spec.md` (the change's full spec) + its `## Spec Impact`, `design.md`, `tasks.md`, the living source specs it
touches, `_contracts/constitution.md`, and `_contracts/context-map.md`. Index requirements by `REQ-###`, tasks by
their `[[REQ-###]]` refs, entities from `## Key Entities`, and the constitution's MUST/SHALL principles.

### Step 3 — Detection passes

- **Coverage** — every `REQ-###` has ≥1 implementing task; every task maps to a requirement (a gap → CRITICAL).
- **Duplication** — near-duplicate requirements.
- **Ambiguity** — vague terms (fast / scalable / secure …) and any unresolved `[NEEDS CLARIFICATION]` marker.
- **Underspecification** — a requirement with no measurable/testable outcome; a scenario with no clear THEN.
- **Constitution alignment** — anything conflicting with a MUST principle or a missing mandated gate.
- **Consistency** — terminology drift; an entity referenced but absent from `## Key Entities`; a capability
  declared impacted in `proposal.md` with no matching requirements in the change's `spec.md` (cross-capability ripple).
- **Parallel safety** — for slices marked `[P]`, compare their `Owns:` globs: an **overlap** between two `[P]`
  slices → CRITICAL (unsafe to run concurrently). Flag any task that touches files outside its slice's `Owns:`.

### Step 4 — Report

Emit, every run:

- **Coverage matrix** — one row per `REQ-###`: `REQ-### | status`, status ∈ `✓ covered` (≥1 task satisfies it) /
  `❌ MISSING` (no task).
- The three sets explicitly — **mapped** · **unmapped requirements** · **orphan tasks** (a task with no
  `[[REQ-###]]` / `**Satisfies**` link) — plus a coverage **%**.
- A findings table (`ID | Category | Severity | Location | Recommendation`), severity CRITICAL / HIGH / MEDIUM / LOW.
- A one-line **verdict — PASS** (full coverage, no CRITICAL) / **CONCERNS** (only warnings) / **FAIL** (any MISSING
  or CRITICAL). Master rule: every `REQ-###` has a traceable implementing task.
- **Context used** — a short list of which artifacts/specs you read and why.

Offer remediation but do NOT apply it.

## Constraints

- Read-only — never edit artifacts or code; report only.
- Coverage mapping depends on `REQ-###` IDs; if the specs lack IDs, flag that first.
- Prefer false-negatives: when uncertain, downgrade severity. Every finding must be actionable.
