<!-- Link sibling artifacts with WikiLinks: this change's [[design]] and [[tasks]], and each affected
     capability's [[spec]]; a graduating exploration links back to its `_contracts/explorations/` note. -->

## Why

<!-- Explain the motivation for this change. What problem does this solve? Why now? -->
<!-- Optional user-story framing: As a <role>, I want <capability>, so that <value>. -->
<!-- Business KPIs / post-launch outcome metrics belong here (not in the spec contract). -->

## What Changes

<!-- Describe what will change. Be specific about new capabilities, modifications, or removals. -->

## Capabilities

### New Capabilities

<!-- Capabilities being introduced. Replace <name> with kebab-case identifier (e.g., user-auth, data-export, api-rate-limiting). Each creates specs/<name>/spec.md -->

- `<name>`: <brief description of what this capability covers>

### Modified Capabilities

<!-- Existing capabilities whose REQUIREMENTS are changing (not just implementation).
     Only list here if spec-level behavior changes; the change's spec.md carries the changed requirements in full.
     Use existing spec names from _contracts/specs/. Leave empty if no requirement changes. -->

- `<existing-name>`: <what requirement is changing>

## Spec Impact

<!-- The requirement-level effect on the living specs/. The change's spec.md carries the FULL text of added and
     changed requirements; this section is the human summary AND the home for removals (which are NOT written in
     spec.md). At close, `sync` cross-checks every removal/rename in `git diff specs/` against this list. -->

- **Added**: `<capability>` [[REQ-NNN]] <name> — <one line>
- **Modified**: `<capability>` [[REQ-NNN]] <name> — <what changed>
- **Removed**: `<capability>` [[REQ-NNN]] <name> — **Reason**: <why> · **Migration**: <what consumers do>
- **Renamed**: `<capability>` [[REQ-NNN]] "<old>" → "<new>"

## Impact

<!-- Affected code, APIs, dependencies, systems -->
