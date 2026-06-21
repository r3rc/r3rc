---
name: r3-project-list
description: >
    List all project repositories registered in the workspace. Use when the user says
    "list projects", "what projects are in the workspace", "show workspace", or "qué proyectos hay".
allowed-tools: [Bash]
user-invocable: true
---

# r3-project-list

List all project repositories currently registered in the workspace.

## Steps

### Step 1 — Run the script

```bash
.agents/scripts/projects.sh list
```

### Step 2 — Present results

Relay the script's output to the user as-is. If no projects are found, suggest running `/r3-project-add`.

## Constraints

- Read-only. Never modify any project or the workspace configuration.
