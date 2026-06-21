#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEMPLATES_DIR="$REPO_ROOT/.agents/skills/_shared/sdd/templates"

source "$SCRIPT_DIR/_shared.sh"

# Mechanical scaffold/archive for the r3 SDD convention (engine-free).
# Operates on the openspec/ tree in the current working directory's project.
# Override the target with SDD_OPENSPEC_DIR.
OPENSPEC_DIR="${SDD_OPENSPEC_DIR:-$PWD/openspec}"

# ── private ───────────────────────────────────────────────────────────────────

_require_templates() {
    [[ -d "$TEMPLATES_DIR" ]] || _die "templates not found at $TEMPLATES_DIR"
}

_valid_slug() {
    [[ "$1" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] \
        || _die "invalid slug '$1' — use kebab-case (lowercase letters, digits, hyphens)"
}

# ── commands ──────────────────────────────────────────────────────────────────

cmd_init() {
    _require_templates
    mkdir -p "$OPENSPEC_DIR/specs" "$OPENSPEC_DIR/changes/archive"
    if [[ -f "$OPENSPEC_DIR/config.yaml" ]]; then
        _warn "config.yaml already exists — skipped"
    else
        cp "$TEMPLATES_DIR/config.yaml" "$OPENSPEC_DIR/config.yaml"
        _ok "created: openspec/config.yaml"
    fi
    _done "initialized openspec/ at $OPENSPEC_DIR"
}

cmd_new() {
    local slug="${1:-}"
    [[ -n "$slug" ]] || _usage "sdd.sh new <change-slug>"
    _valid_slug "$slug"
    _require_templates
    [[ -d "$OPENSPEC_DIR/changes" ]] || _die "no openspec/changes — run: sdd.sh init"
    local dir="$OPENSPEC_DIR/changes/$slug"
    [[ -e "$dir" ]] && _die "change '$slug' already exists at $dir"
    # Create the empty change folder only. Artifact files (proposal/design/tasks/specs)
    # are authored by the agent from the templates — they exist only once filled, so that
    # "artifact done = file exists" (the status rule in sdd-schema) holds.
    mkdir -p "$dir/specs"
    _ok "scaffolded empty change: openspec/changes/$slug/ (with specs/)"
    _info "author artifacts from $TEMPLATES_DIR/ → proposal.md, specs/<capability>/spec.md, design.md, tasks.md"
    _done "created change: $slug"
}

# Archive ONLY moves the change. The delta→main spec merge is done by the agent
# (r3-sdd-sync / r3-sdd-archive) BEFORE calling this — see sdd-spec-format.md.
cmd_archive() {
    local slug="${1:-}"
    [[ -n "$slug" ]] || _usage "sdd.sh archive <change-slug>"
    local src="$OPENSPEC_DIR/changes/$slug"
    [[ -d "$src" ]] || _die "change '$slug' not found at $src"
    mkdir -p "$OPENSPEC_DIR/changes/archive"
    local dest="$OPENSPEC_DIR/changes/archive/$(date +%F)-$slug"
    [[ -e "$dest" ]] && _die "archive target already exists: $dest"
    mv "$src" "$dest"
    _done "archived: $slug → changes/archive/$(date +%F)-$slug"
}

cmd_list() {
    local cdir="$OPENSPEC_DIR/changes"
    [[ -d "$cdir" ]] || _die "no openspec/changes at $cdir — run: sdd.sh init"
    local found=0 d name
    for d in "$cdir"/*/; do
        [[ -d "$d" ]] || continue
        name="$(basename "$d")"
        [[ "$name" == "archive" ]] && continue
        echo "$name"
        found=1
    done
    [[ "$found" == 1 ]] || _info "no active changes"
}

case "${1:-}" in
    init)    shift; cmd_init "$@" ;;
    new)     shift; cmd_new "$@" ;;
    archive) shift; cmd_archive "$@" ;;
    list)    shift; cmd_list "$@" ;;
    *) _usage "sdd.sh <init | new <slug> | archive <slug> | list>   (targets \$PWD/openspec; override with SDD_OPENSPEC_DIR)" ;;
esac
