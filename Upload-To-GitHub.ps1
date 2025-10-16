# Upload to GitHub - Interactive Helper
# Helps you push all repositories to GitHub

param(
    [string]$GitHubUsername = ""
)

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  GITHUB UPLOAD HELPER" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get GitHub username
if ($GitHubUsername -eq "") {
    Write-Host "Enter your GitHub username: " -ForegroundColor Yellow -NoNewline
    $GitHubUsername = Read-Host
}

Write-Host ""
Write-Host "GitHub username: $GitHubUsername" -ForegroundColor Green
Write-Host ""

# Check if GitHub CLI is available
$hasGit = Get-Command git -ErrorAction SilentlyContinue

if (-not $hasGit) {
    Write-Host "Git not found! Please install Git first:" -ForegroundColor Red
    Write-Host "  Download: https://git-scm.com/download/win" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Or use GitHub Desktop (easier):" -ForegroundColor Yellow
    Write-Host "  Download: https://desktop.github.com" -ForegroundColor Yellow
    exit
}

Write-Host "Git found!" -ForegroundColor Green
Write-Host ""

# List repositories
$reposPath = ".\deploy\repos"
if (-not (Test-Path $reposPath)) {
    Write-Host "No repositories found!" -ForegroundColor Red
    Write-Host "Run .\Start-Deployment.ps1 first" -ForegroundColor Yellow
    exit
}

$repos = Get-ChildItem $reposPath -Directory

Write-Host "Found $($repos.Count) repositories ready to upload:" -ForegroundColor Cyan
foreach ($repo in $repos) {
    Write-Host "  - $($repo.Name)" -ForegroundColor White
}
Write-Host ""

Write-Host "IMPORTANT: Before running this script..." -ForegroundColor Yellow
Write-Host ""
Write-Host "You need to create empty repositories on GitHub:" -ForegroundColor White
Write-Host ""

foreach ($repo in $repos) {
    Write-Host "Create: https://github.com/new" -ForegroundColor Cyan
    Write-Host "  Name: $($repo.Name)" -ForegroundColor White
    Write-Host "  Public: Yes" -ForegroundColor White
    Write-Host "  README: No (we have one)" -ForegroundColor White
    Write-Host "  .gitignore: None" -ForegroundColor White
    Write-Host ""
}

Write-Host "Have you created all repositories on GitHub? (Y/N): " -ForegroundColor Yellow -NoNewline
$ready = Read-Host

if ($ready -ne "Y" -and $ready -ne "y") {
    Write-Host ""
    Write-Host "Please create repositories on GitHub first!" -ForegroundColor Yellow
    Write-Host "Go to: https://github.com/new" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Then run this script again." -ForegroundColor White
    exit
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  UPLOADING REPOSITORIES" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

foreach ($repo in $repos) {
    Write-Host "Processing: $($repo.Name)" -ForegroundColor Cyan

    Push-Location "$reposPath\$($repo.Name)"

    # Check if remote already exists
    $existingRemote = git remote get-url origin 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Remote already configured: $existingRemote" -ForegroundColor Yellow
        Write-Host "  Pushing to existing remote..." -ForegroundColor White
    } else {
        # Add remote
        $remoteUrl = "https://github.com/$GitHubUsername/$($repo.Name).git"
        Write-Host "  Adding remote: $remoteUrl" -ForegroundColor White
        git remote add origin $remoteUrl 2>&1 | Out-Null
    }

    # Make sure we're on main branch
    git branch -M main 2>&1 | Out-Null

    # Push
    Write-Host "  Pushing to GitHub..." -ForegroundColor White
    $pushResult = git push -u origin main 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  SUCCESS! Live at: https://github.com/$GitHubUsername/$($repo.Name)" -ForegroundColor Green
    } else {
        Write-Host "  FAILED! Error:" -ForegroundColor Red
        Write-Host "  $pushResult" -ForegroundColor Red
        Write-Host ""
        Write-Host "  Possible reasons:" -ForegroundColor Yellow
        Write-Host "    1. Repository doesn't exist on GitHub" -ForegroundColor White
        Write-Host "    2. Authentication failed (need to login)" -ForegroundColor White
        Write-Host "    3. Repository name mismatch" -ForegroundColor White
        Write-Host ""
        Write-Host "  You can:" -ForegroundColor Yellow
        Write-Host "    - Create repo manually on GitHub" -ForegroundColor White
        Write-Host "    - Or use GitHub Desktop (easier)" -ForegroundColor White
    }

    Write-Host ""
    Pop-Location
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  UPLOAD COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Your repositories:" -ForegroundColor Yellow
foreach ($repo in $repos) {
    Write-Host "  https://github.com/$GitHubUsername/$($repo.Name)" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Enable GitHub Pages on each repo (for free hosting)" -ForegroundColor White
Write-Host "  2. Deploy websites to Vercel/Netlify" -ForegroundColor White
Write-Host "  3. Publish packages to npm" -ForegroundColor White
Write-Host ""
Write-Host "Run: .\Deploy-Websites.ps1" -ForegroundColor Cyan
Write-Host ""
