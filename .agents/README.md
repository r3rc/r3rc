# `.agents/` — the agent workspace

This directory is the **canonical, tool-neutral home for every agent artifact** in this repo: skills, rules,
custom agents, workflows, reference sources, and the scripts that manage them. One source of truth,
consumed by every harness (Claude Code, Cursor, Windsurf, Gemini, Warp, VS Code Copilot…) — never forked per
tool.

> **Three entrypoints, three jobs.** The repo-root `README.md` describes _the project_. The repo-root
> `AGENTS.md` defines _agent behavior_ and holds the authoritative _skill catalog_. **This file** is the
> _maintainer's map_: how the workspace is laid out and how you manage what's in it. It complements AGENTS.md —
> it does not duplicate it; for the full skill tables and behavior rules, read `AGENTS.md`.

---

## Getting started

**`r3`** (repo root) is the single entrypoint — `./r3 <command>` (a `pwsh` shim; or `pwsh ./r3.ps1`). Every
step below can also be triggered by just asking the agent in plain language — the skill name in parentheses
is what fires.

Per-context commands (`sdd`, `sources`) act on a **context**: a project (`--project <name>`, or the project
your shell is inside) or the workspace itself (`--workspace`). There is **no silent default** — at the
workspace root with no flag, they stop and ask.

### 1. Initialize the workspace (once per clone)

```bash
./r3 init
```

Creates the harness symlinks (`.claude/skills|rules|agents → .agents/…`, `.warp/workflows → …`), wires
`CLAUDE.md → AGENTS.md`, and registers artifacts with VS Code. Idempotent — re-run after pulling updates.

### 2. Add a project to the workspace

```bash
./r3 project add <git-url> [name]   # clone into the workspace
./r3 project wire <name>            # scaffold its .mcp.json + agent wiring
```

Or ask: _"add the project at &lt;url&gt; to the workspace"_ (`r3-project-add`). Inspect / remove with
`./r3 project list` · `./r3 project status <name>` · `./r3 project remove <name>`.

### 3. Initialize spec-driven development in a project

```bash
./r3 sdd init --project <name>          # create <name>/.covenant/
./r3 sdd new <slug> --project <name>    # scaffold a change folder (auto-numbered, stable id)
```

Or ask: _"init sdd in samaritan"_ (`r3-sdd-init`). Inside the project directory `--project` is optional
(auto-detected); at the workspace root it is required.

### 4. Register an upstream library as a reference source

```bash
./r3 sources link <git-url> [name] --project <name>   # clone (global) + link into the context
```

Or ask: _"link &lt;url&gt; as a reference source for samaritan"_ (`r3-sources-link`). The clone is global
(`~/.r3/sources`); the symlink + registry entry live in the context, so the agent reads real upstream code
instead of guessing APIs.

### Starting prompts

Skills fire from natural language — you don't memorize names. Useful openers once you're in a project:

| You say…                                                 | Fires                            |
| -------------------------------------------------------- | -------------------------------- |
| "init sdd here"                                          | `r3-sdd-init`                    |
| "walk me through sdd on this codebase" (guided tutorial) | `r3-sdd-onboard`                 |
| "I want to propose a change to add refresh tokens"       | `r3-sdd-propose`                 |
| "explore how auth works before we touch it"              | `r3-sdd-explore`                 |
| "drill me on this plan until it's solid"                 | `r3-craft-drill`                 |
| "learn from our sources before I implement the parser"   | `r3-sources-learn`               |
| "implement the change / work the tasks"                  | `r3-sdd-apply`                   |
| "debug this flaky test"                                  | `r3-craft-debug`                 |
| "review the diff against main"                           | `r3-craft-review`                |
| "verify the change matches the spec, then close it"      | `r3-sdd-verify` → `r3-sdd-close` |

---

## Directory map

| Path                          | What lives here                                                                                                         |
| ----------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `skills/<name>/SKILL.md`      | Reusable, invocable task instructions — one skill per directory.                                                        |
| `skills/_shared/`             | Conventions + templates shared across skills (`_`-prefixed → tools skip it).                                            |
| `skills/_feedback/<skill>.md` | Per-skill execution-feedback log — the self-improvement loop (lazy; `_`-skipped).                                       |
| `rules/`                      | Project-agnostic coding rules, auto-applied by harnesses. `sdd-*.md` are symlinks into `_shared/`.                      |
| `agents/`                     | Custom subagent definitions (`code-reviewer`, `source-explorer`).                                                       |
| `workflows/`                  | Warp terminal automation (`.yaml`, discovered via the `.warp/workflows` symlink).                                       |
| `sources/`                    | Per-context symlinks to upstream reference repos (clones live in `~/.r3/sources/`; gitignored — `restore` regenerates). |
| `scripts/`                    | PowerShell management scripts (`setup.ps1`, `projects.ps1`, `sdd.ps1`, `sources.ps1`, `_shared.psm1`).                  |
| `registry.json`               | Per-context registry of reference sources (committed; `restore` re-creates the symlinks from it).                       |
| `plugin.json`                 | Artifact-discovery manifest for VS Code / Copilot.                                                                      |

Related, outside `.agents/`: repo-root **`r3`** / **`r3.ps1`** (the workspace entrypoint), repo-root
**`AGENTS.md`** (behavior + catalog), repo-root **`.mcp.json`** (MCP server registry).

---

## The skill catalog at a glance

31 skills in 6 groups (full tables + triggers in `AGENTS.md → Available skills`):

| Group        | Purpose                                                                                                              |
| ------------ | -------------------------------------------------------------------------------------------------------------------- |
| **sources**  | Clone, sync, read, and learn from upstream reference code.                                                           |
| **git**      | Conventional-commit grouping and semver releases.                                                                    |
| **project**  | Add / list / remove projects in the workspace.                                                                       |
| **artifact** | Manage the agent artifacts themselves (meta — see below).                                                            |
| **sdd**      | Engine-free spec-driven development (the `.covenant/` contract lifecycle).                                           |
| **craft**    | Cross-cutting engineering & thinking practices — `drill` (harden a plan), `debug` (diagnose), `review` (multi-axis). |

`AGENTS.md → Agent trigger rules` records _when_ to reach for each (organic recommendations, not gates).

---

## Craft skills — practices you invoke

Cross-cutting practices you apply to whatever you're working on (not tied to SDD). Invoke by name or by a
trigger phrase in plain language.

### `r3-craft-drill` — harden a plan

A relentless **one-question-at-a-time** interview that drives a _soft_ plan to a _hard_ one before you build.
It walks the decision tree, **recommends an answer for every question** (you react, you don't generate from
scratch), reads the code instead of asking when the answer is there, and resolves decisions in dependency
order. It is **convergent** — the opposite of `r3-sdd-explore` (which diverges to open the problem up). Use it
when you have a rough direction but the decisions aren't pinned down; it sits between exploring and
`r3-sdd-propose`, and never writes code — it hardens the plan, then hands off.

> _"drill me on this refresh-token plan until it's solid"_ · _"gríllame el plan"_ · _"cuestioná cada decisión"_

### `r3-craft-debug` — diagnose a hard bug

A **feedback-loop-first** discipline for hard bugs and performance regressions: build a tight, red-capable
repro **first** (the whole skill rests on this), then minimise it, hypothesise (3–5 ranked, falsifiable),
instrument one variable at a time, fix at a correct seam, and post-mortem. Use it when something is broken,
throwing, flaky, or slow.

> _"debug this flaky test"_ · _"diagnosticá por qué anda lento"_

### `r3-craft-review` — multi-axis review

Fans out four read-only lenses in parallel — **Risk · Readability · Reliability · Resilience** — and aggregates
by severity so no single concern masks another. Use before a PR or before closing a change. (Whether the code
matches the _spec_ is `r3-sdd-verify`'s job, not this one's.)

> _"review the diff against main"_ · _"revisá el código antes del PR"_

---

## Managing artifacts — the `r3-artifact-*` family

The artifacts are themselves managed by skills. Invoke these by name:

| Skill                 | Use it to…                                                                                                   |
| --------------------- | ------------------------------------------------------------------------------------------------------------ |
| `r3-artifact-create`  | Create a skill / rule / agent / workflow / MCP entry in the right place, with side effects (AGENTS.md row).  |
| `r3-artifact-audit`   | Scan the whole workspace for cross-tool consistency (missing files, wrong extensions, unregistered entries). |
| `r3-artifact-improve` | Audit + refactor one skill against the format reference; applies on approval.                                |
| `r3-artifact-retro`   | Capture execution feedback on a skill (gaps, deviations) into its `_feedback/` log.                          |
| `r3-artifact-remove`  | Remove an artifact and clean up every side effect.                                                           |

### The skill self-improvement loop

Skills get better the more they're used:

```
run a skill → (you had to deviate) → r3-artifact-retro captures → skills/_feedback/<skill>.md accumulates → r3-artifact-improve folds the gap into SKILL.md
                                          signal                          memory                                  update
```

`retro` only **captures** (read-only on the `SKILL.md`); `improve` **applies** (edits the `SKILL.md`, marks
folded entries). A clean run logs nothing. The agent offers a retro after a run it had to deviate from; you
can also invoke it directly.

---

## Conventions (`skills/_shared/`)

Canonical here, referenced explicitly by the skills that need them (engine-neutral — works on any tool):

| File                                                                                                           | Defines                                                                                                                                                          |
| -------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `artifact-format.md`                                                                                           | How to write a `SKILL.md` — section order, body budget, leading words, failure modes, the feedback-log convention. Read it before creating or improving a skill. |
| `review-axes.md`                                                                                               | The four read-only review lenses (Risk / Readability / Reliability / Resilience) + shared review discipline.                                                     |
| `sdd-schema.md`, `sdd-spec-format.md`, `sdd-domain-format.md`                                                  | The SDD contract conventions (also symlinked into `rules/` for harnesses that scan that folder).                                                                 |
| `sdd-constitution.md`, `sdd-context-map.md`, `sdd-proposal.md`, `sdd-spec.md`, `sdd-design.md`, `sdd-tasks.md` | The SDD artifact templates.                                                                                                                                      |

---

## Scripts (`scripts/`)

Scripts own the **mechanics** only — deterministic scaffolding and management. All _logic_ (status, validate,
review, close) is performed by the agent, not a runtime. The root **`r3`** entrypoint dispatches to these; you
can also call them directly.

| Script         | Does                                                                                                  |
| -------------- | ----------------------------------------------------------------------------------------------------- |
| `setup.ps1`    | `init` — create the harness symlinks + tool integrations (run via `r3 init`).                         |
| `projects.ps1` | `add` / `wire` / `list` / `status` / `remove` workspace projects.                                     |
| `sdd.ps1`      | `init` / `new <slug>` / `list` — scaffold a **context's** `.covenant/` (`--project` / `--workspace`). |
| `sources.ps1`  | `list` / `link` / `sync` / `restore` / `remove` — global store, **per-context** linkage.              |
| `_shared.psm1` | Shared helpers, incl. `Resolve-Context` (the project/workspace resolver).                             |

---

## How harnesses discover all this

- **`AGENTS.md`** (repo root) is the entrypoint every tool reads first; tool-specific files (`CLAUDE.md`, etc.)
  symlink to it — never fork its content.
- Discovery symlinks, created by `r3 init` (gitignored, **symlinks only** — never duplicated content):
  `.claude/skills → .agents/skills`, `.claude/rules → .agents/rules`, `.claude/agents → .agents/agents`,
  `.warp/workflows → .agents/workflows`.
- `plugin.json` exposes artifacts to VS Code / Copilot; `.mcp.json` (repo root) registers MCP servers.

---

## Principles

- **Tool-neutral.** `.agents/` is the single source of truth. Never create tool-specific instruction
  directories with real content — only the symlinks above.
- **Engine-free.** No runtime executes workflow logic. The agent does the reasoning; `git` is the history;
  `grep` is the index; scripts only scaffold.
- **Predictability.** A skill exists to make the agent take the same _process_ every run (see
  `_shared/artifact-format.md`).
- **Own product.** Shipped artifacts read as this workspace's own work — no provenance narration of external
  sources they were inspired by.
