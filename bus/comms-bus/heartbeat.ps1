# Civic comms-bus heartbeat. Cloud hop only. Does not execute remote commands.
param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot "config.json"),
    [ValidateSet("heartbeat", "notify", "linear", "github", "gmail_draft", "route")]
    [string]$Action = "heartbeat",
    [string]$Subject = "heartbeat",
    [string]$Status = "ok"
)
$ErrorActionPreference = "Stop"
if (-not (Test-Path $ConfigPath)) {
    Write-Error "Missing $ConfigPath — copy config.example.json to config.json and set webhook_url."
}
$config = Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json
if (-not $config.webhook_url -or $config.webhook_url -like "PASTE_*") {
    Write-Error "Set webhook_url in config.json from the comms-bus-webhook automation card."
}
$packet = [ordered]@{
    from_agent = $config.from_agent
    to_agent   = "comms-bus"
    channel    = "webhook"
    action     = $Action
    subject    = $Subject
    lane       = "civic"
    payload    = [ordered]@{
        device = $config.device
        agents = @("heartbeat")
        status = $Status
        queue  = 0
    }
}
$body = $packet | ConvertTo-Json -Depth 6 -Compress
Write-Host "POST $($config.webhook_url)"
try {
    $res = Invoke-RestMethod -Method Post -Uri $config.webhook_url -ContentType "application/json" -Body $body
    $res | ConvertTo-Json -Depth 6
} catch {
    Write-Error $_
    exit 1
}
