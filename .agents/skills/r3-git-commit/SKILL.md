---
name: r3-git-commit
description: >
    Group all pending repo changes (staged, unstaged, and untracked) into logical
    conventional commits and execute them. Use whenever the user wants to commit, says
    "commit the changes", "create the commits", "commitea los cambios", "crea los commits",
    "agrupa y commitea", or when there are mixed changes that need organizing before
    committing. Also invoke when the user simply says "commit" without specifying how to group.
allowed-tools: [Bash, Read]
user-invocable: true
---

# r3-git-commit — Grouped conventional commits

Analyzes all pending changes, groups them into logical commits, shows the proposal to the
user for confirmation, and executes them.

## Steps

### Step 1 — Collect changes

```bash
git status --short
git diff
git diff --cached
```

Combine the results into a single list of modified files plus untracked files (`??`).

### Step 2 — Analyze and group

Read the full diff of each file and group changes by **purpose**, not by file.

Grouping criteria (in priority order):

1. **By feature and change type**: changes in `features/X/` that implement the same
   functionality go together even if they touch different layers (domain + data + screen).
2. **By independent type**: a refactor in the viewer goes separate from a new feature in
   the chat, even within the same feature area.
3. **Infrastructure/deps separately**: `package.json`, `package-lock.json`, lockfiles,
   build configs → their own `chore` commit.
4. **Isolated style refactors**: changes that only reorganize imports, rename internal
   variables, or remove dead code → separate `refactor` or `style` commit, unless they are
   so small they make more sense attached to the functional commit that motivated them.

The goal is that each commit reads on its own: someone running `git show <hash>` understands
what problem it solves without additional context.

### Step 3 — Present the proposal

**⏸ Commit proposal** — show the proposed grouping **before executing anything** and wait
for confirmation:

```
I propose the following commits:

1. feat(heroe): add inline tables and tool_error state to AI chat
   → orchestrator.heroe.api.schema.ts
   → heroe-chat.entity.ts, heroe-chat.factory.ts
   → chat.service.ts
   → map-structured-content-to-heroe-reports.mapper.ts
   → HeroeAiInlineTable.vue (new)
   → HeroeAiChat.vue, HeroeAiMarkdown.vue

2. refactor(heroe): migrate report viewer formatting to useFormat
   → HeroeReportViewer.vue

3. chore: bump package-lock to 2.0.1
   → package-lock.json

Proceed? Any adjustments?
```

If the user adjusts the grouping or a message, apply their changes.

### Step 4 — Execute the commits

For each group, in order:

```bash
git add <files-in-group>
git commit -m "<type>(<scope>): <subject>"
```

Include untracked files (`??`) with regular `git add` — do not ignore them.

If `git commit` fails due to a pre-commit hook, report the exact error and stop the entire
process. Do not retry, do not bypass the hook (`--no-verify`). The user must resolve the
failure before continuing.

Verify at the end:

```bash
git log --oneline -<N>
```

## Commit format

```
<type>(<scope>): <subject>
```

- **No** co-author line
- **No** extended body
- Subject: imperative, lowercase, no trailing period, max 72 characters
- Scope: functional area (`heroe`, `auth`, `products`, `finance`, `deps`, etc.)

### Types

| Type       | When                                      |
| ---------- | ----------------------------------------- |
| `feat`     | New product-visible functionality         |
| `fix`      | Bug fix                                   |
| `refactor` | Restructuring without behavior change     |
| `style`    | Formatting, imports, internal naming only |
| `chore`    | Deps, configs, lockfiles, version bumps   |
| `docs`     | Documentation                             |
| `perf`     | Performance optimization                  |
| `test`     | Tests                                     |

## Constraints

- Do not create one commit per file.
- Do not mix a new feature with a deps chore in the same commit.
- Do not add `Co-Authored-By` or any extra line to the message.
- Do not run `git add .` — always list files explicitly to avoid accidentally including
  `.env` or other sensitive files.
