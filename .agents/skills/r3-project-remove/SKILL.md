---
name: r3-project-remove
description: >
    Remove a project repository from the workspace. Deletes the project directory and
    removes its entry from .gitignore. Use when the user says "remove project", "quita el proyecto",
    "elimina el proyecto", or wants to clean up a project from the workspace.
allowed-tools: [Bash, Read]
user-invocable: true
---

# r3-project-remove

Remove a project repository from the workspace.

## Arguments

```
/r3-project-remove <name>
```

- `<name>` — Required. Directory name of the project to remove.

## Steps

### 1. Check project state

```bash
.agents/scripts/projects.sh status <name>
```

### 2. Present summary and confirm

Show the status output to the user and present a confirmation prompt before proceeding:

```
About to remove project '<name>' from the workspace:
  Directory:  <workspace-root>/<name>/  (will be deleted)
  .gitignore: /<name>/ entry (will be removed)
  Uncommitted changes: <from status output>
  Unpushed commits:    <from status output>

Proceed? This cannot be undone.
```

Wait for explicit user confirmation. If the user does not confirm, stop.

### 3. Remove the project

```bash
.agents/scripts/projects.sh remove <name> --force
```

### 4. Confirm

Relay the script's output. Report in one line: `removed <name> from workspace`.

## Constraints

- Never skip the confirmation step, especially when uncommitted or unpushed work is present.
- Never call `projects.sh remove` without first running `projects.sh status` and getting user confirmation.
- This operation is irreversible. The confirmation step is non-negotiable.
