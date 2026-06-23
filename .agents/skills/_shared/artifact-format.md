# Skill format — canonical structure for r3 skills

How to write the body of a `SKILL.md`. Applies to every skill under `.agents/skills/`.
Consumed by `r3-artifact-create` (creation) and `r3-artifact-improve` (audit/refactor).

**Root virtue — predictability:** a skill exists to make a stochastic agent take the same _process_ every
run (not to produce the same output). Every rule below serves that; when a choice is unclear, pick the
option that makes the agent's behaviour more repeatable.

---

## Skill types

A skill is one of two shapes. Both share the frontmatter, writing rules, body budget, and failure modes below.

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
3. **Steps** — numbered `### Step N — <title>` sections with imperative instructions. End each step on a
   **completion criterion** — a checkable condition that separates done from not-done, and where it matters
   an exhaustive one ("every modified file accounted for", not "produce a list"). A vague criterion invites
   stopping early.
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

## Leading words

A **leading word** is a compact concept already in the model's pretraining that the agent thinks _with_
while running the skill (e.g. _tracer bullet_, _fog of war_, _red_, _drill_). One well-chosen word anchors a
whole region of behaviour in the fewest tokens by recruiting priors the model already holds, and it serves
predictability twice: in the body it anchors _execution_ (the same behaviour fires every time the word
appears); in the `description:` it anchors _invocation_ (shared language makes the agent reach for the skill
more reliably). Prefer one strong word over a restated triad ("fast, deterministic, low-overhead" → _tight_).
A weak word the agent already obeys (_be thorough_) is a no-op — reach for a sharper one (_relentless_).

## Body budget

- Target ≤ 800 tokens; flag above ~1500. A quality signal, not a hard block.
- Overflow goes to `references/<topic>.md`: long code examples, illustrative examples, background. Link from the step that needs it.
- Never cut constraints or steps to meet budget — move support material instead.
- **Load-bearing content never moves to `references/`**: decision tables, file-generation templates, and any material the agent must read on every execution stay in the body. Content in `references/` is read lazily — only support material that is safe to skip belongs there. A skill whose tables or templates _are_ its logic is allowed to exceed the budget; accept the flag.

## Failure modes

Named content defects to hunt — `r3-artifact-improve` diagnoses against these:

- **No-op** — a line the agent already obeys by default, so you pay context load for nothing. Test: does it
  change behaviour versus the default? If not, delete the whole sentence (don't trim words). Documentation
  prose ("this skill is useful because…") is the usual culprit.
- **Duplication** — the same meaning in more than one place; costs tokens and maintenance and inflates that
  meaning's apparent importance. Keep each rule in a single source of truth, and link or invoke logic that
  another skill or script already owns rather than restating it.
- **Premature completion** — a step ends before the work is truly done. Fix the completion criterion first;
  only if it is irreducibly fuzzy and you observe the rush, split the sequence so later steps don't tempt it.
- **Sprawl** — too long even when every line is live. Cure with the body budget: disclose support material to
  `references/`.
- **Sediment** — stale lines that accumulate because adding feels safe and removing feels risky; the default
  fate of any skill without a pruning pass.

Always-defects, regardless: `<placeholders>` left unfilled, and references to files that do not exist in
this workspace.

## Feedback log

A skill earns better over time by capturing what its real executions reveal. When a run **deviates** from a
skill (the steps didn't anticipate the situation, a constraint was missing, the user had to correct it),
that gap is recorded — not in the `SKILL.md`, but in a per-skill log:

- **Location:** `.agents/skills/_feedback/<skill-name>.md` — one file per skill, in the `_feedback/` dir
  (`_`-prefixed, so harnesses and `r3-artifact-audit` skip it). Committed; created lazily on the first entry.
- **Format:** append-only entries, each:

    ```markdown
    ## <YYYY-MM-DD> — <short title>

    - **Observed**: <what happened during the run — the friction/deviation, concrete, with evidence>
    - **Gap**: <what the skill failed to anticipate / what is missing or unclear>
    - **Proposed**: <concrete change to the SKILL.md>
    - **Status**: open | folded
    ```

- **The loop:** `r3-artifact-retro` writes entries (capture, read-only on the `SKILL.md`);
  `r3-artifact-improve` reads `open` entries as real-world evidence, folds confirmed gaps into the
  `SKILL.md`, and marks them `folded` (history is kept, not deleted). A clean run logs nothing.
