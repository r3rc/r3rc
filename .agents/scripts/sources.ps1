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

# The source STORE is global (shared across contexts). The linkage (symlinks + registry) is
# PER-CONTEXT — $Config and $LinksDir are set in the dispatch block below from the resolved
# context. R3_REGISTRY overrides the registry path (testing).
$StoreBase = Join-Path (Get-R3Home) 'sources'

# ── private ───────────────────────────────────────────────────────────────────

function Initialize-Config {
    if (-not (Test-Path -LiteralPath $Config)) {
        $dir = Split-Path -Parent $Config
        if ($dir -and -not (Test-Path -LiteralPath $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        Write-JsonFile -InputObject ([ordered]@{ sources = @() }) -Path $Config
    }
}

function Read-Registry {
    Initialize-Config
    return (Get-Content -Raw -LiteralPath $Config | ConvertFrom-Json)
}

# Always return the sources as an array (empty if none).
function Get-Sources {
    param($Reg)
    if ($null -eq $Reg) { $Reg = Read-Registry }
    if (-not $Reg.PSObject.Properties['sources'] -or $null -eq $Reg.sources) { return @() }
    return @($Reg.sources)
}

function Write-Registry {
    param([object[]]$Sources)
    # Direct @(...) assignment, NOT via an if-expression — a script-block returning @()
    # collapses to $null (and a 1-elem array to a scalar) through the pipeline. pwsh 7.4+
    # then renders empty as `[]` and a single element as `[{...}]`.
    $items = @($Sources)
    Write-JsonFile -InputObject ([ordered]@{ sources = $items }) -Path $Config
}

function Test-Registered {
    param([string]$Name)
    return (@(Get-Sources | Where-Object { $_.name -eq $Name }).Count -gt 0)
}

function Get-StorePortable { param([string]$Name) "~/.r3/sources/$Name" }
function Get-StorePath { param([string]$Name) Join-Path $StoreBase $Name }
function Get-LinkPath { param([string]$Name) Join-Path $LinksDir $Name }
function Expand-Store { param([string]$Path) if ($Path.StartsWith('~/')) { Join-Path $HOME $Path.Substring(2) } else { $Path } }

# Update one store to its latest remote state. Returns $true on success.
function Sync-One {
    param([string]$Name, [string]$Url, [string]$Store, [bool]$Shallow)
    $s = Expand-Store $Store
    if (-not (Test-Path -LiteralPath $s)) {
        Write-Err "[$Name] store missing at $s — re-run: sources.ps1 link $Url $Name"
        return $false
    }
    if ($Shallow) {
        # Read-only reference mirror: reset --hard is correct and intentional here.
        $fetch = Invoke-Git -GitArgs @('fetch', '--depth=1', 'origin') -Cwd $s
        if ($fetch.Ok) {
            $reset = Invoke-Git -GitArgs @('reset', '--hard', 'origin/HEAD') -Cwd $s
            if ($reset.Ok) { Write-Ok "[$Name] updated (shallow)"; return $true }
        }
        Write-Err "[$Name] error during fetch/reset"
        return $false
    }
    $pull = Invoke-Git -GitArgs @('pull', '--ff-only') -Cwd $s
    if ($pull.Ok) { Write-Ok "[$Name] updated"; return $true }
    Write-Err "[$Name] conflict — manual intervention needed (diverged history)"
    return $false
}

# ── commands ──────────────────────────────────────────────────────────────────

function Invoke-ListCommand {
    $sources = @(Get-Sources)
    if ($sources.Count -eq 0) {
        Write-Info "no sources registered — run: sources.ps1 link <url> [name]"
        return
    }
    "{0,-20} {1,-30} {2,-15} {3,-8} {4}" -f "NAME", "LINK", "BRANCH", "SHALLOW", "STORE"
    "{0,-20} {1,-30} {2,-15} {3,-8} {4}" -f "----", "----", "------", "-------", "-----"
    foreach ($s in $sources) {
        $expanded = Expand-Store $s.store
        $g = Invoke-Git -GitArgs @('rev-parse', '--abbrev-ref', 'HEAD') -Cwd $expanded
        $branch = if ($g.Ok) { $g.Value } else { 'unknown' }
        "{0,-20} {1,-30} {2,-15} {3,-8} {4}" -f $s.name, ".agents/sources/$($s.name)", $branch, $s.shallow, $s.store
    }
}

function Invoke-LinkCommand {
    param([string[]]$Rest)
    $url = $null; $name = $null; $branch = $null; $shallow = $true; $depthArgs = @('--depth=1')
    $i = 0
    while ($i -lt $Rest.Count) {
        $a = $Rest[$i]
        if ($a -eq '--branch') { $branch = $Rest[$i + 1]; $i += 2 }
        elseif ($a -eq '--full') { $shallow = $false; $depthArgs = @(); $i += 1 }
        elseif ($a -like '--*') { Die "unknown option $a" }
        else {
            if (-not $url) { $url = $a } elseif (-not $name) { $name = $a }
            $i += 1
        }
    }
    if (-not $url) { Usage "sources.ps1 link <url> [name] [--branch <branch>] [--full]" }
    if (-not $name) { $name = Get-NameFromUrl $url }

    if (Test-Registered $name) { Die "'$name' already registered. Use 'sync' to update or 'remove' to replace it." }

    $store = Get-StorePath $name
    $link = Get-LinkPath $name
    New-Item -ItemType Directory -Path $StoreBase -Force | Out-Null
    New-Item -ItemType Directory -Path $LinksDir -Force | Out-Null

    if (Test-Path -LiteralPath $store) {
        Write-Warn "reusing existing store at $store"
    }
    else {
        $cloneArgs = @('clone') + $depthArgs
        if ($branch) { $cloneArgs += @('--branch', $branch) }
        $cloneArgs += @($url, $store)
        Write-Info "cloning $url → $store"
        $clone = Invoke-Git -GitArgs $cloneArgs
        if (-not $clone.Ok) { Die $clone.Error }
    }

    $sym = New-Symlink -Link $link -Target $store -Display $link
    if (-not $sym.Ok) { Die $sym.Error }

    $entry = [pscustomobject]@{
        name    = $name
        url     = $url
        store   = (Get-StorePortable $name)
        shallow = $shallow
        branch  = if ($branch) { $branch } else { '' }
    }
    Write-Registry (@(Get-Sources) + $entry)
    Write-Success "registered: $name | .agents/sources/$name → $(Get-StorePortable $name) | shallow=$shallow"
}

function Invoke-SyncCommand {
    param([string[]]$Rest)
    $targetName = if ($Rest.Count -ge 1) { $Rest[0] } else { $null }
    $sources = @(Get-Sources)
    if ($targetName) {
        $sources = @($sources | Where-Object { $_.name -eq $targetName })
        if ($sources.Count -eq 0) { Die "'$targetName' not found in config" }
    }
    if ($sources.Count -eq 0) { Write-Info "no sources to sync"; return }

    $errors = 0
    foreach ($s in $sources) {
        if (-not (Sync-One -Name $s.name -Url $s.url -Store $s.store -Shallow ([bool]$s.shallow))) { $errors++ }
    }
    if ($errors -gt 0) { exit 1 }
}

function Invoke-RestoreCommand {
    param([string[]]$Rest)
    $targetName = if ($Rest.Count -ge 1) { $Rest[0] } else { $null }
    $sources = @(Get-Sources)
    if ($targetName) {
        $sources = @($sources | Where-Object { $_.name -eq $targetName })
        if ($sources.Count -eq 0) { Die "'$targetName' not found in config" }
    }
    if ($sources.Count -eq 0) { Write-Info "no sources to restore"; return }

    New-Item -ItemType Directory -Path $StoreBase -Force | Out-Null
    New-Item -ItemType Directory -Path $LinksDir -Force | Out-Null

    $errors = 0
    foreach ($s in $sources) {
        $name = $s.name
        $url = $s.url
        $store = Expand-Store $s.store
        $shallow = [bool]$s.shallow
        $branch = if ($s.PSObject.Properties['branch']) { $s.branch } else { '' }
        $link = Get-LinkPath $name

        if (Test-Path -LiteralPath $store) {
            Write-Info "[$name] store present"
        }
        else {
            $cloneArgs = @('clone')
            if ($shallow) { $cloneArgs += '--depth=1' }
            if ($branch) { $cloneArgs += @('--branch', $branch) }
            $cloneArgs += @($url, $store)
            Write-Info "[$name] cloning $url → $store"
            $clone = Invoke-Git -GitArgs $cloneArgs
            if (-not $clone.Ok) { Write-Err "[$name] clone failed"; $errors++; continue }
        }

        $existing = Get-Item -LiteralPath $link -Force -ErrorAction SilentlyContinue
        if ($existing) {
            if ($existing.LinkType -eq 'SymbolicLink') { Write-Info "[$name] link present" }
            else { Write-Err "[$name] $link exists but is not a symlink — fix manually"; $errors++ }
        }
        else {
            New-Item -ItemType SymbolicLink -Path $link -Target $store | Out-Null
            Write-Ok "[$name] linked: .agents/sources/$name → $store"
        }
    }
    if ($errors -gt 0) { exit 1 }
    Write-Success "restore complete ($($sources.Count) sources checked)"
}

function Invoke-RemoveCommand {
    param([string[]]$Rest)
    $name = $null; $purge = $false
    foreach ($a in $Rest) {
        if ($a -eq '--purge') { $purge = $true } else { $name = $a }
    }
    if (-not $name) { Usage "sources.ps1 remove <name> [--purge]" }

    if (-not (Test-Registered $name)) { Die "'$name' not found in config" }

    $reg = Read-Registry
    $entry = Get-Sources $reg | Where-Object { $_.name -eq $name } | Select-Object -First 1
    $store = Expand-Store $entry.store
    $link = Get-LinkPath $name

    $existing = Get-Item -LiteralPath $link -Force -ErrorAction SilentlyContinue
    if ($existing -and $existing.LinkType -eq 'SymbolicLink') {
        Remove-Item -LiteralPath $link -Force
        Write-Ok "unlinked: $link"
    }
    else {
        Write-Warn "symlink $link not found"
    }

    if ($purge) {
        if (Test-Path -LiteralPath $store) {
            Remove-Item -LiteralPath $store -Recurse -Force
            Write-Ok "purged: $store"
        }
        else { Write-Warn "store $store not found on disk" }
    }
    else {
        Write-Info "store preserved at $store (use --purge to delete it)"
    }

    Write-Registry @(Get-Sources $reg | Where-Object { $_.name -ne $name })
    Write-Success "unregistered: $name"
}

# ── dispatch ──────────────────────────────────────────────────────────────────

Assert-Workspace

# Source linkage is per-context; the store is global. Resolve the context for the real commands.
$CmdArgs = $Rest
if ($Command -in @('list', 'link', 'sync', 'restore', 'remove')) {
    $ctx = Resolve-Context $Rest
    $CmdArgs = $ctx.Args
    $Config = if ($env:R3_REGISTRY) { $env:R3_REGISTRY } else { Join-Path $ctx.Agents 'registry.json' }
    $LinksDir = Join-Path $ctx.Agents 'sources'
}

switch ($Command) {
    'list' { Invoke-ListCommand }
    'link' { Invoke-LinkCommand    -Rest $CmdArgs }
    'sync' { Invoke-SyncCommand    -Rest $CmdArgs }
    'restore' { Invoke-RestoreCommand -Rest $CmdArgs }
    'remove' { Invoke-RemoveCommand  -Rest $CmdArgs }
    default {
        [Console]::Error.WriteLine(@"
usage: sources.ps1 <command> [args] [--project <name> | --workspace]

commands:
  list                                      list registered sources
  link <url> [name] [--branch B] [--full]   clone and register a source
  sync [name]                               update one or all sources
  restore [name]                            re-clone missing stores and re-create missing symlinks
  remove <name> [--purge]                   remove symlink (--purge also deletes store)
"@)
        exit 1
    }
}
