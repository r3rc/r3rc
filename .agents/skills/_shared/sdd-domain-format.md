# Rule: SDD domain-model format (DDD-lite notation)

Applies to any project using the r3 Spec-Driven Development workflow (`r3-sdd-*`). Defines the **DDD-lite
notation** — a lightweight, plain-markdown way to model the domain that is to structure what Given/When/Then
is to behavior. Pairs with [`sdd-schema`](sdd-schema.md) and [`sdd-spec-format`](sdd-spec-format.md).

It has two halves: the **tactical** model (`## Domain Model`, inside a change's `design.md`) and the
**strategic** map (`_contracts/context-map.md`, durable, project-level).

---

## Principles

- **Conceptual, not physical.** Capture domain TRUTHS — identity, relationships, invariants, state — by their
  **domain nature** (`count ≥ 0`, `money`, `identifier`, `enum: …`, `text`, `timestamp`), NEVER by language or
  storage types (`u32`, `Decimal`, `varchar`). Concrete types are an implementation decision; the **code is the
  source of truth for types**, and the model must not duplicate or drift from it.
- **No ceremony.** Plain language. Do NOT use the formal labels `aggregate`, `value object`, `repository`,
  `bounded context`. Model the domain clearly; skip the vocabulary.
- **Depth scales to the domain.** Light by default; elaborate only what the domain demands. Include a section
  only when it carries meaning.
- **Two tiers.** The spec's `## Key Entities` (see `sdd-spec-format`) is the durable, behavior-level **glossary**
  (shared language). The `## Domain Model` here is the per-change **materialized** model. Same entity names.

---

## Tactical — `## Domain Model` (in `design.md`)

A section with these sub-sections (use the ones that carry meaning):

```markdown
## Domain Model

### Entities

- **Product** — identity: `sku`
    - `name` (text)
    - `unit` (enum: each | kg | liter)
- **InventoryItem** — identity: (`product` × `warehouse`)
    - `available` (count ≥ 0)
    - `reserved` (count ≥ 0)
- **StockMovement** — identity: `id` (opaque)
    - `qty` (count > 0)
    - `kind` (enum: inbound | outbound | transfer)
    - `status` (see Lifecycle)

### Relationships

- `InventoryItem` 1—1 (`Product` × `Warehouse`)
- `StockMovement` _—1 `Product`, _—1 `Warehouse`
- `InventoryItem.available` is **derived from** confirmed `StockMovement`s

### Lifecycle

- `StockMovement`: draft → confirmed → (posted | cancelled) # only `confirmed` affects inventory

### Invariants

- `InventoryItem.available` MUST be ≥ 0
- an outbound's `qty` MUST NOT exceed `available` at confirm time
- `Product.sku` is immutable

### Consistency boundaries

- `{ InventoryItem }` changes atomically (the `available ≥ 0` invariant is enforced here)
- `StockMovement` is its own boundary (confirmed independently)
```

Notation:

- **`### Entities`** — `- **Name** — identity: <what makes it unique>`, then attributes as `\`name\` (<nature>)`.
Nature, not type: `count`, `money`, `identifier`, `enum: a | b | c`, `text`, `timestamp`, with constraints
(`≥ 0`, `> 0`, `unique`, `immutable`) inline.
- **`### Relationships`** — multiplicity with `1—1`, `*—1`, `*—*`; ownership and `derived from` for computed
  values.
- **`### Lifecycle`** — `Entity: stateA → stateB → (stateC | stateD)` for entities that have states.
- **`### Invariants`** — normative rules in **RFC 2119** (MUST / MUST NOT), the same grammar as spec requirements
  (see `sdd-spec-format`). These constrain the implementation and drive tests. An invariant may also be an
  **architectural prohibition** — a forbidden dependency/import/path, e.g. "the domain layer MUST NOT import
  `infrastructure/**`". These are checkable boundaries, re-checked by the Constitution Check gate.
- **`### Consistency boundaries`** (optional, Q-driven) — name which entities change **atomically together**
  (the useful core of "aggregates", without the label). A change's slice MUST NOT split a consistency boundary.

The `## Domain Model` is OPTIONAL — include it only when the change touches domain data.

---

## Strategic — `_contracts/context-map.md` (durable, project-level)

A single durable file mapping the relationships **between capabilities** (not entities). Edited directly as
prose, like `## Purpose` — the author keeps it current as capabilities and relationships evolve. It stays small because
it captures only the (sparse) edges between capabilities; a large context map is a coupling smell to address,
not a file to split.

```markdown
# Context Map

- **Warehouses → Inventory** — customer-supplier; Inventory is **upstream** (source-of-truth for available
  stock). Warehouses does not write inventory directly; it goes through Inventory's interface
  (**anti-corruption boundary**).
    - Interaction: `StockMovement confirmed` (Warehouses) → `available` decremented (Inventory)
```

Notation:

- One bullet per capability relationship: `- **A → B** — <relationship-type>`, with a one-line rationale.
- **Relationship types** (use the ones that fit): `customer-supplier`, `upstream` / `downstream`,
  `source-of-truth`, `anti-corruption boundary`, `shared kernel`.
- Under each relationship, an **Interaction** line names the boundary-crossing event:
  `<event> (A) → <effect> (B)`. The behavioral _effect_ itself is a `#### Scenario:` in the triggering
  capability's spec; this is the strategic summary.

---

## Cross-references (WikiLinks)

- Entities are referenced by **name**: `[[entity:Product]]` (the name is the stable anchor — renaming an entity is a
  deliberate ubiquitous-language change).
- Requirements are referenced by their **ID**: `[[REQ-###]]` (see `sdd-spec-format`); principles and checklist
  items likewise: `[[PRIN-###]]`, `[[CHK-###]]`.
- Sibling artifacts are referenced by filename: `[[proposal]]` / `[[spec]]` / `[[design]]` / `[[tasks]]` /
  `[[context-map]]` — each resolves to that file in the change folder (or the durable `_contracts/context-map.md`).
- The MCP that resolves these is deferred; `[[…]]` is plain text until it is wired.

---

## Structural validity (agent self-check)

- The `## Domain Model` lives in `design.md` (it is per-change design — not part of the living specs).
- `_contracts/context-map.md` is durable and project-level, edited directly; relationships use the vocabulary above.
- Attributes carry **domain nature, never language/storage types**; flag any concrete type as a violation.
- Invariants use MUST / MUST NOT (RFC 2119).
- A consistency boundary must not be split across slices in `tasks.md`.
