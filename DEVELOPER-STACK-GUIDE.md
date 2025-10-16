# Complete Developer Stack Installation Guide

## 🎯 Overview

This ceremony installs **EVERYTHING** you'll ever need for professional software development, including:

- 🐍 **Programming Languages** (Python, Node.js, .NET, Go, Rust, Java)
- 🗄️ **Databases** (PostgreSQL, MongoDB, Redis, SQL Server)
- 🐳 **Container Tools** (Docker, Kubernetes, Helm)
- 💻 **IDEs & Editors** (VS Code with 50+ extensions)
- 🛠️ **DevOps Tools** (Terraform, Ansible, Azure CLI)
- 🌐 **Web Dev Tools** (Postman, Chrome DevTools)
- 📊 **Data Science** (Anaconda, R, RStudio)
- ⚡ **Specialized Configurations** (Git aliases, PowerShell profile, VS Code settings)

**Total Installation Time:** ~45-60 minutes (depending on internet speed)

---

## 🚀 Quick Start

### Basic Installation (All Tools)

```powershell
# Run as Administrator
cd "c:\Users\svenk\OneDrive\All_My_Projects\New folder"

# Install everything with default profile
.\scripts\ceremonies\10-final-setup\Install-CompleteDeveloperStack.ps1 -Profile All
```

### Profile-Specific Installation

Choose a profile based on your primary development focus:

```powershell
# Full-Stack Web Development
.\scripts\ceremonies\10-final-setup\Install-CompleteDeveloperStack.ps1 -Profile FullStack

# Backend Development
.\scripts\ceremonies\10-final-setup\Install-CompleteDeveloperStack.ps1 -Profile Backend

# Frontend Development
.\scripts\ceremonies\10-final-setup\Install-CompleteDeveloperStack.ps1 -Profile Frontend

# DevOps Engineering
.\scripts\ceremonies\10-final-setup\Install-CompleteDeveloperStack.ps1 -Profile DevOps

# Data Science
.\scripts\ceremonies\10-final-setup\Install-CompleteDeveloperStack.ps1 -Profile DataScience
```

### Fast Mode (Skip Optional Tools)

```powershell
# Install only essential tools
.\scripts\ceremonies\10-final-setup\Install-CompleteDeveloperStack.ps1 -Profile All -FastMode
```

---

## 📦 What Gets Installed

### Profile: **All** (Complete Stack)

#### Package Managers

- ✅ **Winget** - Windows Package Manager (built-in)
- ✅ **Chocolatey** - Alternative package manager
- ✅ **Scoop** - User-level package manager

#### Programming Languages

- ✅ **Python 3.12** + pip, virtualenv, poetry, pipenv
- ✅ **Node.js LTS** + npm, yarn, pnpm
- ✅ **.NET 8 SDK** + Runtime
- ✅ **Go** (Golang)
- ✅ **Rust** (via rustup)
- ✅ **Java JDK 21** (Eclipse Temurin)
- ✅ **Bun** (fast JavaScript runtime)

#### Version Control

- ✅ **Git** (with custom aliases and configurations)
- ✅ **GitHub CLI** (gh)
- ✅ **GitKraken CLI**
- ✅ **Git LFS** (Large File Storage)

#### Containers & Orchestration

- ✅ **Docker Desktop**
- ✅ **kubectl** (Kubernetes CLI)
- ✅ **Helm** (Kubernetes package manager)
- ✅ **Lens** (Kubernetes IDE)

#### Databases

- ✅ **PostgreSQL** (latest)
- ✅ **MongoDB Community**
- ✅ **Redis**
- ✅ **SQL Server 2022 Developer Edition**
- ✅ **DBeaver** (universal database tool)

#### Editors & Terminals

- ✅ **Visual Studio Code** (with 50+ extensions)
- ✅ **Windows Terminal**
- ✅ **PowerShell 7**
- ✅ **Notepad++**

#### DevOps & Cloud

- ✅ **Terraform**
- ✅ **Vagrant**
- ✅ **Ansible**
- ✅ **Azure CLI**

#### Web Development

- ✅ **Postman** (API testing)
- ✅ **Insomnia** (alternative API client)
- ✅ **Google Chrome**
- ✅ **Firefox Developer Edition**

#### Data Science

- ✅ **Anaconda** (Python data science distribution)
- ✅ **R Language**
- ✅ **RStudio Desktop**

#### Utilities

- ✅ **7-Zip**
- ✅ **VLC Media Player**
- ✅ **ShareX** (screenshots)
- ✅ **PowerToys**
- ✅ **Flameshot**
- ✅ **WizTree** (disk analyzer)

#### WSL2 & Linux

- ✅ **WSL2** (Windows Subsystem for Linux)
- ✅ **Ubuntu** (latest LTS)

---

### VS Code Extensions (50+)

#### Core Extensions (Always Installed)

```
✓ PowerShell
✓ Remote - WSL
✓ Remote - Containers
✓ Docker
✓ GitLens
✓ Git Graph
✓ Git History
✓ Material Icon Theme
✓ GitHub Theme
✓ Error Lens
✓ TODO Highlight
✓ Code Spell Checker
```

#### Python Development

```
✓ Python
✓ Pylance
✓ Python Debugger
✓ Jupyter
✓ Jupyter Keymap
✓ Ruff (linter/formatter)
```

#### JavaScript/TypeScript/Node.js

```
✓ ESLint
✓ Prettier
✓ TypeScript
✓ Code Runner
✓ npm Intellisense
✓ npm Scripts
✓ Import Cost
```

#### Web Development

```
✓ Live Server
✓ Tailwind CSS IntelliSense
✓ Styled Components
✓ CSS Peek
✓ HTML CSS Support
✓ HTML CSS Class Completion
```

#### Frontend Frameworks

```
✓ Vue (Volar)
✓ Angular Language Service
✓ Svelte
✓ Astro
```

#### Backend & API

```
✓ REST Client
✓ Thunder Client
✓ Postman
✓ GraphQL
✓ GraphQL Syntax
```

#### Databases

```
✓ SQLTools
✓ MongoDB for VS Code
✓ PostgreSQL
```

#### DevOps & Cloud

```
✓ Azure Account
✓ Azure Functions
✓ Terraform
✓ YAML
✓ Kubernetes Tools
```

#### Other Languages

```
✓ Rust Analyzer
✓ Go
✓ C# (OmniSharp)
✓ .NET Runtime
✓ Java Extension Pack
✓ Java Debugger
```

#### AI & Productivity

```
✓ GitHub Copilot
✓ GitHub Copilot Chat
✓ Continue (local AI)
✓ Todo Tree
✓ Indent Rainbow
✓ Bracket Pair Colorizer
✓ Color Highlight
```

---

## ⚙️ Specialized Configurations

### 1. Git Configuration

**Custom Aliases:**

```bash
git st          # git status
git co          # git checkout
git br          # git branch
git ci          # git commit
git unstage     # reset HEAD
git last        # show last commit
git lg          # beautiful log with graph
```

**Editor & Diff Tools:**

- Default editor: VS Code
- Diff tool: VS Code
- Merge tool: VS Code

**Settings:**

- CRLF handling: automatic
- Default branch: main
- Pull strategy: merge (no rebase)

### 2. PowerShell Profile

**Custom Aliases:**

```powershell
g               # git
k               # kubectl
tf              # terraform
py              # python
dc              # docker-compose
```

**Custom Functions:**

```powershell
code-here       # Open VS Code in current directory
open-here       # Open Explorer in current directory
touch <file>    # Create new file
mkcd <dir>      # Create and enter directory
dev             # Navigate to c:\dev
projects        # Navigate to projects folder
```

**Git Shortcuts:**

```powershell
gs              # git status
ga              # git add .
gc "msg"        # git commit -m "msg"
gp              # git push
gl              # git pull
```

**Docker Shortcuts:**

```powershell
dps             # docker ps
di              # docker images
dcu             # docker-compose up
dcd             # docker-compose down
```

**Enhanced Prompt:**

- Shows current directory in cyan
- Shows Git branch in yellow
- Custom prompt symbol (λ)

### 3. PowerShell Modules

```powershell
✓ PSReadLine       # Intelligent command-line editing
✓ posh-git         # Git integration in prompt
✓ PowerShellGet    # Module management
✓ Terminal-Icons   # File/folder icons in terminal
✓ PSFzf            # Fuzzy finder integration
```

**PSReadLine Features:**

- Predictive IntelliSense from history
- List view for predictions
- Ctrl+D to delete character
- Ctrl+W to delete word backward
- Alt+D to delete word forward
- Ctrl+Arrow for word navigation

### 4. Python Configuration

**Installed Packages:**

```
✓ pip (latest)
✓ virtualenv      # Virtual environments
✓ pipenv          # Pipfile-based environments
✓ poetry          # Modern dependency management
✓ black           # Code formatter
✓ flake8          # Linter
✓ pylint          # Advanced linter
✓ pytest          # Testing framework
✓ ipython         # Enhanced Python shell
✓ jupyter         # Notebooks
✓ requests        # HTTP library
✓ numpy           # Numerical computing
✓ pandas          # Data analysis
```

### 5. Node.js Global Packages

```
✓ npm (latest)
✓ yarn            # Alternative package manager
✓ pnpm            # Fast package manager
✓ typescript      # TypeScript compiler
✓ ts-node         # TypeScript execution
✓ nodemon         # Auto-restart on changes
✓ eslint          # Linter
✓ prettier        # Code formatter
✓ webpack         # Bundler
✓ vite            # Fast build tool
✓ create-react-app    # React starter
✓ create-next-app     # Next.js starter
✓ @vue/cli            # Vue CLI
✓ express-generator   # Express starter
```

### 6. VS Code Settings

**Editor:**

- Font: Cascadia Code with ligatures
- Font size: 14
- Tab size: 2 spaces
- Format on save: ✅
- Format on paste: ✅
- Bracket pair colorization: ✅
- Minimap: ✅

**Files:**

- Auto-save: After 1 second delay
- Trim trailing whitespace: ✅
- Insert final newline: ✅

**Terminal:**

- Font: Cascadia Code
- Font size: 13
- Default shell: PowerShell

**Theme:**

- Color theme: GitHub Dark Default
- Icon theme: Material Icon Theme

**Git:**

- Auto-fetch: ✅
- Confirm sync: ❌
- Smart commit: ✅

**Language-Specific:**

- Python formatter: Black
- JavaScript formatter: Prettier
- TypeScript formatter: Prettier
- JSON formatter: Prettier

---

## 📊 Installation by Profile

### FullStack Profile

Installs:

- Python + JavaScript/TypeScript
- All web frameworks
- Backend & frontend tools
- Databases
- All VS Code extensions

**Use for:** Full-stack web development, MERN/MEAN stack, Django + React, etc.

### Backend Profile

Installs:

- Python, Node.js, Go, Rust, Java
- Databases (PostgreSQL, MongoDB, Redis)
- Backend frameworks
- API tools

**Use for:** Backend development, microservices, API development

### Frontend Profile

Installs:

- JavaScript/TypeScript ecosystem
- Frontend frameworks (React, Vue, Angular, Svelte)
- Web development tools
- Browser dev tools

**Use for:** Frontend development, web design, UI/UX implementation

### DevOps Profile

Installs:

- Container tools (Docker, Kubernetes)
- Infrastructure as Code (Terraform, Ansible)
- Cloud CLIs (Azure, AWS)
- CI/CD tools

**Use for:** DevOps, SRE, infrastructure management, cloud engineering

### DataScience Profile

Installs:

- Python scientific stack
- R language
- Jupyter notebooks
- Databases
- Anaconda distribution

**Use for:** Data science, machine learning, statistical analysis

---

## 🔧 Advanced Options

### Skip Specific Phases

```powershell
# Skip language installation
.\Install-CompleteDeveloperStack.ps1 -SkipLanguages

# Skip database tools
.\Install-CompleteDeveloperStack.ps1 -SkipDatabases

# Skip container tools
.\Install-CompleteDeveloperStack.ps1 -SkipContainers

# Skip VS Code extensions
.\Install-CompleteDeveloperStack.ps1 -SkipVSCodeExtensions

# Skip all configurations (install only)
.\Install-CompleteDeveloperStack.ps1 -SkipConfigurations

# Combine multiple skips
.\Install-CompleteDeveloperStack.ps1 -SkipDatabases -SkipContainers
```

### Preview Mode

```powershell
# See what would be installed (WhatIf mode)
.\Install-CompleteDeveloperStack.ps1 -Profile All -WhatIf
```

---

## ✅ Post-Installation Checklist

### Immediate Actions (Before Restart)

1. ✅ Review installation summary
2. ✅ Check for failed packages
3. ✅ Note any warnings

### After Restart

1. ✅ Verify installations:

   ```powershell
   # Test each tool
   python --version
   node --version
   npm --version
   git --version
   docker --version
   code --version
   ```

2. ✅ Configure Git identity:

   ```powershell
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"
   ```

3. ✅ Create development directory:

   ```powershell
   New-Item -Path "c:\dev" -ItemType Directory
   Set-Location "c:\dev"
   ```

4. ✅ Test VS Code:

   ```powershell
   code .
   ```

5. ✅ Test PowerShell profile:

   ```powershell
   # Close and reopen terminal
   # Prompt should show enhanced colors and Git branch
   ```

6. ✅ Verify WSL2:

   ```powershell
   wsl --list --verbose
   wsl --status
   ```

### Optional Font Installation

For better terminal experience:

```powershell
# Cascadia Code (recommended)
winget install Microsoft.CascadiaCode

# Fira Code (alternative with ligatures)
winget install FiraCode.FiraCode

# Nerd Fonts (icons in terminal)
scoop bucket add nerd-fonts
scoop install FiraCode-NF
```

---

## 🛠️ Customization After Installation

### Edit PowerShell Profile

```powershell
# Open profile in VS Code
code $PROFILE

# Add your own aliases, functions, configurations
```

### Edit Git Configuration

```powershell
# Set custom Git editor
git config --global core.editor "code --wait"

# Set diff tool
git config --global diff.tool vscode

# Add more aliases
git config --global alias.undo "reset HEAD~1"
```

### Edit VS Code Settings

```powershell
# Open settings in VS Code
code $env:APPDATA\Code\User\settings.json

# Or use VS Code UI
# Press: Ctrl+, (open settings)
```

---

## 📚 Common Development Workflows

### Create New Python Project

```powershell
# Navigate to dev folder
dev

# Create project directory
mkdir my-python-project
cd my-python-project

# Create virtual environment
python -m venv venv

# Activate virtual environment
.\venv\Scripts\Activate.ps1

# Install dependencies
pip install django flask fastapi

# Open in VS Code
code .
```

### Create New Node.js Project

```powershell
# Navigate to dev folder
dev

# Create Next.js app
npx create-next-app my-next-app
cd my-next-app

# Install dependencies
npm install

# Run development server
npm run dev

# Open in VS Code
code .
```

### Create New Docker Project

```powershell
# Create project
dev
mkdir my-docker-app
cd my-docker-app

# Create Dockerfile
touch Dockerfile

# Create docker-compose.yml
touch docker-compose.yml

# Open in VS Code
code .
```

---

## 🚨 Troubleshooting

### Winget Issues

**Problem:** `winget: command not found`

**Solution:**

```powershell
# Install App Installer from Microsoft Store
start ms-windows-store://pdp/?ProductId=9NBLGGH4NNS1

# Or download from GitHub
# https://github.com/microsoft/winget-cli/releases
```

### VS Code Extensions Failed

**Problem:** Some extensions didn't install

**Solution:**

```powershell
# Manually install from VS Code
# Press: Ctrl+Shift+X
# Search for extension name
# Click Install
```

### Python Not in PATH

**Problem:** `python: command not found` after installation

**Solution:**

```powershell
# Close and reopen terminal
# Or add manually to PATH in System Properties
```

### Docker Desktop Won't Start

**Problem:** Docker Desktop fails to start

**Solution:**

```powershell
# Enable Hyper-V and WSL2
wsl --install
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All

# Restart computer
Restart-Computer
```

---

## 📊 Installation Manifest

After installation, check the manifest:

```powershell
# View installation summary
code "$env:USERPROFILE\Documents\WindowsGovernance\Configurations\CompleteDeveloperStack.json"
```

**Manifest includes:**

- Timestamp of installation
- Profile used
- List of all installed packages
- List of all configured tools
- Failed packages (if any)
- Duration of installation
- Success rate statistics

---

## 🎯 Next Steps After Complete Setup

1. **Clone Your Projects**

   ```powershell
   dev
   git clone https://github.com/yourusername/your-repo.git
   cd your-repo
   code .
   ```

2. **Set Up Project Environments**
   - Python: Create `venv` or use `poetry`
   - Node.js: Run `npm install`
   - Docker: Build containers with `docker-compose up`

3. **Configure Additional Tools**
   - Set up SSH keys for GitHub
   - Configure AWS/Azure credentials
   - Install project-specific extensions

4. **Explore Installed Tools**
   - Try PowerShell aliases (`gs`, `ga`, `gc`)
   - Use VS Code integrated terminal
   - Experiment with Docker containers

5. **Start Coding! 🚀**

---

## 📈 System Requirements

**Minimum:**

- Windows 11 Pro
- 8 GB RAM
- 50 GB free disk space
- Stable internet connection

**Recommended:**

- Windows 11 Pro (latest update)
- 16 GB+ RAM
- 100 GB+ free disk space (SSD)
- Fast internet (10+ Mbps)

---

## 📝 Summary

This ceremony provides a **production-ready, enterprise-grade development environment** with:

- ✅ All major programming languages
- ✅ Complete database stack
- ✅ Container orchestration tools
- ✅ DevOps & cloud tools
- ✅ 50+ VS Code extensions
- ✅ Specialized configurations
- ✅ PowerShell productivity enhancements
- ✅ Git workflow optimizations
- ✅ WSL2 for Linux compatibility

**Total tools installed:** 100+
**Total configurations:** 20+
**Installation time:** ~45-60 minutes
**Result:** Professional development workstation ready for any project! 🎉

---

*Part of Windows 11 Pro Civic Infrastructure Project*
*Last Updated: 2025-10-15*
