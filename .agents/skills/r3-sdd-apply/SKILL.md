---
name: r3-sdd-apply
description: >
    Spec-Driven Development — implement a change: work through its tasks.md checklist, writing code and checking
    off tasks as you go. Triggers (EN+ES): "apply the change", "implement the change", "sdd apply", "work the
    tasks", "implementa el cambio", "aplica el cambio", "trabajemos las tareas", "ejecuta las tareas".
user-invocable: true
---

# r3-sdd-apply — implement a change's tasks

Implement the tasks of a change, marking progress as you go. Conventions live in the auto-loaded rules `sdd-schema`
and `sdd-spec-format`.

## Steps

### Step 1 — Select the change

Use the change name if given; else infer from the conversation; else auto-select when only one active change exists;
otherwise list `openspec/changes/` (excluding `archive/`) and ask which one. Announce "Using change: `<slug>`".

### Step 2 — Load context

Read the change's artifacts: `proposal.md`, `specs/<capability>/spec.md`, `design.md` (if present), `tasks.md`.
Confirm the change is apply-ready (`tasks.md` exists — see status derivation in `sdd-schema`); if a required artifact
is missing, stop and suggest `r3-sdd-continue`.

### Step 3 — Implement tasks (loop until done or blocked)

For each pending task (`- [ ]`):

- announce the task; make the minimal, focused code changes it requires;
- **mark it complete in `tasks.md`: `- [ ]` → `- [x]`** immediately after finishing it;
- continue to the next task.

**Pause if:** a task is unclear (ask); implementation reveals a design issue (suggest updating `design.md`/`specs`); an
error or blocker appears (report and wait); or the user interrupts.

### Step 4 — Report

Show progress (N/M tasks). When all tasks are `- [x]`, say the change is ready to verify (`r3-sdd-verify`) or archive
(`r3-sdd-archive`).

## Constraints

- Keep changes minimal and aligned with the spec; the spec/design are the contract.
- Update the checkbox right after each task — progress is read from `tasks.md` (`- [ ]` vs `- [x]`), there is no tracker.
- If implementation should change the agreed behavior, update the artifacts rather than silently diverging.
