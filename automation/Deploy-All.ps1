# Deploy-All.ps1 - Automated deployment to all platforms
param([switch]$Verbose)

Write-Host ""
Write-Host "AUTOMATED DEPLOYMENT STARTING..." -ForegroundColor Cyan
Write-Host ""

$startTime = Get-Date

# Configuration
$deployPath = ".\deploy"
$webPackages = "$deployPath\web-packages"
$evidencePath = ".\evidence"

# Strategy: Use available tools, fallback to web-based
$deploymentLog = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Deployments = @()
}

# Check for GitHub CLI
$ghCLI = Get-Command gh -ErrorAction SilentlyContinue
if ($ghCLI) {
    Write-Host "[GITHUB CLI] Attempting automated repository deployment..." -ForegroundColor Yellow

    # Check if authenticated
    $ghAuth = gh auth status 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] GitHub CLI authenticated" -ForegroundColor Green

        # Deploy repositories via GitHub CLI
        $repos = Get-ChildItem -Path "$deployPath\repos" -Directory
        foreach ($repo in $repos) {
            Push-Location $repo.FullName

            try {
                # Create repo and push
                Write-Host "  Deploying: $($repo.Name)..." -ForegroundColor White
                $result = gh repo create $repo.Name --public --source=. --push 2>&1

                if ($LASTEXITCODE -eq 0) {
                    Write-Host "  [SUCCESS] $($repo.Name) deployed to GitHub" -ForegroundColor Green
                    $deploymentLog.Deployments += @{
                        Name = $repo.Name
                        Type = "Repository"
                        Platform = "GitHub"
                        Status = "SUCCESS"
                        URL = "https://github.com/$(gh api user --jq .login)/$($repo.Name)"
                        Method = "GitHub CLI"
                        Timestamp = Get-Date -Format "HH:mm:ss"
                    }
                } else {
                    Write-Host "  [INFO] $($repo.Name) - Already exists or requires manual setup" -ForegroundColor Yellow
                }
            } catch {
                Write-Host "  [INFO] $($repo.Name) - Error: $_" -ForegroundColor Yellow
            }

            Pop-Location
        }
    } else {
        Write-Host "[INFO] GitHub CLI not authenticated. Run: gh auth login" -ForegroundColor Yellow
        Write-Host "[INFO] Falling back to web-based deployment..." -ForegroundColor Yellow
    }
} else {
    Write-Host "[INFO] GitHub CLI not available" -ForegroundColor Yellow
    Write-Host "[INFO] Using web-based deployment strategy" -ForegroundColor Yellow
}

# Web-based deployment instructions
Write-Host ""
Write-Host "WEB-BASED DEPLOYMENT READY:" -ForegroundColor Cyan
Write-Host "  Packages: $webPackages" -ForegroundColor White
Write-Host "  Action: Drag & drop to deployment platforms" -ForegroundColor White
Write-Host ""

# Open deployment platforms
$platforms = @(
    "https://app.netlify.com/drop",
    "https://replit.com/~",
    "https://codesandbox.io/dashboard",
    "https://vercel.com/new"
)

Write-Host "Opening deployment platforms..." -ForegroundColor Yellow
foreach ($url in $platforms) {
    Start-Process $url
    Start-Sleep -Milliseconds 500
}

Write-Host "[OK] Deployment platforms opened" -ForegroundColor Green

# Open deployment folder
explorer $webPackages

Write-Host "[OK] Deployment folder opened" -ForegroundColor Green
Write-Host ""

# Save deployment log
$logPath = Join-Path $evidencePath "auto-deploy-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$deploymentLog | ConvertTo-Json -Depth 10 | Out-File $logPath -Encoding UTF8

$elapsed = ((Get-Date) - $startTime).TotalSeconds
Write-Host "DEPLOYMENT AUTOMATION COMPLETE" -ForegroundColor Green
Write-Host "  Time: $([math]::Round($elapsed, 2)) seconds" -ForegroundColor White
Write-Host "  Log: $logPath" -ForegroundColor White
Write-Host ""
