# VS Code Integration Guide
## AI-Powered Civic Infrastructure

This document explains how to use VS Code effectively with your AI-powered Windows 11 civic infrastructure system.

---

## 🎯 Quick Start

### 1. Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+Shift+T` | Run AI system tests |
| `Ctrl+Shift+B` | Build custom ISO |
| `Ctrl+Shift+I` | Analyze ISO with AI |
| `Ctrl+Alt+M` | Start Master Orchestrator |
| `Ctrl+Alt+C` | Start Civic Agent (AI-enabled) |
| `Ctrl+Alt+V` | Run validation tests |
| `Ctrl+Alt+Enter` | Run selected PowerShell code |
| `F8` | Debug selected PowerShell code |

### 2. Terminal Profiles

Access via Terminal menu or `Ctrl+Shift+\`:

- **PowerShell** - Standard terminal
- **PowerShell (Admin)** - Elevated permissions
- **Civic Agent Watch** - Auto-starts civic agent in watch mode with AI
- **Master Orchestrator** - Auto-starts AI master orchestrator

### 3. Code Snippets

Type these prefixes and press `Tab`:

- `civic-function` - Create DAO-governed function
- `ai-request` - Create AI agent request packet
- `warrant-check` - Add DAO warrant validation
- `audit-log` - Add audit trail entry
- `ollama-invoke` - Call Ollama AI
- `kb-save` - Save to knowledge base

---

## 📁 Workspace Organization

### File Nesting

VS Code automatically groups related files:

```
agents/
  civic/
    civic-agent.ps1          # Main file
    ├─ civic-agent.Tests.ps1 # Nested under main
    └─ civic-agent.psd1      # Nested under main
```

### Color-Coded Brackets

- **Gold** - First level `{ }`
- **Orchid** - Second level `{ { } }`
- **Sky Blue** - Third level `{ { { } } }`

---

## 🔧 Configuration Files

### `.vscode/settings.json`
- Editor preferences (font, size, formatting)
- PowerShell configuration
- Terminal profiles
- File associations
- Custom civic infrastructure settings

### `.vscode/tasks.json`
- 19 pre-configured tasks
- AI operations (7 tasks)
- ISO build ceremonies (5 tasks)
- Validation & testing (4 tasks)
- Background services (3 tasks)

### `.vscode/launch.json`
- Debug configurations
- Run scripts with arguments
- Interactive debugging for agents
- Test harnesses

### `.vscode/keybindings.json`
- Custom keyboard shortcuts
- Quick access to common tasks
- PowerShell-specific bindings

### `.vscode/snippets.code-snippets`
- AI request templates
- DAO warrant checks
- Audit trail logging
- Knowledge base entries
- Ollama AI invocations

### `.vscode/PSScriptAnalyzerSettings.psd1`
- Code quality rules
- Style enforcement
- Best practices validation

### `.editorconfig`
- Cross-editor consistency
- File format rules
- Line ending standards

---

## 🚀 Common Workflows

### Workflow 1: Analyze ISO with AI

**Method A: Keyboard Shortcut**
```
Press: Ctrl+Shift+I
```

**Method B: Task Menu**
```
1. Ctrl+Shift+P
2. Type: "Tasks: Run Task"
3. Select: "AI: Analyze ISO with AI"
```

**Method C: Terminal**
```powershell
.\agents\build\iso-build-ai-agent.ps1 `
    -BaseISOPath "C:\path\to\Win11.iso" `
    -AnalyzeOnly
```

**Method D: Debug Mode**
```
1. F5 (or click Debug icon)
2. Select: "ISO Build AI Agent: Analyze Only"
```

---

### Workflow 2: Submit AI Request via Message Bus

**Using Snippet:**
```powershell
# 1. Create new .ps1 file
# 2. Type: ai-request
# 3. Press: Tab
# 4. Fill in the template
# 5. Run: F8 or Ctrl+Alt+Enter
```

**Manual:**
```powershell
$request = @{
    packet_id = "my-task-$(Get-Date -Format 'yyyyMMddHHmmss')"
    timestamp = (Get-Date).ToString('o')
    user_request = "Build Windows 11 ISO optimized for developers"
    priority = "high"
    requirements = @("privacy", "performance", "developer-tools")
}

$request | ConvertTo-Json | Set-Content "bus\inbox\high\request.json"
```

---

### Workflow 3: Start AI Agent System

**Background Mode (Recommended):**
```
1. Press: Ctrl+Alt+M (Start Master)
2. Press: Ctrl+Alt+C (Start Civic Agent)
3. Submit requests to bus/inbox/
4. Monitor logs in dedicated terminals
```

**Interactive Mode:**
```
1. Open Terminal 1: .\agents\master\master-orchestrator.ps1 -WatchMode
2. Open Terminal 2: .\agents\civic\civic-agent.ps1 -WatchMode -EnableAI
3. Open Terminal 3: Submit requests & monitor
```

---

### Workflow 4: Build Custom ISO

**Full AI Workflow:**
```
1. Ctrl+Shift+P → "Tasks: Run Task"
2. Select: "AI: Build ISO with AI Optimization"
3. Watch autonomous execution in terminal
4. Review results in workspace/output/
```

**Traditional Workflow:**
```
1. Ctrl+Shift+B (or Ctrl+Shift+P → "Tasks: Run Task" → "Build Custom ISO")
2. Follow ceremony prompts
3. Monitor progress in terminal
```

---

### Workflow 5: Debug Agent Scripts

**Interactive Debugging:**
```
1. Open agent script (e.g., civic-agent.ps1)
2. Set breakpoints (click left of line numbers)
3. F5 → Select debug configuration
4. Use Debug toolbar:
   - Continue (F5)
   - Step Over (F10)
   - Step Into (F11)
   - Step Out (Shift+F11)
   - Restart (Ctrl+Shift+F5)
   - Stop (Shift+F5)
```

**Variable Inspection:**
```
- Hover over variables to see values
- Use Debug Console to evaluate expressions
- Watch panel for monitoring specific variables
```

---

## 📊 Monitoring & Observability

### Live Log Tailing

**Terminal Commands:**
```powershell
# Civic operations
Get-Content logs\civic.jsonl -Wait -Tail 20

# AI orchestration
Get-Content logs\master.jsonl -Wait -Tail 20

# All DAO governance
Get-Content logs\council_ledger.jsonl -Wait -Tail 20

# Specific AI agent
Get-Content logs\agents\iso-build-ai.jsonl -Wait -Tail 20
```

### VS Code Features

**Problems Panel** (`Ctrl+Shift+M`)
- Shows PSScriptAnalyzer warnings
- Code quality issues
- Syntax errors

**Output Panel** (`Ctrl+Shift+U`)
- PowerShell extension output
- Task execution logs
- Debug output

**Terminal Panel** (`Ctrl+\`)
- Multiple terminal tabs
- Named profiles
- Split view support

---

## 🎨 UI Customization

### Themes

**Recommended for Code:**
- Default Dark+ (current)
- Monokai
- Solarized Dark

**Recommended for Icons:**
- VS Icons (install: `vscode-icons-team.vscode-icons`)
- Material Icon Theme (install: `pkief.material-icon-theme`)

### Font

**Current:** Cascadia Code with ligatures

**Alternatives:**
- Fira Code
- JetBrains Mono
- Victor Mono

**Install:**
```powershell
# Via winget
winget install Microsoft.CascadiaCode
winget install FiraCode
```

---

## 🔌 Recommended Extensions

### Installed (via extensions.json)

**Essential:**
- `ms-vscode.powershell` - PowerShell support
- `editorconfig.editorconfig` - EditorConfig support

**AI & Coding:**
- `continue.continue` - Local AI code assistant
- `github.copilot` - GitHub Copilot (if licensed)
- `github.copilot-chat` - Copilot chat interface

**Productivity:**
- `yzhang.markdown-all-in-one` - Markdown tools
- `gruntfuggly.todo-tree` - TODO highlighting
- `eamodio.gitlens` - Git superpowers
- `usernamehw.errorlens` - Inline errors
- `visualstudioexptteam.vscodeintellicode` - AI IntelliSense

**Quality:**
- `streetsidesoftware.code-spell-checker` - Spell checking
- `davidanson.vscode-markdownlint` - Markdown linting

### Install Extensions

**Via Command Palette:**
```
1. Ctrl+Shift+P
2. "Extensions: Install Extensions"
3. Search and install
```

**Via Terminal:**
```powershell
code --install-extension ms-vscode.powershell
code --install-extension continue.continue
code --install-extension eamodio.gitlens
```

---

## 🧪 Testing & Validation

### Run Tests

**All Validation Tests:**
```
Ctrl+Alt+V
# or
Ctrl+Shift+P → "Tasks: Run Task" → "Run Validation Tests"
```

**Detailed Tests:**
```powershell
.\tests\Invoke-ValidationTests.ps1 -Detailed
```

**AI System Tests:**
```
Ctrl+Shift+T
# or
.\Test-AgentSystem.ps1
```

### Pester Tests (if using)

```powershell
# Run all tests
Invoke-Pester

# Run specific test file
Invoke-Pester -Path .\tests\Test-ManifestValidator.Tests.ps1

# Generate coverage report
Invoke-Pester -CodeCoverage *.ps1 -OutputFile coverage.xml
```

---

## 🛠️ PowerShell Integration

### IntelliSense

- **Auto-complete:** Type and wait for suggestions
- **Parameter help:** Type `-` after cmdlet
- **Snippet completion:** Type prefix and `Tab`
- **Import hints:** Auto-suggests module imports

### Code Actions

- **Right-click** → "Format Document" (or `Shift+Alt+F`)
- **Right-click** → "Run Selection" (or `Ctrl+Alt+Enter`)
- **Right-click** → "Debug Selection" (or `F8`)

### Script Analyzer

**Real-time:**
- Green squiggles = Information
- Blue squiggles = Warning
- Red squiggles = Error

**Fix Issues:**
```
1. Hover over squiggle
2. Click "Quick Fix" (or Ctrl+.)
3. Select fix action
```

---

## 📚 Documentation Access

### In-Workspace Docs

| File | Purpose |
|------|---------|
| `INTEGRATION_SUMMARY.md` | Complete integration guide |
| `AI-CIVIC-INTEGRATION-PLAN.md` | Architecture & strategy |
| `AI-SYSTEM-SUMMARY.md` | AI system overview |
| `QUICK-REFERENCE.md` | Command cheat sheet |
| `CUSTOMIZATION_DETAILS.md` | ISO customizations (95+) |
| `.vscode/AI-INTEGRATION-GUIDE.md` | This guide |

### Quick Open

```
Ctrl+P → Type filename → Enter
```

**Examples:**
```
Ctrl+P → "integ" → Select "INTEGRATION_SUMMARY.md"
Ctrl+P → "quick" → Select "QUICK-REFERENCE.md"
```

### Markdown Preview

```
1. Open .md file
2. Ctrl+Shift+V (or click preview icon)
3. Split editor for side-by-side view
```

---

## 🔐 Security & Trust

### Workspace Trust

**Current:** Enabled, prompt once

**If Prompted:**
```
1. Review workspace contents
2. Click "Trust" if you created this
3. Click "Don't Trust" for unknown workspaces
```

### PowerShell Execution Policy

**Current:** Bypassed for tasks via `-ExecutionPolicy Bypass`

**Check Policy:**
```powershell
Get-ExecutionPolicy -List
```

**Set for Current User:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## 🎓 Pro Tips

### 1. Multi-Cursor Editing
```
Alt+Click = Add cursor
Ctrl+Alt+Up/Down = Add cursor above/below
Ctrl+D = Select next occurrence
```

### 2. Command Palette Fuzzy Search
```
Ctrl+Shift+P → Type: "runtas" → Matches "Tasks: Run Task"
```

### 3. Quick File Navigation
```
Ctrl+P = Quick open file
Ctrl+Tab = Switch between recent files
Ctrl+Shift+E = Explorer focus
```

### 4. Terminal Tricks
```
Ctrl+` = Toggle terminal
Ctrl+Shift+` = New terminal
Ctrl+Shift+5 = Split terminal
```

### 5. Zen Mode
```
Ctrl+K Z = Enter Zen Mode (distraction-free)
Escape Escape = Exit Zen Mode
```

### 6. Breadcrumbs Navigation
```
Ctrl+Shift+. = Focus breadcrumbs
Arrow keys = Navigate
Enter = Jump to location
```

---

## 🐛 Troubleshooting

### PowerShell Extension Not Working

**Fix:**
```
1. Ctrl+Shift+P → "PowerShell: Restart Current Session"
2. If still broken: Reload VS Code (Ctrl+Shift+P → "Developer: Reload Window")
```

### Tasks Not Appearing

**Fix:**
```
1. Ctrl+Shift+P → "Tasks: Run Task"
2. Check .vscode/tasks.json exists
3. Reload window if needed
```

### Snippets Not Working

**Fix:**
```
1. Check file language mode (bottom-right corner)
2. Should show "PowerShell" for .ps1 files
3. Type prefix exactly (e.g., "civic-function")
4. Press Tab (not Enter)
```

### AI Integration Not Working

**Check:**
```powershell
# 1. Ollama running
Invoke-WebRequest http://localhost:11434/api/version

# 2. Models available
ollama list

# 3. Integration setup
.\scripts\AI-Civic-Integration.ps1 -Test
```

---

## 📞 Quick Reference Card

```
╔════════════════════════════════════════════════════════╗
║           VS CODE QUICK REFERENCE                      ║
╠════════════════════════════════════════════════════════╣
║ AI WORKFLOWS                                           ║
║  Ctrl+Shift+I     Analyze ISO with AI                  ║
║  Ctrl+Alt+M       Start Master Orchestrator            ║
║  Ctrl+Alt+C       Start Civic Agent (AI)               ║
║  Ctrl+Shift+T     Test AI system                       ║
╠════════════════════════════════════════════════════════╣
║ BUILD & DEPLOY                                         ║
║  Ctrl+Shift+B     Build custom ISO                     ║
║  Ctrl+Alt+V       Run validation tests                 ║
╠════════════════════════════════════════════════════════╣
║ POWERSHELL                                             ║
║  Ctrl+Alt+Enter   Run selection                        ║
║  F8               Debug selection                      ║
║  F5               Start debugging                      ║
╠════════════════════════════════════════════════════════╣
║ NAVIGATION                                             ║
║  Ctrl+P           Quick open file                      ║
║  Ctrl+Shift+P     Command palette                      ║
║  Ctrl+Tab         Switch files                         ║
║  Ctrl+`           Toggle terminal                      ║
╠════════════════════════════════════════════════════════╣
║ SNIPPETS (type + Tab)                                  ║
║  civic-function   DAO-governed function                ║
║  ai-request       AI request packet                    ║
║  warrant-check    Warrant validation                   ║
║  ollama-invoke    Call local AI                        ║
╚════════════════════════════════════════════════════════╝
```

---

**🎉 You're all set! Start building with AI-powered civic infrastructure!**
