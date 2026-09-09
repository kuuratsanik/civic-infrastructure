#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Install civic orchestrator as a native OS service (systemd / launchd / Windows Scheduled Task).
#>
[CmdletBinding()]
param(
    [string]$RepoRoot = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
}
Import-Module (Join-Path $RepoRoot 'platform/Platform.psm1') -Force
$info = Get-CivicPlatformInfo

$pwsh = (Get-Command pwsh).Source
$orch = Join-Path $RepoRoot 'scripts/cross-platform/Start-CivicOrchestrator.ps1'

switch ($info.OsFamily) {
    'linux' {
        $unitSrc = Join-Path $RepoRoot 'platform/services/systemd/civic-orchestrator.service'
        $unitDst = '/etc/systemd/system/civic-orchestrator.service'
        $content = (Get-Content -LiteralPath $unitSrc -Raw) `
            -replace '__REPO_ROOT__', $RepoRoot `
            -replace '__PWSH__', $pwsh `
            -replace '__USER__', $env:USER
        if (-not (Test-Path '/etc/systemd/system')) {
            throw "systemd not available on this host"
        }
        Write-Host "[service] Writing $unitDst (requires sudo)" -ForegroundColor Yellow
        $tmp = Join-Path $env:TEMP 'civic-orchestrator.service'
        Set-Content -LiteralPath $tmp -Value $content -Encoding utf8
        & sudo cp $tmp $unitDst
        & sudo systemctl daemon-reload
        & sudo systemctl enable --now civic-orchestrator.service
        Write-Host "[service] systemd unit enabled" -ForegroundColor Green
    }
    'macos' {
        $plistSrc = Join-Path $RepoRoot 'platform/services/launchd/com.civic.orchestrator.plist'
        $plistDst = Join-Path $HOME 'Library/LaunchAgents/com.civic.orchestrator.plist'
        $content = (Get-Content -LiteralPath $plistSrc -Raw) `
            -replace '__REPO_ROOT__', $RepoRoot `
            -replace '__PWSH__', $pwsh `
            -replace '__HOME__', $HOME
        $dir = Split-Path $plistDst -Parent
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        Set-Content -LiteralPath $plistDst -Value $content -Encoding utf8
        launchctl unload $plistDst 2>$null
        launchctl load $plistDst
        Write-Host "[service] launchd agent loaded: $plistDst" -ForegroundColor Green
    }
    'windows' {
        $taskName = 'CivicInfrastructureOrchestrator'
        $action = New-ScheduledTaskAction -Execute $pwsh -Argument "-NoProfile -File `"$orch`" -RepoRoot `"$RepoRoot`""
        $trigger = New-ScheduledTaskTrigger -AtStartup
        $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Force | Out-Null
        Write-Host "[service] Scheduled Task registered: $taskName" -ForegroundColor Green
    }
    default {
        throw "Unsupported OS family for service install: $($info.OsFamily)"
    }
}
