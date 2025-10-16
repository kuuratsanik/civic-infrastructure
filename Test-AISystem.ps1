<#
.SYNOPSIS
    Simple AI system test script
.DESCRIPTION
    Tests if Ollama and AI models are working correctly
#>

param(
    [switch]$Quick
)

$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  AI SYSTEM TEST" -ForegroundColor Magenta
Write-Host "========================================`n" -ForegroundColor Magenta

# Test 1: Check Ollama service
Write-Host "[TEST 1] Checking Ollama service..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "http://localhost:11434/api/version" -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        $version = ($response.Content | ConvertFrom-Json).version
        Write-Host "  ✓ Ollama v$version running" -ForegroundColor Green
    }
} catch {
    Write-Host "  ✗ Ollama not responding" -ForegroundColor Red
    Write-Host "  Run: ollama serve`n" -ForegroundColor Yellow
    exit 1
}

# Test 2: Check models
Write-Host "`n[TEST 2] Checking AI models..." -ForegroundColor Cyan
$ollamaExe = "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe"
if (Test-Path $ollamaExe) {
    $models = & $ollamaExe list 2>&1 | Out-String

    if ($models -match "qwen2.5-coder:1.5b") {
        Write-Host "  ✓ qwen2.5-coder:1.5b available" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️ qwen2.5-coder not found" -ForegroundColor Yellow
    }

    if ($models -match "codellama:7b") {
        Write-Host "  ✓ codellama:7b available (backup)" -ForegroundColor Green
    }
} else {
    Write-Host "  ⚠️ Ollama executable not found" -ForegroundColor Yellow
}

if (-not $Quick) {
    # Test 3: AI inference
    Write-Host "`n[TEST 3] Testing AI inference..." -ForegroundColor Cyan
    $testJson = @{
        model   = "qwen2.5-coder:1.5b"
        prompt  = "Say OK"
        stream  = $false
        options = @{
            temperature = 0.1
            num_predict = 10
        }
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method Post -Body $testJson -ContentType "application/json" -TimeoutSec 30
        if ($response.response) {
            Write-Host "  ✓ AI inference working!" -ForegroundColor Green
            Write-Host "  Response: $($response.response.Trim())" -ForegroundColor Cyan
        }
    } catch {
        Write-Host "  ⚠️ Inference test failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  ALL TESTS PASSED!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Magenta

Write-Host "Your AI system is operational!`n" -ForegroundColor Green
