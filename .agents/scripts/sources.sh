#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG="$REPO_ROOT/.agents/registry.json"
LINKS_DIR="$REPO_ROOT/.agents/sources"

source "$SCRIPT_DIR/_shared.sh"

# ── private ───────────────────────────────────────────────────────────────────

_init_config() {
    if [[ ! -f "$CONFIG" ]]; then
        mkdir -p "$(dirname "$CONFIG")"
        printf '{\n    "sources": []\n}\n' > "$CONFIG"
    fi
}

_registry_has() {
    local name="$1"
    [[ -n "$(jq -r --arg n "$name" '.sources[] | select(.name == $n) | .name' "$CONFIG")" ]]
}

# Store paths: portable (~) for registry, expanded for filesystem ops
_store_portable() { echo "~/.r3/sources/$1"; }
_store_path()     { echo "$HOME/.r3/sources/$1"; }
_link_path()      { echo "$LINKS_DIR/$1"; }
_expand_store()   { echo "${1/#\~/$HOME}"; }

_sync_one() {
    local name="$1" store="$2" shallow="$3"
    store=$(_expand_store "$store")
    if [[ ! -d "$store" ]]; then
        local url
        url=$(jq -r --arg n "$name" '.sources[] | select(.name == $n) | .url' "$CONFIG")
        _error "[$name] store missing at $store — re-run: sources.sh link $url $name"
        return 1
    fi
    if [[ "$shallow" == "true" ]]; then
        # Read-only reference mirror: reset --hard is correct and intentional here.
        if git -C "$store" fetch --depth=1 origin && git -C "$store" reset --hard origin/HEAD; then
            _ok "[$name] updated (shallow)"
        else
            _error "[$name] error during fetch/reset"
            return 1
        fi
    else
        if git -C "$store" pull --ff-only; then
            _ok "[$name] updated"
        else
            _error "[$name] conflict — manual intervention needed (diverged history)"
            return 1
        fi
    fi
}

# ── commands ──────────────────────────────────────────────────────────────────

cmd_list() {
    _init_config
    local count
    count=$(jq '.sources | length' "$CONFIG")
    if [[ "$count" -eq 0 ]]; then
        _info "no sources registered — run: sources.sh link <url> [name]"
        exit 0
    fi
    printf "%-20s %-30s %-15s %-8s %s\n" "NAME" "LINK" "BRANCH" "SHALLOW" "STORE"
    printf "%-20s %-30s %-15s %-8s %s\n" "----" "----" "------" "-------" "-----"
    jq -r '.sources[] | [.name, (.shallow | tostring), .store] | @tsv' "$CONFIG" | \
        while IFS=$'\t' read -r name shallow store; do
            local expanded branch
            expanded=$(_expand_store "$store")
            branch=$(git -C "$expanded" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
            printf "%-20s %-30s %-15s %-8s %s\n" "$name" ".agents/sources/$name" "$branch" "$shallow" "$store"
        done
}

cmd_link() {
    local url="" name="" branch="" depth="--depth=1" shallow=true

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --branch) branch="$2"; shift 2 ;;
            --full)   depth=""; shallow=false; shift ;;
            --*)      _die "unknown option $1" ;;
            *)
                if   [[ -z "$url"  ]]; then url="$1"
                elif [[ -z "$name" ]]; then name="$1"
                fi
                shift ;;
        esac
    done

    [[ -z "$url" ]] && _usage "sources.sh link <url> [name] [--branch <branch>] [--full]"
    [[ -z "$name" ]] && name=$(_name_from_url "$url")

    _init_config
    _registry_has "$name" && _die "'$name' already registered. Use 'sync' to update or 'remove' to replace it."

    local store link
    store=$(_store_path "$name")
    link=$(_link_path "$name")

    mkdir -p "$HOME/.r3/sources" "$LINKS_DIR"

    if [[ -d "$store" ]]; then
        _warn "reusing existing store at $store"
    else
        local branch_arg=""
        [[ -n "$branch" ]] && branch_arg="--branch $branch"
        _info "cloning $url → $store"
        # shellcheck disable=SC2086
        git clone $depth $branch_arg "$url" "$store"
    fi

    ln -s "$store" "$link"
    _ok "linked: $link → $store"

    local tmp
    tmp=$(mktemp)
    jq --indent 4 \
       --arg name "$name" --arg url "$url" --argjson shallow "$shallow" \
       --arg store "$(_store_portable "$name")" --arg branch "$branch" \
       '.sources += [{"name":$name,"url":$url,"store":$store,"shallow":$shallow,"branch":$branch}]' \
       "$CONFIG" > "$tmp" && mv "$tmp" "$CONFIG"
    _done "registered: $name | .agents/sources/$name → $(_store_portable "$name") | shallow=$shallow"
}

cmd_sync() {
    local target_name="${1:-}"
    _init_config

    local sources
    if [[ -n "$target_name" ]]; then
        sources=$(jq -c --arg n "$target_name" '[.sources[] | select(.name == $n)]' "$CONFIG")
        [[ "$(echo "$sources" | jq 'length')" -eq 0 ]] && _die "'$target_name' not found in config"
    else
        sources=$(jq -c '.sources' "$CONFIG")
    fi

    local count errors=0
    count=$(echo "$sources" | jq 'length')
    [[ "$count" -eq 0 ]] && { _info "no sources to sync"; exit 0; }

    while IFS= read -r entry; do
        local name store shallow
        name=$(echo "$entry" | jq -r '.name')
        store=$(echo "$entry" | jq -r '.store')
        shallow=$(echo "$entry" | jq -r '.shallow')
        _sync_one "$name" "$store" "$shallow" || errors=$((errors + 1))
    done < <(echo "$sources" | jq -c '.[]')

    [[ "$errors" -gt 0 ]] && exit 1
    exit 0
}

cmd_restore() {
    local target_name="${1:-}"
    _init_config

    local sources
    if [[ -n "$target_name" ]]; then
        sources=$(jq -c --arg n "$target_name" '[.sources[] | select(.name == $n)]' "$CONFIG")
        [[ "$(echo "$sources" | jq 'length')" -eq 0 ]] && _die "'$target_name' not found in config"
    else
        sources=$(jq -c '.sources' "$CONFIG")
    fi

    local count errors=0
    count=$(echo "$sources" | jq 'length')
    [[ "$count" -eq 0 ]] && { _info "no sources to restore"; exit 0; }

    mkdir -p "$HOME/.r3/sources" "$LINKS_DIR"

    while IFS= read -r entry; do
        local name url store shallow link
        name=$(echo "$entry" | jq -r '.name')
        url=$(echo "$entry" | jq -r '.url')
        store=$(_expand_store "$(echo "$entry" | jq -r '.store')")
        shallow=$(echo "$entry" | jq -r '.shallow')
        link=$(_link_path "$name")

        if [[ -d "$store" ]]; then
            _info "[$name] store present"
        else
            local depth="" branch_arg=""
            [[ "$shallow" == "true" ]] && depth="--depth=1"
            local branch
            branch=$(echo "$entry" | jq -r '.branch // ""')
            [[ -n "$branch" ]] && branch_arg="--branch $branch"
            _info "[$name] cloning $url → $store"
            # shellcheck disable=SC2086
            if ! git clone $depth $branch_arg "$url" "$store"; then
                _error "[$name] clone failed"
                errors=$((errors + 1))
                continue
            fi
        fi

        if [[ -L "$link" ]]; then
            _info "[$name] link present"
        elif [[ -e "$link" ]]; then
            _error "[$name] $link exists but is not a symlink — fix manually"
            errors=$((errors + 1))
        else
            ln -s "$store" "$link"
            _ok "[$name] linked: .agents/sources/$name → $store"
        fi
    done < <(echo "$sources" | jq -c '.[]')

    [[ "$errors" -gt 0 ]] && exit 1
    _done "restore complete ($count sources checked)"
    exit 0
}

cmd_remove() {
    local name="" purge=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --purge) purge=true; shift ;;
            *) name="$1"; shift ;;
        esac
    done

    [[ -z "$name" ]] && _usage "sources.sh remove <name> [--purge]"

    _init_config
    _registry_has "$name" || _die "'$name' not found in config"

    local store link
    store=$(_expand_store "$(jq -r --arg n "$name" '.sources[] | select(.name == $n) | .store' "$CONFIG")")
    link=$(_link_path "$name")

    if [[ -L "$link" ]]; then
        rm "$link"
        _ok "unlinked: $link"
    else
        _warn "symlink $link not found"
    fi

    if [[ "$purge" == "true" ]]; then
        if [[ -d "$store" ]]; then
            rm -rf "$store"
            _ok "purged: $store"
        else
            _warn "store $store not found on disk"
        fi
    else
        _info "store preserved at $store (use --purge to delete it)"
    fi

    local tmp
    tmp=$(mktemp)
    jq --indent 4 --arg n "$name" '.sources = [.sources[] | select(.name != $n)]' \
       "$CONFIG" > "$tmp" && mv "$tmp" "$CONFIG"
    _done "unregistered: $name"
}

# ── dispatch ──────────────────────────────────────────────────────────────────

_require_jq
_require_workspace

case "${1:-}" in
    list)    cmd_list ;;
    link)    shift; cmd_link "$@" ;;
    sync)    shift; cmd_sync "${1:-}" ;;
    restore) shift; cmd_restore "${1:-}" ;;
    remove)  shift; cmd_remove "$@" ;;
    *)
        echo "usage: sources.sh <command> [args]"
        echo ""
        echo "commands:"
        echo "  list                                      list registered sources"
        echo "  link <url> [name] [--branch B] [--full]   clone and register a source"
        echo "  sync [name]                               update one or all sources"
        echo "  restore [name]                            re-clone missing stores and re-create missing symlinks"
        echo "  remove <name> [--purge]                   remove symlink (--purge also deletes store)"
        exit 1
        ;;
esac
