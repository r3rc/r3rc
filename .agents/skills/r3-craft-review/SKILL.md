---
name: r3-craft-review
description: >
    Multi-axis code review — fan out four read-only lenses (Risk, Readability, Reliability, Resilience) in
    parallel and aggregate their findings by severity, so no single concern masks another. Use before a PR,
    before closing a change, or to review a diff/branch/file set. Triggers (EN+ES): "review this", "code
    review", "multi-axis review", "review the diff", "review before pr", "revisa el código", "revisa el
    diff", "revisión de código", "revisá antes del pr", "review multi-eje".
user-invocable: true
---

# r3-craft-review — multi-axis code review

Review a target through four independent read-only lenses at once, so no single concern masks another.
Cross-cutting: any codebase. Spec/behavior conformance is **not** this skill — that is `r3-sdd-verify`.

## Steps

### Step 1 — Pin the target

Establish exactly what is under review: a diff against a ref (`git diff <ref>...HEAD`), a set of files, a
branch, or the current uncommitted changes. If unclear, ask. Confirm the diff is non-empty before fanning out.

### Step 2 — Fan out one read-only sub-agent per axis (parallel)

Launch four read-only sub-agents concurrently (one message, four Agent calls) — one per axis: **Risk ·
Readability · Reliability · Resilience**. Separate contexts keep one lens from contaminating another. Each
sub-agent prompt carries:

- the target (diff command / file list);
- its axis from `.agents/skills/_shared/review-axes.md` — the axis rules, its do-not-flag list, and the
  shared discipline (severity, evidence, `No findings.` sentinel, real-vs-theoretical WARNING);
- the project's own standard — `.agents/rules/`, the `constitution`, and `AGENTS.md` security/style rules —
  which the generic axis is applied against.

Each returns findings only (severity + `file:line` + evidence + why it matters), or exactly `No findings.`

### Step 3 — Aggregate

Collect the four reports and present them **grouped by axis, side by side**. Do **not** merge or rerank
across axes — that masking is exactly what the split prevents. Deduplicate only identical findings on the
same `file:line`.

### Step 4 — Verdict

One line per axis (its worst severity), then an overall verdict: **FAIL** if any `BLOCKER`/`CRITICAL`,
**CONCERNS** if only `WARNING`s remain, **PASS** if all four return `No findings.` Name the single worst
issue per axis; never pick one cross-axis "winner".

## Output Contract

- A report with `## Risk` / `## Readability` / `## Reliability` / `## Resilience` sections, each listing
  severity-tagged findings or `No findings.`
- A final verdict line: `PASS | CONCERNS | FAIL`, with each axis's worst severity.

## Constraints

- Read-only. This skill finds problems; it never fixes them.
- Never merge or rerank findings across axes — report them separately.
- Spec/behavior conformance is out of scope — that is `r3-sdd-verify`. These axes judge code quality, not
  whether the implementation matches the spec.
- Every finding carries evidence (`file:line` + the pattern); a claim without a cite is not a finding.
