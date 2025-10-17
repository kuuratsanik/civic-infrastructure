# Tool Limit Policy - Quick Reference

**Status**: 17. oktoober 2025

---

## At a Glance

| Category               | Current | Limit | Status       | Action   |
| ---------------------- | ------- | ----- | ------------ | -------- |
| **VS Code Extensions** | 76      | 100   | ✅ COMPLIANT | None     |
| **MCP Server Tools**   | ~232    | 128   | ⚠️ Over      | Optional |

---

## Quick Commands

### Check Compliance

```powershell
.\scripts\Monitor-ToolLimits.ps1
```

### Check Extensions Only

```powershell
(code --list-extensions).Count
```

### Clean Extensions (If Needed)

```powershell
.\scripts\Cleanup-VSCodeExtensions.ps1 -Interactive
```

---

## What Are MCP Tools?

**Model Context Protocol (MCP) Tools** = AI agent capabilities from external servers

### Your MCP Servers:

- **Azure MCP**: ~60 tools (ACR, AKS, Functions, SQL, Storage, etc.)
- **GitKraken MCP**: ~10 tools (Git, PRs, Issues)
- **Microsoft Docs MCP**: 3 tools (Search, Fetch, Samples)
- **Core VS Code**: ~30 tools (Files, Terminal)
- **AI Toolkit**: 3 tools (Model guidance)

**Total**: ~232 tools

---

## The 232 vs 76 Confusion

❓ **"Tool limit exceeded (232/128)" error shows 232 tools, but I only have 76 extensions?**

✅ **Answer**:

- **232** = MCP server tools (AI capabilities)
- **76** = VS Code extensions (user-installed)
- **Different things!**

---

## Impact of MCP Tool Count

### What Works ✅

- Inline Copilot suggestions
- VS Code performance
- Extension functionality
- All Azure operations
- Git workflows
- Documentation search

### What's Affected ⚠️

- GitHub Copilot Chat (occasional "tool limit exceeded" errors)
- Happens when working with comprehensive Azure tooling
- Copilot auto-selects relevant tools to work around this

---

## Recommendations

### For VS Code Extensions (76/100)

✅ **NO ACTION REQUIRED**

- You're 24 under the limit
- Keep up the good work!

### For MCP Tools (~232/128)

✅ **ACCEPT CURRENT STATE** (Recommended)

- You need Azure capabilities for civic infrastructure
- Occasional Copilot Chat errors are acceptable trade-off
- All functionality remains available

⚠️ **OPTIMIZE** (Optional, if errors are frequent)

- Option 1: Work in smaller scopes (focus on one Azure service area)
- Option 2: Restart VS Code between context switches
- Option 3: Disable non-essential MCP servers (advanced)

❌ **DON'T DISABLE AZURE MCP**

- Loses all Azure AI automation
- Defeats purpose of cloud-powered workspace

---

## When to Act

### Extensions

| Count  | Action                  |
| ------ | ----------------------- |
| 0-80   | ✅ Excellent            |
| 81-90  | ✅ Good                 |
| 91-100 | ⚠️ Review new additions |
| 101+   | ❌ Run cleanup script   |

### MCP Tools

| Symptom                | Action                               |
| ---------------------- | ------------------------------------ |
| No errors              | ✅ Continue current state            |
| Occasional Chat errors | ✅ Acceptable, use workarounds       |
| Frequent Chat failures | ⚠️ Consider optimization             |
| Can't work at all      | ❌ Disable non-essential MCP servers |

---

## Workarounds for "Tool Limit Exceeded"

If Copilot Chat fails:

1. **Rephrase your question** (simpler/more specific)
2. **Restart VS Code** (fresh tool selection)
3. **Work in smaller scope** (one Azure service at a time)
4. **Use inline suggestions** (still works normally)
5. **Break into smaller requests** (don't ask about everything at once)

---

## Monitoring Schedule

- **Weekly**: Run `Monitor-ToolLimits.ps1`
- **Monthly**: Review new extensions
- **Quarterly**: Full audit (17. jaanuar 2026)
- **As-needed**: After major VS Code updates

---

## Files to Know

| File                                   | Purpose                 |
| -------------------------------------- | ----------------------- |
| `docs/policies/TOOL-LIMIT-POLICY.md`   | Full policy (693 lines) |
| `scripts/Monitor-ToolLimits.ps1`       | Compliance checker      |
| `scripts/Cleanup-VSCodeExtensions.ps1` | Extension cleanup       |
| `TOOL-LIMIT-STATUS.md`                 | Investigation results   |
| `MCP-POLICY-ADDED.md`                  | Policy changes summary  |
| `TOOL-LIMIT-QUICK-REF.md`              | This file               |

---

## TL;DR

✅ **You're doing fine!**

- Extensions: 76/100 ✅
- MCP Tools: ~232/128 ⚠️ (but this is OK)
- Action: None required
- If Copilot Chat fails occasionally, that's expected with comprehensive Azure tooling
- All core functionality works normally

**Just keep monitoring weekly and you're golden!** 🎯

---

**Last Updated**: 17. oktoober 2025
**Next Review**: 17. jaanuar 2026

