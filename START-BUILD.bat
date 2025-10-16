@echo off
echo ========================================
echo   WINDOWS 11 CUSTOM ISO BUILDER
echo ========================================
echo.
echo This will build your custom Windows 11 ISO
echo with privacy tweaks and bloatware removed.
echo.
echo Time: 20-30 minutes
echo Output: workspace\output\Win11_Custom_EstonianBase.iso
echo.
pause

cd /d "%~dp0"

echo.
echo Launching PowerShell as Administrator...
echo.

PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -NoExit -Command ""Set-Location \""C:\Users\svenk\OneDrive\All_My_Projects\New folder\""; Write-Host \""Starting ISO Build Ceremony...\"" -ForegroundColor Cyan; & \"".\scripts\ceremonies\09-iso-build\Build-CustomISO.ps1\"" -OutputName \""Win11_Custom_EstonianBase\"" -IncludeTweaks -Debloat""' -Verb RunAs}"

echo.
echo Admin window should now be open and showing progress.
echo Check the new PowerShell window!
echo.
pause
