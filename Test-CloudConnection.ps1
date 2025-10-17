<#
.SYNOPSIS
    Test cloud connection and verify deployment
#>

Write-Host "`n🔍 Testing Cloud Connection..." -ForegroundColor Cyan
Write-Host "`n"

$configPath = "C:\ai-council\config\azure-config.json"

if (-not (Test-Path $configPath)) {
  Write-Warning "No cloud configuration found"
  Write-Host "Run .\Deploy-FullPower.ps1 first`n"
  exit 1
}

$config = Get-Content $configPath | ConvertFrom-Json

# Test 1: Azure OpenAI
Write-Host "☁️  Azure OpenAI..." -NoNewline
try {
  $headers = @{
    "api-key"      = $config.OpenAI.Key
    "Content-Type" = "application/json"
  }

  $url = "$($config.OpenAI.Endpoint)/openai/deployments/$($config.OpenAI.DeploymentName)/chat/completions?api-version=2024-02-01"
  $body = @{
    messages   = @(@{
        role    = "user"
        content = "Say 'Hello from Sentient Workspace' in 3 words"
      })
    max_tokens = 10
  } | ConvertTo-Json -Depth 10

  $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body -TimeoutSec 10
  $reply = $response.choices[0].message.content

  Write-Host " ✅ Connected" -ForegroundColor Green
  Write-Host "   Response: $reply" -ForegroundColor Gray

  $openaiWorking = $true
} catch {
  Write-Host " ❌ Failed" -ForegroundColor Red
  Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Gray
  $openaiWorking = $false
}

# Test 2: Local orchestrator files
Write-Host "`n🧠 Local Orchestrator..." -NoNewline
$orchestratorPath = ".\agents\master\sentient-orchestrator.ps1"
if (Test-Path $orchestratorPath) {
  Write-Host " ✅ Found" -ForegroundColor Green
  $orchestratorExists = $true
} else {
  Write-Host " ❌ Missing" -ForegroundColor Red
  $orchestratorExists = $false
}

# Test 3: VS Code extension
Write-Host "💻 VS Code Extension..." -NoNewline
$extensionPath = "C:\ai-council\vscode-extension\package.json"
if (Test-Path $extensionPath) {
  Write-Host " ✅ Created" -ForegroundColor Green

  # Check if compiled
  $outPath = "C:\ai-council\vscode-extension\out\extension.js"
  if (Test-Path $outPath) {
    Write-Host "   Compiled: ✅" -ForegroundColor Gray
  } else {
    Write-Host "   Compiled: ⚠️  Run 'npm install && npm run compile'" -ForegroundColor Yellow
  }

  $extensionExists = $true
} else {
  Write-Host " ❌ Missing" -ForegroundColor Red
  $extensionExists = $false
}

# Test 4: WebSocket bridge
Write-Host "🔌 WebSocket Bridge..." -NoNewline
$bridgePath = "C:\ai-council\agents\vscode\websocket-bridge.ps1"
if (Test-Path $bridgePath) {
  Write-Host " ✅ Ready" -ForegroundColor Green
  $bridgeExists = $true
} else {
  Write-Host " ❌ Missing" -ForegroundColor Red
  $bridgeExists = $false
}

# Test 5: Logs directory
Write-Host "📝 Logs Directory..." -NoNewline
$logsPath = "C:\ai-council\logs"
if (Test-Path $logsPath) {
  $obsFile = "$logsPath\observations.jsonl"
  if (Test-Path $obsFile) {
    $obsCount = (Get-Content $obsFile | Measure-Object -Line).Lines
    Write-Host " ✅ Active ($obsCount observations)" -ForegroundColor Green
  } else {
    Write-Host " ✅ Ready (no observations yet)" -ForegroundColor Green
  }
  $logsExist = $true
} else {
  Write-Host " ❌ Missing" -ForegroundColor Red
  $logsExist = $false
}

# Summary
Write-Host "`n"
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "                 TEST SUMMARY                       " -ForegroundColor Magenta
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "`n"

$allPassed = $openaiWorking -and $orchestratorExists -and $extensionExists -and $bridgeExists -and $logsExist

if ($allPassed) {
  Write-Host "   ✅ ALL SYSTEMS OPERATIONAL" -ForegroundColor Green
  Write-Host "`n   Ready to launch:" -ForegroundColor White
  Write-Host "   .\Start-SentientWorkspace-Cloud.ps1 -CloudEnabled" -ForegroundColor Gray
} else {
  Write-Host "   ⚠️  SOME ISSUES DETECTED" -ForegroundColor Yellow
  Write-Host "`n   Recommended actions:" -ForegroundColor White

  if (-not $openaiWorking) {
    Write-Host "   • Check Azure OpenAI deployment" -ForegroundColor Gray
  }
  if (-not $orchestratorExists) {
    Write-Host "   • Verify orchestrator file exists" -ForegroundColor Gray
  }
  if (-not $extensionExists) {
    Write-Host "   • Re-run .\Deploy-FullPower.ps1" -ForegroundColor Gray
  }
}

Write-Host "`n"
<#
.SYNOPSIS
    Test cloud connection and verify deployment
#>

Write-Host "`n🔍 Testing Cloud Connection..." -ForegroundColor Cyan
Write-Host "`n"

$configPath = "C:\ai-council\config\azure-config.json"

if (-not (Test-Path $configPath)) {
  Write-Warning "No cloud configuration found"
  Write-Host "Run .\Deploy-FullPower.ps1 first`n"
  exit 1
}

$config = Get-Content $configPath | ConvertFrom-Json

# Test 1: Azure OpenAI
Write-Host "☁️  Azure OpenAI..." -NoNewline
try {
  $headers = @{
    "api-key"      = $config.OpenAI.Key
    "Content-Type" = "application/json"
  }

  $url = "$($config.OpenAI.Endpoint)/openai/deployments/$($config.OpenAI.DeploymentName)/chat/completions?api-version=2024-02-01"
  $body = @{
    messages   = @(@{
        role    = "user"
        content = "Say 'Hello from Sentient Workspace' in 3 words"
      })
    max_tokens = 10
  } | ConvertTo-Json -Depth 10

  $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body -TimeoutSec 10
  $reply = $response.choices[0].message.content

  Write-Host " ✅ Connected" -ForegroundColor Green
  Write-Host "   Response: $reply" -ForegroundColor Gray

  $openaiWorking = $true
} catch {
  Write-Host " ❌ Failed" -ForegroundColor Red
  Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Gray
  $openaiWorking = $false
}

# Test 2: Local orchestrator files
Write-Host "`n🧠 Local Orchestrator..." -NoNewline
$orchestratorPath = ".\agents\master\sentient-orchestrator.ps1"
if (Test-Path $orchestratorPath) {
  Write-Host " ✅ Found" -ForegroundColor Green
  $orchestratorExists = $true
} else {
  Write-Host " ❌ Missing" -ForegroundColor Red
  $orchestratorExists = $false
}

# Test 3: VS Code extension
Write-Host "💻 VS Code Extension..." -NoNewline
$extensionPath = "C:\ai-council\vscode-extension\package.json"
if (Test-Path $extensionPath) {
  Write-Host " ✅ Created" -ForegroundColor Green

  # Check if compiled
  $outPath = "C:\ai-council\vscode-extension\out\extension.js"
  if (Test-Path $outPath) {
    Write-Host "   Compiled: ✅" -ForegroundColor Gray
  } else {
    Write-Host "   Compiled: ⚠️  Run 'npm install && npm run compile'" -ForegroundColor Yellow
  }

  $extensionExists = $true
} else {
  Write-Host " ❌ Missing" -ForegroundColor Red
  $extensionExists = $false
}

# Test 4: WebSocket bridge
Write-Host "🔌 WebSocket Bridge..." -NoNewline
$bridgePath = "C:\ai-council\agents\vscode\websocket-bridge.ps1"
if (Test-Path $bridgePath) {
  Write-Host " ✅ Ready" -ForegroundColor Green
  $bridgeExists = $true
} else {
  Write-Host " ❌ Missing" -ForegroundColor Red
  $bridgeExists = $false
}

# Test 5: Logs directory
Write-Host "📝 Logs Directory..." -NoNewline
$logsPath = "C:\ai-council\logs"
if (Test-Path $logsPath) {
  $obsFile = "$logsPath\observations.jsonl"
  if (Test-Path $obsFile) {
    $obsCount = (Get-Content $obsFile | Measure-Object -Line).Lines
    Write-Host " ✅ Active ($obsCount observations)" -ForegroundColor Green
  } else {
    Write-Host " ✅ Ready (no observations yet)" -ForegroundColor Green
  }
  $logsExist = $true
} else {
  Write-Host " ❌ Missing" -ForegroundColor Red
  $logsExist = $false
}

# Summary
Write-Host "`n"
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "                 TEST SUMMARY                       " -ForegroundColor Magenta
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "`n"

$allPassed = $openaiWorking -and $orchestratorExists -and $extensionExists -and $bridgeExists -and $logsExist

if ($allPassed) {
  Write-Host "   ✅ ALL SYSTEMS OPERATIONAL" -ForegroundColor Green
  Write-Host "`n   Ready to launch:" -ForegroundColor White
  Write-Host "   .\Start-SentientWorkspace-Cloud.ps1 -CloudEnabled" -ForegroundColor Gray
} else {
  Write-Host "   ⚠️  SOME ISSUES DETECTED" -ForegroundColor Yellow
  Write-Host "`n   Recommended actions:" -ForegroundColor White

  if (-not $openaiWorking) {
    Write-Host "   • Check Azure OpenAI deployment" -ForegroundColor Gray
  }
  if (-not $orchestratorExists) {
    Write-Host "   • Verify orchestrator file exists" -ForegroundColor Gray
  }
  if (-not $extensionExists) {
    Write-Host "   • Re-run .\Deploy-FullPower.ps1" -ForegroundColor Gray
  }
}

Write-Host "`n"
