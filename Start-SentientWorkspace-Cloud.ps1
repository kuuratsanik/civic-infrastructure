<#
.SYNOPSIS
    Start Sentient Workspace with full cloud integration

.DESCRIPTION
    Enhanced launcher with Azure AI, OpenAI, and VS Code bridge support

.PARAMETER CloudEnabled
    Enable cloud features (Azure OpenAI, Computer Vision, etc.)

.PARAMETER VSCodeBridge
    Start the VS Code WebSocket bridge
#>

param(
  [Parameter(Mandatory = $false)]
  [switch]$CloudEnabled,

  [Parameter(Mandatory = $false)]
  [switch]$VSCodeBridge
)

# Check for cloud config
$cloudConfigPath = "C:\ai-council\config\azure-config.json"
$hasCloudConfig = Test-Path $cloudConfigPath

if ($CloudEnabled -and -not $hasCloudConfig) {
  Write-Warning "Cloud mode requested but azure-config.json not found"
  Write-Host "Run .\Deploy-FullPower.ps1 first to set up cloud resources`n"
  $CloudEnabled = $false
}

function Show-Banner {
  Clear-Host
  Write-Host "`n"
  Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Magenta
  Write-Host "         🧠 SENTIENT WORKSPACE CONTROL CENTER" -ForegroundColor Magenta
  if ($CloudEnabled) {
    Write-Host "                   ☁️  CLOUD MODE ACTIVE                   " -ForegroundColor Cyan
  }
  Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Magenta
  Write-Host "`n"
}

function Show-MainMenu {
  Show-Banner

  Write-Host "🎯 SELECT MODE:" -ForegroundColor Yellow
  Write-Host "`n"
  Write-Host "   [1] 🎓 Learning Mode" -ForegroundColor Green
  Write-Host "       Recommended for first 30 days" -ForegroundColor Gray
  Write-Host "       Observes your behavior, builds profile" -ForegroundColor Gray

  Write-Host "`n   [2] 💡 Suggestion Mode" -ForegroundColor Yellow
  Write-Host "       After 30 days of learning" -ForegroundColor Gray
  Write-Host "       Proposes automations, requires approval" -ForegroundColor Gray

  Write-Host "`n   [3] 🤖 Autonomous Mode" -ForegroundColor Red
  Write-Host "       Full AI control (use with caution!)" -ForegroundColor Gray
  Write-Host "       Executes pre-approved automations" -ForegroundColor Gray

  if ($hasCloudConfig) {
    Write-Host "`n   [4] ☁️  Cloud Features" -ForegroundColor Cyan
    Write-Host "       Enable Azure AI + OpenAI GPT-4" -ForegroundColor Gray
  }

  Write-Host "`n   [5] 📊 View Statistics" -ForegroundColor Cyan
  Write-Host "   [6] 🔄 Reset System" -ForegroundColor Yellow
  Write-Host "   [7] ❌ Exit" -ForegroundColor Red

  Write-Host "`n"
  $choice = Read-Host "Enter choice [1-7]"
  return $choice
}

function Start-LearningMode {
  Write-Host "`n🎓 Starting Learning Mode..." -ForegroundColor Green
  Write-Host "`n"
  Write-Host "   Duration: 30 days (43,200 observations)" -ForegroundColor Gray
  Write-Host "   Observation Interval: 1 minute" -ForegroundColor Gray
  Write-Host "   Pattern Detection: After 7 days minimum" -ForegroundColor Gray
  Write-Host "`n"

  # Start orchestrator in learning mode
  $orchestratorPath = ".\agents\master\sentient-orchestrator.ps1"

  if (Test-Path $orchestratorPath) {
    $params = @{
      Mode         = "Learning"
      CloudEnabled = $CloudEnabled
    }

    Write-Host "   🚀 Launching orchestrator..." -ForegroundColor Cyan
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$orchestratorPath`" -Mode Learning $(if ($CloudEnabled) {'-CloudEnabled'})" -WindowStyle Minimized

    Write-Host "`n   ✅ Learning Mode activated!" -ForegroundColor Green
    Write-Host "   📝 Observations will be saved to C:\ai-council\logs\observations.jsonl" -ForegroundColor Gray
    Write-Host "`n   💡 System will now learn your patterns. Check back in 7 days!" -ForegroundColor Yellow

  } else {
    Write-Error "Orchestrator not found at $orchestratorPath"
  }

  Read-Host "`nPress Enter to continue"
}

function Start-SuggestionMode {
  # Check if we have enough observations
  $obsFile = "C:\ai-council\logs\observations.jsonl"

  if (-not (Test-Path $obsFile)) {
    Write-Warning "`nNo observations found. Please run Learning Mode first."
    Read-Host "Press Enter to continue"
    return
  }

  $obsCount = (Get-Content $obsFile | Measure-Object -Line).Lines

  if ($obsCount -lt 10080) {
    Write-Warning "`nInsufficient data: $obsCount observations (need 10,080 for 7 days)"
    Write-Host "Continue learning for $([math]::Ceiling((10080 - $obsCount) / 60 / 24)) more days`n" -ForegroundColor Yellow
    Read-Host "Press Enter to continue"
    return
  }

  Write-Host "`n💡 Starting Suggestion Mode..." -ForegroundColor Yellow

  $orchestratorPath = ".\agents\master\sentient-orchestrator.ps1"
  Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$orchestratorPath`" -Mode Suggestion $(if ($CloudEnabled) {'-CloudEnabled'})" -WindowStyle Minimized

  Write-Host "`n   ✅ Suggestion Mode activated!" -ForegroundColor Green
  Write-Host "   💡 System will propose automations based on your patterns" -ForegroundColor Gray

  Read-Host "`nPress Enter to continue"
}

function Start-AutonomousMode {
  Write-Host "`n⚠️  AUTONOMOUS MODE - FULL AI CONTROL" -ForegroundColor Red
  Write-Host "`n   This mode allows the AI to:" -ForegroundColor Yellow
  Write-Host "   • Modify system settings automatically" -ForegroundColor Gray
  Write-Host "   • Launch applications without asking" -ForegroundColor Gray
  Write-Host "   • Adjust performance settings" -ForegroundColor Gray
  Write-Host "   • Execute pre-approved workflows" -ForegroundColor Gray

  Write-Host "`n   Are you ABSOLUTELY SURE? (Type 'YES' to confirm)" -ForegroundColor Red
  $confirm = Read-Host

  if ($confirm -ne 'YES') {
    Write-Host "   Cancelled" -ForegroundColor Yellow
    Read-Host "Press Enter to continue"
    return
  }

  Write-Host "`n🤖 Starting Autonomous Mode..." -ForegroundColor Red

  $orchestratorPath = ".\agents\master\sentient-orchestrator.ps1"
  Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$orchestratorPath`" -Mode Autonomous $(if ($CloudEnabled) {'-CloudEnabled'})" -WindowStyle Minimized

  Write-Host "`n   ✅ Autonomous Mode activated!" -ForegroundColor Green
  Write-Host "   🤖 AI now has full control (within approved boundaries)" -ForegroundColor Gray

  Read-Host "`nPress Enter to continue"
}

function Show-CloudFeatures {
  if (-not $hasCloudConfig) {
    Write-Warning "`nCloud features not configured"
    Write-Host "Run .\Deploy-FullPower.ps1 to set up Azure resources`n"
    Read-Host "Press Enter to continue"
    return
  }

  $config = Get-Content $cloudConfigPath | ConvertFrom-Json

  Write-Host "`n☁️  CLOUD FEATURES" -ForegroundColor Cyan
  Write-Host "`n"
  Write-Host "   Azure OpenAI:" -ForegroundColor White
  Write-Host "   • Endpoint: $($config.OpenAI.Endpoint)" -ForegroundColor Gray
  Write-Host "   • Model: GPT-4 Turbo" -ForegroundColor Gray
  Write-Host "   • Status: " -NoNewline -ForegroundColor Gray

  # Quick health check
  try {
    $headers = @{
      "api-key"      = $config.OpenAI.Key
      "Content-Type" = "application/json"
    }

    $testUrl = "$($config.OpenAI.Endpoint)/openai/deployments/$($config.OpenAI.DeploymentName)/chat/completions?api-version=2024-02-01"
    $testBody = @{
      messages   = @(@{ role = "user"; content = "Hello" })
      max_tokens = 5
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri $testUrl -Method Post -Headers $headers -Body $testBody -ErrorAction Stop
    Write-Host "✅ Connected" -ForegroundColor Green

  } catch {
    Write-Host "❌ Error" -ForegroundColor Red
  }

  Write-Host "`n   🎯 Available Features:" -ForegroundColor Yellow
  Write-Host "   • Natural language command interpretation" -ForegroundColor Gray
  Write-Host "   • Intelligent code generation" -ForegroundColor Gray
  Write-Host "   • Context-aware automation suggestions" -ForegroundColor Gray
  Write-Host "   • Advanced pattern recognition" -ForegroundColor Gray

  Write-Host "`n   Enable cloud features for this session? (y/n)" -ForegroundColor Cyan
  $enable = Read-Host

  if ($enable -eq 'y') {
    $script:CloudEnabled = $true
    Write-Host "   ✅ Cloud features enabled!" -ForegroundColor Green
  }

  Read-Host "`nPress Enter to continue"
}

function Show-Statistics {
  Write-Host "`n📊 SYSTEM STATISTICS" -ForegroundColor Cyan
  Write-Host "`n"

  # Observations
  $obsFile = "C:\ai-council\logs\observations.jsonl"
  if (Test-Path $obsFile) {
    $obsCount = (Get-Content $obsFile | Measure-Object -Line).Lines
    $daysLearning = [math]::Floor($obsCount / 1440)

    Write-Host "   📝 Observations:" -ForegroundColor White
    Write-Host "      Total: $obsCount" -ForegroundColor Gray
    Write-Host "      Days of learning: $daysLearning" -ForegroundColor Gray
    Write-Host "      Progress: $([math]::Min(100, [math]::Floor($obsCount / 432)))% to pattern detection" -ForegroundColor Gray
  } else {
    Write-Host "   📝 No observations yet (Learning Mode not started)" -ForegroundColor Yellow
  }

  # Patterns
  $patternsFile = "C:\ai-council\logs\patterns.json"
  if (Test-Path $patternsFile) {
    $patterns = Get-Content $patternsFile | ConvertFrom-Json
    Write-Host "`n   🎯 Detected Patterns: $($patterns.Count)" -ForegroundColor White

    foreach ($pattern in $patterns | Select-Object -First 5) {
      Write-Host "      • $($pattern.Name) (confidence: $($pattern.Confidence)%)" -ForegroundColor Gray
    }
  }

  # Automations
  $autoFile = "C:\ai-council\logs\automations.json"
  if (Test-Path $autoFile) {
    $automations = Get-Content $autoFile | ConvertFrom-Json
    $executed = ($automations | Where-Object { $_.Executed }).Count

    Write-Host "`n   🤖 Automations:" -ForegroundColor White
    Write-Host "      Proposed: $($automations.Count)" -ForegroundColor Gray
    Write-Host "      Executed: $executed" -ForegroundColor Gray
  }

  # Cloud stats
  if ($hasCloudConfig) {
    Write-Host "`n   ☁️  Cloud Status: Configured" -ForegroundColor Green
  } else {
    Write-Host "`n   ☁️  Cloud Status: Not configured" -ForegroundColor Yellow
  }

  Read-Host "`nPress Enter to continue"
}

function Reset-System {
  Write-Host "`n⚠️  RESET SYSTEM" -ForegroundColor Red
  Write-Host "`n   This will delete:" -ForegroundColor Yellow
  Write-Host "   • All observations" -ForegroundColor Gray
  Write-Host "   • Detected patterns" -ForegroundColor Gray
  Write-Host "   • Learning progress" -ForegroundColor Gray

  Write-Host "`n   Type 'RESET' to confirm:" -ForegroundColor Red
  $confirm = Read-Host

  if ($confirm -eq 'RESET') {
    Remove-Item "C:\ai-council\logs\observations.jsonl" -ErrorAction SilentlyContinue
    Remove-Item "C:\ai-council\logs\patterns.json" -ErrorAction SilentlyContinue
    Remove-Item "C:\ai-council\logs\automations.json" -ErrorAction SilentlyContinue

    Write-Host "`n   ✅ System reset complete" -ForegroundColor Green
  } else {
    Write-Host "`n   Cancelled" -ForegroundColor Yellow
  }

  Read-Host "Press Enter to continue"
}

# Main loop
while ($true) {
  $choice = Show-MainMenu

  switch ($choice) {
    '1' { Start-LearningMode }
    '2' { Start-SuggestionMode }
    '3' { Start-AutonomousMode }
    '4' {
      if ($hasCloudConfig) {
        Show-CloudFeatures
      }
    }
    '5' { Show-Statistics }
    '6' { Reset-System }
    '7' {
      Write-Host "`n👋 Goodbye!`n" -ForegroundColor Cyan
      exit
    }
    default {
      Write-Warning "Invalid choice"
      Start-Sleep -Seconds 1
    }
  }
}
