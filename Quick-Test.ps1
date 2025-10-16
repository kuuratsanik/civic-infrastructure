# Simple AI Test
Write-Host "`nTesting Ollama..." -ForegroundColor Cyan

try {
    $response = Invoke-WebRequest -Uri "http://localhost:11434/api/version" -UseBasicParsing -TimeoutSec 5
    Write-Host "✓ Ollama running!" -ForegroundColor Green
} catch {
    Write-Host "✗ Ollama not running" -ForegroundColor Red
}

Write-Host "`nDone!`n" -ForegroundColor Green
