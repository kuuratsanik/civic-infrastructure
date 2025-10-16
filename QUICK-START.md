# 🚀 Quick Start Guide - AI-Powered Civic Infrastructure

**Status**: ✅ System Operational
**Last Verified**: October 15, 2025

---

## ⚡ 30-Second Start

### Option 1: Use Keyboard Shortcuts (Fastest)

```
Ctrl+Shift+I  → Analyze ISO with AI
Ctrl+Alt+M    → Start Master Orchestrator
Ctrl+Alt+C    → Start Civic Agent with AI
Ctrl+Shift+T  → Test AI system
```

### Option 2: Use VS Code Tasks

```
Press: Ctrl+Shift+P
Type: "Run Task"
Select: "AI: Test Agent System"
```

### Option 3: Use PowerShell

```powershell
# Test AI integration
.\scripts\AI-Civic-Integration.ps1 -Test

# Start Master Orchestrator
.\agents\master\master-orchestrator.ps1 -WatchMode

# Build ISO with AI
.\agents\build\iso-build-ai-agent.ps1 -AnalyzeOnly
```

---

## 🎯 Common Tasks

### Test AI Response

```powershell
$ollamaExe = "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe"
& $ollamaExe run qwen2.5-coder:1.5b "Write a hello world function"
```

### Switch AI Models

```json
// In .vscode/settings.json
"civic.aiModel": "qwen2.5-coder:1.5b"  // Fast (2GB RAM)
// or
"civic.aiModel": "codellama:7b"         // Powerful (6GB RAM)
```

### Use Code Snippets

```
Type in .ps1 file:
  civic-function + Tab  → DAO-governed function
  ai-request + Tab      → AI request packet
  ollama-invoke + Tab   → Call AI model
```

---

## 📋 System Status Check

```powershell
# Quick health check
Get-Process ollama -ErrorAction SilentlyContinue

# List available models
& "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe" list

# Test API
Invoke-RestMethod -Uri "http://localhost:11434/api/version"
```

---

## 🔧 Keyboard Shortcuts Reference

| Shortcut | Action |
|----------|--------|
| `Ctrl+Shift+I` | Analyze ISO with AI |
| `Ctrl+Alt+M` | Start Master Orchestrator |
| `Ctrl+Alt+C` | Start Civic Agent with AI |
| `Ctrl+Shift+T` | Test AI system |
| `Ctrl+Shift+B` | Build custom ISO |
| `Ctrl+Alt+Enter` | Run PowerShell selection |
| `F8` | Debug PowerShell selection |

---

## 📝 Code Snippets

| Snippet | Trigger | Description |
|---------|---------|-------------|
| `civic-function` | Tab | DAO-governed function template |
| `ai-request` | Tab | AI request packet for message bus |
| `ollama-invoke` | Tab | Call Ollama API with AI model |
| `warrant-check` | Tab | DAO warrant validation |
| `audit-log` | Tab | Audit trail entry |
| `kb-save` | Tab | Knowledge base entry |

---

## 🎓 Learning Path

### Day 1: Get Familiar

1. ✅ Test AI response (you've done this!)
2. Try keyboard shortcuts
3. Explore code snippets
4. Run integration test

### Day 2: Build Something

1. Analyze an ISO with AI
2. Use Master Orchestrator
3. Create custom ceremony
4. Build AI-powered workflow

### Day 3: Advanced

1. Create custom AI agent
2. Integrate with DAO governance
3. Build automated pipeline
4. Optimize performance

---

## 🆘 Troubleshooting

### AI not responding?

```powershell
# Restart Ollama
$ollamaExe = "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe"
Stop-Process -Name ollama -Force -ErrorAction SilentlyContinue
Start-Sleep 2
Start-Process -FilePath $ollamaExe -ArgumentList "serve" -NoNewWindow
```

### Out of memory?

```powershell
# Switch to smaller model
# Edit .vscode/settings.json:
"civic.aiModel": "qwen2.5-coder:1.5b"
```

### Keyboard shortcuts not working?

```
Reload VS Code: Ctrl+Shift+P → "Developer: Reload Window"
```

---

## 📚 Documentation

- **AI-DEPLOYMENT-COMPLETE.md** - Complete deployment summary
- **IMPLEMENTATION_QUICKSTART.md** - Detailed implementation guide
- **AI-INTEGRATION-GUIDE.md** - VS Code integration details
- **INTEGRATION_SUMMARY.md** - Architecture overview

---

## 💡 Pro Tips

1. **Use qwen2.5-coder for daily work** - It's 2-3x faster
2. **Switch to codellama for complex tasks** - When you have 6+ GB RAM free
3. **Your 1GB internet = instant model switching** - Download any model in seconds
4. **Code snippets save time** - Just type trigger + Tab
5. **Keyboard shortcuts boost productivity** - Learn the top 4 shortcuts

---

## ✅ Current Status

- ✅ Ollama v0.12.5 running
- ✅ qwen2.5-coder:1.5b active (tested)
- ✅ codellama:7b backup available
- ✅ All VS Code configs loaded
- ✅ All AI agents ready
- ✅ Documentation complete

**You're ready to build! 🚀**
