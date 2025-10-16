# Watch-Deploy.ps1 - Continuous deployment monitoring
Write-Host ""
Write-Host "WATCH MODE ACTIVATED" -ForegroundColor Cyan
Write-Host "Monitoring for changes and auto-deploying..." -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
Write-Host ""

$deployPath = ".\deploy"
$lastCheck = Get-Date

while ($true) {
    # Check for new files or changes
    $recentChanges = Get-ChildItem -Path $deployPath -Recurse -File |
        Where-Object { $_.LastWriteTime -gt $lastCheck }

    if ($recentChanges.Count -gt 0) {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Detected $($recentChanges.Count) changes" -ForegroundColor Yellow
        Write-Host "  Triggering deployment..." -ForegroundColor White

        # Trigger deployment
        & ".\automation\Deploy-All.ps1"

        $lastCheck = Get-Date
    }

    # Check every 5 seconds
    Start-Sleep -Seconds 5
}
