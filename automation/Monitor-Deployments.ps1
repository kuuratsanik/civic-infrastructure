# Monitor-Deployments.ps1
# POST-DEPLOYMENT MONITORING AND URL COLLECTION
# Tracks deployment success and collects live URLs

param(
    [switch]$WatchMode,
    [int]$CheckInterval = 10
)

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  DEPLOYMENT MONITORING SYSTEM" -ForegroundColor Yellow
Write-Host "  Track Deployments & Collect URLs" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

$config = @{
    EvidencePath       = Join-Path $PWD.Path "evidence"
    DeploymentURLsPath = Join-Path $PWD.Path "evidence\deployment-urls.json"
    Timestamp          = Get-Date -Format "yyyyMMdd-HHmmss"
}

# Load existing URLs or create new
if (Test-Path $config.DeploymentURLsPath) {
    $deploymentURLs = Get-Content $config.DeploymentURLsPath | ConvertFrom-Json
    Write-Host "[OK] Loaded existing deployment URLs" -ForegroundColor Green
} else {
    $deploymentURLs = @{
        LastUpdated  = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Repositories = @{}
        Websites     = @{}
        Stats        = @{
            TotalDeployments   = 0
            LiveURLs           = 0
            PendingDeployments = 0
        }
    }
    Write-Host "[INFO] Starting new deployment tracking" -ForegroundColor Yellow
}

Write-Host ""

# ============================================================================
# FUNCTION: Add Deployment URL
# ============================================================================

function Add-DeploymentURL {
    param(
        [string]$Name,
        [string]$Type,  # "Repository" or "Website"
        [string]$Platform,
        [string]$URL,
        [string]$Status = "LIVE"
    )

    $deployment = @{
        URL         = $URL
        Platform    = $Platform
        Status      = $Status
        AddedAt     = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        LastChecked = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }

    if ($Type -eq "Repository") {
        $deploymentURLs.Repositories[$Name] = $deployment
    } elseif ($Type -eq "Website") {
        $deploymentURLs.Websites[$Name] = $deployment
    }

    # Update stats
    $deploymentURLs.Stats.TotalDeployments = `
        $deploymentURLs.Repositories.Count + $deploymentURLs.Websites.Count
    $deploymentURLs.Stats.LiveURLs = `
    ($deploymentURLs.Repositories.Values + $deploymentURLs.Websites.Values |
        Where-Object { $_.Status -eq "LIVE" }).Count

    # Save
    $deploymentURLs.LastUpdated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $deploymentURLs | ConvertTo-Json -Depth 10 | Out-File $config.DeploymentURLsPath -Encoding UTF8

    Write-Host "[ADDED] $Name ($Platform)" -ForegroundColor Green
    Write-Host "  URL: $URL" -ForegroundColor Cyan
}

# ============================================================================
# FUNCTION: Check GitHub Repositories
# ============================================================================

function Check-GitHubRepos {
    Write-Host "Checking GitHub repositories..." -ForegroundColor Yellow

    $ghCLI = Get-Command gh -ErrorAction SilentlyContinue
    if ($ghCLI) {
        $authStatus = gh auth status 2>&1
        if ($LASTEXITCODE -eq 0) {
            $username = gh api user --jq .login 2>&1
            $repos = gh repo list $username --json name, url, isPrivate --limit 100 2>&1 | ConvertFrom-Json

            $expectedRepos = @(
                "superintelligence-framework",
                "world-change-500",
                "ai-problem-solver",
                "multi-agent-system",
                "self-learning-ai",
                "cloud-integrations"
            )

            foreach ($repoName in $expectedRepos) {
                $found = $repos | Where-Object { $_.name -eq $repoName }
                if ($found) {
                    Add-DeploymentURL -Name $repoName -Type "Repository" `
                        -Platform "GitHub" -URL $found.url -Status "LIVE"
                }
            }

            Write-Host "  Found $($repos.Count) repositories on GitHub" -ForegroundColor White
        } else {
            Write-Host "  [INFO] GitHub CLI not authenticated" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [INFO] GitHub CLI not available" -ForegroundColor Yellow
    }

    Write-Host ""
}

# ============================================================================
# MANUAL URL ENTRY
# ============================================================================

function Enter-ManualURLs {
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  MANUAL URL ENTRY" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Enter deployment URLs as you deploy them" -ForegroundColor White
    Write-Host "Leave blank to skip or finish" -ForegroundColor Gray
    Write-Host ""

    # Repositories
    Write-Host "REPOSITORIES:" -ForegroundColor Yellow
    Write-Host ""

    $repos = @(
        "superintelligence-framework",
        "world-change-500",
        "ai-problem-solver",
        "multi-agent-system",
        "self-learning-ai",
        "cloud-integrations"
    )

    foreach ($repo in $repos) {
        # Check if already exists
        if ($deploymentURLs.Repositories.ContainsKey($repo)) {
            Write-Host "  $repo" -ForegroundColor Gray
            Write-Host "    Existing: $($deploymentURLs.Repositories[$repo].URL)" -ForegroundColor Cyan
            $update = Read-Host "    Update? (y/N)"
            if ($update -ne "y") {
                continue
            }
        } else {
            Write-Host "  $repo" -ForegroundColor White
        }

        $url = Read-Host "    URL"
        if ($url) {
            $platform = Read-Host "    Platform (GitHub/Replit/CodeSandbox)"
            if (-not $platform) { $platform = "GitHub" }

            Add-DeploymentURL -Name $repo -Type "Repository" `
                -Platform $platform -URL $url -Status "LIVE"
        }
        Write-Host ""
    }

    # Websites
    Write-Host "WEBSITES:" -ForegroundColor Yellow
    Write-Host ""

    $sites = @(
        "ai-dashboard",
        "progress-tracker",
        "documentation",
        "api-gateway"
    )

    foreach ($site in $sites) {
        # Check if already exists
        if ($deploymentURLs.Websites.ContainsKey($site)) {
            Write-Host "  $site" -ForegroundColor Gray
            Write-Host "    Existing: $($deploymentURLs.Websites[$site].URL)" -ForegroundColor Cyan
            $update = Read-Host "    Update? (y/N)"
            if ($update -ne "y") {
                continue
            }
        } else {
            Write-Host "  $site" -ForegroundColor White
        }

        $url = Read-Host "    URL"
        if ($url) {
            $platform = Read-Host "    Platform (Netlify/Vercel/CloudFlare)"
            if (-not $platform) { $platform = "Netlify" }

            Add-DeploymentURL -Name $site -Type "Website" `
                -Platform $platform -URL $url -Status "LIVE"
        }
        Write-Host ""
    }
}

# ============================================================================
# DISPLAY CURRENT STATUS
# ============================================================================

function Show-DeploymentStatus {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  DEPLOYMENT STATUS" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "STATISTICS:" -ForegroundColor Yellow
    Write-Host "  Total Deployments: $($deploymentURLs.Stats.TotalDeployments)" -ForegroundColor White
    Write-Host "  Live URLs: $($deploymentURLs.Stats.LiveURLs)" -ForegroundColor Green
    Write-Host "  Last Updated: $($deploymentURLs.LastUpdated)" -ForegroundColor Gray
    Write-Host ""

    if ($deploymentURLs.Repositories.Count -gt 0) {
        Write-Host "REPOSITORIES ($($deploymentURLs.Repositories.Count)):" -ForegroundColor Yellow
        foreach ($repo in $deploymentURLs.Repositories.GetEnumerator()) {
            Write-Host "  $($repo.Key)" -ForegroundColor White
            Write-Host "    Platform: $($repo.Value.Platform)" -ForegroundColor Gray
            Write-Host "    URL: $($repo.Value.URL)" -ForegroundColor Cyan
            Write-Host "    Status: $($repo.Value.Status)" -ForegroundColor Green
            Write-Host ""
        }
    } else {
        Write-Host "REPOSITORIES: None tracked yet" -ForegroundColor Gray
        Write-Host ""
    }

    if ($deploymentURLs.Websites.Count -gt 0) {
        Write-Host "WEBSITES ($($deploymentURLs.Websites.Count)):" -ForegroundColor Yellow
        foreach ($site in $deploymentURLs.Websites.GetEnumerator()) {
            Write-Host "  $($site.Key)" -ForegroundColor White
            Write-Host "    Platform: $($site.Value.Platform)" -ForegroundColor Gray
            Write-Host "    URL: $($site.Value.URL)" -ForegroundColor Cyan
            Write-Host "    Status: $($site.Value.Status)" -ForegroundColor Green
            Write-Host ""
        }
    } else {
        Write-Host "WEBSITES: None tracked yet" -ForegroundColor Gray
        Write-Host ""
    }

    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================================================
# GENERATE DEPLOYMENT REPORT
# ============================================================================

function Export-DeploymentReport {
    $reportPath = Join-Path $config.EvidencePath "DEPLOYMENT-REPORT-$($config.Timestamp).md"

    $report = @"
# DEPLOYMENT REPORT
**Generated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Summary

- **Total Deployments:** $($deploymentURLs.Stats.TotalDeployments)
- **Live URLs:** $($deploymentURLs.Stats.LiveURLs)
- **Repositories:** $($deploymentURLs.Repositories.Count)
- **Websites:** $($deploymentURLs.Websites.Count)

---

## Repositories

"@

    if ($deploymentURLs.Repositories.Count -gt 0) {
        foreach ($repo in $deploymentURLs.Repositories.GetEnumerator() | Sort-Object Key) {
            $report += @"

### $($repo.Key)
- **Platform:** $($repo.Value.Platform)
- **URL:** [$($repo.Value.URL)]($($repo.Value.URL))
- **Status:** $($repo.Value.Status)
- **Added:** $($repo.Value.AddedAt)

"@
        }
    } else {
        $report += "`n*No repositories tracked yet*`n"
    }

    $report += @"

---

## Websites

"@

    if ($deploymentURLs.Websites.Count -gt 0) {
        foreach ($site in $deploymentURLs.Websites.GetEnumerator() | Sort-Object Key) {
            $report += @"

### $($site.Key)
- **Platform:** $($site.Value.Platform)
- **URL:** [$($site.Value.URL)]($($site.Value.URL))
- **Status:** $($site.Value.Status)
- **Added:** $($site.Value.AddedAt)

"@
        }
    } else {
        $report += "`n*No websites tracked yet*`n"
    }

    $report += @"

---

## Quick Links

### All Repository URLs
"@

    foreach ($repo in $deploymentURLs.Repositories.Values) {
        $report += "`n- $($repo.URL)"
    }

    $report += "`n`n### All Website URLs`n"

    foreach ($site in $deploymentURLs.Websites.Values) {
        $report += "`n- $($site.URL)"
    }

    $report += @"


---

**Data File:** `evidence\deployment-urls.json`
**Report Generated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@

    $report | Out-File $reportPath -Encoding UTF8

    Write-Host "[OK] Report exported: $reportPath" -ForegroundColor Green
    Write-Host ""
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

# Check GitHub automatically
Check-GitHubRepos

# Show current status
Show-DeploymentStatus

# Interactive mode
if (-not $WatchMode) {
    Write-Host "OPTIONS:" -ForegroundColor Yellow
    Write-Host "  1. Enter deployment URLs manually" -ForegroundColor White
    Write-Host "  2. Export deployment report" -ForegroundColor White
    Write-Host "  3. Show status only (current)" -ForegroundColor White
    Write-Host "  4. Exit" -ForegroundColor White
    Write-Host ""

    $choice = Read-Host "Select option (1-4)"

    switch ($choice) {
        "1" {
            Enter-ManualURLs
            Show-DeploymentStatus
            Export-DeploymentReport
        }
        "2" {
            Export-DeploymentReport
        }
        "3" {
            # Already showed status above
        }
        default {
            Write-Host "Exiting..." -ForegroundColor Gray
        }
    }
}

# Watch mode
if ($WatchMode) {
    Write-Host "WATCH MODE ACTIVE" -ForegroundColor Cyan
    Write-Host "Checking for new deployments every $CheckInterval seconds..." -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
    Write-Host ""

    while ($true) {
        Start-Sleep -Seconds $CheckInterval

        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Checking..." -ForegroundColor Gray
        Check-GitHubRepos

        # Could add other platform checks here (Netlify API, etc.)
    }
}

Write-Host "Deployment monitoring complete" -ForegroundColor Green
Write-Host ""
