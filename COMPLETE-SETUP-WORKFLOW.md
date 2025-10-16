# 🎯 COMPLETE SETUP WORKFLOW

**From Fresh Windows Install to Production-Ready Development Workstation**

This guide walks you through the entire setup process in the correct order.

---

## 📋 PHASE 1: First Boot Preparation

**Goal:** Remove Ubuntu, repair bootloader, prepare for ceremonies

### ✅ What You Need

- Fresh Windows 11 install (or dual-boot with Ubuntu)
- Small SSD with Ubuntu partitions to remove
- Administrator access

### 🚀 Execute

```powershell
# Step 1: Open PowerShell as Administrator
# Win+X → Windows PowerShell (Admin)

# Step 2: Navigate to workspace
cd "c:\Users\svenk\OneDrive\All_My_Projects\New folder"

# Step 3: Run first boot preparation
.\scripts\setup\Prepare-FirstBoot.ps1

# OR use VS Code Task:
# Ctrl+Shift+P → Tasks: Run Task → "Setup: Prepare First Boot"
```

**This will:**

- 🗑️ Remove GRUB bootloader
- 🗑️ Delete Ubuntu partitions
- 🔧 Repair Windows bootloader
- 🧹 Clean temporary files
- 📁 Prepare governance directories

**Duration:** ~5-10 minutes

### ⚠️ Important

After this step, you MUST restart your computer:

```powershell
Restart-Computer
```

---

## 📋 PHASE 2: After First Restart

**Goal:** Extend C: drive, verify clean boot

### ✅ Verify Boot

- ✅ Windows boots directly (no GRUB menu)
- ✅ No error messages
- ✅ System is responsive

### 🚀 Extend C: Drive

```powershell
# Option A: Automatic (PowerShell)
Get-Partition -DriveLetter C | Resize-Partition -Size (Get-PartitionSupportedSize -DriveLetter C).SizeMax

# Option B: Manual (GUI)
# Win+X → Disk Management
# Right-click C: → Extend Volume
# Follow wizard
```

**Result:** C: drive now includes Ubuntu's freed space (~25-50 GB)

---

## 📋 PHASE 3: Foundation Ceremony

**Goal:** Establish civic governance structure

### 🚀 Execute

```powershell
# PowerShell as Administrator
cd "c:\Users\svenk\OneDrive\All_My_Projects\New folder"

.\scripts\ceremonies\01-foundation\Initialize-Foundation.ps1

# OR use VS Code Task:
# Ctrl+Shift+P → Tasks: Run Task → "Run Foundation Ceremony"
```

**This creates:**

- 📁 Governance directory structure
- 📝 Audit trail system
- 🔐 Configuration anchoring
- 📊 System baseline

**Duration:** ~5 minutes

### ✅ Verify

```powershell
# Check governance directory exists
Test-Path "$env:USERPROFILE\Documents\WindowsGovernance"

# View ceremony log
code "$env:USERPROFILE\Documents\WindowsGovernance\Ceremonies\01-Foundation.md"
```

---

## 📋 PHASE 4: Developer Cockpit Ceremony

**Goal:** Install basic development tools

### 🚀 Execute

```powershell
.\scripts\ceremonies\05-developer-cockpit\Setup-DeveloperEnvironment.ps1

# OR use VS Code Task:
# Ctrl+Shift+P → Tasks: Run Task → "Run Developer Cockpit Ceremony"
```

**This installs:**

- ✅ Winget (verified)
- ✅ PowerShell 7
- ✅ Git
- ✅ VS Code (if not already installed)
- ✅ Basic VS Code extensions
- ✅ WSL2
- ✅ Docker Desktop

**Duration:** ~15 minutes

### ✅ Verify

```powershell
# Check installations
winget --version
git --version
code --version
pwsh --version
```

---

## 📋 PHASE 5: Complete Developer Stack (FINAL SETUP)

**Goal:** Install ALL development tools with specialized configurations

### 🚀 Execute

```powershell
# Full installation (recommended)
.\scripts\ceremonies\10-final-setup\Install-CompleteDeveloperStack.ps1 -Profile All

# OR use VS Code Task:
# Ctrl+Shift+P → Tasks: Run Task → "Setup: Install Complete Developer Stack (All)"
```

**Alternative Profiles:**

```powershell
# Full-stack web development
.\scripts\ceremonies\10-final-setup\Install-CompleteDeveloperStack.ps1 -Profile FullStack

# Backend development
.\scripts\ceremonies\10-final-setup\Install-CompleteDeveloperStack.ps1 -Profile Backend

# Frontend development
.\scripts\ceremonies\10-final-setup\Install-CompleteDeveloperStack.ps1 -Profile Frontend

# DevOps engineering
.\scripts\ceremonies\10-final-setup\Install-CompleteDeveloperStack.ps1 -Profile DevOps

# Data science
.\scripts\ceremonies\10-final-setup\Install-CompleteDeveloperStack.ps1 -Profile DataScience

# Fast mode (skip optional tools)
.\scripts\ceremonies\10-final-setup\Install-CompleteDeveloperStack.ps1 -Profile All -FastMode
```

**This installs (100+ tools):**

**Languages:**

- 🐍 Python 3.12 + tools
- 🟢 Node.js LTS + npm/yarn/pnpm
- 💠 .NET 8 SDK
- 🔵 Go
- 🦀 Rust
- ☕ Java JDK 21
- ⚡ Bun

**Databases:**

- 🐘 PostgreSQL
- 🍃 MongoDB
- 🔴 Redis
- 💾 SQL Server 2022
- 🛠️ DBeaver

**Containers:**

- 🐳 Docker Desktop
- ☸️ Kubernetes (kubectl)
- ⛑️ Helm
- 👓 Lens

**DevOps:**

- 🏗️ Terraform
- 📦 Vagrant
- 🤖 Ansible
- ☁️ Azure CLI

**Web Development:**

- 📮 Postman
- 🛏️ Insomnia
- 🌐 Chrome + Firefox Dev Edition

**VS Code Extensions (50+):**

- Python, JavaScript, TypeScript
- React, Vue, Angular, Svelte
- Docker, Kubernetes
- Git integration
- Formatters, linters
- GitHub Copilot
- Database tools
- And many more...

**Specialized Configurations:**

- ⚙️ Git aliases and settings
- 💻 PowerShell profile with custom functions
- 📦 PowerShell modules (PSReadLine, posh-git)
- 🐍 Python packages (pip, black, pytest, jupyter)
- 📦 Node.js global packages (typescript, webpack, vite)
- 🎨 VS Code settings (themes, formatters, keybindings)

**Duration:** ~45-60 minutes (depending on internet speed)

---

## 📋 PHASE 6: Final Restart

**Goal:** Finalize all installations

### ⚠️ Required Restart

After the complete developer stack installation:

```powershell
# Script will prompt automatically
# Press Enter to restart
```

Or manually:

```powershell
Restart-Computer
```

---

## 📋 PHASE 7: Post-Installation Configuration

**Goal:** Personalize and verify setup

### 🚀 Configure Git Identity

```powershell
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### 🚀 Create Development Directory

```powershell
# Create main dev folder
New-Item -Path "c:\dev" -ItemType Directory
Set-Location "c:\dev"

# Verify PowerShell profile loaded
# (should see enhanced prompt with colors)
```

### 🚀 Verify All Tools

```powershell
# Programming languages
python --version
node --version
npm --version
dotnet --version
go version
rustc --version
java --version

# Version control
git --version
gh --version

# Containers
docker --version
kubectl version --client

# Databases
psql --version
mongo --version
redis-server --version

# DevOps
terraform --version
az --version

# Editors
code --version
pwsh --version
```

### 🚀 Test PowerShell Aliases

```powershell
# Navigate shortcuts
dev          # Go to c:\dev
projects     # Go to projects folder

# Git shortcuts
gs           # git status
ga           # git add .
gc "test"    # git commit -m "test"
gl           # git pull
gp           # git push

# Docker shortcuts
dps          # docker ps
di           # docker images

# Utilities
code-here    # Open VS Code in current directory
open-here    # Open Explorer
```

### 🚀 Test VS Code

```powershell
# Open VS Code
code .

# Verify extensions loaded:
# - Press Ctrl+Shift+X
# - Should see 50+ extensions installed
```

### 🚀 Test WSL2

```powershell
# Check WSL status
wsl --status
wsl --list --verbose

# Enter Ubuntu
wsl

# Update Ubuntu
sudo apt update && sudo apt upgrade -y

# Install common tools
sudo apt install build-essential curl wget git -y

# Exit WSL
exit
```

---

## ✅ FINAL CHECKLIST

### System Setup

- [x] Ubuntu removed from dual-boot
- [x] C: drive extended with reclaimed space
- [x] Windows boots directly (no GRUB)
- [x] Foundation ceremony completed
- [x] Developer Cockpit completed
- [x] Complete Developer Stack installed

### Tools Installed

- [x] Python, Node.js, .NET, Go, Rust, Java
- [x] PostgreSQL, MongoDB, Redis, SQL Server
- [x] Docker, Kubernetes, Helm
- [x] Terraform, Ansible, Azure CLI
- [x] Git, GitHub CLI
- [x] VS Code with 50+ extensions
- [x] WSL2 + Ubuntu

### Configurations Applied

- [x] Git configured (aliases, editor, diff tool)
- [x] PowerShell profile (custom prompt, aliases, functions)
- [x] PowerShell modules (PSReadLine, posh-git)
- [x] Python packages (pip, black, pytest, jupyter)
- [x] Node.js global packages (typescript, webpack, vite)
- [x] VS Code settings (theme, formatters, editor config)

### Verification

- [x] All tools respond to `--version` commands
- [x] PowerShell aliases work
- [x] VS Code opens and shows extensions
- [x] WSL2 accessible and updated
- [x] Development directory created (c:\dev)

---

## 📊 What You Have Now

### 🎯 A Production-Ready Development Workstation With

**100+ Tools Installed:**

- All major programming languages
- Complete database stack
- Container orchestration
- DevOps automation tools
- Web development ecosystem
- Data science tools

**50+ VS Code Extensions:**

- Language support for everything
- Git integration
- Docker & Kubernetes tools
- Formatters & linters
- GitHub Copilot
- Database clients

**Specialized Configurations:**

- Git workflow optimized
- PowerShell productivity enhanced
- VS Code fully customized
- Python & Node.js ready
- WSL2 for Linux compatibility

**Governance Framework:**

- Audit trails for all changes
- Configuration anchoring
- Civic infrastructure patterns
- Reproducible setup process

---

## 🚀 Start Developing

### Create Your First Project

```powershell
# Python web app
dev
mkdir my-python-app
cd my-python-app
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install django
code .

# Node.js app
dev
npx create-next-app my-next-app
cd my-next-app
code .

# Full-stack with Docker
dev
mkdir my-fullstack-app
cd my-fullstack-app
code .
# Create Dockerfile and docker-compose.yml
```

---

## 📚 Key Documentation

- **First Boot Guide:** `FIRST-BOOT-GUIDE.md`
- **Developer Stack Guide:** `DEVELOPER-STACK-GUIDE.md`
- **Foundation Ceremony:** `docs/ceremonies/01-foundation.md`
- **Quick Start:** `QUICK-START.md`
- **Troubleshooting:** `docs/troubleshooting/common-issues.md`

---

## 🎉 You're All Set

Your Windows 11 Pro system is now:

- ✅ **Ubuntu-free** with reclaimed disk space
- ✅ **Governance-ready** with civic infrastructure
- ✅ **Developer-optimized** with 100+ tools
- ✅ **Production-ready** for any project type
- ✅ **Fully configured** with specialized settings
- ✅ **Audit-tracked** with complete ceremony logs

**Time to build something amazing! 🚀**

---

*Part of Windows 11 Pro Civic Infrastructure Project*
*Complete Setup Workflow - Last Updated: 2025-10-15*
