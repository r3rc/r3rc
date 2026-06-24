# Shared helpers for r3 PowerShell scripts. Import as a module:
#
#   using module "$PSScriptRoot/_shared.psm1"
#
# `using module` (parse-time, top of file) brings BOTH the exported functions and the
# types (Result, SymlinkOutcome) into the caller.
#
# Cross-platform PowerShell (pwsh). Command execution uses the native `git` call.
# Shared by every r3 script (setup.ps1, sources.ps1, projects.ps1, sdd.ps1).
#
# Return discipline (these are building blocks consumed by other functions — keep emits
# exact): pipe side-effecting cmdlets to `| Out-Null`, capture other output into variables,
# and emit messages via Write-Host / [Console]::Error (off the success/output stream).

# ── types ─────────────────────────────────────────────────────────────────────

# Outcome of New-Symlink on success.
enum SymlinkOutcome {
    Created
    Skipped
}

# Explicit success/failure result. Functions that can fail return this instead of
# throwing, so callers branch on `.Ok` rather than try/catch.
class Result {
    [bool]   $Ok
    [object] $Value      # payload on success
    [string] $Error      # message on failure

    static [Result] Ok([object]$value) {
        return [Result]@{ Ok = $true; Value = $value; Error = $null }
    }

    static [Result] Fail([string]$message) {
        return [Result]@{ Ok = $false; Value = $null; Error = $message }
    }
}

# ── colors ────────────────────────────────────────────────────────────────────
# Trimmed to the ANSI codes r3 uses. Color only when stdout is a TTY and NO_COLOR is unset.

$script:Esc = [char]27
$script:ColorEnabled = (-not $env:NO_COLOR) -and (-not [Console]::IsOutputRedirected)

# private — not exported
function Format-Ansi {
    param([string]$Text, [string]$Open, [string]$Close)
    if (-not $script:ColorEnabled) { return $Text }
    return "$($script:Esc)[${Open}m$Text$($script:Esc)[${Close}m"
}

function Bold { param([string]$Text) Format-Ansi $Text '1' '22' }
function Red { param([string]$Text) Format-Ansi $Text '31' '39' }
function Green { param([string]$Text) Format-Ansi $Text '32' '39' }
function Yellow { param([string]$Text) Format-Ansi $Text '33' '39' }
function Cyan { param([string]$Text) Format-Ansi $Text '36' '39' }

# ── logging ───────────────────────────────────────────────────────────────────
# stdout (host stream) for info/ok/warn/success; stderr for error/die/usage.

function Write-Info { param([Parameter(Mandatory)][string]$Msg) Write-Host "$(Cyan '→') $Msg" }
function Write-Ok { param([Parameter(Mandatory)][string]$Msg) Write-Host "$(Green '✓') $Msg" }
function Write-Warn { param([Parameter(Mandatory)][string]$Msg) Write-Host "$(Yellow '!') $Msg" }
function Write-Err { param([Parameter(Mandatory)][string]$Msg) [Console]::Error.WriteLine("$(Red '✗ error:') $Msg") }
function Write-Success { param([Parameter(Mandatory)][string]$Msg) Write-Host "$(Green (Bold 'done:')) $Msg" }

function Die {
    param([Parameter(Mandatory)][string]$Msg)
    Write-Err $Msg
    exit 1
}

function Usage {
    param([Parameter(Mandatory)][string]$Msg)
    [Console]::Error.WriteLine("usage: $Msg")
    exit 1
}

# ── paths ─────────────────────────────────────────────────────────────────────
# Realpath of this module's dir (resolves symlinks, = `pwd -P`) so the workspace root is
# correct even when .agents/scripts is symlinked into a project.

$script:ResolvedScriptDir = $PSScriptRoot
$script:LinkTarget = (Get-Item -LiteralPath $PSScriptRoot -Force).ResolveLinkTarget($true)
if ($script:LinkTarget) { $script:ResolvedScriptDir = $script:LinkTarget.FullName }
$script:RepoRoot = [System.IO.Path]::GetFullPath((Join-Path $script:ResolvedScriptDir '..' '..'))

# Absolute path of the workspace root (two levels up from .agents/scripts).
function Get-RepoRoot {
    [OutputType([string])]
    param()
    return $script:RepoRoot
}

# Absolute path of the workspace `.agents/` directory (canonical home for agent artifacts).
function Get-AgentsDir {
    [OutputType([string])]
    param()
    return (Join-Path $script:RepoRoot '.agents')
}

# Absolute path of the global r3 data home (~/.r3) — shared store root across projects.
function Get-R3Home {
    [OutputType([string])]
    param()
    return (Join-Path $HOME '.r3')
}

# ── guards ──────────────────────────────────────────────────────────────────

# Abort unless the workspace root is present (AGENTS.md at the repo root).
function Assert-Workspace {
    if (-not (Test-Path -LiteralPath (Join-Path $script:RepoRoot 'AGENTS.md'))) {
        Die "workspace root not found — expected AGENTS.md at $($script:RepoRoot)"
    }
}

# ── context ───────────────────────────────────────────────────────────────────
# Per-context operations (sdd, sources linkage) target a *context*: the workspace itself or
# a project under it. Each context owns its own `.agents/` and `.covenant/`. Parse the
# context flags out of $Rest and return the resolved context plus the remaining args.
#
# Resolution — never a silent fallback to the workspace:
#   --workspace        → the workspace root
#   --project <name>   → <workspace>/<name> (must be a git project)
#   (neither)          → the project the current directory is inside; if the CWD is the
#                        workspace root (or outside it), the context is ambiguous → Die.
#
# Returns @{ Root; Agents (= Root/.agents); Covenant (= Root/.covenant); Name; IsWorkspace; Args }.
function Resolve-Context {
    [OutputType([hashtable])]
    param([string[]]$Rest = @())

    $name = $null
    $workspace = $false
    $remaining = [System.Collections.Generic.List[string]]::new()
    for ($i = 0; $i -lt $Rest.Count; $i++) {
        $a = $Rest[$i]
        if ($a -eq '--workspace') { $workspace = $true }
        elseif ($a -eq '--project') {
            if ($i + 1 -ge $Rest.Count) { Die "--project requires a <name>" }
            $name = $Rest[$i + 1]; $i++
        }
        else { $remaining.Add($a) }
    }
    if ($workspace -and $name) { Die "pass either --project <name> or --workspace, not both" }

    $repoRoot = [System.IO.Path]::GetFullPath((Get-RepoRoot))

    if ($workspace) {
        return @{ Root = $repoRoot; Agents = (Join-Path $repoRoot '.agents'); Covenant = (Join-Path $repoRoot '.covenant'); Name = '(workspace)'; IsWorkspace = $true; Args = $remaining.ToArray() }
    }

    if (-not $name) {
        # Detect the project from the current directory; never silently use the workspace.
        $cwd = [System.IO.Path]::GetFullPath($PWD.Path)
        $resolved = (Get-Item -LiteralPath $cwd -Force).ResolveLinkTarget($true)
        if ($resolved) { $cwd = $resolved.FullName }
        $prefix = $repoRoot.TrimEnd([char]'/', [char]'\') + [System.IO.Path]::DirectorySeparatorChar
        if ($cwd -eq $repoRoot) {
            Die "ambiguous context — run inside a project, or pass --project <name> (or --workspace)"
        }
        if (-not $cwd.StartsWith($prefix)) {
            Die "not inside the r3 workspace — pass --project <name> or --workspace"
        }
        $name = ($cwd.Substring($prefix.Length) -split '[\\/]')[0]
    }

    $root = Join-Path $repoRoot $name
    if (-not (Test-Path -LiteralPath (Join-Path $root '.git'))) {
        Die "'$name' is not a workspace project (no .git at $root)"
    }
    return @{ Root = $root; Agents = (Join-Path $root '.agents'); Covenant = (Join-Path $root '.covenant'); Name = $name; IsWorkspace = $false; Args = $remaining.ToArray() }
}

# ── helpers ─────────────────────────────────────────────────────────────────

# Derive a lowercase kebab-case name from a repo URL (basename, no `.git`).
function Get-NameFromUrl {
    [OutputType([string])]
    param([Parameter(Mandatory)][string]$Url)
    $base = ([System.IO.Path]::GetFileName($Url)) -replace '\.git$', ''
    return ($base.ToLower() -replace '[^a-z0-9-]', '-')
}

# Create a symlink, making the parent dir if needed. `Target` may be relative; the
# relative link is preserved. Returns Result: Ok(SymlinkOutcome.Created/Skipped) or Fail(msg).
# Skips (does not overwrite) when the link path already exists — including a broken symlink.
function New-Symlink {
    [OutputType([Result])]
    param(
        [Parameter(Mandatory)][string]$Link,
        [Parameter(Mandatory)][string]$Target,
        [string]$Display = $Link
    )
    $parent = Split-Path -Parent $Link
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $present = (Test-Path -LiteralPath $Link) -or `
    ($null -ne (Get-Item -LiteralPath $Link -Force -ErrorAction SilentlyContinue))
    if ($present) {
        Write-Warn "$Display already exists — skipped"
        return [Result]::Ok([SymlinkOutcome]::Skipped)
    }
    try {
        New-Item -ItemType SymbolicLink -Path $Link -Target $Target -ErrorAction Stop | Out-Null
    }
    catch {
        return [Result]::Fail("could not create symlink ${Display}: $($_.Exception.Message)")
    }
    Write-Ok "$Display → $Target"
    return [Result]::Ok([SymlinkOutcome]::Created)
}

# ── git ─────────────────────────────────────────────────────────────────────

# Run `git`. Always returns Result — never throws. On success, Value is the trimmed
# stdout; on a non-zero exit, Error holds the message. Caller decides: `if (-not $r.Ok) { Die $r.Error }`
# or tolerate (`$x = if ($r.Ok) { $r.Value } else { 'fallback' }`).
function Invoke-Git {
    [OutputType([Result])]
    param(
        [Parameter(Mandatory)][string[]]$GitArgs,
        [string]$Cwd
    )
    if ($Cwd) {
        if (-not (Test-Path -LiteralPath $Cwd)) {
            return [Result]::Fail("git: working directory not found: $Cwd")
        }
        Push-Location -LiteralPath $Cwd
    }
    try {
        $output = & git @GitArgs 2>&1
        $code = $LASTEXITCODE
    }
    finally {
        if ($Cwd) { Pop-Location }
    }
    $text = ($output | Out-String).Trim()
    if ($code -ne 0) {
        return [Result]::Fail("git $($GitArgs -join ' ') failed (exit ${code}): $text")
    }
    return [Result]::Ok($text)
}

# ── json ─────────────────────────────────────────────────────────────────────

# Canonical r3 JSON: 4-space indent. ConvertTo-Json has no indent option and emits 2, so
# double each line-leading space run — safe because JSON escapes newlines, so no string
# content ever begins a line. Empty arrays render as `[]` (fixed in pwsh 7.4+).
function ConvertTo-R3Json {
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][AllowNull()][object]$InputObject,
        [int]$Depth = 20
    )
    $json = $InputObject | ConvertTo-Json -Depth $Depth
    return [regex]::Replace($json, '(?m)^ +', { param($m) $m.Value * 2 })
}

# Serialize with ConvertTo-R3Json and write to $Path (Set-Content → UTF-8 no BOM + trailing newline).
function Write-JsonFile {
    param(
        [Parameter(Mandatory)][AllowNull()][object]$InputObject,
        [Parameter(Mandatory)][string]$Path,
        [int]$Depth = 20
    )
    Set-Content -LiteralPath $Path -Value (ConvertTo-R3Json -InputObject $InputObject -Depth $Depth)
}

# ── exports ───────────────────────────────────────────────────────────────────
# Public surface. Format-Ansi stays private. Types (Result, SymlinkOutcome) reach the
# caller via `using module`, independent of this list.

Export-ModuleMember -Function `
    Bold, Red, Green, Yellow, Cyan, `
    Write-Info, Write-Ok, Write-Warn, Write-Err, Write-Success, `
    Die, Usage, Assert-Workspace, Resolve-Context, Get-RepoRoot, Get-AgentsDir, Get-R3Home, Get-NameFromUrl, New-Symlink, Invoke-Git, `
    ConvertTo-R3Json, Write-JsonFile
