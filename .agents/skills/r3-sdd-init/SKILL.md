---
name: r3-sdd-init
description: >
    Spec-Driven Development — initialize the SDD workspace in a project: create the openspec/ tree and config so
    the r3-sdd-* workflow can run. Triggers (EN+ES): "init sdd", "sdd init", "set up spec-driven development",
    "initialize openspec", "inicializa sdd", "configura spec-driven", "prepara el proyecto para sdd", "arranca sdd".
user-invocable: true
---

# r3-sdd-init — initialize SDD in a project

Set up the `openspec/` structure so the SDD skills can operate. Conventions live in the auto-loaded rule `sdd-schema`.

## Steps

### Step 1 — Scaffold

From the project root (or with `SDD_OPENSPEC_DIR` set), run:

```bash
.agents/scripts/sdd.sh init
```

This creates `openspec/specs/`, `openspec/changes/archive/`, and `openspec/config.yaml` (idempotent — existing files
are kept).

### Step 2 — Fill project context (optional but recommended)

Edit `openspec/config.yaml`: set `schema: spec-driven`, and add a `context:` block (tech stack, architecture, testing,
product language, conventions) and per-artifact `rules:` if useful. These are injected as authoring constraints — they
are never copied into artifacts.

### Step 3 — Confirm

Report the created structure and point to `r3-sdd-propose` (all-in-one) or `r3-sdd-new` (step-by-step) to start the
first change.

## Output Contract

Creates (idempotent):

- `openspec/specs/` and `openspec/changes/archive/`
- `openspec/config.yaml` (`schema: spec-driven`; never overwritten if present)

## Constraints

- Idempotent — safe to run again; it never overwrites an existing `config.yaml` or specs.
- Targets `$PWD/openspec` by default; override with `SDD_OPENSPEC_DIR` when running outside the project root.
