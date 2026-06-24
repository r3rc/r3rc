#!/usr/bin/env bash
# r3 — POSIX shim for the workspace entrypoint. Runs r3.ps1 with pwsh so you can call
# `./r3 <command>` without typing `pwsh`. All arguments pass through unchanged.
exec pwsh "$(dirname "$0")/r3.ps1" "$@"
