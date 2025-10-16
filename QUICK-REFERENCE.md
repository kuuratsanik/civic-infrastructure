# Quick Reference - AI Agent System

## 🚀 Quick Start

### 1. After Ollama Installation Completes
```powershell
# Initialize system
.\scripts\Initialize-AgentSystem.ps1

# Run test
.\Test-AgentSystem.ps1
```

### 2. Submit Your First Request
```powershell
# Method A: Direct
.\agents\master\master-orchestrator.ps1 -UserRequest "Create a function to parse JSON"

# Method B: File-based
@{ user_request = "Build a password validator" } | ConvertTo-Json | Set-Content "bus\inbox\master-request-001.json"
```

### 3. Start Continuous Mode
```powershell
.\agents\master\master-orchestrator.ps1 -WatchMode
```

---

## 📋 Common Commands

### Check System Status
```powershell
# Verify Ollama
Invoke-WebRequest http://localhost:11434/api/version

# List models
ollama list

# View active agents
Get-Content council\keys\agents-registry.json | ConvertFrom-Json
```

### Monitor Activity
```powershell
# Watch Master logs
Get-Content logs\master.jsonl -Wait -Tail 10

# Check pending tasks
Get-ChildItem bus\inbox -Recurse

# View results
Get-ChildItem bus\outbox -Recurse
```

### Manual Agent Control
```powershell
# Spawn coding agent
.\agents\factory\agent-factory.ps1 -AgentType "coding"

# Start agent watching
.\agents\coding\coding-agent.ps1 -WatchMode
```

---

## 🎯 Request Examples

### Simple Tasks
```powershell
"Create a function to calculate factorial"
"Write unit tests for email validation"
"Generate API documentation for User endpoints"
"Fix SQL injection in login function"
```

### Complex Projects
```powershell
"Build a REST API for task management with CRUD operations"
"Create a user authentication system with JWT and refresh tokens"
"Implement a file upload system with virus scanning"
"Build a real-time chat application with WebSockets"
```

### Refactoring & Fixes
```powershell
"Refactor the User class to use dependency injection"
"Optimize database queries in the Reports module"
"Add error handling to all API endpoints"
"Implement caching for frequently accessed data"
```

---

## 📊 Monitoring Queries

### Agent Performance
```powershell
# Agent stats
$registry = Get-Content council\keys\agents-registry.json | ConvertFrom-Json
$registry.agents | Select-Object agent_id, type, status, tasks_completed, tasks_failed | Format-Table
```

### Task Queue Status
```powershell
# Pending tasks by priority
Get-ChildItem bus\inbox\critical | Measure-Object
Get-ChildItem bus\inbox\high | Measure-Object
Get-ChildItem bus\inbox\normal | Measure-Object
```

### Recent Results
```powershell
# Last 5 completed tasks
Get-ChildItem bus\outbox\*-result.json | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First 5 | 
    ForEach-Object { Get-Content $_.FullName | ConvertFrom-Json }
```

---

## 🔧 Configuration

### Master Agent Settings
**File:** `agents\master\master-orchestrator.ps1`

```powershell
$global:MasterConfig = @{
    Model = "codellama:7b"              # AI model
    MaxConcurrentAgents = 10            # Max agents at once
    AgentScalingThreshold = 0.8         # When to scale up
    IdleTerminationMinutes = 5          # When to kill idle agents
}
```

### Agent Types & Skills
```powershell
AgentTypes = @{
    "coding" = @{
        Skills = @("code-generation", "refactoring", "bug-fixing")
        Model = "codellama:7b"
        MaxInstances = 3
    }
    # Add more types...
}
```

---

## 🐛 Troubleshooting

### Ollama Issues
```powershell
# Service not running
ollama serve

# Model not loaded
ollama pull codellama:7b

# Test inference
ollama run codellama:7b "print hello world in python"
```

### Agent Issues
```powershell
# No agents spawning
Get-Content logs\master.jsonl -Tail 20

# Agent crashed
Get-Job | Remove-Job -Force  # Clean up
.\scripts\Initialize-AgentSystem.ps1  # Reinitialize
```

### Performance Issues
```powershell
# Too slow
# 1. Reduce max_tokens in agent scripts
# 2. Use smaller model: codellama:7b instead of 13b
# 3. Close other applications

# Too many agents
$registry = Get-Content council\keys\agents-registry.json | ConvertFrom-Json
$registry.agents.Count  # Check count
# Reduce MaxConcurrentAgents in Master config
```

---

## 📁 Important Files

| File | Purpose |
|------|---------|
| `agents/master/master-orchestrator.ps1` | Main brain |
| `agents/factory/agent-factory.ps1` | Agent spawner |
| `council/keys/agents-registry.json` | Agent tracking |
| `logs/master.jsonl` | Master activity log |
| `knowledge/patterns/*.md` | Best practices |
| `bus/inbox/` | Task queue |
| `bus/outbox/` | Results |

---

## 🎨 Task Packet Format

### Input (Submit to bus/inbox/)
```json
{
  "user_request": "Create email validator",
  "priority": "high",
  "timestamp": "2025-10-15T12:00:00Z"
}
```

### Output (Generated in bus/outbox/)
```json
{
  "packet_id": "pkt-abc123",
  "task_id": "task-001",
  "agent_id": "coding-agent-20251015120000-1",
  "status": "completed",
  "result": "function Test-Email { ... }",
  "completed_at": "2025-10-15T12:05:00Z"
}
```

---

## 🔐 Privacy Notes

✅ **All AI runs locally** (Ollama on port 11434)  
✅ **No cloud API calls** (zero network after setup)  
✅ **No API keys needed** (completely free)  
✅ **Full data control** (everything stays on your machine)

Models stored: `C:\Users\[you]\.ollama\models\`

---

## 🎯 Best Practices

### Request Writing
- ✅ Be specific: "Create a User class with validation" not "make user stuff"
- ✅ Include context: "Using PowerShell" or "For REST API"
- ✅ Mention standards: "Follow PSScriptAnalyzer rules"
- ✅ State requirements: "Must handle null values"

### System Maintenance
- Run `Initialize-AgentSystem.ps1` after updates
- Monitor `logs/` directory size (archive old logs)
- Review `knowledge/lessons/` to see what system learned
- Clean `bus/deadletter/` periodically

### Performance Tuning
- Start with 1-2 agents, scale as needed
- Use critical priority only for urgent tasks
- Let idle agents terminate (saves resources)
- Keep knowledge base updated (faster decisions)

---

## 📚 Learn More

- **Full Guide:** `docs\AI-AGENT-SYSTEM-GUIDE.md`
- **Roadmap:** `docs\AI_ORCHESTRATION_ROADMAP.md`
- **Customization:** `CUSTOMIZATION_DETAILS.md`

---

## 🎉 You're Ready!

```powershell
# Start building with AI right now:
.\agents\master\master-orchestrator.ps1 -WatchMode

# Then submit tasks:
@{ user_request = "Your task here" } | 
    ConvertTo-Json | 
    Set-Content "bus\inbox\master-request-$(Get-Date -Format 'yyyyMMddHHmmss').json"
```

**The agents will handle the rest! 🚀**
