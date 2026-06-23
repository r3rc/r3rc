---
name: r3-sdd-apply
description: >
    Spec-Driven Development — implement a change: work through its tasks.md checklist, writing code and checking
    off tasks as you go. Triggers (EN+ES): "apply the change", "implement the change", "sdd apply", "work the
    tasks", "implementa el cambio", "aplica el cambio", "trabajemos las tareas", "ejecuta las tareas".
user-invocable: true
---

# r3-sdd-apply — implement a change's tasks

Implement the tasks of a change, marking progress as you go. Conventions live in `sdd-schema`,
`sdd-spec-format`, and `sdd-domain-format`.

## Steps

### Step 1 — Select the change

Use the change name if given; else infer from the conversation; else auto-select when only one active change exists;
otherwise list `.covenant/changes/` and ask which one. Announce "Using change: `<slug>`".

### Step 2 — Load context

Read the change's artifacts: `proposal.md`, `spec.md`, `design.md` (if present), `tasks.md`.
Confirm the change is apply-ready (`tasks.md` exists — see status derivation in `sdd-schema`); if a required artifact
is missing, stop and suggest `r3-sdd-continue`. Briefly note which artifacts you loaded and why (context used).

**Resolve strict-TDD mode:** read `.covenant/constitution.md` `## Testing`. If strict-TDD is mandated AND a test
runner is present, you are in **Strict TDD mode** — load and follow `references/strict-tdd.md` for
Step 3. Otherwise (no mandate, or no runnable behavior) use the standard loop. When inactive, `references/strict-tdd.md` is
never read (0 tokens).

### Step 3 — Implement tasks (loop until done or blocked)

Respect the tasks' **Review Workload Forecast** — if a slice is oversized (large), confirm a split / delivery
decision with the user before implementing it. Work the phases/slices in order. Setup/Foundational tasks
**scaffold the skeleton first** — empty structural stubs
(signatures, types, interfaces) derived from the `## Domain Model`; these are structural and TDD-exempt. The P1
slice is the walking skeleton. Respect each slice's **`Owns:`** globs as its write scope, and only work `[P]`
slices concurrently when their `Owns:` don't overlap (see `r3-sdd-analyze`). **Under Strict TDD mode, follow
`references/strict-tdd.md` for every behavior task** (RED → GREEN → TRIANGULATE → REFACTOR + Cycle Evidence).
Before implementing a task that depends on a registered third-party library, consult its checkout under
`.agents/sources/` (per the source-verification policy in `AGENTS.md`) rather than coding its API from memory; if a
relevant library is not registered and the work is non-trivial, suggest `r3-sources-learn` / `r3-sources-link` first.
Otherwise, for each open task (`- [ ]`):

- announce the task; make the minimal, focused code changes it requires (within the slice's `Owns:`);
- **mark its state in `tasks.md`** immediately: `- [x]` done · `- [!]` blocked · `- [?]` needs-decision ·
  `- [-]` skipped (note why);
- continue to the next task.

**Don't stall silently:** a task is unclear → mark `- [?]` and ask; an error/blocker → mark `- [!]` and report; a
design issue surfaces → suggest updating `design.md`/`specs`; the user interrupts → stop. Re-attempt `[!]`/`[?]`
tasks once resolved.

### Step 4 — Report

Show progress (N/M tasks; flag any `[!]` blocked / `[?]` needs-decision). When no open tasks remain, say the change is ready to verify (`r3-sdd-verify`) or close (`r3-sdd-close`).

## Constraints

- Keep changes minimal and aligned with the spec; the spec/design are the contract.
- Update the state right after each task — progress is read from `tasks.md` task states (`[ ]`/`[x]`/`[!]`/`[?]`/`[-]`), there is no tracker.
- If implementation should change the agreed behavior, update the artifacts rather than silently diverging.

## References

- `references/strict-tdd.md` — the strict-TDD module (RED→GREEN→TRIANGULATE→REFACTOR cycle, Cycle Evidence table, assertion rubric); loaded only when strict-TDD is active (0 tokens otherwise).
