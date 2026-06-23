## Context

<!-- Background and current state. Related: [[proposal]], affected [[spec]]s. -->

## Constitution Check

<!-- GATE: must pass before tasks. Derive the checks from _contracts/constitution.md's principles at runtime
     (NOT hardcoded). Re-verified at r3-sdd-verify. Examples: -->
<!-- - [ ] Test-first plan present (strict-TDD mandate) -->
<!-- - [ ] No unjustified complexity / dependencies -->

## Goals / Non-Goals

**Goals:**

<!-- What this design aims to achieve -->

**Non-Goals:**

<!-- What is explicitly out of scope -->

## Domain Model

<!-- OPTIONAL — include only if the change touches domain data. Conceptual, by domain nature
     (count / money / identifier / enum / text), NEVER language/storage types. See sdd-domain-format. -->

### Entities

<!-- - **Name** — identity: `id`; `attr` (count ≥ 0); `kind` (enum: a | b) -->

### Relationships

<!-- - `A` *—1 `B`; `A.x` derived from `B` -->

### Lifecycle

<!-- - `Entity`: stateA → stateB → (stateC | stateD) -->

### Invariants

<!-- - `X` MUST be ≥ 0  (RFC 2119) -->

### Consistency boundaries

<!-- optional — which entities change atomically together (a slice must not split a boundary) -->

## Decisions

<!-- Key design decisions and rationale (Decision / Rationale / Alternatives) -->

## Risks / Trade-offs

<!-- Known risks and trade-offs -->

## Complexity Tracking

<!-- Fill ONLY if the Constitution Check has violations to justify. -->
<!-- | Violation | Why Needed | Simpler Alternative Rejected Because | -->
