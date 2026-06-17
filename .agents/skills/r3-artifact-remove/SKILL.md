---
name: r3-artifact-remove
description: >
    Remove an agent artifact (skill, rule, agent definition, Warp workflow, or MCP server
    entry) and clean up all its side effects: AGENTS.md table rows, JSON keys, empty group
    sections. Use when the user says "remove the skill", "delete that rule", "elimina el
    skill", "borra el workflow", or wants to retire an agent capability cleanly.
user-invocable: true
---

# r3-artifact-remove — Remove a cross-tool artifact

Deletes an artifact and cleans up all side effects so no harness retains a stale reference.
Always verify the artifact exists before deleting, and always confirm with the user before
applying destructive operations.

---

## Steps

### Step 1 — Identify the artifact

If the user provided only a name (not a type), infer the type by checking which location
contains a matching entry:

| Type     | Location to check                         |
| -------- | ----------------------------------------- |
| skill    | `.agents/skills/<name>/` directory        |
| rule     | `.agents/rules/<name>.md`                 |
| agent    | `.agents/agents/<name>.md`                |
| workflow | `.agents/workflows/<name>.yaml` or `.yml` |
| mcp      | entry `"<name>"` in `.mcp.json`           |

If the artifact is not found in any location, report: `artifact '<name>' not found — nothing to remove`.

If multiple matches exist (unlikely but possible), list them and ask the user to confirm which.

---

### Step 2 — Show side effects

**⏸ Removal confirmation** — report what will be removed and wait for explicit confirmation:

```
Will remove:
  - .agents/skills/r3-foo-bar/SKILL.md
  - .agents/skills/r3-foo-bar/ (directory)
  - AGENTS.md row: | `r3-foo-bar` | ... |

Proceed? (yes / no)
```

For each artifact type, the side effects are:

**skill** — delete `<name>/` directory; remove the matching row from the `AGENTS.md` table.
If removing the row leaves a group table empty, also remove the empty `### <Group>` section.

**rule** — delete the `.md` file. No other side effects.

**agent** — delete the `.md` file. No other side effects.

**workflow** — delete the `.yaml` file. No other side effects.

**mcp** — remove the `"<name>"` key from `mcpServers` in the target `.mcp.json`.

---

### Step 3 — Execute (after confirmation)

Apply the deletions and edits described in Step 2. Use surgical edits — do not rewrite
entire files, only remove the target lines or keys.

---

### Step 4 — Verify

After removal, confirm:

- The file or directory no longer exists on disk.
- For skills: the row is gone from `AGENTS.md` and no empty group section remains.
- For MCP: `.mcp.json` is still valid JSON after the key removal.

Report in one line: what was removed and what was cleaned up.

## Constraints

- Always verify the artifact exists before deleting.
- Never apply deletions without explicit user confirmation at the ⏸ pause.
- Use surgical edits — remove only the target lines or keys, never rewrite entire files.
