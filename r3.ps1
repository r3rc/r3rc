#!/usr/bin/env pwsh
#Requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Position = 0)][string]$Command,
    [Parameter(ValueFromRemainingArguments = $true)][string[]]$Rest = @()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# r3 — the single workspace entrypoint. Thin dispatcher: every command delegates to a script
# under .agents/scripts/. Context flags (--project <name> / --workspace) pass straight through to
# the per-context scripts (sdd, sources), which resolve them via Resolve-Context.
$Scripts = Join-Path $PSScriptRoot '.agents/scripts'

$global:LASTEXITCODE = 0
switch ($Command) {
    'init' { & "$Scripts/setup.ps1" init @Rest }
    'project' { & "$Scripts/projects.ps1" @Rest }
    'sources' { & "$Scripts/sources.ps1" @Rest }
    'sdd' { & "$Scripts/sdd.ps1" @Rest }
    default {
        [Console]::Error.WriteLine(@"
usage: r3 <command> [args]

commands:
  init                                              set up the workspace (symlinks + tool integrations)
  project <add|wire|list|status|remove> [args]      manage workspace projects
  sources <link|sync|restore|remove|list> [args]    manage reference sources   [--project <name> | --workspace]
  sdd     <init|new|list> [args]                     spec-driven development     [--project <name> | --workspace]

per-context ops (sdd, sources) target a project — by --project <name>, or the project the current
directory is inside — or the workspace via --workspace. There is no silent default.
"@)
        exit 1
    }
}
exit $LASTEXITCODE
