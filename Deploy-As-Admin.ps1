# Launch deployment with administrator privileges

$scriptPath = Join-Path $PSScriptRoot "Deploy-FullPower.ps1"

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  Write-Host "Launching deployment with administrator privileges..." -ForegroundColor Cyan
  Write-Host ""

  # Relaunch as administrator
  Start-Process powershell.exe -Verb RunAs -ArgumentList @(
    "-ExecutionPolicy", "Bypass",
    "-NoExit",
    "-File", "`"$scriptPath`"",
    "-Mode", "Full"
  )

  Write-Host "Admin PowerShell window opened" -ForegroundColor Green
  Write-Host "Watch the new window for deployment progress..." -ForegroundColor Gray
  Write-Host ""

  exit
}

# If already admin, run directly
& $scriptPath -Mode Full
