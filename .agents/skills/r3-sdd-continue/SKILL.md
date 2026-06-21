---
name: r3-sdd-continue
description: >
    Spec-Driven Development — create the NEXT artifact for an in-progress change (one artifact, then stop).
    Advances proposal → specs → design → tasks step by step. Triggers (EN+ES): "continue the change", "sdd
    continue", "next artifact", "keep going on the change", "continúa el cambio", "siguiente artefacto", "seguí
    con el cambio", "avanza el cambio".
user-invocable: true
---

# r3-sdd-continue — create the next artifact for a change

Advance an in-progress change by creating exactly ONE next artifact, then stop. Conventions and the status rules
live in the auto-loaded rules `sdd-schema` and `sdd-spec-format`.

## Steps

### Step 1 — Select the change

If not given, list `openspec/changes/` (excluding `archive/`), sorted by most-recently modified, and ask which one
(mark the most recent as recommended). Do NOT auto-select.

### Step 2 — Derive status and pick the next artifact

Per `sdd-schema`, derive each artifact's state from file existence: `done` = its file exists; `ready` = all its
`requires` are done; `blocked` otherwise. If everything is done, congratulate and stop (suggest `r3-sdd-apply` or
`r3-sdd-archive`). Otherwise pick the **first `ready`** artifact in graph order (`proposal → {specs, design} → tasks`).

### Step 3 — Create that one artifact

Read the completed dependency files for context. Create the artifact by copying its template from
`.agents/skills/_shared/sdd/templates/` and filling it, applying `config.yaml` `context`/`rules`
as constraints (never copy them in). Use the format from `sdd-spec-format` for specs. Then **STOP** — one artifact per
invocation. If context is unclear, ask before writing.

### Step 4 — Report

Show what was created and what is now unlocked. Prompt to continue (`r3-sdd-continue`) or, if apply-ready, to
implement (`r3-sdd-apply`).

## Output Contract

Writes exactly ONE artifact file into `openspec/changes/<slug>/` — the next ready one: `proposal.md`, a `specs/<capability>/spec.md`, `design.md`, or `tasks.md`.

## Constraints

- Exactly ONE artifact per invocation; never skip or reorder the graph.
- Read dependencies first; verify the file exists after writing.
- `design.md` is conditional in depth: always create it (`tasks` depends on it), but a one-line note suffices when a dedicated design isn't warranted.
