---
name: r3-sdd-init
description: >
    Spec-Driven Development — initialize the SDD workspace in a project: create the _contracts/ tree
    (specs, changes, constitution, context-map, explorations) so the r3-sdd-* workflow can run. Triggers
    (EN+ES): "init sdd", "sdd init", "set up spec-driven development", "initialize _contracts", "inicializa
    sdd", "configura spec-driven", "prepara el proyecto para sdd", "arranca sdd".
user-invocable: true
---

# r3-sdd-init — initialize SDD in a project

Set up the `_contracts/` structure so the SDD skills can operate. Conventions live in `sdd-schema`, `sdd-spec-format`, and `sdd-domain-format`.

## Steps

### Step 1 — Scaffold

From the project root (or with `SDD_ROOT` set), run:

```bash
.agents/scripts/sdd.ps1 init
```

This creates `_contracts/specs/`, `_contracts/changes/archive/`, `_contracts/explorations/`, and scaffolds
`_contracts/constitution.md` + `_contracts/context-map.md` from the templates (idempotent — existing files are
kept).

### Step 2 — Fill the constitution

Edit `_contracts/constitution.md` — the project's governance: binding **Core Principles** (with rationale),
free-form **Standards**, and a **`## Testing`** section — detect the test runner from the project (`package.json` /
`go.mod` / `Cargo.toml` / `pyproject.toml` / `Makefile`) and record the runner command, layers, and coverage, plus
the strict-TDD mandate. This is read by the Constitution Check gate (in `design`) and re-verified at `verify`. Optionally seed
`_contracts/context-map.md` if cross-capability relationships already exist.

### Step 3 — Confirm

Report the created structure and point to `r3-sdd-propose` (all-in-one) or `r3-sdd-scaffold` (step-by-step) to start
the first change.

## Output Contract

Creates (idempotent):

- `_contracts/specs/`, `_contracts/changes/archive/`, `_contracts/explorations/`
- `_contracts/constitution.md` and `_contracts/context-map.md` (scaffolded from templates; never overwritten if present)

## Constraints

- Idempotent — safe to run again; never overwrites an existing constitution, context-map, or specs.
- Targets `$PWD/_contracts` by default; override with `SDD_ROOT` when running outside the project root.
