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
implementing. The conventions (dir model, artifact graph, status-by-file-existence, spec format) live
in the conventions **`sdd-schema`**, **`sdd-spec-format`**, and **`sdd-domain-format`** — follow them.

## Steps

### Step 1 — Get the change intent

If the user gave no clear input, ask one open question: "What change do you want to work on? Describe what you
want to build or fix." Derive a **kebab-case slug** (e.g. "add user authentication" → `add-user-auth`). Do NOT
proceed without understanding the change. If the direction is still soft or the decisions are ambiguous, run
`r3-craft-drill` first to harden them, then return here. If a change with that slug already exists, ask whether to
continue it (`r3-sdd-continue`) or choose a new name.

### Step 2 — Scaffold the change

Run `.agents/scripts/sdd.ps1 new <slug> --project <name>` (the project you're working in, or `--workspace`; see Context in `sdd-schema`). It creates the empty
change folder `.covenant/changes/<NNN-slug>/` (the script assigns the next `NNN` and prints a stable `id` — record that `id` in `proposal.md`'s frontmatter). You author each artifact by copying its template
from `.agents/skills/_shared/` and filling it. If `.covenant/` does not exist yet, run `r3-sdd-init` first.

### Step 3 — Fill artifacts in dependency order, until apply-ready

Per the schema graph `proposal → {spec, design} → tasks`. Read the project's `.covenant/constitution.md`
(principles, standards, `## Testing`) and apply it as constraints — **never copy it into the files**. Read each completed dependency for context before writing
the next. Create each artifact by copying its template (`sdd-<artifact>.md` in `.agents/skills/_shared/`) and filling it as `<artifact>.md`:

- **proposal.md** — frontmatter `id` (the stable id from `sdd.ps1 new`) · Why (+ optional user-story framing) ·
  What Changes · Capabilities (New + Modified) · **`## Spec Impact`** (added/modified/removed, with
  reason+migration for removals) · Impact.
- **spec.md** — a **full self-contained** spec of the requirements this change establishes: complete
  `### Requirement:` blocks (a `**ID**: REQ-###` bullet + `#### Scenario:` GWT); `## <Capability>`
  sections if it spans more than one. Include `## Purpose`/`## Key Entities` for a new capability. For an existing
  capability, assign each new requirement the **next free `REQ-###` from the living spec** (never restart at 001).
- **design.md** — always created (it gates `tasks`); include a `## Constitution Check` (gate vs the constitution)
  and, when the change touches domain data, a `## Domain Model` (DDD-lite, per `sdd-domain-format`). Full depth
  when warranted, else a one-line "no dedicated design needed" note. When the design hinges on a third-party
  library's behavior, consult it first via `r3-sources-learn` — do not design from memory.
- **tasks.md** — phase/slice structure (Setup / Foundational / Slice P1… / Polish); per slice a
  **`Satisfies: [[REQ-###]]`** line, optional **`Owns:`** (file globs) / **`Depends:`**, and an Independent Test;
  `[P]` markers and `[[REQ-###]]` refs.

Stop when the apply-requires artifact (`tasks`) is done — that is "apply-ready". If an artifact's context is unclear,
ask the user before writing it.

### Step 4 — Confirm

Verify each file exists and is filled (not just the template). Summarize: the change slug + location, which artifacts
were created, and the status (e.g. "apply-ready"). Point the user to `r3-sdd-apply` to implement.

## Output Contract

After running, `.covenant/changes/<slug>/` contains (filled, not templates):

- `proposal.md` (incl. `## Spec Impact`), `design.md`, `tasks.md`
- `spec.md` — the full self-contained spec for what the change establishes

## Constraints

- One change = one numbered folder under `.covenant/changes/`. Never edit `.covenant/specs/` here (that happens at `r3-sdd-close`).
- A spec is a **behavior contract** (WHAT), not implementation — keep code/design detail in `design.md`/`tasks.md`.
- The constitution's standards/context are constraints for you, never content copied into artifacts.
- Status is derived from **file existence** (see `sdd-schema`); there is no engine or CLI.
- Scaffolding goes through `.agents/scripts/sdd.ps1 new`; the close (editing the living spec) is `r3-sdd-close`. Everything else is reading/writing markdown.
