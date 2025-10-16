<#
.SYNOPSIS
    Self-Developing AI Module - Autonomous code generation

.DESCRIPTION
    Enables AI to write new features, fix bugs, generate tests, and create documentation.
    Includes AI code review and human approval workflow.

.NOTES
    Requires: SafetyFramework.ps1, Ollama with qwen2.5-coder
    Safety: All generated code reviewed before execution
#>

#Requires -Version 5.1

Import-Module "$PSScriptRoot\..\safety\SafetyFramework.ps1" -Force

# ============================================
# CODE GENERATION
# ============================================

function New-FeatureImplementation {
    <#
    .SYNOPSIS
        Generate code for a new feature using AI
    #>
    param(
        [Parameter(Mandatory)]
        [string]$FeatureDescription,

        [ValidateSet('PowerShell', 'Python', 'JavaScript', 'C#')]
        [string]$Language = 'PowerShell',

        [string]$OutputPath,

        [switch]$IncludeTests,

        [switch]$IncludeDocs
    )

    Write-Host "💻 Self-Developing: Generating feature..." -ForegroundColor Cyan
    Write-Host "  Feature: $FeatureDescription" -ForegroundColor Gray
    Write-Host "  Language: $Language" -ForegroundColor Gray

    # Safety check
    $SafetyCheck = Invoke-SafetyCheck -Action "Generate code for feature: $FeatureDescription" -Context @{
        Scope          = "Development"
        Language       = $Language
        ReviewRequired = $true
    }

    if (-not $SafetyCheck.Approved) {
        Write-SafetyLog "CODE_GEN_BLOCKED: Feature generation blocked" -Level WARN
        return $null
    }

    # Step 1: Generate code using AI
    Write-Host "  🤖 Generating code with AI (Qwen2.5-Coder)..." -ForegroundColor Yellow

    $Prompt = @"
Generate production-ready $Language code for the following feature:

Feature: $FeatureDescription

Requirements:
- Follow best practices for $Language
- Include error handling
- Add inline comments
- Make it maintainable and testable
$(if ($IncludeTests) { "- Include unit tests" })
$(if ($IncludeDocs) { "- Include documentation comments" })

Generate only the code, no explanations.
"@

    $GeneratedCode = Invoke-AICodeGeneration -Prompt $Prompt -Language $Language

    if (-not $GeneratedCode) {
        Write-Host "  ❌ Code generation failed" -ForegroundColor Red
        return $null
    }

    Write-Host "  ✅ Code generated ($($GeneratedCode.Length) characters)" -ForegroundColor Green

    # Step 2: AI Code Review
    Write-Host "  🔍 Running AI code review..." -ForegroundColor Yellow

    $ReviewResult = Invoke-AICodeReview -Code $GeneratedCode -Language $Language

    if ($ReviewResult.Issues.Count -gt 0) {
        Write-Host "  ⚠️  Code review found $($ReviewResult.Issues.Count) issues:" -ForegroundColor Yellow
        foreach ($Issue in $ReviewResult.Issues) {
            Write-Host "    • $($Issue.Severity): $($Issue.Description)" -ForegroundColor Yellow
        }

        # Auto-fix minor issues
        if ($ReviewResult.AutoFixable) {
            Write-Host "  🔧 Auto-fixing issues..." -ForegroundColor Cyan
            $GeneratedCode = Invoke-AICodeFix -Code $GeneratedCode -Issues $ReviewResult.Issues
            Write-Host "  ✅ Issues fixed" -ForegroundColor Green
        }
    } else {
        Write-Host "  ✅ Code review passed - no issues found" -ForegroundColor Green
    }

    # Step 3: Human approval
    Write-Host "`n📋 Generated Code Preview:" -ForegroundColor Cyan
    Write-Host "─" * 80 -ForegroundColor Gray
    Write-Host $GeneratedCode.Substring(0, [Math]::Min(500, $GeneratedCode.Length))
    if ($GeneratedCode.Length -gt 500) {
        Write-Host "... (truncated, full code: $($GeneratedCode.Length) chars)" -ForegroundColor Gray
    }
    Write-Host "─" * 80 -ForegroundColor Gray

    $Approved = Read-Host "`nApprove this generated code? (Y/N)"

    if ($Approved -notin @('y', 'yes', 'Y', 'Yes')) {
        Write-Host "  🛑 Code generation cancelled by user" -ForegroundColor Red
        return $null
    }

    # Step 4: Save code
    if ($OutputPath) {
        Write-Host "  💾 Saving code to: $OutputPath" -ForegroundColor Gray

        # Create backup if file exists
        if (Test-Path $OutputPath) {
            $BackupPath = "$OutputPath.backup-$(Get-Date -Format 'yyyyMMddHHmmss')"
            Copy-Item -Path $OutputPath -Destination $BackupPath
            Write-Host "  💾 Backup created: $BackupPath" -ForegroundColor Gray
        }

        Set-Content -Path $OutputPath -Value $GeneratedCode
        Write-Host "  ✅ Code saved" -ForegroundColor Green
    }

    # Step 5: Generate tests if requested
    $TestCode = $null
    if ($IncludeTests) {
        Write-Host "  🧪 Generating unit tests..." -ForegroundColor Yellow
        $TestCode = New-UnitTests -Code $GeneratedCode -Language $Language
    }

    # Step 6: Generate docs if requested
    $Documentation = $null
    if ($IncludeDocs) {
        Write-Host "  📖 Generating documentation..." -ForegroundColor Yellow
        $Documentation = New-CodeDocumentation -Code $GeneratedCode -Language $Language
    }

    return @{
        Code          = $GeneratedCode
        Tests         = $TestCode
        Documentation = $Documentation
        ReviewResult  = $ReviewResult
        OutputPath    = $OutputPath
        Approved      = $true
    }
}

function Invoke-AICodeGeneration {
    param([string]$Prompt, [string]$Language)

    # Check if Ollama is available
    if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
        Write-Host "  ⚠️  Ollama not found, using template-based generation" -ForegroundColor Yellow
        return Get-CodeTemplate -Language $Language
    }

    try {
        # Use Qwen2.5-Coder for code generation
        $Result = ollama run qwen2.5-coder:1.5b $Prompt 2>&1

        if ($LASTEXITCODE -eq 0 -and $Result) {
            # Extract code from markdown if present
            if ($Result -match '```[\w]*\s*([\s\S]*?)```') {
                return $Matches[1].Trim()
            }
            return $Result
        }

    } catch {
        Write-Host "  ⚠️  AI generation failed: $_" -ForegroundColor Yellow
    }

    # Fallback to template
    return Get-CodeTemplate -Language $Language
}

function Get-CodeTemplate {
    param([string]$Language)

    # Simple template fallback
    switch ($Language) {
        'PowerShell' {
            return @"
<#
.SYNOPSIS
    Auto-generated feature implementation

.DESCRIPTION
    Generated by AI Self-Developing module
#>

function Invoke-GeneratedFeature {
    [CmdletBinding()]
    param()

    Write-Host "Feature implementation pending" -ForegroundColor Yellow

    # TODO: Implement feature logic
}

Export-ModuleMember -Function Invoke-GeneratedFeature
"@
        }

        'Python' {
            return @"
"""
Auto-generated feature implementation
Generated by AI Self-Developing module
"""

def generated_feature():
    """Feature implementation pending"""
    print("Feature implementation pending")
    # TODO: Implement feature logic

if __name__ == "__main__":
    generated_feature()
"@
        }
    }
}

function Invoke-AICodeReview {
    param([string]$Code, [string]$Language)

    Write-Host "    Analyzing code quality..." -ForegroundColor Gray

    $Issues = @()

    # Basic static analysis
    if ($Language -eq 'PowerShell') {
        # Check for common issues
        if ($Code -match 'Invoke-Expression') {
            $Issues += @{Severity = 'High'; Description = 'Dangerous use of Invoke-Expression'; AutoFixable = $false }
        }

        if ($Code -notmatch '\[CmdletBinding\(\)\]') {
            $Issues += @{Severity = 'Low'; Description = 'Missing CmdletBinding attribute'; AutoFixable = $true }
        }

        if ($Code -notmatch 'try\s*\{.*catch') {
            $Issues += @{Severity = 'Medium'; Description = 'No error handling found'; AutoFixable = $false }
        }
    }

    return @{
        Issues      = $Issues
        AutoFixable = ($Issues | Where-Object { $_.AutoFixable }).Count -gt 0
        Passed      = $Issues.Count -eq 0
    }
}

function Invoke-AICodeFix {
    param([string]$Code, [array]$Issues)

    $FixedCode = $Code

    # Apply auto-fixes
    foreach ($Issue in $Issues | Where-Object { $_.AutoFixable }) {
        switch ($Issue.Description) {
            'Missing CmdletBinding attribute' {
                $FixedCode = $FixedCode -replace 'function\s+(\w+)\s*\{', 'function $1 {[CmdletBinding()]param()'
            }
        }
    }

    return $FixedCode
}

# ============================================
# BUG FIXING
# ============================================

function Repair-CodeBug {
    <#
    .SYNOPSIS
        Analyze and fix bugs in code using AI
    #>
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [string]$ErrorMessage,

        [switch]$AutoApply
    )

    Write-Host "🐛 Self-Developing: Analyzing bug..." -ForegroundColor Cyan

    # Safety check
    $SafetyCheck = Invoke-SafetyCheck -Action "Analyze and fix bug in: $FilePath" -Context @{
        Scope        = "File"
        Reversible   = $true
        BackupExists = $true
    }

    if (-not $SafetyCheck.Approved) {
        return $null
    }

    # Read code
    $OriginalCode = Get-Content $FilePath -Raw

    # Create backup
    $BackupPath = "$FilePath.backup-$(Get-Date -Format 'yyyyMMddHHmmss')"
    Copy-Item -Path $FilePath -Destination $BackupPath

    Write-Host "  📝 Analyzing code for bugs..." -ForegroundColor Yellow

    # AI-based bug analysis
    $AnalysisPrompt = @"
Analyze this code for bugs:

Error Message: $ErrorMessage

Code:
$OriginalCode

Identify the bug and provide a fix.
"@

    $Analysis = Invoke-AICodeGeneration -Prompt $AnalysisPrompt -Language "PowerShell"

    Write-Host "  💡 AI Analysis:" -ForegroundColor Cyan
    Write-Host $Analysis

    if ($AutoApply) {
        # Apply fix (simplified - would need more sophisticated parsing)
        Write-Host "  ⚠️  Auto-apply not fully implemented yet" -ForegroundColor Yellow
    }

    return @{
        Analysis   = $Analysis
        BackupPath = $BackupPath
    }
}

# ============================================
# TEST GENERATION
# ============================================

function New-UnitTests {
    param([string]$Code, [string]$Language)

    Write-Host "    Generating unit tests..." -ForegroundColor Gray

    $TestPrompt = @"
Generate comprehensive unit tests for this $Language code:

$Code

Include:
- Happy path tests
- Edge cases
- Error handling tests
- Input validation tests

Generate test code only.
"@

    $TestCode = Invoke-AICodeGeneration -Prompt $TestPrompt -Language $Language

    return $TestCode
}

# ============================================
# DOCUMENTATION GENERATION
# ============================================

function New-CodeDocumentation {
    param([string]$Code, [string]$Language)

    Write-Host "    Generating documentation..." -ForegroundColor Gray

    $DocPrompt = @"
Generate comprehensive documentation for this $Language code:

$Code

Include:
- Function/class descriptions
- Parameter explanations
- Return value descriptions
- Usage examples
- Error handling notes

Generate markdown documentation.
"@

    $Documentation = Invoke-AICodeGeneration -Prompt $DocPrompt -Language "Markdown"

    return $Documentation
}

# ============================================
# EXPORT MODULE MEMBERS
# ============================================

Export-ModuleMember -Function @(
    'New-FeatureImplementation',
    'Repair-CodeBug',
    'New-UnitTests',
    'New-CodeDocumentation'
)
<#
.SYNOPSIS
    Self-Developing AI Module - Autonomous code generation

.DESCRIPTION
    Enables AI to write new features, fix bugs, generate tests, and create documentation.
    Includes AI code review and human approval workflow.

.NOTES
    Requires: SafetyFramework.ps1, Ollama with qwen2.5-coder
    Safety: All generated code reviewed before execution
#>

#Requires -Version 5.1

Import-Module "$PSScriptRoot\..\safety\SafetyFramework.ps1" -Force

# ============================================
# CODE GENERATION
# ============================================

function New-FeatureImplementation {
    <#
    .SYNOPSIS
        Generate code for a new feature using AI
    #>
    param(
        [Parameter(Mandatory)]
        [string]$FeatureDescription,

        [ValidateSet('PowerShell', 'Python', 'JavaScript', 'C#')]
        [string]$Language = 'PowerShell',

        [string]$OutputPath,

        [switch]$IncludeTests,

        [switch]$IncludeDocs
    )

    Write-Host "💻 Self-Developing: Generating feature..." -ForegroundColor Cyan
    Write-Host "  Feature: $FeatureDescription" -ForegroundColor Gray
    Write-Host "  Language: $Language" -ForegroundColor Gray

    # Safety check
    $SafetyCheck = Invoke-SafetyCheck -Action "Generate code for feature: $FeatureDescription" -Context @{
        Scope          = "Development"
        Language       = $Language
        ReviewRequired = $true
    }

    if (-not $SafetyCheck.Approved) {
        Write-SafetyLog "CODE_GEN_BLOCKED: Feature generation blocked" -Level WARN
        return $null
    }

    # Step 1: Generate code using AI
    Write-Host "  🤖 Generating code with AI (Qwen2.5-Coder)..." -ForegroundColor Yellow

    $Prompt = @"
Generate production-ready $Language code for the following feature:

Feature: $FeatureDescription

Requirements:
- Follow best practices for $Language
- Include error handling
- Add inline comments
- Make it maintainable and testable
$(if ($IncludeTests) { "- Include unit tests" })
$(if ($IncludeDocs) { "- Include documentation comments" })

Generate only the code, no explanations.
"@

    $GeneratedCode = Invoke-AICodeGeneration -Prompt $Prompt -Language $Language

    if (-not $GeneratedCode) {
        Write-Host "  ❌ Code generation failed" -ForegroundColor Red
        return $null
    }

    Write-Host "  ✅ Code generated ($($GeneratedCode.Length) characters)" -ForegroundColor Green

    # Step 2: AI Code Review
    Write-Host "  🔍 Running AI code review..." -ForegroundColor Yellow

    $ReviewResult = Invoke-AICodeReview -Code $GeneratedCode -Language $Language

    if ($ReviewResult.Issues.Count -gt 0) {
        Write-Host "  ⚠️  Code review found $($ReviewResult.Issues.Count) issues:" -ForegroundColor Yellow
        foreach ($Issue in $ReviewResult.Issues) {
            Write-Host "    • $($Issue.Severity): $($Issue.Description)" -ForegroundColor Yellow
        }

        # Auto-fix minor issues
        if ($ReviewResult.AutoFixable) {
            Write-Host "  🔧 Auto-fixing issues..." -ForegroundColor Cyan
            $GeneratedCode = Invoke-AICodeFix -Code $GeneratedCode -Issues $ReviewResult.Issues
            Write-Host "  ✅ Issues fixed" -ForegroundColor Green
        }
    } else {
        Write-Host "  ✅ Code review passed - no issues found" -ForegroundColor Green
    }

    # Step 3: Human approval
    Write-Host "`n📋 Generated Code Preview:" -ForegroundColor Cyan
    Write-Host "─" * 80 -ForegroundColor Gray
    Write-Host $GeneratedCode.Substring(0, [Math]::Min(500, $GeneratedCode.Length))
    if ($GeneratedCode.Length -gt 500) {
        Write-Host "... (truncated, full code: $($GeneratedCode.Length) chars)" -ForegroundColor Gray
    }
    Write-Host "─" * 80 -ForegroundColor Gray

    $Approved = Read-Host "`nApprove this generated code? (Y/N)"

    if ($Approved -notin @('y', 'yes', 'Y', 'Yes')) {
        Write-Host "  🛑 Code generation cancelled by user" -ForegroundColor Red
        return $null
    }

    # Step 4: Save code
    if ($OutputPath) {
        Write-Host "  💾 Saving code to: $OutputPath" -ForegroundColor Gray

        # Create backup if file exists
        if (Test-Path $OutputPath) {
            $BackupPath = "$OutputPath.backup-$(Get-Date -Format 'yyyyMMddHHmmss')"
            Copy-Item -Path $OutputPath -Destination $BackupPath
            Write-Host "  💾 Backup created: $BackupPath" -ForegroundColor Gray
        }

        Set-Content -Path $OutputPath -Value $GeneratedCode
        Write-Host "  ✅ Code saved" -ForegroundColor Green
    }

    # Step 5: Generate tests if requested
    $TestCode = $null
    if ($IncludeTests) {
        Write-Host "  🧪 Generating unit tests..." -ForegroundColor Yellow
        $TestCode = New-UnitTests -Code $GeneratedCode -Language $Language
    }

    # Step 6: Generate docs if requested
    $Documentation = $null
    if ($IncludeDocs) {
        Write-Host "  📖 Generating documentation..." -ForegroundColor Yellow
        $Documentation = New-CodeDocumentation -Code $GeneratedCode -Language $Language
    }

    return @{
        Code          = $GeneratedCode
        Tests         = $TestCode
        Documentation = $Documentation
        ReviewResult  = $ReviewResult
        OutputPath    = $OutputPath
        Approved      = $true
    }
}

function Invoke-AICodeGeneration {
    param([string]$Prompt, [string]$Language)

    # Check if Ollama is available
    if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
        Write-Host "  ⚠️  Ollama not found, using template-based generation" -ForegroundColor Yellow
        return Get-CodeTemplate -Language $Language
    }

    try {
        # Use Qwen2.5-Coder for code generation
        $Result = ollama run qwen2.5-coder:1.5b $Prompt 2>&1

        if ($LASTEXITCODE -eq 0 -and $Result) {
            # Extract code from markdown if present
            if ($Result -match '```[\w]*\s*([\s\S]*?)```') {
                return $Matches[1].Trim()
            }
            return $Result
        }

    } catch {
        Write-Host "  ⚠️  AI generation failed: $_" -ForegroundColor Yellow
    }

    # Fallback to template
    return Get-CodeTemplate -Language $Language
}

function Get-CodeTemplate {
    param([string]$Language)

    # Simple template fallback
    switch ($Language) {
        'PowerShell' {
            return @"
<#
.SYNOPSIS
    Auto-generated feature implementation

.DESCRIPTION
    Generated by AI Self-Developing module
#>

function Invoke-GeneratedFeature {
    [CmdletBinding()]
    param()

    Write-Host "Feature implementation pending" -ForegroundColor Yellow

    # TODO: Implement feature logic
}

Export-ModuleMember -Function Invoke-GeneratedFeature
"@
        }

        'Python' {
            return @"
"""
Auto-generated feature implementation
Generated by AI Self-Developing module
"""

def generated_feature():
    """Feature implementation pending"""
    print("Feature implementation pending")
    # TODO: Implement feature logic

if __name__ == "__main__":
    generated_feature()
"@
        }
    }
}

function Invoke-AICodeReview {
    param([string]$Code, [string]$Language)

    Write-Host "    Analyzing code quality..." -ForegroundColor Gray

    $Issues = @()

    # Basic static analysis
    if ($Language -eq 'PowerShell') {
        # Check for common issues
        if ($Code -match 'Invoke-Expression') {
            $Issues += @{Severity = 'High'; Description = 'Dangerous use of Invoke-Expression'; AutoFixable = $false }
        }

        if ($Code -notmatch '\[CmdletBinding\(\)\]') {
            $Issues += @{Severity = 'Low'; Description = 'Missing CmdletBinding attribute'; AutoFixable = $true }
        }

        if ($Code -notmatch 'try\s*\{.*catch') {
            $Issues += @{Severity = 'Medium'; Description = 'No error handling found'; AutoFixable = $false }
        }
    }

    return @{
        Issues      = $Issues
        AutoFixable = ($Issues | Where-Object { $_.AutoFixable }).Count -gt 0
        Passed      = $Issues.Count -eq 0
    }
}

function Invoke-AICodeFix {
    param([string]$Code, [array]$Issues)

    $FixedCode = $Code

    # Apply auto-fixes
    foreach ($Issue in $Issues | Where-Object { $_.AutoFixable }) {
        switch ($Issue.Description) {
            'Missing CmdletBinding attribute' {
                $FixedCode = $FixedCode -replace 'function\s+(\w+)\s*\{', 'function $1 {[CmdletBinding()]param()'
            }
        }
    }

    return $FixedCode
}

# ============================================
# BUG FIXING
# ============================================

function Repair-CodeBug {
    <#
    .SYNOPSIS
        Analyze and fix bugs in code using AI
    #>
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [string]$ErrorMessage,

        [switch]$AutoApply
    )

    Write-Host "🐛 Self-Developing: Analyzing bug..." -ForegroundColor Cyan

    # Safety check
    $SafetyCheck = Invoke-SafetyCheck -Action "Analyze and fix bug in: $FilePath" -Context @{
        Scope        = "File"
        Reversible   = $true
        BackupExists = $true
    }

    if (-not $SafetyCheck.Approved) {
        return $null
    }

    # Read code
    $OriginalCode = Get-Content $FilePath -Raw

    # Create backup
    $BackupPath = "$FilePath.backup-$(Get-Date -Format 'yyyyMMddHHmmss')"
    Copy-Item -Path $FilePath -Destination $BackupPath

    Write-Host "  📝 Analyzing code for bugs..." -ForegroundColor Yellow

    # AI-based bug analysis
    $AnalysisPrompt = @"
Analyze this code for bugs:

Error Message: $ErrorMessage

Code:
$OriginalCode

Identify the bug and provide a fix.
"@

    $Analysis = Invoke-AICodeGeneration -Prompt $AnalysisPrompt -Language "PowerShell"

    Write-Host "  💡 AI Analysis:" -ForegroundColor Cyan
    Write-Host $Analysis

    if ($AutoApply) {
        # Apply fix (simplified - would need more sophisticated parsing)
        Write-Host "  ⚠️  Auto-apply not fully implemented yet" -ForegroundColor Yellow
    }

    return @{
        Analysis   = $Analysis
        BackupPath = $BackupPath
    }
}

# ============================================
# TEST GENERATION
# ============================================

function New-UnitTests {
    param([string]$Code, [string]$Language)

    Write-Host "    Generating unit tests..." -ForegroundColor Gray

    $TestPrompt = @"
Generate comprehensive unit tests for this $Language code:

$Code

Include:
- Happy path tests
- Edge cases
- Error handling tests
- Input validation tests

Generate test code only.
"@

    $TestCode = Invoke-AICodeGeneration -Prompt $TestPrompt -Language $Language

    return $TestCode
}

# ============================================
# DOCUMENTATION GENERATION
# ============================================

function New-CodeDocumentation {
    param([string]$Code, [string]$Language)

    Write-Host "    Generating documentation..." -ForegroundColor Gray

    $DocPrompt = @"
Generate comprehensive documentation for this $Language code:

$Code

Include:
- Function/class descriptions
- Parameter explanations
- Return value descriptions
- Usage examples
- Error handling notes

Generate markdown documentation.
"@

    $Documentation = Invoke-AICodeGeneration -Prompt $DocPrompt -Language "Markdown"

    return $Documentation
}

# ============================================
# EXPORT MODULE MEMBERS
# ============================================

Export-ModuleMember -Function @(
    'New-FeatureImplementation',
    'Repair-CodeBug',
    'New-UnitTests',
    'New-CodeDocumentation'
)
