<#
.SYNOPSIS
    Downloads official Windows 11 ISO from Microsoft
.DESCRIPTION
    Automated script to download Windows 11 multi-edition ISO directly from Microsoft's servers
    Uses official download methods to get the latest Windows 11 ISO
.PARAMETER OutputPath
    Directory to save the downloaded ISO (defaults to Downloads folder)
#>

param(
    [string]$OutputPath = "$env:USERPROFILE\Downloads",
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Windows 11 ISO Download Automation" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Check if ISO already exists
$existingISO = Get-ChildItem -Path $OutputPath -Filter "Win11*.iso" -ErrorAction SilentlyContinue | Select-Object -First 1

if ($existingISO -and -not $Force) {
    Write-Host "[OK] Windows 11 ISO already exists:" -ForegroundColor Green
    Write-Host "     $($existingISO.FullName)" -ForegroundColor White
    Write-Host "     Size: $([math]::Round($existingISO.Length/1GB, 2)) GB" -ForegroundColor White
    Write-Host "`nUse -Force to download again`n" -ForegroundColor Yellow
    return $existingISO.FullName
}

Write-Host "[*] Preparing to download Windows 11 ISO..." -ForegroundColor Yellow
Write-Host "    This will download ~5-6 GB from Microsoft`n" -ForegroundColor White

# Use UUP dump or direct Microsoft link
# For automation, we'll provide instructions for manual download or use aria2c if available
$outputFile = Join-Path $OutputPath "Win11_23H2_English_x64.iso"

# Check if aria2c is available for fast download
$aria2c = Get-Command aria2c -ErrorAction SilentlyContinue

if (-not $aria2c) {
    Write-Host "[!!] Direct download requires manual step" -ForegroundColor Yellow
    Write-Host "`nOPTION 1 - Manual Download (Recommended):" -ForegroundColor Cyan
    Write-Host "  1. Visit: https://www.microsoft.com/software-download/windows11" -ForegroundColor White
    Write-Host "  2. Scroll to 'Download Windows 11 Disk Image (ISO)'" -ForegroundColor White
    Write-Host "  3. Select 'Windows 11 (multi-edition ISO)'" -ForegroundColor White
    Write-Host "  4. Click Download -> Choose language -> Download 64-bit" -ForegroundColor White
    Write-Host "  5. Save to: $OutputPath" -ForegroundColor White
    Write-Host "  6. Rename to: Win11_23H2_English_x64.iso`n" -ForegroundColor White
    
    Write-Host "OPTION 2 - Use existing ISO:" -ForegroundColor Cyan
    Write-Host "  If you have Windows 11 ISO already, copy it to:" -ForegroundColor White
    Write-Host "  $outputFile`n" -ForegroundColor White
    
    Write-Host "OPTION 3 - UUP Dump (Advanced):" -ForegroundColor Cyan
    Write-Host "  1. Visit: https://uupdump.net/" -ForegroundColor White
    Write-Host "  2. Select latest Windows 11 build" -ForegroundColor White
    Write-Host "  3. Download and run the script`n" -ForegroundColor White
    
    $choice = Read-Host "Have you downloaded the ISO? (y/N)"
    
    if ($choice -ne 'y') {
        Write-Host "`nPlease download Windows 11 ISO first, then run this script again.`n" -ForegroundColor Yellow
        exit 1
    }
    
    # Ask for ISO location
    $userISO = Read-Host "Enter full path to your Windows 11 ISO (or press Enter if in Downloads)"
    
    if ($userISO -and (Test-Path $userISO)) {
        $outputFile = $userISO
        Write-Host "[OK] Using: $outputFile" -ForegroundColor Green
        return $outputFile
    }
    
    # Check Downloads folder
    $foundISO = Get-ChildItem -Path $OutputPath -Filter "*.iso" | Where-Object { $_.Length -gt 3GB } | Select-Object -First 1
    
    if ($foundISO) {
        $outputFile = $foundISO.FullName
        Write-Host "[OK] Found: $outputFile" -ForegroundColor Green
        return $outputFile
    }
    
    Write-Error "No Windows 11 ISO found. Please download manually."
}

# If aria2c is available, use it for fast multi-connection download
$isoUrl = "https://software.download.prss.microsoft.com/dbazure/Win11_23H2_English_x64.iso"

Write-Host "[1/3] Checking disk space..." -ForegroundColor Cyan
$drive = (Get-Item $OutputPath).PSDrive.Name
$freeSpace = (Get-PSDrive $drive).Free / 1GB
Write-Host "      Available: $([math]::Round($freeSpace, 2)) GB" -ForegroundColor White

if ($freeSpace -lt 10) {
    Write-Error "Insufficient disk space. Need at least 10 GB free."
}

Write-Host "[2/3] Starting download from Microsoft..." -ForegroundColor Cyan
Write-Host "      URL: $isoUrl" -ForegroundColor White
Write-Host "      Destination: $outputFile" -ForegroundColor White
Write-Host "`n      This may take 10-30 minutes depending on your connection..." -ForegroundColor Yellow
Write-Host "      Progress will be shown below:`n" -ForegroundColor White

try {
    # Use BITS for reliable background download with progress
    Import-Module BitsTransfer -ErrorAction Stop
    
    $job = Start-BitsTransfer -Source $isoUrl -Destination $outputFile -DisplayName "Windows 11 ISO Download" -Description "Downloading Windows 11 ISO from Microsoft" -Asynchronous
    
    while ($job.JobState -eq "Transferring" -or $job.JobState -eq "Connecting") {
        $percent = 0
        if ($job.BytesTotal -gt 0) {
            $percent = [math]::Round(($job.BytesTransferred / $job.BytesTotal) * 100, 2)
        }
        
        Write-Progress -Activity "Downloading Windows 11 ISO" `
            -Status "$percent% Complete - $([math]::Round($job.BytesTransferred/1MB, 2)) MB / $([math]::Round($job.BytesTotal/1MB, 2)) MB" `
            -PercentComplete $percent
        
        Start-Sleep -Seconds 2
    }
    
    Complete-BitsTransfer -BitsJob $job
    Write-Progress -Activity "Downloading Windows 11 ISO" -Completed
    
} catch {
    Write-Host "`n[!!] BITS transfer failed, trying Invoke-WebRequest..." -ForegroundColor Yellow
    
    # Fallback to Invoke-WebRequest
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $isoUrl -OutFile $outputFile -UseBasicParsing
    $ProgressPreference = 'Continue'
}

Write-Host "`n[3/3] Verifying download..." -ForegroundColor Cyan

if (Test-Path $outputFile) {
    $downloadedFile = Get-Item $outputFile
    $sizeGB = [math]::Round($downloadedFile.Length/1GB, 2)
    
    if ($downloadedFile.Length -lt 100MB) {
        Write-Error "Downloaded file is too small ($sizeGB GB). Download may have failed."
    }
    
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "       DOWNLOAD SUCCESSFUL!" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Green
    
    Write-Host "[OK] Windows 11 ISO downloaded:" -ForegroundColor Green
    Write-Host "     Location: $outputFile" -ForegroundColor White
    Write-Host "     Size: $sizeGB GB" -ForegroundColor White
    Write-Host "     Date: $($downloadedFile.LastWriteTime)" -ForegroundColor White
    
    Write-Host "`n[NEXT STEP] Run the setup wizard:" -ForegroundColor Cyan
    Write-Host "  .\scripts\Setup-ISOBuildSystem.ps1`n" -ForegroundColor White
    
    return $outputFile
    
} else {
    Write-Error "Download failed - file not found at $outputFile"
}
