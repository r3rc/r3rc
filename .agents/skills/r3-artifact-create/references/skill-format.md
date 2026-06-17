# Skill format — canonical structure for r3 skills

How to write the body of a `SKILL.md`. Applies to every skill under `.agents/skills/`.
Consumed by `r3-artifact-create` (creation) and `r3-artifact-improve` (audit/refactor).

---

## Frontmatter

```yaml
---
name: r3-<domain>-<action>
description: >
    <What it does + when to invoke. Include trigger phrases the user would actually
    say, in English and Spanish. Multiline with `>` is the workspace norm.>
allowed-tools: [Bash, Read] # optional — only when restricting tools
user-invocable: true
---
```

## Section order

1. `# <name> — <one-line purpose>` — title plus a 1–2 sentence intro.
2. **Arguments** — only for skills invoked with parameters: `/name <arg>` synopsis plus one bullet per argument.
3. **Steps** — numbered `### Step N — <title>` sections with imperative instructions.
4. **Output Contract** — only when the skill produces files or structured output: concrete paths and formats.
5. **Constraints** — non-negotiable rules, one bullet each.
6. **References** — only if a `references/` directory exists: link each file with one line on when to read it.

Skips are fine — a section with nothing to say is omitted, not left empty.

## Writing rules

- Everything is written in English. The only exception is trigger phrases inside the frontmatter `description:`, which stay bilingual (English + Spanish) to match user utterances.
- Imperative instructions: "Read X", "Verify Y", "Produce Z". Explain rationale only when it changes how the agent should act.
- Decision points with real forks → a situation → action table, not branching prose.
- Pauses are named and declare their output: `**⏸ <name>** — <what is presented>. Wait for <expected response>.` Never a bare "present and wait".
- Destructive or irreversible operations always pause for explicit confirmation before executing.
- Scripts own the mechanics: if a `.agents/scripts/` script already does the work, the skill invokes it and relays output — it does not reimplement the logic.

## Body budget

- Target ≤ 800 tokens; flag above ~1500. A quality signal, not a hard block.
- Overflow goes to `references/<topic>.md`: long code examples, illustrative examples, anti-patterns, background. Link from the step that needs it.
- Never cut constraints or steps to meet budget — move support material instead.
- **Load-bearing content never moves to `references/`**: decision tables, file-generation templates, and any material the agent must read on every execution stay in the body. Content in `references/` is read lazily — only support material that is safe to skip belongs there. A skill whose tables or templates _are_ its logic is allowed to exceed the budget; accept the flag.

## Anti-patterns

- Documentation prose ("this skill is useful because…") instead of executable instructions.
- Duplicating logic that another skill or script already owns — link or invoke it instead.
- `<placeholders>` left unfilled in a generated skill.
- References to files that do not exist in this workspace.
