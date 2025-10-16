<#
.SYNOPSIS
    📊 Show World Change Progress - Interactive progress viewer for all 500 ideas

.DESCRIPTION
    Displays progress on all world-changing ideas with interactive details view.

    Features:
    - Overview of all 500 ideas
    - Progress by category
    - Active projects tracking
    - Detailed view for any idea
    - Impact calculations
    - Timeline projections

.EXAMPLE
    .\Show-WorldChangeProgress.ps1

    Show overview and enter interactive mode

.EXAMPLE
    .\Show-WorldChangeProgress.ps1 -Details 101

    Show details for idea #101 immediately

.EXAMPLE
    .\Show-WorldChangeProgress.ps1 -Category Healthcare

    Show only healthcare ideas

.EXAMPLE
    .\Show-WorldChangeProgress.ps1 -StatusFilter "In Progress"

    Show only ideas currently being worked on
#>

param(
    [int]$Details,
    [string]$Category,
    [ValidateSet("Not Started", "In Progress", "Complete", "Blocked")]
    [string]$StatusFilter,
    [switch]$Interactive = $true,
    [switch]$ExportToHTML
)

# Progress file location
$ProgressFile = "$PSScriptRoot\evidence\world-change-progress.json"
$IdeasFile = "$PSScriptRoot\500-AI-WORLD-CHANGING-IDEAS.md"

function Show-ProgressOverview {
    param([hashtable]$ProgressData)

    Clear-Host

    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                                ║" -ForegroundColor Cyan
    Write-Host "║      🌍  WORLD CHANGE IMPLEMENTATION - PROGRESS REPORT  🌍      ║" -ForegroundColor Yellow
    Write-Host "║                                                                ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

    Write-Host "`n  📅 Last Updated: $($ProgressData.LastUpdated)" -ForegroundColor Gray
    Write-Host "  📊 Total Ideas: $($ProgressData.TotalIdeas)" -ForegroundColor Cyan

    # Overall status
    Write-Host "`n┌─────────────────────────────────────────────────────────────┐" -ForegroundColor DarkCyan
    Write-Host "│  📈 OVERALL STATUS                                          │" -ForegroundColor Yellow
    Write-Host "└─────────────────────────────────────────────────────────────┘" -ForegroundColor DarkCyan

    $allIdeas = $ProgressData.AllIdeas.Values
    $statusGroups = $allIdeas | Group-Object -Property Status

    $maxWidth = 50
    foreach ($group in $statusGroups) {
        $count = $group.Count
        $percentage = [math]::Round(($count / $ProgressData.TotalIdeas) * 100, 1)
        $barLength = [math]::Round(($percentage / 100) * $maxWidth)

        # Color by status
        $color = switch ($group.Name) {
            "Complete" { "Green" }
            "In Progress" { "Yellow" }
            "Blocked" { "Red" }
            default { "Gray" }
        }

        $icon = switch ($group.Name) {
            "Complete" { "✅" }
            "In Progress" { "🔄" }
            "Blocked" { "🚫" }
            default { "⏳" }
        }

        $bar = "█" * $barLength + "░" * ($maxWidth - $barLength)

        Write-Host "`n  $icon " -NoNewline -ForegroundColor $color
        Write-Host "$($group.Name): " -NoNewline -ForegroundColor White
        Write-Host "$count ideas " -NoNewline -ForegroundColor Cyan
        Write-Host "($percentage%)" -ForegroundColor Gray
        Write-Host "     $bar" -ForegroundColor $color
    }

    # Average progress
    $avgProgress = [math]::Round($ProgressData.AverageProgress, 1)
    Write-Host "`n  🎯 Average Progress: " -NoNewline -ForegroundColor White
    Write-Host "$avgProgress%" -ForegroundColor $(if ($avgProgress -lt 25) { "Red" }elseif ($avgProgress -lt 75) { "Yellow" }else { "Green" })

    # Progress by category
    Write-Host "`n┌─────────────────────────────────────────────────────────────┐" -ForegroundColor DarkCyan
    Write-Host "│  📊 PROGRESS BY CATEGORY                                    │" -ForegroundColor Yellow
    Write-Host "└─────────────────────────────────────────────────────────────┘" -ForegroundColor DarkCyan

    $categories = $allIdeas | Group-Object -Property Category

    foreach ($cat in ($categories | Sort-Object Name)) {
        $catProgress = [math]::Round(($cat.Group | Measure-Object -Property Progress -Average).Average, 1)
        $completed = ($cat.Group | Where-Object { $_.Status -eq "Complete" }).Count
        $total = $cat.Count

        $barLength = [math]::Round(($catProgress / 100) * 30)
        $bar = "█" * $barLength + "░" * (30 - $barLength)

        $color = if ($catProgress -ge 75) { "Green" }elseif ($catProgress -ge 25) { "Yellow" }else { "Red" }

        Write-Host "`n  " -NoNewline
        Write-Host $cat.Name.PadRight(15) -NoNewline -ForegroundColor Cyan
        Write-Host " $bar " -NoNewline -ForegroundColor $color
        Write-Host "$catProgress% " -NoNewline -ForegroundColor White
        Write-Host "($completed/$total complete)" -ForegroundColor Gray
    }

    # Active projects
    if ($ProgressData.ActiveProjects -gt 0) {
        Write-Host "`n┌─────────────────────────────────────────────────────────────┐" -ForegroundColor DarkCyan
        Write-Host "│  🔄 ACTIVE PROJECTS ($($ProgressData.ActiveProjects))                                      │" -ForegroundColor Yellow
        Write-Host "└─────────────────────────────────────────────────────────────┘" -ForegroundColor DarkCyan

        $activeIdeas = $allIdeas | Where-Object { $_.Status -eq "In Progress" } | Sort-Object -Property Progress -Descending

        foreach ($idea in $activeIdeas | Select-Object -First 15) {
            $progress = [math]::Round($idea.Progress, 0)
            $barLength = [math]::Round(($progress / 100) * 20)
            $bar = "█" * $barLength + "░" * (20 - $barLength)

            $color = if ($progress -ge 75) { "Green" }elseif ($progress -ge 50) { "Yellow" }else { "Red" }

            Write-Host "`n  #$($idea.Number.ToString().PadLeft(3)) " -NoNewline -ForegroundColor Gray
            Write-Host $idea.Name.Substring(0, [Math]::Min(40, $idea.Name.Length)).PadRight(40) -NoNewline -ForegroundColor White
            Write-Host " $bar " -NoNewline -ForegroundColor $color
            Write-Host "$progress%" -ForegroundColor $color
        }

        if ($activeIdeas.Count -gt 15) {
            Write-Host "`n  ... and $($activeIdeas.Count - 15) more active projects" -ForegroundColor Gray
        }
    }

    # Impact calculations
    Write-Host "`n┌─────────────────────────────────────────────────────────────┐" -ForegroundColor DarkCyan
    Write-Host "│  🌍 ESTIMATED GLOBAL IMPACT                                 │" -ForegroundColor Yellow
    Write-Host "└─────────────────────────────────────────────────────────────┘" -ForegroundColor DarkCyan

    $completedIdeas = $allIdeas | Where-Object { $_.Status -eq "Complete" }
    $totalImpact = ($completedIdeas | Measure-Object -Property Impact -Sum).Sum
    $estimatedLives = [math]::Round($totalImpact * 10000000)  # Impact score × 10M

    Write-Host "`n  ✅ Ideas Completed: " -NoNewline -ForegroundColor White
    Write-Host "$($completedIdeas.Count)" -ForegroundColor Green

    Write-Host "  📊 Cumulative Impact Score: " -NoNewline -ForegroundColor White
    Write-Host "$totalImpact" -ForegroundColor Cyan

    Write-Host "  👥 Lives Potentially Helped: " -NoNewline -ForegroundColor White
    if ($estimatedLives -gt 1000000000) {
        Write-Host "~$([math]::Round($estimatedLives/1000000000, 1)) billion" -ForegroundColor Yellow
    } elseif ($estimatedLives -gt 1000000) {
        Write-Host "~$([math]::Round($estimatedLives/1000000, 0)) million" -ForegroundColor Yellow
    } else {
        Write-Host "~$estimatedLives" -ForegroundColor Yellow
    }

    # Recent completions
    $recentCompletions = $completedIdeas | Sort-Object -Property LastUpdated -Descending | Select-Object -First 5
    if ($recentCompletions.Count -gt 0) {
        Write-Host "`n  🎉 Recent Completions:" -ForegroundColor Green
        foreach ($idea in $recentCompletions) {
            $timeAgo = (Get-Date) - $idea.LastUpdated
            $timeStr = if ($timeAgo.TotalDays -gt 1) {
                "$([math]::Round($timeAgo.TotalDays)) days ago"
            } elseif ($timeAgo.TotalHours -gt 1) {
                "$([math]::Round($timeAgo.TotalHours)) hours ago"
            } else {
                "$([math]::Round($timeAgo.TotalMinutes)) minutes ago"
            }

            Write-Host "     #$($idea.Number): " -NoNewline -ForegroundColor Gray
            Write-Host "$($idea.Name) " -NoNewline -ForegroundColor Cyan
            Write-Host "($timeStr)" -ForegroundColor DarkGray
        }
    }

    Write-Host "`n╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
}

function Show-IdeaDetails {
    param(
        [int]$IdeaNumber,
        [hashtable]$AllIdeas
    )

    $idea = $AllIdeas[$IdeaNumber.ToString()]

    if (-not $idea) {
        Write-Host "`n  ❌ Idea #$IdeaNumber not found!" -ForegroundColor Red
        return
    }

    Clear-Host

    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                    IDEA DETAILS                                ║" -ForegroundColor Yellow
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

    # Header
    Write-Host "`n  🔷 Idea #$IdeaNumber" -ForegroundColor Cyan
    Write-Host "  📝 " -NoNewline -ForegroundColor White
    Write-Host $idea.Name -ForegroundColor Yellow
    Write-Host "  📂 Category: " -NoNewline -ForegroundColor White
    Write-Host $idea.Category -ForegroundColor Cyan

    # Description
    Write-Host "`n  📄 Description:" -ForegroundColor White
    Write-Host "     $($idea.Description)" -ForegroundColor Gray

    # Status
    Write-Host "`n┌─────────────────────────────────────────────────────────────┐" -ForegroundColor DarkCyan
    Write-Host "│  STATUS & PROGRESS                                          │" -ForegroundColor Yellow
    Write-Host "└─────────────────────────────────────────────────────────────┘" -ForegroundColor DarkCyan

    $statusColor = switch ($idea.Status) {
        "Complete" { "Green" }
        "In Progress" { "Yellow" }
        "Blocked" { "Red" }
        default { "Gray" }
    }

    Write-Host "`n  📊 Status: " -NoNewline -ForegroundColor White
    Write-Host $idea.Status -ForegroundColor $statusColor

    Write-Host "  🎯 Progress: " -NoNewline -ForegroundColor White
    $progress = [math]::Round($idea.Progress, 1)
    $barLength = [math]::Round(($progress / 100) * 40)
    $bar = "█" * $barLength + "░" * (40 - $barLength)
    Write-Host "$bar " -NoNewline -ForegroundColor $(if ($progress -ge 75) { "Green" }elseif ($progress -ge 25) { "Yellow" }else { "Red" })
    Write-Host "$progress%" -ForegroundColor White

    Write-Host "  📅 Last Updated: " -NoNewline -ForegroundColor White
    Write-Host $idea.LastUpdated -ForegroundColor Gray

    # Metrics
    Write-Host "`n┌─────────────────────────────────────────────────────────────┐" -ForegroundColor DarkCyan
    Write-Host "│  METRICS & ASSESSMENT                                       │" -ForegroundColor Yellow
    Write-Host "└─────────────────────────────────────────────────────────────┘" -ForegroundColor DarkCyan

    Write-Host "`n  🔧 Feasibility: " -NoNewline -ForegroundColor White
    $feasibility = $idea.Feasibility
    Write-Host "$feasibility/100 " -NoNewline -ForegroundColor $(if ($feasibility -ge 70) { "Green" }elseif ($feasibility -ge 40) { "Yellow" }else { "Red" })
    Write-Host "(" -NoNewline -ForegroundColor Gray
    Write-Host $(if ($feasibility -ge 70) { "Easy" }elseif ($feasibility -ge 40) { "Medium" }else { "Difficult" }) -NoNewline -ForegroundColor White
    Write-Host ")" -ForegroundColor Gray

    Write-Host "  🔥 Impact: " -NoNewline -ForegroundColor White
    $impact = $idea.Impact
    Write-Host "$impact/100 " -NoNewline -ForegroundColor $(if ($impact -ge 70) { "Green" }elseif ($impact -ge 40) { "Yellow" }else { "Red" })
    $impactLevel = if ($impact -ge 90) { "🔥🔥🔥 Revolutionary" }elseif ($impact -ge 70) { "🔥🔥 High" }elseif ($impact -ge 40) { "🔥 Medium" }else { "Low" }
    Write-Host "($impactLevel)" -ForegroundColor White

    Write-Host "  ⏱️  Estimated Time: " -NoNewline -ForegroundColor White
    Write-Host $idea.EstimatedTime -ForegroundColor Cyan

    # Required capabilities
    if ($idea.RequiredCapabilities -and $idea.RequiredCapabilities.Count -gt 0) {
        Write-Host "`n┌─────────────────────────────────────────────────────────────┐" -ForegroundColor DarkCyan
        Write-Host "│  REQUIRED CAPABILITIES                                      │" -ForegroundColor Yellow
        Write-Host "└─────────────────────────────────────────────────────────────┘" -ForegroundColor DarkCyan

        foreach ($cap in $idea.RequiredCapabilities) {
            Write-Host "     • $cap" -ForegroundColor Cyan
        }
    }

    # Blockers
    if ($idea.Blockers -and $idea.Blockers.Count -gt 0) {
        Write-Host "`n┌─────────────────────────────────────────────────────────────┐" -ForegroundColor DarkCyan
        Write-Host "│  🚫 BLOCKERS                                                │" -ForegroundColor Red
        Write-Host "└─────────────────────────────────────────────────────────────┘" -ForegroundColor DarkCyan

        foreach ($blocker in $idea.Blockers) {
            Write-Host "     ⚠️  $blocker" -ForegroundColor Yellow
        }
    }

    # Next steps
    if ($idea.NextSteps -and $idea.NextSteps.Count -gt 0) {
        Write-Host "`n┌─────────────────────────────────────────────────────────────┐" -ForegroundColor DarkCyan
        Write-Host "│  📋 NEXT STEPS                                              │" -ForegroundColor Yellow
        Write-Host "└─────────────────────────────────────────────────────────────┘" -ForegroundColor DarkCyan

        foreach ($step in $idea.NextSteps | Select-Object -First 10) {
            Write-Host "     ➤ $step" -ForegroundColor Cyan
        }

        if ($idea.NextSteps.Count -gt 10) {
            Write-Host "     ... and $($idea.NextSteps.Count - 10) more steps" -ForegroundColor Gray
        }
    }

    # Impact projection
    Write-Host "`n┌─────────────────────────────────────────────────────────────┐" -ForegroundColor DarkCyan
    Write-Host "│  🌍 IMPACT PROJECTION                                       │" -ForegroundColor Yellow
    Write-Host "└─────────────────────────────────────────────────────────────┘" -ForegroundColor DarkCyan

    $projectedLives = $impact * 10000000
    Write-Host "`n  👥 Estimated Lives Helped: " -NoNewline -ForegroundColor White
    if ($projectedLives -gt 1000000000) {
        Write-Host "~$([math]::Round($projectedLives/1000000000, 1)) billion" -ForegroundColor Yellow
    } elseif ($projectedLives -gt 1000000) {
        Write-Host "~$([math]::Round($projectedLives/1000000, 0)) million" -ForegroundColor Yellow
    } else {
        Write-Host "~$projectedLives thousand" -ForegroundColor Yellow
    }

    # Category impact
    $categoryImpact = switch ($idea.Category) {
        "Healthcare" { "Direct health improvements, disease prevention, life extension" }
        "Environment" { "Climate stabilization, biodiversity protection, pollution reduction" }
        "Education" { "Knowledge access, skill development, opportunity creation" }
        "Governance" { "Fair laws, transparent systems, justice for all" }
        "Economy" { "Poverty reduction, financial inclusion, economic opportunity" }
        "Infrastructure" { "Efficient cities, sustainable transport, resilient systems" }
        "Science" { "Scientific breakthroughs, technological advancement, knowledge expansion" }
        "Culture" { "Cultural preservation, creative expression, social connection" }
        "Humanitarian" { "Rights protection, disaster relief, conflict resolution" }
        "Future" { "Space exploration, human enhancement, existential risk mitigation" }
    }

    Write-Host "  💡 Impact Type: " -NoNewline -ForegroundColor White
    Write-Host $categoryImpact -ForegroundColor Cyan

    Write-Host "`n╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
}

function Show-CategoryView {
    param(
        [string]$Category,
        [hashtable]$AllIdeas
    )

    Clear-Host

    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              CATEGORY VIEW: $($Category.ToUpper().PadRight(30))             ║" -ForegroundColor Yellow
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

    $categoryIdeas = $AllIdeas.Values | Where-Object { $_.Category -eq $Category } | Sort-Object Number

    if ($categoryIdeas.Count -eq 0) {
        Write-Host "`n  ❌ No ideas found in category: $Category" -ForegroundColor Red
        return
    }

    # Category summary
    $completed = ($categoryIdeas | Where-Object { $_.Status -eq "Complete" }).Count
    $inProgress = ($categoryIdeas | Where-Object { $_.Status -eq "In Progress" }).Count
    $avgProgress = [math]::Round(($categoryIdeas | Measure-Object -Property Progress -Average).Average, 1)
    $avgImpact = [math]::Round(($categoryIdeas | Measure-Object -Property Impact -Average).Average, 1)

    Write-Host "`n  📊 Summary:" -ForegroundColor White
    Write-Host "     Total Ideas: $($categoryIdeas.Count)" -ForegroundColor Cyan
    Write-Host "     Completed: $completed" -ForegroundColor Green
    Write-Host "     In Progress: $inProgress" -ForegroundColor Yellow
    Write-Host "     Average Progress: $avgProgress%" -ForegroundColor Cyan
    Write-Host "     Average Impact: $avgImpact/100" -ForegroundColor Cyan

    Write-Host "`n  📋 All Ideas in $Category`:" -ForegroundColor White

    foreach ($idea in $categoryIdeas) {
        $statusIcon = switch ($idea.Status) {
            "Complete" { "✅" }
            "In Progress" { "🔄" }
            "Blocked" { "🚫" }
            default { "⏳" }
        }

        $progress = [math]::Round($idea.Progress, 0)
        $progressColor = if ($progress -eq 100) { "Green" }elseif ($progress -ge 50) { "Yellow" }else { "Red" }

        Write-Host "`n  $statusIcon #$($idea.Number.ToString().PadLeft(3)): " -NoNewline
        Write-Host $idea.Name -ForegroundColor Cyan
        Write-Host "       Progress: " -NoNewline -ForegroundColor Gray
        Write-Host "$progress% " -NoNewline -ForegroundColor $progressColor
        Write-Host "| Impact: " -NoNewline -ForegroundColor Gray
        Write-Host "$($idea.Impact)/100 " -NoNewline -ForegroundColor White
        Write-Host "| Feasibility: " -NoNewline -ForegroundColor Gray
        Write-Host "$($idea.Feasibility)/100" -ForegroundColor White
    }

    Write-Host "`n╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
}

function Show-InteractiveMenu {
    param([hashtable]$ProgressData)

    while ($true) {
        Write-Host "`n┌─────────────────────────────────────────────────────────────┐" -ForegroundColor DarkCyan
        Write-Host "│  🎮 INTERACTIVE MENU                                        │" -ForegroundColor Yellow
        Write-Host "└─────────────────────────────────────────────────────────────┘" -ForegroundColor DarkCyan

        Write-Host "`n  Commands:" -ForegroundColor White
        Write-Host "     [1-500]     - View details for specific idea number" -ForegroundColor Cyan
        Write-Host "     [category]  - View all ideas in category" -ForegroundColor Cyan
        Write-Host "     [status]    - Filter by status (complete/progress/blocked)" -ForegroundColor Cyan
        Write-Host "     overview    - Return to overview" -ForegroundColor Cyan
        Write-Host "     refresh     - Reload progress data" -ForegroundColor Cyan
        Write-Host "     export      - Export to HTML report" -ForegroundColor Cyan
        Write-Host "     quit        - Exit" -ForegroundColor Cyan

        Write-Host "`n  Categories:" -ForegroundColor White
        Write-Host "     Healthcare | Environment | Education | Governance" -ForegroundColor Gray
        Write-Host "     Economy | Infrastructure | Science | Culture" -ForegroundColor Gray
        Write-Host "     Humanitarian | Future" -ForegroundColor Gray

        Write-Host "`n  ▶ " -NoNewline -ForegroundColor Yellow
        $input = Read-Host

        if ([string]::IsNullOrWhiteSpace($input)) {
            continue
        }

        $input = $input.Trim().ToLower()

        switch -Regex ($input) {
            '^\d+$' {
                # Idea number
                $ideaNum = [int]$input
                if ($ideaNum -ge 1 -and $ideaNum -le 500) {
                    Show-IdeaDetails -IdeaNumber $ideaNum -AllIdeas $ProgressData.AllIdeas
                } else {
                    Write-Host "`n  ❌ Idea number must be between 1 and 500" -ForegroundColor Red
                }
            }

            '^(healthcare|environment|education|governance|economy|infrastructure|science|culture|humanitarian|future)$' {
                # Category view
                $cat = (Get-Culture).TextInfo.ToTitleCase($input)
                Show-CategoryView -Category $cat -AllIdeas $ProgressData.AllIdeas
            }

            '^(complete|progress|blocked|started)$' {
                # Status filter
                $status = switch ($input) {
                    "complete" { "Complete" }
                    "progress" { "In Progress" }
                    "blocked" { "Blocked" }
                    "started" { "Not Started" }
                }

                $filtered = $ProgressData.AllIdeas.Values | Where-Object { $_.Status -eq $status } | Sort-Object Number

                Write-Host "`n  📋 Ideas with status '$status': $($filtered.Count)" -ForegroundColor Cyan
                foreach ($idea in $filtered | Select-Object -First 20) {
                    Write-Host "     #$($idea.Number): $($idea.Name)" -ForegroundColor White
                }

                if ($filtered.Count -gt 20) {
                    Write-Host "     ... and $($filtered.Count - 20) more" -ForegroundColor Gray
                }
            }

            '^overview$' {
                Show-ProgressOverview -ProgressData $ProgressData
            }

            '^refresh$' {
                Write-Host "`n  🔄 Refreshing data..." -ForegroundColor Yellow
                $ProgressData = Load-ProgressData
                Show-ProgressOverview -ProgressData $ProgressData
                Write-Host "`n  ✅ Data refreshed!" -ForegroundColor Green
            }

            '^export$' {
                Export-ToHTML -ProgressData $ProgressData
            }

            '^(quit|exit|q)$' {
                Write-Host "`n  👋 Goodbye! Keep changing the world! 🌍" -ForegroundColor Green
                return
            }

            default {
                Write-Host "`n  ❌ Unknown command. Type a number (1-500), category, or command." -ForegroundColor Red
            }
        }
    }
}

function Load-ProgressData {
    if (-not (Test-Path $ProgressFile)) {
        Write-Host "`n  ⚠️  Progress file not found. Creating initial data..." -ForegroundColor Yellow

        # Create initial structure
        return @{
            LastUpdated     = Get-Date
            TotalIdeas      = 500
            AverageProgress = 0
            ActiveProjects  = 0
            AllIdeas        = @{}
        }
    }

    try {
        $data = Get-Content $ProgressFile -Raw | ConvertFrom-Json -AsHashtable
        return $data
    } catch {
        Write-Host "`n  ❌ Error loading progress file: $_" -ForegroundColor Red
        return $null
    }
}

function Export-ToHTML {
    param([hashtable]$ProgressData)

    $htmlPath = "$PSScriptRoot\evidence\world-change-progress-report.html"

    Write-Host "`n  📝 Generating HTML report..." -ForegroundColor Yellow

    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>World Change Implementation Progress Report</title>
    <meta charset="UTF-8">
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            margin: 0;
            padding: 20px;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.3);
            padding: 40px;
        }
        h1 {
            color: #667eea;
            text-align: center;
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        .subtitle {
            text-align: center;
            color: #666;
            margin-bottom: 40px;
        }
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 40px;
        }
        .stat-card {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 10px;
            text-align: center;
        }
        .stat-value {
            font-size: 2em;
            font-weight: bold;
        }
        .stat-label {
            font-size: 0.9em;
            opacity: 0.9;
        }
        .category {
            margin-bottom: 30px;
        }
        .category-header {
            background: #f0f0f0;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 15px;
            cursor: pointer;
        }
        .category-header:hover {
            background: #e0e0e0;
        }
        .idea {
            padding: 15px;
            border-left: 4px solid #667eea;
            margin-bottom: 10px;
            background: #f9f9f9;
            border-radius: 5px;
        }
        .idea-number {
            color: #667eea;
            font-weight: bold;
        }
        .progress-bar {
            width: 100%;
            height: 20px;
            background: #e0e0e0;
            border-radius: 10px;
            overflow: hidden;
            margin-top: 10px;
        }
        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);
            transition: width 0.3s;
        }
        .status-complete { border-left-color: #28a745; }
        .status-progress { border-left-color: #ffc107; }
        .status-blocked { border-left-color: #dc3545; }
        .timestamp {
            text-align: center;
            color: #999;
            margin-top: 40px;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌍 World Change Implementation Progress</h1>
        <div class="subtitle">Autonomous AI System - Complete Report</div>

        <div class="stats">
            <div class="stat-card">
                <div class="stat-value">$($ProgressData.TotalIdeas)</div>
                <div class="stat-label">Total Ideas</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">$([math]::Round($ProgressData.AverageProgress, 1))%</div>
                <div class="stat-label">Average Progress</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">$($ProgressData.ActiveProjects)</div>
                <div class="stat-label">Active Projects</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">$(($ProgressData.AllIdeas.Values | Where-Object {$_.Status -eq "Complete"}).Count)</div>
                <div class="stat-label">Completed</div>
            </div>
        </div>
"@

    # Add ideas by category
    $categories = $ProgressData.AllIdeas.Values | Group-Object -Property Category | Sort-Object Name

    foreach ($cat in $categories) {
        $catProgress = [math]::Round(($cat.Group | Measure-Object -Property Progress -Average).Average, 1)

        $html += @"
        <div class="category">
            <div class="category-header">
                <h2>$($cat.Name) <span style="float:right;font-size:0.8em;">$catProgress% Complete</span></h2>
            </div>
"@

        foreach ($idea in ($cat.Group | Sort-Object Number)) {
            $statusClass = switch ($idea.Status) {
                "Complete" { "status-complete" }
                "In Progress" { "status-progress" }
                "Blocked" { "status-blocked" }
                default { "" }
            }

            $progress = [math]::Round($idea.Progress, 0)

            $html += @"
            <div class="idea $statusClass">
                <div><span class="idea-number">#$($idea.Number)</span> - $($idea.Name)</div>
                <div style="font-size:0.9em;color:#666;margin-top:5px;">$($idea.Description)</div>
                <div style="margin-top:10px;font-size:0.85em;">
                    <strong>Status:</strong> $($idea.Status) |
                    <strong>Feasibility:</strong> $($idea.Feasibility)/100 |
                    <strong>Impact:</strong> $($idea.Impact)/100
                </div>
                <div class="progress-bar">
                    <div class="progress-fill" style="width:$progress%"></div>
                </div>
            </div>
"@
        }

        $html += "</div>"
    }

    $html += @"
        <div class="timestamp">
            Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        </div>
    </div>
</body>
</html>
"@

    $html | Out-File $htmlPath -Encoding UTF8

    Write-Host "`n  ✅ HTML report generated: $htmlPath" -ForegroundColor Green
    Write-Host "  🌐 Opening in browser..." -ForegroundColor Cyan

    Start-Process $htmlPath
}

# Main execution
$progressData = Load-ProgressData

if (-not $progressData) {
    Write-Host "`n  ❌ Failed to load progress data. Exiting." -ForegroundColor Red
    exit 1
}

# Handle command-line parameters
if ($Details) {
    Show-IdeaDetails -IdeaNumber $Details -AllIdeas $progressData.AllIdeas
    if (-not $Interactive) { exit 0 }
}

if ($Category) {
    Show-CategoryView -Category $Category -AllIdeas $progressData.AllIdeas
    if (-not $Interactive) { exit 0 }
}

if ($StatusFilter) {
    $filtered = $progressData.AllIdeas.Values | Where-Object { $_.Status -eq $StatusFilter }
    Write-Host "`n  Ideas with status '$StatusFilter': $($filtered.Count)" -ForegroundColor Cyan
    foreach ($idea in $filtered) {
        Write-Host "     #$($idea.Number): $($idea.Name) - $([math]::Round($idea.Progress))%" -ForegroundColor White
    }
    if (-not $Interactive) { exit 0 }
}

if ($ExportToHTML) {
    Export-ToHTML -ProgressData $progressData
    if (-not $Interactive) { exit 0 }
}

# Show overview
Show-ProgressOverview -ProgressData $progressData

# Interactive mode
if ($Interactive) {
    Show-InteractiveMenu -ProgressData $progressData
}
