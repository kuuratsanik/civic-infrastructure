# Windows service helper notes (Scheduled Task is used — no admin Windows Service required).
# Install via:
#   pwsh ./scripts/cross-platform/Install-CivicService.ps1
# Uninstall:
#   Unregister-ScheduledTask -TaskName CivicInfrastructureOrchestrator -Confirm:$false
