---
name: r3-sources-learn
description: >
    Learn from project reference sources before implementing non-trivial functionality. Use when building a feature,
    module, command, data structure, storage behavior, sync behavior, parser, or other code where mature references may
    have relevant patterns. Reads AGENTS.md and .agents/registry.json to discover available context and source checkouts,
    then pauses for user confirmation before reading any source tree. Do not use for trivial edits, renames, comments, or
    purely exploratory architecture discussion where no implementation is planned.
user-invocable: true
---

# r3-sources-learn

Learn from mature codebases before writing code. Reference sources encode edge cases, design decisions, tests, and
operational traps. Distill their patterns; do not copy code.

This skill is a methodology. The project-level instructions live in `AGENTS.md`. The available external sources are
listed in `.agents/registry.json` and, when present locally, checked out under `.agents/sources/<name>/`.

## Project contract

Use these files as routers, not as implementation sources:

- `AGENTS.md` — repository instructions, quality gates, context routers, and source-verification policy.
- `.agents/notes/INDEX.md` — workspace notes entry point (cross-cutting concerns, shared patterns).
- `.agents/registry.json` — names and remotes for available reference sources.

Reading these routing files does not require user confirmation. Reading source trees under `.agents/sources/` does.

## Steps

### Step 1 — Understand what is being built

Identify:

- **What** is being implemented: data structure, protocol, module, command, storage behavior, parser, sync flow, etc.
- **What properties** it needs: persistence, ordering, transactions, streaming, cancellation, concurrency, error model,
  temporal behavior, or search behavior.
- **What scope** it has: single function, package, subsystem, or cross-cutting change.

If the request is vague, ask one clarifying question. Do not guess.

### Step 2 — Evaluate available references

Read `AGENTS.md` and `.agents/registry.json`. If design context is needed, read `.agents/notes/INDEX.md` before
selecting source repositories.

For each source listed in `.agents/registry.json`, judge relevance using:

- the source name and remote URL;
- project context from `.agents/notes/INDEX.md`;
- the implementation properties identified in step 1;
- any already-known project conventions in `AGENTS.md`.

Produce a list of **picked sources**, which may be empty. Do not read `.agents/sources/<name>/` yet.

### ⏸ Source confirmation — before reading any source tree

**⏸ Source confirmation** — present the picks to the user and wait for a response. This pause is mandatory even if
there is only one obvious source.

If no source matches:

> I did not find a configured reference source whose domain clearly matches this task. Do you want to add one for this
> task? If yes, give me the path and a short description. Otherwise, I will proceed without a reference.

If sources match:

> I plan to read these reference sources for this task:
>
> 1. `<source>` — `.agents/sources/<source>/` — <why it is relevant>
> 2. ...
>
> Confirm reading all of them? You can discard any, or add another source/path for this task.

Allowed user responses:

| Response                  | Action                                           |
| ------------------------- | ------------------------------------------------ |
| Confirm                   | Read the picked sources as-is                    |
| Discard                   | Remove the named sources before reading          |
| Add                       | Append the named source/path for this task only  |
| Proceed without reference | Skip source reading and document that explicitly |

Sources added during the pause apply only to the current task. Do not persist them to `.agents/registry.json` unless the
user explicitly asks.

### Step 3 — Delegate source reading to source-explorer agents

For each confirmed source, launch a separate `source-explorer` subagent (defined in
`.agents/agents/source-explorer.md`). If the harness does not expose `source-explorer`,
fall back to its built-in read-only exploration agent (e.g. `Explore` in Claude Code).
Do not read source files directly in the main chat. Launch all agents in parallel when
there are multiple confirmed sources.

The agent already knows its method, constraints, and report formats. The prompt only needs
the specifics:

```
Explore the source repository at <resolved-path> to inform an implementation task.

Implementation context: <what is being built, properties identified in Step 1>

Return the implementation-task report format (patterns, edge cases, traps, relevance verdict).
```

If a configured source is missing locally, report that and ask before launching any command. Do not silently skip it.

If a confirmed source turns out to be irrelevant after the agent's honest browsing, document the miss. Do not hide it.

### Step 4 — Synthesize before implementation

Collect the reports from all source-explorer agents and produce a single synthesis:

```markdown
## Implementation plan for <feature>

**Learned from:** <sources/files read, or "no reference sources used (user-confirmed)">

**Patterns to adopt:**

- <pattern and why>

**Edge cases to handle:**

- <case extracted from implementations or tests>

**Traps to avoid:**

- <subtlety found while reading>

**Approach:**

- <implementation approach informed by the references>
```

Keep this brief for straightforward additions.

### ⏸ Plan approval — before significant implementation

**⏸ Plan approval** — for significant features, present the synthesis and ask: "This is my plan based on what I found.
Should I proceed?" Wait for approval.

For small additions, a concise note is enough; do not block on trivial work.

### Step 5 — Hand off to implementation

The skill stops at an approved or accepted plan. Implementation happens afterward in the main workflow:

- if the project uses SDD (`.covenant/` exists), this synthesized plan is the input to `r3-sdd-propose` (new
  change) or feeds the `design.md` / `tasks.md` of an in-progress change; otherwise implement directly;
- apply the distilled patterns;
- cover the extracted edge cases;
- write or update tests for the same concerns;
- keep APIs idiomatic for this project, even when references use a different language or runtime.

## Constraints

- The pause before reading source trees is non-negotiable.
- Every source the user confirms gets a dedicated source-explorer agent. If it is irrelevant, document the miss.
- Never read source files directly in the main chat — always delegate to source-explorer agents.
- Tests are the highest-value artifact in any source.
- Distill patterns; do not copy code.
- Selectivity happens before confirmation, not during confirmed reading.
- Prefer project-runtime primitives over ports of low-level patterns from other runtimes.
- A documented miss beats a silent skip.
- Memory is not a source; verify APIs against source code or official documentation.
