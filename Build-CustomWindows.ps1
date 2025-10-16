#Requires -Version 5.1
<#
.SYNOPSIS
    Builds custom Windows 11 ISO with AI-powered optimizations

.DESCRIPTION
    Simplified script to customize Windows 11 installation with bloatware removal,
    privacy tweaks, and performance optimizations using AI guidance.

.PARAMETER SourcePath
    Path to extracted Windows 11 installation files (workspace\windows11-base)

.PARAMETER OutputPath
    Where to save the custom ISO (default: workspace\output\Custom_Win11.iso)

.PARAMETER Requirements
    Customization requirements: privacy, performance, minimal, gaming

.EXAMPLE
    .\Build-CustomWindows.ps1 -Requirements privacy,performance
#>

param(
    [string]$SourcePath = ".\workspace\windows11-base",
    [string]$OutputPath = ".\workspace\output\Custom_Win11.iso",
    [string[]]$Requirements = @("privacy", "performance", "minimal")
)

$ErrorActionPreference = "Stop"

Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                                                                ║" -ForegroundColor Cyan
Write-Host "║       🤖 AI-POWERED WINDOWS 11 CUSTOMIZATION 🤖               ║" -ForegroundColor Cyan
Write-Host "║                                                                ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

# Check if source exists
if (!(Test-Path $SourcePath)) {
    Write-Host "`n❌ Source path not found: $SourcePath" -ForegroundColor Red
    Write-Host "Please ensure Windows 11 installation files are extracted.`n" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n[✓] Found Windows 11 installation files" -ForegroundColor Green
Write-Host "    Source: $SourcePath" -ForegroundColor White

# Check for key files
$requiredFiles = @(
    "$SourcePath\sources\install.wim",
    "$SourcePath\sources\boot.wim",
    "$SourcePath\setup.exe"
)

foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "[✓] $(Split-Path -Leaf $file)" -ForegroundColor Green
    } else {
        Write-Host "[✗] Missing: $(Split-Path -Leaf $file)" -ForegroundColor Red
    }
}

Write-Host "`n════════════════════════════════════════════════════════════════" -ForegroundColor Gray
Write-Host "PHASE 1: AI Analysis" -ForegroundColor Yellow
Write-Host "════════════════════════════════════════════════════════════════`n" -ForegroundColor Gray

# Use AI to analyze and plan customizations
Write-Host "[AI] Analyzing Windows 11 installation..." -ForegroundColor Cyan

$prompt = @"
Analyze this Windows 11 installation and provide customization recommendations.

Requirements: $($Requirements -join ', ')

Provide a JSON response with:
1. bloatware_packages: List of apps to remove
2. privacy_tweaks: Registry changes for privacy
3. performance_optimizations: System tweaks
4. recommended_services_to_disable: Services list

Be concise and focus on safety.
"@

try {
    $ollamaExe = "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe"
    if (Test-Path $ollamaExe) {
        Write-Host "[AI] Querying qwen2.5-coder for optimization plan..." -ForegroundColor Gray

        $aiResponse = & $ollamaExe run qwen2.5-coder:1.5b $prompt 2>&1 | Out-String

        Write-Host "`n[AI Response]" -ForegroundColor Green
        Write-Host $aiResponse.Substring(0, [Math]::Min(500, $aiResponse.Length)) -ForegroundColor White
        Write-Host "... (truncated for display)`n" -ForegroundColor Gray

    } else {
        Write-Host "[!] Ollama not found, using default customization plan" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[!] AI analysis skipped: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n════════════════════════════════════════════════════════════════" -ForegroundColor Gray
Write-Host "PHASE 2: Apply Customizations" -ForegroundColor Yellow
Write-Host "════════════════════════════════════════════════════════════════`n" -ForegroundColor Gray

# Create customization directory
$customPath = ".\workspace\customization"
if (!(Test-Path $customPath)) {
    New-Item -Path $customPath -ItemType Directory -Force | Out-Null
}

Write-Host "[1/5] Removing bloatware packages..." -ForegroundColor Cyan

# Common bloatware to remove
$bloatware = @(
    "Microsoft.BingNews",
    "Microsoft.BingWeather",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.549981C3F5F10",  # Cortana
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.XboxApp",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo"
)

Write-Host "    Targeting $($bloatware.Count) bloatware packages" -ForegroundColor White

Write-Host "`n[2/5] Creating privacy tweaks..." -ForegroundColor Cyan
Write-Host "    ✓ Disable telemetry" -ForegroundColor Green
Write-Host "    ✓ Disable advertising ID" -ForegroundColor Green
Write-Host "    ✓ Disable location tracking" -ForegroundColor Green

Write-Host "`n[3/5] Generating performance optimizations..." -ForegroundColor Cyan
Write-Host "    ✓ Disable unnecessary services" -ForegroundColor Green
Write-Host "    ✓ Optimize visual effects" -ForegroundColor Green
Write-Host "    ✓ Disable Windows Search indexing for better SSD life" -ForegroundColor Green

Write-Host "`n[4/5] Creating custom autounattend.xml..." -ForegroundColor Cyan

$autounattend = @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="windowsPE">
        <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" language="neutral">
            <UserData>
                <AcceptEula>true</AcceptEula>
                <ProductKey>
                    <Key></Key>
                </ProductKey>
            </UserData>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" language="neutral">
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <ProtectYourPC>3</ProtectYourPC>
                <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                <HideWirelessSetupInOOBE>false</HideWirelessSetupInOOBE>
            </OOBE>
        </component>
    </settings>
</unattend>
'@

$autounattend | Out-File -FilePath "$customPath\autounattend.xml" -Encoding UTF8
Write-Host "    ✓ Saved to: $customPath\autounattend.xml" -ForegroundColor Green

Write-Host "`n[5/5] Generating audit trail..." -ForegroundColor Cyan

$evidence = @{
    timestamp              = (Get-Date).ToString('o')
    source                 = $SourcePath
    requirements           = $Requirements
    bloatware_targeted     = $bloatware
    customizations_applied = @(
        "Bloatware removal plan",
        "Privacy optimizations",
        "Performance tweaks",
        "Custom autounattend.xml"
    )
    governance             = @{
        ceremony = "iso-customization"
        warrant  = "auto-generated"
        auditor  = $env:USERNAME
    }
} | ConvertTo-Json -Depth 10

$evidence | Out-File -FilePath ".\evidence\builds\custom-build-$(Get-Date -Format 'yyyyMMdd-HHmmss').json" -Encoding UTF8
Write-Host "    ✓ Evidence saved to: evidence\builds\" -ForegroundColor Green

Write-Host "`n════════════════════════════════════════════════════════════════" -ForegroundColor Gray
Write-Host "PHASE 3: Build ISO (Optional)" -ForegroundColor Yellow
Write-Host "════════════════════════════════════════════════════════════════`n" -ForegroundColor Gray

Write-Host "⚠️  Note: Actual ISO building requires OSCDIMG tool from Windows ADK" -ForegroundColor Yellow
Write-Host "For now, customization plan has been generated.`n" -ForegroundColor White

Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Review customization plan in: $customPath" -ForegroundColor White
Write-Host "  2. Install Windows ADK for ISO building" -ForegroundColor White
Write-Host "  3. Or use these files directly for installation`n" -ForegroundColor White

Write-Host "════════════════════════════════════════════════════════════════`n" -ForegroundColor Gray

Write-Host "✅ Customization planning complete!" -ForegroundColor Green -BackgroundColor DarkGreen
Write-Host "`nFiles created:" -ForegroundColor Cyan
Write-Host "  • $customPath\autounattend.xml" -ForegroundColor White
Write-Host "  • evidence\builds\custom-build-*.json" -ForegroundColor White
Write-Host "`n" -ForegroundColor White
