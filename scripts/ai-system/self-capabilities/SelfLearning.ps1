<#
.SYNOPSIS
    Self-Learning AI Module - Learn from experience

.DESCRIPTION
    Enables AI to learn from past decisions, mistakes, and successes.
    Uses reinforcement learning principles with safety boundaries.

.NOTES
    Requires: SafetyFramework.ps1
    Safety: All learning must pass safety validation
#>

#Requires -Version 5.1

Import-Module "$PSScriptRoot\..\safety\SafetyFramework.ps1" -Force

# ============================================
# LEARNING STORAGE
# ============================================

$script:LearningDB = "ai-system\data\learning\learning.db.json"
$script:PatternDB = "ai-system\data\learning\patterns.db.json"
$script:SuccessDB = "ai-system\data\learning\successes.db.json"
$script:FailureDB = "ai-system\data\learning\failures.db.json"

# ============================================
# LEARNING CLASSES
# ============================================

class Experience {
    [string]$Id
    [datetime]$Timestamp
    [string]$Context
    [string]$Action
    [string]$Outcome
    [string]$Result # Success, Failure, Partial
    [double]$ConfidenceScore
    [hashtable]$Metrics
    [string[]]$Lessons

    Experience() {
        $this.Id = (New-Guid).ToString()
        $this.Timestamp = Get-Date
        $this.Metrics = @{}
        $this.Lessons = @()
    }
}

class Pattern {
    [string]$Id
    [string]$PatternType # Success, Failure, Optimization
    [string]$Context
    [string]$Trigger
    [string]$BestAction
    [double]$SuccessRate
    [int]$Occurrences
    [datetime]$FirstSeen
    [datetime]$LastSeen
    [string[]]$RelatedPatterns

    Pattern() {
        $this.Id = (New-Guid).ToString()
        $this.FirstSeen = Get-Date
        $this.LastSeen = Get-Date
        $this.RelatedPatterns = @()
    }
}

class KnowledgeBase {
    [hashtable]$Patterns
    [hashtable]$Experiences
    [hashtable]$BestPractices
    [hashtable]$Heuristics

    KnowledgeBase() {
        $this.Patterns = @{}
        $this.Experiences = @{}
        $this.BestPractices = @{}
        $this.Heuristics = @{}
    }

    [void] Save([string]$Path) {
        $Data = @{
            Patterns      = $this.Patterns
            Experiences   = $this.Experiences
            BestPractices = $this.BestPractices
            Heuristics    = $this.Heuristics
            LastUpdated   = Get-Date
        }

        $Data | ConvertTo-Json -Depth 10 | Set-Content $Path
    }

    static [KnowledgeBase] Load([string]$Path) {
        if (Test-Path $Path) {
            $Data = Get-Content $Path | ConvertFrom-Json
            $KB = [KnowledgeBase]::new()
            $KB.Patterns = $Data.Patterns
            $KB.Experiences = $Data.Experiences
            $KB.BestPractices = $Data.BestPractices
            $KB.Heuristics = $Data.Heuristics
            return $KB
        }
        return [KnowledgeBase]::new()
    }
}

# ============================================
# LEARNING FUNCTIONS
# ============================================

function Initialize-LearningSystem {
    <#
    .SYNOPSIS
        Initialize learning system and knowledge bases
    #>
    [CmdletBinding()]
    param()

    Write-Host "🧠 Initializing Self-Learning System..." -ForegroundColor Cyan

    # Create learning directories
    $Dirs = @(
        "ai-system\data\learning",
        "ai-system\data\learning\experiences",
        "ai-system\data\learning\patterns",
        "ai-system\logs\learning"
    )

    foreach ($Dir in $Dirs) {
        if (-not (Test-Path $Dir)) {
            New-Item -Path $Dir -ItemType Directory -Force | Out-Null
        }
    }

    # Initialize knowledge base
    $KB = [KnowledgeBase]::Load($script:LearningDB)

    Write-Host "✅ Learning system initialized" -ForegroundColor Green
    Write-Host "  📊 Patterns: $($KB.Patterns.Count)" -ForegroundColor Yellow
    Write-Host "  📚 Experiences: $($KB.Experiences.Count)" -ForegroundColor Yellow

    return $KB
}

function Add-Experience {
    <#
    .SYNOPSIS
        Record a new experience for learning
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Context,

        [Parameter(Mandatory)]
        [string]$Action,

        [Parameter(Mandatory)]
        [string]$Outcome,

        [ValidateSet('Success', 'Failure', 'Partial')]
        [string]$Result = 'Success',

        [double]$ConfidenceScore = 0.5,

        [hashtable]$Metrics = @{}
    )

    # Safety check: Ensure we're learning from safe operations
    $SafetyCheck = Invoke-SafetyCheck -Action "Record learning experience: $Action" -Context @{}

    if (-not $SafetyCheck.Approved) {
        Write-SafetyLog "LEARNING_BLOCKED: Cannot learn from unsafe action: $Action" -Level WARN
        return $null
    }

    $Exp = [Experience]::new()
    $Exp.Context = $Context
    $Exp.Action = $Action
    $Exp.Outcome = $Outcome
    $Exp.Result = $Result
    $Exp.ConfidenceScore = $ConfidenceScore
    $Exp.Metrics = $Metrics

    # Extract lessons
    $Exp.Lessons = Get-LessonsLearned -Experience $Exp

    # Save to database
    $ExpFile = Join-Path "ai-system\data\learning\experiences" "$($Exp.Id).json"
    $Exp | ConvertTo-Json -Depth 5 | Set-Content $ExpFile

    # Update knowledge base
    Update-KnowledgeBase -Experience $Exp

    Write-Host "📝 Recorded experience: $Context → $Result" -ForegroundColor Cyan

    return $Exp
}

function Get-LessonsLearned {
    param([Experience]$Experience)

    $Lessons = @()

    # Analyze outcome
    switch ($Experience.Result) {
        'Success' {
            $Lessons += "Action '$($Experience.Action)' succeeded in context '$($Experience.Context)'"

            if ($Experience.ConfidenceScore -gt 0.8) {
                $Lessons += "High confidence action - can be reused"
            }
        }

        'Failure' {
            $Lessons += "Action '$($Experience.Action)' failed in context '$($Experience.Context)'"
            $Lessons += "Avoid this action in similar contexts"

            # Extract failure reasons
            if ($Experience.Outcome -match 'timeout') {
                $Lessons += "Consider increasing timeout or optimizing operation"
            }
            if ($Experience.Outcome -match 'permission|access denied') {
                $Lessons += "Check permissions before similar actions"
            }
            if ($Experience.Outcome -match 'not found|missing') {
                $Lessons += "Verify prerequisites before execution"
            }
        }

        'Partial' {
            $Lessons += "Action completed with issues - investigate root cause"
        }
    }

    # Analyze metrics
    if ($Experience.Metrics.ContainsKey('Duration')) {
        $Duration = $Experience.Metrics.Duration
        if ($Duration -gt 300) {
            $Lessons += "Long duration ($Duration s) - consider optimization"
        }
    }

    return $Lessons
}

function Update-KnowledgeBase {
    param([Experience]$Experience)

    $KB = [KnowledgeBase]::Load($script:LearningDB)

    # Add experience
    $KB.Experiences[$Experience.Id] = $Experience

    # Detect patterns
    $DetectedPatterns = Find-Patterns -Experience $Experience -KnowledgeBase $KB

    foreach ($Pattern in $DetectedPatterns) {
        if ($KB.Patterns.ContainsKey($Pattern.Id)) {
            # Update existing pattern
            $KB.Patterns[$Pattern.Id].Occurrences++
            $KB.Patterns[$Pattern.Id].LastSeen = Get-Date
        } else {
            # New pattern
            $KB.Patterns[$Pattern.Id] = $Pattern
        }
    }

    # Update best practices
    if ($Experience.Result -eq 'Success' -and $Experience.ConfidenceScore -gt 0.7) {
        $PracticeKey = "$($Experience.Context):$($Experience.Action)"

        if (-not $KB.BestPractices.ContainsKey($PracticeKey)) {
            $KB.BestPractices[$PracticeKey] = @{
                Action            = $Experience.Action
                Context           = $Experience.Context
                SuccessCount      = 1
                TotalCount        = 1
                AverageConfidence = $Experience.ConfidenceScore
            }
        } else {
            $Practice = $KB.BestPractices[$PracticeKey]
            $Practice.SuccessCount++
            $Practice.TotalCount++
            $Practice.AverageConfidence = ($Practice.AverageConfidence + $Experience.ConfidenceScore) / 2
        }
    }

    # Save knowledge base
    $KB.Save($script:LearningDB)
}

function Find-Patterns {
    param(
        [Experience]$Experience,
        [KnowledgeBase]$KnowledgeBase
    )

    $Patterns = @()

    # Find similar past experiences
    $Similar = $KnowledgeBase.Experiences.Values | Where-Object {
        $_.Context -eq $Experience.Context -or
        $_.Action -eq $Experience.Action
    }

    if ($Similar.Count -ge 3) {
        # Pattern detected
        $Pattern = [Pattern]::new()
        $Pattern.PatternType = $Experience.Result
        $Pattern.Context = $Experience.Context
        $Pattern.BestAction = $Experience.Action
        $Pattern.Occurrences = $Similar.Count

        # Calculate success rate
        $Successes = ($Similar | Where-Object { $_.Result -eq 'Success' }).Count
        $Pattern.SuccessRate = $Successes / $Similar.Count

        $Patterns += $Pattern
    }

    return $Patterns
}

function Get-BestAction {
    <#
    .SYNOPSIS
        Get the best action for a context based on learned knowledge
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Context,

        [string[]]$AvailableActions
    )

    $KB = [KnowledgeBase]::Load($script:LearningDB)

    # Find best practices for this context
    $Recommendations = @()

    foreach ($Practice in $KB.BestPractices.GetEnumerator()) {
        if ($Practice.Value.Context -eq $Context) {
            $SuccessRate = $Practice.Value.SuccessCount / $Practice.Value.TotalCount

            $Recommendations += @{
                Action      = $Practice.Value.Action
                SuccessRate = $SuccessRate
                Confidence  = $Practice.Value.AverageConfidence
                Score       = $SuccessRate * $Practice.Value.AverageConfidence
            }
        }
    }

    # Return best recommendation
    if ($Recommendations.Count -gt 0) {
        $Best = $Recommendations | Sort-Object -Property Score -Descending | Select-Object -First 1

        Write-Host "💡 Learning recommendation: $($Best.Action) (Score: $([math]::Round($Best.Score, 2)))" -ForegroundColor Green

        return $Best
    }

    return $null
}

function Optimize-DecisionMaking {
    <#
    .SYNOPSIS
        Use machine learning to optimize decision-making
    #>
    param(
        [string]$DecisionContext
    )

    $KB = [KnowledgeBase]::Load($script:LearningDB)

    # Analyze past decisions in similar context
    $RelevantExperiences = $KB.Experiences.Values | Where-Object {
        $_.Context -like "*$DecisionContext*"
    }

    if ($RelevantExperiences.Count -eq 0) {
        Write-Host "ℹ️ No learning data for context: $DecisionContext" -ForegroundColor Yellow
        return $null
    }

    # Calculate optimization metrics
    $Successes = ($RelevantExperiences | Where-Object { $_.Result -eq 'Success' }).Count
    $Failures = ($RelevantExperiences | Where-Object { $_.Result -eq 'Failure' }).Count
    $SuccessRate = $Successes / $RelevantExperiences.Count

    # Find most successful actions
    $ActionStats = $RelevantExperiences | Group-Object -Property Action | ForEach-Object {
        $Successes = ($_.Group | Where-Object { $_.Result -eq 'Success' }).Count

        @{
            Action      = $_.Name
            Count       = $_.Count
            Successes   = $Successes
            SuccessRate = $Successes / $_.Count
        }
    } | Sort-Object -Property SuccessRate -Descending

    return @{
        Context            = $DecisionContext
        TotalExperiences   = $RelevantExperiences.Count
        OverallSuccessRate = $SuccessRate
        BestActions        = $ActionStats | Select-Object -First 3
    }
}

function Invoke-ReinforcementLearning {
    <#
    .SYNOPSIS
        Apply reinforcement learning to improve over time
    #>
    param(
        [string]$Action,
        [double]$Reward, # -1 to +1
        [hashtable]$State
    )

    # Safety validation
    $SafetyCheck = Invoke-SafetyCheck -Action "Apply reinforcement learning: $Action" -Context $State

    if (-not $SafetyCheck.Approved) {
        Write-SafetyLog "LEARNING_BLOCKED: Unsafe reinforcement learning action: $Action" -Level WARN
        return
    }

    # Q-learning update (simplified)
    $KB = [KnowledgeBase]::Load($script:LearningDB)

    $StateKey = ($State.GetEnumerator() | Sort-Object Key | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ","
    $ActionKey = "$StateKey:$Action"

    if (-not $KB.Heuristics.ContainsKey($ActionKey)) {
        $KB.Heuristics[$ActionKey] = @{
            State       = $StateKey
            Action      = $Action
            QValue      = 0.0
            UpdateCount = 0
        }
    }

    # Update Q-value with learning rate and discount factor
    $LearningRate = 0.1
    $DiscountFactor = 0.9

    $CurrentQ = $KB.Heuristics[$ActionKey].QValue
    $NewQ = $CurrentQ + $LearningRate * ($Reward - $CurrentQ)

    $KB.Heuristics[$ActionKey].QValue = $NewQ
    $KB.Heuristics[$ActionKey].UpdateCount++

    $KB.Save($script:LearningDB)

    Write-Host "🎓 Reinforcement learning: Q($Action) = $([math]::Round($NewQ, 3))" -ForegroundColor Magenta
}

# ============================================
# EXPORT MODULE MEMBERS
# ============================================

Export-ModuleMember -Function @(
    'Initialize-LearningSystem',
    'Add-Experience',
    'Get-BestAction',
    'Optimize-DecisionMaking',
    'Invoke-ReinforcementLearning'
)
