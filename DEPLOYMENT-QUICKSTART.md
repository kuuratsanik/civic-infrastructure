# 🌩️ FULL POWER DEPLOYMENT - QUICK START GUIDE

**Status**: ✅ READY TO DEPLOY
**Last Updated**: 2025-01-14
**Deployment Time**: ~15 minutes (cloud) or ~5 minutes (local only)

---

## 🎯 What You're Deploying

A complete AI-powered Windows 11 automation system with:

- **☁️ Azure Cloud Integration**

  - OpenAI GPT-4 Turbo for natural language commands
  - Azure Computer Vision for screen analysis
  - Azure Speech Services for voice control
  - Serverless Functions for automation

- **💻 VS Code Integration**

  - Custom extension for workspace analysis
  - WebSocket bridge for real-time communication
  - Multi-instance coordination
  - Automated code optimization

- **🧠 Local AI Orchestration**
  - 15 specialized agents across 5 teams
  - 3 operating modes (Learning → Suggestion → Autonomous)
  - Pattern detection engine
  - Phase 1-7 framework integration

---

## 🚀 30-Second Deployment

### Option 1: Full Power (Cloud + Local)

**Requirements**:

- Azure subscription (free tier works: https://azure.microsoft.com/free)
- Administrator access
- ~$10/month estimated cost

**Deploy**:

```powershell
# Run as Administrator
cd "C:\Users\svenk\OneDrive\All_My_Projects\New folder"
.\Deploy-FullPower.ps1 -Mode Full
```

**What happens**:

1. ✅ Installs prerequisites (Python, Azure CLI)
2. ✅ Creates Azure resources (OpenAI, Computer Vision)
3. ✅ Generates VS Code extension
4. ✅ Sets up WebSocket bridge
5. ✅ Configures local agents

**Duration**: ~15 minutes (Azure provisioning is slow)

---

### Option 2: Local Only (No Cloud)

**Requirements**:

- Administrator access only
- $0 cost

**Deploy**:

```powershell
# Run as Administrator
.\Deploy-FullPower.ps1 -Mode LocalOnly
```

**What you get**:

- ✅ 15 local AI agents
- ✅ VS Code extension (local features only)
- ✅ Pattern detection
- ❌ No GPT-4 natural language
- ❌ No cloud compute

**Duration**: ~5 minutes

---

## 📋 Step-by-Step Guide

### Step 1: Deploy Infrastructure

```powershell
# Open PowerShell as Administrator
cd "C:\Users\svenk\OneDrive\All_My_Projects\New folder"

# For full power with cloud:
.\Deploy-FullPower.ps1 -Mode Full

# OR for local only:
.\Deploy-FullPower.ps1 -Mode LocalOnly
```

**You'll be prompted for**:

- Azure Subscription ID (if cloud mode)
- Device code login (if cloud mode)

**Output**:

```
═══════════════════════════════════════════════════════════════════
        🌩️  FULL POWER DEPLOYMENT: CLOUD + AI + VS CODE
═══════════════════════════════════════════════════════════════════

✅ Deployment complete!
Azure OpenAI: sentient-openai-abc123
GPT-4 Turbo deployed and ready
VS Code extension created
WebSocket bridge configured
```

---

### Step 2: Install VS Code Extension

```powershell
# Navigate to extension directory
cd C:\ai-council\vscode-extension

# Install dependencies
npm install

# Compile TypeScript
npm run compile

# Install extension
code --install-extension .
```

**Verify**: Open VS Code, press `Ctrl+Shift+P`, type "Sentient" - you should see:

- Sentient: Analyze Workspace
- Sentient: Optimize Settings
- Sentient: Predict Next Action

---

### Step 3: Launch Sentient Workspace

```powershell
# Back to main directory
cd "C:\Users\svenk\OneDrive\All_My_Projects\New folder"

# Start with cloud features enabled
.\Start-SentientWorkspace-Cloud.ps1 -CloudEnabled

# OR start local only
.\Start-SentientWorkspace-Cloud.ps1
```

**Interactive Menu**:

```
═══════════════════════════════════════════════════════════════════
         🧠 SENTIENT WORKSPACE CONTROL CENTER
                   ☁️  CLOUD MODE ACTIVE
═══════════════════════════════════════════════════════════════════

[1] 🎓 Learning Mode (Recommended)
[2] 💡 Suggestion Mode
[3] 🤖 Autonomous Mode
[4] ☁️  Cloud Features
[5] 📊 View Statistics
[6] 🔄 Reset System
[7] ❌ Exit
```

**Choose [1] for first-time setup** - starts 30-day learning period

---

### Step 4: First Run Experience

When you select **Learning Mode**, the system:

1. **Minute 1-10**: Observes your active applications
2. **Minute 11-60**: Tracks window switches, file access
3. **Hour 2-24**: Monitors time-of-day patterns
4. **Day 2-7**: Detects weekly routines
5. **Day 8+**: Begins pattern recognition
6. **Day 30**: Ready for Suggestion Mode

**Observations are stored** in `C:\ai-council\logs\observations.jsonl`

---

## 🧪 Testing Cloud Features

Once deployed, test your cloud connection:

### Test 1: Natural Language Command (GPT-4)

```powershell
# In VS Code terminal
Ctrl+Shift+P -> "Sentient: Predict Next Action"
```

**Behind the scenes**:

1. VS Code extension sends workspace state to orchestrator
2. Orchestrator calls Azure OpenAI GPT-4
3. GPT-4 analyzes patterns and suggests next action
4. Result displayed in VS Code

---

### Test 2: Azure Health Check

```powershell
# Run health check
cd "C:\Users\svenk\OneDrive\All_My_Projects\New folder"
.\Test-CloudConnection.ps1
```

Expected output:

```
☁️  Azure OpenAI: ✅ Connected
🧠 GPT-4 Turbo: ✅ Responding
🔌 WebSocket Bridge: ✅ Listening
💻 VS Code Extension: ✅ Active
```

---

## 📊 Monitoring Progress

### View Statistics Anytime

```powershell
# Launch control center
.\Start-SentientWorkspace-Cloud.ps1

# Choose [5] View Statistics
```

**Example Output**:

```
📊 SYSTEM STATISTICS

📝 Observations:
   Total: 15,840
   Days of learning: 11
   Progress: 36% to pattern detection

🎯 Detected Patterns: 3
   • Morning routine (confidence: 85%)
   • VS Code launch pattern (confidence: 92%)
   • Focus time 10AM-12PM (confidence: 78%)

🤖 Automations:
   Proposed: 2
   Executed: 0 (waiting for Suggestion Mode)

☁️  Cloud Status: Configured
```

---

## 🎯 Usage Examples

### Example 1: AI-Suggested Workflow

**Scenario**: After 30 days of learning, you start Suggestion Mode

**What happens**:

```
💡 SUGGESTION: Morning Routine Automation

I've noticed you always:
1. Open VS Code at 9:15 AM
2. Load yesterday's projects
3. Start Spotify with "Deep Focus" playlist
4. Close all notifications
5. Set system to high-performance mode

Should I automate this? (y/n)
```

Type `y` → automation is saved and will run automatically next morning

---

### Example 2: Cloud-Powered Code Analysis

**Scenario**: You open a new project in VS Code

**What happens**:

1. VS Code extension detects new workspace
2. Sends code to Azure OpenAI via WebSocket
3. GPT-4 analyzes architecture, dependencies, patterns
4. Suggestions appear in status bar:
   ```
   💡 Detected: React + TypeScript project
   Suggestions:
   • Add ESLint config (common in your projects)
   • Setup Jest testing (you use this 90% of the time)
   • Create .vscode/settings.json (matches your preferences)
   ```

---

### Example 3: Voice Commands (if Speech Services enabled)

**Say**: "Sentient, optimize my system for gaming"

**What happens**:

1. Azure Speech Services transcribes command
2. GPT-4 interprets intent
3. Orchestrator executes:
   - Close background apps
   - Set GPU to maximum performance
   - Disable Windows Update
   - Kill Chrome (known RAM hog)
   - Apply high-performance power plan

**Confirmation**: "✅ Gaming mode activated. 12 GB RAM freed, GPU at 100%"

---

## 🛠️ Customization

### Add Custom Agents

Create new agent in `agents\custom\`:

```powershell
# agents\custom\my-custom-agent.ps1

function Start-MyCustomAgent {
    param([string]$Mode = "Learning")

    while ($true) {
        # Your custom logic here

        # Use cloud features if available
        if ($CloudEnabled) {
            $aiResponse = Invoke-GPT4 -Prompt "Analyze my custom data"
        }

        Start-Sleep -Seconds 60
    }
}

# Register with orchestrator
Register-Agent -Name "MyCustomAgent" -Team "Workflow"
```

---

### Configure Cloud Budget

Edit `C:\ai-council\config\azure-config.json`:

```json
{
  "OpenAI": {
    "MaxTokensPerDay": 100000,
    "CostAlertThreshold": 10.0
  }
}
```

---

## 💰 Cost Breakdown (Cloud Mode)

| Service                    | Tier            | Monthly Cost     |
| -------------------------- | --------------- | ---------------- |
| Azure OpenAI (GPT-4 Turbo) | 100K tokens/day | ~$6              |
| Computer Vision            | 1K images/month | ~$1              |
| Speech Services            | 5 hours/month   | ~$1              |
| Storage (logs)             | 10 GB           | ~$0.20           |
| **TOTAL**                  |                 | **~$8.20/month** |

**Free tier available**: First 12 months free with $200 credit

---

## 🚨 Troubleshooting

### Issue: "Azure login failed"

**Solution**:

```powershell
# Manual login
az login --use-device-code

# Set subscription
az account set --subscription YOUR_SUBSCRIPTION_ID

# Re-run deployment
.\Deploy-FullPower.ps1 -Mode Full -AzureSubscriptionId YOUR_SUBSCRIPTION_ID
```

---

### Issue: "VS Code extension not loading"

**Solution**:

```powershell
# Check extension is installed
code --list-extensions | Select-String "sentient"

# If not found, reinstall
cd C:\ai-council\vscode-extension
code --uninstall-extension sentient-ai.sentient-workspace-bridge
code --install-extension .

# Reload VS Code
Ctrl+Shift+P -> "Developer: Reload Window"
```

---

### Issue: "WebSocket connection refused"

**Solution**:

```powershell
# Check if bridge is running
Get-Process | Where-Object {$_.ProcessName -like "*websocket*"}

# If not found, start manually
cd "C:\Users\svenk\OneDrive\All_My_Projects\New folder"
.\agents\vscode\websocket-bridge.ps1
```

---

## 📚 Next Steps

### After Deployment:

1. **Week 1**: Let Learning Mode observe (no action needed)
2. **Week 2**: Check statistics daily to see patterns forming
3. **Week 3**: Review detected patterns, adjust if needed
4. **Week 4**: Transition to Suggestion Mode
5. **Week 5-6**: Approve/reject automation suggestions
6. **Week 7+**: Enable Autonomous Mode for full AI control

### Parallel Development:

While Sentient Workspace learns in the background:

- ✅ Start AliExpress CBA Plan (Week 1: database expansion)
- ✅ Begin Personal Development Platform (AI engines)
- ✅ All systems work in parallel - no conflicts

---

## 🎉 Success Criteria

You'll know it's working when:

✅ **VS Code status bar shows**: "$(brain) Sentient Active"
✅ **Statistics show**: Observations > 1,000
✅ **Cloud health check**: All services green
✅ **Patterns detected**: After 7 days minimum
✅ **First automation suggested**: After 30 days

---

## 🆘 Support

**Configuration Files**:

- Azure: `C:\ai-council\config\azure-config.json`
- Agents: `C:\ai-council\agents\`
- Logs: `C:\ai-council\logs\`

**Documentation**:

- Full cloud architecture: `docs\CLOUD-POWERED-SENTIENT.md` (in progress)
- Sentient plan: `SENTIENT-WORKSPACE-PLAN.md`
- System summary: `SENTIENT-WORKSPACE-COMPLETE.md`

**Command Reference**:

```powershell
# Deploy full system
.\Deploy-FullPower.ps1 -Mode Full

# Start with cloud
.\Start-SentientWorkspace-Cloud.ps1 -CloudEnabled

# Health check
.\Test-CloudConnection.ps1

# View logs
Get-Content C:\ai-council\logs\observations.jsonl -Tail 20

# Reset everything
.\Start-SentientWorkspace-Cloud.ps1  # Choose [6] Reset System
```

---

## ✨ You're Ready!

**Current Status**: All deployment files created ✅

**To begin right now**:

```powershell
# 1. Open PowerShell as Administrator
# 2. Run deployment
cd "C:\Users\svenk\OneDrive\All_My_Projects\New folder"
.\Deploy-FullPower.ps1 -Mode Full

# 3. Start learning
.\Start-SentientWorkspace-Cloud.ps1 -CloudEnabled
# Choose [1] Learning Mode
```

**Time to full automation**: 30 days
**Time to first suggestions**: 7 days
**Time to see magic**: Immediately 🌟

---

**Next**: After deployment completes, see `DEPLOYMENT-SUCCESS.md` for verification steps

