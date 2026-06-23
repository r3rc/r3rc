# Rule: SDD spec format, delta DSL & merge (engine-free)

Applies to any project using the r3 Spec-Driven Development workflow (`r3-sdd-*`). Defines the spec format, the
delta DSL, the agent-driven merge, and the validation self-check. Pairs with [`sdd-schema`](sdd-schema.md) and
[`sdd-domain-format`](sdd-domain-format.md).

---

## Spec format (the source-of-truth `_contracts/specs/<capability>/spec.md`)

```markdown
# <Capability> Specification

## Purpose

<one-paragraph description of this capability's domain>

## Key Entities <!-- optional — include only if the capability involves domain data -->

- **<Entity>**: <what it represents; key relationships> — behavior-level, no types

## Requirements

### Requirement: <name>

- **ID**: REQ-001

The system SHALL <normative behavior>.

#### Scenario: <name>

- **GIVEN** <precondition> <!-- optional: omit if there is no meaningful precondition -->
- **WHEN** <condition>
- **THEN** <expected outcome>
- **AND** <optional further outcome>
```

A spec is a **behavior contract, not an implementation plan.** No class/function names, library choices, or
step-by-step code — those belong in `design.md`/`tasks.md`. Progressive rigor: keep specs lite by default; go
full only for higher-risk / cross-cutting / contract / migration changes.

### Requirements & RFC 2119

- `### Requirement:` headers carry the behavior. Each requirement's **normative keyword MUST appear in the body
  line** (the line after the header / after any metadata bullets), NOT only in the header name. The check is
  **case-sensitive**: `\b(SHALL|MUST)\b`.
- Keyword set (English): **MUST / MUST NOT / REQUIRED / SHALL / SHALL NOT / SHOULD / SHOULD NOT / RECOMMENDED /
  MAY / OPTIONAL**. SHALL/MUST = absolute (the default); prohibitions use MUST NOT / SHALL NOT; SHOULD =
  recommended; MAY = optional.
- A requirement body over ~500 characters is a smell — consider splitting it.

### Requirement IDs

- Each requirement carries a stable ID as a metadata bullet right under the header: `- **ID**: REQ-001`.
- IDs are `REQ-###` (zero-padded), assigned sequentially and **unique within a capability spec**. On REMOVED, an
  ID is **retired, never reused** (so external references stay unambiguous).
- The ID is a **traceability anchor**, not the merge key — the merge matches requirements by header **name** (see
  Merge). The ID rides in the body, so it **survives a rename**. Tasks, `/analyze`, and tests reference a
  requirement as **`[[REQ-###]]`** (the WikiLink-resolving MCP is deferred; `[[…]]` is plain text until wired).

### Key Entities (glossary)

- `## Key Entities` is an OPTIONAL, top-level section (sibling of `## Purpose`) — a **behavior-level glossary**
  establishing the shared/ubiquitous language: entity name + what it represents + key relationships. **No types,
  no fields.**
- It is **non-deltable**, exactly like `## Purpose` — prose the author maintains; the delta DSL does NOT track it.
  The rigorous, materialized model lives in `design.md`'s `## Domain Model` (see `sdd-domain-format`); this
  glossary is the durable summary. Glossary drift (a requirement referencing an undefined entity) is caught by
  `/analyze`, not the merge.
- Entities are referenced by **name** (`[[Product]]`) — the name is the stable anchor.

### Scenarios (Given/When/Then)

- **`#### Scenario:` MUST use exactly four hashtags** and a named scenario, with GWT bullets.
- **GIVEN is optional** (a precondition) — omit it when there is none; a scenario may start at WHEN. **WHEN** and
  **THEN** are required. **AND** continues a step; **BUT** is allowed for a negative continuation.
- **Every requirement MUST have ≥1 scenario**, and scenarios must be testable. Scenarios live **inline** under
  their requirement — never in a separate `scenarios.md`/`.feature` file (that would break the delta/merge, which
  operates on requirement blocks including their scenarios). Spec length is managed by splitting **per
  capability**, not per file.

### NEEDS CLARIFICATION

- A draft spec marks genuine ambiguities inline as `[NEEDS CLARIFICATION: <specific question>]`, capped at **≤3**
  (priority to keep: scope > security/privacy > UX > technical; resolve the rest with informed defaults).
- A **ready/finalized spec MUST have zero** markers. Resolution is inline (edit the requirement); open questions
  persist as the markers themselves.

### Success criteria & non-functional requirements

- There is **no `## Success Criteria` section.** Measurable / non-functional goals (latency, throughput,
  reliability %) are modeled **as requirements** (a measurable SHALL + a scenario asserting the metric, e.g.
  "THEN p95 ≤ 200 ms"). Business KPIs / post-launch metrics are not system behavior — they belong in
  `proposal.md` ("why"), not the contract.

---

## Delta DSL (the per-change `_contracts/changes/<slug>/specs/<capability>/spec.md`)

A change spec is a **delta** against the source-of-truth spec, using these `##` sections:

```markdown
## ADDED Requirements

### Requirement: <name>

- **ID**: REQ-00N

...the requirement body + one or more #### Scenario: blocks...

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

Format details (how the delta is parsed):

- New capability → the change spec is effectively all `## ADDED Requirements`; it becomes the new source spec on
  archive.
- Match requirements by their `### Requirement:` header text — **whitespace-trimmed but case-SENSITIVE**.
- Section titles are **case-insensitive** (`## added Requirements` == `## ADDED Requirements`).
- The requirement header regex is case-insensitive on `Requirement:`, exactly **three** hashes; the name may
  contain colons.
- **REMOVED** entries accept either a bare header `### Requirement: <name>` OR a bulleted form
  `` - `### Requirement: <name>` ``.
- **RENAMED** FROM/TO lines allow an optional `-` bullet and optional backticks around the header.
- Fenced code blocks are stripped before header detection — example delta blocks inside ``` fences are safe.

---

## Merge: applying a change's delta into the source spec (the `r3-sdd-sync` operation — agent-driven)

**Agent-driven intelligent merging**, NOT a wholesale block-replace. Read the delta spec and the main spec, then
edit the main spec in place. **Apply order:** RENAMED → REMOVED → MODIFIED → ADDED.

- **RENAMED** → find the FROM requirement, rename it to TO. FROM not found → error; TO already exists → error.
- **REMOVED** → delete the entire requirement block. On an existing spec, name not found → error.
- **MODIFIED** → apply the change to the existing requirement (add a scenario, edit a scenario, change the
  description). **Partial updates are allowed** — to add one scenario you include only that scenario; you do NOT
  copy the existing ones. **Preserve any content not mentioned in the delta** (including the `**ID**:` bullet).
  Name not found → error. The block's header must **match the key literally** (header-mismatch → error).
- **ADDED** → if absent, add it; if it already exists, update it to match (implicit MODIFIED).

Constraints & invariants:

- **New spec:** if the capability's source spec does not exist, only **ADDED** is valid — MODIFIED / RENAMED are
  a hard error; REMOVED is silently skipped. Create `_contracts/specs/<capability>/spec.md` with a skeleton:
  `# <Capability> Specification` + `## Purpose` (TBD, update after archive) + `## Requirements` + the ADDED
  requirements.
- **Ordering of the rebuilt spec:** existing requirements keep their original order; newly ADDED requirements are
  appended at the end. The **preamble** (text between `## Requirements` and the first `### Requirement:`) is
  preserved.
- **Two-phase** (the agent's discipline, no engine): validate the delta → build the rebuilt spec → re-validate it
  → only then write. Never leave a half-merged spec on disk.
- Collapse 3+ consecutive blank lines to 2 in the rebuilt spec.
- The operation is **idempotent** — running it twice yields the same result.

---

## Structural validity (agent invariants — checked, not tool-enforced)

- A **source** spec (`_contracts/specs/...`) keeps `### Requirement:` headers inside the `## Requirements`
  section and NEVER contains delta headers (`## ADDED/MODIFIED/REMOVED/RENAMED`).
- A **delta** spec (`changes/<slug>/specs/...`) uses the delta headers and targets a capability by folder name.

---

## Validation (an agent self-check, not a binary)

When asked to validate, self-check against these and report issues (do not silently fix). In **strict mode**,
warnings count as failures; default mode fails only on errors.

**Structural (ERROR):**

- `## Purpose` present; `## Requirements` present.
- A `### Requirement:` header outside the `## Requirements` section is an ERROR (it is invisible to validate /
  list / archive).
- A **main** spec containing any delta header (`## ADDED/…`) is an ERROR.
- Every requirement has ≥1 `#### Scenario:` (exactly `####`, with WHEN/THEN). REMOVED entries need neither
  SHALL/MUST nor a scenario.
- Each requirement's normative keyword (SHALL/MUST, case-sensitive) is in the **body**, not only the header.
- IDs unique within the capability.

**Content (WARNING / INFO):**

- `## Purpose` under ~50 characters → WARNING (too brief).
- A requirement body over ~500 characters → INFO (consider splitting).
- A ready spec with any `[NEEDS CLARIFICATION]` marker → WARNING.

**Delta well-formedness & conflicts (ERROR):**

- The change has ≥1 delta operation; REMOVED has Reason + Migration; RENAMED has a FROM/TO pair.
- No requirement appears in **conflicting delta sections** — the full set: MODIFIED+REMOVED, MODIFIED+ADDED,
  ADDED+REMOVED, a RENAMED-FROM also in MODIFIED, a RENAMED-TO also in ADDED; and no duplicate name within
  ADDED / MODIFIED / REMOVED, no duplicate FROM or TO within RENAMED.
