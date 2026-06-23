---
name: r3-craft-debug
description: >
    Diagnosis discipline for hard bugs and performance regressions — build a tight feedback loop first,
    then reproduce, hypothesise, instrument, fix, and post-mortem. Use when something is broken, throwing,
    failing, flaky, or slow. Triggers (EN+ES): "debug this", "diagnose", "diagnose the bug", "this is
    broken", "it's throwing", "tests are failing", "it's slow", "performance regression", "depura esto",
    "diagnostica el bug", "está roto", "tira error", "los tests fallan", "anda lento", "regresión de
    performance".
user-invocable: true
---

# r3-craft-debug — diagnose a hard bug, feedback-loop first

A discipline for hard bugs and performance regressions. Cross-cutting: any codebase, any language. Skip a
phase only with an explicit reason. The whole method rests on Phase 1 — everything after it is mechanical.

## Steps

### Phase 1 — Build a feedback loop (this is the skill)

A **tight, red-capable** signal that goes red on _this_ bug. With it, the cause is 90% found — bisection,
hypothesis-testing, and instrumentation just consume it. Without it, staring at code will not save you. Be
aggressive and creative here; spend disproportionate effort.

Ways to construct one, roughly in order of preference:

- a **failing test** at whatever seam reaches the bug (unit / integration / e2e);
- an **HTTP/CLI script** against a running process, diffing output against known-good;
- a **replayed trace** — capture a real request/payload/event to disk, replay it through the path in isolation;
- a **throwaway harness** — a minimal subset of the system that hits the bug code path in one call;
- a **property/fuzz loop** for "sometimes wrong" bugs; a **bisection** or **differential** loop when the bug
  appeared between two known states;
- a **human-in-the-loop script** only as a last resort, structured so its output still feeds back to you.

**Tighten the loop** like a product: faster (cache setup, narrow scope), sharper (assert the exact symptom,
not "didn't crash"), more deterministic (pin time, seed RNG, isolate the filesystem, freeze the network).
For non-deterministic bugs the goal is a **higher reproduction rate**, not a clean repro — loop, parallelise,
add stress until it is debuggable.

**Completion criterion:** name one command you have **already run** (paste the invocation and its output)
that is red-capable (drives the real path, asserts the user's exact symptom), deterministic, fast, and
agent-runnable. **No red-capable command → no Phase 2.** Building a theory before this command exists is the
exact failure this skill prevents.

### Phase 2 — Reproduce + minimise

Run the loop; watch it go red. Confirm it reproduces the **user's** symptom (not a nearby failure) and is
repeatable. Then shrink to the **smallest scenario that still goes red** — cut inputs, callers, config, and
data one at a time, re-running after each cut. Done when every remaining element is load-bearing.

### Phase 3 — Hypothesise

Generate **3–5 ranked, falsifiable hypotheses before testing any** (a single hypothesis anchors on the
first plausible idea). Each states a prediction: "if X is the cause, changing Y makes it disappear." Show
the ranked list to the user — they often re-rank instantly with domain knowledge. Don't block if they're away.

### Phase 4 — Instrument

Each probe maps to a specific prediction; **change one variable at a time**. Prefer a debugger/REPL over
logs; if logging, target the boundaries that distinguish hypotheses — never "log everything and grep". Tag
every debug log with a unique prefix (e.g. `[DEBUG-a4f2]`) so cleanup is one grep. For performance, measure
a baseline (timing harness / profiler) and bisect — logs are usually the wrong tool.

### Phase 5 — Fix + regression test

Write the regression test **before** the fix — but only at a **correct seam**, one that exercises the real
bug pattern as it occurs at the call site. If the only available seam is too shallow to catch the real
pattern, **that absence is itself the finding** — note it and flag the architecture. Otherwise: fail → fix →
pass → re-run the Phase 1 loop against the original (un-minimised) scenario.

### Phase 6 — Cleanup + post-mortem

Before declaring done: the original repro no longer reproduces; the regression test passes (or the seam
absence is documented); all tagged instrumentation is removed (grep the prefix); throwaway harnesses are
deleted; the hypothesis that proved correct is stated in the commit/PR so the next debugger learns. Then ask
**what would have prevented this** — if the answer is architectural, record it.

## Constraints

- No hypothesising before a red-capable feedback loop exists — the Phase 1 gate is non-negotiable.
- One variable per probe; one cut at a time when minimising.
- Never leave tagged debug instrumentation or throwaway harnesses in the tree.
- A regression test counts only at a correct seam; a missing seam is a finding, not a skip.
