# Rule: SDD schema & lifecycle (engine-free)

Applies to any project using the r3 Spec-Driven Development workflow (the `r3-sdd-*` skills). There is **no CLI
engine** — the agent performs every deterministic job (scaffold, status, sync, validate) by following the rules
below.

---

## Directory model

```
_contracts/
├── constitution.md                     # project governance: principles + standards + ## Testing
├── context-map.md                      # strategic: relationships between capabilities (see sdd-domain-format)
├── specs/                              # SOURCE OF TRUTH (living current behavior, edited directly)
│   └── <capability>/spec.md            # kebab-case capability/domain
├── changes/                            # numbered chronological log; a change stays in place once closed
│   └── <NNN-change-slug>/              # NNN = zero-padded sequential (assigned by `sdd.ps1 new`); kebab slug
│       ├── proposal.md                 # why + what + impacted capabilities + ## Spec Impact
│       ├── spec.md                     # FULL self-contained spec of what this change establishes
│       ├── design.md                   # how: Domain Model + Constitution Check (depth optional)
│       ├── tasks.md                    # implementation checklist (phase/slice structure)
│       └── checklists/<domain>.md      # optional requirement-quality checklists
└── explorations/                       # pre-change investigation notes (r3-sdd-explore)
```

Naming is fixed: capabilities are **kebab-case**; change folders are **`NNN-slug`** (zero-padded sequential
number + kebab slug, `NNN` auto-assigned by `sdd.ps1 new` by scanning existing changes). A closed change stays in place — the numbering is the chronology and git is the history. Each change also carries a stable opaque **id** (assigned by `sdd.ps1 new`) in its `proposal.md` frontmatter — the durable cross-branch anchor; the `NNN-slug` folder name may be renumbered on a collision, but the id never changes.

## Artifact graph (the `spec-driven` schema)

```
proposal ──► spec ──► tasks ──► apply ──► sync (close)
    └──────► design ─┘
```

- `proposal` requires nothing. `spec` requires `proposal`. `design` requires `proposal`. `tasks` requires `spec` +
  `design`. `apply` requires `tasks`. `sync` (the close) requires `apply` done.
- **`design.md` is conditional in DEPTH, not in existence** — always create it (`tasks` depends on it). Write a full
  design when warranted (cross-cutting change, new dependency/data model, security/perf/migration complexity, or
  genuine ambiguity); otherwise a one-line note ("No dedicated design needed — straightforward; see proposal/tasks.")
  is enough.
- **Dependencies enable, they don't dictate a rigid order.** You may draft `spec` and `design` in either order once
  `proposal` exists; an artifact is "ready" only once its dependency files exist.

## Status derivation (replaces the engine's `status`/graph — the agent computes this by reading the dir)

For a change folder, derive each artifact's state from **file existence**, not from any tool:

| State     | Rule                                                                    |
| --------- | ----------------------------------------------------------------------- |
| `done`    | the artifact's output file exists and is non-empty (`spec` → `spec.md`) |
| `ready`   | not done, and every artifact in its `requires` list is `done`           |
| `blocked` | not done, and some required artifact is not done                        |

- `isComplete` = every planning artifact is `done`.
- "apply-ready" = the schema's `apply.requires` are `done` (for `spec-driven`: `tasks` is done).
- **list changes** = the subdirectories of `_contracts/changes/` (the whole chronological log; sort by the `NNN`
  prefix). A change is **in progress** while `tasks.md` has any open task — `- [ ]` todo, `- [!]` blocked, or
  `- [?]` needs-decision (`- [-]` is a deliberately skipped task); it is **closed** once applied and **synced**
  (the living spec reflects it — git records the sync commit; there is no folder move).

## Project configuration & governance

The workflow schema is fixed (`spec-driven`). Per-project background, standards,
and mandates live in **`_contracts/constitution.md`** (binding principles + a `## Testing` section holding the
test runner / layers / coverage + the strict-TDD mandate); the SDD conventions themselves
(`sdd-schema`, `sdd-spec-format`, `sdd-domain-format`) are **canonical under `.agents/skills/_shared/`**, and the
cross-project tech-agnostic coding rules under `.agents/rules/`. All are **read explicitly** by the workflow
(engine-neutral; the `_shared/` conventions are also symlinked into `.agents/rules/` for harnesses that scan
that folder), and are constraints for the author — never content copied into artifacts.

## Proposal validation (agent self-check, NON-blocking)

When validating a `proposal.md` (e.g. at close), report — but do NOT block on — these:

- `why` (the motivation) present and ≥ ~50 characters; over ~1000 → WARNING.
- the change's `spec.md` establishes ≥1 requirement; more than ~10 requirement changes → WARNING (consider splitting).
- the `## Spec Impact` section is present and lists what the change adds / modifies / removes (with a reason +
  migration for each removal).

Only the **spec validation** (in [`sdd-spec-format`](sdd-spec-format.md)) is the blocking check; proposal
validation is advisory.

## No-engine principle

There is no CLI/engine binary. Every deterministic job is done by the agent: scaffolding = `mkdir` + write
templates; "status"/"list" = read the dirs per the table above; **specs evolve by direct edit — `sync` edits the
living `specs/<capability>/spec.md` and verifies integrity via `git diff`** (see
[`sdd-spec-format`](sdd-spec-format.md)); "validate" = the agent self-check in the same rule. A closed change stays numbered-in-place and **git is the
history**. There
is no per-tool command generation (r3 uses symlinks + AGENTS.md), no workspaces, no telemetry, and no per-change
metadata file.
