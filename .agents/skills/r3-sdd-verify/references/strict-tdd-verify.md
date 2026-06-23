# Strict-TDD verify companion (loaded by r3-sdd-verify when active)

Loaded ONLY when strict-TDD is active. Audits the TDD discipline against the actual code and tests.

## Checks

- **TDD Cycle Evidence** present for the change's behavior tasks (the table from `strict-tdd.md`); a behavior task
  with no test → CRITICAL.
- **Scenario coverage** — every `#### Scenario:` of every `REQ-###` has a covering test that passed at runtime; an
  uncovered scenario → CRITICAL (UNTESTED).
- **Assertion quality** — scan changed tests for the banned patterns in `strict-tdd.md` (tautology, ghost loop,
  smoke-only, type-only, implementation coupling); each hit → WARNING with `file:line`.
- **Mock ratio** — flag tests over the 7-mock threshold (wrong layer) → WARNING.
- **Full suite** — the full test suite passes (strict-TDD runs only the relevant file during apply; the full run is here).

## Output

Fold into the verify report's Correctness / Coherence dimensions: a Spec Compliance row per scenario
(`REQ-### | Scenario | Test | Result`) plus the assertion-quality findings. Read-only — emits a report, writes no files.
