# Setup-GitHubCLI.ps1
# AUTOMATED GITHUB CLI INSTALLATION AND CONFIGURATION
# Enables 100% autonomous deployment

param(
    [switch]$SkipInstall,
    [switch]$AuthOnly
)

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  GITHUB CLI SETUP AUTOMATION" -ForegroundColor Yellow
Write-Host "  Upgrade to 100% Autonomous Deployment" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# PHASE 1: CHECK CURRENT STATUS
# ============================================================================

Write-Host "PHASE 1: CHECKING GITHUB CLI STATUS" -ForegroundColor Cyan
Write-Host "--------------------------------------------------------------" -ForegroundColor Gray
Write-Host ""

$ghCLI = Get-Command gh -ErrorAction SilentlyContinue

if ($ghCLI) {
    Write-Host "[OK] GitHub CLI is installed" -ForegroundColor Green
    $version = gh --version 2>&1 | Select-Object -First 1
    Write-Host "    Version: $version" -ForegroundColor Gray
    Write-Host ""

    # Check authentication
    Write-Host "Checking authentication..." -ForegroundColor Yellow
    $authStatus = gh auth status 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] GitHub CLI is authenticated" -ForegroundColor Green
        Write-Host ""
        Write-Host "CURRENT USER:" -ForegroundColor Cyan
        $user = gh api user 2>&1 | ConvertFrom-Json
        Write-Host "  Username: $($user.login)" -ForegroundColor White
        Write-Host "  Name: $($user.name)" -ForegroundColor White
        Write-Host "  Email: $($user.email)" -ForegroundColor White
        Write-Host ""

        Write-Host "================================================================" -ForegroundColor Green
        Write-Host "  GITHUB CLI READY - 100% AUTOMATION AVAILABLE!" -ForegroundColor Yellow
        Write-Host "================================================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "You can now deploy with ZERO human intervention:" -ForegroundColor Cyan
        Write-Host "  .\automation\Deploy-Advanced.ps1" -ForegroundColor White
        Write-Host ""

        return @{
            Status        = "READY"
            Installed     = $true
            Authenticated = $true
            User          = $user.login
        }
    } else {
        Write-Host "[INFO] GitHub CLI is NOT authenticated" -ForegroundColor Yellow
        Write-Host ""

        if ($AuthOnly) {
            Write-Host "Starting authentication process..." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "AUTHENTICATION OPTIONS:" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "OPTION 1: Browser Authentication (Recommended)" -ForegroundColor Yellow
            Write-Host "  gh auth login" -ForegroundColor White
            Write-Host ""
            Write-Host "OPTION 2: Token Authentication" -ForegroundColor Yellow
            Write-Host "  gh auth login --with-token" -ForegroundColor White
            Write-Host "  Then paste your Personal Access Token" -ForegroundColor Gray
            Write-Host ""
            Write-Host "Running browser authentication..." -ForegroundColor Green
            Write-Host ""

            gh auth login

            Write-Host ""
            Write-Host "Verifying authentication..." -ForegroundColor Yellow
            $authCheck = gh auth status 2>&1

            if ($LASTEXITCODE -eq 0) {
                Write-Host "[OK] Successfully authenticated!" -ForegroundColor Green
                Write-Host ""

                return @{
                    Status        = "AUTHENTICATED"
                    Installed     = $true
                    Authenticated = $true
                }
            } else {
                Write-Host "[ERROR] Authentication failed" -ForegroundColor Red
                Write-Host ""

                return @{
                    Status        = "AUTH_FAILED"
                    Installed     = $true
                    Authenticated = $false
                }
            }
        }
    }
} else {
    Write-Host "[INFO] GitHub CLI is NOT installed" -ForegroundColor Yellow
    Write-Host ""
}

# ============================================================================
# PHASE 2: INSTALLATION
# ============================================================================

if (-not $ghCLI -and -not $SkipInstall) {
    Write-Host "PHASE 2: INSTALLING GITHUB CLI" -ForegroundColor Cyan
    Write-Host "--------------------------------------------------------------" -ForegroundColor Gray
    Write-Host ""

    # Check if winget is available
    $winget = Get-Command winget -ErrorAction SilentlyContinue

    if ($winget) {
        Write-Host "Installing GitHub CLI via winget..." -ForegroundColor Yellow
        Write-Host ""

        try {
            $installResult = winget install GitHub.cli --silent --accept-package-agreements --accept-source-agreements 2>&1

            if ($LASTEXITCODE -eq 0) {
                Write-Host "[OK] GitHub CLI installed successfully" -ForegroundColor Green
                Write-Host ""
                Write-Host "IMPORTANT: Please restart your terminal or VS Code" -ForegroundColor Yellow
                Write-Host "Then run this script again to authenticate" -ForegroundColor Yellow
                Write-Host ""

                return @{
                    Status        = "INSTALLED_RESTART_REQUIRED"
                    Installed     = $true
                    Authenticated = $false
                    Message       = "Restart terminal and run: .\automation\Setup-GitHubCLI.ps1 -AuthOnly"
                }
            } else {
                Write-Host "[ERROR] Installation failed" -ForegroundColor Red
                Write-Host "Error: $installResult" -ForegroundColor Red
                Write-Host ""
            }
        } catch {
            Write-Host "[ERROR] Exception during installation: $_" -ForegroundColor Red
            Write-Host ""
        }
    } else {
        Write-Host "[ERROR] winget not found" -ForegroundColor Red
        Write-Host ""
        Write-Host "MANUAL INSTALLATION OPTIONS:" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "OPTION 1: Download installer" -ForegroundColor Yellow
        Write-Host "  Visit: https://cli.github.com/" -ForegroundColor White
        Write-Host "  Download and run the installer" -ForegroundColor Gray
        Write-Host ""
        Write-Host "OPTION 2: Use Chocolatey" -ForegroundColor Yellow
        Write-Host "  choco install gh" -ForegroundColor White
        Write-Host ""
        Write-Host "OPTION 3: Use Scoop" -ForegroundColor Yellow
        Write-Host "  scoop install gh" -ForegroundColor White
        Write-Host ""

        Write-Host "Opening GitHub CLI website..." -ForegroundColor Green
        Start-Process "https://cli.github.com/"
        Write-Host ""

        return @{
            Status        = "MANUAL_INSTALL_REQUIRED"
            Installed     = $false
            Authenticated = $false
        }
    }
}

# ============================================================================
# PHASE 3: POST-INSTALLATION GUIDE
# ============================================================================

Write-Host "PHASE 3: SETUP GUIDE" -ForegroundColor Cyan
Write-Host "--------------------------------------------------------------" -ForegroundColor Gray
Write-Host ""

Write-Host "AFTER INSTALLATION:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Restart Terminal/VS Code" -ForegroundColor White
Write-Host "   Close and reopen to refresh PATH" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Authenticate with GitHub" -ForegroundColor White
Write-Host "   Run: gh auth login" -ForegroundColor Cyan
Write-Host "   Or:  .\automation\Setup-GitHubCLI.ps1 -AuthOnly" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. Deploy with full automation" -ForegroundColor White
Write-Host "   Run: .\automation\Deploy-Advanced.ps1" -ForegroundColor Cyan
Write-Host "   Or:  Press Ctrl+Shift+B in VS Code" -ForegroundColor Cyan
Write-Host ""

Write-Host "BENEFITS OF 100% AUTOMATION:" -ForegroundColor Cyan
Write-Host "  - Zero human intervention" -ForegroundColor Green
Write-Host "  - 2-minute deployment time (vs 7 minutes)" -ForegroundColor Green
Write-Host "  - Automatic repository creation" -ForegroundColor Green
Write-Host "  - Automatic git push" -ForegroundColor Green
Write-Host "  - Automatic URL collection" -ForegroundColor Green
Write-Host "  - Complete audit trail" -ForegroundColor Green
Write-Host ""

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

return @{
    Status        = "SETUP_GUIDE_DISPLAYED"
    Installed     = $false
    Authenticated = $false
}
