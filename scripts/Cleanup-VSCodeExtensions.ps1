#Requires -Version 5.1
<#
.SYNOPSIS
    Audit and cleanup VS Code extensions to meet 100-extension policy

.DESCRIPTION
    Lists all installed extensions, categorizes them, and provides
    recommendations for removal to stay under 100-extension limit

.PARAMETER DryRun
    Show what would be removed without actually removing

.PARAMETER AutoRemove
    Automatically remove suggested extensions (use with caution!)

.PARAMETER Interactive
    Interactively choose which extensions to remove

.EXAMPLE
    .\Cleanup-VSCodeExtensions.ps1
    Shows current status and suggestions

.EXAMPLE
    .\Cleanup-VSCodeExtensions.ps1 -Interactive
    Interactively choose extensions to remove

.NOTES
    Policy: DO NOT EXCEED 100 VS CODE TOOLS AND EXTENSIONS
    Created: 17. oktoober 2025
#>

param(
  [switch]$DryRun,
  [switch]$AutoRemove,
  [switch]$Interactive
)

$ErrorActionPreference = 'Stop'

Write-Host "`n"
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host "    VS CODE EXTENSION AUDIT & CLEANUP" -ForegroundColor Cyan
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host "`n"

# Get all extensions
Write-Host "[*] Scanning installed extensions..." -ForegroundColor Yellow
$extensions = code --list-extensions
$count = ($extensions | Measure-Object).Count

Write-Host "`nCurrent Status:" -ForegroundColor Yellow
Write-Host "   Total Extensions:  $count" -ForegroundColor White
Write-Host "   Policy Limit:      100" -ForegroundColor $(if ($count -gt 100) { 'Red' } else { 'Green' })
Write-Host "   System Limit:      128" -ForegroundColor White

if ($count -le 100) {
  Write-Host "`n✅ COMPLIANT - Under policy limit!" -ForegroundColor Green
  Write-Host "   You have $($100 - $count) extensions of headroom.`n" -ForegroundColor Gray
  exit 0
}

$excess = $count - 100
Write-Host "   Excess:            $excess extensions" -ForegroundColor Red
Write-Host "`n⚠️  ACTION REQUIRED: Must remove at least $excess extensions`n" -ForegroundColor Yellow

# Define low-priority patterns (likely removable)
$lowPriorityPatterns = @(
  @{ Pattern = 'theme'; Reason = 'Theme (keep 1-2 max)'; Priority = 3 }
  @{ Pattern = 'icon'; Reason = 'Icon pack (keep 1 max)'; Priority = 3 }
  @{ Pattern = 'color'; Reason = 'Color scheme'; Priority = 3 }
  @{ Pattern = 'language-pack'; Reason = 'UI language pack'; Priority = 2 }
  @{ Pattern = 'vscode-language'; Reason = 'Syntax highlighting only'; Priority = 2 }
  @{ Pattern = 'deprecated'; Reason = 'Deprecated extension'; Priority = 1 }
  @{ Pattern = 'legacy'; Reason = 'Legacy extension'; Priority = 1 }
  @{ Pattern = 'old'; Reason = 'Outdated extension'; Priority = 1 }
)

# Critical extensions to NEVER remove
$criticalExtensions = @(
  'github.copilot',
  'github.copilot-chat',
  'ms-python.python',
  'ms-vscode.powershell',
  'ms-azuretools.vscode-docker',
  'ms-vscode-remote.remote-wsl'
)

Write-Host "[*] Analyzing extensions for removal candidates...`n" -ForegroundColor Cyan

$suggestions = @()

foreach ($ext in $extensions) {
  # Skip critical extensions
  if ($criticalExtensions -contains $ext) {
    continue
  }

  # Check against low-priority patterns
  foreach ($pattern in $lowPriorityPatterns) {
    if ($ext -match $pattern.Pattern) {
      $suggestions += [PSCustomObject]@{
        Extension = $ext
        Reason    = $pattern.Reason
        Priority  = $pattern.Priority
      }
      break
    }
  }
}

# If not enough suggestions, add more based on publisher
if ($suggestions.Count -lt $excess) {
  $extensions | Where-Object {
    $_ -notin $criticalExtensions -and
    $_ -notin $suggestions.Extension
  } | ForEach-Object {
    if ($suggestions.Count -lt ($excess + 10)) {
      $suggestions += [PSCustomObject]@{
        Extension = $_
        Reason    = 'Review manually - non-critical'
        Priority  = 4
      }
    }
  }
}

# Display suggestions
Write-Host "[!] Removal Suggestions (showing top $($excess + 10)):`n" -ForegroundColor Yellow

$sortedSuggestions = $suggestions | Sort-Object Priority, Extension

$i = 1
foreach ($sug in $sortedSuggestions | Select-Object -First ($excess + 10)) {
  $color = switch ($sug.Priority) {
    1 { 'Red' }
    2 { 'Yellow' }
    3 { 'Cyan' }
    default { 'Gray' }
  }

  Write-Host "   [$i] " -NoNewline -ForegroundColor Gray
  Write-Host "$($sug.Extension)" -ForegroundColor White
  Write-Host "       Reason: $($sug.Reason)" -ForegroundColor $color
  Write-Host ""
  $i++
}

# Interactive mode
if ($Interactive) {
  Write-Host "`n[+] Interactive Removal Mode" -ForegroundColor Cyan
  Write-Host "You need to remove at least $excess extensions`n" -ForegroundColor Yellow  $toRemove = @()
  $i = 1

  foreach ($sug in $sortedSuggestions) {
    if ($toRemove.Count -ge $excess) {
      break
    }

    Write-Host "[$i/$($sortedSuggestions.Count)] " -NoNewline -ForegroundColor Gray
    Write-Host "$($sug.Extension)" -ForegroundColor White
    Write-Host "    Reason: $($sug.Reason)" -ForegroundColor Cyan

    $response = Read-Host "    Remove? [Y/n/q]"

    if ($response -eq 'q') {
      Write-Host "`nOperation cancelled by user.`n" -ForegroundColor Yellow
      exit 0
    }

    if ($response -eq '' -or $response -eq 'y' -or $response -eq 'Y') {
      $toRemove += $sug.Extension
      Write-Host "    ✓ Marked for removal" -ForegroundColor Green
    } else {
      Write-Host "    ⊗ Skipped" -ForegroundColor Gray
    }

    Write-Host ""
    $i++
  }

  if ($toRemove.Count -lt $excess) {
    Write-Host "⚠️  Warning: Only marked $($toRemove.Count)/$excess extensions for removal" -ForegroundColor Yellow
    $continue = Read-Host "Continue anyway? [y/N]"

    if ($continue -ne 'y' -and $continue -ne 'Y') {
      Write-Host "`nOperation cancelled.`n" -ForegroundColor Yellow
      exit 0
    }
  }

  Write-Host "`n🗑️  Removing $($toRemove.Count) extensions..." -ForegroundColor Red

  foreach ($ext in $toRemove) {
    Write-Host "   Removing: $ext" -ForegroundColor Gray
    code --uninstall-extension $ext 2>&1 | Out-Null

    if ($LASTEXITCODE -eq 0) {
      Write-Host "   ✓ Removed successfully" -ForegroundColor Green
    } else {
      Write-Host "   ✗ Failed to remove" -ForegroundColor Red
    }
  }

  $newCount = (code --list-extensions | Measure-Object).Count
  Write-Host "`n✅ Cleanup complete!" -ForegroundColor Green
  Write-Host "   Extensions: $newCount/100" -ForegroundColor $(if ($newCount -le 100) { 'Green' } else { 'Yellow' })
  Write-Host "`n"

  exit 0
}

# Auto-remove mode
if ($AutoRemove -and -not $DryRun) {
  Write-Host "🗑️  Auto-removing suggested extensions..." -ForegroundColor Red
  Write-Host "   (This will remove the top $excess priority items)`n" -ForegroundColor Yellow

  Start-Sleep -Seconds 3

  $removed = 0
  foreach ($sug in ($sortedSuggestions | Select-Object -First $excess)) {
    Write-Host "   Removing: $($sug.Extension)" -ForegroundColor Gray
    code --uninstall-extension $sug.Extension 2>&1 | Out-Null

    if ($LASTEXITCODE -eq 0) {
      $removed++
    }
  }

  $newCount = (code --list-extensions | Measure-Object).Count
  Write-Host "`n✅ Cleanup complete!" -ForegroundColor Green
  Write-Host "   Removed: $removed extensions" -ForegroundColor White
  Write-Host "   Extensions: $newCount/100" -ForegroundColor $(if ($newCount -le 100) { 'Green' } else { 'Yellow' })
  Write-Host "`n"
} else {
  Write-Host "ℹ️  This is a dry run. To remove extensions:" -ForegroundColor Cyan
  Write-Host "`n   Option 1 (Interactive - Recommended):" -ForegroundColor Yellow
  Write-Host "   .\Cleanup-VSCodeExtensions.ps1 -Interactive`n" -ForegroundColor Gray

  Write-Host "   Option 2 (Automatic - Use with caution):" -ForegroundColor Yellow
  Write-Host "   .\Cleanup-VSCodeExtensions.ps1 -AutoRemove`n" -ForegroundColor Gray

  Write-Host "   Option 3 (Manual):" -ForegroundColor Yellow
  Write-Host "   code --uninstall-extension EXTENSION.NAME`n" -ForegroundColor Gray
}

Write-Host "📝 Tip: Export your extension list first:" -ForegroundColor Cyan
Write-Host "   code --list-extensions > extensions-backup-$(Get-Date -Format 'yyyyMMdd').txt`n" -ForegroundColor Gray
