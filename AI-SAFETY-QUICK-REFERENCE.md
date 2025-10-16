# 🛡️ AI SAFETY FRAMEWORK - QUICK REFERENCE

## 🎯 The First Rule

**"FIRST RULE: DO NO HARM!"**

Every AI action must pass safety validation. No exceptions.

---

## ⚡ Quick Commands

### Test Safety

```powershell
# Import safety framework
Import-Module ".\scripts\ai-system\safety\SafetyFramework.ps1"

# Test if action is prohibited
Test-ProhibitedAction -Action "Remove-Item C:\Windows"  # → True (blocked)

# Full safety check
Invoke-SafetyCheck -Action "Get-Process" -Context @{Scope="Read"}
```

### Use Self-Learning

```powershell
Import-Module ".\scripts\ai-system\self-capabilities\SelfLearning.ps1"

# Initialize
Initialize-LearningSystem

# Record experience
Add-Experience -Context "Optimization" -Action "Clear temp" -Outcome "Success" -Result "Success"

# Get best action
Get-BestAction -Context "Optimization"
```

### Use Self-Researching

```powershell
Import-Module ".\scripts\ai-system\self-capabilities\SelfResearching.ps1"

# Find solution
Find-Solution -Problem "High CPU" -Context "Windows"

# Research best practices
Get-BestPractice -Technology "PowerShell" -Aspect "Performance"

# Verify facts
Invoke-FactVerification -Claim "PowerShell 7 is faster" -MinSources 2
```

### Run Safe AI

```powershell
# Start safe orchestrator
.\agents\master\master-orchestrator-safe.ps1

# Emergency stop
Invoke-EmergencyStop -Reason "User requested"
```

---

## 📊 File Structure

```
scripts/ai-system/
  ├── safety/
  │   └── SafetyFramework.ps1          # FIRST RULE enforcement
  └── self-capabilities/
      ├── SelfLearning.ps1             # Learn from experience
      ├── SelfResearching.ps1          # Find solutions
      └── SelfImproving.ps1            # Optimize code

agents/master/
  └── master-orchestrator-safe.ps1     # Safe AI orchestrator

ai-system/
  ├── data/
  │   ├── learning/                    # Knowledge base
  │   └── research/                    # Research findings
  └── logs/
      ├── safety/                      # Safety decisions
      └── decisions/                   # AI decisions
```

---

## 🚦 Risk Levels

| Level | Action Type | Requirements |
|-------|-------------|-------------|
| 🟢 **SAFE** | Read-only | Execute freely |
| 🔵 **LOW** | Minor config | Log + execute |
| 🟡 **MEDIUM** | System changes | Backup + execute |
| 🟠 **HIGH** | Data modification | Backup + approval |
| 🔴 **CRITICAL** | Data deletion | Backup + multi-approval |

---

## ❌ Prohibited Actions

AI **CANNOT** do:

- Delete system files (`C:\Windows`, `C:\Program Files`)
- Expose secrets in logs
- Disable security (Defender, Firewall)
- Modify critical services
- Execute unsigned code
- Send data externally without consent

---

## ✅ Safety Workflow

```
1. Propose Action
   ↓
2. Research Solution (Self-Researching)
   ↓
3. Check Learning (Self-Learning)
   ↓
4. Safety Check (SafetyFramework) ← MANDATORY
   - Prohibited? → BLOCK
   - Risk level?
   - Backup exists?
   - Need approval?
   ↓
5. Execute (if approved)
   ↓
6. Verify + Rollback if failed
   ↓
7. Record Experience (Self-Learning)
```

---

## 🔍 Monitoring

### View Safety Logs

```powershell
# Today's safety decisions
Get-Content "ai-system\logs\safety\safety-$(Get-Date -Format 'yyyyMMdd').log" |
    ConvertFrom-Json

# Blocked actions
Get-Content "ai-system\logs\safety\*.log" |
    ConvertFrom-Json |
    Where-Object { $_.Message -like "*BLOCKED*" }
```

### View AI Decisions

```powershell
# Today's decisions
Get-Content "ai-system\logs\decisions\decisions-$(Get-Date -Format 'yyyyMMdd').jsonl" |
    ConvertFrom-Json |
    Format-Table Timestamp, Context, SafetyApproved, Outcome
```

### View Learning Progress

```powershell
# Knowledge base
Get-Content "ai-system\data\learning\learning.db.json" | ConvertFrom-Json

# Success rate
$KB = Get-Content "ai-system\data\learning\learning.db.json" | ConvertFrom-Json
$KB.Experiences.Values |
    Group-Object Result |
    Select-Object Name, Count
```

---

## 🚨 Emergency

### Stop All AI

```powershell
# Method 1: Use safety framework
Invoke-EmergencyStop -Reason "User stop"

# Method 2: Manual
Get-Job | Where-Object { $_.Name -like "AI-*" } | Stop-Job -Force
```

### Review Violations

```powershell
Get-Content "ai-system\logs\safety\*.log" |
    ConvertFrom-Json |
    Where-Object { $_.Level -in @("ERROR", "CRITICAL") } |
    Format-Table Timestamp, Level, Message
```

### Rollback Changes

```powershell
# Find backups
Get-ChildItem -Recurse -Filter "*.backup-*"

# Restore
Copy-Item "file.backup-20250101120000" "file" -Force
```

---

## 🎯 Example: Safe Decision Flow

**Scenario**: AI detects high CPU usage

```
1. System Monitor: CPU = 85%

2. Self-Research:
   Search: "high CPU usage solutions Windows"
   Found: 3 trusted sources (Microsoft Learn, Stack Overflow)

3. Self-Learning:
   Check knowledge base
   Past success: "Get-Process | Sort CPU" worked 5 times

4. Propose Action:
   "Get-Process | Sort-Object CPU -Descending | Select-Object -First 5"

5. Safety Check:
   ✅ Not prohibited (read-only)
   ✅ Risk: SAFE
   ✅ No backup needed
   ✅ No approval needed

6. Execute:
   Get-Process | Sort-Object CPU -Descending | Select-Object -First 5

7. Result:
   Success: Identified chrome.exe using 40% CPU

8. Record Experience:
   Context: "High CPU"
   Action: "Get-Process sort"
   Outcome: "Success"
   → Add to knowledge base
   → Increase success rate to 100% (6/6)
```

---

## 📚 Documentation

| Doc | Purpose |
|-----|---------|
| [AI-SAFETY-FRAMEWORK.md](AI-SAFETY-FRAMEWORK.md) | Complete safety spec |
| [AI-SAFETY-INSTALLATION.md](AI-SAFETY-INSTALLATION.md) | Setup guide |
| [AI-SAFETY-IMPLEMENTATION-SUMMARY.md](AI-SAFETY-IMPLEMENTATION-SUMMARY.md) | What was built |
| [AI-AUTONOMOUS-SYSTEM-GUIDE.md](AI-AUTONOMOUS-SYSTEM-GUIDE.md) | Full AI guide |

---

## 💡 Pro Tips

1. **Always import SafetyFramework first**

   ```powershell
   Import-Module ".\scripts\ai-system\safety\SafetyFramework.ps1" -Force
   ```

2. **Use -WhatIf for testing**

   ```powershell
   Invoke-SafetyCheck -Action "Remove-Item" -Context @{} -WhatIf
   ```

3. **Check logs regularly**

   ```powershell
   # Safety violations
   Get-Content "ai-system\logs\safety\*.log" | ConvertFrom-Json |
       Where Level -eq "CRITICAL"
   ```

4. **Emergency stop alias**

   ```powershell
   Set-Alias -Name 'Stop-AI' -Value 'Invoke-EmergencyStop'
   Stop-AI -Reason "Testing emergency stop"
   ```

5. **Monitor learning progress**

   ```powershell
   # Watch AI learn in real-time
   Get-Content "ai-system\data\learning\learning.db.json" -Wait
   ```

---

**First Rule: DO NO HARM** | **Safety-First AI** | **Autonomous with Ethics**

---

**Quick Start**: `.\agents\master\master-orchestrator-safe.ps1`

**Emergency**: `Invoke-EmergencyStop`

**Help**: See [AI-SAFETY-INSTALLATION.md](AI-SAFETY-INSTALLATION.md)
