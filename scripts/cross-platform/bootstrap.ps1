#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Cross-platform bootstrap for civic-infrastructure (Windows / Linux / macOS / container).

.PARAMETER Profile
    host | docker | kubernetes | check

.PARAMETER LightMode
    Prefer smaller models / lower resource footprint.

.PARAMETER SkipDeps
    Skip dependency installation (pwsh modules, etc.).
#>
[CmdletBinding()]
param(
    [ValidateSet('host', 'docker', 'kubernetes', 'check')]
    [string]$Profile = 'host',

    [switch]$LightMode,
    [switch]$SkipDeps,
    [switch]$InstallService
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = if ($PSScriptRoot) {
    # scripts/cross-platform -> repo root
    if ((Split-Path -Leaf $PSScriptRoot) -eq 'cross-platform') {
        (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
    }
    else {
        (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    }
}
else {
    (Get-Location).Path
}

# Allow running from repo root: ./bootstrap.ps1
if (-not (Test-Path (Join-Path $RepoRoot 'configs/platform/capabilities.json'))) {
    $RepoRoot = (Get-Location).Path
}

Import-Module (Join-Path $RepoRoot 'platform/Platform.psm1') -Force
Write-CivicPlatformBanner

$info = Get-CivicPlatformInfo
$caps = Get-CivicCapabilities

function Install-CivicHostDeps {
    Write-Host "[bootstrap] Ensuring PowerShell modules..." -ForegroundColor Yellow
    $mods = @('powershell-yaml', 'Pester')
    foreach ($m in $mods) {
        $have = Get-Module -ListAvailable -Name $m | Select-Object -First 1
        if (-not $have) {
            try {
                Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue
                Install-Module -Name $m -Scope CurrentUser -Force -SkipPublisherCheck -AllowClobber
                Write-Host "  installed $m" -ForegroundColor Green
            }
            catch {
                Write-Warning "Could not install $m : $_"
            }
        }
        else {
            Write-Host "  $m already present ($($have.Version))" -ForegroundColor DarkGray
        }
    }

    # Portable data dirs
    foreach ($d in @('logs', 'state', 'evidence', 'bus', 'config')) {
        $null = Get-CivicDataPath -Name $d
    }

    # Env shims for Linux/macOS when scripts expect Windows vars
    if (-not $IsWindows) {
        $env:TEMP = if ($env:TMPDIR) { $env:TMPDIR } else { '/tmp' }
        $env:TMP = $env:TEMP
        $env:USERPROFILE = $HOME
    }
}

function Invoke-CivicCheck {
    Write-Host "`n[check] Platform capability gate" -ForegroundColor Cyan
    $features = $caps.Features.PSObject.Properties
    foreach ($f in $features) {
        $mark = if ($f.Value) { 'OK ' } else { '-- ' }
        Write-Host ("  {0}{1}" -f $mark, $f.Name)
    }
    Write-Host "`n[check] Tooling" -ForegroundColor Cyan
    foreach ($tool in @('pwsh', 'docker', 'kubectl', 'helm', 'ollama', 'python3', 'git')) {
        $cmd = Get-Command $tool -ErrorAction SilentlyContinue
        if ($cmd) {
            Write-Host "  OK  $tool -> $($cmd.Source)" -ForegroundColor Green
        }
        else {
            Write-Host "  --  $tool (optional / not found)" -ForegroundColor DarkYellow
        }
    }
    Write-Host "`n[check] done." -ForegroundColor Cyan
}

function Invoke-CivicDocker {
    Test-CivicFeature -Name 'docker_stack' -ThrowIfMissing | Out-Null
    $compose = Join-Path $RepoRoot 'docker/docker-compose.yml'
    if (-not (Test-Path $compose)) { throw "Missing $compose" }
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw "Docker CLI not found. Install Docker Desktop / Engine first."
    }
    $profileName = if ($LightMode) { 'light' } else { 'full' }
    if ($profileName -eq 'full') {
        $envFile = Join-Path $RepoRoot 'docker/.env'
        $example = Join-Path $RepoRoot 'docker/.env.example'
        if (-not (Test-Path $envFile) -and (Test-Path $example)) {
            Copy-Item $example $envFile
            Write-Warning "Created docker/.env from .env.example — change N8N_BASIC_AUTH_PASSWORD before production use."
        }
        $env:CIVIC_LIGHT_MODE = '0'
    }
    else {
        $env:CIVIC_LIGHT_MODE = '1'
    }
    $args = @('compose', '-f', $compose, '--profile', $profileName, 'up', '-d', '--build')
    Write-Host "[bootstrap] docker $($args -join ' ')" -ForegroundColor Yellow
    Push-Location (Join-Path $RepoRoot 'docker')
    try {
        & docker @args
    }
    finally {
        Pop-Location
    }
}

function Invoke-CivicKubernetes {
    Test-CivicFeature -Name 'kubernetes_deploy' -ThrowIfMissing | Out-Null
    if (-not (Get-Command helm -ErrorAction SilentlyContinue)) {
        throw "helm not found. Install Helm 3+."
    }
    if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
        throw "kubectl not found."
    }
    $chart = Join-Path $RepoRoot 'deploy/kubernetes/helm/civic-infrastructure'
    $ns = if ($env:CIVIC_NAMESPACE) { $env:CIVIC_NAMESPACE } else { 'civic' }
    Write-Host "[bootstrap] Ensuring namespace $ns..." -ForegroundColor Yellow
    kubectl get ns $ns 2>$null
    if ($LASTEXITCODE -ne 0) {
        kubectl create namespace $ns
    }
    $setArgs = @()
    if ($LightMode) {
        $setArgs += '--set'
        $setArgs += 'orchestrator.lightMode=true'
        $setArgs += '--set'
        $setArgs += 'ollama.enabled=false'
    }
    Write-Host "[bootstrap] helm upgrade --install civic $chart -n $ns" -ForegroundColor Yellow
    & helm upgrade --install civic $chart -n $ns --wait --timeout 10m @setArgs
}

function Invoke-CivicHost {
    if (-not $SkipDeps) {
        Install-CivicHostDeps
    }

    $portable = Join-Path $RepoRoot 'scripts/cross-platform/Start-CivicOrchestrator.ps1'
    if (Test-Path $portable) {
        Write-Host "[bootstrap] Starting portable orchestrator (host profile)..." -ForegroundColor Yellow
        & $portable -RepoRoot $RepoRoot -LightMode:$LightMode
    }
    else {
        Write-Warning "Portable orchestrator missing at $portable"
    }

    if ($InstallService) {
        $svc = Join-Path $RepoRoot 'scripts/cross-platform/Install-CivicService.ps1'
        if (Test-Path $svc) {
            & $svc -RepoRoot $RepoRoot
        }
    }

    Write-Host @"

[bootstrap] Host profile ready on $($info.OsFamily)/$($info.Architecture).

Next:
  pwsh ./civic.ps1 check
  pwsh ./civic.ps1 docker     # Compose stack
  pwsh ./civic.ps1 kubernetes  # Helm deploy

Windows-only ceremonies (registry/ISO) remain gated and will no-op on this OS.
"@ -ForegroundColor Green
}

switch ($Profile) {
    'check' { Invoke-CivicCheck }
    'docker' { Invoke-CivicDocker }
    'kubernetes' { Invoke-CivicKubernetes }
    'host' { Invoke-CivicHost }
}
