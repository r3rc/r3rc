# Rule: SDD schema & lifecycle (engine-free)

Applies to any project using the r3 Spec-Driven Development workflow (the `r3-sdd-*` skills). There is **no CLI
engine** — the agent performs every deterministic job (scaffold, status, merge, archive, validate) by following
the rules below.

---

## Directory model

```
openspec/
├── config.yaml                          # schema + context + rules (optional)
├── specs/                               # SOURCE OF TRUTH (current behavior)
│   └── <capability>/spec.md             # kebab-case capability/domain
└── changes/
    ├── <change-slug>/                   # kebab-case, one folder per change
    │   ├── proposal.md                  # why + what + capabilities + impact
    │   ├── design.md                    # how (optional — create only when warranted)
    │   ├── tasks.md                     # implementation checklist
    │   └── specs/<capability>/spec.md   # DELTA spec for this change
    └── archive/
        └── YYYY-MM-DD-<change-slug>/    # completed change, moved here on archive
```

Naming is fixed: capabilities and change slugs are **kebab-case**; the archive prefix is the ISO date
(`$(date +%F)` → `YYYY-MM-DD`). `changes/archive/` is excluded from the active-change list.

## Artifact graph (the `spec-driven` schema)

```
proposal ──► specs ──► tasks ──► implement(apply)
    └──────► design ──┘
```

- `proposal` requires nothing. `specs` requires `proposal`. `design` requires `proposal`. `tasks` requires `specs` +
  `design`. `apply` requires `tasks`.
- **`design.md` is conditional in DEPTH, not in existence** — always create it (`tasks` depends on it). Write a full
  design when warranted (cross-cutting change, new dependency/data model, security/perf/migration complexity, or
  genuine ambiguity); otherwise a one-line note ("No dedicated design needed — straightforward; see proposal/tasks.")
  is enough.
- **Dependencies enable, they don't dictate a rigid order.** You may draft `specs` and `design` in either order once
  `proposal` exists; an artifact is "ready" only once its dependency files exist.

## Status derivation (replaces the engine's `status`/graph — the agent computes this by reading the dir)

For a change folder, derive each artifact's state from **file existence**, not from any tool:

| State     | Rule                                                                                            |
| --------- | ----------------------------------------------------------------------------------------------- |
| `done`    | the artifact's output file exists and is non-empty (`specs` → any file under `<change>/specs/`) |
| `ready`   | not done, and every artifact in its `requires` list is `done`                                   |
| `blocked` | not done, and some required artifact is not done                                                |

- `isComplete` = every artifact is `done`.
- "apply-ready" = the schema's `apply.requires` are `done` (for `spec-driven`: `tasks` is done).
- **list active changes** = the subdirectories of `openspec/changes/` excluding `archive/` (sort by mtime when ordering matters).

## config.yaml

```yaml
schema: spec-driven # required — which workflow schema
context: | # optional — project background, injected as constraints into authoring
    ...
rules: # optional — per-artifact extra rules, keyed by artifact id
    specs: [...]
    tasks: [...]
```

Read it directly when present. `context`/`rules` are **constraints for the author, never content copied into artifacts.**

## No-engine principle

There is no CLI/engine binary. Every deterministic job is done by the agent: scaffolding = `mkdir` + write
templates; "status"/"list" = read the dirs per the table above; the spec merge = the agent-driven merge in
[`sdd-spec-format`](sdd-spec-format.md); "validate" = the agent self-check in the same rule; archive = `mkdir -p
openspec/changes/archive` + `mv` to `archive/$(date +%F)-<slug>`. There is no per-tool command generation (r3 uses
symlinks + AGENTS.md), no workspaces, no telemetry, and no per-change metadata file.
