---
name: r3-artifact-create
description: >
    Create a new cross-tool agent artifact: skill, rule, agent definition, Warp workflow,
    or MCP server registration. Places the file in the correct .agents/ location with the
    correct format and applies side effects like AGENTS.md registration. Use when the user
    says "create a skill", "new rule", "add an agent definition", "crea un skill", "nueva
    regla", "nuevo workflow de warp", "registra un MCP", or wants to add any reusable agent
    capability to the workspace.
user-invocable: true
---

# r3-artifact-create — Create a cross-tool artifact

Creates a new agent artifact (skill, rule, agent definition, Warp workflow, or MCP server)
in the correct location, with the correct format, and applies all required side effects so
every harness discovers it without manual follow-up.

---

## Step 1 — Identify artifact type and name

If the user did not specify the type, ask:

> What type of artifact? `skill` / `rule` / `agent` / `workflow` / `mcp`

If the user did not specify a name, ask. Apply the naming convention for the chosen type
(see the matrix below).

---

## Artifact matrix

### skill

| Field         | Value                                                                                                            |
| ------------- | ---------------------------------------------------------------------------------------------------------------- |
| Location      | `.agents/skills/<name>/SKILL.md`                                                                                 |
| Naming        | `r3-<domain>-<action>` — lowercase kebab-case                                                                    |
| Discovered by | Claude Code (`.claude/skills` symlink), VSCode (plugin.json), Warp (`.agents/skills/` highest-priority provider) |
| Side effects  | Add row to the relevant group table in `AGENTS.md`. If no group fits, create a new `###` section.                |

**Format:** follow `.agents/skills/_shared/skill-format.md` — canonical section order, writing rules,
body budget, and anti-patterns. Read it before writing the skill body.

**Skill type:** procedure (Steps-based, default) or stance (a posture with no fixed procedure, e.g. an explore/think
mode) — see the "Skill types" section in `.agents/skills/_shared/skill-format.md`.

**Shared assets:** markdown shared across skills (templates, snippets) goes under `.agents/skills/_shared/<group>/`.
A `_`-prefixed directory is NOT a skill (no `SKILL.md`); harnesses and `r3-artifact-audit` skip `_*` dirs.

**Template** (minimal skeleton — see the format reference for optional sections like
Arguments, Output Contract, and References):

```markdown
---
name: <name>
description: >
    <What it does + when to invoke. Trigger phrases first, in English and Spanish.>
user-invocable: true
---

# <name> — <one-line purpose>

<One- or two-sentence description of what this skill does.>

## Steps

### Step 1 — <title>

<Imperative instructions.>

### Step 2 — <title>

<Imperative instructions.>

## Constraints

- <Non-negotiable rule.>
```

**Side-effect procedure:**

1. Read `AGENTS.md` to find the right `### <Group>` table.
2. Append a row: `| \`<name>\` | <purpose> |`
3. If no group fits, add a new `### <Domain> — <description>` section with a fresh table.

---

### rule

| Field         | Value                                                                                |
| ------------- | ------------------------------------------------------------------------------------ |
| Location      | `.agents/rules/<name>.md`                                                            |
| Naming        | `<scope>-<topic>` — lowercase kebab-case (e.g. `dotnet-library`, `typescript-style`) |
| Discovered by | Claude Code (`.claude/rules` symlink), VSCode Copilot (plugin.json `rules.paths`)    |
| Side effects  | None — files are auto-loaded by both harnesses                                       |

**Template:**

```markdown
# Rule: <title>

Applies to <scope — language, framework, layer, etc.>.

---

## <Section>

<Rule content.>
```

---

### agent

| Field         | Value                                                                               |
| ------------- | ----------------------------------------------------------------------------------- |
| Location      | `.agents/agents/<name>.md`                                                          |
| Naming        | Descriptive lowercase kebab-case (e.g. `code-reviewer`, `migration-planner`)        |
| Discovered by | Claude Code (`.claude/agents` symlink), VSCode Copilot (plugin.json `agents.paths`) |
| Side effects  | None — files are auto-loaded by both harnesses                                      |

**Template:**

```markdown
---
model: claude-sonnet-4-6
description: <one-line description shown in the agent picker>
---

<System prompt in Markdown. Define the agent's persona, scope, and behavioral rules.>
```

Valid model IDs: `claude-sonnet-4-6`, `claude-opus-4-8`, `claude-haiku-4-5-20251001`.

---

### workflow

| Field         | Value                                                         |
| ------------- | ------------------------------------------------------------- |
| Location      | `.agents/workflows/<name>.yaml`                               |
| Naming        | Descriptive lowercase kebab-case                              |
| Discovered by | Warp (via `.warp/workflows → ../.agents/workflows` symlink)   |
| Side effects  | None — Warp picks up any `.yaml` file in the linked directory |

**Template** (schema verified against `cloud_object_models/src/workflow.rs` in the warp source):

```yaml
name: <Human-readable workflow name>
command: <single shell command string, may use {{arg}} placeholders>
description: <What this workflow automates>
tags:
    - <tag>
arguments:
    - name: <arg>
      description: <What this argument is>
      default_value: ~
```

`command` is a single string — multi-step workflows chain with `&&`. Each `{{arg}}` in the
command must have a matching entry in `arguments`. `default_value: ~` means no default
(Warp prompts for it).

---

### mcp

| Field         | Value                                                                              |
| ------------- | ---------------------------------------------------------------------------------- |
| Location      | `.mcp.json` at workspace root (shared) or `<project>/.mcp.json` (project-specific) |
| Discovered by | Claude Code, Warp, Gemini CLI — any harness that reads `.mcp.json`                 |
| Side effects  | None — entry is directly in the consumed file                                      |

**Entry format** (add under `"mcpServers"`):

```json
"<server-name>": {
    "command": "<executable>",
    "args": ["<arg1>", "<arg2>"],
    "env": {
        "ENV_VAR": "<value>"
    }
}
```

Use `"url"` instead of `"command"` + `"args"` for remote (HTTP/SSE) MCP servers:

```json
"<server-name>": {
    "url": "http://localhost:3000/mcp"
}
```

---

## Step 2 — Create the artifact

Write the file to the location specified above. Use the template for the chosen type.
Fill in all placeholder fields — do not leave `<...>` in the output.

## Step 3 — Apply side effects

Follow the side-effect procedure for the chosen type. For `skill`, always update `AGENTS.md`.
For all other types, verify the file is in the right location (no further action needed).

## Step 4 — Confirm

Report in one line: what was created and where. If `AGENTS.md` was updated, include that.

## Output Contract

- The artifact file at the type's location: skill → `.agents/skills/<name>/SKILL.md`; rule → `.agents/rules/<name>.md`; agent → `.agents/agents/<name>.md`; workflow → `.agents/workflows/<name>.yaml`; mcp → an entry under `"mcpServers"` in `.mcp.json`.
- For `skill`: a new row in the relevant `AGENTS.md` group table (or a new `### <Group>` section).
