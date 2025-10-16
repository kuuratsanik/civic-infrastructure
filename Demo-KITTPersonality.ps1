<#
.SYNOPSIS
    Demo script showing K.I.T.T. using your real name automatically

.DESCRIPTION
    This demo shows how K.I.T.T. personality module automatically detects
    and uses the user's real name instead of hardcoding "Michael".

.EXAMPLE
    .\Demo-KITTPersonality.ps1
#>

Import-Module "$PSScriptRoot\scripts\ai-system\personality\KITT-Personality.ps1" -Force

Write-Host ""
Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "  K.I.T.T. PERSONALITY DEMO - AUTO NAME DETECTION" -ForegroundColor Yellow
Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host ""

Write-Host "🔍 Detecting your real name from Windows..." -ForegroundColor Cyan
Write-Host ""

# Start K.I.T.T. session (will auto-detect your name)
Start-KITTSession -SarcasmLevel 5

Write-Host ""
Write-Host "📝 Demo Messages:" -ForegroundColor Yellow
Write-Host ""

# Various message types with your real name
Write-KITTMessage -Message "All systems are operational and ready for your commands." -Type Info

Start-Sleep -Seconds 1

Write-KITTMessage -Message "Security scan completed successfully. No vulnerabilities detected." -Type Success

Start-Sleep -Seconds 1

Write-KITTMessage -Message "I must advise caution with this registry modification." -Type Warning

Start-Sleep -Seconds 1

Write-KITTMessage -Message "Oh, splendid. Manually editing system files. What could possibly go wrong?" -Type Sarcasm

Start-Sleep -Seconds 1

Write-Host ""
Write-Host "🎯 Notice:" -ForegroundColor Cyan
Write-Host "  K.I.T.T. is using YOUR real name, not 'Michael'!" -ForegroundColor White
Write-Host "  This is automatically detected from your Windows user profile." -ForegroundColor Gray
Write-Host ""

Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host ""

Write-KITTMessage -Message "Demo complete. I remain at your service for any task you require." -Type Success

Write-Host ""
