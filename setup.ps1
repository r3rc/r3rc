#!/usr/bin/env pwsh
#Requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Position = 0)][string]$Command,
    [Parameter(ValueFromRemainingArguments = $true)][string[]]$Rest = @()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# setup.ps1 lives at the workspace root; the shared module is under .agents/scripts.
$RepoRoot = $PSScriptRoot
Import-Module "$RepoRoot/.agents/scripts/_shared.psm1" -Force

# ── private ───────────────────────────────────────────────────────────────────

# Locate the VSCode user settings.json (Linux first, then macOS). Empty string if absent.
function Get-VSCodeUserSettings {
    [OutputType([string])]
    param()
    $linux = Join-Path $HOME '.config/Code/User/settings.json'
    if (Test-Path -LiteralPath $linux) { return $linux }
    $mac = Join-Path $HOME 'Library/Application Support/Code/User/settings.json'
    if (Test-Path -LiteralPath $mac) { return $mac }
    return ''
}

# Wire chat.pluginLocations → $PluginPath in the user's VSCode settings.
# Returns 'created' or 'skipped'. Bails to manual instructions on JSONC (comments/trailing
# commas) since ConvertFrom-Json only accepts strict JSON — same fallback as the jq version.
function Set-VSCodePlugin {
    [OutputType([string])]
    param([string]$PluginPath)

    $manual = "      `"chat.pluginLocations`": { `"$PluginPath`": true }"
    $settings = Get-VSCodeUserSettings
    if (-not $settings) {
        Write-Warn "VSCode user settings not found — add manually to your user settings:"
        Write-Host $manual
        return 'skipped'
    }

    try {
        $json = Get-Content -Raw -LiteralPath $settings | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        Write-Warn "VSCode user settings is JSONC — add manually:"
        Write-Host $manual
        return 'skipped'
    }

    $key = 'chat.pluginLocations'
    $locations = if ($json.PSObject.Properties[$key]) { $json.$key } else { $null }

    if ($null -ne $locations -and $locations.PSObject.Properties[$PluginPath] -and [bool]$locations.$PluginPath) {
        Write-Warn "VSCode chat.pluginLocations ($PluginPath) already set — skipped"
        return 'skipped'
    }

    if ($null -eq $locations) {
        $locations = [pscustomobject]@{}
        $json | Add-Member -NotePropertyName $key -NotePropertyValue $locations
    }
    if ($locations.PSObject.Properties[$PluginPath]) {
        $locations.$PluginPath = $true
    }
    else {
        $locations | Add-Member -NotePropertyName $PluginPath -NotePropertyValue $true
    }

    ($json | ConvertTo-Json -Depth 20) | Set-Content -LiteralPath $settings
    Write-Ok "VSCode user settings: chat.pluginLocations → $PluginPath"
    return 'created'
}

# ── commands ──────────────────────────────────────────────────────────────────

function Invoke-InitCommand {
    if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot 'AGENTS.md')) -or
        -not (Test-Path -LiteralPath (Join-Path $RepoRoot '.agents/skills'))) {
        Die "run this script from the r3 workspace root (AGENTS.md not found)"
    }

    $created = 0
    $skipped = 0

    # Symlink targets must exist or the links dangle (git does not track empty dirs).
    New-Item -ItemType Directory -Path (Join-Path $RepoRoot '.agents/agents') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $RepoRoot '.agents/workflows') -Force | Out-Null

    # Tool-specific wiring: symlinks back into .agents/ (gitignored, never duplicated content).
    $symlinks = @(
        @{ Link = 'CLAUDE.md'; Target = 'AGENTS.md' }
        @{ Link = '.claude/skills'; Target = '../.agents/skills' }
        @{ Link = '.claude/rules'; Target = '../.agents/rules' }
        @{ Link = '.claude/agents'; Target = '../.agents/agents' }
        @{ Link = '.warp/workflows'; Target = '../.agents/workflows' }
    )
    foreach ($s in $symlinks) {
        $r = New-Symlink -Link (Join-Path $RepoRoot $s.Link) -Target $s.Target -Display $s.Link
        if (-not $r.Ok) { Die $r.Error }
        if ($r.Value.ToString() -eq 'Created') { $created++ } else { $skipped++ }
    }

    $status = Set-VSCodePlugin -PluginPath (Join-Path $RepoRoot '.agents')
    if ($status -eq 'created') { $created++ } else { $skipped++ }

    Write-Host ""
    Write-Success "$created created, $skipped skipped"
}

# ── dispatch ──────────────────────────────────────────────────────────────────

switch ($Command) {
    'init' { Invoke-InitCommand }
    default {
        [Console]::Error.WriteLine(@"
usage: setup.ps1 <command>

commands:
  init   create symlinks and wire integrations (CLAUDE.md, .claude/*, .warp/*, user settings)
"@)
        exit 1
    }
}
