#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Installs Ollama locally for AI agent orchestration
.DESCRIPTION
    Downloads and installs Ollama, then pulls CodeLlama model for local AI inference.
    100% local, no internet needed after initial setup.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  OLLAMA LOCAL AI INSTALLATION" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Configuration
$ollamaDownloadUrl = "https://ollama.ai/download/OllamaSetup.exe"
$tempInstaller = "$env:TEMP\OllamaSetup.exe"
$modelsToInstall = @("codellama:7b", "llama2:7b")

# Step 1: Download Ollama installer
Write-Host "[1/5] Downloading Ollama installer..." -ForegroundColor Yellow
try {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $ollamaDownloadUrl -OutFile $tempInstaller -UseBasicParsing
    Write-Host "      ✓ Downloaded to $tempInstaller" -ForegroundColor Green
} catch {
    Write-Host "      ✗ Download failed: $_" -ForegroundColor Red
    Write-Host "`nAlternative: Download manually from https://ollama.ai/download" -ForegroundColor Yellow
    exit 1
}

# Step 2: Install Ollama
Write-Host "`n[2/5] Installing Ollama..." -ForegroundColor Yellow
try {
    Start-Process -FilePath $tempInstaller -ArgumentList "/S" -Wait -NoNewWindow
    Write-Host "      ✓ Ollama installed successfully" -ForegroundColor Green
    
    # Wait for service to start
    Start-Sleep -Seconds 5
} catch {
    Write-Host "      ✗ Installation failed: $_" -ForegroundColor Red
    exit 1
}

# Step 3: Verify Ollama is running
Write-Host "`n[3/5] Verifying Ollama service..." -ForegroundColor Yellow
$maxRetries = 10
$retryCount = 0
$ollamaRunning = $false

while ($retryCount -lt $maxRetries) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:11434/api/version" -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            $version = ($response.Content | ConvertFrom-Json).version
            Write-Host "      ✓ Ollama service running (version: $version)" -ForegroundColor Green
            $ollamaRunning = $true
            break
        }
    } catch {
        $retryCount++
        Write-Host "      Waiting for Ollama service... ($retryCount/$maxRetries)" -ForegroundColor Yellow
        Start-Sleep -Seconds 3
    }
}

if (-not $ollamaRunning) {
    Write-Host "      ✗ Ollama service did not start" -ForegroundColor Red
    Write-Host "      Try running: ollama serve" -ForegroundColor Yellow
    exit 1
}

# Step 4: Pull AI models
Write-Host "`n[4/5] Downloading AI models (this may take 10-20 minutes)..." -ForegroundColor Yellow
foreach ($model in $modelsToInstall) {
    Write-Host "      Pulling $model..." -ForegroundColor Cyan
    try {
        $pullProcess = Start-Process -FilePath "ollama" -ArgumentList "pull", $model -NoNewWindow -Wait -PassThru
        if ($pullProcess.ExitCode -eq 0) {
            Write-Host "      ✓ $model ready" -ForegroundColor Green
        } else {
            Write-Host "      ✗ Failed to pull $model" -ForegroundColor Red
        }
    } catch {
        Write-Host "      ✗ Error pulling $model : $_" -ForegroundColor Red
    }
}

# Step 5: Test model
Write-Host "`n[5/5] Testing CodeLlama model..." -ForegroundColor Yellow
try {
    $testPrompt = @{
        model = "codellama:7b"
        prompt = "Write a PowerShell function to calculate fibonacci. Only respond with code, no explanation."
        stream = $false
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method Post -Body $testPrompt -ContentType "application/json"
    
    if ($response.response) {
        Write-Host "      ✓ CodeLlama is working!" -ForegroundColor Green
        Write-Host "`nSample output:" -ForegroundColor Cyan
        Write-Host $response.response.Substring(0, [Math]::Min(200, $response.response.Length)) -ForegroundColor White
    }
} catch {
    Write-Host "      ✗ Model test failed: $_" -ForegroundColor Red
}

# Cleanup
Remove-Item $tempInstaller -Force -ErrorAction SilentlyContinue

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  INSTALLATION COMPLETE!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Installed Models:" -ForegroundColor Yellow
ollama list

Write-Host "`nOllama API: http://localhost:11434" -ForegroundColor Cyan
Write-Host "Models location: $env:USERPROFILE\.ollama\models`n" -ForegroundColor Cyan

Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Models are now running locally (no internet needed)" -ForegroundColor White
Write-Host "  2. Ready to build AI agent system" -ForegroundColor White
Write-Host "  3. Run: .\scripts\agents\Initialize-MasterAgent.ps1`n" -ForegroundColor Green
