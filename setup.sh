#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$REPO_ROOT/.agents/scripts/_shared.sh"

_vscode_user_settings() {
    # Linux
    [[ -f "$HOME/.config/Code/User/settings.json" ]] && { echo "$HOME/.config/Code/User/settings.json"; return; }
    # macOS
    [[ -f "$HOME/Library/Application Support/Code/User/settings.json" ]] && { echo "$HOME/Library/Application Support/Code/User/settings.json"; return; }
    echo ""
}

_wire_vscode_plugin() {
    local plugin_path="$1"

    if ! command -v jq &>/dev/null; then
        _warn "jq not found — add manually to your VSCode user settings:"
        echo "      \"chat.pluginLocations\": { \"$plugin_path\": true }"
        skipped=$((skipped + 1))
        return
    fi

    local settings
    settings=$(_vscode_user_settings)

    if [[ -z "$settings" ]]; then
        _warn "VSCode user settings not found — add manually to your user settings:"
        echo "      \"chat.pluginLocations\": { \"$plugin_path\": true }"
        skipped=$((skipped + 1))
        return
    fi

    if jq -e --arg p "$plugin_path" '.["chat.pluginLocations"][$p]' "$settings" &>/dev/null; then
        _warn "VSCode chat.pluginLocations ($plugin_path) already set — skipped"
        skipped=$((skipped + 1))
        return
    fi

    local tmp
    tmp=$(mktemp)
    if jq --indent 4 --arg p "$plugin_path" '.["chat.pluginLocations"][$p] = true' "$settings" > "$tmp"; then
        mv "$tmp" "$settings"
        _ok "VSCode user settings: chat.pluginLocations → $plugin_path"
        created=$((created + 1))
    else
        rm -f "$tmp"
        _warn "VSCode user settings is JSONC — add manually:"
        echo "      \"chat.pluginLocations\": { \"$plugin_path\": true }"
        skipped=$((skipped + 1))
    fi
}

cmd_init() {
    cd "$REPO_ROOT"

    if [[ ! -f AGENTS.md || ! -d .agents/skills ]]; then
        _die "run this script from the r3 workspace root (AGENTS.md not found)"
    fi

    local created=0 skipped=0

    # Symlink targets must exist or the links dangle (git does not track empty dirs)
    mkdir -p .agents/agents .agents/workflows

    _create_symlink CLAUDE.md         AGENTS.md
    _create_symlink .claude/skills    ../.agents/skills
    _create_symlink .claude/rules     ../.agents/rules
    _create_symlink .claude/agents    ../.agents/agents
    _create_symlink .warp/workflows   ../.agents/workflows

    _wire_vscode_plugin "$REPO_ROOT/.agents"

    echo ""
    _done "$created created, $skipped skipped"
}

case "${1:-}" in
    init) cmd_init ;;
    *)
        echo "usage: setup.sh <command>"
        echo ""
        echo "commands:"
        echo "  init   create symlinks and wire integrations (CLAUDE.md, .claude/*, .warp/*, user settings)"
        exit 1
        ;;
esac
