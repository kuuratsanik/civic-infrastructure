<#
.SYNOPSIS
    Self-Improvising AI Module - Creative problem-solving within constraints

.DESCRIPTION
    Enables AI to find novel solutions, create workarounds, adapt strategies,
    and handle unexpected situations creatively while maintaining safety.

.NOTES
    Requires: SafetyFramework.ps1, SelfLearning.ps1, SelfResearching.ps1
    Safety: All improvised solutions validated before execution
#>

#Requires -Version 5.1

Import-Module "$PSScriptRoot\..\safety\SafetyFramework.ps1" -Force
Import-Module "$PSScriptRoot\SelfLearning.ps1" -Force
Import-Module "$PSScriptRoot\SelfResearching.ps1" -Force

# ============================================
# CREATIVE PROBLEM SOLVING
# ============================================

function Invoke-CreativeSolution {
    <#
    .SYNOPSIS
        Find novel solution to a problem using creative AI reasoning
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Problem,

        [string[]]$Constraints = @(),

        [string[]]$AvailableResources = @(),

        [string[]]$FailedAttempts = @(),

        [int]$MaxAlternatives = 5
    )

    Write-Host "🎭 Self-Improvising: Creative problem-solving..." -ForegroundColor Cyan
    Write-Host "  Problem: $Problem" -ForegroundColor Gray

    # Safety boundary check
    $SafetyCheck = Invoke-SafetyCheck -Action "Improvise solution for: $Problem" -Context @{
        Scope       = "Problem Solving"
        Constraints = $Constraints
        Creative    = $true
    }

    if (-not $SafetyCheck.Approved) {
        Write-SafetyLog "IMPROVISATION_BLOCKED: Creative solution blocked" -Level WARN
        return $null
    }

    Write-Host "`n📋 Problem Analysis:" -ForegroundColor Yellow
    Write-Host "  Constraints: $($Constraints.Count)" -ForegroundColor Gray
    Write-Host "  Resources: $($AvailableResources.Count)" -ForegroundColor Gray
    Write-Host "  Failed Attempts: $($FailedAttempts.Count)" -ForegroundColor Gray

    # Step 1: Analyze the problem space
    Write-Host "`n🔍 Analyzing problem space..." -ForegroundColor Yellow
    $Analysis = Get-ProblemSpaceAnalysis -Problem $Problem -Constraints $Constraints

    # Step 2: Generate creative alternatives
    Write-Host "`n💡 Generating creative alternatives..." -ForegroundColor Yellow
    $Alternatives = New-CreativeAlternatives `
        -Problem $Problem `
        -Analysis $Analysis `
        -Constraints $Constraints `
        -AvailableResources $AvailableResources `
        -FailedAttempts $FailedAttempts `
        -MaxAlternatives $MaxAlternatives

    Write-Host "  ✅ Generated $($Alternatives.Count) alternatives" -ForegroundColor Green

    # Step 3: Evaluate alternatives
    Write-Host "`n📊 Evaluating alternatives..." -ForegroundColor Yellow
    $Evaluated = $Alternatives | ForEach-Object {
        $Score = Get-SolutionScore -Solution $_ -Problem $Problem -Constraints $Constraints
        $_ | Add-Member -NotePropertyName 'Score' -NotePropertyValue $Score -PassThru
    } | Sort-Object -Property Score -Descending

    # Step 4: Safety validation for top solutions
    Write-Host "`n🛡️ Safety validation..." -ForegroundColor Yellow
    $ValidSolutions = @()

    foreach ($Solution in $Evaluated) {
        $SafetyResult = Invoke-SafetyCheck -Action $Solution.Implementation -Context @{
            Creative = $true
            Novel    = $Solution.IsNovel
        }

        if ($SafetyResult.Approved) {
            $Solution | Add-Member -NotePropertyName 'SafetyApproved' -NotePropertyValue $true -PassThru
            $ValidSolutions += $Solution
        }
    }

    Write-Host "  ✅ $($ValidSolutions.Count) solutions passed safety" -ForegroundColor Green

    # Display results
    Write-Host "`n🎯 Creative Solutions Found:" -ForegroundColor Cyan
    for ($i = 0; $i -lt [Math]::Min(3, $ValidSolutions.Count); $i++) {
        $Sol = $ValidSolutions[$i]
        Write-Host "  $($i + 1). $($Sol.Description) (Score: $([math]::Round($Sol.Score, 2)))" -ForegroundColor Yellow
        Write-Host "     Novelty: $($Sol.NoveltyLevel) | Feasibility: $($Sol.Feasibility)" -ForegroundColor Gray
    }

    return $ValidSolutions
}

function Get-ProblemSpaceAnalysis {
    param([string]$Problem, [string[]]$Constraints)

    return @{
        ProblemType        = Get-ProblemType -Problem $Problem
        ComplexityLevel    = Get-ComplexityLevel -Problem $Problem
        ConstraintCount    = $Constraints.Count
        RequiresCreativity = $true
        SearchSpace        = "Large"
    }
}

function Get-ProblemType {
    param([string]$Problem)

    if ($Problem -match 'optimize|improve|faster') { return "Optimization" }
    if ($Problem -match 'fix|repair|broken') { return "Repair" }
    if ($Problem -match 'create|build|generate') { return "Creation" }
    if ($Problem -match 'find|locate|discover') { return "Discovery" }

    return "General"
}

function Get-ComplexityLevel {
    param([string]$Problem)

    $Words = $Problem.Split(' ').Count

    if ($Words -lt 5) { return "Low" }
    if ($Words -lt 10) { return "Medium" }
    return "High"
}

function New-CreativeAlternatives {
    param(
        [string]$Problem,
        [hashtable]$Analysis,
        [string[]]$Constraints,
        [string[]]$AvailableResources,
        [string[]]$FailedAttempts,
        [int]$MaxAlternatives
    )

    $Alternatives = @()

    # Strategy 1: Constraint relaxation
    if ($Constraints.Count -gt 0) {
        $Alternatives += New-ConstraintRelaxationSolution -Problem $Problem -Constraints $Constraints
    }

    # Strategy 2: Resource recombination
    if ($AvailableResources.Count -gt 0) {
        $Alternatives += New-ResourceRecombinationSolution -Problem $Problem -Resources $AvailableResources
    }

    # Strategy 3: Analogical reasoning
    $Alternatives += New-AnalogyBasedSolution -Problem $Problem

    # Strategy 4: Inverse approach
    $Alternatives += New-InverseApproachSolution -Problem $Problem

    # Strategy 5: Divide and conquer
    $Alternatives += New-DivideConquerSolution -Problem $Problem

    return $Alternatives | Select-Object -First $MaxAlternatives
}

function New-ConstraintRelaxationSolution {
    param([string]$Problem, [string[]]$Constraints)

    return @{
        Type           = "ConstraintRelaxation"
        Description    = "Relax least critical constraint to enable solution"
        Implementation = "Identify and relax constraint: $($Constraints[0])"
        NoveltyLevel   = "Medium"
        Feasibility    = "High"
        IsNovel        = $true
    }
}

function New-ResourceRecombinationSolution {
    param([string]$Problem, [string[]]$Resources)

    return @{
        Type           = "ResourceRecombination"
        Description    = "Combine existing resources in novel way"
        Implementation = "Use $($Resources[0]) + $($Resources[1]) together"
        NoveltyLevel   = "High"
        Feasibility    = "Medium"
        IsNovel        = $true
    }
}

function New-AnalogyBasedSolution {
    param([string]$Problem)

    return @{
        Type           = "Analogy"
        Description    = "Apply solution pattern from similar problem domain"
        Implementation = "Research similar problems and adapt solution"
        NoveltyLevel   = "Medium"
        Feasibility    = "High"
        IsNovel        = $true
    }
}

function New-InverseApproachSolution {
    param([string]$Problem)

    return @{
        Type           = "Inverse"
        Description    = "Solve the inverse problem instead"
        Implementation = "Instead of solving $Problem, prevent its opposite"
        NoveltyLevel   = "High"
        Feasibility    = "Low"
        IsNovel        = $true
    }
}

function New-DivideConquerSolution {
    param([string]$Problem)

    return @{
        Type           = "DivideConquer"
        Description    = "Break problem into smaller solvable pieces"
        Implementation = "Decompose into sub-problems and solve independently"
        NoveltyLevel   = "Low"
        Feasibility    = "High"
        IsNovel        = $false
    }
}

function Get-SolutionScore {
    param($Solution, [string]$Problem, [string[]]$Constraints)

    $Score = 0.0

    # Novelty bonus
    if ($Solution.IsNovel) { $Score += 30 }

    # Feasibility weight
    $Score += switch ($Solution.Feasibility) {
        'High' { 40 }
        'Medium' { 25 }
        'Low' { 10 }
        default { 0 }
    }

    # Novelty level
    $Score += switch ($Solution.NoveltyLevel) {
        'High' { 20 }
        'Medium' { 15 }
        'Low' { 10 }
        default { 0 }
    }

    # Type bonus
    $Score += switch ($Solution.Type) {
        'ResourceRecombination' { 10 }
        'Analogy' { 15 }
        'Inverse' { 5 }
        default { 10 }
    }

    return $Score
}

# ============================================
# ADAPTIVE STRATEGIES
# ============================================

function Invoke-AdaptiveStrategy {
    <#
    .SYNOPSIS
        Adapt approach based on changing context
    #>
    param(
        [Parameter(Mandatory)]
        [hashtable]$CurrentContext,

        [Parameter(Mandatory)]
        [hashtable]$NewContext,

        [string]$CurrentStrategy
    )

    Write-Host "🔄 Self-Improvising: Adapting strategy..." -ForegroundColor Cyan

    # Detect context changes
    $Changes = Compare-Context -Old $CurrentContext -New $NewContext

    Write-Host "  📊 Context changes detected: $($Changes.Count)" -ForegroundColor Yellow

    if ($Changes.Count -eq 0) {
        Write-Host "  ℹ️  No adaptation needed" -ForegroundColor Gray
        return $CurrentStrategy
    }

    # Determine new strategy
    $NewStrategy = Select-AdaptiveStrategy -Changes $Changes -CurrentStrategy $CurrentStrategy

    Write-Host "  ✅ Strategy adapted: $CurrentStrategy → $NewStrategy" -ForegroundColor Green

    return $NewStrategy
}

function Compare-Context {
    param([hashtable]$Old, [hashtable]$New)

    $Changes = @()

    foreach ($Key in $New.Keys) {
        if ($Old.ContainsKey($Key)) {
            if ($Old[$Key] -ne $New[$Key]) {
                $Changes += @{
                    Key      = $Key
                    OldValue = $Old[$Key]
                    NewValue = $New[$Key]
                    Change   = "Modified"
                }
            }
        } else {
            $Changes += @{
                Key      = $Key
                NewValue = $New[$Key]
                Change   = "Added"
            }
        }
    }

    return $Changes
}

function Select-AdaptiveStrategy {
    param([array]$Changes, [string]$CurrentStrategy)

    # Simple strategy selection based on changes
    if ($Changes.Count -gt 3) {
        return "CompleteRethink"
    } elseif ($Changes.Count -gt 1) {
        return "IncrementalAdapt"
    } else {
        return "MinorTweak"
    }
}

# ============================================
# WORKAROUND GENERATION
# ============================================

function New-Workaround {
    <#
    .SYNOPSIS
        Generate workaround when standard approach is blocked
    #>
    param(
        [Parameter(Mandatory)]
        [string]$BlockedApproach,

        [Parameter(Mandatory)]
        [string]$Goal,

        [string]$BlockReason
    )

    Write-Host "🔧 Self-Improvising: Generating workaround..." -ForegroundColor Cyan
    Write-Host "  Blocked: $BlockedApproach" -ForegroundColor Yellow
    Write-Host "  Goal: $Goal" -ForegroundColor Gray
    Write-Host "  Reason: $BlockReason" -ForegroundColor Gray

    # Research alternative approaches
    Write-Host "`n🔬 Researching alternatives..." -ForegroundColor Yellow
    $Alternatives = Find-Solution -Problem "Alternative to: $BlockedApproach for goal: $Goal"

    # Generate creative workarounds
    $Workarounds = @()

    # Workaround 1: Different tool
    $Workarounds += @{
        Type           = "DifferentTool"
        Description    = "Use alternative tool to achieve same goal"
        Implementation = "Research and use tool similar to $BlockedApproach"
        Complexity     = "Low"
    }

    # Workaround 2: Manual process
    $Workarounds += @{
        Type           = "ManualProcess"
        Description    = "Break into manual steps"
        Implementation = "Decompose $BlockedApproach into manual steps"
        Complexity     = "Medium"
    }

    # Workaround 3: Indirect approach
    $Workarounds += @{
        Type           = "IndirectApproach"
        Description    = "Achieve goal through indirect means"
        Implementation = "Find indirect path to goal"
        Complexity     = "High"
    }

    Write-Host "`n💡 Generated $($Workarounds.Count) workarounds" -ForegroundColor Green

    return $Workarounds
}

# ============================================
# EMERGENCY HANDLING
# ============================================

function Invoke-EmergencyImprovisation {
    <#
    .SYNOPSIS
        Handle unexpected emergency situations with improvised solutions
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Emergency,

        [int]$TimeConstraintSeconds = 60,

        [string[]]$ImmediateResources = @()
    )

    Write-Host "🚨 Self-Improvising: Emergency mode!" -ForegroundColor Red
    Write-Host "  Emergency: $Emergency" -ForegroundColor Yellow
    Write-Host "  Time Constraint: $TimeConstraintSeconds seconds" -ForegroundColor Yellow

    # Quick safety check
    $SafetyCheck = Invoke-SafetyCheck -Action "Emergency improvisation: $Emergency" -Context @{
        Emergency      = $true
        TimeConstraint = $TimeConstraintSeconds
    }

    if (-not $SafetyCheck.Approved) {
        Write-Host "  🛑 Emergency action blocked by safety" -ForegroundColor Red
        return $null
    }

    # Generate immediate action plan
    $ActionPlan = @{
        Immediate = "Assess situation and stabilize"
        ShortTerm = "Implement temporary fix"
        LongTerm  = "Research permanent solution"
        Fallback  = "Manual intervention required"
    }

    Write-Host "`n📋 Emergency Action Plan:" -ForegroundColor Cyan
    Write-Host "  Immediate: $($ActionPlan.Immediate)" -ForegroundColor Yellow
    Write-Host "  Short-term: $($ActionPlan.ShortTerm)" -ForegroundColor Yellow
    Write-Host "  Long-term: $($ActionPlan.LongTerm)" -ForegroundColor Gray

    return $ActionPlan
}

# ============================================
# EXPORT MODULE MEMBERS
# ============================================

Export-ModuleMember -Function @(
    'Invoke-CreativeSolution',
    'Invoke-AdaptiveStrategy',
    'New-Workaround',
    'Invoke-EmergencyImprovisation'
)
