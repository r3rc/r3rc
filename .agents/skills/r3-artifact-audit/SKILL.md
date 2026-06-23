---
name: r3-artifact-audit
description: >
    Scan all agent artifacts (skills, rules, agent definitions, Warp workflows, MCP configs)
    for cross-tool consistency issues: missing files, wrong extensions, unregistered entries,
    invalid structure. Use when the user says "audit the artifacts", "check the skills",
    "revisa los skills", "está todo consistente", after bulk artifact changes, or before
    releasing the workspace.
user-invocable: true
---

# r3-artifact-audit — Audit cross-tool artifact consistency

Scans all agent artifacts in the workspace and reports inconsistencies: missing files,
wrong naming conventions, unregistered entries, invalid structure. Run periodically or
before a release to prevent harnesses from silently failing to load artifacts.

---

## Steps

### Step 1 — Collect inventory

Run the following reads in parallel:

```bash
# Skills on disk
ls .agents/skills/

# Rules on disk
ls .agents/rules/

# Agent definitions on disk
ls .agents/agents/

# Workflows on disk
ls .agents/workflows/

# MCP config
cat .mcp.json
```

Also read `AGENTS.md` to extract the skills listed in all `### <Group>` tables.

---

### Step 2 — Check each artifact type

#### Skills

For every directory in `.agents/skills/` — **skip directories whose name starts with `_`** (e.g. `_shared/`, which
holds assets shared across skills, not skills themselves):

- [ ] `SKILL.md` exists inside it. Missing → **ERROR: no SKILL.md**
- [ ] The directory name follows `r3-<domain>-<action>`. Deviations → **WARNING: non-standard name**
- [ ] The skill appears in an `AGENTS.md` table row. Missing → **WARNING: unregistered in AGENTS.md**
- [ ] `SKILL.md` starts with `---` (YAML frontmatter present). Missing → **WARNING: no frontmatter — harnesses may not discover this skill**
- [ ] Frontmatter contains `name:` and `description:` keys. Missing → **WARNING: incomplete frontmatter**

For every skill listed in `AGENTS.md`:

- [ ] A corresponding `.agents/skills/<name>/` directory exists. Missing → **ERROR: listed in AGENTS.md but no file on disk**

#### Rules

For every file in `.agents/rules/`:

- [ ] Extension is `.md`. Other extensions → **WARNING: harnesses may not load this rule**

#### Agent definitions

For every file in `.agents/agents/`:

- [ ] Extension is `.md`. Other extensions → **WARNING: harnesses may not load this agent**
- [ ] File starts with `---` (YAML frontmatter present). Missing → **WARNING: no frontmatter — harnesses may not parse model/description**
- [ ] Frontmatter contains `model:` and `description:` keys. Missing → **WARNING: incomplete frontmatter**

#### Warp workflows

For every file in `.agents/workflows/`:

- [ ] Extension is `.yaml` or `.yml`. Other extensions → **WARNING: Warp will not load this file**
- [ ] File contains `name:`, `description:`, and `command:` keys. Missing → **ERROR: invalid workflow structure**

#### MCP configuration

- [ ] `.mcp.json` exists at workspace root. Missing → **WARNING: no workspace MCP config**
- [ ] `.mcp.json` is valid JSON and contains `"mcpServers"` key. Invalid → **ERROR: malformed .mcp.json**

For each registered project (directories in `.gitignore` matching `/<name>/`):

- [ ] `<project>/.mcp.json` exists. Missing → **WARNING: project has no MCP config scaffold**

---

### Step 3 — Report findings

Group findings by artifact type. Use this format:

```
## Audit Report

### Skills (N files, M registered in AGENTS.md)
- ERROR   r3-foo-bar: no SKILL.md
- WARNING r3-baz: unregistered in AGENTS.md

### Rules (N files)
- WARNING dotnet-library.txt: wrong extension — rename to dotnet-library.md

### Agents (N files)
- OK

### Workflows (N files)
- OK

### MCP
- WARNING samaritan/.mcp.json: missing — run: projects.ps1 wire samaritan
```

If no issues found for a type, print `OK`. At the end, print a one-line summary:
`N errors, M warnings` — or `all clean` if zero findings.

---

### Step 4 — Offer to fix

**⏸ Fix proposal** — list each auto-fixable issue (wrong extension rename, missing
AGENTS.md entry) with its proposed fix. Wait for the user to approve all, some, or none.

For non-auto-fixable issues (missing SKILL.md, missing project .mcp.json), describe what
the user must do.

## Constraints

- Do not auto-fix without confirmation.
