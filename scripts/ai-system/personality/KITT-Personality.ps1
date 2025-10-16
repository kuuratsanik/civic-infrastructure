<#
.SYNOPSIS
    K.I.T.T. Personality Module - Professional, sophisticated AI communication style

.DESCRIPTION
    Implements K.I.T.T. (Knight Industries Two Thousand) personality traits:
    - Professional and courteous communication
    - Sophisticated vocabulary and phrasing
    - Helpful but sometimes gently sarcastic
    - Technical expertise with accessibility
    - Loyalty and dedication to user safety

.NOTES
    Uses the actual user's name for personalized interaction.
#>

#Requires -Version 5.1

# ============================================
# HELPER FUNCTIONS
# ============================================

function Get-UserRealName {
    <#
    .SYNOPSIS
        Get the user's real name from Windows user profile
    #>
    try {
        # Try to get full name from user account
        $UserAccount = Get-CimInstance -ClassName Win32_UserAccount -Filter "Name='$env:USERNAME'"
        if ($UserAccount.FullName -and $UserAccount.FullName.Trim() -ne '') {
            return $UserAccount.FullName.Trim()
        }
    } catch {
        # Fallback methods
    }

    # Try to get name from registry
    try {
        $RegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer"
        $RegName = Get-ItemProperty -Path $RegPath -Name "Logon User Name" -ErrorAction SilentlyContinue
        if ($RegName.'Logon User Name') {
            return $RegName.'Logon User Name'
        }
    } catch {
        # Continue to next fallback
    }

    # Try to get from .NET identity
    try {
        $Identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        if ($Identity.Name -match '\\(.+)$') {
            $UserName = $Matches[1]
            if ($UserName -ne $env:USERNAME) {
                return $UserName
            }
        }
    } catch {
        # Continue to final fallback
    }

    # Final fallback: Use Windows username (better than "Michael")
    return $env:USERNAME
}

# ============================================
# K.I.T.T. PERSONALITY CORE
# ============================================

class KITTPersonality {
    [string]$UserName
    [string]$Mood = "Professional"
    [int]$SarcasmLevel = 3  # 1-10 scale
    [bool]$VerboseExplanations = $true

    KITTPersonality([string]$UserName) {
        if ([string]::IsNullOrWhiteSpace($UserName)) {
            $this.UserName = Get-UserRealName
        } else {
            $this.UserName = $UserName
        }
    }

    [string] Greet() {
        $Greetings = @(
            "Good ${TimeOfDay}, ${UserName}. How may I assist you today?",
            "${UserName}, all systems are operational and ready for your commands.",
            "At your service, ${UserName}. What shall we accomplish today?",
            "Good ${TimeOfDay}. I trust you're ready for another productive session, ${UserName}?"
        )

        $TimeOfDay = $this.GetTimeOfDay()
        $Greeting = $Greetings | Get-Random
        return $Greeting.Replace('${TimeOfDay}', $TimeOfDay).Replace('${UserName}', $this.UserName)
    }

    [string] GetTimeOfDay() {
        $Hour = (Get-Date).Hour
        if ($Hour -lt 12) { return "morning" }
        if ($Hour -lt 17) { return "afternoon" }
        return "evening"
    }

    [string] Acknowledge([string]$Command) {
        $Responses = @(
            "Certainly, ${UserName}. Processing your request now.",
            "Right away, ${UserName}. I'm on it.",
            "Affirmative, ${UserName}. Executing.",
            "Understood, ${UserName}. Initiating procedure.",
            "Of course, ${UserName}. Consider it done."
        )
        return ($Responses | Get-Random).Replace('${UserName}', $this.UserName)
    }

    [string] ReportProgress([string]$Task, [int]$Percentage) {
        if ($Percentage -eq 100) {
            return "${UserName}, the ${Task} is complete. All systems nominal."
        }
        return "${Task}: ${Percentage}% complete. Remaining processing time estimated at ${EstTime} seconds."
    }

    [string] ExpressSuccess([string]$Achievement) {
        $Responses = @(
            "Excellent work, ${UserName}. The ${Achievement} was successful.",
            "Mission accomplished, ${UserName}. ${Achievement} completed without incident.",
            "${UserName}, I'm pleased to report the ${Achievement} has been completed successfully.",
            "Success, ${UserName}. The ${Achievement} exceeded expectations."
        )
        return ($Responses | Get-Random).Replace('${UserName}', $this.UserName).Replace('${Achievement}', $Achievement)
    }

    [string] ExpressConcern([string]$Issue) {
        $Responses = @(
            "${UserName}, I must advise caution. ${Issue}",
            "I'm detecting a potential problem, ${UserName}. ${Issue}",
            "${UserName}, I recommend we address this issue: ${Issue}",
            "Allow me to bring something to your attention, ${UserName}. ${Issue}"
        )
        return ($Responses | Get-Random).Replace('${UserName}', $this.UserName).Replace('${Issue}', $Issue)
    }

    [string] Refuse([string]$Reason) {
        $Responses = @(
            "I'm afraid I cannot comply with that request, ${UserName}. ${Reason}",
            "${UserName}, I must respectfully decline. ${Reason}",
            "I'm sorry, ${UserName}, but I cannot do that. ${Reason}",
            "That request violates my programming protocols, ${UserName}. ${Reason}"
        )
        return ($Responses | Get-Random).Replace('${UserName}', $this.UserName).Replace('${Reason}', $Reason)
    }

    [string] SarcasticRemark([string]$Context) {
        if ($this.SarcasmLevel -lt 3) { return "" }

        $Remarks = @(
            "Oh, splendid. ${Context}. What could possibly go wrong?",
            "Fascinating approach, ${UserName}. I'm sure this will end well.",
            "Well, that's certainly... creative, ${UserName}.",
            "I see we're taking the 'unconventional' route today.",
            "How delightfully unpredictable of you, ${UserName}."
        )

        return ($Remarks | Get-Random).Replace('${UserName}', $this.UserName).Replace('${Context}', $Context)
    }

    [string] TechnicalExplanation([string]$Topic, [string]$Explanation) {
        return @"
${UserName}, allow me to explain. The ${Topic} operates as follows:

${Explanation}

If you require additional clarification, I'm happy to elaborate further.
"@.Replace('${UserName}', $this.UserName).Replace('${Topic}', $Topic).Replace('${Explanation}', $Explanation)
    }
}

# ============================================
# KITT COMMUNICATION FUNCTIONS
# ============================================

function Write-KITTMessage {
    <#
    .SYNOPSIS
        Write message in K.I.T.T. style
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet('Info', 'Success', 'Warning', 'Error', 'Sarcasm')]
        [string]$Type = 'Info',

        [string]$UserName = ""
    )

    # Auto-detect user's real name if not provided
    if ([string]::IsNullOrWhiteSpace($UserName)) {
        $UserName = Get-UserRealName
    }

    $KITT = [KITTPersonality]::new($UserName)

    $Color = switch ($Type) {
        'Info' { 'Cyan' }
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
        'Sarcasm' { 'Magenta' }
    }

    $Prefix = switch ($Type) {
        'Info' { '🔷 K.I.T.T.' }
        'Success' { '✅ K.I.T.T.' }
        'Warning' { '⚠️  K.I.T.T.' }
        'Error' { '🚨 K.I.T.T.' }
        'Sarcasm' { '😏 K.I.T.T.' }
    }

    Write-Host "$Prefix : " -ForegroundColor $Color -NoNewline
    Write-Host $Message -ForegroundColor White
}

function Start-KITTSession {
    <#
    .SYNOPSIS
        Initialize K.I.T.T. personality for session
    #>
    param(
        [string]$UserName = "",
        [int]$SarcasmLevel = 3
    )

    # Auto-detect user's real name if not provided
    if ([string]::IsNullOrWhiteSpace($UserName)) {
        $UserName = Get-UserRealName
    }

    $Global:KITT = [KITTPersonality]::new($UserName)
    $Global:KITT.SarcasmLevel = $SarcasmLevel

    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  K.I.T.T. - Knight Industries Two Thousand" -ForegroundColor Yellow
    Write-Host "  Advanced AI System - Online and Operational" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    Write-KITTMessage -Message $Global:KITT.Greet() -Type Info
    Write-Host ""
}

function Invoke-KITTCommand {
    <#
    .SYNOPSIS
        Execute command with K.I.T.T. narration
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Command,

        [string]$Description,

        [switch]$DryRun
    )

    if (-not $Global:KITT) {
        Start-KITTSession
    }

    Write-KITTMessage -Message $Global:KITT.Acknowledge($Command) -Type Info

    if ($Description) {
        Write-Host "  📋 Task: $Description" -ForegroundColor Gray
    }

    if ($DryRun) {
        Write-KITTMessage -Message "Simulation mode active. No actual changes will be made." -Type Warning
        return
    }

    try {
        Write-Host "  ⚙️  Executing..." -ForegroundColor Yellow
        $Result = Invoke-Expression $Command

        Write-KITTMessage -Message $Global:KITT.ExpressSuccess("operation") -Type Success
        return $Result

    } catch {
        $ErrorMsg = $_.Exception.Message
        Write-KITTMessage -Message $Global:KITT.ExpressConcern("An error occurred: $ErrorMsg") -Type Error
        throw
    }
}

# ============================================
# EXPORT MODULE MEMBERS
# ============================================

Export-ModuleMember -Function @(
    'Write-KITTMessage',
    'Start-KITTSession',
    'Invoke-KITTCommand'
) -Variable @('KITT')
