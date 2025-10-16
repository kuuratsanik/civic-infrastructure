# Check-Status.ps1 - Deployment status checker
Write-Host ""
Write-Host "DEPLOYMENT STATUS CHECK" -ForegroundColor Cyan
Write-Host ""

$deployPath = ".\deploy"
$evidencePath = ".\evidence"

# Check repositories
$repos = Get-ChildItem -Path "$deployPath\repos" -Directory
Write-Host "REPOSITORIES: $($repos.Count)" -ForegroundColor Yellow
foreach ($repo in $repos) {
    $gitStatus = "Not initialized"
    if (Test-Path "$($repo.FullName)\.git") {
        Push-Location $repo.FullName
        $branch = git branch --show-current 2>$null
        $gitStatus = "Git: $branch"
        Pop-Location
    }
    Write-Host "  [OK] $($repo.Name) - $gitStatus" -ForegroundColor Green
}

Write-Host ""

# Check websites
$sites = Get-ChildItem -Path "$deployPath\sites" -Directory
Write-Host "WEBSITES: $($sites.Count)" -ForegroundColor Yellow
foreach ($site in $sites) {
    $files = (Get-ChildItem -Path $site.FullName -File | Measure-Object).Count
    Write-Host "  [OK] $($site.Name) - $files files" -ForegroundColor Green
}

Write-Host ""

# Check packages
$packages = Get-ChildItem -Path "$deployPath\web-packages" -Filter "*.zip" -ErrorAction SilentlyContinue
Write-Host "DEPLOYMENT PACKAGES: $($packages.Count)" -ForegroundColor Yellow
foreach ($pkg in $packages) {
    $size = [math]::Round($pkg.Length / 1KB, 2)
    Write-Host "  [OK] $($pkg.Name) - $size KB" -ForegroundColor Green
}

Write-Host ""

# Check recent deployments
$logs = Get-ChildItem -Path $evidencePath -Filter "auto-deploy-*.json" -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending | Select-Object -First 5

if ($logs) {
    Write-Host "RECENT DEPLOYMENTS:" -ForegroundColor Yellow
    foreach ($log in $logs) {
        $content = Get-Content $log.FullName | ConvertFrom-Json
        Write-Host "  [$($content.Timestamp)] $($content.Deployments.Count) deployments" -ForegroundColor White
    }
} else {
    Write-Host "No deployment logs found" -ForegroundColor Gray
}

Write-Host ""
