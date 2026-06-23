---
name: r3-artifact-improve
description: >
    Audit and refactor a single skill against the canonical format defined in
    _shared/skill-format.md: section order, body budget, named
    pauses, output contract, broken references. Audit-only by default — applies
    changes only after explicit approval. Use when the user says "improve this
    skill", "mejora el skill", "audita el skill", "refactoriza el skill", "el skill
    está muy largo", or when r3-artifact-audit flags content issues in one skill.
allowed-tools: [Bash, Read, Edit, Write]
user-invocable: true
---

# r3-artifact-improve — Audit and refactor one artifact

Audits a single skill against the canonical format and, after approval, applies the fixes.
Complements `r3-artifact-audit`: audit scans the whole workspace structurally; improve goes
deep on the content of one artifact.

## Decision gates

| Finding                                 | Action                                                                                                                                                                       |
| --------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Body over budget (see format reference) | Move examples/anti-patterns to `references/`, preserve every rule. If the overflow is load-bearing (decision tables, generation templates), accept the flag — do not move it |
| Sections out of canonical order         | Reorder per `skill-format.md`                                                                                                                                                |
| Branching written as prose              | Convert to a situation → action table                                                                                                                                        |
| Constraints mixed into Steps            | Extract to a Constraints section                                                                                                                                             |
| Description without trigger phrases     | Rewrite: triggers first, English and Spanish                                                                                                                                 |
| Pauses without name or declared output  | Name them and declare what they present and await                                                                                                                            |
| Produces files but no Output Contract   | Add one with concrete paths and formats                                                                                                                                      |
| References to files that do not exist   | Fix the path or remove the reference                                                                                                                                         |

## Steps

### Step 1 — Read the target

Read the target `SKILL.md` in full, plus its `references/` directory if present. Read
`.agents/skills/_shared/skill-format.md` as the audit criteria.

### Step 2 — Audit

Check the skill against every row of the decision gates table and every rule in the format
reference.

**⏸ Audit report of `<skill-name>`** — present findings grouped by severity
(blocking / improvement / nitpick), each with a concrete proposed change. Wait for the user
to approve all, some, or none.

### Step 3 — Apply (only approved changes)

Apply only what was approved. Create `references/` if material is being moved. Use surgical
edits — do not rewrite the whole file.

### Step 4 — Verify

Confirm the body budget of the result, that the original intent is preserved, and that every
link in the refactored skill resolves to a file on disk.

## Output Contract

Audit mode:

- Findings report grouped by severity, with a concrete proposed change for each.

Apply mode:

- `.agents/skills/<name>/SKILL.md` refactored
- `.agents/skills/<name>/references/` with moved content (if any)
- One-line before/after summary (sections fixed, body budget)

## Constraints

- Preserve the skill's intent and original constraints. Never rewrite its business logic.
- Never delete content without moving it to `references/`. If it exists, someone put it there for a reason.
- Default mode is audit. Modify files only after the user explicitly approves.
- Never invent rules, triggers, or outputs that were not in the original skill.
- Scope is skills for now. For rules, agents, workflows, or MCP entries, run
  `r3-artifact-audit` instead — their structure is too thin to need a refactor pass.
- Never change the skill's `name:` — renaming is `r3-artifact-remove` + `r3-artifact-create`.
