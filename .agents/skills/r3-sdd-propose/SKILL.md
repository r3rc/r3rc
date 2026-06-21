---
name: r3-sdd-propose
description: >
    Spec-Driven Development — propose a change and generate ALL its planning artifacts (proposal, specs,
    design, tasks) in one pass, ready to implement. Use when starting a new feature/fix/change.
    Triggers (EN+ES): "propose a change", "sdd propose", "start a spec", "new change", "propon un cambio",
    "crea un cambio", "arranquemos un spec", "nuevo cambio sdd".
user-invocable: true
---

# r3-sdd-propose — propose a change and generate its planning artifacts

Engine-free entry point of the r3 SDD workflow. Creates one change and generates every artifact needed to start
implementing. The conventions (dir model, artifact graph, status-by-file-existence, spec/delta format, merge) live
in the auto-loaded rules **`sdd-schema`** and **`sdd-spec-format`** — follow them.

## Steps

### Step 1 — Get the change intent

If the user gave no clear input, ask one open question: "What change do you want to work on? Describe what you
want to build or fix." Derive a **kebab-case slug** (e.g. "add user authentication" → `add-user-auth`). Do NOT
proceed without understanding the change. If a change with that slug already exists, ask whether to continue it
(`r3-sdd-continue`) or choose a new name.

### Step 2 — Scaffold the change

Run `.agents/scripts/sdd.sh new <slug>` from the project root (or set `SDD_OPENSPEC_DIR`). It creates the empty
change folder `openspec/changes/<slug>/` (with a `specs/` subdir). You author each artifact by copying its template
from `.agents/skills/_shared/sdd/templates/` and filling it. If `openspec/` does not exist yet, run `r3-sdd-init` first.

### Step 3 — Fill artifacts in dependency order, until apply-ready

Per the schema graph `proposal → {specs, design} → tasks`. Read `openspec/config.yaml` `context`/`rules` and apply
them as constraints — **never copy them into the files**. Read each completed dependency for context before writing
the next. Create each artifact by copying its template from `.agents/skills/_shared/sdd/templates/` and filling it:

- **proposal.md** — Why · What Changes · Capabilities (New + Modified — this is the contract to the specs) · Impact.
- **specs/<capability>/spec.md** — one delta spec per capability listed in the proposal, using `## ADDED Requirements`
  etc. and the `### Requirement:` / `#### Scenario:` format from `sdd-spec-format`.
- **design.md** — always created (it gates `tasks`); write a full design when warranted (cross-cutting, new
  dependency/data model, security/perf/migration, or real ambiguity), else a one-line "no dedicated design needed" note.
- **tasks.md** — checkboxed `- [ ] N.M` items grouped under `## N. <group>`, ordered by dependency.

Stop when the apply-requires artifact (`tasks`) is done — that is "apply-ready". If an artifact's context is unclear,
ask the user before writing it.

### Step 4 — Confirm

Verify each file exists and is filled (not just the template). Summarize: the change slug + location, which artifacts
were created, and the status (e.g. "apply-ready"). Point the user to `r3-sdd-apply` to implement.

## Output Contract

After running, `openspec/changes/<slug>/` contains (filled, not templates):

- `proposal.md`, `design.md`, `tasks.md`
- `specs/<capability>/spec.md` — one delta spec per capability in the proposal

## Constraints

- One change = one kebab-case folder under `openspec/changes/`. Never edit `openspec/specs/` here (that happens at sync/archive).
- A spec is a **behavior contract** (WHAT), not implementation — keep code/design detail in `design.md`/`tasks.md`.
- `context`/`rules` from `config.yaml` are constraints for you, never content copied into artifacts.
- Status is derived from **file existence** (see `sdd-schema`); there is no engine or CLI.
- Scaffolding and the archive move go through `.agents/scripts/sdd.sh`; everything else is reading/writing markdown.
