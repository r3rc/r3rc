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

$RepoRoot = Get-RepoRoot
$Gitignore = Join-Path $RepoRoot '.gitignore'

# ── private ───────────────────────────────────────────────────────────────────

function Get-ProjectDir {
    [OutputType([string])]
    param([string]$Name)
    return (Join-Path $RepoRoot $Name)
}

# Exact whole-line match within a file (equivalent to `grep -qxF`).
function Test-LineInFile {
    [OutputType([bool])]
    param([string]$Path, [string]$Line)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    foreach ($l in Get-Content -LiteralPath $Path) {
        if ($l -eq $Line) { return $true }
    }
    return $false
}

# A directory is a workspace project if it has .git/ and is gitignored as /name/.
function Test-Project {
    [OutputType([bool])]
    param([string]$Name)
    $hasGit = Test-Path -LiteralPath (Join-Path $RepoRoot "$Name/.git")
    return ($hasGit -and (Test-LineInFile -Path $Gitignore -Line "/$Name/"))
}

# Delete a directory tree without ever following symlinks into their targets:
# remove every reparse point (link) as a link first, then remove the remaining real tree.
# Guards against Remove-Item -Recurse traversing into shared workspace dirs.
function Remove-Tree {
    param([string]$Path)
    # -Recurse does NOT descend into symlinks (no -FollowSymlink), so this enumerates
    # the link entries themselves; .Delete() removes the link, never its target.
    $links = Get-ChildItem -LiteralPath $Path -Recurse -Force -Attributes ReparsePoint -ErrorAction SilentlyContinue
    foreach ($link in $links) {
        $link.Delete()
    }
    Remove-Item -LiteralPath $Path -Recurse -Force
}

function Initialize-Project {
    param([string]$Target, [string]$Name)

    # Register in the workspace .gitignore
    if (Test-LineInFile -Path $Gitignore -Line "/$Name/") {
        Write-Warn "/$Name/ already in .gitignore"
    }
    else {
        Add-Content -LiteralPath $Gitignore -Value "/$Name/"
        Write-Ok "gitignored: /$Name/"
    }

    # Project's own .gitignore — exclude workspace wiring from the project's repo
    $projectGitignore = Join-Path $Target '.gitignore'
    $entries = @('CLAUDE.md', '.claude/', '.agents/scripts', '.agents/sources', '.warp/')
    $added = 0
    foreach ($entry in $entries) {
        if (-not (Test-LineInFile -Path $projectGitignore -Line $entry)) {
            Add-Content -LiteralPath $projectGitignore -Value $entry
            $added++
        }
    }
    if ($added -gt 0) {
        Write-Ok "updated: $Name/.gitignore (r3 wiring entries)"
    }
    else {
        Write-Warn "$Name/.gitignore r3 entries already present — skipped"
    }

    # CLAUDE.md — inherits workspace agent config
    $claudeMd = Join-Path $Target 'CLAUDE.md'
    if (Test-Path -LiteralPath $claudeMd) {
        Write-Warn "CLAUDE.md already exists in $Name — skipped"
    }
    else {
        Set-Content -LiteralPath $claudeMd -Value '@../AGENTS.md'
        Write-Ok "created: $Name/CLAUDE.md"
    }

    # Workspace wiring symlinks — relative targets are preserved so the project stays portable.
    $links = @(
        @{ Link = '.claude/skills'; Target = '../../.agents/skills' }
        @{ Link = '.claude/rules'; Target = '../../.agents/rules' }
        @{ Link = '.claude/agents'; Target = '../../.agents/agents' }
        @{ Link = '.agents/scripts'; Target = '../../.agents/scripts' }
        @{ Link = '.warp/workflows'; Target = '../../.agents/workflows' }
    )
    foreach ($l in $links) {
        $sym = New-Symlink -Link (Join-Path $Target $l.Link) -Target $l.Target -Display "$Name/$($l.Link)"
        if (-not $sym.Ok) { Die $sym.Error }
    }

    # .mcp.json — MCP server registration (empty scaffold, fill with project-specific servers)
    $mcp = Join-Path $Target '.mcp.json'
    if (Test-Path -LiteralPath $mcp) {
        Write-Warn ".mcp.json already exists in $Name — skipped"
    }
    else {
        Set-Content -LiteralPath $mcp -Value "{`n    `"mcpServers`": {}`n}"
        Write-Ok "created: $Name/.mcp.json"
    }

    # Durable project context (specs, design, decisions) is the SDD `.covenant/` tree — set up separately
    # and explicitly via `r3 sdd init --project <name>`.
}

# ── commands ──────────────────────────────────────────────────────────────────

function Invoke-ListCommand {
    "{0,-20} {1,-15} {2,-6} {3,-50} {4}" -f 'NAME', 'BRANCH', 'DIRTY', 'REMOTE', 'LAST COMMIT'
    "{0,-20} {1,-15} {2,-6} {3,-50} {4}" -f '----', '------', '-----', '------', '-----------'

    $found = $false
    foreach ($dir in Get-ChildItem -LiteralPath $RepoRoot -Directory) {
        $name = $dir.Name
        if (-not (Test-Project $name)) { continue }
        $found = $true

        $path = $dir.FullName
        $b = Invoke-Git -GitArgs @('rev-parse', '--abbrev-ref', 'HEAD') -Cwd $path
        $branch = if ($b.Ok) { $b.Value } else { 'unreadable' }
        $r = Invoke-Git -GitArgs @('remote', 'get-url', 'origin') -Cwd $path
        $remote = if ($r.Ok) { $r.Value } else { '(no remote)' }
        $c = Invoke-Git -GitArgs @('log', '-1', '--format=%h %s') -Cwd $path
        $last = if ($c.Ok) { $c.Value } else { '(no commits)' }
        $s = Invoke-Git -GitArgs @('status', '--short') -Cwd $path
        $dirty = 'no'
        if ($s.Ok -and $s.Value) {
            $count = @($s.Value -split "`n" | Where-Object { $_ -ne '' }).Count
            if ($count -gt 0) { $dirty = "yes ($count)" }
        }

        "{0,-20} {1,-15} {2,-6} {3,-50} {4}" -f $name, $branch, $dirty, $remote, $last
    }

    if (-not $found) {
        Write-Info "no projects in workspace — run: projects.ps1 add <url> [name]"
    }
}

function Invoke-AddCommand {
    param([string[]]$Rest)
    $url = $null; $name = $null
    foreach ($a in $Rest) {
        if ($a -like '--*') { Die "unknown option $a" }
        elseif (-not $url) { $url = $a }
        elseif (-not $name) { $name = $a }
    }
    if (-not $url) { Usage "projects.ps1 add <url> [name]" }
    if (-not $name) { $name = Get-NameFromUrl $url }

    $target = Get-ProjectDir $name
    if (Test-Path -LiteralPath $target) { Die "'$name' already exists in workspace root" }

    Write-Info "cloning $url → $target"
    $clone = Invoke-Git -GitArgs @('clone', $url, $target)
    if (-not $clone.Ok) { Die $clone.Error }

    Initialize-Project -Target $target -Name $name
    Write-Success "$name added to workspace"
}

function Invoke-WireCommand {
    param([string[]]$Rest)
    $name = if ($Rest.Count -ge 1) { $Rest[0] } else { $null }
    if (-not $name) { Usage "projects.ps1 wire <name>" }

    $dir = Get-ProjectDir $name
    if (-not (Test-Path -LiteralPath (Join-Path $dir '.git'))) {
        Die "'$name' is not a git repository in the workspace root"
    }

    Initialize-Project -Target $dir -Name $name
    Write-Success "$name wired"
}

function Invoke-StatusCommand {
    param([string[]]$Rest)
    $name = if ($Rest.Count -ge 1) { $Rest[0] } else { $null }
    if (-not $name) { Usage "projects.ps1 status <name>" }

    $dir = Get-ProjectDir $name
    if (-not (Test-Path -LiteralPath $dir)) { Die "'$name' not found in workspace root" }
    if (-not (Test-Project $name)) { Write-Warn "'$name' is not a registered workspace project" }

    $u = Invoke-Git -GitArgs @('status', '--short') -Cwd $dir
    if ($u.Ok -and $u.Value) {
        Write-Warn "uncommitted: yes"
        $u.Value -split "`n" | ForEach-Object { Write-Host "  $_" }
    }
    else {
        Write-Ok "uncommitted: no"
    }

    $p = Invoke-Git -GitArgs @('log', '@{u}..HEAD', '--oneline') -Cwd $dir
    if ($p.Ok -and $p.Value) {
        Write-Warn "unpushed: yes"
        $p.Value -split "`n" | ForEach-Object { Write-Host "  $_" }
    }
    else {
        Write-Ok "unpushed: no"
    }
}

function Invoke-RemoveCommand {
    param([string[]]$Rest)
    $name = $null; $force = $false
    foreach ($a in $Rest) {
        if ($a -eq '--force') { $force = $true } else { $name = $a }
    }
    if (-not $name) { Usage "projects.ps1 remove <name> [--force]" }

    $dir = Get-ProjectDir $name
    if (-not (Test-Path -LiteralPath $dir)) { Die "'$name' not found in workspace root" }

    $u = Invoke-Git -GitArgs @('status', '--short') -Cwd $dir
    if ($u.Ok -and $u.Value) {
        Write-Warn "uncommitted changes in ${name}:"
        $u.Value -split "`n" | ForEach-Object { Write-Host "  $_" }
        if (-not $force) {
            Die "refusing to delete with uncommitted changes. Re-run with --force to override."
        }
    }
    elseif (-not $force) {
        Die "refusing to delete without --force. Re-run with --force to confirm."
    }

    Remove-Tree $dir
    Write-Ok "deleted: $dir"

    if (Test-Path -LiteralPath $Gitignore) {
        $kept = @(Get-Content -LiteralPath $Gitignore | Where-Object { $_ -ne "/$name/" })
        Set-Content -LiteralPath $Gitignore -Value $kept
        Write-Ok "ungitignored: /$name/"
    }
}

# ── dispatch ──────────────────────────────────────────────────────────────────

Assert-Workspace

switch ($Command) {
    'list' { Invoke-ListCommand }
    'add' { Invoke-AddCommand    -Rest $Rest }
    'wire' { Invoke-WireCommand   -Rest $Rest }
    'status' { Invoke-StatusCommand -Rest $Rest }
    'remove' { Invoke-RemoveCommand -Rest $Rest }
    default {
        [Console]::Error.WriteLine(@"
usage: projects.ps1 <command> [args]

commands:
  list                     list all workspace projects
  add <url> [name]         clone and register a project
  wire <name>              wire an already-cloned project (symlinks, CLAUDE.md, .mcp.json)
  status <name>            show uncommitted and unpushed state
  remove <name> [--force]  delete project directory and unregister from .gitignore
"@)
        exit 1
    }
}
