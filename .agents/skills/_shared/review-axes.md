# Review axes — the four read-only lenses (shared reference)

Consumed by `r3-craft-review`: each axis runs as its own read-only sub-agent. These are language-agnostic
**lenses**; the concrete standard of the codebase lives in `.agents/rules/`, the project `constitution`, and
`AGENTS.md` — each axis applies those rules to its target.

## Shared discipline (every axis)

- **Read-only.** Find problems; never fix them.
- **Severity** on every finding: `BLOCKER` (must fix before merge) · `CRITICAL` (serious, fix now) ·
  `WARNING` · `SUGGESTION`.
- **Evidence required.** Cite `file:line` and the exact pattern — no "looks risky" without a concrete cite.
- **WARNING real vs theoretical.** `WARNING (real)` only if normal intended use can trigger it; a
  contrived/impossible path is `WARNING (theoretical)` → downgrade to `SUGGESTION`.
- **Sentinel.** If the axis finds nothing, return exactly `No findings.`
- Respect each axis's **do-not-flag** list — it kills the common false positives.

## R1 — Risk (security)

Flag: secrets/credentials/tokens hardcoded or written to logs; authorization enforced only client-side or in
the UI (require a server-side / trust-boundary check); injection — SQL/command/path strings built by
concatenation instead of parameterization; untrusted input reaching a dangerous sink (eval, shell, file path,
deserialization) without validation; vulnerable or unpinned dependencies (cite the package/advisory).

Do not flag: framework defaults that already escape/parameterize when no raw sink is involved.

## R2 — Readability (clarity & maintainability)

Flag: magic numbers/strings that should be named constants; long parameter lists that should be a parameter
object/struct; duplicated logic across modules/functions; dead code (unused imports, unreachable branches,
commented-out blocks, never-called functions); naming that hides intent or needs comment-heavy explanation; a
function/module/diff too large to review safely (cite the span — don't assert "too complex" without evidence).

Do not flag: a small, clear, local helper or inline constant that is self-explanatory.

## R3 — Reliability (tests & behavior)

Flag: a behavior change with no test asserting the externally-visible contract; implementation-centric tests
(coupled to internals — they break on refactor though behavior is unchanged); missing edge cases (boundaries,
invalid input, empty states, error/failure paths); non-determinism (tests or code depending on unseeded RNG,
wall-clock, or uncontrolled external deps); error paths never exercised.

Do not flag: integration-style tests that assert behavior through the public interface — those are the goal.

## R4 — Resilience (operation)

Flag: a failure mode with no fallback, retry, or graceful-degradation path; errors expected in the wild with
no logging/observability hook; a risky change with no rollback/recovery path; performance regressions beyond a
stated budget, or unmeasured perf claims; resource leaks (unclosed handles, unbounded growth) and
panics/`unwrap`-style aborts on production paths.

Do not flag: low-impact issues already isolated/handled, or generic "might be slow" without measurement.
