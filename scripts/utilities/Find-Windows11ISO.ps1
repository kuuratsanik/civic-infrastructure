<#
.SYNOPSIS
    Smart ISO finder and downloader for Windows 11
.DESCRIPTION
    Finds existing Windows 11 ISO or guides through download process
#>

param(
    [string]$OutputPath = "$env:USERPROFILE\Downloads"
)

$ErrorActionPreference = 'Continue'

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Windows 11 ISO Locator" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Search for existing ISOs
Write-Host "[*] Searching for existing Windows 11 ISOs...`n" -ForegroundColor Yellow

$searchLocations = @(
    "$env:USERPROFILE\Downloads",
    "$env:USERPROFILE\Desktop",
    "C:\ISO",
    "C:\Users\svenk\OneDrive\All_My_Projects\New folder\workspace"
)

$foundISOs = @()

foreach ($location in $searchLocations) {
    if (Test-Path $location) {
        $isos = Get-ChildItem -Path $location -Filter "*.iso" -ErrorAction SilentlyContinue | 
                Where-Object { $_.Length -gt 3GB -and $_.Length -lt 8GB }
        
        if ($isos) {
            foreach ($iso in $isos) {
                $foundISOs += [PSCustomObject]@{
                    Path = $iso.FullName
                    Name = $iso.Name
                    SizeGB = [math]::Round($iso.Length / 1GB, 2)
                    Date = $iso.LastWriteTime
                }
            }
        }
    }
}

if ($foundISOs.Count -gt 0) {
    Write-Host "Found $($foundISOs.Count) ISO file(s):`n" -ForegroundColor Green
    
    for ($i = 0; $i -lt $foundISOs.Count; $i++) {
        Write-Host "  [$($i+1)] $($foundISOs[$i].Name)" -ForegroundColor White
        Write-Host "      Path: $($foundISOs[$i].Path)" -ForegroundColor Gray
        Write-Host "      Size: $($foundISOs[$i].SizeGB) GB" -ForegroundColor Gray
        Write-Host "      Date: $($foundISOs[$i].Date)`n" -ForegroundColor Gray
    }
    
    if ($foundISOs.Count -eq 1) {
        $choice = Read-Host "Use this ISO? (Y/n)"
        if ($choice -ne 'n') {
            Write-Host "`n[OK] Using: $($foundISOs[0].Path)" -ForegroundColor Green
            return $foundISOs[0].Path
        }
    } else {
        $choice = Read-Host "Select ISO number (1-$($foundISOs.Count)) or 'n' to download new"
        
        if ($choice -match '^\d+$' -and [int]$choice -le $foundISOs.Count -and [int]$choice -gt 0) {
            $selected = $foundISOs[[int]$choice - 1]
            Write-Host "`n[OK] Using: $($selected.Path)" -ForegroundColor Green
            return $selected.Path
        }
    }
}

# No ISO found or user wants to download
Write-Host "`n========================================" -ForegroundColor Yellow
Write-Host "  DOWNLOAD WINDOWS 11 ISO" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Yellow

Write-Host "Opening Microsoft's official download page..." -ForegroundColor Cyan
Start-Process "https://www.microsoft.com/software-download/windows11"

Write-Host "`nFollow these steps:" -ForegroundColor White
Write-Host "  1. On the page that opened, scroll down to:" -ForegroundColor Cyan
Write-Host '     "Download Windows 11 Disk Image (ISO)"' -ForegroundColor White
Write-Host "  2. Select: 'Windows 11 (multi-edition ISO)'" -ForegroundColor Cyan
Write-Host "  3. Click: 'Download'" -ForegroundColor Cyan
Write-Host "  4. Choose language: 'English (United States)'" -ForegroundColor Cyan
Write-Host "  5. Click: '64-bit Download'" -ForegroundColor Cyan
Write-Host "  6. Save to your Downloads folder`n" -ForegroundColor Cyan

Write-Host "File size: ~5-6 GB" -ForegroundColor Yellow
Write-Host "Download time: 10-30 minutes (depends on connection)`n" -ForegroundColor Yellow

Write-Host "Waiting for download to complete..." -ForegroundColor Yellow
Write-Host "(Script will check every 30 seconds)`n" -ForegroundColor Gray

# Wait for ISO to appear in Downloads
$timeout = 120 # Wait up to 60 minutes
$elapsed = 0

while ($elapsed -lt $timeout) {
    Start-Sleep -Seconds 30
    $elapsed += 0.5
    
    $newISO = Get-ChildItem -Path "$env:USERPROFILE\Downloads" -Filter "*.iso" -ErrorAction SilentlyContinue |
              Where-Object { $_.Length -gt 3GB -and $_.LastWriteTime -gt (Get-Date).AddMinutes(-60) } |
              Sort-Object LastWriteTime -Descending |
              Select-Object -First 1
    
    if ($newISO) {
        Write-Host "`n[OK] Download detected!" -ForegroundColor Green
        Write-Host "     File: $($newISO.Name)" -ForegroundColor White
        Write-Host "     Size: $([math]::Round($newISO.Length/1GB, 2)) GB" -ForegroundColor White
        Write-Host "     Path: $($newISO.FullName)`n" -ForegroundColor White
        return $newISO.FullName
    }
    
    Write-Host "." -NoNewline -ForegroundColor Gray
}

Write-Host "`n`n[!!] Timeout waiting for download" -ForegroundColor Yellow
Write-Host "If download is still in progress, run this script again when complete.`n" -ForegroundColor Yellow

# Check one more time
$finalCheck = Get-ChildItem -Path "$env:USERPROFILE\Downloads" -Filter "*.iso" -ErrorAction SilentlyContinue |
              Where-Object { $_.Length -gt 3GB } |
              Sort-Object LastWriteTime -Descending |
              Select-Object -First 1

if ($finalCheck) {
    Write-Host "[*] Found ISO in Downloads:" -ForegroundColor Cyan
    Write-Host "    $($finalCheck.FullName)`n" -ForegroundColor White
    $use = Read-Host "Use this ISO? (Y/n)"
    if ($use -ne 'n') {
        return $finalCheck.FullName
    }
}

Write-Error "No Windows 11 ISO available. Please complete download first."
