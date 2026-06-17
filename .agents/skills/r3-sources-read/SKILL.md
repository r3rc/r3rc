---
name: r3-sources-read
description: >
    Explore, map, and learn from a locally cloned reference source under .agents/sources/.
    Use when the user wants to understand how a cloned library works internally, find specific
    APIs, types, or signatures, trace how a feature is implemented upstream, get a structural
    overview of a dependency, or says "revisa el source", "como funciona X en la libreria",
    "explora el codigo de <source>". Prefer this over answering from memory about a registered library.
user-invocable: true
---

# r3-sources-read

Explore, map, and learn from locally cloned sources under `.agents/sources/`.

## Arguments

```
/r3-sources-read [name] [query]
```

- `[name]` — Optional. Name of a specific source (matches `name` field in `.agents/registry.json`). If omitted, lists all available sources.
- `[query]` — Optional. A question or search term to focus the exploration (e.g., "how is auth handled", "find the Router type", "list public exports").

## Steps

### Step 1 — Load registry

Read `.agents/registry.json`. If it does not exist or `sources` is empty, report the gap and suggest running `/r3-sources-link` first.

### Step 2 — No name given: list sources

**⏸ Source selection** — print a table of all registered sources and wait for the user to choose which one to explore:

| Name | Path | Branch | Shallow |
| ---- | ---- | ------ | ------- |

### Step 3 — Name given: delegate to the source-explorer agent

Resolve the path from the registry entry. Then launch a `source-explorer` subagent
(defined in `.agents/agents/source-explorer.md`) to read the source tree. If the
harness does not expose `source-explorer`, fall back to its built-in read-only exploration
agent (e.g. `Explore` in Claude Code). Do not read the source files directly in the main chat.

The agent already knows its method, constraints, and report format. The prompt only needs
the specifics:

```
Explore the source repository at <resolved-path>.
<if query is provided>
Answer this specific query: "<query>"
- For type/symbol queries: grep recursively for the term, read matching files in full.
- For architecture queries: read entry points, module boundaries, and any design docs.
- For "list exports": read index/barrel files and public API surface.
</if>
Return the default report format.
```

### Step 4 — Present results

Relay the agent's report to the user. If the agent flagged gaps, surface them explicitly.

## Constraints

- Never read source files directly in the main chat — always delegate to the source-explorer agent.
- If `.agents/sources/<name>/` is missing or empty despite being registered, do not launch the agent. Report the gap and ask the user to run `/r3-sources-link` again.
- Do not modify any file under `.agents/sources/`.
