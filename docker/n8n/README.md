# n8n Self-Healing Automation for civic-infrastructure

## 🎯 Purpose

This directory contains the n8n automation platform deployment for civic-infrastructure self-healing workflows.

## 📦 What's Included

- `docker-compose.yml` - n8n container configuration
- `n8n-data/` - Persistent workflow data (auto-created)
- Workflow templates (will be imported via UI)

## 🚀 Quick Start

### 1. Start n8n

```powershell
# Navigate to this directory
cd docker/n8n

# Start n8n container
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f n8n
```

### 2. Access n8n Web UI

Open browser: http://localhost:5678

**Default Credentials:**

- Username: `civic-admin`
- Password: `ChangeMeToSecurePassword!`

**⚠️ IMPORTANT:** Change the password in `docker-compose.yml` before first start!

### 3. Import Workflows

After logging in, import these workflows:

#### Workflow 1: Blockchain Backup (Every 4 Hours) 🔥 **PRIORITY**

**Purpose:** Backup blockchain ledger to Azure Blob Storage (immutable)

**Nodes:**

1. **Schedule Trigger** - Every 4 hours
2. **Read Binary File** - `/civic/logs/council_ledger.jsonl`
3. **Azure Blob Storage** - Upload with timestamp
4. **Discord Webhook** - Success/failure notification

#### Workflow 2: Evidence Bundle Validation (On File Create)

**Purpose:** Validate evidence bundles on creation

**Nodes:**

1. **File Trigger** - Watch `/civic/evidence/bundles/`
2. **PowerShell Script** - Calculate merkle root
3. **Compare** - Validate against blockchain
4. **If** - Valid or Invalid
5. **Discord Webhook** - Alert on invalid

#### Workflow 3: Service Health Check (Every 15 Minutes)

**Purpose:** Monitor critical services and auto-remediate

**Nodes:**

1. **Schedule Trigger** - Every 15 minutes
2. **HTTP Request** - Check OpenAI API
3. **HTTP Request** - Check Azure Storage
4. **PowerShell Script** - Check blockchain sync status
5. **If** - All healthy?
6. **Discord Webhook** - Alert on failure
7. **PowerShell Script** - Attempt restart (if safe)

#### Workflow 4: AI Error Analysis (On Error Detected)

**Purpose:** Use ChatGPT to analyze errors and suggest fixes

**Nodes:**

1. **Webhook Trigger** - Error webhook endpoint
2. **Extract Error Context** - Parse error details
3. **OpenAI ChatGPT** - Analyze error
4. **Format Response** - Create remediation plan
5. **Discord Webhook** - Send analysis + suggestions
6. **Write to File** - Log to `logs/ai-analysis.jsonl`

## 📋 Workflow Import Process

### Manual Import (Recommended for Learning)

1. **Open n8n UI**: http://localhost:5678
2. **Click "Add Workflow"** (+ button top-right)
3. **Follow workflow templates** in this README
4. **Configure credentials**:
   - Azure Blob Storage connection
   - Discord webhook URL
   - OpenAI API key
5. **Activate workflow** (toggle switch top-right)

### JSON Import (Advanced - Coming Soon)

Workflow JSON files will be created after manual setup and exported to:

- `workflows/blockchain-backup.json`
- `workflows/evidence-validation.json`
- `workflows/service-health-check.json`
- `workflows/ai-error-analysis.json`

## 🔧 Configuration

### Azure Blob Storage Credentials

In n8n UI:

1. Go to **Credentials** → **New**
2. Select **Azure Blob Storage**
3. Enter:
   - Account Name: `civicstorage` (or your account)
   - Account Key: From Azure Portal
4. Test connection
5. Save as `civic-azure-storage`

### Discord Webhook

1. In your Discord server → **Server Settings** → **Integrations** → **Webhooks**
2. **Create Webhook** → Name it "Civic Alerts"
3. Copy webhook URL
4. In n8n:
   - Add **Discord** credential
   - Paste webhook URL
   - Save as `civic-discord-webhook`

### OpenAI API Key

1. Get API key from https://platform.openai.com/api-keys
2. In n8n:
   - Add **OpenAI** credential
   - Paste API key
   - Save as `civic-openai`

## 📊 Monitoring

### Check Workflow Status

```powershell
# View n8n logs
docker-compose logs -f n8n

# Check last 50 executions (in n8n UI)
# Executions tab → Filter by workflow
```

### Execution History

n8n saves ALL executions (success + error) for audit trail:

- View in UI: **Executions** tab
- Data stored in: `n8n-data/database.sqlite`

## 🛠️ Troubleshooting

### Container Won't Start

```powershell
# Check Docker status
docker ps -a

# View full logs
docker-compose logs n8n

# Restart container
docker-compose restart n8n
```

### Can't Access UI (http://localhost:5678)

```powershell
# Check if port is in use
netstat -ano | findstr :5678

# Check container networking
docker network ls
docker network inspect civic-network
```

### Workflows Not Triggering

1. Check workflow is **Activated** (toggle in UI)
2. Check **Executions** tab for errors
3. Verify credentials are configured
4. Check file paths are correct (Windows paths in Docker)

### File Access Issues

- Ensure volumes are mounted correctly in `docker-compose.yml`
- Check Windows file permissions
- Verify paths exist: `logs/`, `evidence/`, `configs/`

## 🔐 Security Best Practices

### ✅ DO:

- Change default password in `docker-compose.yml` BEFORE starting
- Use strong passwords (20+ characters)
- Enable HTTPS if exposing to internet (use Nginx Proxy Manager)
- Regularly update n8n image: `docker-compose pull && docker-compose up -d`
- Backup n8n-data directory (workflows + credentials)

### ❌ DON'T:

- Use default password in production
- Expose port 5678 to internet without HTTPS
- Store credentials in workflow code (use n8n Credentials instead)
- Commit `n8n-data/` to Git (contains sensitive data)

## 📈 Success Metrics

After deployment, you should have:

- ✅ n8n container running (`docker ps`)
- ✅ UI accessible at http://localhost:5678
- ✅ Blockchain backup workflow active (every 4 hours)
- ✅ Discord notifications working
- ✅ Azure backups being created
- ✅ Audit trail in Executions tab

## 🔄 Backup & Recovery

### Backup n8n Data

```powershell
# Stop n8n
docker-compose down

# Backup data directory
Copy-Item -Recurse ./n8n-data ./n8n-data-backup-$(Get-Date -Format 'yyyyMMdd')

# Restart n8n
docker-compose up -d
```

### Restore n8n Data

```powershell
# Stop n8n
docker-compose down

# Restore from backup
Remove-Item -Recurse ./n8n-data
Copy-Item -Recurse ./n8n-data-backup-YYYYMMDD ./n8n-data

# Restart n8n
docker-compose up -d
```

## 📚 Resources

- **n8n Documentation**: https://docs.n8n.io/
- **n8n Community**: https://community.n8n.io/
- **n8n Workflows**: https://n8n.io/workflows/
- **Docker Documentation**: https://docs.docker.com/

## 🎯 Next Steps

After n8n is running:

1. ✅ Create Workflow 1: Blockchain Backup (4h schedule)
2. ✅ Test backup manually (Execute workflow)
3. ✅ Verify Azure Blob Storage has backup
4. ✅ Configure Discord webhook
5. ✅ Create Workflow 2: Evidence Validation
6. ✅ Create Workflow 3: Service Health Check
7. ✅ Create Workflow 4: AI Error Analysis
8. ✅ Log to blockchain (Record #10)

---

**Created:** 2025-10-17
**Version:** 1.0
**Status:** Ready for deployment
**Est. Setup Time:** 1-2 hours (first workflow), 8-12 hours (all 4 workflows)

