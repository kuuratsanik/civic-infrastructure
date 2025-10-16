# 🚀 AI Autonomous System - Quick Start

## 🎯 What You're Getting

A **fully self-hosted AI management team** that:

- Runs **automatically on every boot**
- **Controls everything** on your machine autonomously
- Uses **local AI models** (Ollama) - no cloud dependency
- Makes **intelligent decisions** 24/7
- **Zero manual intervention** required

---

## ⚡ One-Command Deployment

### Standard Mode (Recommended - 16GB+ RAM)

```powershell
# Run as Administrator
.\scripts\ai-system\Initialize-AIAutonomousSystem.ps1
```

**This command does EVERYTHING:**

1. ✅ Installs Ollama (self-hosted AI runtime)
2. ✅ Downloads 6 AI models (7B-14B parameters)
3. ✅ Creates AI management team (Master Orchestrator, System Monitor, etc.)
4. ✅ Configures boot-on-startup (Windows Task Scheduler)
5. ✅ Starts AI system immediately
6. ✅ Shows management dashboard

**Duration**: ~10 minutes (internet-dependent for model downloads)

### Light Mode (8GB RAM / Small SSD)

```powershell
# Smaller models, faster, still very capable
.\scripts\ai-system\Initialize-AIAutonomousSystem.ps1 -LightMode
```

### With Auto-Fix (AI Can Fix Issues Automatically)

```powershell
# AI can clean temp files, restart services, kill hung processes, etc.
.\scripts\ai-system\Initialize-AIAutonomousSystem.ps1 -EnableAutoFix
```

---

## 🤖 What Happens After Deployment

### Immediately

```
✅ Ollama service running in background
✅ Master Orchestrator AI analyzing system every 30 seconds
✅ System Monitor AI checking health every 60 seconds
✅ All decisions logged to ai-system/logs/
✅ Metrics recorded to ai-system/state/metrics/
```

### On Next Boot (And Every Boot After)

```
1. Windows boots normally
   ↓
2. Task Scheduler waits 1 minute
   ↓
3. AI system launches automatically
   ↓
4. Ollama service starts
   ↓
5. All AI agents activate
   ↓
6. System is under full AI management
   ↓
7. You do NOTHING - it's all autonomous
```

---

## 📊 View AI Dashboard

```powershell
# See what AI agents are doing right now
.\ai-system\Show-AIDashboard.ps1
```

**Dashboard shows:**

- ✅ Agent status (running/stopped)
- ⏱️ Uptime for each agent
- 💻 Current system health (CPU, memory, disk)
- 📁 Log/state file counts
- 🎛️ Quick management commands

---

## 📋 VS Code Tasks (Click to Run)

After deployment, these tasks are available in VS Code:

### Deployment Tasks

- **AI-System: Deploy Autonomous AI (Standard Mode)** - Full deployment
- **AI-System: Deploy Autonomous AI (Light Mode)** - Lightweight deployment
- **AI-System: Deploy with Auto-Fix Enabled** - AI can auto-fix issues

### Management Tasks

- **AI-System: Show Dashboard** - View AI agent status
- **AI-System: Start AI Agents** - Manually start AI system
- **AI-System: Stop All AI Agents** - Stop all AI agents

### Monitoring Tasks

- **AI-System: View Master Orchestrator Logs** - Live log tailing
- **AI-System: View System Monitor Logs** - Live log tailing

**How to use**: Press `Ctrl+Shift+P` → type "Run Task" → select task

---

## 🎯 The AI Management Team

### 1. Master Orchestrator AI 🧠

- **Job**: Chief decision-maker
- **Does**: Analyzes system every 30 seconds, makes decisions, delegates tasks
- **Model**: qwen2.5-coder (7B or 14B params)
- **Location**: `ai-system/agents/master-orchestrator/`

### 2. System Monitor AI 👁️

- **Job**: 24/7 health watchdog
- **Does**: Checks CPU/memory/disk every 60 seconds, detects issues
- **Model**: qwen2.5 (7B or 14B params)
- **Location**: `ai-system/agents/system-monitor/`

### 3-6. Coming Soon

- Development Assistant AI (code quality)
- Security Guardian AI (threat detection)
- Performance Optimizer AI (auto-tuning)
- Backup Coordinator AI (automated backups)

---

## 🔧 Quick Management Commands

### View Live Logs

```powershell
# Master Orchestrator (real-time)
Get-Content ".\ai-system\logs\master\orchestrator-$(Get-Date -Format 'yyyyMMdd').log" -Tail 50 -Wait

# System Monitor (real-time)
Get-Content ".\ai-system\logs\monitor\monitor-$(Get-Date -Format 'yyyyMMdd').log" -Tail 50 -Wait
```

### Check AI Agent Status

```powershell
# List all AI jobs
Get-Job | Where-Object { $_.Name -like "AI-*" }
```

### Stop AI System

```powershell
# Stop all AI agents
Get-Job | Where-Object { $_.Name -like "AI-*" } | Stop-Job
```

### Restart AI System

```powershell
# Via Task Scheduler
schtasks /run /tn "AI-Autonomous-System-Boot"

# Or manually
.\ai-system\Launch-AISystem.ps1
```

---

## 📈 Example AI Decisions

### What Master Orchestrator AI Does

Every 30 seconds:

```
1. Collects system metrics (CPU, memory, disk, processes)
   ↓
2. Sends to AI model: "What needs attention right now?"
   ↓
3. AI responds with JSON decision:
   {
     "action": "monitor_memory",
     "reason": "Memory usage trending upward",
     "priority": "medium",
     "delegate_to": "system-monitor"
   }
   ↓
4. Logs decision
   ↓
5. Delegates to appropriate specialized agent
```

### What System Monitor AI Does

Every 60 seconds:

```
1. Measures CPU, memory, disk, processes, handles, threads
   ↓
2. Records metrics to JSON file
   ↓
3. Sends to AI model: "Analyze this system state"
   ↓
4. AI responds:
   {
     "status": "healthy",
     "issues": [],
     "recommendations": ["Monitor memory trend"]
   }
   ↓
5. Logs analysis
   ↓
6. (If auto-fix enabled) Takes corrective actions
```

---

## 🔐 Privacy & Security

### All AI is Local (Self-Hosted)

✅ **No cloud API calls** - All AI runs on your PC
✅ **No data sent externally** - Your code never leaves your machine
✅ **Works offline** - No internet needed after initial setup
✅ **Full privacy** - You own and control all AI models

### Audit Trail

Every decision is logged:

```powershell
# View today's decisions
Get-Content ".\ai-system\logs\master\orchestrator-$(Get-Date -Format 'yyyyMMdd').log"
```

Example log:

```
[2025-10-15 14:35:22] [SUCCESS] Decision: optimize_memory - Memory at 85%
[2025-10-15 14:35:22] [INFO] Delegating to: performance-optimizer
[2025-10-15 14:36:15] [SUCCESS] Memory optimized: 85% → 72%
```

---

## 💾 Disk Usage

### Models (One-Time Download)

| Mode | Models | Total Size |
|------|--------|------------|
| **Light** | qwen2.5:1.5b, qwen2.5:3b, qwen2.5-coder:1.5b, qwen2.5-coder:3b | ~3-5 GB |
| **Standard** | qwen2.5:7b, qwen2.5:14b, qwen2.5-coder:7b, qwen2.5-coder:14b | ~15-25 GB |

### Logs & Metrics (Growing)

- **Logs**: ~10-50 MB per day
- **Metrics**: ~1-5 MB per day
- **State files**: ~1-10 MB per day

**Total ongoing**: ~20-100 MB per day

### Clean Old Data

```powershell
# Keep last 7 days of logs
Get-ChildItem ".\ai-system\logs" -Recurse -Filter "*.log" |
  Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } |
  Remove-Item

# Keep last 30 days of metrics
Get-ChildItem ".\ai-system\state\metrics" -Filter "*.json" |
  Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } |
  Remove-Item
```

---

## 🚨 Troubleshooting

### AI Agents Not Running

```powershell
# Check if Ollama is running
Get-Process | Where-Object { $_.ProcessName -like "*ollama*" }

# If not, start it
Start-Process -FilePath "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe" -ArgumentList "serve" -WindowStyle Hidden

# Then start AI system
.\ai-system\Launch-AISystem.ps1
```

### Task Scheduler Not Working

```powershell
# Check task
schtasks /query /tn "AI-Autonomous-System-Boot"

# Manually run task
schtasks /run /tn "AI-Autonomous-System-Boot"
```

### High Resource Usage

```powershell
# Switch to light mode (re-deploy)
.\scripts\ai-system\Initialize-AIAutonomousSystem.ps1 -LightMode -SkipOllamaInstall
```

---

## 📖 Full Documentation

For complete details, see:

- **AI-AUTONOMOUS-SYSTEM-GUIDE.md** - Complete 400+ line guide

---

## 🎉 You're Done

After running the deployment script, your system is:

✅ **Fully autonomous** - AI manages everything
✅ **Self-hosted** - No cloud dependency
✅ **Boot-to-AI** - Starts automatically
✅ **Privacy-first** - All local processing
✅ **Auditable** - Complete decision logs
✅ **Zero maintenance** - Runs forever

**Welcome to the autonomous future!** 🤖🚀

---

## 💡 Pro Tip: Create Aliases

Add to PowerShell profile (`code $PROFILE`):

```powershell
function ai-dash { & ".\ai-system\Show-AIDashboard.ps1" }
function ai-logs { Get-Content ".\ai-system\logs\master\orchestrator-$(Get-Date -Format 'yyyyMMdd').log" -Tail 50 -Wait }
function ai-stop { Get-Job | Where-Object { $_.Name -like "AI-*" } | Stop-Job }
function ai-start { & ".\ai-system\Launch-AISystem.ps1" }
function ai-status { Get-Job | Where-Object { $_.Name -like "AI-*" } }
```

Then just type:

- `ai-dash` - Show dashboard
- `ai-logs` - Tail logs
- `ai-stop` - Stop agents
- `ai-start` - Start agents
- `ai-status` - Check status

---

**Questions?** Check logs in `ai-system/logs/` or view dashboard with `ai-dash` 📊
