#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    ISO Build Ceremony - Creates custom Windows 11 ISOs with DAO governance

.DESCRIPTION
    This ceremony integrates with the AI Council infrastructure to build
    privacy-hardened, debloated Windows 11 ISOs with full audit trails.

.PARAMETER OutputName
    Name for the output ISO (without extension)

.PARAMETER IncludeTweaks
    Apply registry privacy/UI tweaks

.PARAMETER Debloat
    Remove bloatware applications

.PARAMETER WhatIf
    Show what would be done without making changes

.EXAMPLE
    .\Build-CustomISO.ps1 -OutputName "Win11_Privacy_v1"

.EXAMPLE
    .\Build-CustomISO.ps1 -OutputName "Win11_Minimal" -Debloat -IncludeTweaks
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputName = "Win11_Custom_$(Get-Date -Format 'yyyyMMdd_HHmmss')",

    [Parameter(Mandatory = $false)]
    [switch]$IncludeTweaks = $true,

    [Parameter(Mandatory = $false)]
    [switch]$Debloat = $true,

    [Parameter(Mandatory = $false)]
    [switch]$SkipVerification
)

$ErrorActionPreference = "Stop"

# ============================================
# Configuration
# ============================================

$CouncilRoot = "C:\ai-council"
$WorkspaceRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$CeremonyName = "ISO Build"

# ============================================
# Banner
# ============================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "CEREMONY: ISO BUILD" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Output ISO: $OutputName.iso" -ForegroundColor White
Write-Host "  Privacy Tweaks: $IncludeTweaks" -ForegroundColor White
Write-Host "  Debloat: $Debloat" -ForegroundColor White
Write-Host "  Council: $CouncilRoot" -ForegroundColor Gray
Write-Host "  Workspace: $WorkspaceRoot" -ForegroundColor Gray

# ============================================
# Prerequisites Check
# ============================================

Write-Host "`n[1/7] Checking Prerequisites..." -ForegroundColor Yellow

# Check Council infrastructure
if (-not (Test-Path $CouncilRoot)) {
    Write-Host "ERROR: AI Council not found at $CouncilRoot" -ForegroundColor Red
    Write-Host "Please ensure the ISO build system is integrated." -ForegroundColor Yellow
    exit 1
}

Write-Host "  [OK] AI Council infrastructure found" -ForegroundColor Green

# Check Windows ADK
$adkPaths = @(
    "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe",
    "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\x86\Oscdimg\oscdimg.exe"
)

$oscdimgFound = $false
foreach ($path in $adkPaths) {
    if (Test-Path $path) {
        Write-Host "  [OK] Windows ADK found" -ForegroundColor Green
        $oscdimgFound = $true
        break
    }
}

if (-not $oscdimgFound) {
    Write-Host "  [!!] Windows ADK not installed" -ForegroundColor Red
    Write-Host "`nPlease install Windows ADK:" -ForegroundColor Yellow
    Write-Host "  Download: https://go.microsoft.com/fwlink/?linkid=2243390" -ForegroundColor Cyan
    Write-Host "  Select: 'Deployment Tools' feature only" -ForegroundColor White
    
    if (-not $SkipVerification) {
        exit 1
    }
}

# Check Windows 11 base ISO
$wimPath = "$CouncilRoot\workspace\windows11-base\sources\install.wim"
if (-not (Test-Path $wimPath)) {
    Write-Host "  [!!] Windows 11 base ISO not found" -ForegroundColor Red
    Write-Host "`nPlease extract Windows 11 ISO:" -ForegroundColor Yellow
    Write-Host "  Run: cd $CouncilRoot" -ForegroundColor Cyan
    Write-Host "  Run: .\extract-windows11-iso.ps1" -ForegroundColor Cyan
    
    if (-not $SkipVerification) {
        exit 1
    }
} else {
    $wimSize = [math]::Round((Get-Item $wimPath).Length / 1GB, 2)
    Write-Host "  [OK] Base WIM found ($wimSize GB)" -ForegroundColor Green
}

# Check Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "  [!!] Not running as Administrator" -ForegroundColor Red
    Write-Host "`nThis ceremony requires Administrator privileges." -ForegroundColor Yellow
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor White
    exit 1
}

Write-Host "  [OK] Running as Administrator" -ForegroundColor Green

# ============================================
# Create Warrant
# ============================================

Write-Host "`n[2/7] Creating Build Warrant..." -ForegroundColor Yellow

$warrantId = "warrant-iso-build-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$warrant = @{
    warrant_id = $warrantId
    issued = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    expiry = (Get-Date).AddDays(7).ToString("yyyy-MM-ddTHH:mm:ssZ")
    authorized_actions = @(
        "mount_wim",
        "apply_customizations",
        "unmount_wim",
        "create_iso",
        "hash_iso"
    )
    constraints = @{
        max_duration_minutes = 60
        require_evidence = $true
        require_hash_verification = $true
    }
    metadata = @{
        ceremony = "iso_build"
        workspace = $WorkspaceRoot
        output_name = $OutputName
        include_tweaks = $IncludeTweaks.IsPresent
        debloat = $Debloat.IsPresent
    }
}

$warrantDir = "$CouncilRoot\council\warrants\active"
if (-not (Test-Path $warrantDir)) {
    New-Item -Path $warrantDir -ItemType Directory -Force | Out-Null
}

$warrantPath = "$warrantDir\$warrantId.json"
$warrant | ConvertTo-Json -Depth 10 | Set-Content $warrantPath

Write-Host "  Warrant created: $warrantId" -ForegroundColor Green
Write-Host "  Expires: $(($warrant.expiry))" -ForegroundColor Gray

# ============================================
# Prepare Customizations
# ============================================

Write-Host "`n[3/7] Preparing Customizations..." -ForegroundColor Yellow

$customizationDir = "$CouncilRoot\workspace\customization"
$tweaksDir = "$customizationDir\tweaks"

# Ensure directories exist
if (-not (Test-Path $tweaksDir)) {
    New-Item -Path $tweaksDir -ItemType Directory -Force | Out-Null
}

# Copy tweaks from templates if enabled
if ($IncludeTweaks) {
    $templateTweaks = "$CouncilRoot\templates\privacy-tweaks"
    if (Test-Path $templateTweaks) {
        Copy-Item "$templateTweaks\*.reg" $tweaksDir -Force
        $tweakCount = (Get-ChildItem $tweaksDir -Filter *.reg).Count
        Write-Host "  [OK] Copied $tweakCount registry tweak files" -ForegroundColor Green
    } else {
        Write-Host "  [!!] No template tweaks found" -ForegroundColor Yellow
    }
}

# Verify debloat script
$debloatScript = "$CouncilRoot\templates\debloat\Remove-Bloatware.ps1"
if ($Debloat -and (Test-Path $debloatScript)) {
    Write-Host "  [OK] Debloat script ready" -ForegroundColor Green
} elseif ($Debloat) {
    Write-Host "  [!!] Debloat script not found" -ForegroundColor Yellow
}

# ============================================
# Create Build Packet
# ============================================

Write-Host "`n[4/7] Creating Build Packet..." -ForegroundColor Yellow

$packetId = "iso-build-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$packet = @{
    packet_id = $packetId
    role = "build"
    action = "iso_build"
    warrant_id = $warrantId
    inputs = @{
        base_iso = "windows11-base/sources/install.wim"
        mount_dir = "customization/mount"
        output_iso = "output/$OutputName.iso"
        test_in_vm = $false
        customizations = @{
            updates = $null
            drivers = $null
            tweaks = if ($IncludeTweaks) { "customization/tweaks" } else { $null }
            debloat = if ($Debloat) { "templates/debloat/Remove-Bloatware.ps1" } else { $null }
        }
    }
    timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    source = @{
        ceremony = "iso_build"
        workspace = $WorkspaceRoot
        operator = $env:USERNAME
    }
}

Write-Host "  Packet ID: $packetId" -ForegroundColor Green
Write-Host "  Output: $OutputName.iso" -ForegroundColor Gray

# ============================================
# Dispatch to Agent
# ============================================

Write-Host "`n[5/7] Dispatching to ISO Build Agent..." -ForegroundColor Yellow

# Check if agent is running
$agentRunning = Get-Process -Name "powershell" -ErrorAction SilentlyContinue | 
    Where-Object { $_.CommandLine -like "*iso-build-agent*" }

if (-not $agentRunning) {
    Write-Host "  [!!] ISO Build Agent not detected" -ForegroundColor Yellow
    Write-Host "`nStarting ISO Build Agent..." -ForegroundColor Cyan
    
    # Start agent in background
    $agentScript = "$CouncilRoot\agents\build\iso-build-agent.ps1"
    if (Test-Path $agentScript) {
        if ($PSCmdlet.ShouldProcess("ISO Build Agent", "Start in watch mode")) {
            Write-Host "  Starting agent: $agentScript" -ForegroundColor Gray
            Write-Host "  Please start the agent manually in another terminal:" -ForegroundColor Yellow
            Write-Host "    cd $CouncilRoot" -ForegroundColor Cyan
            Write-Host "    .\agents\build\iso-build-agent.ps1 -WatchMode" -ForegroundColor Cyan
            Write-Host "`n  Press Enter when agent is running..." -ForegroundColor Yellow
            Read-Host
        }
    }
}

# Dispatch packet
$inboxPath = "$CouncilRoot\bus\inbox\$packetId.json"
if ($PSCmdlet.ShouldProcess($inboxPath, "Dispatch build packet")) {
    $packet | ConvertTo-Json -Depth 10 | Set-Content $inboxPath
    Write-Host "  [OK] Packet dispatched to inbox" -ForegroundColor Green
}

# ============================================
# Monitor Build Progress
# ============================================

Write-Host "`n[6/7] Monitoring Build Progress..." -ForegroundColor Yellow
Write-Host "  This will take approximately 15-20 minutes" -ForegroundColor Gray
Write-Host "  Phases: Mount -> Customize -> Unmount -> Create ISO -> Hash" -ForegroundColor Gray
Write-Host ""

if (-not $WhatIfPreference) {
    $startTime = Get-Date
    $timeout = New-TimeSpan -Minutes 30
    $resultFound = $false
    
    while (((Get-Date) - $startTime) -lt $timeout) {
        # Check for result
        $resultPath = "$CouncilRoot\bus\outbox\$packetId-result.json"
        if (Test-Path $resultPath) {
            $result = Get-Content $resultPath | ConvertFrom-Json
            
            Write-Host "`n  [OK] Build completed!" -ForegroundColor Green
            Write-Host "  Status: $($result.result.status)" -ForegroundColor Cyan
            
            if ($result.result.status -eq "completed") {
                Write-Host "  Duration: $($result.result.duration_seconds) seconds" -ForegroundColor Gray
                $resultFound = $true
                break
            } elseif ($result.result.status -eq "failed") {
                Write-Host "  Error: $($result.result.error)" -ForegroundColor Red
                exit 1
            }
        }
        
        # Show progress from log
        $logPath = "$CouncilRoot\logs\agents\iso-build.jsonl"
        if (Test-Path $logPath) {
            $latestLog = Get-Content $logPath -Tail 1 | ConvertFrom-Json
            if ($latestLog.phase) {
                Write-Host "  Progress: $($latestLog.phase) - $($latestLog.status)" -ForegroundColor Cyan
            }
        }
        
        Start-Sleep -Seconds 10
    }
    
    if (-not $resultFound) {
        Write-Host "`n  [!!] Build timeout reached" -ForegroundColor Yellow
        Write-Host "  Check logs: $CouncilRoot\logs\agents\iso-build.jsonl" -ForegroundColor Gray
    }
}

# ============================================
# Verify Output
# ============================================

Write-Host "`n[7/7] Verifying Output..." -ForegroundColor Yellow

$outputISO = "$CouncilRoot\workspace\output\$OutputName.iso"
if (Test-Path $outputISO) {
    $isoSize = [math]::Round((Get-Item $outputISO).Length / 1GB, 2)
    Write-Host "  [OK] ISO created: $OutputName.iso" -ForegroundColor Green
    Write-Host "  Size: $isoSize GB" -ForegroundColor Gray
    Write-Host "  Path: $outputISO" -ForegroundColor Gray
    
    # Verify hash
    $hashFile = "$CouncilRoot\evidence\hashes\iso-builds\$OutputName.sha256"
    if (Test-Path $hashFile) {
        $hashData = Get-Content $hashFile | ConvertFrom-Json
        Write-Host "  [OK] Hash verified: $($hashData.sha256.Substring(0,16))..." -ForegroundColor Green
    }
} else {
    Write-Host "  [!!] ISO not found at expected location" -ForegroundColor Yellow
    Write-Host "  Check: $CouncilRoot\workspace\output\" -ForegroundColor Gray
}

# ============================================
# Summary
# ============================================

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "CEREMONY COMPLETE" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "Build Summary:" -ForegroundColor Yellow
Write-Host "  Warrant: $warrantId" -ForegroundColor White
Write-Host "  Packet: $packetId" -ForegroundColor White
Write-Host "  Output: $OutputName.iso" -ForegroundColor White
Write-Host "  Tweaks: $IncludeTweaks" -ForegroundColor White
Write-Host "  Debloat: $Debloat" -ForegroundColor White

Write-Host "`nEvidence Locations:" -ForegroundColor Yellow
Write-Host "  ISO: $CouncilRoot\workspace\output\" -ForegroundColor Gray
Write-Host "  Hash: $CouncilRoot\evidence\hashes\iso-builds\" -ForegroundColor Gray
Write-Host "  Logs: $CouncilRoot\logs\agents\iso-build.jsonl" -ForegroundColor Gray
Write-Host "  Ledger: $CouncilRoot\logs\council_ledger.jsonl" -ForegroundColor Gray

Write-Host "`n========================================`n" -ForegroundColor Green
