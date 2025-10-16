# Ollama Installation Checklist

**Date Started:** October 15, 2025
**Status:** In Progress ⏳

---

## ✅ Pre-Installation (COMPLETE)

- [x] AI Agent System created (Master, Factory, 6 Specialists)
- [x] ISO Build AI Agent created (395 lines)
- [x] Civic Infrastructure integration complete
- [x] VS Code configuration complete
- [x] Integration scripts ready
- [x] Documentation complete (8 guides)

---

## 📥 Ollama Installation Steps

### Step 1: Download Ollama
- [ ] Visit https://ollama.ai/download/windows (already opened)
- [ ] Click "Download for Windows"
- [ ] Wait for OllamaSetup.exe to download

**Time:** 1-2 minutes
**Status:** ⏳ Waiting for download

---

### Step 2: Install Ollama
- [ ] Run OllamaSetup.exe
- [ ] Click through installer wizard
- [ ] Wait for installation to complete
- [ ] Verify Ollama icon appears in system tray

**Time:** 2-3 minutes
**Status:** ⏳ Not started

**How to verify:**
```powershell
# Run in PowerShell (may need to restart terminal first)
Get-Process ollama -ErrorAction SilentlyContinue
```

---

### Step 3: Download CodeLlama Model
- [ ] Open NEW PowerShell window (or restart current one)
- [ ] Run: `ollama pull codellama:7b`
- [ ] Wait for ~4GB download to complete
- [ ] Verify model installed

**Time:** 5-15 minutes (depending on internet speed)
**Status:** ⏳ Not started

**How to verify:**
```powershell
ollama list
# Should show: codellama:7b
```

---

### Step 4 (Optional): Download Llama2 Model
- [ ] Run: `ollama pull llama2:7b`
- [ ] Wait for ~4GB download

**Time:** 5-15 minutes
**Status:** ⏳ Optional (can skip for now)

**Note:** You can skip this and download later. CodeLlama is sufficient to get started.

---

### Step 5: Test Ollama
- [ ] Run test command
- [ ] Verify AI responds

**Command:**
```powershell
ollama run codellama:7b "Write a PowerShell hello world"
```

**Expected:** AI-generated PowerShell code
**Status:** ⏳ Not started

---

## 🔧 Integration Steps

### Step 6: Run Integration Setup
- [ ] Navigate to workspace
- [ ] Run integration script
- [ ] Verify all checks pass

**Commands:**
```powershell
cd "C:\Users\svenk\OneDrive\All_My_Projects\New folder"
.\scripts\AI-Civic-Integration.ps1 -Setup
```

**Expected Output:**
```
✓ Ollama is running
✓ CodeLlama available
✓ Directory structure created
✓ Knowledge base initialized
✓ Integration complete!
```

**Time:** 2-3 minutes
**Status:** ⏳ Not started

---

### Step 7: Test Integration
- [ ] Run integration tests
- [ ] Verify all tests pass

**Command:**
```powershell
.\scripts\AI-Civic-Integration.ps1 -Test
```

**Expected Output:**
```
✓ AI Service Check
✓ Message Bus Integration
✓ Knowledge Base Access
✓ All tests passed!
```

**Time:** 1-2 minutes
**Status:** ⏳ Not started

---

### Step 8: First AI Workflow
- [ ] Try AI ISO analysis OR
- [ ] Submit test AI request OR
- [ ] Use VS Code shortcut

**Option A - VS Code (Easiest):**
```
1. Reload VS Code (Ctrl+Shift+P → "Reload Window")
2. Press: Ctrl+Shift+I
```

**Option B - Command Line:**
```powershell
.\agents\build\iso-build-ai-agent.ps1 `
    -BaseISOPath "C:\path\to\Win11.iso" `
    -AnalyzeOnly
```

**Option C - Test Request:**
```powershell
$request = @{
    packet_id = "test-$(Get-Date -Format 'yyyyMMddHHmmss')"
    timestamp = (Get-Date).ToString('o')
    user_request = "Create a PowerShell function to list services"
    priority = "normal"
}
$request | ConvertTo-Json | Set-Content "bus\inbox\normal\test.json"
```

**Status:** ⏳ Not started

---

## 🎉 Success Criteria

You'll know everything is working when:

- [x] System status shows all components ready ✅
- [ ] `ollama list` shows CodeLlama ⏳
- [ ] Integration setup completes successfully ⏳
- [ ] Integration tests all pass ⏳
- [ ] AI responds to test prompts ⏳
- [ ] VS Code shortcuts work ⏳

---

## ⏱️ Total Time Estimate

- Ollama download & install: **3-5 minutes**
- CodeLlama download: **5-15 minutes**
- Integration setup: **2-3 minutes**
- Testing: **2 minutes**

**Total:** ~15-25 minutes

---

## 🆘 Troubleshooting

### Ollama not found after install?
```powershell
# Restart PowerShell terminal
# Or restart VS Code
# Or restart computer
```

### Ollama service not running?
```powershell
# Check if running
Get-Process ollama

# If not, start it
& "C:\Users\$env:USERNAME\AppData\Local\Programs\Ollama\ollama.exe" serve
```

### Model download slow or stuck?
- Normal! Models are ~4GB each
- Check internet connection
- Can take 15+ minutes on slower connections
- Cancel with Ctrl+C and retry if truly stuck

### Integration setup fails?
```powershell
# Run with verbose output
.\scripts\AI-Civic-Integration.ps1 -Setup -Verbose

# Check logs
Get-Content logs\civic.jsonl -Tail 20
```

---

## 📋 Quick Commands Reference

```powershell
# Check Ollama status
Get-Command ollama
Get-Process ollama

# List installed models
ollama list

# Test AI
ollama run codellama:7b "test prompt"

# Integration
.\scripts\AI-Civic-Integration.ps1 -Setup
.\scripts\AI-Civic-Integration.ps1 -Test

# VS Code reload
Ctrl+Shift+P → "Developer: Reload Window"
```

---

## 📖 Documentation

While waiting for downloads, read:

- **INTEGRATION_SUMMARY.md** - Complete system overview
- **IMPLEMENTATION_QUICKSTART.md** - Getting started guide
- **OLLAMA-INSTALL-GUIDE.md** - Ollama installation details
- **.vscode/AI-INTEGRATION-GUIDE.md** - VS Code usage
- **QUICK-REFERENCE.md** - Command cheat sheet

---

## 🎯 Current Status

**Last Updated:** Just now
**Current Step:** Step 1 - Downloading Ollama
**Estimated Completion:** ~20 minutes from now

**Update this checklist as you progress!**

---

**Next Action:** Download and run OllamaSetup.exe from your browser! 🚀
