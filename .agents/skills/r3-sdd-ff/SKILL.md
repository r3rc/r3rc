---
name: r3-sdd-ff
description: >
    Spec-Driven Development — fast-forward: generate every remaining planning artifact for a change in one pass,
    until it is ready to implement (no per-artifact stop). Triggers (EN+ES): "fast-forward the change", "sdd ff",
    "generate all artifacts", "get it apply-ready", "acelera el cambio", "genera todos los artefactos", "déjalo
    listo para implementar", "fast forward".
user-invocable: true
---

# r3-sdd-ff — fast-forward a change to apply-ready

Generate all remaining ready artifacts for a change in one pass, biased toward momentum. Conventions and status
rules live in the auto-loaded rules `sdd-schema` and `sdd-spec-format`.

## Steps

### Step 1 — Get the change

Use a named change, or scaffold a new one: derive a **kebab-case slug** and run `.agents/scripts/sdd.sh new <slug>`
(run `r3-sdd-init` first if `openspec/` is missing). Don't proceed without understanding what is being built.

### Step 2 — Loop until apply-ready

Per the graph `proposal → {specs, design} → tasks`, repeatedly pick the first `ready` artifact (state derived from
file existence — see `sdd-schema`), read its dependencies, and create the artifact from its template in
`.agents/skills/_shared/sdd/templates/` (apply `config.yaml`
`context`/`rules` as constraints; use `sdd-spec-format` for specs). Continue until the apply-requires artifact
(`tasks`) is done. Always create `design.md` (brief note when a dedicated design isn't warranted).

### Step 3 — Report

Confirm all planning artifacts are created and the change is apply-ready. Point to `r3-sdd-apply`.

## Output Contract

After running, `openspec/changes/<slug>/` holds every planning artifact through apply-ready: `proposal.md`, `specs/<capability>/spec.md`, `design.md`, `tasks.md`.

## Constraints

- Prefer reasonable decisions to keep momentum; only stop to ask when context is critically unclear.
- Verify each artifact file exists after writing before moving to the next.
- This is the one-pass variant of `r3-sdd-continue`; for one-at-a-time control use that instead.
