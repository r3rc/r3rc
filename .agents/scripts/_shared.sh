#!/usr/bin/env bash
# Shared helpers for r3 scripts. Source this file, do not execute it.
# Callers must define REPO_ROOT before calling _require_workspace.

# ── ui ────────────────────────────────────────────────────────────────────────
# Colors only when stdout is a TTY and NO_COLOR is unset.

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    _C_GREEN=$'\033[32m'; _C_YELLOW=$'\033[33m'; _C_RED=$'\033[31m'
    _C_CYAN=$'\033[36m'; _C_BOLD=$'\033[1m'; _C_OFF=$'\033[0m'
else
    _C_GREEN=''; _C_YELLOW=''; _C_RED=''; _C_CYAN=''; _C_BOLD=''; _C_OFF=''
fi

_info()  { echo "${_C_CYAN}→${_C_OFF} $*"; }
_ok()    { echo "${_C_GREEN}✓${_C_OFF} $*"; }
_warn()  { echo "${_C_YELLOW}!${_C_OFF} $*"; }
_error() { echo "${_C_RED}✗ error:${_C_OFF} $*" >&2; }
_die()   { _error "$@"; exit 1; }
_done()  { echo "${_C_GREEN}${_C_BOLD}done:${_C_OFF} $*"; }
_usage() { echo "usage: $*" >&2; exit 1; }

# ── guards ────────────────────────────────────────────────────────────────────

_require_workspace() {
    [[ -f "$REPO_ROOT/AGENTS.md" ]] || _die "workspace root not found — expected AGENTS.md at $REPO_ROOT"
}

_require_jq() {
    command -v jq &>/dev/null || _die "jq is required but not installed"
}

# _name_from_url <git-url> — derive a lowercase kebab-case name from a repo URL
_name_from_url() {
    basename "$1" .git | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g'
}

# _create_symlink <link-path> <target> [display-name]
# Creates parent directory if needed. Increments `created`/`skipped` counters
# when the caller has them defined (setup.sh); otherwise they land as unused globals.
_create_symlink() {
    local link="$1" target="$2" display="${3:-$1}"
    mkdir -p "$(dirname "$link")"
    if [[ -e "$link" || -L "$link" ]]; then
        _warn "$display already exists — skipped"
        skipped=$(( ${skipped:-0} + 1 ))
    else
        ln -s "$target" "$link"
        _ok "$display → $target"
        created=$(( ${created:-0} + 1 ))
    fi
}
