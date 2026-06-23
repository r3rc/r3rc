<!-- Tasks in phase/slice order. Task states: [ ] todo · [x] done · [-] skipped (note why) · [!] blocked ·
     [?] needs-decision. `[P]` = parallelizable — only safe when the slices' `Owns:` globs do NOT overlap.
     The slice's `**Satisfies**:` is the primary requirement link; a task adds `([[REQ-###]])` only when it maps
     to a different requirement than its slice. Tests go before implementation when strict-TDD is mandated. -->
<!-- Review Workload Forecast: <small | medium | large> — flag/split a slice if oversized. -->

## 1. Setup

- [ ] 1.1 [P] <!-- shared scaffolding / skeleton stubs (structural; TDD-exempt) -->

## 2. Foundational

- [ ] 2.1 <!-- blocking prerequisites; stubs from the Domain Model (walking skeleton) -->

## 3. Slice P1 — <!-- MVP name --> 🎯

**Satisfies**: [[REQ-###]] <!-- the requirement(s) this slice delivers -->
**Owns**: <!-- file globs this slice may modify, e.g. `src/auth/**` — enables safe [P] and scope-creep checks -->
**Independent Test**: <!-- how this slice is verified standalone -->

- [ ] 3.1 <!-- behavior (test-first under strict-TDD) -->

## 4. Slice P2 — <!-- name -->

**Satisfies**: [[REQ-###]]
**Owns**: <!-- globs -->
**Depends**: <!-- slice(s) that must finish first, e.g. `P1` — omit if independent -->
**Independent Test**: <!-- ... -->

- [ ] 4.1 <!-- ... only add ([[REQ-###]]) if it differs from the slice's Satisfies -->

## N. Polish

- [ ] N.1 <!-- cross-cutting cleanup -->
