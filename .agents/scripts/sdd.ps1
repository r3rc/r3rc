#!/usr/bin/env pwsh
#Requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Position = 0)][string]$Command,
    [Parameter(ValueFromRemainingArguments = $true)][string[]]$Rest = @()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module "$PSScriptRoot/_shared.psm1" -Force

$TemplatesDir = Join-Path (Get-AgentsDir) 'skills/_shared'

# Mechanical scaffold/archive for the r3 SDD convention (engine-free). Operates on the
# _contracts/ tree in the current project (CWD). Override the target with SDD_ROOT.
$SddRoot = if ($env:SDD_ROOT) { $env:SDD_ROOT } else { Join-Path $PWD.Path '_contracts' }

# ── private ───────────────────────────────────────────────────────────────────

function Assert-Templates {
    if (-not (Test-Path -LiteralPath $TemplatesDir)) {
        Die "templates not found at $TemplatesDir"
    }
}

# Validate a change slug is kebab-case. -cnotmatch is case-sensitive (PS -match is not),
# so uppercase and underscores are rejected exactly like the bash `[[ =~ ]]`.
function Assert-Slug {
    param([string]$Slug)
    if ($Slug -cnotmatch '^[a-z0-9]+(-[a-z0-9]+)*$') {
        Die "invalid slug '$Slug' — use kebab-case (lowercase letters, digits, hyphens)"
    }
}

# ── commands ──────────────────────────────────────────────────────────────────

function Invoke-InitCommand {
    Assert-Templates
    New-Item -ItemType Directory -Path (Join-Path $SddRoot 'specs') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $SddRoot 'changes/archive') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $SddRoot 'explorations') -Force | Out-Null
    # Scaffold the durable project-level files from templates. Idempotent: skip if present;
    # skip (with a note) if the template is not yet available.
    foreach ($name in 'constitution.md', 'context-map.md') {
        $dest = Join-Path $SddRoot $name
        $tpl = Join-Path $TemplatesDir "sdd-$name"   # templates are namespaced sdd-*.md in _shared/
        if (Test-Path -LiteralPath $dest) {
            Write-Warn "$name already exists — skipped"
        }
        elseif (Test-Path -LiteralPath $tpl) {
            Copy-Item -LiteralPath $tpl -Destination $dest
            Write-Ok "created: _contracts/$name"
        }
        else {
            Write-Warn "template $name not found — skipped"
        }
    }
    Write-Success "initialized _contracts/ at $SddRoot"
}

function Invoke-NewCommand {
    param([string[]]$Rest)
    $slug = if ($Rest.Count -ge 1) { $Rest[0] } else { $null }
    if (-not $slug) { Usage "sdd.ps1 new <change-slug>" }
    Assert-Slug $slug
    Assert-Templates
    if (-not (Test-Path -LiteralPath (Join-Path $SddRoot 'changes') -PathType Container)) {
        Die "no _contracts/changes — run: sdd.ps1 init"
    }
    $dir = Join-Path $SddRoot "changes/$slug"
    if (Test-Path -LiteralPath $dir) { Die "change '$slug' already exists at $dir" }
    # Create the empty change folder only. Artifact files (proposal/design/tasks/specs)
    # are authored by the agent from the templates — they exist only once filled, so that
    # "artifact done = file exists" (the status rule in sdd-schema) holds.
    New-Item -ItemType Directory -Path (Join-Path $dir 'specs') -Force | Out-Null
    Write-Ok "scaffolded empty change: _contracts/changes/$slug/ (with specs/)"
    Write-Info "author artifacts from $TemplatesDir/ → proposal.md, specs/<capability>/spec.md, design.md, tasks.md"
    Write-Success "created change: $slug"
}

# Archive ONLY moves the change. The delta→main spec merge is done by the agent
# (r3-sdd-sync / r3-sdd-archive) BEFORE calling this — see sdd-spec-format.md.
function Invoke-ArchiveCommand {
    param([string[]]$Rest)
    $slug = if ($Rest.Count -ge 1) { $Rest[0] } else { $null }
    if (-not $slug) { Usage "sdd.ps1 archive <change-slug>" }
    $src = Join-Path $SddRoot "changes/$slug"
    if (-not (Test-Path -LiteralPath $src -PathType Container)) { Die "change '$slug' not found at $src" }
    $archiveRoot = Join-Path $SddRoot 'changes/archive'
    New-Item -ItemType Directory -Path $archiveRoot -Force | Out-Null
    $today = Get-Date -Format 'yyyy-MM-dd'
    $dest = Join-Path $archiveRoot "$today-$slug"
    if (Test-Path -LiteralPath $dest) { Die "archive target already exists: $dest" }
    Move-Item -LiteralPath $src -Destination $dest
    Write-Success "archived: $slug → changes/archive/$today-$slug"
}

function Invoke-ListCommand {
    $cdir = Join-Path $SddRoot 'changes'
    if (-not (Test-Path -LiteralPath $cdir -PathType Container)) {
        Die "no _contracts/changes at $cdir — run: sdd.ps1 init"
    }
    $found = $false
    foreach ($d in Get-ChildItem -LiteralPath $cdir -Directory) {
        if ($d.Name -eq 'archive') { continue }
        $d.Name
        $found = $true
    }
    if (-not $found) { Write-Info "no active changes" }
}

# ── dispatch ──────────────────────────────────────────────────────────────────

switch ($Command) {
    'init'    { Invoke-InitCommand }
    'new'     { Invoke-NewCommand     -Rest $Rest }
    'archive' { Invoke-ArchiveCommand -Rest $Rest }
    'list'    { Invoke-ListCommand }
    default {
        Usage "sdd.ps1 <init | new <slug> | archive <slug> | list>   (targets `$PWD/_contracts; override with SDD_ROOT)"
    }
}
