#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Unified civic CLI — Windows, Linux, macOS (PowerShell 7+).

.EXAMPLE
    ./civic.ps1 check
    ./civic.ps1 host
    ./civic.ps1 docker -LightMode
    ./civic.ps1 kubernetes
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('check', 'host', 'docker', 'kubernetes', 'help')]
    [string]$Command = 'help',

    [switch]$LightMode,
    [switch]$SkipDeps,
    [switch]$InstallService
)

$ErrorActionPreference = 'Stop'

# This file lives at the repository root.
$RepoRoot = $PSScriptRoot
if (-not (Test-Path (Join-Path $RepoRoot 'configs/platform/capabilities.json'))) {
    throw "civic.ps1 must be run from the civic-infrastructure repository root (missing configs/platform/capabilities.json)."
}

$boot = Join-Path $RepoRoot 'scripts/cross-platform/bootstrap.ps1'

if ($Command -eq 'help') {
    Write-Host @"
civic — cross-platform civic-infrastructure CLI

Usage:
  ./civic.ps1 check
  ./civic.ps1 host [-LightMode] [-InstallService]
  ./civic.ps1 docker [-LightMode]
  ./civic.ps1 kubernetes [-LightMode]

POSIX:
  ./civic check|host|docker|kubernetes [--light]

Compose / Helm:
  docker compose -f docker/docker-compose.yml --profile light up -d --build
  helm upgrade --install civic deploy/kubernetes/helm/civic-infrastructure -n civic
"@
    exit 0
}

& $boot -Profile $Command -LightMode:$LightMode -SkipDeps:$SkipDeps -InstallService:$InstallService
