<#
.SYNOPSIS
    Quick status check for ISO build
.DESCRIPTION
    Simple script to check if the ISO build has completed
#>

$workspaceRoot = "C:\Users\svenk\OneDrive\All_My_Projects\New folder"
Set-Location $workspaceRoot

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "  ISO BUILD STATUS CHECK" -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan

# Check for output ISO
$outputPath = Join-Path $workspaceRoot "workspace\output"
if (Test-Path $outputPath) {
    $isos = Get-ChildItem -Path $outputPath -Filter "*.iso" -ErrorAction SilentlyContinue
    
    if ($isos) {
        Write-Host "STATUS: BUILD COMPLETE! " -ForegroundColor Green -NoNewline
        Write-Host "✓`n" -ForegroundColor Green
        
        foreach ($iso in $isos) {
            $sizeGB = [math]::Round($iso.Length / 1GB, 2)
            Write-Host "  ISO File: $($iso.Name)" -ForegroundColor White
            Write-Host "  Size: $sizeGB GB" -ForegroundColor White
            Write-Host "  Location: $($iso.FullName)" -ForegroundColor Gray
            Write-Host "  Created: $($iso.CreationTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
            Write-Host ""
        }
        
        # Check for hash
        $hashPath = Join-Path $workspaceRoot "evidence\hashes\iso-builds"
        if (Test-Path $hashPath) {
            $hashes = Get-ChildItem -Path $hashPath -Filter "*.sha256" -ErrorAction SilentlyContinue
            if ($hashes) {
                Write-Host "  Hash Files: $($hashes.Count) found" -ForegroundColor Green
            }
        }
        
        Write-Host "`nNEXT STEPS:" -ForegroundColor Cyan
        Write-Host "  1. Verify ISO integrity" -ForegroundColor White
        Write-Host "  2. Test in VM or create bootable USB" -ForegroundColor White
        Write-Host "  3. Check REAL_BUILD_SUMMARY.md for details`n" -ForegroundColor White
        
    } else {
        Write-Host "STATUS: " -ForegroundColor Yellow -NoNewline
        Write-Host "IN PROGRESS" -ForegroundColor Yellow
        Write-Host "`nThe build is still running in the Administrator window." -ForegroundColor White
        Write-Host "This typically takes 20-30 minutes.`n" -ForegroundColor Gray
        
        Write-Host "What is happening:" -ForegroundColor Cyan
        Write-Host "  - Mounting WIM image" -ForegroundColor Gray
        Write-Host "  - Applying registry tweaks" -ForegroundColor Gray
        Write-Host "  - Removing bloatware apps" -ForegroundColor Gray
        Write-Host "  - Creating bootable ISO" -ForegroundColor Gray
        Write-Host "  - Generating hash and evidence`n" -ForegroundColor Gray
        
        Write-Host "Check back in a few minutes or look at the Admin window for progress.`n" -ForegroundColor White
    }
} else {
    Write-Host "STATUS: " -ForegroundColor Yellow -NoNewline
    Write-Host "WAITING TO START" -ForegroundColor Yellow
    Write-Host "`nOutput folder not created yet. The build ceremony is initializing.`n" -ForegroundColor Gray
}

Write-Host "======================================`n" -ForegroundColor Cyan
