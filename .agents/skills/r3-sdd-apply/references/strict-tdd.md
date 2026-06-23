# Strict-TDD module (loaded by r3-sdd-apply when active)

Loaded ONLY when strict-TDD is active — the constitution `## Testing` mandates it AND a test runner is present.
When inactive, this file is never read (0 tokens). During the cycle run only the relevant test file; the full
suite runs at `verify`.

## The cycle — per behavior task

0. **SAFETY NET** — run the existing tests for the area; capture a green baseline. Stop on pre-existing failures.
1. **UNDERSTAND** — read the task, its `[[REQ-###]]` and that requirement's scenarios, the design, and existing
   code. Pick the test layer (unit by default; integration/e2e when the behavior demands it).
2. **RED** — write a failing test FIRST, referencing the not-yet-written production code. GATE: do not proceed
   until the test is written and fails for the right reason.
3. **GREEN** — write the minimum code to pass; EXECUTE. GATE: do not proceed until it passes by execution.
4. **TRIANGULATE** (mandatory by default) — add a second test with different inputs (≥2 cases per behavior) so a
   hardcoded "fake it" return breaks. Skip ONLY for a pure-structural task or a single-possible-output (note it).
   GATE: every scenario of the requirement has a test before REFACTOR.
5. **REFACTOR** — improve without changing behavior; EXECUTE after each change. For legacy / at-risk code, capture
   current behavior with an approval/snapshot test BEFORE changing it.
6. Mark the task `- [x]`; note any deviation.

**Stub-first:** Setup/Foundational tasks scaffold empty structural stubs (signatures, types, interfaces) from the
`## Domain Model` — structural and TDD-exempt. Behavior is then added test-first per the cycle. The P1 slice is the
walking skeleton.

**Cross-capability:** when a task implements a context-map interaction (a boundary crossing), add a **contract
test** that verifies the boundary holds (the consumer's expectation of the upstream capability).

## TDD Cycle Evidence (record in the apply summary)

| Task | Test File       | Layer | Safety Net | RED        | GREEN     | TRIANGULATE | REFACTOR |
| ---- | --------------- | ----- | ---------- | ---------- | --------- | ----------- | -------- |
| 1.1  | `path/test.ext` | Unit  | ✅ 5/5     | ✅ Written | ✅ Passed | ✅ 3 cases  | ✅ Clean |

When Strict TDD is active this table is MANDATORY — there is no silent fallback to a non-TDD path.

## Assertion-quality rubric

Every real assertion MUST: call production code, assert a specific output, and FAIL if the code were wrong.

Banned / flagged:

- **Tautologies** — `expect(true).toBe(true)`, `assert True` (CRITICAL).
- **Ghost loops** — assertions inside a loop over a possibly-empty collection (CRITICAL).
- **Smoke-only** — render/instantiate + "exists" with no behavioral assertion (WARNING).
- **Type-only alone** — `toBeDefined()` / not-null as the only check (WARNING).
- **Empty-collection without companion** — asserting `[]` without a non-empty companion test + a real code path (WARNING).
- **Implementation coupling** — asserting mock call counts / internal state instead of observable output (WARNING).

Mock ratio per test: ≤3 healthy · 4–6 consider extracting a pure function · 7+ STOP (wrong test layer).
