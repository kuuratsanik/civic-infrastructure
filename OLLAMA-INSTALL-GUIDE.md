# Quick Ollama Manual Installation Guide

## ✅ EASIEST METHOD - Manual Installation

### Step 1: Download Ollama (1 minute)
1. The download page is opening in your browser automatically
2. Or visit: https://ollama.ai/download/windows
3. Click "Download for Windows"
4. Save `OllamaSetup.exe`

### Step 2: Install Ollama (2 minutes)
1. Run the downloaded `OllamaSetup.exe`
2. Follow the installation wizard (Next → Next → Install)
3. Ollama will start automatically when installation completes
4. You'll see the Ollama icon in your system tray (bottom-right)

### Step 3: Download AI Models (10-15 minutes)
Open PowerShell (any window) and run:

```powershell
# Download CodeLlama 7B (~4GB)
ollama pull codellama:7b

# Download Llama2 7B (~4GB) - optional but recommended
ollama pull llama2:7b
```

**Note:** Downloads may take 5-15 minutes depending on internet speed.

### Step 4: Verify Installation
```powershell
# Check installed models
ollama list

# Test CodeLlama
ollama run codellama:7b "Write a PowerShell hello world"
```

You should see AI-generated code!

### Step 5: Run Integration Setup
```powershell
# Navigate to your workspace
cd "C:\Users\svenk\OneDrive\All_My_Projects\New folder"

# Run integration setup
.\scripts\AI-Civic-Integration.ps1 -Setup
```

### Step 6: Test Everything
```powershell
# Run integration tests
.\scripts\AI-Civic-Integration.ps1 -Test

# Or in VS Code (after reload):
# Press: Ctrl+Shift+I
```

---

## 🚀 You're Done!

After these steps, you'll have:
- ✅ Local AI running (Ollama + CodeLlama)
- ✅ AI agents integrated with civic infrastructure
- ✅ VS Code fully configured
- ✅ Ready to build AI-powered Windows 11 ISOs!

---

## 🆘 Troubleshooting

**Ollama not starting after install?**
```powershell
# Check if running
Get-Process ollama -ErrorAction SilentlyContinue

# Start manually
& "C:\Users\$env:USERNAME\AppData\Local\Programs\Ollama\ollama.exe" serve
```

**Models download slow?**
- Normal! Models are ~4GB each
- You can continue with just codellama:7b
- llama2:7b is optional

**Can't find ollama command?**
- Restart PowerShell terminal
- Or restart VS Code
- Or restart computer (Ollama adds itself to PATH)

---

## ⏭️ Skip Models for Now?

If you want to test the system without waiting for downloads:

```powershell
# Just pull codellama:7b (smaller, faster)
ollama pull codellama:7b

# Skip llama2:7b for now
# You can download it later
```

Then proceed with integration setup!
