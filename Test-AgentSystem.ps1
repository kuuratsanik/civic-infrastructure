# Simple Test for AI Agent System

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  AI AGENT SYSTEM - SIMPLE TEST" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Test 1: Submit a simple coding request
Write-Host "[TEST 1] Simple coding request" -ForegroundColor Yellow
Write-Host "Request: Create a PowerShell function to calculate fibonacci numbers`n" -ForegroundColor White

$testRequest = @{
    user_request = "Create a PowerShell function to calculate the Nth fibonacci number. Include parameter validation and examples."
    priority = "normal"
    timestamp = (Get-Date -Format "o")
}

$requestFile = "bus\inbox\master-request-test-$(Get-Date -Format 'yyyyMMddHHmmss').json"
$testRequest | ConvertTo-Json | Set-Content $requestFile

Write-Host "✓ Request submitted: $requestFile`n" -ForegroundColor Green

# Launch Master in background
Write-Host "[TEST 2] Starting Master Orchestrator..." -ForegroundColor Yellow
$masterJob = Start-Job -ScriptBlock {
    Set-Location "C:\Users\svenk\OneDrive\All_My_Projects\New folder"
    & ".\agents\master\master-orchestrator.ps1" -WatchMode
}

Write-Host "✓ Master running (Job ID: $($masterJob.Id))`n" -ForegroundColor Green

# Monitor for 60 seconds
Write-Host "[TEST 3] Monitoring execution (60 seconds)..." -ForegroundColor Yellow
$startTime = Get-Date
$timeout = 60

while (((Get-Date) - $startTime).TotalSeconds -lt $timeout) {
    # Check for results
    $results = Get-ChildItem "bus\outbox\*-result.json" -ErrorAction SilentlyContinue | 
        Where-Object { $_.LastWriteTime -gt $startTime }
    
    if ($results.Count -gt 0) {
        Write-Host "`n✓ Results found!" -ForegroundColor Green
        
        foreach ($result in $results) {
            $data = Get-Content $result.FullName | ConvertFrom-Json
            Write-Host "`nTask: $($data.task_id)" -ForegroundColor Cyan
            Write-Host "Agent: $($data.agent_id)" -ForegroundColor Yellow
            Write-Host "Status: $($data.status)" -ForegroundColor Green
            Write-Host "`nResult:" -ForegroundColor White
            Write-Host $data.result.Substring(0, [Math]::Min(500, $data.result.Length)) -ForegroundColor Gray
        }
        
        break
    }
    
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 2
}

# Stop master
Stop-Job $masterJob
Remove-Job $masterJob

Write-Host "`n`n========================================" -ForegroundColor Cyan
Write-Host "  TEST COMPLETE" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Check full logs:" -ForegroundColor Yellow
Write-Host "  logs\master.jsonl" -ForegroundColor White
Write-Host "  logs\agents\*.jsonl`n" -ForegroundColor White
