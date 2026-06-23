# Rule: SDD spec format & validation (engine-free)

Applies to any project using the r3 Spec-Driven Development workflow (`r3-sdd-*`). Defines the spec format, how
specs evolve (direct edit + git), and the validation self-check. Pairs with [`sdd-schema`](sdd-schema.md) and
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

The **same format** is used in two places: the living source spec
(`_contracts/specs/<capability>/spec.md`) and a change's self-contained record
(`_contracts/changes/<NNN-slug>/spec.md`). Both are **full specs** in the format above (see "How specs evolve"). A change that spans more than one
capability groups its requirements under `## <Capability>`
headings in that single file.

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
- IDs are `REQ-###` (zero-padded), assigned sequentially and **unique within a capability spec**. When a
  requirement is removed, its ID is **retired, never reused** (so external references stay unambiguous).
- **Assignment:** a requirement added to an **existing** capability takes the **next free ID from the living
  capability spec** (highest ever issued + 1 — a retired ID still counts as issued; check git / `## Spec Impact`),
  **never restarting at `REQ-001`**. A genuinely new capability starts at `REQ-001`. This keeps the ID stable
  through the close — no renumbering.
- In a **multi-capability change**, if two capabilities would share a number, qualify the reference by capability:
  `[[auth/REQ-001]]`.
- The ID is a **traceability anchor** that **survives a rename** (it rides in the body, not the header). Tasks,
  `/analyze`, and tests reference a requirement as **`[[REQ-###]]`** (the WikiLink-resolving MCP is deferred;
  `[[…]]` is plain text until wired).

### Key Entities (glossary)

- `## Key Entities` is an OPTIONAL, top-level section (sibling of `## Purpose`) — a **behavior-level glossary**
  establishing the shared/ubiquitous language: entity name + what it represents + key relationships. **No types,
  no fields.**
- Like `## Purpose`, it is **prose the author edits directly**. The rigorous, materialized model lives in
  `design.md`'s `## Domain Model` (see `sdd-domain-format`); this glossary is the durable summary. Glossary drift
  (a requirement referencing an undefined entity) is caught by `/analyze`.
- Entities are referenced by **name** (`[[entity:Product]]`) — the name is the stable anchor.

### Scenarios (Given/When/Then)

- **`#### Scenario:` MUST use exactly four hashtags** and a named scenario, with GWT bullets.
- **GIVEN is optional** (a precondition) — omit it when there is none; a scenario may start at WHEN. **WHEN** and
  **THEN** are required. **AND** continues a step; **BUT** is allowed for a negative continuation.
- **Every requirement MUST have ≥1 scenario**, and scenarios must be testable. Scenarios live **inline** under
  their requirement — never in a separate `scenarios.md`/`.feature` file (a scenario is part of its requirement
  block). Spec length is managed by splitting **per capability**, not per file.

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

## How specs evolve (living spec + git)

A capability's `_contracts/specs/<capability>/spec.md` is a **living document, edited directly** — git is the
diff, history, and conflict-resolution engine.

- **During a change:** the work lives in `_contracts/changes/<NNN-slug>/` — a single self-contained `spec.md`
  (full, same format as a source spec; `## <Capability>` sections if it spans more than one) plus `proposal.md` /
  `design.md` / `tasks.md`. The living source spec is **not touched yet**; the change folder is the in-flight
  boundary.
- **At close (`r3-sdd-close`):** edit the living `specs/<capability>/spec.md` **directly** to reflect the completed
  change. The change folder stays as the immutable, numbered record.
- **`git diff specs/` is the record of what changed** — added lines = new requirements/scenarios, removed lines =
  removals, changed lines = modifications. `close` reads this diff to **verify integrity** (see Validation).
- **Semantic intent** (what was added / modified / removed, with reason + migration for a removal) is recorded in
  prose in the change's **`## Spec Impact`** section (in `proposal.md`).
- A **new capability** → at close, its requirements (from the change's `spec.md`) become the living
  `specs/<capability>/spec.md` (essentially a copy).

Integrity has two layers: **data integrity (nothing lost) is git** — structural, always-on, every prior state
recoverable; **quality validity** (below) is the `close` verify step over the diff, optionally delegated to a
fresh adversarial agent.

---

## Structural validity (agent invariants)

- A living source spec keeps `### Requirement:` headers inside its `## Requirements` section, and is always a
  **full spec** in the format above. A change's `spec.md` uses the same full format (optionally grouped by
  `## <Capability>`).
- A spec uses only the top-level sections `## Purpose`, `## Key Entities`, and `## Requirements` (a change's
  `spec.md` may add `## <Capability>` groupings); any other top-level section is an ERROR.

---

## Validation (an agent self-check, not a binary)

`r3-sdd-close` runs this over the **living spec** after editing it (using `git diff specs/` as evidence);
`r3-sdd-analyze` and `r3-sdd-verify` run it read-only. Report issues (do not silently fix). In **strict mode**,
warnings count as failures; default mode fails only on errors.

**Structural (ERROR):**

- `## Purpose` present; `## Requirements` present.
- A `### Requirement:` header outside the `## Requirements` section is an ERROR (invisible to validate / list).
- Every requirement has ≥1 `#### Scenario:` (exactly `####`, with WHEN/THEN).
- Each requirement's normative keyword (SHALL/MUST, case-sensitive) is in the **body**, not only the header.
- IDs unique within the capability; a retired ID is not reused.
- **Referential integrity:** every `[[REQ-###]]` / `[[PRIN-###]]` / `[[CHK-###]]` / `[[entity:Name]]` resolves to a
  definition — a dangling reference is an ERROR (grep defs vs refs); no two requirements share a `REQ-###` in one
  capability.
- Only the expected top-level sections appear (`## Purpose` / `## Key Entities` / `## Requirements`).

**Integrity over the diff (ERROR) — the `close` verify:**

- Every requirement/scenario **removed or renamed** in `git diff specs/` is **accounted for** by the change's
  `## Spec Impact` (an intended removal carries a reason + migration there). An unexplained deletion is an ERROR —
  it is most likely an accidental drop.
- The edit applied the change faithfully (the requirements the change establishes are present and correct).

**Content (WARNING / INFO):**

- `## Purpose` under ~50 characters → WARNING (too brief).
- A requirement body over ~500 characters → INFO (consider splitting).
- A ready spec with any `[NEEDS CLARIFICATION]` marker → WARNING.
