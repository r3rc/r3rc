---
name: r3-sdd-checklist
description: >
    Spec-Driven Development — generate a requirement-QUALITY checklist for a concern (security, ux, api…):
    "unit tests for English" that probe whether the requirements are complete / clear / consistent, NOT whether
    code works. Optional, for quality-critical domains. Triggers (EN+ES): "sdd checklist", "quality checklist",
    "checklist de calidad", "revisa la calidad de los requirements", "checklist de seguridad/ux".
user-invocable: true
---

# r3-sdd-checklist — requirement-quality checklist ("unit tests for English")

OPTIONAL. Generates a per-concern checklist that validates requirement QUALITY (not implementation). Conventions:
convention `sdd-spec-format`.

## Steps

### Step 1 — Select the change + concern

Pick the change and the concern/domain (security, ux, api, error-handling…). One checklist per concern.

### Step 2 — Author the checklist

Create `_contracts/changes/<slug>/checklists/<concern>.md`. Each item: `- [ ] CHK### <question testing a
requirement's quality> [<dimension>, [[REQ-###]]]`. Dimensions: Completeness / Clarity / Consistency /
Measurability / Coverage. **≥80% of items MUST cite** a `[[REQ-###]]` or a `[Gap]` / `[Ambiguity]` / `[Conflict]`
/ `[Assumption]` marker. `CHK###` IDs increment globally; append if the file already exists.

### Step 3 — Report

Report the checklist path and item count. `r3-sdd-apply` MAY gate on incomplete checklists when present.

## Output Contract

- `_contracts/changes/<slug>/checklists/<concern>.md` — `CHK###` quality items with dimension tag + spec refs.

## Constraints

- Checks requirement QUALITY, not behavior — never asserts the system works (that is `verify` / tests).
- Optional and per-concern; not a core pipeline step.
