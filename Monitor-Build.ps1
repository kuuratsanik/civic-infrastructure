<#
.SYNOPSIS
    Monitors the ISO build progress in real-time
.DESCRIPTION
    Watches logs, output folder, and evidence generation during the build
#>

$ErrorActionPreference = 'Continue'

$workspaceRoot = "C:\Users\svenk\OneDrive\All_My_Projects\New folder"
$outputFolder = Join-Path $workspaceRoot "workspace\output"
$logsFile = Join-Path $workspaceRoot "logs\civic.jsonl"
$ledgerFile = Join-Path $workspaceRoot "logs\council_ledger.jsonl"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  ISO BUILD MONITOR" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Monitoring build progress..." -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop monitoring (build will continue)`n" -ForegroundColor Gray

$startTime = Get-Date
$lastLogSize = 0
$lastLedgerSize = 0

while ($true) {
    Clear-Host
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  ISO BUILD MONITOR" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    $elapsed = (Get-Date) - $startTime
    Write-Host "Elapsed time: $($elapsed.ToString('hh\:mm\:ss'))" -ForegroundColor White
    Write-Host "Started: $($startTime.ToString('HH:mm:ss'))`n" -ForegroundColor Gray
    
    # Check output folder
    Write-Host "[1] OUTPUT FOLDER:" -ForegroundColor Yellow
    if (Test-Path $outputFolder) {
        $isos = Get-ChildItem -Path $outputFolder -Filter "*.iso" -ErrorAction SilentlyContinue
        if ($isos) {
            foreach ($iso in $isos) {
                $sizeGB = [math]::Round($iso.Length / 1GB, 2)
                Write-Host "    [+] $($iso.Name)" -ForegroundColor Green
                Write-Host "        Size: $sizeGB GB" -ForegroundColor White
                Write-Host "        Time: $($iso.LastWriteTime.ToString('HH:mm:ss'))" -ForegroundColor White
            }
        } else {
            Write-Host "    [ ] No ISO files yet..." -ForegroundColor Gray
        }
    } else {
        Write-Host "    [ ] Output folder not created yet" -ForegroundColor Gray
    }
    
    # Check logs
    Write-Host "`n[2] BUILD LOGS:" -ForegroundColor Yellow
    if (Test-Path $logsFile) {
        $logSize = (Get-Item $logsFile).Length
        $logLines = (Get-Content $logsFile -ErrorAction SilentlyContinue | Measure-Object -Line).Lines
        
        Write-Host "    [+] civic.jsonl" -ForegroundColor Green
        Write-Host "        Lines: $logLines" -ForegroundColor White
        Write-Host "        Size: $([math]::Round($logSize/1KB, 2)) KB" -ForegroundColor White
        
        if ($logSize -gt $lastLogSize) {
            # Show latest log entry
            $lastEntry = Get-Content $logsFile -Tail 1 | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($lastEntry) {
                Write-Host "        Latest: $($lastEntry.message)" -ForegroundColor Cyan
            }
            $lastLogSize = $logSize
        }
    } else {
        Write-Host "    [ ] No logs yet" -ForegroundColor Gray
    }
    
    # Check ledger
    Write-Host "`n[3] AUDIT TRAIL:" -ForegroundColor Yellow
    if (Test-Path $ledgerFile) {
        $ledgerSize = (Get-Item $ledgerFile).Length
        $ledgerLines = (Get-Content $ledgerFile -ErrorAction SilentlyContinue | Measure-Object -Line).Lines
        
        Write-Host "    [+] council_ledger.jsonl" -ForegroundColor Green
        Write-Host "        Entries: $ledgerLines" -ForegroundColor White
        
        if ($ledgerSize -gt $lastLedgerSize) {
            $lastEntry = Get-Content $ledgerFile -Tail 1 | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($lastEntry) {
                Write-Host "        Latest: $($lastEntry.action)" -ForegroundColor Cyan
            }
            $lastLedgerSize = $ledgerSize
        }
    } else {
        Write-Host "    [ ] No audit trail yet" -ForegroundColor Gray
    }
    
    # Check hash files
    Write-Host "`n[4] EVIDENCE:" -ForegroundColor Yellow
    $hashFolder = Join-Path $workspaceRoot "evidence\hashes\iso-builds"
    if (Test-Path $hashFolder) {
        $hashes = Get-ChildItem -Path $hashFolder -Filter "*.sha256" -ErrorAction SilentlyContinue
        if ($hashes) {
            Write-Host "    [+] Hash files: $($hashes.Count)" -ForegroundColor Green
            foreach ($hash in $hashes | Select-Object -Last 3) {
                Write-Host "        - $($hash.Name)" -ForegroundColor White
            }
        } else {
            Write-Host "    [ ] No hash files yet" -ForegroundColor Gray
        }
    } else {
        Write-Host "    [ ] Evidence folder not created yet" -ForegroundColor Gray
    }
    
    # Check mount point (if WIM is mounted, build is in progress)
    Write-Host "`n[5] BUILD STATUS:" -ForegroundColor Yellow
    $mountPoint = Join-Path $workspaceRoot "workspace\customization\mount"
    if (Test-Path $mountPoint) {
        $mountedFiles = Get-ChildItem -Path $mountPoint -ErrorAction SilentlyContinue | Measure-Object
        if ($mountedFiles.Count -gt 10) {
            Write-Host "    [*] WIM IMAGE MOUNTED - Build in progress!" -ForegroundColor Green
            Write-Host "        Mounted files: $($mountedFiles.Count)" -ForegroundColor White
        } else {
            Write-Host "    [~] Mount point empty" -ForegroundColor Gray
        }
    } else {
        Write-Host "    [ ] Mount point not created yet" -ForegroundColor Gray
    }
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Refreshing in 10 seconds..." -ForegroundColor Gray
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    # Check if build is complete
    if (Test-Path $outputFolder) {
        $recentISO = Get-ChildItem -Path $outputFolder -Filter "Win11_Custom_*.iso" -ErrorAction SilentlyContinue | 
                     Where-Object { $_.LastWriteTime -gt $startTime }
        
        if ($recentISO) {
            Write-Host "`n" -NoNewline
            Write-Host "========================================" -ForegroundColor Green
            Write-Host "       BUILD COMPLETE!" -ForegroundColor Green
            Write-Host "========================================`n" -ForegroundColor Green
            
            Write-Host "[OK] Custom ISO created:" -ForegroundColor Green
            Write-Host "     $($recentISO.FullName)" -ForegroundColor White
            Write-Host "     Size: $([math]::Round($recentISO.Length/1GB, 2)) GB" -ForegroundColor White
            Write-Host "     Time: $($recentISO.CreationTime.ToString('HH:mm:ss'))`n" -ForegroundColor White
            
            Write-Host "Total build time: $($elapsed.ToString('hh\:mm\:ss'))" -ForegroundColor Yellow
            Write-Host "`n========================================`n" -ForegroundColor Green
            
            break
        }
    }
    
    Start-Sleep -Seconds 10
}

Write-Host "Monitoring stopped. Build artifacts are ready!`n" -ForegroundColor Cyan
