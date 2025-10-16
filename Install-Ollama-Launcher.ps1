# Install Ollama - Launcher
# This script helps you install Ollama with proper elevation

Write-Host "`n╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   OLLAMA INSTALLATION - CHOOSE METHOD               ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "METHOD 1: Automated Install (Requires Admin)" -ForegroundColor Yellow
Write-Host "  ✓ Downloads and installs Ollama automatically" -ForegroundColor Gray
Write-Host "  ✓ Downloads CodeLlama 7B (~4GB) and Llama2 7B (~4GB)" -ForegroundColor Gray
Write-Host "  ✓ Tests installation automatically`n" -ForegroundColor Gray

Write-Host "METHOD 2: Manual Install (Easier)" -ForegroundColor Yellow
Write-Host "  ✓ Download installer yourself" -ForegroundColor Gray
Write-Host "  ✓ Run as normal user" -ForegroundColor Gray
Write-Host "  ✓ More control over process`n" -ForegroundColor Gray

$choice = Read-Host "Choose method (1 or 2)"

if ($choice -eq "1") {
    Write-Host "`nStarting automated installation as Administrator...`n" -ForegroundColor Green

    $scriptPath = Join-Path $PSScriptRoot "setup\Install-Ollama.ps1"

    # Run as administrator
    Start-Process powershell.exe -Verb RunAs -ArgumentList @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", "`"$scriptPath`""
    ) -Wait

    Write-Host "`nInstallation complete! Press any key to continue..." -ForegroundColor Green
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

} elseif ($choice -eq "2") {
    Write-Host "`n=== MANUAL INSTALLATION GUIDE ===" -ForegroundColor Cyan

    Write-Host "`nSTEP 1: Download Ollama" -ForegroundColor Yellow
    Write-Host "  Opening download page in browser..." -ForegroundColor Gray
    Start-Process "https://ollama.ai/download/windows"

    Write-Host "`nSTEP 2: Install Ollama" -ForegroundColor Yellow
    Write-Host "  1. Run the OllamaSetup.exe file when downloaded" -ForegroundColor White
    Write-Host "  2. Follow the installation wizard" -ForegroundColor White
    Write-Host "  3. Ollama will start automatically after install`n" -ForegroundColor White

    Write-Host "Press any key when Ollama is installed..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

    Write-Host "`nSTEP 3: Download AI Models" -ForegroundColor Yellow
    Write-Host "  Running model downloads...`n" -ForegroundColor Gray

    # Download CodeLlama
    Write-Host "  Downloading CodeLlama 7B (~4GB)..." -ForegroundColor Cyan
    Write-Host "  (This may take 5-15 minutes depending on internet speed)`n" -ForegroundColor Gray
    & ollama pull codellama:7b

    # Download Llama2
    Write-Host "`n  Downloading Llama2 7B (~4GB)..." -ForegroundColor Cyan
    Write-Host "  (This may take 5-15 minutes depending on internet speed)`n" -ForegroundColor Gray
    & ollama pull llama2:7b

    Write-Host "`nSTEP 4: Verify Installation" -ForegroundColor Yellow
    Write-Host "  Checking Ollama status...`n" -ForegroundColor Gray

    # List installed models
    Write-Host "Installed models:" -ForegroundColor Cyan
    & ollama list

    # Test AI
    Write-Host "`n  Testing CodeLlama..." -ForegroundColor Cyan
    $testResult = & ollama run codellama:7b "Write hello world in PowerShell. Only code, no explanation." --timeout 30

    if ($testResult) {
        Write-Host "  ✓ CodeLlama is working!`n" -ForegroundColor Green
        Write-Host "Sample output:" -ForegroundColor Gray
        Write-Host $testResult -ForegroundColor White
    }

    Write-Host "`n╔══════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║   ✅ OLLAMA INSTALLATION COMPLETE! ✅               ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════╝`n" -ForegroundColor Green

} else {
    Write-Host "`nInvalid choice. Exiting..." -ForegroundColor Red
    exit 1
}

Write-Host "`nNEXT STEPS:" -ForegroundColor Yellow
Write-Host "  Run integration setup:" -ForegroundColor White
Write-Host "  .\scripts\AI-Civic-Integration.ps1 -Setup`n" -ForegroundColor Cyan

Write-Host "  Then test it:" -ForegroundColor White
Write-Host "  .\scripts\AI-Civic-Integration.ps1 -Test`n" -ForegroundColor Cyan

Write-Host "  Or press Ctrl+Shift+I in VS Code (after reload)`n" -ForegroundColor Gray
