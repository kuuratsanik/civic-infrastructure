<#
.SYNOPSIS
    Self-Improving AI Module - Autonomous code optimization

.DESCRIPTION
    Enables AI to improve its own code, algorithms, and performance.
    Includes validation gates and rollback safety.
#>

#Requires -Version 5.1

Import-Module "$PSScriptRoot\..\safety\SafetyFramework.ps1" -Force

function Optimize-Code {
    <#
    .SYNOPSIS
        Analyze and optimize code for better performance
    #>
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [string[]]$OptimizationTargets = @('Performance', 'Memory', 'Readability')
    )

    Write-Host "🔧 Self-Improving: Optimizing $FilePath" -ForegroundColor Cyan

    # Safety check
    $SafetyCheck = Invoke-SafetyCheck -Action "Optimize code file: $FilePath" -Context @{
        Scope        = "File"
        Reversible   = $true
        BackupExists = $true
    }

    if (-not $SafetyCheck.Approved) {
        Write-SafetyLog "IMPROVEMENT_BLOCKED: Cannot optimize: $FilePath" -Level WARN
        return $null
    }

    # Create backup
    $BackupPath = "$FilePath.backup-$(Get-Date -Format 'yyyyMMddHHmmss')"
    Copy-Item -Path $FilePath -Destination $BackupPath

    $Optimizations = @()

    # Analyze current code
    $CodeMetrics = Measure-CodeQuality -FilePath $FilePath

    # Apply optimizations
    foreach ($Target in $OptimizationTargets) {
        $Result = switch ($Target) {
            'Performance' { Optimize-Performance -FilePath $FilePath }
            'Memory' { Optimize-Memory -FilePath $FilePath }
            'Readability' { Optimize-Readability -FilePath $FilePath }
        }

        if ($Result) { $Optimizations += $Result }
    }

    # Measure improvements
    $NewMetrics = Measure-CodeQuality -FilePath $FilePath
    $Improvement = Compare-Metrics -Before $CodeMetrics -After $NewMetrics

    # Rollback if worse
    if ($Improvement.Overall -lt 0) {
        Write-Host "  ⚠️ Optimization made code worse, rolling back" -ForegroundColor Yellow
        Copy-Item -Path $BackupPath -Destination $FilePath -Force
        return $null
    }

    Write-Host "  ✅ Code improved by $([math]::Round($Improvement.Overall * 100, 1))%" -ForegroundColor Green

    return @{
        File          = $FilePath
        Optimizations = $Optimizations
        Improvement   = $Improvement
        Backup        = $BackupPath
    }
}

function Measure-CodeQuality {
    param([string]$FilePath)

    # Simplified code quality metrics
    $Content = Get-Content $FilePath -Raw
    $Lines = (Get-Content $FilePath).Count

    return @{
        Lines           = $Lines
        Complexity      = Measure-Complexity -Code $Content
        Duplication     = Measure-Duplication -Code $Content
        Maintainability = Measure-Maintainability -Code $Content
    }
}

function Measure-Complexity {
    param([string]$Code)

    # Count decision points (if, switch, for, while, etc.)
    $IfCount = ([regex]::Matches($Code, '\bif\b')).Count
    $SwitchCount = ([regex]::Matches($Code, '\bswitch\b')).Count
    $LoopCount = ([regex]::Matches($Code, '\b(for|while|foreach)\b')).Count

    return $IfCount + $SwitchCount + $LoopCount
}

function Measure-Duplication {
    param([string]$Code)

    # Very simplified duplication detection
    $Lines = $Code -split "`n"
    $Unique = $Lines | Select-Object -Unique

    return 1 - ($Unique.Count / $Lines.Count)
}

function Measure-Maintainability {
    param([string]$Code)

    # Heuristic based on comments, naming, structure
    $CommentLines = ([regex]::Matches($Code, '#.*$', [Text.RegularExpressions.RegexOptions]::Multiline)).Count
    $TotalLines = ($Code -split "`n").Count

    $CommentRatio = $CommentLines / $TotalLines

    # Good maintainability if 10-30% comments
    return [math]::Min(1.0, $CommentRatio / 0.2)
}

function Compare-Metrics {
    param($Before, $After)

    # Calculate overall improvement
    $Improvements = @{
        Complexity      = if ($Before.Complexity -gt 0) { ($Before.Complexity - $After.Complexity) / $Before.Complexity } else { 0 }
        Duplication     = ($Before.Duplication - $After.Duplication) / [math]::Max($Before.Duplication, 0.01)
        Maintainability = ($After.Maintainability - $Before.Maintainability) / [math]::Max($Before.Maintainability, 0.01)
    }

    $Improvements.Overall = ($Improvements.Complexity + $Improvements.Duplication + $Improvements.Maintainability) / 3

    return $Improvements
}

# ============================================
# EXPORT MODULE MEMBERS
# ============================================

Export-ModuleMember -Function @(
    'Optimize-Code',
    'Measure-CodeQuality'
)
