---
name: r3-craft-drill
description: >
    Relentlessly interrogate a plan or design — one decision at a time, recommending an answer each
    time — until every choice is explicit and the plan is hard enough to build from. The convergent
    counterpart to exploring. Triggers (EN+ES): "drill me", "drill the plan", "stress-test this plan",
    "pressure-test the design", "interrogate the plan", "harden the plan", "grill me", "gríllame",
    "cuestióname el plan", "interrógame el plan", "endurece el plan", "presiona el plan".
user-invocable: true
---

# r3-craft-drill — harden a plan by interrogating every decision

A **stance skill** — a posture, not a procedure. Drive a soft plan to a hard one by walking its
decision tree and forcing every choice to be explicit. Cross-cutting: works on any plan (an SDD
change, a refactor, an architecture call, a naming decision), not only SDD.

## Stance

Interrogate relentlessly until you reach shared understanding. **Converge** — assume a direction
exists and harden it; do not open new threads for their own sake (that is exploring). Four rules:

1. **One question at a time.** Wait for the answer before the next. Batching questions is bewildering
   and yields shallow answers.
2. **Recommend an answer to every question.** Never ask open-endedly — propose the choice you would
   make and why, so the user reacts to a concrete option instead of generating one from scratch.
3. **Read the code instead of asking** whenever the codebase holds the answer. Do not ask the user
   what the disk already knows.
4. **Walk the decision tree in dependency order.** A decision that gates others comes first; resolve
   it before the choices that depend on it.

## What you might do

No fixed order — whatever the plan needs:

- Map the open decisions (the branches of the tree) and the dependencies between them.
- Drive down each branch one question at a time, carrying your recommended answer.
- Surface hidden assumptions, edge cases, and failure modes as each decision lands.
- Verify a claim against the code rather than taking it on faith.
- Stop when the plan is **hard enough** — every load-bearing decision explicit — and hand off.

## Constraints

- Never implement code. Drill hardens the plan; it does not build it.
- One question at a time — never batch. Every question carries your recommended answer.
- Prefer reading the code over asking when the answer is in the codebase.
- Converge, don't diverge. If the session needs open-ended investigation, that is `r3-sdd-explore`.
- In the SDD flow, drill sits between exploring and proposing: once the plan is hard, hand off to
  `r3-sdd-propose` to author the artifacts.
