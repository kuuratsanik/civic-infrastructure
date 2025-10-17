# Setup-N8nWorkflows.ps1
# Automated n8n workflow setup helper for civic-infrastructure
# This script automates as much as possible and guides you through the rest

param(
  [switch]$SkipPasswordChange,
  [switch]$ExportOnly
)

$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  n8n Workflow Setup Automation" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan

# Check if n8n is running
Write-Host "Checking n8n status..." -ForegroundColor Yellow
$container = docker ps --filter "name=civic-n8n" --format "{{.Status}}"
if (-not $container) {
  Write-Host "❌ n8n container not running!" -ForegroundColor Red
  Write-Host "Start it with: docker-compose up -d" -ForegroundColor Yellow
  exit 1
}
Write-Host "✅ n8n is running ($container)" -ForegroundColor Green

# Check n8n accessibility
Write-Host "`nChecking n8n web UI..." -ForegroundColor Yellow
try {
  $response = Invoke-WebRequest -Uri "http://localhost:5678" -Method GET -TimeoutSec 5 -UseBasicParsing
  Write-Host "✅ n8n UI is accessible" -ForegroundColor Green
} catch {
  Write-Host "⚠️ n8n UI not responding yet (may still be starting)" -ForegroundColor Yellow
  Write-Host "Waiting 10 seconds..." -ForegroundColor Yellow
  Start-Sleep -Seconds 10
}

# Step 1: Password Change
if (-not $SkipPasswordChange) {
  Write-Host "`n" -NoNewline
  Write-Host "========================================" -ForegroundColor Cyan
  Write-Host "  STEP 1: Change Default Password" -ForegroundColor Yellow
  Write-Host "========================================" -ForegroundColor Cyan

  Write-Host "`n⚠️  CRITICAL: You must change the default password!" -ForegroundColor Red
  Write-Host "Current password: ChangeMeToSecurePassword!" -ForegroundColor Yellow

  Write-Host "`nOptions:" -ForegroundColor Cyan
  Write-Host "  1. Edit docker-compose.yml manually (recommended)" -ForegroundColor White
  Write-Host "  2. I'll generate a secure password for you" -ForegroundColor White
  Write-Host "  3. Skip for now (NOT RECOMMENDED)" -ForegroundColor DarkGray

  $choice = Read-Host "`nYour choice (1/2/3)"

  switch ($choice) {
    "1" {
      Write-Host "`nOpening docker-compose.yml..." -ForegroundColor Green
      code docker-compose.yml
      Write-Host "1. Find line: N8N_BASIC_AUTH_PASSWORD=ChangeMeToSecurePassword!" -ForegroundColor Yellow
      Write-Host "2. Change to a secure password" -ForegroundColor Yellow
      Write-Host "3. Save the file" -ForegroundColor Yellow
      Write-Host "4. Run: docker-compose restart n8n" -ForegroundColor Yellow
      Read-Host "`nPress Enter when done"
    }
    "2" {
      # Generate secure password
      Add-Type -AssemblyName 'System.Web'
      $newPassword = [System.Web.Security.Membership]::GeneratePassword(24, 8)

      Write-Host "`n✅ Generated secure password:" -ForegroundColor Green
      Write-Host $newPassword -ForegroundColor Cyan
      Write-Host "`n⚠️  SAVE THIS PASSWORD SECURELY!" -ForegroundColor Red

      # Update docker-compose.yml
      $composePath = "docker-compose.yml"
      $content = Get-Content $composePath -Raw
      $content = $content -replace 'N8N_BASIC_AUTH_PASSWORD=ChangeMeToSecurePassword!', "N8N_BASIC_AUTH_PASSWORD=$newPassword"
      Set-Content $composePath -Value $content

      Write-Host "✅ docker-compose.yml updated" -ForegroundColor Green
      Write-Host "Restarting n8n container..." -ForegroundColor Yellow
      docker-compose restart n8n
      Start-Sleep -Seconds 5
      Write-Host "✅ n8n restarted with new password" -ForegroundColor Green
    }
    "3" {
      Write-Host "`n⚠️  Skipping password change (NOT SECURE!)" -ForegroundColor Red
    }
  }
}

# Step 2: Prerequisites Check
Write-Host "`n" -NoNewline
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  STEP 2: Prerequisites Check" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`nFor Workflow 1 (Blockchain Backup), you need:" -ForegroundColor White
Write-Host "  ✓ Azure Blob Storage account" -ForegroundColor Yellow
Write-Host "  ✓ Discord webhook URL" -ForegroundColor Yellow

Write-Host "`nDo you have these ready? (y/n)" -ForegroundColor Cyan
$hasPrereqs = Read-Host

if ($hasPrereqs -eq "n") {
  Write-Host "`n📋 Quick Setup Instructions:" -ForegroundColor Yellow

  Write-Host "`n1️⃣  Azure Blob Storage:" -ForegroundColor Cyan
  Write-Host "   - Go to: https://portal.azure.com" -ForegroundColor White
  Write-Host "   - Create Storage Account or use existing" -ForegroundColor White
  Write-Host "   - Create container: blockchain-backups-immutable" -ForegroundColor White
  Write-Host "   - Enable versioning and immutability with 90-day lock" -ForegroundColor White
  Write-Host "   - Copy Account Name and Access Key" -ForegroundColor White  Write-Host "`n2️⃣  Discord Webhook:" -ForegroundColor Cyan
  Write-Host "   - Open Discord → Server Settings → Integrations" -ForegroundColor White
  Write-Host "   - Create Webhook → Name: Civic Blockchain Alerts" -ForegroundColor White
  Write-Host "   - Copy webhook URL" -ForegroundColor White

  Write-Host "`nPress Enter when ready to continue..." -ForegroundColor Yellow
  Read-Host
}

# Step 3: Collect Credentials
Write-Host "`n" -NoNewline
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  STEP 3: Collect Credentials" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`nI'll help you prepare the credentials for n8n..." -ForegroundColor White

$creds = @{}

Write-Host "`n📦 Azure Blob Storage:" -ForegroundColor Cyan
$creds.AzureAccountName = Read-Host "  Account Name (e.g., civicstorage)"
$creds.AzureAccountKey = Read-Host "  Account Key" -AsSecureString
$creds.AzureContainer = Read-Host "  Container Name (default: blockchain-backups-immutable)"
if (-not $creds.AzureContainer) { $creds.AzureContainer = "blockchain-backups-immutable" }

Write-Host "`n💬 Discord:" -ForegroundColor Cyan
$creds.DiscordWebhook = Read-Host "  Webhook URL"

# Save credentials template
$credsTemplate = @"
# n8n Credentials Reference
# Copy these into n8n UI when creating credentials

## Azure Blob Storage
Account Name: $($creds.AzureAccountName)
Account Key: [PASTE FROM SECURE STORAGE]
Container: $($creds.AzureContainer)

## Discord Webhook
Webhook URL: $($creds.DiscordWebhook)

## OpenAI (if needed)
API Key: [YOUR OPENAI API KEY]
"@

Set-Content "n8n-credentials-REFERENCE.txt" -Value $credsTemplate
Write-Host "`n✅ Credentials saved to: n8n-credentials-REFERENCE.txt" -ForegroundColor Green

# Step 4: Generate Workflow JSON
Write-Host "`n" -NoNewline
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  STEP 4: Generate Workflow Templates" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

# Create workflows directory
if (-not (Test-Path "workflows")) {
  New-Item -ItemType Directory -Path "workflows" | Out-Null
}

# Workflow 1: Blockchain Backup
$workflow1 = @{
  name        = "Blockchain Backup (Every 4 Hours)"
  nodes       = @(
    @{
      parameters  = @{
        rule = @{
          interval = @(
            @{
              field         = "hours"
              hoursInterval = 4
            }
          )
        }
      }
      name        = "Schedule Trigger"
      type        = "n8n-nodes-base.scheduleTrigger"
      typeVersion = 1.2
      position    = @(300, 300)
    },
    @{
      parameters  = @{
        filePath = "/civic/logs/council_ledger.jsonl"
      }
      name        = "Read Blockchain Ledger"
      type        = "n8n-nodes-base.readBinaryFiles"
      typeVersion = 1
      position    = @(500, 300)
    },
    @{
      parameters  = @{
        jsCode = @"
// Generate timestamped filename
const now = new Date();
const timestamp = now.toISOString().replace(/[:.]/g, '-');
const filename = ``council_ledger_`${timestamp}.jsonl``;

return [{
  json: {
    filename: filename,
    timestamp: now.toISOString(),
    originalPath: '/civic/logs/council_ledger.jsonl'
  },
  binary: {
    data: `$input.item.binary.data
  }
}];
"@
      }
      name        = "Generate Filename"
      type        = "n8n-nodes-base.code"
      typeVersion = 2
      position    = @(700, 300)
    }
  )
  connections = @{
    "Schedule Trigger"       = @{
      main = @(
        @(
          @{
            node  = "Read Blockchain Ledger"
            type  = "main"
            index = 0
          }
        )
      )
    }
    "Read Blockchain Ledger" = @{
      main = @(
        @(
          @{
            node  = "Generate Filename"
            type  = "main"
            index = 0
          }
        )
      )
    }
  }
}

$workflow1Json = $workflow1 | ConvertTo-Json -Depth 10 -Compress
Set-Content "workflows/workflow1-blockchain-backup-TEMPLATE.json" -Value $workflow1Json

Write-Host "✅ Workflow 1 template generated" -ForegroundColor Green

# Step 5: Open n8n and provide instructions
Write-Host "`n" -NoNewline
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  STEP 5: Next Actions" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`n🎯 What to do next:" -ForegroundColor Green

Write-Host "`n1️⃣  Open n8n UI:" -ForegroundColor Cyan
Write-Host "   URL: http://localhost:5678" -ForegroundColor White
Write-Host "   Login: civic-admin / [your password]" -ForegroundColor White

Write-Host "`n2️⃣  Add Credentials:" -ForegroundColor Cyan
Write-Host "   - Go to Credentials menu (left sidebar)" -ForegroundColor White
Write-Host "   - Click 'Add Credential'" -ForegroundColor White
Write-Host "   - Add: Azure Blob Storage (use n8n-credentials-REFERENCE.txt)" -ForegroundColor White
Write-Host "   - Add: Discord Webhook" -ForegroundColor White

Write-Host "`n3️⃣  Create Workflow 1:" -ForegroundColor Cyan
Write-Host "   - Click '+ Workflow'" -ForegroundColor White
Write-Host "   - Follow: WORKFLOW-1-BLOCKCHAIN-BACKUP.md" -ForegroundColor White
Write-Host "   - Or import: workflows/workflow1-blockchain-backup-TEMPLATE.json" -ForegroundColor White

Write-Host "`n4️⃣  Test & Activate:" -ForegroundColor Cyan
Write-Host "   - Execute workflow manually (test)" -ForegroundColor White
Write-Host "   - Verify backup in Azure" -ForegroundColor White
Write-Host "   - Check Discord notification" -ForegroundColor White
Write-Host "   - Activate workflow (toggle ON)" -ForegroundColor White

Write-Host "`n📚 Documentation:" -ForegroundColor Yellow
Write-Host "   - Complete guide: WORKFLOW-1-BLOCKCHAIN-BACKUP.md" -ForegroundColor White
Write-Host "   - Credentials reference: n8n-credentials-REFERENCE.txt" -ForegroundColor White
Write-Host "   - Main README: README.md" -ForegroundColor White

# Offer to open browser
Write-Host "`n🌐 Open n8n in browser now? (y/n)" -ForegroundColor Cyan
$openBrowser = Read-Host

if ($openBrowser -eq "y") {
  Start-Process "http://localhost:5678"
  Write-Host "✅ Browser opened to http://localhost:5678" -ForegroundColor Green
}

# Success summary
Write-Host "`n" -NoNewline
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ✅ SETUP HELPER COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`n📊 What's Ready:" -ForegroundColor Yellow
Write-Host "  ✅ n8n container running" -ForegroundColor Green
Write-Host "  ✅ Credentials collected" -ForegroundColor Green
Write-Host "  ✅ Workflow template generated" -ForegroundColor Green
Write-Host "  ✅ Documentation available" -ForegroundColor Green

Write-Host "`n⏱️  Estimated time to first working workflow: 20-30 minutes" -ForegroundColor Magenta
Write-Host "🎯 Your blockchain will be protected soon!" -ForegroundColor Cyan

Write-Host "`n========================================`n" -ForegroundColor Cyan
