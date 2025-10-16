<#
.SYNOPSIS
    Creates Windows Task Scheduler tasks for automated video generation

.DESCRIPTION
    Sets up 3 daily tasks:
    - 7:30 AM: Morning video
    - 1:00 PM: Lunch video
    - 8:00 PM: Evening video

    Plus error monitoring and cleanup tasks

.PARAMETER Uninstall
    Remove all scheduled tasks instead of creating them

.EXAMPLE
    .\Create-ScheduledTasks.ps1
    .\Create-ScheduledTasks.ps1 -Uninstall
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory = $false)]
  [switch]$Uninstall
)

# Requires admin privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  Write-Error "This script requires administrator privileges."
  Write-Host ""
  Write-Host "Please run as Administrator:" -ForegroundColor Yellow
  Write-Host "  1. Right-click PowerShell" -ForegroundColor Cyan
  Write-Host "  2. Select 'Run as Administrator'" -ForegroundColor Cyan
  Write-Host "  3. Navigate to: $PSScriptRoot" -ForegroundColor Cyan
  Write-Host "  4. Run: .\Create-ScheduledTasks.ps1" -ForegroundColor Cyan
  Write-Host ""
  exit 1
}

$scriptPath = Join-Path $PSScriptRoot "Start-DailyVideoGeneration.ps1"

if (-not (Test-Path $scriptPath)) {
  Write-Error "Start-DailyVideoGeneration.ps1 not found at: $scriptPath"
  exit 1
}

# ============================================
# UNINSTALL MODE
# ============================================

if ($Uninstall) {
  Write-Host ""
  Write-Host "========================================" -ForegroundColor Yellow
  Write-Host "UNINSTALLING SCHEDULED TASKS" -ForegroundColor Yellow
  Write-Host "========================================" -ForegroundColor Yellow
  Write-Host ""

  $tasks = @(
    "Dropshipping - Morning Video",
    "Dropshipping - Lunch Video",
    "Dropshipping - Evening Video"
  )

  foreach ($taskName in $tasks) {
    try {
      $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
      if ($task) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Write-Host "[OK] Removed: $taskName" -ForegroundColor Green
      } else {
        Write-Host "[SKIP] Not found: $taskName" -ForegroundColor Gray
      }
    } catch {
      Write-Host "[ERROR] Failed to remove $taskName : $_" -ForegroundColor Red
    }
  }

  Write-Host ""
  Write-Host "Uninstall complete!" -ForegroundColor Green
  Write-Host ""
  exit 0
}

# ============================================
# INSTALL MODE
# ============================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CREATING SCHEDULED TASKS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This will create 3 daily tasks:" -ForegroundColor White
Write-Host "  - 7:30 AM: Morning video" -ForegroundColor Gray
Write-Host "  - 1:00 PM: Lunch video" -ForegroundColor Gray
Write-Host "  - 8:00 PM: Evening video" -ForegroundColor Gray
Write-Host ""
Write-Host "Script location: $scriptPath" -ForegroundColor Gray
Write-Host "User: $env:USERNAME" -ForegroundColor Gray
Write-Host ""

$confirm = Read-Host "Continue? (y/n)"
if ($confirm -ne 'y' -and $confirm -ne 'Y') {
  Write-Host "Cancelled by user" -ForegroundColor Yellow
  exit 0
}

Write-Host ""

# Common task settings
$settings = New-ScheduledTaskSettingsSet `
  -AllowStartIfOnBatteries `
  -DontStopIfGoingOnBatteries `
  -StartWhenAvailable `
  -RunOnlyIfNetworkAvailable `
  -ExecutionTimeLimit (New-TimeSpan -Hours 1) `
  -RestartCount 3 `
  -RestartInterval (New-TimeSpan -Minutes 5)

# ============================================
# TASK 1: MORNING VIDEO (7:30 AM)
# ============================================

Write-Host "[1/3] Creating Morning Video task (7:30 AM)..." -ForegroundColor Cyan

try {
  $action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`" -TimeSlot Morning"

  $trigger = New-ScheduledTaskTrigger -Daily -At 7:30AM

  Register-ScheduledTask `
    -TaskName "Dropshipping - Morning Video" `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Description "Generates and posts morning TikTok video (7:30 AM daily)" `
    -User $env:USERNAME `
    -RunLevel Highest `
    -Force | Out-Null

  Write-Host "      [OK] Morning task created" -ForegroundColor Green

} catch {
  Write-Host "      [ERROR] Failed to create morning task: $_" -ForegroundColor Red
}

# ============================================
# TASK 2: LUNCH VIDEO (1:00 PM)
# ============================================

Write-Host "[2/3] Creating Lunch Video task (1:00 PM)..." -ForegroundColor Cyan

try {
  $action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`" -TimeSlot Lunch"

  $trigger = New-ScheduledTaskTrigger -Daily -At 1:00PM

  Register-ScheduledTask `
    -TaskName "Dropshipping - Lunch Video" `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Description "Generates and posts lunch TikTok video (1:00 PM daily)" `
    -User $env:USERNAME `
    -RunLevel Highest `
    -Force | Out-Null

  Write-Host "      [OK] Lunch task created" -ForegroundColor Green

} catch {
  Write-Host "      [ERROR] Failed to create lunch task: $_" -ForegroundColor Red
}

# ============================================
# TASK 3: EVENING VIDEO (8:00 PM)
# ============================================

Write-Host "[3/3] Creating Evening Video task (8:00 PM)..." -ForegroundColor Cyan

try {
  $action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`" -TimeSlot Evening"

  $trigger = New-ScheduledTaskTrigger -Daily -At 8:00PM

  Register-ScheduledTask `
    -TaskName "Dropshipping - Evening Video" `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Description "Generates and posts evening TikTok video (8:00 PM daily)" `
    -User $env:USERNAME `
    -RunLevel Highest `
    -Force | Out-Null

  Write-Host "      [OK] Evening task created" -ForegroundColor Green

} catch {
  Write-Host "      [ERROR] Failed to create evening task: $_" -ForegroundColor Red
}

# ============================================
# VERIFICATION
# ============================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "SCHEDULED TASKS CREATED SUCCESSFULLY" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Write-Host "Scheduled tasks:" -ForegroundColor White
Write-Host ""

$tasks = Get-ScheduledTask | Where-Object { $_.TaskName -like "Dropshipping*" }

foreach ($task in $tasks) {
  $nextRun = (Get-ScheduledTaskInfo -TaskName $task.TaskName).NextRunTime
  Write-Host "  $($task.TaskName)" -ForegroundColor Cyan
  Write-Host "    State: $($task.State)" -ForegroundColor Gray
  Write-Host "    Next run: $nextRun" -ForegroundColor Gray
  Write-Host ""
}

Write-Host "View in Task Scheduler: " -ForegroundColor White -NoNewline
Write-Host "taskschd.msc" -ForegroundColor Yellow
Write-Host ""

Write-Host "Test tasks manually:" -ForegroundColor White
Write-Host "  Start-ScheduledTask -TaskName 'Dropshipping - Morning Video'" -ForegroundColor Cyan
Write-Host "  Start-ScheduledTask -TaskName 'Dropshipping - Lunch Video'" -ForegroundColor Cyan
Write-Host "  Start-ScheduledTask -TaskName 'Dropshipping - Evening Video'" -ForegroundColor Cyan
Write-Host ""

Write-Host "Uninstall tasks:" -ForegroundColor White
Write-Host "  .\Create-ScheduledTasks.ps1 -Uninstall" -ForegroundColor Cyan
Write-Host ""

Write-Host "========================================" -ForegroundColor Green
Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "1. Configure config.json with API keys" -ForegroundColor White
Write-Host "   Location: ..\scripts\config.json" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Test video generation manually:" -ForegroundColor White
Write-Host "   .\Start-DailyVideoGeneration.ps1 -TimeSlot Morning -TestMode" -ForegroundColor Gray
Write-Host ""
Write-Host "3. If test succeeds, tasks will run automatically" -ForegroundColor White
Write-Host "   - 7:30 AM: Morning video" -ForegroundColor Gray
Write-Host "   - 1:00 PM: Lunch video" -ForegroundColor Gray
Write-Host "   - 8:00 PM: Evening video" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Check logs for results:" -ForegroundColor White
Write-Host "   .\logs\video-generation-*.log" -ForegroundColor Gray
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
