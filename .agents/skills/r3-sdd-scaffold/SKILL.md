---
name: r3-sdd-scaffold
description: >
    Spec-Driven Development — scaffold a new change and show the first artifact to fill, then stop (step-by-step,
    one artifact at a time). Use `r3-sdd-propose` instead to generate everything in one pass. Triggers (EN+ES):
    "new change scaffold", "sdd new", "start a change step by step", "scaffold a change", "nuevo cambio paso a
    paso", "scaffold de cambio", "crear cambio vacío".
user-invocable: true
---

# r3-sdd-scaffold — scaffold a change, one artifact at a time

Create a change's folder and surface the first artifact to fill, then stop. For the all-in-one path use
`r3-sdd-propose`; to advance one artifact at a time afterwards use `r3-sdd-continue`. Conventions live in the
convention `sdd-schema`.

## Steps

### Step 1 — Get the change intent

If no clear input, ask one open question ("What change do you want to work on?") and derive a **kebab-case slug**. Do
NOT proceed without understanding it. If the slug already exists, suggest `r3-sdd-continue` instead.

### Step 2 — Scaffold

Run `.agents/scripts/sdd.ps1 new <slug>` from the project root. It creates the empty change folder
`_contracts/changes/<slug>/` (with a `specs/` subdir); artifacts are authored from the templates in
`.agents/skills/_shared/`. If `_contracts/` does not exist, run `r3-sdd-init` first.

### Step 3 — Show the first artifact and stop

Per the schema graph the first ready artifact is `proposal.md`. Show its template structure and what it captures
(Why, What Changes, Capabilities, Impact). Then **STOP** — do not create artifact content yet.

### Step 4 — Hand off

Summarize: the change slug + location, the artifact sequence (`proposal → {specs, design} → tasks`), current status
(0 artifacts filled), and prompt: "Describe the change and I'll draft the proposal, or run `r3-sdd-continue`."

## Output Contract

Creates the empty change folder `_contracts/changes/<slug>/` (with a `specs/` subdir). No artifact content is written — that happens in `r3-sdd-continue` / `r3-sdd-propose`.

## Constraints

- Do NOT fill any artifact here — only scaffold and show the first template.
- One change = one kebab-case folder under `_contracts/changes/`.
