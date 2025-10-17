<#
.SYNOPSIS
    Knowledge Management System - Main Interface

.DESCRIPTION
    Central script for managing the knowledge base including blueprints,
    lessons learned, and domain-specific knowledge.

.PARAMETER Action
    The action to perform: Add, List, Search, Update, Export

.PARAMETER Type
    The type of knowledge entry: Blueprint, Lesson, Domain

.PARAMETER Domain
    The knowledge domain (ai, it-infrastructure, coding, etc.)

.PARAMETER Title
    Title of the knowledge entry

.PARAMETER Source
    Source URL or reference for the knowledge

.EXAMPLE
    .\Manage-Knowledge.ps1 -Action Add -Type Blueprint -Domain ai -Title "New AI Technology"

.EXAMPLE
    .\Manage-Knowledge.ps1 -Action List -Type Blueprint

.EXAMPLE
    .\Manage-Knowledge.ps1 -Action Search -Query "virtualization"

.NOTES
    Author: AI Autonomous System
    Date: October 17, 2025
    Version: 1.0.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('Add', 'List', 'Search', 'Update', 'Export', 'Stats')]
    [string]$Action,

    [Parameter(Mandatory=$false)]
    [ValidateSet('Blueprint', 'Lesson', 'Domain')]
    [string]$Type,

    [Parameter(Mandatory=$false)]
    [ValidateSet('ai', 'it-infrastructure', 'coding', 'supercomputers', 'networking', 'security', 'virtualization', 'business', 'content-creation')]
    [string]$Domain,

    [Parameter(Mandatory=$false)]
    [string]$Title,

    [Parameter(Mandatory=$false)]
    [string]$Source,

    [Parameter(Mandatory=$false)]
    [string]$Query,

    [Parameter(Mandatory=$false)]
    [switch]$Verbose
)

# Set error action
$ErrorActionPreference = 'Stop'

# Define paths
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$KnowledgeRoot = Join-Path $RepoRoot "knowledge"
$BlueprintsPath = Join-Path $KnowledgeRoot "blueprints"
$LessonsPath = Join-Path $KnowledgeRoot "lessons"
$DomainsPath = Join-Path $KnowledgeRoot "domains"

#region Helper Functions

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )
    
    $colors = @{
        'Info' = 'Cyan'
        'Success' = 'Green'
        'Warning' = 'Yellow'
        'Error' = 'Red'
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] " -NoNewline -ForegroundColor Gray
    Write-Host $Message -ForegroundColor $colors[$Level]
}

function Get-NextId {
    param(
        [string]$Path,
        [string]$Prefix
    )
    
    $today = Get-Date -Format "yyyyMMdd"
    $files = Get-ChildItem -Path $Path -Filter "$Prefix-$today-*.md" -ErrorAction SilentlyContinue
    
    if ($files.Count -eq 0) {
        return "$Prefix-$today-01"
    }
    
    $maxNum = ($files | ForEach-Object {
        if ($_.BaseName -match "$Prefix-$today-(\d+)") {
            [int]$matches[1]
        }
    } | Measure-Object -Maximum).Maximum
    
    $nextNum = $maxNum + 1
    return "$Prefix-$today-{0:D2}" -f $nextNum
}

function New-Blueprint {
    param(
        [string]$Title,
        [string]$Domain,
        [string]$Source
    )
    
    $id = Get-NextId -Path $BlueprintsPath -Prefix "BP"
    $date = Get-Date -Format "MMMM d, yyyy"
    $fileName = "$id`_$($Title -replace '[^\w\s-]', '' -replace '\s+', '-').md"
    $filePath = Join-Path $BlueprintsPath $fileName
    
    $content = @"
# Blueprint: $Title

**ID**: $id
**Date**: $date
**Source**: $Source
**Domain**: $Domain
**Status**: Proposed

---

## 1. Executive Summary

[Brief overview of the technology/technique and its relevance to the civic infrastructure project]

## 2. Key Findings

- **Finding 1**: [Description]
- **Finding 2**: [Description]
- **Finding 3**: [Description]

## 3. Integration Strategy

### Phase 1: Zero-Budget Implementation (Immediate)

1. **Initial Setup**:
   - [Step-by-step instructions]

2. **Validation**:
   - [How to verify it works]

### Phase 2: Micro-Investment (Profit > `$100/month)

1. **Enhanced Implementation**:
   - [Improvements when budget allows]

### Phase 3: Strategic Procurement (Profit > `$1,000/month)

1. **Production Deployment**:
   - [Full-scale implementation]

## 4. Automation & Self-Improvement

- **Automated Monitoring**: [How the system tracks this]
- **Dynamic Optimization**: [How it improves over time]
- **Self-Learning**: [How knowledge is captured]

## 5. Governance & Audit Trail

- Initialization logged in council ledger
- Phase transitions documented
- Benchmark results archived in evidence/

## 6. Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

---

**Conclusion**: [Summary of expected impact and next steps]
"@

    $content | Out-File -FilePath $filePath -Encoding UTF8
    Write-Log "Blueprint created: $fileName" -Level Success
    return $filePath
}

function New-Lesson {
    param(
        [string]$Title,
        [string]$BlueprintId
    )
    
    $id = Get-NextId -Path $LessonsPath -Prefix "LL"
    $date = Get-Date -Format "MMMM d, yyyy"
    $fileName = "$id`_$($Title -replace '[^\w\s-]', '' -replace '\s+', '-').md"
    $filePath = Join-Path $LessonsPath $fileName
    
    $blueprintRef = if ($BlueprintId) { "[Link to Blueprint](../blueprints/$BlueprintId*.md)" } else { "N/A" }
    
    $content = @"
# Lesson Learned: $Title

**ID**: $id
**Date**: $date
**Source Blueprint**: $blueprintRef

---

## 1. Core Insight

[The primary lesson learned from this implementation or analysis]

## 2. Key Takeaways

1. **Takeaway 1**: [Description and implications]

2. **Takeaway 2**: [Description and implications]

3. **Takeaway 3**: [Description and implications]

## 3. Impact on System Blueprints & Policies

- **Impact on [Document/System]**: [How this changes existing approaches]
- **Policy Updates**: [Any policy changes required]
- **Architecture Changes**: [System design implications]

## 4. Next Actions

1. **Immediate Actions**:
   - [Action items that should be taken right away]

2. **Future Considerations**:
   - [Longer-term implications and planning]

---

This lesson has been integrated into the autonomous system's knowledge base for future decision-making.
"@

    $content | Out-File -FilePath $filePath -Encoding UTF8
    Write-Log "Lesson created: $fileName" -Level Success
    return $filePath
}

function Get-KnowledgeList {
    param(
        [string]$Type
    )
    
    $path = switch ($Type) {
        'Blueprint' { $BlueprintsPath }
        'Lesson' { $LessonsPath }
        'Domain' { $DomainsPath }
        default { $KnowledgeRoot }
    }
    
    if ($Type -eq 'Domain') {
        $items = Get-ChildItem -Path $path -Directory | Select-Object Name, FullName
        Write-Log "Knowledge Domains:" -Level Info
        $items | ForEach-Object {
            Write-Host "  - $($_.Name)" -ForegroundColor Cyan
            $readme = Join-Path $_.FullName "README.md"
            if (Test-Path $readme) {
                $firstLine = (Get-Content $readme -First 1).TrimStart('#').Trim()
                Write-Host "    $firstLine" -ForegroundColor Gray
            }
        }
    } else {
        $items = Get-ChildItem -Path $path -Filter "*.md" | 
            Where-Object { $_.Name -ne "README.md" } |
            Select-Object Name, LastWriteTime, @{Name='Size';Expression={$_.Length}}
        
        Write-Log "$Type List:" -Level Info
        $items | Format-Table -AutoSize
    }
}

function Search-Knowledge {
    param(
        [string]$Query
    )
    
    Write-Log "Searching for: $Query" -Level Info
    
    $results = @()
    
    # Search blueprints
    Get-ChildItem -Path $BlueprintsPath -Filter "*.md" -Recurse | ForEach-Object {
        $content = Get-Content $_.FullName -Raw
        if ($content -match $Query) {
            $results += [PSCustomObject]@{
                Type = 'Blueprint'
                File = $_.Name
                Path = $_.FullName
            }
        }
    }
    
    # Search lessons
    Get-ChildItem -Path $LessonsPath -Filter "*.md" -Recurse | ForEach-Object {
        $content = Get-Content $_.FullName -Raw
        if ($content -match $Query) {
            $results += [PSCustomObject]@{
                Type = 'Lesson'
                File = $_.Name
                Path = $_.FullName
            }
        }
    }
    
    # Search domains
    Get-ChildItem -Path $DomainsPath -Filter "*.md" -Recurse | ForEach-Object {
        $content = Get-Content $_.FullName -Raw
        if ($content -match $Query) {
            $results += [PSCustomObject]@{
                Type = 'Domain'
                File = $_.Name
                Path = $_.FullName
            }
        }
    }
    
    if ($results.Count -eq 0) {
        Write-Log "No results found" -Level Warning
    } else {
        Write-Log "Found $($results.Count) results:" -Level Success
        $results | Format-Table -AutoSize
    }
}

function Get-KnowledgeStats {
    Write-Log "Knowledge Base Statistics" -Level Info
    Write-Host ""
    
    $blueprintCount = (Get-ChildItem -Path $BlueprintsPath -Filter "*.md" | Where-Object { $_.Name -ne "README.md" }).Count
    $lessonCount = (Get-ChildItem -Path $LessonsPath -Filter "*.md" | Where-Object { $_.Name -ne "README.md" }).Count
    $domainCount = (Get-ChildItem -Path $DomainsPath -Directory).Count
    
    Write-Host "  Blueprints: $blueprintCount" -ForegroundColor Green
    Write-Host "  Lessons:    $lessonCount" -ForegroundColor Green
    Write-Host "  Domains:    $domainCount" -ForegroundColor Green
    Write-Host ""
    
    Write-Log "Domains:" -Level Info
    Get-ChildItem -Path $DomainsPath -Directory | ForEach-Object {
        $readme = Join-Path $_.FullName "README.md"
        $fileCount = (Get-ChildItem -Path $_.FullName -Filter "*.md" -Recurse).Count
        Write-Host "  - $($_.Name): $fileCount files" -ForegroundColor Cyan
    }
}

#endregion

#region Main Logic

try {
    Write-Host "`n=== Knowledge Management System ===" -ForegroundColor Yellow
    Write-Host ""
    
    switch ($Action) {
        'Add' {
            if (-not $Type) {
                throw "Type parameter is required for Add action"
            }
            
            switch ($Type) {
                'Blueprint' {
                    if (-not $Title -or -not $Domain) {
                        throw "Title and Domain are required for creating a Blueprint"
                    }
                    $path = New-Blueprint -Title $Title -Domain $Domain -Source $Source
                    Write-Log "Blueprint created at: $path" -Level Success
                    Write-Host "`nYou can now edit the file to add details." -ForegroundColor Yellow
                }
                'Lesson' {
                    if (-not $Title) {
                        throw "Title is required for creating a Lesson"
                    }
                    $path = New-Lesson -Title $Title -BlueprintId $Source
                    Write-Log "Lesson created at: $path" -Level Success
                    Write-Host "`nYou can now edit the file to add details." -ForegroundColor Yellow
                }
                default {
                    throw "Type '$Type' is not supported for Add action"
                }
            }
        }
        
        'List' {
            Get-KnowledgeList -Type $Type
        }
        
        'Search' {
            if (-not $Query) {
                throw "Query parameter is required for Search action"
            }
            Search-Knowledge -Query $Query
        }
        
        'Stats' {
            Get-KnowledgeStats
        }
        
        'Export' {
            Write-Log "Export functionality coming soon!" -Level Warning
        }
        
        default {
            throw "Unknown action: $Action"
        }
    }
    
    Write-Host ""
    Write-Host "=== Operation Complete ===" -ForegroundColor Green
    Write-Host ""
    
} catch {
    Write-Log "Error: $($_.Exception.Message)" -Level Error
    exit 1
}

#endregion
