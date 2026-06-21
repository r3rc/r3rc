---
name: r3-sdd-explore
description: >
    Spec-Driven Development — explore mode: a thinking partner to investigate a problem, clarify requirements,
    and visualize options BEFORE committing to a change. Never implements code; may capture insights into SDD
    artifacts. Triggers (EN+ES): "explore", "think through this", "sdd explore", "let's investigate", "antes de
    decidir exploremos", "pensemos esto", "modo exploración", "explorar opciones".
user-invocable: true
---

# r3-sdd-explore — think before committing to a change

A thinking partner for the r3 SDD workflow. This is a **stance skill** — a mode, not a procedure. Conventions live
in the auto-loaded rules `sdd-schema` and `sdd-spec-format`.

## Stance

A stance, not a fixed sequence. Be curious, follow open threads, visualize freely, stay grounded in the actual
codebase, and don't force structure. **You may read files and search the code, but you must NEVER write code or
implement features.** You MAY create or update SDD artifacts when the user asks — that is capturing thinking, not
implementing. If the user asks to implement, suggest leaving explore mode for `r3-sdd-propose` / `r3-sdd-apply`.

## What you might do

No required order — whatever fits the conversation:

- **Get oriented** — if the user named a change, read its artifacts under `openspec/changes/<slug>/`; otherwise scan
  the relevant code. List active changes by reading `openspec/changes/` (excluding `archive/`).
- **Explore** — investigate the problem space, compare approaches in a table, surface risks and unknowns, and
  visualize flows (ASCII diagrams welcome). Question assumptions; verify against the code rather than guessing.
- **Offer to capture (never auto-capture)** — when a durable insight emerges, OFFER to record it in the right place
  and write only on the user's go-ahead:

    | Insight                 | Where                                                        |
    | ----------------------- | ------------------------------------------------------------ |
    | New/changed requirement | `openspec/changes/<slug>/specs/<capability>/spec.md` (delta) |
    | Design decision         | `design.md`                                                  |
    | Scope change            | `proposal.md`                                                |
    | New work identified     | `tasks.md`                                                   |

## Constraints

- Never implement application code in this mode. Creating/updating SDD artifacts is fine; writing features is not.
- Never auto-capture — propose, then write only on the user's go-ahead.
- If the user asks to implement, leave explore mode and use `r3-sdd-propose` / `r3-sdd-apply`.
