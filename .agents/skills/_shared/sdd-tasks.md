<!-- Tasks in phase/slice order. Task states: [ ] todo · [x] done · [-] skipped (note why) · [!] blocked ·
     [?] needs-decision. `[P]` = parallelizable — only safe when the slices' `Owns:` globs do NOT overlap.
     Each behavior task cites the requirement it implements as [[REQ-###]]; tests go before implementation when
     the constitution mandates strict-TDD. -->
<!-- Review Workload Forecast: <small | medium | large> — flag/split a slice if oversized. -->

## 1. Setup

- [ ] 1.1 [P] <!-- shared scaffolding / skeleton stubs (structural; TDD-exempt) -->

## 2. Foundational

- [ ] 2.1 <!-- blocking prerequisites; stubs from the Domain Model (walking skeleton) -->

## 3. Slice P1 — <!-- MVP name --> 🎯

**Satisfies**: [[REQ-###]] <!-- the requirement(s) this slice delivers -->
**Owns**: <!-- file globs this slice may modify, e.g. `src/auth/**` — enables safe [P] and scope-creep checks -->
**Independent Test**: <!-- how this slice is verified standalone -->

- [ ] 3.1 <!-- behavior (test-first under strict-TDD) --> ([[REQ-###]])

## 4. Slice P2 — <!-- name -->

**Satisfies**: [[REQ-###]]
**Owns**: <!-- globs -->
**Depends**: <!-- slice(s) that must finish first, e.g. `P1` — omit if independent -->
**Independent Test**: <!-- ... -->

- [ ] 4.1 <!-- ... --> ([[REQ-###]])

## N. Polish

- [ ] N.1 <!-- cross-cutting cleanup -->
