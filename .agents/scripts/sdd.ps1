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

# Mechanical scaffold/list for the r3 SDD convention (engine-free). Operates on the
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
    New-Item -ItemType Directory -Path (Join-Path $SddRoot 'changes') -Force | Out-Null
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
    $changesDir = Join-Path $SddRoot 'changes'
    # Reject a duplicate slug regardless of its NNN prefix.
    foreach ($d in Get-ChildItem -LiteralPath $changesDir -Directory -ErrorAction SilentlyContinue) {
        if ($d.Name -match '^\d+-(.+)$' -and $Matches[1] -eq $slug) {
            Die "change '$slug' already exists at $($d.Name)"
        }
    }
    # Assign the next zero-padded NNN by scanning existing numbered folders.
    $max = Get-ChildItem -LiteralPath $changesDir -Directory -ErrorAction SilentlyContinue |
        ForEach-Object { if ($_.Name -match '^(\d+)-') { [int]$Matches[1] } } |
        Measure-Object -Maximum
    $nnn = '{0:D3}' -f ([int]$max.Maximum + 1)
    $dir = Join-Path $changesDir "$nnn-$slug"
    # Create the empty change folder only. Artifact files (proposal/spec/design/tasks)
    # are authored by the agent from the templates — they exist only once filled, so that
    # "artifact done = file exists" (the status rule in sdd-schema) holds.
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $id = [guid]::NewGuid().ToString('N').Substring(0, 8)   # stable opaque change id (durable cross-branch anchor)
    Write-Ok "scaffolded empty change: _contracts/changes/$nnn-$slug/"
    Write-Info "stable id: $id  — record it in proposal.md frontmatter (id: $id)"
    Write-Info "author artifacts from $TemplatesDir/ → proposal.md, spec.md, design.md, tasks.md"
    Write-Success "created change: $nnn-$slug"
}

function Invoke-ListCommand {
    $cdir = Join-Path $SddRoot 'changes'
    if (-not (Test-Path -LiteralPath $cdir -PathType Container)) {
        Die "no _contracts/changes at $cdir — run: sdd.ps1 init"
    }
    $found = $false
    foreach ($d in Get-ChildItem -LiteralPath $cdir -Directory | Sort-Object Name) {
        $d.Name
        $found = $true
    }
    if (-not $found) { Write-Info "no changes yet" }
}

# ── dispatch ──────────────────────────────────────────────────────────────────

switch ($Command) {
    'init' { Invoke-InitCommand }
    'new'  { Invoke-NewCommand -Rest $Rest }
    'list' { Invoke-ListCommand }
    default {
        Usage "sdd.ps1 <init | new <slug> | list>   (targets `$PWD/_contracts; override with SDD_ROOT)"
    }
}
