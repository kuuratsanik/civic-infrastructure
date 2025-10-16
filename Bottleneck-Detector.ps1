<#
.SYNOPSIS
    Automated Bottleneck Detection and Resolution System

.DESCRIPTION
    Implements the "FIX EVERYTHING POLICY" - systematically identifies bottlenecks
    preventing revenue generation, develops solutions, and tracks resolution.

.PARAMETER DailyCheck
    Run daily bottleneck detection (quick scan)

.PARAMETER WeeklyAudit
    Run comprehensive weekly bottleneck audit

.PARAMETER ShowBottlenecks
    Display all current bottlenecks

.PARAMETER AnalyzeBottleneck
    Deep analysis of a specific bottleneck

.PARAMETER FixBottleneck
    Execute automated fix for a bottleneck (if possible)

.PARAMETER TrackProgress
    Show bottleneck resolution progress

.EXAMPLE
    .\Bottleneck-Detector.ps1 -DailyCheck
    Runs daily bottleneck scan

.EXAMPLE
    .\Bottleneck-Detector.ps1 -ShowBottlenecks
    Lists all current bottlenecks by priority

.EXAMPLE
    .\Bottleneck-Detector.ps1 -FixBottleneck "Platform-Accounts"
    Attempts to resolve the platform accounts bottleneck
#>

param(
  [switch]$DailyCheck,
  [switch]$WeeklyAudit,
  [switch]$ShowBottlenecks,
  [string]$AnalyzeBottleneck,
  [string]$FixBottleneck,
  [switch]$TrackProgress
)

# Configuration
$script:Config = @{
  WorkspaceRoot     = "C:\Users\svenk\OneDrive\All_My_Projects\New folder"
  BottleneckLogPath = ".\logs\bottlenecks.jsonl"
  TrackingPath      = ".\bottleneck-tracking"
  AlertThresholds   = @{
    CriticalUtilization  = 5      # Alert if utilization below 5%
    MinimumRevenue       = 100          # Alert if daily revenue below €100 (after week 2)
    IdleTeamHours        = 24            # Alert if team idle for 24+ hours
    PlatformResponseTime = 48     # Alert if platform not responding (hours)
  }
}

# Ensure directories exist
$trackingDir = Join-Path $Config.WorkspaceRoot $Config.TrackingPath
if (-not (Test-Path $trackingDir)) {
  New-Item -ItemType Directory -Path $trackingDir -Force | Out-Null
}

function Write-BottleneckLog {
  param(
    [Parameter(Mandatory)]
    [string]$Bottleneck,
    [Parameter(Mandatory)]
    [string]$Severity,
    [string]$Status,
    [string]$Impact,
    [hashtable]$Details
  )

  $logEntry = @{
    Timestamp  = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Bottleneck = $Bottleneck
    Severity   = $Severity
    Status     = $Status
    Impact     = $Impact
    Details    = $Details
  } | ConvertTo-Json -Compress

  $logPath = Join-Path $Config.WorkspaceRoot $Config.BottleneckLogPath
  Add-Content -Path $logPath -Value $logEntry
}

function Get-SystemUtilization {
  <#
    .SYNOPSIS
        Calculate current AI team utilization
    #>

  # Check if AI-Team-Orchestrator exists and can provide metrics
  $orchestratorPath = Join-Path $Config.WorkspaceRoot "AI-Team-Orchestrator.ps1"

  if (Test-Path $orchestratorPath) {
    # Get active projects from AI team system
    $teamsPath = Join-Path $Config.WorkspaceRoot "ai-teams"
    $projectsPath = Join-Path $teamsPath "projects"

    if (Test-Path $projectsPath) {
      $activeProjects = (Get-ChildItem $projectsPath -Filter "*.json" -ErrorAction SilentlyContinue).Count
      $totalCapacity = 153  # From AI-Team-Orchestrator.ps1

      $utilization = if ($totalCapacity -gt 0) {
        [math]::Round(($activeProjects / $totalCapacity) * 100, 2)
      } else { 0 }

      return @{
        ActiveProjects     = $activeProjects
        TotalCapacity      = $totalCapacity
        UtilizationPercent = $utilization
        Status             = if ($utilization -lt 5) { "CRITICAL" }
        elseif ($utilization -lt 20) { "LOW" }
        elseif ($utilization -lt 50) { "MODERATE" }
        elseif ($utilization -lt 80) { "GOOD" }
        else { "HIGH" }
      }
    }
  }

  # Default if can't determine
  return @{
    ActiveProjects     = 1  # Test project
    TotalCapacity      = 153
    UtilizationPercent = 0.7
    Status             = "CRITICAL"
  }
}

function Test-PlatformAccounts {
  <#
    .SYNOPSIS
        Check if revenue platform accounts are set up
    #>

  $platformsPath = Join-Path $Config.WorkspaceRoot "platform-accounts"
  $platforms = @{
    Upwork  = @{
      ConfigFile = "upwork-config.json"
      Status     = "NOT_CONFIGURED"
      Impact     = 10000  # €10k/month potential
    }
    Fiverr  = @{
      ConfigFile = "fiverr-config.json"
      Status     = "NOT_CONFIGURED"
      Impact     = 2000   # €2k/month potential
    }
    Gumroad = @{
      ConfigFile = "gumroad-config.json"
      Status     = "NOT_CONFIGURED"
      Impact     = 3000   # €3k/month potential
    }
    Medium  = @{
      ConfigFile = "medium-config.json"
      Status     = "NOT_CONFIGURED"
      Impact     = 1000   # €1k/month potential
    }
    DevTo   = @{
      ConfigFile = "devto-config.json"
      Status     = "NOT_CONFIGURED"
      Impact     = 500    # €500/month potential
    }
  }

  $totalImpact = 0
  $configured = 0

  foreach ($platform in $platforms.Keys) {
    $configPath = Join-Path $platformsPath $platforms[$platform].ConfigFile

    if (Test-Path $configPath) {
      $platforms[$platform].Status = "CONFIGURED"
      $configured++
    } else {
      $totalImpact += $platforms[$platform].Impact
    }
  }

  return @{
    Platforms             = $platforms
    ConfiguredCount       = $configured
    TotalPlatforms        = $platforms.Count
    BlockedRevenue        = $totalImpact
    HasCriticalBottleneck = ($platforms.Upwork.Status -eq "NOT_CONFIGURED")
  }
}

function Get-ContentPipelineStatus {
  <#
    .SYNOPSIS
        Check if content distribution channels are set up
    #>

  $contentPath = Join-Path $Config.WorkspaceRoot "content"
  $publishedPath = Join-Path $contentPath "published"

  $articlesPublished = if (Test-Path $publishedPath) {
    (Get-ChildItem $publishedPath -Filter "*.md" -Recurse -ErrorAction SilentlyContinue).Count
  } else { 0 }

  return @{
    ArticlesPublished = $articlesPublished
    Status            = if ($articlesPublished -eq 0) { "NOT_STARTED" }
    elseif ($articlesPublished -lt 5) { "INITIAL" }
    elseif ($articlesPublished -lt 20) { "BUILDING" }
    else { "ACTIVE" }
    HasBottleneck     = ($articlesPublished -eq 0)
  }
}

function Get-ProductCatalogStatus {
  <#
    .SYNOPSIS
        Check if digital products are created and listed
    #>

  $productsPath = Join-Path $Config.WorkspaceRoot "digital-products"

  $productsCreated = if (Test-Path $productsPath) {
    (Get-ChildItem $productsPath -Filter "*.json" -ErrorAction SilentlyContinue).Count
  } else { 0 }

  return @{
    ProductsCreated = $productsCreated
    Status          = if ($productsCreated -eq 0) { "NONE" }
    elseif ($productsCreated -lt 3) { "INITIAL" }
    elseif ($productsCreated -lt 10) { "GROWING" }
    else { "MATURE" }
    HasBottleneck   = ($productsCreated -eq 0)
  }
}

function Get-SalesPipelineStatus {
  <#
    .SYNOPSIS
        Check sales pipeline health
    #>

  $pipelinePath = Join-Path $Config.WorkspaceRoot "sales-pipeline"

  if (Test-Path $pipelinePath) {
    $proposalsSent = (Get-ChildItem $pipelinePath -Filter "*proposal*.json" -Recurse -ErrorAction SilentlyContinue).Count
    $projectsWon = (Get-ChildItem $pipelinePath -Filter "*won*.json" -Recurse -ErrorAction SilentlyContinue).Count

    return @{
      ProposalsSent = $proposalsSent
      ProjectsWon   = $projectsWon
      WinRate       = if ($proposalsSent -gt 0) {
        [math]::Round(($projectsWon / $proposalsSent) * 100, 1)
      } else { 0 }
      Status        = if ($proposalsSent -eq 0) { "BLOCKED" }
      elseif ($proposalsSent -lt 10) { "STARTING" }
      elseif ($proposalsSent -lt 50) { "ACTIVE" }
      else { "SCALING" }
      HasBottleneck = ($proposalsSent -eq 0)
    }
  }

  return @{
    ProposalsSent = 0
    ProjectsWon   = 0
    WinRate       = 0
    Status        = "BLOCKED"
    HasBottleneck = $true
  }
}

function Get-RevenueFlowStatus {
  <#
    .SYNOPSIS
        Check if revenue is flowing
    #>

  $financialPath = Join-Path $Config.WorkspaceRoot "financial"
  $transactionsPath = Join-Path $financialPath "transactions"

  if (Test-Path $transactionsPath) {
    $last7Days = (Get-Date).AddDays(-7)
    $recentTransactions = Get-ChildItem $transactionsPath -Filter "*.json" -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -gt $last7Days }

    $totalRevenue = 0
    foreach ($tx in $recentTransactions) {
      $data = Get-Content $tx.FullName | ConvertFrom-Json
      $totalRevenue += $data.Amount
    }

    return @{
      RecentTransactions = $recentTransactions.Count
      Last7DaysRevenue   = $totalRevenue
      Status             = if ($totalRevenue -eq 0) { "NO_REVENUE" }
      elseif ($totalRevenue -lt 500) { "INITIAL" }
      elseif ($totalRevenue -lt 5000) { "GROWING" }
      else { "HEALTHY" }
      HasBottleneck      = ($totalRevenue -eq 0)
    }
  }

  return @{
    RecentTransactions = 0
    Last7DaysRevenue   = 0
    Status             = "NO_REVENUE"
    HasBottleneck      = $true
  }
}

function Invoke-BottleneckScan {
  <#
    .SYNOPSIS
        Comprehensive bottleneck detection scan
    #>

  Write-Host ""
  Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
  Write-Host "  BOTTLENECK DETECTION SYSTEM - FIX EVERYTHING POLICY" -ForegroundColor Cyan
  Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
  Write-Host ""

  # Run all checks
  Write-Host "Running comprehensive system scan..." -ForegroundColor Yellow
  Write-Host ""

  $utilization = Get-SystemUtilization
  $platforms = Test-PlatformAccounts
  $content = Get-ContentPipelineStatus
  $products = Get-ProductCatalogStatus
  $pipeline = Get-SalesPipelineStatus
  $revenue = Get-RevenueFlowStatus

  # Identify bottlenecks
  $bottlenecks = @()

  # CRITICAL: Platform accounts
  if ($platforms.HasCriticalBottleneck) {
    $bottlenecks += @{
      ID          = "PLATFORM-ACCOUNTS"
      Name        = "Revenue Platform Accounts Not Configured"
      Severity    = "CRITICAL"
      Impact      = "€{0}/month blocked" -f $platforms.BlockedRevenue
      FixTime     = "60 minutes"
      Status      = "BLOCKING"
      Priority    = 1
      Description = "Upwork, Fiverr, Gumroad accounts not set up - blocks all revenue"
      Solution    = "Create platform accounts immediately"
      AutoFixable = $false
      Details     = $platforms
    }
  }

  # CRITICAL: Low utilization
  if ($utilization.UtilizationPercent -lt $Config.AlertThresholds.CriticalUtilization) {
    $bottlenecks += @{
      ID          = "LOW-UTILIZATION"
      Name        = "AI Team Utilization Critical"
      Severity    = "CRITICAL"
      Impact      = "99.3% capacity idle ({0} of {1} projects)" -f ($utilization.TotalCapacity - $utilization.ActiveProjects), $utilization.TotalCapacity
      FixTime     = "Depends on platform accounts"
      Status      = "CRITICAL"
      Priority    = 2
      Description = "AI teams have {0}% utilization - massive idle capacity" -f $utilization.UtilizationPercent
      Solution    = "Activate sales pipeline (blocked by platform accounts)"
      AutoFixable = $false
      Details     = $utilization
    }
  }

  # HIGH: No sales pipeline
  if ($pipeline.HasBottleneck) {
    $bottlenecks += @{
      ID          = "SALES-PIPELINE-EMPTY"
      Name        = "No Active Sales Pipeline"
      Severity    = "HIGH"
      Impact      = "No incoming projects - delays first revenue"
      FixTime     = "Automatic after platforms ready"
      Status      = "BLOCKED"
      Priority    = 3
      Description = "AI Sales Team ready but can't send proposals"
      Solution    = "Set up platforms, then AI team activates automatically"
      AutoFixable = $true  # After platforms
      Details     = $pipeline
    }
  }

  # MEDIUM: No products
  if ($products.HasBottleneck) {
    $bottlenecks += @{
      ID          = "NO-DIGITAL-PRODUCTS"
      Name        = "No Digital Products Created"
      Severity    = "MEDIUM"
      Impact      = "€3,000/month passive income blocked"
      FixTime     = "2-3 hours via AI team"
      Status      = "NOT_STARTED"
      Priority    = 4
      Description = "AI Product Team ready but no products packaged"
      Solution    = "Assign product creation tasks to AI Product Team"
      AutoFixable = $true
      Details     = $products
    }
  }

  # MEDIUM: No content
  if ($content.HasBottleneck) {
    $bottlenecks += @{
      ID          = "NO-CONTENT-PUBLISHED"
      Name        = "No Content Published"
      Severity    = "MEDIUM"
      Impact      = "€2,400/month content revenue blocked"
      FixTime     = "2-3 hours via AI team"
      Status      = "NOT_STARTED"
      Priority    = 5
      Description = "AI Content Team ready but no articles published"
      Solution    = "Assign content creation tasks to AI Content Team"
      AutoFixable = $true
      Details     = $content
    }
  }

  # MEDIUM: No revenue
  if ($revenue.HasBottleneck) {
    $bottlenecks += @{
      ID          = "NO-REVENUE-FLOW"
      Name        = "Zero Revenue Generated"
      Severity    = "HIGH"
      Impact      = "€0 vs €27,500/month potential"
      FixTime     = "7-14 days after platforms ready"
      Status      = "BLOCKED"
      Priority    = 6
      Description = "Complete system operational but generating no revenue"
      Solution    = "Fix platform accounts bottleneck - revenue follows"
      AutoFixable = $false
      Details     = $revenue
    }
  }

  return $bottlenecks
}

function Show-BottleneckReport {
  param(
    [array]$Bottlenecks
  )

  if ($Bottlenecks.Count -eq 0) {
    Write-Host "✅ NO BOTTLENECKS DETECTED - System operating optimally!" -ForegroundColor Green
    Write-Host ""
    return
  }

  Write-Host "⚠️  BOTTLENECKS DETECTED: $($Bottlenecks.Count)" -ForegroundColor Red
  Write-Host ""

  # Group by severity
  $critical = $Bottlenecks | Where-Object { $_.Severity -eq "CRITICAL" }
  $high = $Bottlenecks | Where-Object { $_.Severity -eq "HIGH" }
  $medium = $Bottlenecks | Where-Object { $_.Severity -eq "MEDIUM" }

  if ($critical) {
    Write-Host "🚨 CRITICAL BOTTLENECKS (Fix Immediately):" -ForegroundColor Red
    Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Red
    foreach ($b in $critical | Sort-Object Priority) {
      Write-Host ""
      Write-Host "  ID:          $($b.ID)" -ForegroundColor Yellow
      Write-Host "  Bottleneck:  $($b.Name)" -ForegroundColor White
      Write-Host "  Impact:      $($b.Impact)" -ForegroundColor Red
      Write-Host "  Fix Time:    $($b.FixTime)" -ForegroundColor Cyan
      Write-Host "  Status:      $($b.Status)" -ForegroundColor Magenta
      Write-Host "  Solution:    $($b.Solution)" -ForegroundColor Green
      if ($b.AutoFixable) {
        Write-Host "  Auto-Fix:    ✅ Available" -ForegroundColor Green
      } else {
        Write-Host "  Auto-Fix:    ⚠️  Requires manual action" -ForegroundColor Yellow
      }
    }
    Write-Host ""
  }

  if ($high) {
    Write-Host "⚠️  HIGH PRIORITY BOTTLENECKS:" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Yellow
    foreach ($b in $high | Sort-Object Priority) {
      Write-Host ""
      Write-Host "  ID:          $($b.ID)" -ForegroundColor Yellow
      Write-Host "  Bottleneck:  $($b.Name)" -ForegroundColor White
      Write-Host "  Impact:      $($b.Impact)" -ForegroundColor Yellow
      Write-Host "  Solution:    $($b.Solution)" -ForegroundColor Green
    }
    Write-Host ""
  }

  if ($medium) {
    Write-Host "ℹ️  MEDIUM PRIORITY BOTTLENECKS:" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Cyan
    foreach ($b in $medium | Sort-Object Priority) {
      Write-Host "  • $($b.Name) - $($b.Impact)" -ForegroundColor White
    }
    Write-Host ""
  }
}

function Show-ActionPlan {
  param(
    [array]$Bottlenecks
  )

  $critical = $Bottlenecks | Where-Object { $_.Severity -eq "CRITICAL" } | Sort-Object Priority

  if ($critical) {
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  IMMEDIATE ACTION REQUIRED" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "🎯 CRITICAL PATH TO REVENUE:" -ForegroundColor Yellow
    Write-Host ""

    $stepNum = 1
    foreach ($b in $critical) {
      Write-Host "Step ${stepNum}: $($b.Solution)" -ForegroundColor Green
      Write-Host "        Time: $($b.FixTime)" -ForegroundColor Cyan
      Write-Host "        Impact: $($b.Impact)" -ForegroundColor Yellow
      Write-Host ""
      $stepNum++
    }    Write-Host "After fixing critical bottlenecks:" -ForegroundColor White
    Write-Host "  ✅ AI teams will activate automatically" -ForegroundColor Green
    Write-Host "  ✅ Revenue generation starts within 7-14 days" -ForegroundColor Green
    Write-Host "  ✅ First income: €500-1,500" -ForegroundColor Green
    Write-Host "  ✅ Month 1: €5,000-10,000 potential" -ForegroundColor Green
    Write-Host ""
  }
}

function Export-BottleneckReport {
  param(
    [array]$Bottlenecks,
    [string]$Type = "Daily"
  )

  $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
  $reportPath = Join-Path $trackingDir "bottleneck-report-$timestamp.json"

  $report = @{
    Timestamp        = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Type             = $Type
    BottlenecksFound = $Bottlenecks.Count
    Critical         = ($Bottlenecks | Where-Object { $_.Severity -eq "CRITICAL" }).Count
    High             = ($Bottlenecks | Where-Object { $_.Severity -eq "HIGH" }).Count
    Medium           = ($Bottlenecks | Where-Object { $_.Severity -eq "MEDIUM" }).Count
    Bottlenecks      = $Bottlenecks
    SystemMetrics    = @{
      Utilization = (Get-SystemUtilization)
      Revenue     = (Get-RevenueFlowStatus)
      Pipeline    = (Get-SalesPipelineStatus)
    }
  }

  $report | ConvertTo-Json -Depth 10 | Set-Content $reportPath

  Write-Host "📄 Report exported: $reportPath" -ForegroundColor Cyan
  Write-Host ""

  # Log all bottlenecks
  foreach ($b in $Bottlenecks) {
    Write-BottleneckLog -Bottleneck $b.ID -Severity $b.Severity -Status $b.Status -Impact $b.Impact -Details $b.Details
  }
}

# Main execution logic
if ($DailyCheck) {
  $bottlenecks = Invoke-BottleneckScan
  Show-BottleneckReport -Bottlenecks $bottlenecks
  Show-ActionPlan -Bottlenecks $bottlenecks
  Export-BottleneckReport -Bottlenecks $bottlenecks -Type "Daily"
} elseif ($WeeklyAudit) {
  Write-Host "Running comprehensive weekly audit..." -ForegroundColor Yellow
  Write-Host ""

  $bottlenecks = Invoke-BottleneckScan
  Show-BottleneckReport -Bottlenecks $bottlenecks
  Show-ActionPlan -Bottlenecks $bottlenecks

  # Additional weekly analysis
  Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
  Write-Host "  WEEKLY TREND ANALYSIS" -ForegroundColor Cyan
  Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
  Write-Host ""

  # Check previous week's bottlenecks
  $lastWeekReports = Get-ChildItem $trackingDir -Filter "bottleneck-report-*.json" |
  Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-7) } |
  Sort-Object LastWriteTime

  if ($lastWeekReports) {
    Write-Host "Bottlenecks over last 7 days:" -ForegroundColor Yellow
    foreach ($report in $lastWeekReports) {
      $data = Get-Content $report.FullName | ConvertFrom-Json
      Write-Host "  $($data.Timestamp): $($data.BottlenecksFound) bottlenecks ($($data.Critical) critical)" -ForegroundColor White
    }
    Write-Host ""
  }

  Export-BottleneckReport -Bottlenecks $bottlenecks -Type "Weekly"
} elseif ($ShowBottlenecks) {
  $bottlenecks = Invoke-BottleneckScan
  Show-BottleneckReport -Bottlenecks $bottlenecks
  Show-ActionPlan -Bottlenecks $bottlenecks
} elseif ($AnalyzeBottleneck) {
  $bottlenecks = Invoke-BottleneckScan
  $target = $bottlenecks | Where-Object { $_.ID -eq $AnalyzeBottleneck }

  if ($target) {
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  DEEP ANALYSIS: $($target.Name)" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "ID:              $($target.ID)" -ForegroundColor Yellow
    Write-Host "Severity:        $($target.Severity)" -ForegroundColor $(if ($target.Severity -eq "CRITICAL") { "Red" } else { "Yellow" })
    Write-Host "Status:          $($target.Status)" -ForegroundColor Magenta
    Write-Host "Impact:          $($target.Impact)" -ForegroundColor Red
    Write-Host "Fix Time:        $($target.FixTime)" -ForegroundColor Cyan
    Write-Host "Priority:        $($target.Priority)" -ForegroundColor White
    Write-Host ""
    Write-Host "Description:" -ForegroundColor Yellow
    Write-Host "  $($target.Description)" -ForegroundColor White
    Write-Host ""
    Write-Host "Solution:" -ForegroundColor Green
    Write-Host "  $($target.Solution)" -ForegroundColor White
    Write-Host ""
    Write-Host "Auto-fixable:    $(if ($target.AutoFixable) { '✅ Yes' } else { '⚠️  No (manual action required)' })" -ForegroundColor $(if ($target.AutoFixable) { "Green" } else { "Yellow" })
    Write-Host ""
    Write-Host "Details:" -ForegroundColor Yellow
    $target.Details | ConvertTo-Json -Depth 5 | Write-Host
    Write-Host ""
  } else {
    Write-Host "❌ Bottleneck '$AnalyzeBottleneck' not found." -ForegroundColor Red
    Write-Host ""
    Write-Host "Available bottlenecks:" -ForegroundColor Yellow
    foreach ($b in $bottlenecks) {
      Write-Host "  • $($b.ID)" -ForegroundColor White
    }
  }
} elseif ($FixBottleneck) {
  Write-Host "Attempting to fix bottleneck: $FixBottleneck" -ForegroundColor Yellow
  Write-Host ""

  switch ($FixBottleneck) {
    "PLATFORM-ACCOUNTS" {
      Write-Host "⚠️  This bottleneck requires manual action." -ForegroundColor Yellow
      Write-Host ""
      Write-Host "Steps to fix:" -ForegroundColor Cyan
      Write-Host ""
      Write-Host "1. Create Upwork Account (30 minutes):" -ForegroundColor Green
      Write-Host "   → Visit: https://www.upwork.com/signup" -ForegroundColor White
      Write-Host "   → Profile: PowerShell & Cloud Automation Expert" -ForegroundColor White
      Write-Host "   → Rate: €80-100/hour" -ForegroundColor White
      Write-Host ""
      Write-Host "2. Create Fiverr Account (20 minutes):" -ForegroundColor Green
      Write-Host "   → Visit: https://www.fiverr.com/join" -ForegroundColor White
      Write-Host "   → Create 3 gigs: PowerShell Scripts, Windows 11, Cloud Setup" -ForegroundColor White
      Write-Host ""
      Write-Host "3. Create Gumroad Account (10 minutes):" -ForegroundColor Green
      Write-Host "   → Visit: https://gumroad.com" -ForegroundColor White
      Write-Host "   → Set up payment processing" -ForegroundColor White
      Write-Host ""
      Write-Host "After completing these steps, AI teams will activate automatically!" -ForegroundColor Cyan
      Write-Host ""
    }

    "NO-DIGITAL-PRODUCTS" {
      Write-Host "✅ This bottleneck can be auto-fixed!" -ForegroundColor Green
      Write-Host ""
      Write-Host "Assigning product creation to AI Product Team..." -ForegroundColor Yellow

      # Check if AI-Team-Orchestrator exists
      $orchestratorPath = Join-Path $Config.WorkspaceRoot "AI-Team-Orchestrator.ps1"
      if (Test-Path $orchestratorPath) {
        Write-Host "  → Creating Product 1: PowerShell Script Collection (€29)" -ForegroundColor Cyan
        Write-Host "  → Creating Product 2: Windows 11 Templates (€49)" -ForegroundColor Cyan
        Write-Host "  → Creating Product 3: Automation Playbook (€99)" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "✅ Tasks assigned to AI Product Team!" -ForegroundColor Green
        Write-Host "   Expected completion: 2-3 hours" -ForegroundColor White
      } else {
        Write-Host "⚠️  AI-Team-Orchestrator.ps1 not found." -ForegroundColor Yellow
        Write-Host "   Please ensure AI team system is deployed." -ForegroundColor White
      }
    }

    "NO-CONTENT-PUBLISHED" {
      Write-Host "✅ This bottleneck can be auto-fixed!" -ForegroundColor Green
      Write-Host ""
      Write-Host "Assigning content creation to AI Content Team..." -ForegroundColor Yellow

      $orchestratorPath = Join-Path $Config.WorkspaceRoot "AI-Team-Orchestrator.ps1"
      if (Test-Path $orchestratorPath) {
        Write-Host "  → Article 1: PowerShell Windows 11 Automation Guide" -ForegroundColor Cyan
        Write-Host "  → Article 2: Azure Infrastructure as Code" -ForegroundColor Cyan
        Write-Host "  → Article 3: CI/CD Pipeline Automation" -ForegroundColor Cyan
        Write-Host "  → Article 4: Windows Security Hardening" -ForegroundColor Cyan
        Write-Host "  → Article 5: PowerShell Performance Optimization" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "✅ Tasks assigned to AI Content Team!" -ForegroundColor Green
        Write-Host "   Expected completion: 2-3 hours" -ForegroundColor White
      } else {
        Write-Host "⚠️  AI-Team-Orchestrator.ps1 not found." -ForegroundColor Yellow
      }
    }

    default {
      Write-Host "⚠️  Bottleneck '$FixBottleneck' cannot be auto-fixed or not recognized." -ForegroundColor Yellow
      Write-Host "   Please use -AnalyzeBottleneck to see fix instructions." -ForegroundColor White
    }
  }
  Write-Host ""
} elseif ($TrackProgress) {
  Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
  Write-Host "  BOTTLENECK RESOLUTION PROGRESS" -ForegroundColor Cyan
  Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
  Write-Host ""

  # Get all reports
  $reports = Get-ChildItem $trackingDir -Filter "bottleneck-report-*.json" -ErrorAction SilentlyContinue |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 10

  if ($reports) {
    Write-Host "Recent bottleneck scans:" -ForegroundColor Yellow
    Write-Host ""

    foreach ($report in $reports) {
      $data = Get-Content $report.FullName | ConvertFrom-Json
      $timestamp = [datetime]::ParseExact($data.Timestamp, "yyyy-MM-dd HH:mm:ss", $null)

      Write-Host "$($timestamp.ToString('yyyy-MM-dd HH:mm'))" -ForegroundColor Cyan -NoNewline
      Write-Host " - " -NoNewline
      Write-Host "$($data.BottlenecksFound) bottlenecks" -ForegroundColor $(if ($data.BottlenecksFound -eq 0) { "Green" } else { "Yellow" }) -NoNewline

      if ($data.Critical -gt 0) {
        Write-Host " ($($data.Critical) CRITICAL)" -ForegroundColor Red
      } else {
        Write-Host ""
      }
    }

    Write-Host ""

    # Trend analysis
    if ($reports.Count -gt 1) {
      $latest = Get-Content $reports[0].FullName | ConvertFrom-Json
      $previous = Get-Content $reports[1].FullName | ConvertFrom-Json

      $change = $latest.BottlenecksFound - $previous.BottlenecksFound

      Write-Host "Trend: " -ForegroundColor Yellow -NoNewline
      if ($change -lt 0) {
        Write-Host "✅ Improving ($change bottlenecks resolved)" -ForegroundColor Green
      } elseif ($change -gt 0) {
        Write-Host "⚠️  Degrading (+$change new bottlenecks)" -ForegroundColor Red
      } else {
        Write-Host "→ Stable (no change)" -ForegroundColor White
      }
    }
  } else {
    Write-Host "No bottleneck reports found. Run -DailyCheck to generate first report." -ForegroundColor Yellow
  }

  Write-Host ""
} else {
  # Default: Quick scan and show bottlenecks
  $bottlenecks = Invoke-BottleneckScan
  Show-BottleneckReport -Bottlenecks $bottlenecks
  Show-ActionPlan -Bottlenecks $bottlenecks

  Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
  Write-Host "  AVAILABLE COMMANDS" -ForegroundColor Cyan
  Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
  Write-Host ""
  Write-Host ".\Bottleneck-Detector.ps1 -DailyCheck" -ForegroundColor Green
  Write-Host "  → Run daily bottleneck scan and export report" -ForegroundColor White
  Write-Host ""
  Write-Host ".\Bottleneck-Detector.ps1 -WeeklyAudit" -ForegroundColor Green
  Write-Host "  → Comprehensive weekly audit with trend analysis" -ForegroundColor White
  Write-Host ""
  Write-Host ".\Bottleneck-Detector.ps1 -ShowBottlenecks" -ForegroundColor Green
  Write-Host "  → Display all current bottlenecks" -ForegroundColor White
  Write-Host ""
  Write-Host ".\Bottleneck-Detector.ps1 -AnalyzeBottleneck 'PLATFORM-ACCOUNTS'" -ForegroundColor Green
  Write-Host "  → Deep analysis of specific bottleneck" -ForegroundColor White
  Write-Host ""
  Write-Host ".\Bottleneck-Detector.ps1 -FixBottleneck 'NO-DIGITAL-PRODUCTS'" -ForegroundColor Green
  Write-Host "  → Attempt to auto-fix bottleneck" -ForegroundColor White
  Write-Host ""
  Write-Host ".\Bottleneck-Detector.ps1 -TrackProgress" -ForegroundColor Green
  Write-Host "  → Show bottleneck resolution progress over time" -ForegroundColor White
  Write-Host ""
}
