#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Portable civic orchestrator — runs on host, Docker, or Kubernetes.
    Windows-only ceremonies are skipped via capability gates.
#>
[CmdletBinding()]
param(
    [string]$RepoRoot = '',
    [switch]$LightMode,
    [switch]$Once
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $RepoRoot) {
    $RepoRoot = if ($env:CIVIC_REPO_ROOT) { $env:CIVIC_REPO_ROOT } else {
        (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
    }
}

Import-Module (Join-Path $RepoRoot 'platform/Platform.psm1') -Force
Write-CivicPlatformBanner

$info = Get-CivicPlatformInfo
$caps = Get-CivicCapabilities
$logs = Get-CivicDataPath -Name 'logs'
$state = Get-CivicDataPath -Name 'state'
$bus = Get-CivicDataPath -Name 'bus'

$stateFile = Join-Path $state 'orchestrator-state.json'
$logFile = Join-Path $logs ("orchestrator-{0:yyyyMMdd}.log" -f (Get-Date))

function Write-OrchestratorLog {
    param([string]$Message, [string]$Level = 'INFO')
    $line = "{0:o} [{1}] {2}" -f (Get-Date).ToUniversalTime(), $Level, $Message
    Add-Content -LiteralPath $logFile -Value $line
    Write-Host $line
}

function Get-OllamaHealth {
    $url = if ($env:OLLAMA_HOST) { $env:OLLAMA_HOST.TrimEnd('/') } else { 'http://127.0.0.1:11434' }
    try {
        $r = Invoke-WebRequest -Uri "$url/api/tags" -Method GET -TimeoutSec 3 -UseBasicParsing
        return ($r.StatusCode -ge 200 -and $r.StatusCode -lt 300)
    }
    catch {
        return $false
    }
}

function Invoke-OrchestratorTick {
    $ollamaOk = Get-OllamaHealth
    $payload = [ordered]@{
        timestamp    = (Get-Date).ToUniversalTime().ToString('o')
        platform     = $caps.Key
        runtime      = $info.Runtime
        architecture = $info.Architecture
        light_mode   = [bool]$LightMode -or $env:CIVIC_LIGHT_MODE -eq '1'
        ollama       = $ollamaOk
        features     = @{}
        pid          = $PID
        hostname     = [System.Net.Dns]::GetHostName()
    }
    foreach ($p in $caps.Features.PSObject.Properties) {
        $payload.features[$p.Name] = [bool]$p.Value
    }

    $payload | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $stateFile -Encoding utf8

    $busDir = Join-Path $bus 'lineage/events'
    if (-not (Test-Path $busDir)) { New-Item -ItemType Directory -Path $busDir -Force | Out-Null }
    $evt = [ordered]@{
        event_id   = "evt-orch-$(Get-Date -Format 'yyyyMMddHHmmss')-$PID"
        event_type = 'orchestrator_heartbeat'
        timestamp  = $payload.timestamp
        agent_role = 'civic-portable-orchestrator'
        payload    = @{
            platform = $payload.platform
            runtime  = $payload.runtime
            ollama   = $ollamaOk
        }
    }
    $evtPath = Join-Path $busDir ("{0:yyyyMMdd}.jsonl" -f (Get-Date).ToUniversalTime())
    ($evt | ConvertTo-Json -Compress -Depth 6) | Add-Content -LiteralPath $evtPath

    Write-OrchestratorLog "heartbeat platform=$($payload.platform) ollama=$ollamaOk"
}

Write-OrchestratorLog "starting portable orchestrator (Once=$Once LightMode=$LightMode)"
Invoke-OrchestratorTick

if ($Once) {
    Write-OrchestratorLog "single tick complete; exiting"
    exit 0
}

$interval = if ($env:CIVIC_HEARTBEAT_SECONDS) { [int]$env:CIVIC_HEARTBEAT_SECONDS } else { 60 }
Write-OrchestratorLog "loop interval=${interval}s"
while ($true) {
    Start-Sleep -Seconds $interval
    try {
        Invoke-OrchestratorTick
    }
    catch {
        Write-OrchestratorLog "tick failed: $_" 'ERROR'
    }
}
