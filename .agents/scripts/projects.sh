#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
GITIGNORE="$REPO_ROOT/.gitignore"

source "$SCRIPT_DIR/_shared.sh"

# ── private ───────────────────────────────────────────────────────────────────

_project_dir() { echo "$REPO_ROOT/$1"; }

# A directory is a workspace project if it has .git/ and is listed in .gitignore
_is_project() {
    local name="$1"
    [[ -d "$REPO_ROOT/$name/.git" ]] && grep -qxF "/$name/" "$GITIGNORE" 2>/dev/null
}

_wire_project() {
    local target="$1" name="$2"

    # Register in .gitignore
    if grep -qxF "/$name/" "$GITIGNORE" 2>/dev/null; then
        _warn "/$name/ already in .gitignore"
    else
        echo "/$name/" >> "$GITIGNORE"
        _ok "gitignored: /$name/"
    fi

    # .gitignore — exclude workspace wiring from the project's own repo
    local project_gitignore="$target/.gitignore"
    local gitignore_entries=("CLAUDE.md" ".claude/" ".agents/scripts" ".warp/")
    local added=0
    for entry in "${gitignore_entries[@]}"; do
        if ! grep -qxF "$entry" "$project_gitignore" 2>/dev/null; then
            echo "$entry" >> "$project_gitignore"
            added=$((added + 1))
        fi
    done
    if [[ "$added" -gt 0 ]]; then
        _ok "updated: $name/.gitignore (r3 wiring entries)"
    else
        _warn "$name/.gitignore r3 entries already present — skipped"
    fi

    # CLAUDE.md — inherits workspace agent config
    if [[ -f "$target/CLAUDE.md" ]]; then
        _warn "CLAUDE.md already exists in $name — skipped"
    else
        echo "@../AGENTS.md" > "$target/CLAUDE.md"
        _ok "created: $name/CLAUDE.md"
    fi

    _create_symlink "$target/.claude/skills"   ../../.agents/skills      "$name/.claude/skills"
    _create_symlink "$target/.claude/rules"    ../../.agents/rules       "$name/.claude/rules"
    _create_symlink "$target/.claude/agents"   ../../.agents/agents      "$name/.claude/agents"
    _create_symlink "$target/.agents/scripts"  ../../.agents/scripts     "$name/.agents/scripts"
    _create_symlink "$target/.warp/workflows"  ../../.agents/workflows   "$name/.warp/workflows"

    # .mcp.json — MCP server registration (empty scaffold, fill with project-specific servers)
    if [[ -f "$target/.mcp.json" ]]; then
        _warn ".mcp.json already exists in $name — skipped"
    else
        printf '{\n    "mcpServers": {}\n}\n' > "$target/.mcp.json"
        _ok "created: $name/.mcp.json"
    fi

    # .agents/notes/INDEX.md — project notes entry point
    local notes_index="$target/.agents/notes/INDEX.md"
    if [[ -f "$notes_index" ]]; then
        _warn ".agents/notes/INDEX.md already exists in $name — skipped"
    else
        mkdir -p "$(dirname "$notes_index")"
        cat > "$notes_index" <<EOF
# $name — Notes

Project notes for AI agents working on this project.

## Overview

_Describe this project here._

## Notes

_Add [[WikiLinks]] to notes as they are created._
EOF
        _ok "created: $name/.agents/notes/INDEX.md"
    fi
}

# ── commands ──────────────────────────────────────────────────────────────────

cmd_list() {
    local found=0
    printf "%-20s %-15s %-6s %-50s %s\n" "NAME" "BRANCH" "DIRTY" "REMOTE" "LAST COMMIT"
    printf "%-20s %-15s %-6s %-50s %s\n" "----" "------" "-----" "------" "-----------"

    for dir in "$REPO_ROOT"/*/; do
        local name
        name=$(basename "$dir")
        _is_project "$name" || continue
        found=1

        local branch remote last dirty
        branch=$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unreadable")
        remote=$(git -C "$dir" remote get-url origin 2>/dev/null || echo "(no remote)")
        last=$(git -C "$dir" log -1 --format="%h %s" 2>/dev/null || echo "(no commits)")
        dirty=$(git -C "$dir" status --short 2>/dev/null | wc -l | tr -d ' ')
        [[ "$dirty" -gt 0 ]] && dirty="yes ($dirty)" || dirty="no"

        printf "%-20s %-15s %-6s %-50s %s\n" "$name" "$branch" "$dirty" "$remote" "$last"
    done

    if [[ "$found" -eq 0 ]]; then
        _info "no projects in workspace — run: projects.sh add <url> [name]"
    fi
}

cmd_add() {
    local url="" name=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --*) _die "unknown option $1" ;;
            *)
                if   [[ -z "$url"  ]]; then url="$1"
                elif [[ -z "$name" ]]; then name="$1"
                fi
                shift ;;
        esac
    done

    [[ -z "$url" ]] && _usage "projects.sh add <url> [name]"
    [[ -z "$name" ]] && name=$(_name_from_url "$url")

    local target
    target=$(_project_dir "$name")
    [[ -d "$target" ]] && _die "'$name' already exists in workspace root"

    _info "cloning $url → $target"
    git clone "$url" "$target"

    _wire_project "$target" "$name"

    _done "$name added to workspace"
}

cmd_wire() {
    local name="${1:-}"
    [[ -z "$name" ]] && _usage "projects.sh wire <name>"

    local dir
    dir=$(_project_dir "$name")
    [[ -d "$dir/.git" ]] || _die "'$name' is not a git repository in the workspace root"

    _wire_project "$dir" "$name"

    _done "$name wired"
}

cmd_status() {
    local name="${1:-}"
    [[ -z "$name" ]] && _usage "projects.sh status <name>"

    local dir
    dir=$(_project_dir "$name")
    [[ -d "$dir" ]] || _die "'$name' not found in workspace root"

    _is_project "$name" || _warn "'$name' is not a registered workspace project"

    local uncommitted
    uncommitted=$(git -C "$dir" status --short 2>/dev/null)
    if [[ -n "$uncommitted" ]]; then
        _warn "uncommitted: yes"
        echo "$uncommitted" | sed 's/^/  /'
    else
        _ok "uncommitted: no"
    fi

    local unpushed
    unpushed=$(git -C "$dir" log "@{u}..HEAD" --oneline 2>/dev/null || echo "")
    if [[ -n "$unpushed" ]]; then
        _warn "unpushed: yes"
        echo "$unpushed" | sed 's/^/  /'
    else
        _ok "unpushed: no"
    fi
}

cmd_remove() {
    local name="" force=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force) force=true; shift ;;
            *) name="$1"; shift ;;
        esac
    done

    [[ -z "$name" ]] && _usage "projects.sh remove <name> [--force]"

    [[ "$force" != "true" ]] && \
        _die "refusing to delete without --force. Run 'projects.sh status $name' first, then re-run with --force."

    local dir
    dir=$(_project_dir "$name")
    [[ -d "$dir" ]] || _die "'$name' not found in workspace root"

    rm -rf "$dir"
    _ok "deleted: $dir"

    if [[ -f "$GITIGNORE" ]]; then
        local tmp
        tmp=$(mktemp)
        grep -vxF "/$name/" "$GITIGNORE" > "$tmp" && mv "$tmp" "$GITIGNORE"
        _ok "ungitignored: /$name/"
    fi

    _done "$name removed from workspace"
}

# ── dispatch ──────────────────────────────────────────────────────────────────

_require_workspace

case "${1:-}" in
    list)   cmd_list ;;
    add)    shift; cmd_add "$@" ;;
    wire)   shift; cmd_wire "${1:-}" ;;
    status) shift; cmd_status "${1:-}" ;;
    remove) shift; cmd_remove "$@" ;;
    *)
        echo "usage: projects.sh <command> [args]"
        echo ""
        echo "commands:"
        echo "  list                     list all workspace projects"
        echo "  add <url> [name]         clone and register a project"
        echo "  wire <name>              wire an already-cloned project (symlinks, CLAUDE.md, notes)"
        echo "  status <name>            show uncommitted and unpushed state"
        echo "  remove <name> [--force]  delete project directory and unregister from .gitignore"
        exit 1
        ;;
esac
