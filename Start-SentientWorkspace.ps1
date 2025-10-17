<#
.SYNOPSIS
    Quick launch script for the Sentient Workspace

.DESCRIPTION
    One-click launcher to start your AI-driven Windows 11 Pro automation system

.EXAMPLE
    .\Start-SentientWorkspace.ps1
    Launch the sentient workspace in interactive mode
#>

[CmdletBinding()]
param()

# Banner
Write-Host "`n"
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "                  🧠 SENTIENT WORKSPACE LAUNCHER                   " -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "`n"

# Check admin privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  Write-Host "❌ This script requires Administrator privileges" -ForegroundColor Red
  Write-Host "`nRestarting as Administrator...`n" -ForegroundColor Yellow

  Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
  exit
}

# Check if profile exists
$profilePath = "C:\ai-council\profiles\user-profile.json"
$isFirstRun = -not (Test-Path $profilePath)

if ($isFirstRun) {
  Write-Host "👋 Welcome to the Sentient Workspace!" -ForegroundColor Green
  Write-Host "`nThis appears to be your first time. Let me explain the operating modes:`n" -ForegroundColor White

  Write-Host "📚 LEARNING MODE" -ForegroundColor Cyan
  Write-Host "   • AI agents observe your behavior passively" -ForegroundColor Gray
  Write-Host "   • No automations are executed" -ForegroundColor Gray
  Write-Host "   • Builds a profile of your habits and preferences" -ForegroundColor Gray
  Write-Host "   • Recommended duration: 30 days`n" -ForegroundColor Gray

  Write-Host "💡 SUGGESTION MODE" -ForegroundColor Yellow
  Write-Host "   • AI agents propose automations based on detected patterns" -ForegroundColor Gray
  Write-Host "   • You approve, customize, or reject each suggestion" -ForegroundColor Gray
  Write-Host "   • Refines understanding through your feedback" -ForegroundColor Gray
  Write-Host "   • Recommended duration: 14 days`n" -ForegroundColor Gray

  Write-Host "🚀 AUTONOMOUS MODE" -ForegroundColor Green
  Write-Host "   • AI agents operate independently" -ForegroundColor Gray
  Write-Host "   • Executes approved automations without asking" -ForegroundColor Gray
  Write-Host "   • Continuously adapts to your evolving needs" -ForegroundColor Gray
  Write-Host "   • Full sentient operation`n" -ForegroundColor Gray

  Write-Host "For first-time users, " -NoNewline -ForegroundColor White
  Write-Host "LEARNING MODE" -NoNewline -ForegroundColor Cyan
  Write-Host " is strongly recommended.`n" -ForegroundColor White
}

# Mode selection
Write-Host "Select Operating Mode:`n" -ForegroundColor Cyan
Write-Host "  [1] Learning Mode     (Recommended for new users)" -ForegroundColor White
Write-Host "  [2] Suggestion Mode   (After 30 days of learning)" -ForegroundColor White
Write-Host "  [3] Autonomous Mode   (Full AI control)" -ForegroundColor White
Write-Host "  [4] View Statistics" -ForegroundColor White
Write-Host "  [5] Exit`n" -ForegroundColor White

$choice = Read-Host "Enter your choice (1-5)"

switch ($choice) {
  "1" {
    Write-Host "`n🔄 Starting Learning Mode...`n" -ForegroundColor Cyan
    & "$PSScriptRoot\agents\master\sentient-orchestrator.ps1" -OperatingMode Learning -WatchMode
  }
  "2" {
    Write-Host "`n💡 Starting Suggestion Mode...`n" -ForegroundColor Yellow
    & "$PSScriptRoot\agents\master\sentient-orchestrator.ps1" -OperatingMode Suggestion -WatchMode
  }
  "3" {
    Write-Host "`n⚠️  WARNING: Autonomous Mode grants full system control to AI agents" -ForegroundColor Red
    Write-Host "Are you sure you want to proceed? (Y/N): " -NoNewline -ForegroundColor Yellow
    $confirm = Read-Host

    if ($confirm -eq 'Y' -or $confirm -eq 'y') {
      Write-Host "`n🚀 Starting Autonomous Mode...`n" -ForegroundColor Green
      & "$PSScriptRoot\agents\master\sentient-orchestrator.ps1" -OperatingMode Autonomous -WatchMode
    } else {
      Write-Host "`nOperation cancelled.`n" -ForegroundColor Gray
    }
  }
  "4" {
    # Show statistics
    if (Test-Path $profilePath) {
      $profile = Get-Content $profilePath -Raw | ConvertFrom-Json

      Write-Host "`n📊 Sentient Workspace Statistics`n" -ForegroundColor Cyan
      Write-Host "User Profile:" -ForegroundColor White
      Write-Host "  Energy Profile: $($profile.EnergyProfile)" -ForegroundColor Gray
      Write-Host "  Detected Habits: $($profile.Habits.Count)" -ForegroundColor Gray
      Write-Host "  Preferences: $($profile.Preferences.Count)" -ForegroundColor Gray

      $observationsPath = "C:\ai-council\logs\observations.jsonl"
      if (Test-Path $observationsPath) {
        $observationCount = (Get-Content $observationsPath).Count
        Write-Host "`nObservations Collected: $observationCount" -ForegroundColor Gray
      }

      Write-Host "`n"
    } else {
      Write-Host "`n❌ No statistics available yet. Run Learning Mode first.`n" -ForegroundColor Red
    }
  }
  "5" {
    Write-Host "`nGoodbye! 👋`n" -ForegroundColor Cyan
    exit
  }
  default {
    Write-Host "`n❌ Invalid choice. Please run the script again.`n" -ForegroundColor Red
  }
}
