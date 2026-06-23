# <!-- Project --> Constitution

<!-- Per-project governance: binding principles + technical standards + mandates. Read explicitly by the
     workflow (the Constitution Check gate in design, re-verified at verify). Engine-neutral. -->

## Core Principles

### I. <!-- Principle name -->

<!-- The binding rule(s), in MUST/SHALL language. -->

**Rationale**: <!-- why this is non-negotiable -->

### II. <!-- ... -->

## Standards

<!-- Free-form project standards: security, cross-platform, conventions, quality gates. -->

## Testing

<!-- The strict-TDD mandate + the project's testing capabilities (read by the strict-TDD module). -->

- **Strict TDD**: <!-- mandatory | not applicable (no test runner) -->
- **Runner**: <!-- e.g. `cargo test` / `go test ./...` / `npm test` -->
- **Layers**: <!-- unit / integration / e2e (those available) -->
- **Coverage**: <!-- command, if any -->

## Governance

<!-- Authority (what this doc supersedes); Amendments (PR + approval); SemVer-for-governance:
     MAJOR = remove/redefine a principle · MINOR = add a principle/section · PATCH = clarify.
     On amend: bump the footer below + run a propagation check for stale references to touched principles.
     (Git is the change history — no separate impact-report block.) -->

**Version**: 0.1.0 | **Ratified**: <!-- YYYY-MM-DD --> | **Last Amended**: <!-- YYYY-MM-DD -->
