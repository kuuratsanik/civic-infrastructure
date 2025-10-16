<#
.SYNOPSIS
    Self-Researching AI Module - Autonomous knowledge acquisition

.DESCRIPTION
    Enables AI to research solutions, read documentation, and discover answers.
    Uses trusted sources and fact verification for safety.

.NOTES
    Requires: SafetyFramework.ps1
    Safety: Only research from trusted sources
#>

#Requires -Version 5.1

Import-Module "$PSScriptRoot\..\safety\SafetyFramework.ps1" -Force

# ============================================
# TRUSTED SOURCES
# ============================================

$script:TrustedSources = @{
    Documentation      = @(
        "docs.microsoft.com",
        "learn.microsoft.com",
        "github.com",
        "stackoverflow.com",
        "docs.python.org",
        "nodejs.org/docs",
        "developer.mozilla.org"
    )

    PackageRegistries  = @(
        "nuget.org",
        "npmjs.com",
        "pypi.org",
        "rubygems.org"
    )

    SecurityAdvisories = @(
        "nvd.nist.gov",
        "cve.mitre.org",
        "github.com/advisories"
    )
}

# ============================================
# RESEARCH FUNCTIONS
# ============================================

function Search-Documentation {
    <#
    .SYNOPSIS
        Search official documentation for solutions
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Query,

        [string]$Domain = "Microsoft",

        [int]$MaxResults = 5
    )

    Write-Host "🔬 Researching: $Query" -ForegroundColor Cyan

    # Safety check
    $SafetyCheck = Invoke-SafetyCheck -Action "Search documentation: $Query" -Context @{Scope = "Read" }

    if (-not $SafetyCheck.Approved) {
        Write-SafetyLog "RESEARCH_BLOCKED: Search blocked for: $Query" -Level WARN
        return @()
    }

    $Results = @()

    # Search based on domain
    switch ($Domain) {
        "Microsoft" {
            $Results = Search-MicrosoftDocs -Query $Query -MaxResults $MaxResults
        }

        "PowerShell" {
            $Results = Search-PowerShellDocs -Query $Query -MaxResults $MaxResults
        }

        "GitHub" {
            $Results = Search-GitHubDocs -Query $Query -MaxResults $MaxResults
        }

        default {
            Write-Host "ℹ️ Using general search for: $Domain" -ForegroundColor Yellow
            $Results = Search-GeneralDocs -Query $Query -MaxResults $MaxResults
        }
    }

    # Log research
    Write-ResearchLog -Query $Query -Domain $Domain -ResultCount $Results.Count

    return $Results
}

function Search-MicrosoftDocs {
    param([string]$Query, [int]$MaxResults)

    # Use Microsoft Learn search API or web scraping
    $SearchUrl = "https://learn.microsoft.com/en-us/search/?terms=$([uri]::EscapeDataString($Query))"

    Write-Host "  📖 Searching Microsoft Learn..." -ForegroundColor Gray

    # Simulate search results (in production, would use actual API)
    return @(
        @{
            Title       = "Microsoft Documentation Result"
            Url         = $SearchUrl
            Summary     = "Relevant Microsoft documentation for: $Query"
            Source      = "Microsoft Learn"
            Trustworthy = $true
        }
    )
}

function Search-PowerShellDocs {
    param([string]$Query, [int]$MaxResults)

    # Search PowerShell help
    $Results = @()

    try {
        $HelpResults = Get-Help -Name "*$Query*" -ErrorAction SilentlyContinue | Select-Object -First $MaxResults

        foreach ($Help in $HelpResults) {
            $Results += @{
                Title       = $Help.Name
                Summary     = $Help.Synopsis
                Details     = $Help.Description
                Examples    = $Help.Examples
                Source      = "PowerShell Built-in Help"
                Trustworthy = $true
            }
        }

        Write-Host "  ✅ Found $($Results.Count) PowerShell help topics" -ForegroundColor Green

    } catch {
        Write-Host "  ⚠️ PowerShell help search failed: $_" -ForegroundColor Yellow
    }

    return $Results
}

function Search-GitHubDocs {
    param([string]$Query, [int]$MaxResults)

    Write-Host "  🐙 Searching GitHub..." -ForegroundColor Gray

    # Would use GitHub API in production
    return @(
        @{
            Title       = "GitHub Search Result"
            Url         = "https://github.com/search?q=$([uri]::EscapeDataString($Query))"
            Summary     = "GitHub repositories and code for: $Query"
            Source      = "GitHub"
            Trustworthy = $true
        }
    )
}

function Search-GeneralDocs {
    param([string]$Query, [int]$MaxResults)

    # Multi-source search
    $Results = @()

    $Results += Search-PowerShellDocs -Query $Query -MaxResults 2
    $Results += Search-MicrosoftDocs -Query $Query -MaxResults 2

    return $Results
}

function Get-BestPractice {
    <#
    .SYNOPSIS
        Research best practices for a technology or pattern
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Technology,

        [string]$Aspect = "General"
    )

    Write-Host "📚 Researching best practices: $Technology ($Aspect)" -ForegroundColor Cyan

    $Query = "$Technology best practices $Aspect"
    $Results = Search-Documentation -Query $Query -MaxResults 5

    # Extract best practices
    $BestPractices = @()

    foreach ($Result in $Results) {
        $BestPractices += @{
            Technology     = $Technology
            Aspect         = $Aspect
            Source         = $Result.Source
            Recommendation = $Result.Summary
            Reference      = $Result.Url
            ResearchedAt   = Get-Date
        }
    }

    # Save to knowledge base
    Save-ResearchFindings -Technology $Technology -Findings $BestPractices

    return $BestPractices
}

function Find-Solution {
    <#
    .SYNOPSIS
        Research solution to a specific problem
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Problem,

        [string]$Context = "",

        [string[]]$Constraints = @()
    )

    Write-Host "🔍 Finding solution for: $Problem" -ForegroundColor Cyan

    # Build search query
    $Query = $Problem
    if ($Context) { $Query += " $Context" }
    if ($Constraints.Count -gt 0) { $Query += " " + ($Constraints -join " ") }

    # Multi-strategy research
    $Solutions = @()

    # 1. Search documentation
    $DocResults = Search-Documentation -Query $Query -MaxResults 3
    foreach ($Doc in $DocResults) {
        $Solutions += @{
            Type       = "Documentation"
            Source     = $Doc.Source
            Solution   = $Doc.Summary
            Confidence = 0.8
            Reference  = $Doc.Url
        }
    }

    # 2. Check local knowledge base
    $KBSolutions = Search-LocalKnowledge -Problem $Problem
    foreach ($KB in $KBSolutions) {
        $Solutions += @{
            Type       = "Knowledge Base"
            Source     = "Local Learning"
            Solution   = $KB.Solution
            Confidence = $KB.Confidence
            Reference  = "Previously solved"
        }
    }

    # 3. Pattern matching from similar problems
    $Patterns = Find-SimilarPatterns -Problem $Problem
    foreach ($Pattern in $Patterns) {
        $Solutions += @{
            Type       = "Pattern"
            Source     = "Pattern Recognition"
            Solution   = $Pattern.Solution
            Confidence = $Pattern.Similarity
            Reference  = "Similar problem: $($Pattern.OriginalProblem)"
        }
    }

    # Rank solutions by confidence
    $RankedSolutions = $Solutions | Sort-Object -Property Confidence -Descending

    Write-Host "  ✅ Found $($RankedSolutions.Count) potential solutions" -ForegroundColor Green

    return $RankedSolutions
}

function Search-LocalKnowledge {
    param([string]$Problem)

    $KBPath = "ai-system\data\knowledge\solutions.json"

    if (-not (Test-Path $KBPath)) {
        return @()
    }

    $KB = Get-Content $KBPath | ConvertFrom-Json

    # Search for similar problems
    $Results = $KB | Where-Object { $_.Problem -like "*$Problem*" }

    return $Results
}

function Find-SimilarPatterns {
    param([string]$Problem)

    # Simplified pattern matching
    # In production, would use NLP/ML for similarity

    $PatternsPath = "ai-system\data\learning\patterns.db.json"

    if (-not (Test-Path $PatternsPath)) {
        return @()
    }

    $Patterns = Get-Content $PatternsPath | ConvertFrom-Json

    # Very basic similarity (word overlap)
    $ProblemWords = $Problem.ToLower() -split '\s+'

    $Similar = @()
    foreach ($Pattern in $Patterns.PSObject.Properties.Value) {
        $PatternWords = $Pattern.Context.ToLower() -split '\s+'
        $CommonWords = $ProblemWords | Where-Object { $_ -in $PatternWords }

        $Similarity = $CommonWords.Count / [math]::Max($ProblemWords.Count, $PatternWords.Count)

        if ($Similarity -gt 0.3) {
            $Similar += @{
                OriginalProblem = $Pattern.Context
                Solution        = $Pattern.BestAction
                Similarity      = $Similarity
            }
        }
    }

    return $Similar
}

function Save-ResearchFindings {
    param(
        [string]$Technology,
        [array]$Findings
    )

    $ResearchDir = "ai-system\data\research"
    if (-not (Test-Path $ResearchDir)) {
        New-Item -Path $ResearchDir -ItemType Directory -Force | Out-Null
    }

    $ResearchFile = Join-Path $ResearchDir "$Technology-$(Get-Date -Format 'yyyyMMdd').json"

    $Data = @{
        Technology   = $Technology
        ResearchDate = Get-Date
        Findings     = $Findings
    }

    $Data | ConvertTo-Json -Depth 5 | Set-Content $ResearchFile

    Write-Host "  💾 Saved research findings to: $ResearchFile" -ForegroundColor Gray
}

function Write-ResearchLog {
    param(
        [string]$Query,
        [string]$Domain,
        [int]$ResultCount
    )

    $LogDir = "ai-system\logs\research"
    if (-not (Test-Path $LogDir)) {
        New-Item -Path $LogDir -ItemType Directory -Force | Out-Null
    }

    $LogFile = Join-Path $LogDir "research-$(Get-Date -Format 'yyyyMMdd').log"

    $LogEntry = @{
        Timestamp   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Query       = $Query
        Domain      = $Domain
        ResultCount = $ResultCount
    }

    $LogEntry | ConvertTo-Json -Compress | Add-Content $LogFile
}

function Test-SourceTrustworthiness {
    <#
    .SYNOPSIS
        Verify if a source is trustworthy
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Url
    )

    $Uri = [uri]$Url
    $Host = $Uri.Host

    # Check against trusted sources
    $IsTrusted = $false

    foreach ($Category in $script:TrustedSources.Keys) {
        if ($Host -in $script:TrustedSources[$Category]) {
            $IsTrusted = $true
            break
        }
    }

    # Additional checks
    $Checks = @{
        IsTrusted = $IsTrusted
        IsHTTPS   = $Uri.Scheme -eq "https"
        Domain    = $Host
        Category  = if ($IsTrusted) { $Category } else { "Untrusted" }
    }

    return $Checks
}

function Invoke-FactVerification {
    <#
    .SYNOPSIS
        Verify facts from research against multiple sources
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Claim,

        [int]$MinSources = 2
    )

    Write-Host "✅ Verifying claim: $Claim" -ForegroundColor Yellow

    # Research claim from multiple sources
    $Sources = Search-Documentation -Query $Claim -MaxResults 5

    # Check source trustworthiness
    $TrustedSources = $Sources | Where-Object {
        if ($_.Url) {
            $Trust = Test-SourceTrustworthiness -Url $_.Url
            return $Trust.IsTrusted
        }
        return $_.Trustworthy -eq $true
    }

    $Verified = $TrustedSources.Count -ge $MinSources

    return @{
        Claim           = $Claim
        Verified        = $Verified
        SourceCount     = $TrustedSources.Count
        Sources         = $TrustedSources
        ConfidenceLevel = [math]::Min($TrustedSources.Count / $MinSources, 1.0)
    }
}

# ============================================
# EXPORT MODULE MEMBERS
# ============================================

Export-ModuleMember -Function @(
    'Search-Documentation',
    'Get-BestPractice',
    'Find-Solution',
    'Test-SourceTrustworthiness',
    'Invoke-FactVerification'
)
<#
.SYNOPSIS
    Self-Researching AI Module - Autonomous knowledge acquisition

.DESCRIPTION
    Enables AI to research solutions, read documentation, and discover answers.
    Uses trusted sources and fact verification for safety.

.NOTES
    Requires: SafetyFramework.ps1
    Safety: Only research from trusted sources
#>

#Requires -Version 5.1

Import-Module "$PSScriptRoot\..\safety\SafetyFramework.ps1" -Force

# ============================================
# TRUSTED SOURCES
# ============================================

$script:TrustedSources = @{
    Documentation      = @(
        "docs.microsoft.com",
        "learn.microsoft.com",
        "github.com",
        "stackoverflow.com",
        "docs.python.org",
        "nodejs.org/docs",
        "developer.mozilla.org"
    )

    PackageRegistries  = @(
        "nuget.org",
        "npmjs.com",
        "pypi.org",
        "rubygems.org"
    )

    SecurityAdvisories = @(
        "nvd.nist.gov",
        "cve.mitre.org",
        "github.com/advisories"
    )
}

# ============================================
# RESEARCH FUNCTIONS
# ============================================

function Search-Documentation {
    <#
    .SYNOPSIS
        Search official documentation for solutions
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Query,

        [string]$Domain = "Microsoft",

        [int]$MaxResults = 5
    )

    Write-Host "🔬 Researching: $Query" -ForegroundColor Cyan

    # Safety check
    $SafetyCheck = Invoke-SafetyCheck -Action "Search documentation: $Query" -Context @{Scope = "Read" }

    if (-not $SafetyCheck.Approved) {
        Write-SafetyLog "RESEARCH_BLOCKED: Search blocked for: $Query" -Level WARN
        return @()
    }

    $Results = @()

    # Search based on domain
    switch ($Domain) {
        "Microsoft" {
            $Results = Search-MicrosoftDocs -Query $Query -MaxResults $MaxResults
        }

        "PowerShell" {
            $Results = Search-PowerShellDocs -Query $Query -MaxResults $MaxResults
        }

        "GitHub" {
            $Results = Search-GitHubDocs -Query $Query -MaxResults $MaxResults
        }

        default {
            Write-Host "ℹ️ Using general search for: $Domain" -ForegroundColor Yellow
            $Results = Search-GeneralDocs -Query $Query -MaxResults $MaxResults
        }
    }

    # Log research
    Write-ResearchLog -Query $Query -Domain $Domain -ResultCount $Results.Count

    return $Results
}

function Search-MicrosoftDocs {
    param([string]$Query, [int]$MaxResults)

    # Use Microsoft Learn search API or web scraping
    $SearchUrl = "https://learn.microsoft.com/en-us/search/?terms=$([uri]::EscapeDataString($Query))"

    Write-Host "  📖 Searching Microsoft Learn..." -ForegroundColor Gray

    # Simulate search results (in production, would use actual API)
    return @(
        @{
            Title       = "Microsoft Documentation Result"
            Url         = $SearchUrl
            Summary     = "Relevant Microsoft documentation for: $Query"
            Source      = "Microsoft Learn"
            Trustworthy = $true
        }
    )
}

function Search-PowerShellDocs {
    param([string]$Query, [int]$MaxResults)

    # Search PowerShell help
    $Results = @()

    try {
        $HelpResults = Get-Help -Name "*$Query*" -ErrorAction SilentlyContinue | Select-Object -First $MaxResults

        foreach ($Help in $HelpResults) {
            $Results += @{
                Title       = $Help.Name
                Summary     = $Help.Synopsis
                Details     = $Help.Description
                Examples    = $Help.Examples
                Source      = "PowerShell Built-in Help"
                Trustworthy = $true
            }
        }

        Write-Host "  ✅ Found $($Results.Count) PowerShell help topics" -ForegroundColor Green

    } catch {
        Write-Host "  ⚠️ PowerShell help search failed: $_" -ForegroundColor Yellow
    }

    return $Results
}

function Search-GitHubDocs {
    param([string]$Query, [int]$MaxResults)

    Write-Host "  🐙 Searching GitHub..." -ForegroundColor Gray

    # Would use GitHub API in production
    return @(
        @{
            Title       = "GitHub Search Result"
            Url         = "https://github.com/search?q=$([uri]::EscapeDataString($Query))"
            Summary     = "GitHub repositories and code for: $Query"
            Source      = "GitHub"
            Trustworthy = $true
        }
    )
}

function Search-GeneralDocs {
    param([string]$Query, [int]$MaxResults)

    # Multi-source search
    $Results = @()

    $Results += Search-PowerShellDocs -Query $Query -MaxResults 2
    $Results += Search-MicrosoftDocs -Query $Query -MaxResults 2

    return $Results
}

function Get-BestPractice {
    <#
    .SYNOPSIS
        Research best practices for a technology or pattern
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Technology,

        [string]$Aspect = "General"
    )

    Write-Host "📚 Researching best practices: $Technology ($Aspect)" -ForegroundColor Cyan

    $Query = "$Technology best practices $Aspect"
    $Results = Search-Documentation -Query $Query -MaxResults 5

    # Extract best practices
    $BestPractices = @()

    foreach ($Result in $Results) {
        $BestPractices += @{
            Technology     = $Technology
            Aspect         = $Aspect
            Source         = $Result.Source
            Recommendation = $Result.Summary
            Reference      = $Result.Url
            ResearchedAt   = Get-Date
        }
    }

    # Save to knowledge base
    Save-ResearchFindings -Technology $Technology -Findings $BestPractices

    return $BestPractices
}

function Find-Solution {
    <#
    .SYNOPSIS
        Research solution to a specific problem
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Problem,

        [string]$Context = "",

        [string[]]$Constraints = @()
    )

    Write-Host "🔍 Finding solution for: $Problem" -ForegroundColor Cyan

    # Build search query
    $Query = $Problem
    if ($Context) { $Query += " $Context" }
    if ($Constraints.Count -gt 0) { $Query += " " + ($Constraints -join " ") }

    # Multi-strategy research
    $Solutions = @()

    # 1. Search documentation
    $DocResults = Search-Documentation -Query $Query -MaxResults 3
    foreach ($Doc in $DocResults) {
        $Solutions += @{
            Type       = "Documentation"
            Source     = $Doc.Source
            Solution   = $Doc.Summary
            Confidence = 0.8
            Reference  = $Doc.Url
        }
    }

    # 2. Check local knowledge base
    $KBSolutions = Search-LocalKnowledge -Problem $Problem
    foreach ($KB in $KBSolutions) {
        $Solutions += @{
            Type       = "Knowledge Base"
            Source     = "Local Learning"
            Solution   = $KB.Solution
            Confidence = $KB.Confidence
            Reference  = "Previously solved"
        }
    }

    # 3. Pattern matching from similar problems
    $Patterns = Find-SimilarPatterns -Problem $Problem
    foreach ($Pattern in $Patterns) {
        $Solutions += @{
            Type       = "Pattern"
            Source     = "Pattern Recognition"
            Solution   = $Pattern.Solution
            Confidence = $Pattern.Similarity
            Reference  = "Similar problem: $($Pattern.OriginalProblem)"
        }
    }

    # Rank solutions by confidence
    $RankedSolutions = $Solutions | Sort-Object -Property Confidence -Descending

    Write-Host "  ✅ Found $($RankedSolutions.Count) potential solutions" -ForegroundColor Green

    return $RankedSolutions
}

function Search-LocalKnowledge {
    param([string]$Problem)

    $KBPath = "ai-system\data\knowledge\solutions.json"

    if (-not (Test-Path $KBPath)) {
        return @()
    }

    $KB = Get-Content $KBPath | ConvertFrom-Json

    # Search for similar problems
    $Results = $KB | Where-Object { $_.Problem -like "*$Problem*" }

    return $Results
}

function Find-SimilarPatterns {
    param([string]$Problem)

    # Simplified pattern matching
    # In production, would use NLP/ML for similarity

    $PatternsPath = "ai-system\data\learning\patterns.db.json"

    if (-not (Test-Path $PatternsPath)) {
        return @()
    }

    $Patterns = Get-Content $PatternsPath | ConvertFrom-Json

    # Very basic similarity (word overlap)
    $ProblemWords = $Problem.ToLower() -split '\s+'

    $Similar = @()
    foreach ($Pattern in $Patterns.PSObject.Properties.Value) {
        $PatternWords = $Pattern.Context.ToLower() -split '\s+'
        $CommonWords = $ProblemWords | Where-Object { $_ -in $PatternWords }

        $Similarity = $CommonWords.Count / [math]::Max($ProblemWords.Count, $PatternWords.Count)

        if ($Similarity -gt 0.3) {
            $Similar += @{
                OriginalProblem = $Pattern.Context
                Solution        = $Pattern.BestAction
                Similarity      = $Similarity
            }
        }
    }

    return $Similar
}

function Save-ResearchFindings {
    param(
        [string]$Technology,
        [array]$Findings
    )

    $ResearchDir = "ai-system\data\research"
    if (-not (Test-Path $ResearchDir)) {
        New-Item -Path $ResearchDir -ItemType Directory -Force | Out-Null
    }

    $ResearchFile = Join-Path $ResearchDir "$Technology-$(Get-Date -Format 'yyyyMMdd').json"

    $Data = @{
        Technology   = $Technology
        ResearchDate = Get-Date
        Findings     = $Findings
    }

    $Data | ConvertTo-Json -Depth 5 | Set-Content $ResearchFile

    Write-Host "  💾 Saved research findings to: $ResearchFile" -ForegroundColor Gray
}

function Write-ResearchLog {
    param(
        [string]$Query,
        [string]$Domain,
        [int]$ResultCount
    )

    $LogDir = "ai-system\logs\research"
    if (-not (Test-Path $LogDir)) {
        New-Item -Path $LogDir -ItemType Directory -Force | Out-Null
    }

    $LogFile = Join-Path $LogDir "research-$(Get-Date -Format 'yyyyMMdd').log"

    $LogEntry = @{
        Timestamp   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Query       = $Query
        Domain      = $Domain
        ResultCount = $ResultCount
    }

    $LogEntry | ConvertTo-Json -Compress | Add-Content $LogFile
}

function Test-SourceTrustworthiness {
    <#
    .SYNOPSIS
        Verify if a source is trustworthy
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Url
    )

    $Uri = [uri]$Url
    $Host = $Uri.Host

    # Check against trusted sources
    $IsTrusted = $false

    foreach ($Category in $script:TrustedSources.Keys) {
        if ($Host -in $script:TrustedSources[$Category]) {
            $IsTrusted = $true
            break
        }
    }

    # Additional checks
    $Checks = @{
        IsTrusted = $IsTrusted
        IsHTTPS   = $Uri.Scheme -eq "https"
        Domain    = $Host
        Category  = if ($IsTrusted) { $Category } else { "Untrusted" }
    }

    return $Checks
}

function Invoke-FactVerification {
    <#
    .SYNOPSIS
        Verify facts from research against multiple sources
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Claim,

        [int]$MinSources = 2
    )

    Write-Host "✅ Verifying claim: $Claim" -ForegroundColor Yellow

    # Research claim from multiple sources
    $Sources = Search-Documentation -Query $Claim -MaxResults 5

    # Check source trustworthiness
    $TrustedSources = $Sources | Where-Object {
        if ($_.Url) {
            $Trust = Test-SourceTrustworthiness -Url $_.Url
            return $Trust.IsTrusted
        }
        return $_.Trustworthy -eq $true
    }

    $Verified = $TrustedSources.Count -ge $MinSources

    return @{
        Claim           = $Claim
        Verified        = $Verified
        SourceCount     = $TrustedSources.Count
        Sources         = $TrustedSources
        ConfidenceLevel = [math]::Min($TrustedSources.Count / $MinSources, 1.0)
    }
}

# ============================================
# EXPORT MODULE MEMBERS
# ============================================

Export-ModuleMember -Function @(
    'Search-Documentation',
    'Get-BestPractice',
    'Find-Solution',
    'Test-SourceTrustworthiness',
    'Invoke-FactVerification'
)
