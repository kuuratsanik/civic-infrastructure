# 🎯 AI System - Quick Reference Card

**Print this page and keep it handy!**

---

## ⚡ One-Line Deployments

```powershell
# Standard (16GB+ RAM)
.\scripts\ai-system\Initialize-AIAutonomousSystem.ps1

# Light (8GB RAM)
.\scripts\ai-system\Initialize-AIAutonomousSystem.ps1 -LightMode

# With Auto-Fix
.\scripts\ai-system\Initialize-AIAutonomousSystem.ps1 -EnableAutoFix
```

---

## 📊 Essential Commands

### View Dashboard

```powershell
.\ai-system\Show-AIDashboard.ps1
```

### View Live Logs

```powershell
# Master Orchestrator
Get-Content ".\ai-system\logs\master\orchestrator-$(Get-Date -Format 'yyyyMMdd').log" -Tail 50 -Wait

# System Monitor
Get-Content ".\ai-system\logs\monitor\monitor-$(Get-Date -Format 'yyyyMMdd').log" -Tail 50 -Wait
```

### Check AI Status

```powershell
Get-Job | Where-Object { $_.Name -like "AI-*" }
```

### Stop AI System

```powershell
Get-Job | Where-Object { $_.Name -like "AI-*" } | Stop-Job
```

### Start AI System

```powershell
.\ai-system\Launch-AISystem.ps1
# OR
schtasks /run /tn "AI-Autonomous-System-Boot"
```

---

## 🎯 VS Code Tasks (Ctrl+Shift+P → Run Task)

- **AI-System: Deploy Autonomous AI (Standard Mode)**
- **AI-System: Deploy Autonomous AI (Light Mode)**
- **AI-System: Show Dashboard**
- **AI-System: Start AI Agents**
- **AI-System: Stop All AI Agents**
- **AI-System: View Master Orchestrator Logs**
- **AI-System: View System Monitor Logs**

---

## 📂 Key Directories

| Directory | Contents |
|-----------|----------|
| `ai-system/agents/` | AI agent scripts |
| `ai-system/config/` | Configuration files |
| `ai-system/logs/` | Log files (all agents) |
| `ai-system/state/` | State & metrics |

---

## 📚 Documentation Quick Links

| Doc | Purpose | Lines |
|-----|---------|-------|
| `AI-SYSTEM-QUICKSTART.md` | Get started | 400 |
| `AI-AUTONOMOUS-SYSTEM-GUIDE.md` | Full guide | 800 |
| `AI-SYSTEM-ROADMAP-500-UPGRADES.md` | Roadmap | 1500 |
| `PHASE1-IMPLEMENTATION-GUIDE.md` | Build Phase 1 | 800 |
| `AI-UPGRADE-TRACKER.md` | Track progress | 500 |
| `AI-SYSTEM-COMPLETE-SUMMARY.md` | Summary | 400 |

---

## 🤖 AI Agents (Current)

### Master Orchestrator AI

- **Checks**: Every 30 seconds
- **Does**: Makes decisions, delegates tasks
- **Log**: `ai-system/logs/master/orchestrator-*.log`

### System Monitor AI

- **Checks**: Every 60 seconds
- **Does**: Monitors CPU/memory/disk, detects issues
- **Log**: `ai-system/logs/monitor/monitor-*.log`

---

## 📈 Key Metrics

| Metric | Current | Target |
|--------|---------|--------|
| Decision Latency | ~1s | <100ms |
| Agent Response | ~2s | <500ms |
| Uptime | 95% | 99.99% |
| CPU Usage | 15% | <5% |
| RAM Usage | 2GB | <500MB |

---

## 🎯 500-Upgrade Phases

1. **Phase 1**: Foundation (50) - 4-6 weeks
2. **Phase 2**: Agent Capabilities (50) - 6-8 weeks
3. **Phase 3**: Multi-Agent Coordination (50) - 6-8 weeks
4. **Phase 4**: Self-Learning (50) - 8-10 weeks
5. **Phase 5**: Dev Workflow (50) - 6-8 weeks
6. **Phase 6**: Security (50) - 8-10 weeks
7. **Phase 7**: Observability (50) - 6-8 weeks
8. **Phase 8**: Cloud & Distributed (50) - 8-10 weeks
9. **Phase 9**: Code Generation (50) - 10-12 weeks
10. **Phase 10**: Self-Healing (50) - 8-10 weeks

**Total**: 12-18 months | 500 upgrades

---

## 🚨 Troubleshooting

### AI Not Running?

```powershell
# Check Ollama
Get-Process | Where-Object { $_.ProcessName -like "*ollama*" }

# Start Ollama
Start-Process -FilePath "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe" -ArgumentList "serve" -WindowStyle Hidden

# Restart AI
.\ai-system\Launch-AISystem.ps1
```

### High Resource Use?

```powershell
# Switch to light mode
.\scripts\ai-system\Initialize-AIAutonomousSystem.ps1 -LightMode -SkipOllamaInstall
```

### Task Scheduler Issues?

```powershell
# Check task
schtasks /query /tn "AI-Autonomous-System-Boot"

# Run manually
schtasks /run /tn "AI-Autonomous-System-Boot"
```

---

## 💾 Cleanup Commands

### Clean Old Logs (keep 7 days)

```powershell
Get-ChildItem ".\ai-system\logs" -Recurse -Filter "*.log" |
  Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } |
  Remove-Item
```

### Clean Old Metrics (keep 30 days)

```powershell
Get-ChildItem ".\ai-system\state\metrics" -Filter "*.json" |
  Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } |
  Remove-Item
```

---

## 🔐 Security

- ✅ **100% Local**: No cloud API calls
- ✅ **Privacy-First**: All data stays on your PC
- ✅ **Encrypted Logs**: Sensitive data encrypted
- ✅ **Audit Trail**: Every decision logged
- ✅ **Offline-Capable**: Works without internet

---

## 💡 Pro Aliases

Add to PowerShell profile (`code $PROFILE`):

```powershell
function ai-dash { & ".\ai-system\Show-AIDashboard.ps1" }
function ai-logs { Get-Content ".\ai-system\logs\master\orchestrator-$(Get-Date -Format 'yyyyMMdd').log" -Tail 50 -Wait }
function ai-stop { Get-Job | Where-Object { $_.Name -like "AI-*" } | Stop-Job }
function ai-start { & ".\ai-system\Launch-AISystem.ps1" }
function ai-status { Get-Job | Where-Object { $_.Name -like "AI-*" } }
```

Then use:

- `ai-dash` - Dashboard
- `ai-logs` - Live logs
- `ai-stop` - Stop agents
- `ai-start` - Start agents
- `ai-status` - Check status

---

## 📞 Quick Help

**Question**: AI not making decisions?
**Answer**: Check logs. Ensure Ollama running. Verify models downloaded.

**Question**: High disk usage?
**Answer**: Clean old logs/metrics. Use light mode.

**Question**: Want faster decisions?
**Answer**: Use GPU acceleration. Reduce check intervals.

**Question**: Need more agents?
**Answer**: Follow Phase 2 in roadmap (6 specialized agents).

**Question**: Want to customize?
**Answer**: Edit `ai-system/config/ai-system-config.json`, hot-reload.

---

## 🎉 Success Checklist

After deployment, verify:

- [ ] Ollama installed and running
- [ ] AI models downloaded (check `ollama list`)
- [ ] Master Orchestrator job running (`ai-status`)
- [ ] System Monitor job running (`ai-status`)
- [ ] Logs being created (`ai-system/logs/`)
- [ ] Metrics being recorded (`ai-system/state/metrics/`)
- [ ] Dashboard shows agents running (`ai-dash`)
- [ ] Task Scheduler task created (`schtasks /query /tn "AI-Autonomous-System-Boot"`)
- [ ] Boot automation working (restart PC, wait 2 min, check `ai-status`)

---

**Last Updated**: October 15, 2025
**Version**: 1.0.0
**Status**: Production Ready

---

**🚀 Your system is now autonomous!**

Print this card → Keep it handy → Refer as needed
