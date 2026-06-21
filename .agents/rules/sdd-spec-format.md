# Rule: SDD spec format, delta DSL & merge (engine-free)

Applies to any project using the r3 Spec-Driven Development workflow (`r3-sdd-*`). Defines the spec format, the
delta DSL, the agent-driven merge, and the validation self-check. Pairs with [`sdd-schema`](sdd-schema.md).

---

## Spec format (the source-of-truth `openspec/specs/<capability>/spec.md`)

```markdown
# <Capability> Specification

## Purpose

<one-paragraph description of this capability's domain>

## Requirements

### Requirement: <name>

The system SHALL <normative behavior>.

#### Scenario: <name>

- **WHEN** <condition>
- **THEN** <expected outcome>
- **AND** <optional further outcome>
```

Rules:

- A spec is a **behavior contract, not an implementation plan.** No class/function names, library choices, or step-by-step code — those belong in `design.md`/`tasks.md`.
- `### Requirement:` headers carry the behavior; use **SHALL/MUST** for normative requirements (avoid should/may unless deliberately weaker). RFC 2119: MUST/SHALL = absolute, SHOULD = recommended, MAY = optional.
- **`#### Scenario:` MUST use exactly four hashtags** and GIVEN/WHEN/THEN(/AND) bullets. Three hashtags or bullets break the convention.
- **Every requirement MUST have at least one scenario**, and scenarios must be testable (you could write an automated test from each).
- Progressive rigor: keep specs lite by default (short behavior-first requirements, clear scope, a few acceptance checks); go full only for higher-risk/cross-cutting/contract/migration changes.

## Delta DSL (the per-change `openspec/changes/<slug>/specs/<capability>/spec.md`)

A change spec is a **delta** against the source-of-truth spec, using these `##` sections:

```markdown
## ADDED Requirements

### Requirement: <name>

...one or more #### Scenario: blocks...

## MODIFIED Requirements

### Requirement: <existing name>

...the changed requirement...

## REMOVED Requirements

### Requirement: <existing name>

**Reason**: <why>
**Migration**: <what consumers should do>

## RENAMED Requirements

- FROM: `### Requirement: <old name>`
- TO: `### Requirement: <new name>`
```

- New capability → the change spec is effectively all `## ADDED Requirements`; it becomes the new source spec on archive.
- Match requirements by their `### Requirement:` header text (whitespace-insensitive).

## Merge: applying a change's delta into the source spec (the `r3-sdd-sync` operation — agent-driven)

This is **agent-driven intelligent merging**, NOT a wholesale block-replace. Read the delta spec and the main spec,
then edit the main spec in place:

- **ADDED** → if the requirement is absent, add it; if it already exists, update it to match (implicit MODIFIED).
- **MODIFIED** → apply the change to the existing requirement. This may be adding a scenario, editing a scenario, or
  changing the description. **You can apply partial updates — to add one scenario you include only that scenario; you
  do NOT need to copy the existing ones. Preserve any content not mentioned in the delta.**
- **REMOVED** → delete the entire requirement block.
- **RENAMED** → find the FROM requirement, rename it to TO.
- If the capability's main spec does not exist yet, create `openspec/specs/<capability>/spec.md` with a `## Purpose`
  (may be brief / TBD) and a `## Requirements` section holding the ADDED requirements.
- The operation is **idempotent** — running it twice yields the same result.

Apply order when several operations touch one spec: RENAMED → REMOVED → MODIFIED → ADDED.

## Structural validity (the agent's invariants — checked, not enforced by a tool)

- A **source** spec (`openspec/specs/...`) must keep `### Requirement:` headers inside the `## Requirements` section and
  must NEVER contain delta headers (`## ADDED/MODIFIED/REMOVED/RENAMED`).
- A **delta** spec (`changes/<slug>/specs/...`) uses the delta headers and targets a capability by folder name.

## Validation (an agent self-check, not a binary)

When asked to validate a spec/change, self-check against these and report issues (do not silently fix):

- every `### Requirement:` has ≥1 `#### Scenario:`; scenarios use exactly `####` and WHEN/THEN;
- normative requirements use SHALL/MUST; `## Purpose` is present and meaningful;
- delta sections are well-formed (REMOVED has Reason+Migration; RENAMED has FROM/TO);
- no requirement appears in conflicting delta sections; the change has at least one delta operation.
