# Windows 11 Debloat Script
# Removes pre-installed apps and unnecessary components
# Designed for offline WIM customization via DISM

param(
    [string]$MountDir = "C:\ai-council\workspace\customization\mount"
)

$ErrorActionPreference = "Stop"

Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "Windows 11 Debloat Script" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "Mount Directory: $MountDir" -ForegroundColor Gray
Write-Host ""

if (-not (Test-Path $MountDir)) {
    Write-Host "ERROR: Mount directory not found: $MountDir" -ForegroundColor Red
    exit 1
}

$ComponentsRemoved = 0

# Bloatware packages to remove
$AppsToRemove = @(
    # === Social & Communication ===
    "Microsoft.BingNews",
    "Microsoft.BingWeather",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.Microsoft3DViewer",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.MicrosoftStickyNotes",
    "Microsoft.MixedReality.Portal",
    "Microsoft.Office.OneNote",
    "Microsoft.People",
    "Microsoft.SkypeApp",
    "Microsoft.Todos",
    "Microsoft.WindowsAlarms",
    "Microsoft.WindowsCommunicationsApps", # Mail and Calendar
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps",
    "Microsoft.WindowsSoundRecorder",
    "Microsoft.YourPhone",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo",
    
    # === Gaming ===
    "Microsoft.GamingApp",
    "Microsoft.Xbox.TCUI",
    "Microsoft.XboxApp",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay",
    
    # === Third-Party Bloatware ===
    "king.com.CandyCrushSaga",
    "king.com.CandyCrushSodaSaga",
    "king.com.FarmHeroesSaga",
    "king.com.BubbleWitch3Saga",
    "Disney.*",
    "Facebook.*",
    "Netflix.*",
    "Spotify.*",
    "TikTok.*",
    "Twitter.*",
    "LinkedIn.*",
    "Minecraft.*",
    "ActiproSoftware.*",
    "AdobePhotoshopExpress.*",
    "Duolingo.*",
    "EclipseManager.*",
    "Flipboard.*",
    "PandoraMedia.*",
    "Wunderlist.*",
    "Xing.*",
    
    # === Microsoft Bloat ===
    "Microsoft.549981C3F5F10", # Cortana
    "Microsoft.BingFinance",
    "Microsoft.BingSports",
    "Microsoft.Messaging",
    "Microsoft.OneConnect",
    "Microsoft.Print3D",
    "Microsoft.Wallet",
    "MicrosoftCorporationII.QuickAssist",
    "Microsoft.PowerAutomateDesktop"
)

Write-Host "Scanning for provisioned packages in WIM..." -ForegroundColor Yellow
Write-Host ""

foreach ($App in $AppsToRemove) {
    try {
        # Find matching packages (supports wildcards)
        $Packages = dism /Image:$MountDir /Get-ProvisionedAppxPackages | Select-String -Pattern "PackageName : $App"
        
        if ($Packages) {
            foreach ($Package in $Packages) {
                $PackageName = ($Package -split " : ")[1].Trim()
                
                Write-Host "[Removing] $PackageName" -ForegroundColor Yellow
                
                dism /Image:$MountDir /Remove-ProvisionedAppxPackage /PackageName:$PackageName 2>&1 | Out-Null
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "  ✓ Removed successfully" -ForegroundColor Green
                    $ComponentsRemoved++
                } else {
                    Write-Host "  ✗ Failed to remove (exit code: $LASTEXITCODE)" -ForegroundColor Red
                }
            }
        }
        
    } catch {
        Write-Host "  ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "Checking for optional features to disable..." -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

# Optional features to disable
$FeaturesToDisable = @(
    "Internet-Explorer-Optional-amd64",
    "MediaPlayback",
    "WindowsMediaPlayer",
    "WorkFolders-Client",
    "Printing-XPSServices-Features",
    "MicrosoftWindowsPowerShellV2Root"
)

foreach ($Feature in $FeaturesToDisable) {
    try {
        $FeatureInfo = dism /Image:$MountDir /Get-FeatureInfo /FeatureName:$Feature 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[Disabling] $Feature" -ForegroundColor Yellow
            
            dism /Image:$MountDir /Disable-Feature /FeatureName:$Feature /Remove 2>&1 | Out-Null
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  ✓ Disabled successfully" -ForegroundColor Green
                $ComponentsRemoved++
            } else {
                Write-Host "  ✗ Failed to disable (exit code: $LASTEXITCODE)" -ForegroundColor Red
            }
        } else {
            Write-Host "[Skipping] $Feature (not found)" -ForegroundColor Gray
        }
        
    } catch {
        Write-Host "  ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=======================================" -ForegroundColor Green
Write-Host "Debloat Complete" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green
Write-Host "Components Removed: $ComponentsRemoved" -ForegroundColor White
Write-Host ""

# Return count for integration with Apply-Customizations.ps1
return $ComponentsRemoved
