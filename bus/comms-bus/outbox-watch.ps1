# Watch civic bus/outbox and POST each new *.json to the comms-bus webhook.
param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot "config.json"),
    [string]$OutboxPath = ""
)
$ErrorActionPreference = "Stop"
if (-not $OutboxPath) {
    $OutboxPath = Join-Path (Split-Path $PSScriptRoot -Parent) "outbox"
}
if (-not (Test-Path $ConfigPath)) { Write-Error "Missing $ConfigPath" }
$config = Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json
if (-not $config.webhook_url -or $config.webhook_url -like "PASTE_*") {
    Write-Error "Set webhook_url in config.json"
}
if (-not (Test-Path $OutboxPath)) {
    New-Item -ItemType Directory -Path $OutboxPath | Out-Null
}
Write-Host "Watching $OutboxPath"
Get-ChildItem -Path $OutboxPath -Filter *.json -ErrorAction SilentlyContinue | ForEach-Object {
    $body = Get-Content -Raw -Path $_.FullName
    try {
        Invoke-RestMethod -Method Post -Uri $config.webhook_url -ContentType "application/json" -Body $body | Out-Null
        Move-Item $_.FullName (Join-Path $OutboxPath ($_.BaseName + ".sent")) -Force
        Write-Host "sent $($_.Name)"
    } catch {
        Write-Warning "fail $($_.Name): $_"
    }
}
