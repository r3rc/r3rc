---
name: r3-artifact-retro
description: >
    Capture execution feedback on a skill — when a run deviated from a skill (its steps didn't anticipate
    the situation, a constraint was missing, the user had to correct it), record the gap in the skill's
    feedback log so `r3-artifact-improve` can fold it in later. Use right after a skill run that hit
    friction. Triggers (EN+ES): "retro", "skill retro", "retrospective on the skill", "the skill missed
    this", "the skill didn't account for", "log skill feedback", "retro del skill", "el skill no contempló",
    "registrá feedback del skill", "qué le faltó al skill".
user-invocable: true
---

# r3-artifact-retro — capture execution feedback on a skill

After a skill run that **deviated** from its written steps, record what the skill failed to anticipate, so it
improves over time. This skill **captures** only — it never edits the `SKILL.md` (that is `r3-artifact-improve`).
The feedback-log location and format are defined in `.agents/skills/_shared/artifact-format.md` (`## Feedback log`).

## Steps

### Step 1 — Identify the target and the deviation

Name the skill(s) that just ran and state, in one line each, the concrete **deviation**: where you stepped
outside the steps, improvised around a gap, hit a missing constraint, or were corrected by the user. If the
run followed the skill exactly, **stop — a clean run logs nothing** (logging it would be a no-op). If a chain
ran, target only the skill(s) that showed friction.

### Step 2 — Self-critique (adversarial)

Be your own harshest critic — ask "what did I rationalise away?", not "did it go fine?". Judge the skill
against the **Failure modes** in `artifact-format.md` and the test _did the steps anticipate what actually
happened?_ Keep only observations backed by concrete evidence from this run; discard vague impressions.

### Step 3 — Append to the feedback log

For each observation, append an entry to `.agents/skills/_feedback/<skill-name>.md` in the format from
`artifact-format.md` (`## <date> — <title>` with **Observed** / **Gap** / **Proposed** / **Status: open**).
Create the `_feedback/` dir and the file if absent. One entry per distinct gap; do not duplicate an entry
already logged for the same gap.

### Step 4 — Report

Summarise what was logged (skill + entry titles) and note that `r3-artifact-improve` folds confirmed `open`
entries into the `SKILL.md` later.

## Output Contract

- Appended entries in `.agents/skills/_feedback/<skill-name>.md`, each with `Status: open`, or a statement
  that the run was clean and nothing was logged.

## Constraints

- Read-only on the `SKILL.md` — capture only; folding gaps in is `r3-artifact-improve`'s job.
- Log only a real deviation. A clean run produces no entry.
- Every entry carries concrete evidence from the run; no vague "could be better".
- One entry per distinct gap; never duplicate an already-logged gap.
