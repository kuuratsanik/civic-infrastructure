<#
.SYNOPSIS
    Cross-platform detection and path helpers for civic-infrastructure.

.DESCRIPTION
    Resolves OS family, container/k8s runtime, repo root, and capability gates
    so PowerShell Core scripts work on Windows, Linux, macOS, Docker, and Kubernetes.
#>

Set-StrictMode -Version Latest

function Get-CivicRepoRoot {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string]$StartPath = $PSScriptRoot
    )
    $dir = if ($StartPath) { Resolve-Path -LiteralPath $StartPath } else { Get-Location }
    $candidate = [System.IO.DirectoryInfo]::new($dir)
    while ($null -ne $candidate) {
        $marker = Join-Path $candidate.FullName 'configs/platform/capabilities.json'
        if (Test-Path -LiteralPath $marker) {
            return $candidate.FullName
        }
        $candidate = $candidate.Parent
    }
    # Fallback: module lives in <repo>/platform
    return (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
}

function Test-CivicInContainer {
    [CmdletBinding()]
    [OutputType([bool])]
    param()
    if ($env:CIVIC_RUNTIME -eq 'docker' -or $env:CIVIC_RUNTIME -eq 'kubernetes') {
        return $true
    }
    if ($env:KUBERNETES_SERVICE_HOST) {
        return $true
    }
    if (Test-Path -LiteralPath '/.dockerenv') {
        return $true
    }
    if ($IsLinux -and (Test-Path -LiteralPath '/proc/1/cgroup')) {
        $cgroup = Get-Content -LiteralPath '/proc/1/cgroup' -Raw -ErrorAction SilentlyContinue
        if ($cgroup -match 'docker|containerd|kubepods|podman') {
            return $true
        }
    }
    return $false
}

function Get-CivicPlatformInfo {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    $osFamily = if ($IsWindows) {
        'windows'
    }
    elseif ($IsMacOS) {
        'macos'
    }
    elseif ($IsLinux) {
        'linux'
    }
    else {
        'unknown'
    }

    $inContainer = Test-CivicInContainer
    $inK8s = [bool]$env:KUBERNETES_SERVICE_HOST -or $env:CIVIC_RUNTIME -eq 'kubernetes'
    $runtime = if ($env:CIVIC_RUNTIME) {
        $env:CIVIC_RUNTIME
    }
    elseif ($inK8s) {
        'kubernetes'
    }
    elseif ($inContainer) {
        'docker'
    }
    else {
        'host'
    }

    $arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToLowerInvariant()
    $repoRoot = Get-CivicRepoRoot

    # Windows-style env shims for scripts that assume TEMP / USERPROFILE
    if (-not $env:TEMP) { $env:TEMP = if ($env:TMPDIR) { $env:TMPDIR } else { [System.IO.Path]::GetTempPath() } }
    if (-not $env:TMP) { $env:TMP = $env:TEMP }
    if (-not $env:USERPROFILE) { $env:USERPROFILE = $HOME }

    return @{
        OsFamily     = $osFamily
        Runtime      = $runtime
        InContainer  = $inContainer
        InKubernetes = $inK8s
        Architecture = $arch
        RepoRoot     = $repoRoot
        Home         = $HOME
        Temp         = $env:TEMP
        PowerShell   = $PSVersionTable.PSVersion.ToString()
        HostOS       = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription
    }
}

function Get-CivicCapabilities {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [hashtable]$PlatformInfo = (Get-CivicPlatformInfo)
    )
    $path = Join-Path $PlatformInfo.RepoRoot 'configs/platform/capabilities.json'
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Capabilities file missing: $path"
    }
    $raw = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
    $key = if ($PlatformInfo.InKubernetes) {
        'kubernetes'
    }
    elseif ($PlatformInfo.InContainer) {
        'docker'
    }
    else {
        $PlatformInfo.OsFamily
    }
    $platform = $raw.platforms.$key
    if (-not $platform) {
        throw "No capabilities defined for platform key '$key'"
    }
    return @{
        Key      = $key
        Features = $platform.features
        Profiles = $raw.profiles
        Version  = $raw.version
    }
}

function Test-CivicFeature {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [switch]$ThrowIfMissing
    )
    $caps = Get-CivicCapabilities
    $enabled = [bool]$caps.Features.$Name
    if (-not $enabled -and $ThrowIfMissing) {
        throw "Feature '$Name' is not available on platform '$($caps.Key)'."
    }
    return $enabled
}

function Get-CivicDataPath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('logs', 'state', 'evidence', 'bus', 'config')]
        [string]$Name
    )
    $info = Get-CivicPlatformInfo
    $override = $env:CIVIC_DATA_ROOT
    $root = if ($override) { $override } else { Join-Path $info.RepoRoot 'var' }
    $map = @{
        logs     = 'logs'
        state    = 'state'
        evidence = 'evidence'
        bus      = 'bus'
        config   = 'config'
    }
    $path = Join-Path $root $map[$Name]
    if (-not (Test-Path -LiteralPath $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
    return $path
}

function Write-CivicPlatformBanner {
    [CmdletBinding()]
    param()
    $p = Get-CivicPlatformInfo
    $c = Get-CivicCapabilities
    Write-Host "civic-infrastructure  platform=$($c.Key)  runtime=$($p.Runtime)  arch=$($p.Architecture)  pwsh=$($p.PowerShell)" -ForegroundColor Cyan
    Write-Host "  root=$($p.RepoRoot)" -ForegroundColor DarkGray
    Write-Host "  host=$($p.HostOS)" -ForegroundColor DarkGray
}

Export-ModuleMember -Function @(
    'Get-CivicRepoRoot',
    'Test-CivicInContainer',
    'Get-CivicPlatformInfo',
    'Get-CivicCapabilities',
    'Test-CivicFeature',
    'Get-CivicDataPath',
    'Write-CivicPlatformBanner'
)
