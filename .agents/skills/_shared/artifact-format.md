# Skill format — canonical structure for r3 skills

How to write the body of a `SKILL.md`. Applies to every skill under `.agents/skills/`.
Consumed by `r3-artifact-create` (creation) and `r3-artifact-improve` (audit/refactor).

---

## Skill types

A skill is one of two shapes. Both share the frontmatter, writing rules, body budget, and anti-patterns below.

- **Procedure skill** (default) — a step-by-step task. Uses the section order below (Steps-based). Most skills.
- **Stance skill** — a mode/posture with no fixed procedure (e.g. an "explore" / "think" mode). Replaces **Steps**
  with a **`## Stance`** section (the posture + principles), optionally followed by loose guidance ("What you might
  do"), then **Constraints**. Use only when the skill genuinely has no ordered procedure — not to dodge writing steps.

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

(For **procedure** skills. A **stance** skill replaces Steps with a `## Stance` section — see Skill types.)

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
- **`⏸` marks blocking gates only** — a point where the skill MUST stop and wait for an explicit user decision (approval, confirmation, a choice that changes course, or any destructive/irreversible action). Name it and declare the response: `**⏸ <name>** — <what is presented>. Wait for <expected response>.` Never a bare "present and wait".
- Clarifying questions (gathering missing input) and a skill ending its own scope (a natural stop/handoff) are normal flow — write them in prose, not as `⏸`.
- Destructive or irreversible operations are always a `⏸` gate with explicit confirmation before executing.
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
