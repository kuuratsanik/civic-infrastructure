# PSScriptAnalyzer Settings for AI-Powered Civic Infrastructure
# This file configures code quality rules for PowerShell scripts

@{
    # Enable all default rules
    IncludeDefaultRules = $true

    # Severity levels to report: Error, Warning, Information
    Severity            = @('Error', 'Warning', 'Information')

    # Exclude specific rules if needed
    ExcludeRules        = @(
        # 'PSAvoidUsingCmdletAliases',  # We auto-correct these
        # 'PSAvoidUsingWriteHost'       # We use Write-Host for colored output
    )

    # Custom rule configurations
    Rules               = @{
        PSPlaceOpenBrace           = @{
            Enable             = $true
            OnSameLine         = $true
            NewLineAfter       = $true
            IgnoreOneLineBlock = $true
        }

        PSPlaceCloseBrace          = @{
            Enable             = $true
            NewLineAfter       = $false
            IgnoreOneLineBlock = $true
            NoEmptyLineBefore  = $false
        }

        PSUseConsistentIndentation = @{
            Enable          = $true
            Kind            = 'space'
            IndentationSize = 4
        }

        PSUseConsistentWhitespace  = @{
            Enable         = $true
            CheckOpenBrace = $true
            CheckOpenParen = $true
            CheckOperator  = $true
            CheckSeparator = $true
        }

        PSAlignAssignmentStatement = @{
            Enable         = $true
            CheckHashtable = $true
        }

        PSAvoidUsingCmdletAliases  = @{
            Enable    = $true
            Whitelist = @()
        }

        PSAvoidUsingWriteHost      = @{
            Enable = $false  # We use Write-Host for colored terminal output
        }

        PSProvideCommentHelp       = @{
            Enable                  = $true
            ExportedOnly            = $false
            BlockComment            = $true
            VSCodeSnippetCorrection = $true
            Placement               = 'before'
        }
    }
}
