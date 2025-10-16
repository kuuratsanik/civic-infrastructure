# Windows Implementation Quick Start Guide
## AI-Powered Civic Infrastructure - Ready to Run!

**Date:** October 15, 2025
**Status:** 🟡 Ready (Ollama installation pending)

---

## 📊 Current Status

### ✅ **READY Components**
- ✅ AI Agent System (Master, Factory, Specialists)
- ✅ ISO Build AI Agent (395 lines, production-ready)
- ✅ Civic Infrastructure (DAO governance, message bus)
- ✅ Integration Scripts (setup, test, demo)
- ✅ VS Code Configuration (complete IDE setup)
- ✅ 19 Tasks (12 existing + 7 AI)
- ✅ Code Snippets & Keyboard Shortcuts
- ✅ Debug Configurations

### 🟡 **PENDING**
- 🟡 Ollama Installation (AI engine)
- 🟡 CodeLlama Model Download (~4GB)
- 🟡 Integration Setup Execution

### ⏳ **OPTIONAL**
- ⏳ Windows 11 ISO Build (can do later)
- ⏳ First AI Analysis Test

---

## 🚀 Implementation Steps

### **STEP 1: Install Ollama** ⚡ (5-10 minutes)

**Method A: Automated (Recommended)**
```powershell
# Run the installation script we created
.\scripts\setup\Install-Ollama.ps1

# This will:
# 1. Download Ollama for Windows
# 2. Install it silently
# 3. Start Ollama service
# 4. Download CodeLlama 7B model (~4GB)
# 5. Test the installation
```

**Method B: Manual**
```powershell
# 1. Download Ollama
Start-Process "https://ollama.ai/download/windows"

# 2. Run the installer (OllamaSetup.exe)
# 3. Ollama starts automatically after install

# 4. Download AI models
ollama pull codellama:7b   # For code generation (~4GB)
ollama pull llama2:7b      # For documentation (~4GB)

# 5. Test it
ollama run codellama:7b "Write a hello world in PowerShell"
```

**Method C: Winget (if available)**
```powershell
winget install Ollama.Ollama
ollama pull codellama:7b
ollama pull llama2:7b
```

---

### **STEP 2: Verify Ollama** ✓ (1 minute)

```powershell
# Check if Ollama is running
Get-Process ollama -ErrorAction SilentlyContinue

# Check installed models
ollama list

# Test AI inference
ollama run codellama:7b "Write a PowerShell function to check disk space"

# Expected output: AI-generated PowerShell code
```

---

### **STEP 3: Run Integration Setup** 🔧 (2-3 minutes)

```powershell
# Navigate to your workspace
cd "C:\Users\svenk\OneDrive\All_My_Projects\New folder"

# Run integration setup
.\scripts\AI-Civic-Integration.ps1 -Setup

# This will:
# ✓ Verify Ollama is running
# ✓ Check CodeLlama model availability
# ✓ Create unified directory structure
# ✓ Initialize knowledge base
# ✓ Configure civic agent paths
# ✓ Set up message bus integration
```

**Expected Output:**
```
[SETUP] Checking Ollama service...
✓ Ollama is running at http://localhost:11434

[SETUP] Checking AI models...
✓ CodeLlama 7B available

[SETUP] Creating directory structure...
✓ Created: bus/inbox/{critical,high,normal,low}
✓ Created: knowledge/{patterns,context,lessons}
✓ Created: logs/agents

[SETUP] Initializing knowledge base...
✓ Created: knowledge/patterns/iso-build-patterns.md
✓ Created: knowledge/context/civic-governance.md

[SETUP] Integration complete!
```

---

### **STEP 4: Test Integration** 🧪 (2 minutes)

```powershell
# Run integration tests
.\scripts\AI-Civic-Integration.ps1 -Test

# This tests:
# 1. AI service availability
# 2. Message bus communication
# 3. Knowledge base access
# 4. Optional: AI ISO analysis
```

**Expected Output:**
```
[TEST] AI Service Check...
✓ AI responded: "Hello! I'm CodeLlama..."

[TEST] Message Bus Integration...
✓ Test packet written successfully

[TEST] Knowledge Base Access...
✓ All knowledge files readable

[TEST] All tests passed!
```

---

### **STEP 5: First AI Workflow** 🎯 (5 minutes)

**Option A: Analyze ISO (if you have Win11 ISO)**
```powershell
# Via VS Code Task:
# Press: Ctrl+Shift+I
# (Analyze ISO with AI)

# Or via command line:
.\agents\build\iso-build-ai-agent.ps1 `
    -BaseISOPath "C:\Users\svenk\Downloads\Win11_25H2_Estonian_x64.iso" `
    -AnalyzeOnly `
    -Verbose
```

**Option B: Simple AI Request**
```powershell
# Create a request packet
$request = @{
    packet_id = "test-$(Get-Date -Format 'yyyyMMddHHmmss')"
    timestamp = (Get-Date).ToString('o')
    user_request = "Create a PowerShell script to check system health"
    priority = "normal"
    requirements = @("error-handling", "logging", "comments")
}

# Submit to message bus
$request | ConvertTo-Json | Set-Content "bus\inbox\normal\test-request.json"

# Watch for response in bus\outbox\
```

**Option C: Test AI Function**
```powershell
# Quick AI test
$testPrompt = "Write a PowerShell function to list all running services"

$aiRequest = @{
    model = "codellama:7b"
    prompt = $testPrompt
    temperature = 0.3
    stream = $false
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:11434/api/generate" `
    -Method Post `
    -Body $aiRequest `
    -ContentType "application/json" |
    Select-Object -ExpandProperty response
```

---

## 🎮 VS Code Shortcuts (After Reload)

### Quick Actions
```
Ctrl+Shift+I   → Analyze ISO with AI
Ctrl+Alt+M     → Start Master Orchestrator
Ctrl+Alt+C     → Start Civic Agent with AI
Ctrl+Shift+T   → Test AI system
Ctrl+Shift+B   → Build custom ISO
```

### Terminal Profiles
```
Click Terminal "+" dropdown:
• Civic Agent Watch → Auto-starts AI civic agent
• Master Orchestrator → Auto-starts AI brain
• PowerShell (Admin) → Elevated terminal
```

### Code Snippets
```
Type in .ps1 file:
civic-function + Tab → DAO function template
ai-request + Tab → AI request packet
ollama-invoke + Tab → Call local AI
warrant-check + Tab → Add DAO validation
```

---

## 📋 Common Workflows

### Workflow 1: Start AI Agent System
```powershell
# Terminal 1: Start Master Orchestrator
.\agents\master\master-orchestrator.ps1 -WatchMode

# Terminal 2: Start Civic Agent with AI
.\agents\civic\civic-agent.ps1 -WatchMode -EnableAI

# Terminal 3: Submit requests & monitor
Get-Content logs\council_ledger.jsonl -Wait -Tail 20
```

**Or via VS Code:**
```
1. Press: Ctrl+Alt+M (Master)
2. Press: Ctrl+Alt+C (Civic)
3. Submit requests to bus\inbox\high\
```

---

### Workflow 2: Build Windows 11 ISO with AI
```powershell
# Full AI-powered workflow
.\agents\build\iso-build-ai-agent.ps1 `
    -BaseISOPath "C:\path\to\Win11.iso" `
    -Requirements "privacy","performance","minimal" `
    -Verbose

# AI will:
# 1. Analyze base ISO
# 2. Suggest optimizations
# 3. Generate custom .reg files
# 4. Validate ISO structure
# 5. Save results to knowledge base
```

**Or via VS Code:**
```
Ctrl+Shift+P → "Tasks: Run Task" → "AI: Build ISO with AI Optimization"
```

---

### Workflow 3: Create Custom Script with AI
```powershell
# Submit request
$request = @{
    packet_id = "script-gen-$(Get-Date -Format 'yyyyMMddHHmmss')"
    timestamp = (Get-Date).ToString('o')
    user_request = "Create PowerShell script to backup registry keys"
    priority = "high"
    requirements = @(
        "error-handling"
        "logging to file"
        "parameter validation"
        "help documentation"
    )
    expected_deliverables = @(
        "Backup-RegistryKeys.ps1"
        "README.md"
        "Test-BackupScript.Tests.ps1"
    )
}

# Submit to AI
$request | ConvertTo-Json -Depth 5 |
    Set-Content "bus\inbox\high\script-gen.json"

# Watch bus\outbox\ for results
```

---

## 🔧 Troubleshooting

### Issue: Ollama Not Installed
**Solution:**
```powershell
# Check if exists
Get-Command ollama -ErrorAction SilentlyContinue

# If not found, install:
.\scripts\setup\Install-Ollama.ps1
# or download from: https://ollama.ai/download/windows
```

---

### Issue: Ollama Service Not Running
**Solution:**
```powershell
# Check process
Get-Process ollama -ErrorAction SilentlyContinue

# Start Ollama (usually auto-starts)
& "C:\Users\$env:USERNAME\AppData\Local\Programs\Ollama\ollama.exe" serve

# Or restart computer (Ollama starts on boot)
```

---

### Issue: Models Not Downloaded
**Solution:**
```powershell
# Check what's installed
ollama list

# Pull required models
ollama pull codellama:7b    # ~4GB
ollama pull llama2:7b       # ~4GB

# Test model
ollama run codellama:7b "test"
```

---

### Issue: Integration Setup Fails
**Solution:**
```powershell
# Check prerequisites
1. Ollama running: http://localhost:11434/api/version
2. Models available: ollama list
3. Paths correct: Get-Location

# Re-run with verbose
.\scripts\AI-Civic-Integration.ps1 -Setup -Verbose

# If still fails, check logs
Get-Content logs\civic.jsonl -Tail 50
```

---

### Issue: VS Code Shortcuts Not Working
**Solution:**
```powershell
# 1. Reload VS Code
Ctrl+Shift+P → "Developer: Reload Window"

# 2. Check keybindings.json exists
Test-Path .vscode\keybindings.json

# 3. Check tasks.json has AI tasks
Get-Content .vscode\tasks.json | Select-String "AI:"
```

---

### Issue: AI Requests Not Processing
**Solution:**
```powershell
# 1. Check Master Orchestrator running
Get-Process powershell | Where-Object {
    $_.CommandLine -like "*master-orchestrator*"
}

# 2. Check message bus for packets
Get-ChildItem bus\inbox -Recurse

# 3. Check logs
Get-Content logs\master.jsonl -Tail 20
Get-Content logs\civic.jsonl -Tail 20

# 4. Restart agents
.\agents\master\master-orchestrator.ps1 -WatchMode
```

---

## 📊 System Requirements

### Minimum
- **OS:** Windows 11 Pro (your current OS)
- **RAM:** 8GB (16GB recommended for AI)
- **Disk:** 20GB free space (for AI models + ISOs)
- **CPU:** 4 cores (8 recommended for parallel agents)

### Recommended
- **RAM:** 16GB+ (AI models use ~4-8GB)
- **SSD:** For faster ISO builds
- **GPU:** Optional (Ollama can use GPU acceleration)

---

## 📈 Performance Notes

### AI Model Performance
- **CodeLlama 7B:** Fast, good for code generation
- **CodeLlama 13B:** Better quality, slower (needs ~16GB RAM)
- **Llama2 7B:** Good for documentation, explanations

### First Run
- **Setup:** 5-10 minutes (Ollama + models)
- **Integration:** 2-3 minutes
- **Test:** 2 minutes
- **Total:** ~15 minutes to fully operational

### Ongoing Usage
- **AI response:** 2-10 seconds (depends on prompt)
- **ISO analysis:** 2-5 minutes
- **ISO build:** 20-40 minutes (with AI optimization)
- **Script generation:** 30-60 seconds

---

## 🎯 Success Criteria

You'll know everything is working when:

✅ `ollama list` shows CodeLlama and Llama2
✅ `.\scripts\AI-Civic-Integration.ps1 -Test` passes all tests
✅ VS Code shortcuts work (Ctrl+Shift+I, etc.)
✅ AI responds to requests in bus\inbox\
✅ Logs appear in logs\agents\*.jsonl
✅ Knowledge base accumulates learnings

---

## 📚 Next Steps After Implementation

### Immediate (Today)
1. ✅ Install Ollama
2. ✅ Run integration setup
3. ✅ Test AI with simple request
4. ✅ Try ISO analysis (if you have ISO)

### Short-term (This Week)
1. Build custom Windows 11 ISO with AI
2. Generate utility scripts with AI
3. Set up automated testing with AI
4. Build knowledge base from successful builds

### Long-term (This Month)
1. Fully autonomous ISO builds
2. Self-healing build system
3. Multi-agent parallel workflows
4. Advanced pattern recognition

---

## 🆘 Quick Help

**Can't find a file?**
```powershell
Get-ChildItem -Recurse -Filter "filename*"
```

**Want to see all tasks?**
```powershell
Get-Content .vscode\tasks.json | ConvertFrom-Json |
    Select-Object -ExpandProperty tasks |
    Select-Object label, type | Format-Table
```

**Need to reset?**
```powershell
# Re-run integration setup
.\scripts\AI-Civic-Integration.ps1 -Setup -Force
```

**Want verbose output?**
```powershell
# Add -Verbose to any script
.\agents\civic\civic-agent.ps1 -WatchMode -EnableAI -Verbose
```

---

## 🎉 You're Ready!

Your AI-powered civic infrastructure is **code-complete and ready to run**.

**All you need to do:**
1. Install Ollama (5 min)
2. Run integration setup (2 min)
3. Start using AI! 🚀

---

**Questions? Check:**
- `.vscode\AI-INTEGRATION-GUIDE.md` - VS Code usage
- `INTEGRATION_SUMMARY.md` - Complete system overview
- `QUICK-REFERENCE.md` - Command cheat sheet
- `AI-SYSTEM-SUMMARY.md` - AI architecture

**Let's get Ollama installed and make this AI system live!** 🎊
