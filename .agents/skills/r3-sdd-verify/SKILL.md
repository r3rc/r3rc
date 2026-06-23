---
name: r3-sdd-verify
description: >
    Spec-Driven Development — verify that an implementation matches a change's artifacts (tasks, specs, design)
    before closing. Read-only self-check across Completeness, Correctness, Coherence. Triggers (EN+ES): "verify
    the change", "sdd verify", "check the implementation matches the spec", "is it ready to close", "verifica el
    cambio", "revisa que la implementación cumpla el spec", "¿está listo para cerrar?".
user-invocable: true
---

# r3-sdd-verify — verify an implementation against its change

A read-only, agent-driven self-check that an implementation satisfies a change's artifacts. Writes NO files — it
emits a report. This is the SDD verification (it does not run the build/test suite; it searches for evidence and
infers coverage). The spec-format self-check rules are in the convention `sdd-spec-format`.

## Steps

### Step 1 — Select the change

If not given, list changes that have a `tasks.md` (mark incomplete ones "in progress") and ask which one. Do NOT
auto-select.

### Step 2 — Load artifacts

Read the change's `tasks.md`, `spec.md`, `design.md` (if present), and `.covenant/constitution.md`.
**If strict-TDD is active** (constitution `## Testing` mandate + a test runner present), also load
`references/strict-tdd-verify.md` for the assertion-quality + TDD-evidence audit; if inactive,
never load it (0 tokens).

### Step 3 — Check three dimensions

- **Completeness** — _Tasks_: parse task states; any open task (`[ ]`/`[!]`/`[?]`) → CRITICAL (a `[-]` skip needs a
  noted reason). _Spec coverage_: for each `### Requirement:`, search the codebase for evidence it is implemented;
  if missing → CRITICAL. _Scope_: a changed file outside the slices' declared `Owns:` globs → WARNING (scope creep).
  _Refs_: every `[[REQ-###]]` / `[[entity:Name]]` in the change's artifacts resolves to a definition — a dangling
  reference → WARNING.
- **Correctness** — for each requirement, find the implementing code and judge whether it matches intent (divergence →
  WARNING with `file:line`). For each `#### Scenario:`, check it is handled and (ideally) tested; uncovered → WARNING.
- **Coherence** — if `design.md` exists, check the implementation follows its decisions (contradiction → WARNING). Check
  consistency with project code patterns (deviation → SUGGESTION). If no `design.md`, note it as skipped.
  Re-check the **Constitution Check** asserted at design (by `[[PRIN-###]]`) against the actual implementation — a constitution violation
  without a justified `## Complexity Tracking` entry → WARNING. Under Strict TDD, run the `references/strict-tdd-verify.md` audit
  (TDD Cycle Evidence present + no banned assertion patterns).

### Step 4 — Report

Emit a markdown report: a summary scorecard (Completeness / Correctness / Coherence), then issues grouped CRITICAL /
WARNING / SUGGESTION (each with a specific, actionable recommendation and `file:line` where applicable), then a final
assessment: CRITICAL present → "fix before closing"; only warnings → "ready to close, with noted improvements";
clean → "all checks passed".

## Constraints

- Read-only — never write files or implement fixes here; report only.
- Prefer false-negatives: when uncertain, downgrade SUGGESTION > WARNING > CRITICAL. Every issue must be actionable.
- Graceful degradation: with only `tasks.md`, check completeness only; add correctness with specs; add coherence with design. Note what was skipped.
- For best results, run verification with a **different model** than authored the code/spec — or delegate it to a fresh adversarial agent (bias reduction).

## References

- `references/strict-tdd-verify.md` — the strict-TDD verify audit (TDD Cycle Evidence + assertion-quality checks); loaded only when strict-TDD is active (0 tokens otherwise).
