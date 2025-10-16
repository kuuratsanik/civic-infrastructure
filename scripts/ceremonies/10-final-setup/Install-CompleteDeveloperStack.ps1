<#
.SYNOPSIS
    Complete Developer Stack - Install all coding tools with specialized configurations

.DESCRIPTION
    Final ceremony that installs a comprehensive development environment including:
    - Programming languages (Python, Node.js, Rust, Go, .NET, Java)
    - Database tools (PostgreSQL, MongoDB, Redis)
    - Container & orchestration (Docker, Kubernetes)
    - IDE & editors (VS Code with 50+ extensions)
    - DevOps tools (Terraform, Ansible, GitHub CLI)
    - Web development (frameworks, bundlers, preprocessors)
    - Specialized configurations for each tool

.NOTES
    Layer: 10-Final-Setup
    Requires: Administrator privileges, Foundation and Developer Cockpit completed
    Duration: ~45-60 minutes (depending on internet speed)

.PARAMETER Profile
    Development profile: FullStack, Backend, Frontend, DevOps, DataScience, All

.EXAMPLE
    .\Install-CompleteDeveloperStack.ps1 -Profile All

.EXAMPLE
    .\Install-CompleteDeveloperStack.ps1 -Profile FullStack -SkipDatabases
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('FullStack', 'Backend', 'Frontend', 'DevOps', 'DataScience', 'All')]
    [string]$Profile = 'All',

    [switch]$SkipLanguages,
    [switch]$SkipDatabases,
    [switch]$SkipContainers,
    [switch]$SkipVSCodeExtensions,
    [switch]$SkipConfigurations,
    [switch]$FastMode  # Skip non-essential packages
)

# Import civic governance module
$ModulePath = Join-Path $PSScriptRoot "..\..\modules\CivicGovernance.psm1"
Import-Module $ModulePath -Force

Write-Host @"
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║    🎯 COMPLETE DEVELOPER STACK INSTALLATION                ║
║    Profile: $Profile
║                                                            ║
╚════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

Initialize-CivicGovernance

$StartTime = Get-Date
$InstalledPackages = @()
$ConfiguredTools = @()
$FailedPackages = @()

# Helper function to install winget package
function Install-WingetPackage {
    param(
        [string]$PackageId,
        [string]$Name,
        [string]$Category = "General"
    )

    Write-Host "`n   📦 Installing $Name..." -ForegroundColor Cyan
    try {
        winget install $PackageId --accept-source-agreements --accept-package-agreements --silent | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "      ✓ $Name installed successfully" -ForegroundColor Green
            $script:InstalledPackages += $Name
            return $true
        } else {
            Write-Host "      ✗ Failed to install $Name (exit code: $LASTEXITCODE)" -ForegroundColor Red
            $script:FailedPackages += $Name
            return $false
        }
    } catch {
        Write-Host "      ✗ Error installing $Name : $($_.Exception.Message)" -ForegroundColor Red
        $script:FailedPackages += $Name
        return $false
    }
}

# ============================================
# PHASE 1: PACKAGE MANAGERS & FOUNDATIONS
# ============================================
Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "║  PHASE 1: Package Managers             ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Yellow

# Verify Winget
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "   ✗ Winget not found! Install App Installer from Microsoft Store" -ForegroundColor Red
    exit 1
}

Write-Host "   ✓ Winget available: $(winget --version)" -ForegroundColor Green

# Install Chocolatey (alternative package manager)
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "`n   📦 Installing Chocolatey..." -ForegroundColor Cyan
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Write-Host "      ✓ Chocolatey installed" -ForegroundColor Green
    $InstalledPackages += "Chocolatey"
} else {
    Write-Host "   ✓ Chocolatey already installed" -ForegroundColor Green
}

# Install Scoop (user-level package manager)
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host "`n   📦 Installing Scoop..." -ForegroundColor Cyan
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
    Write-Host "      ✓ Scoop installed" -ForegroundColor Green
    $InstalledPackages += "Scoop"
} else {
    Write-Host "   ✓ Scoop already installed" -ForegroundColor Green
}

# ============================================
# PHASE 2: PROGRAMMING LANGUAGES & RUNTIMES
# ============================================
if (-not $SkipLanguages) {
    Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║  PHASE 2: Programming Languages        ║" -ForegroundColor Yellow
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Yellow

    # Python 3.12 + Tools
    Write-Host "`n🐍 Python Ecosystem" -ForegroundColor Magenta
    Install-WingetPackage "Python.Python.3.12" "Python 3.12" "Language"
    Install-WingetPackage "Python.Launcher" "Python Launcher" "Language"

    # Node.js LTS + Tools
    Write-Host "`n🟢 Node.js Ecosystem" -ForegroundColor Magenta
    Install-WingetPackage "OpenJS.NodeJS.LTS" "Node.js LTS" "Language"

    # .NET SDK
    Write-Host "`n💠 .NET Ecosystem" -ForegroundColor Magenta
    Install-WingetPackage "Microsoft.DotNet.SDK.8" ".NET 8 SDK" "Language"
    Install-WingetPackage "Microsoft.DotNet.Runtime.8" ".NET 8 Runtime" "Language"

    if ($Profile -in @('All', 'Backend', 'DevOps')) {
        # Go
        Write-Host "`n🔵 Go Language" -ForegroundColor Magenta
        Install-WingetPackage "GoLang.Go" "Go Programming Language" "Language"

        # Rust
        Write-Host "`n🦀 Rust Language" -ForegroundColor Magenta
        Install-WingetPackage "Rustlang.Rustup" "Rust (rustup)" "Language"
    }

    if ($Profile -in @('All', 'Backend', 'DataScience')) {
        # Java
        Write-Host "`n☕ Java Ecosystem" -ForegroundColor Magenta
        Install-WingetPackage "EclipseAdoptium.Temurin.21.JDK" "Java JDK 21" "Language"
    }

    if ($Profile -in @('All', 'Frontend', 'FullStack')) {
        # Bun (fast all-in-one JavaScript runtime)
        Write-Host "`n⚡ Bun Runtime" -ForegroundColor Magenta
        Install-WingetPackage "Oven-sh.Bun" "Bun" "Language"
    }
}

# ============================================
# PHASE 3: VERSION CONTROL & COLLABORATION
# ============================================
Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "║  PHASE 3: Version Control Tools        ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Yellow

Install-WingetPackage "Git.Git" "Git" "VCS"
Install-WingetPackage "GitHub.cli" "GitHub CLI" "VCS"
Install-WingetPackage "GitKraken.cli" "GitKraken CLI" "VCS"

if ($Profile -in @('All', 'DevOps')) {
    Install-WingetPackage "GitHub.GitLFS" "Git Large File Storage" "VCS"
}

# ============================================
# PHASE 4: CONTAINERS & ORCHESTRATION
# ============================================
if (-not $SkipContainers) {
    Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║  PHASE 4: Container Ecosystem          ║" -ForegroundColor Yellow
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Yellow

    Install-WingetPackage "Docker.DockerDesktop" "Docker Desktop" "Container"

    if ($Profile -in @('All', 'DevOps')) {
        Install-WingetPackage "Kubernetes.kubectl" "Kubernetes kubectl" "Container"
        Install-WingetPackage "Helm.Helm" "Helm" "Container"
        Install-WingetPackage "Mirantis.Lens" "Lens (Kubernetes IDE)" "Container"
    }
}

# ============================================
# PHASE 5: DATABASES & DATA TOOLS
# ============================================
if (-not $SkipDatabases) {
    Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║  PHASE 5: Database Tools               ║" -ForegroundColor Yellow
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Yellow

    if ($Profile -in @('All', 'Backend', 'FullStack', 'DataScience')) {
        Install-WingetPackage "PostgreSQL.PostgreSQL" "PostgreSQL" "Database"
        Install-WingetPackage "MongoDB.Server" "MongoDB Community" "Database"
        Install-WingetPackage "Redis.Redis" "Redis" "Database"
        Install-WingetPackage "dbeaver.dbeaver" "DBeaver (Universal DB Tool)" "Database"
    }

    if ($Profile -in @('All', 'DataScience')) {
        Install-WingetPackage "Microsoft.SQLServer.2022.Developer" "SQL Server 2022 Developer" "Database"
    }
}

# ============================================
# PHASE 6: IDE, EDITORS & TERMINALS
# ============================================
Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "║  PHASE 6: Editors & Terminals          ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Yellow

Install-WingetPackage "Microsoft.VisualStudioCode" "Visual Studio Code" "IDE"
Install-WingetPackage "Microsoft.WindowsTerminal" "Windows Terminal" "Terminal"
Install-WingetPackage "Microsoft.PowerShell" "PowerShell 7" "Shell"

if (-not $FastMode) {
    Install-WingetPackage "Notepad++.Notepad++" "Notepad++" "Editor"
    Install-WingetPackage "AntibodySoftware.WizTree" "WizTree (Disk Analyzer)" "Utility"
}

# ============================================
# PHASE 7: DEVOPS & INFRASTRUCTURE TOOLS
# ============================================
if ($Profile -in @('All', 'DevOps')) {
    Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║  PHASE 7: DevOps Tools                 ║" -ForegroundColor Yellow
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Yellow

    Install-WingetPackage "Hashicorp.Terraform" "Terraform" "DevOps"
    Install-WingetPackage "Hashicorp.Vagrant" "Vagrant" "DevOps"
    Install-WingetPackage "Ansible.Ansible" "Ansible" "DevOps"
    Install-WingetPackage "Microsoft.AzureCLI" "Azure CLI" "Cloud"
}

# ============================================
# PHASE 8: WEB DEVELOPMENT TOOLS
# ============================================
if ($Profile -in @('All', 'Frontend', 'FullStack')) {
    Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║  PHASE 8: Web Development Tools        ║" -ForegroundColor Yellow
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Yellow

    Install-WingetPackage "Postman.Postman" "Postman" "API"
    Install-WingetPackage "Insomnia.Insomnia" "Insomnia" "API"

    if (-not $FastMode) {
        Install-WingetPackage "Google.Chrome" "Google Chrome" "Browser"
        Install-WingetPackage "Mozilla.Firefox.DeveloperEdition" "Firefox Developer Edition" "Browser"
    }
}

# ============================================
# PHASE 9: DATA SCIENCE & ML TOOLS
# ============================================
if ($Profile -in @('All', 'DataScience')) {
    Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║  PHASE 9: Data Science Tools           ║" -ForegroundColor Yellow
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Yellow

    Install-WingetPackage "Anaconda.Anaconda3" "Anaconda (Python Data Science)" "DataScience"
    Install-WingetPackage "RProject.R" "R Language" "DataScience"
    Install-WingetPackage "RStudio.RStudio.OpenSource" "RStudio Desktop" "DataScience"
}

# ============================================
# PHASE 10: ADDITIONAL UTILITIES
# ============================================
Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "║  PHASE 10: Productivity Tools          ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Yellow

if (-not $FastMode) {
    Install-WingetPackage "7zip.7zip" "7-Zip" "Utility"
    Install-WingetPackage "VideoLAN.VLC" "VLC Media Player" "Media"
    Install-WingetPackage "ShareX.ShareX" "ShareX (Screenshot)" "Utility"
    Install-WingetPackage "Microsoft.PowerToys" "PowerToys" "Utility"
    Install-WingetPackage "Flameshot.Flameshot" "Flameshot (Screenshot)" "Utility"
}

# ============================================
# PHASE 11: VS CODE EXTENSIONS (COMPREHENSIVE)
# ============================================
if (-not $SkipVSCodeExtensions -and (Get-Command code -ErrorAction SilentlyContinue)) {
    Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║  PHASE 11: VS Code Extensions (50+)    ║" -ForegroundColor Yellow
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Yellow

    $Extensions = @{
        # Core Extensions (Essential)
        Core         = @(
            'ms-vscode.PowerShell',
            'ms-vscode-remote.remote-wsl',
            'ms-vscode-remote.remote-containers',
            'ms-azuretools.vscode-docker',
            'eamodio.gitlens',
            'mhutchie.git-graph',
            'donjayamanne.githistory'
        )

        # Python Development
        Python       = @(
            'ms-python.python',
            'ms-python.vscode-pylance',
            'ms-python.debugpy',
            'ms-toolsai.jupyter',
            'ms-toolsai.jupyter-keymap',
            'charliermarsh.ruff'
        )

        # JavaScript/TypeScript/Node.js
        JavaScript   = @(
            'dbaeumer.vscode-eslint',
            'esbenp.prettier-vscode',
            'ms-vscode.vscode-typescript-next',
            'formulahendry.code-runner',
            'christian-kohler.npm-intellisense',
            'eg2.vscode-npm-script',
            'wix.vscode-import-cost'
        )

        # Web Development
        Web          = @(
            'ritwickdey.LiveServer',
            'bradlc.vscode-tailwindcss',
            'styled-components.vscode-styled-components',
            'pranaygp.vscode-css-peek',
            'ecmel.vscode-html-css',
            'zignd.html-css-class-completion'
        )

        # Frontend Frameworks
        Frontend     = @(
            'Vue.volar',
            'Angular.ng-template',
            'svelte.svelte-vscode',
            'astro-build.astro-vscode'
        )

        # Backend & API
        Backend      = @(
            'humao.rest-client',
            'rangav.vscode-thunder-client',
            'Postman.postman-for-vscode',
            'GraphQL.vscode-graphql',
            'GraphQL.vscode-graphql-syntax'
        )

        # Databases
        Database     = @(
            'mtxr.sqltools',
            'mongodb.mongodb-vscode',
            'ckolkman.vscode-postgres'
        )

        # DevOps & Cloud
        DevOps       = @(
            'ms-vscode.azure-account',
            'ms-azuretools.vscode-azurefunctions',
            'HashiCorp.terraform',
            'redhat.vscode-yaml',
            'ms-kubernetes-tools.vscode-kubernetes-tools'
        )

        # Languages
        Languages    = @(
            'rust-lang.rust-analyzer',
            'golang.go',
            'ms-dotnettools.csharp',
            'ms-dotnettools.vscode-dotnet-runtime',
            'redhat.java',
            'vscjava.vscode-java-debug'
        )

        # Productivity & Theme
        Productivity = @(
            'PKief.material-icon-theme',
            'zhuangtongfa.material-theme',
            'GitHub.github-vscode-theme',
            'usernamehw.errorlens',
            'wayou.vscode-todo-highlight',
            'Gruntfuggly.todo-tree',
            'streetsidesoftware.code-spell-checker',
            'oderwat.indent-rainbow',
            'CoenraadS.bracket-pair-colorizer-2',
            'naumovs.color-highlight'
        )

        # AI & Copilot
        AI           = @(
            'GitHub.copilot',
            'GitHub.copilot-chat',
            'Continue.continue'
        )
    }

    # Install based on profile
    $ExtensionsToInstall = @()

    # Always install core
    $ExtensionsToInstall += $Extensions.Core
    $ExtensionsToInstall += $Extensions.Productivity

    switch ($Profile) {
        'All' {
            foreach ($category in $Extensions.Keys) {
                $ExtensionsToInstall += $Extensions[$category]
            }
        }
        'FullStack' {
            $ExtensionsToInstall += $Extensions.Python
            $ExtensionsToInstall += $Extensions.JavaScript
            $ExtensionsToInstall += $Extensions.Web
            $ExtensionsToInstall += $Extensions.Frontend
            $ExtensionsToInstall += $Extensions.Backend
            $ExtensionsToInstall += $Extensions.Database
        }
        'Frontend' {
            $ExtensionsToInstall += $Extensions.JavaScript
            $ExtensionsToInstall += $Extensions.Web
            $ExtensionsToInstall += $Extensions.Frontend
        }
        'Backend' {
            $ExtensionsToInstall += $Extensions.Python
            $ExtensionsToInstall += $Extensions.JavaScript
            $ExtensionsToInstall += $Extensions.Backend
            $ExtensionsToInstall += $Extensions.Database
            $ExtensionsToInstall += $Extensions.Languages
        }
        'DevOps' {
            $ExtensionsToInstall += $Extensions.DevOps
            $ExtensionsToInstall += $Extensions.Backend
        }
        'DataScience' {
            $ExtensionsToInstall += $Extensions.Python
            $ExtensionsToInstall += $Extensions.Database
        }
    }

    # Remove duplicates
    $ExtensionsToInstall = $ExtensionsToInstall | Select-Object -Unique

    Write-Host "`n   Installing $($ExtensionsToInstall.Count) VS Code extensions..." -ForegroundColor Cyan
    $ExtensionCount = 0
    foreach ($Extension in $ExtensionsToInstall) {
        $ExtensionCount++
        Write-Progress -Activity "Installing VS Code Extensions" -Status "Extension $ExtensionCount of $($ExtensionsToInstall.Count)" -PercentComplete (($ExtensionCount / $ExtensionsToInstall.Count) * 100)

        try {
            code --install-extension $Extension --force 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "      ✓ $Extension" -ForegroundColor Green
                $ConfiguredTools += "VSCode: $Extension"
            }
        } catch {
            Write-Host "      ✗ Failed: $Extension" -ForegroundColor Red
        }
    }
    Write-Progress -Activity "Installing VS Code Extensions" -Completed
}

# ============================================
# PHASE 12: SPECIALIZED CONFIGURATIONS
# ============================================
if (-not $SkipConfigurations) {
    Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║  PHASE 12: Tool Configurations         ║" -ForegroundColor Yellow
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Yellow

    # Configure Git
    if (Get-Command git -ErrorAction SilentlyContinue) {
        Write-Host "`n📝 Configuring Git..." -ForegroundColor Cyan

        git config --global core.autocrlf true
        git config --global init.defaultBranch main
        git config --global pull.rebase false
        git config --global core.editor "code --wait"
        git config --global diff.tool vscode
        git config --global merge.tool vscode
        git config --global alias.st status
        git config --global alias.co checkout
        git config --global alias.br branch
        git config --global alias.ci commit
        git config --global alias.unstage "reset HEAD --"
        git config --global alias.last "log -1 HEAD"
        git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

        Write-Host "      ✓ Git configured with aliases and VS Code integration" -ForegroundColor Green
        $ConfiguredTools += "Git"
    }

    # Configure PowerShell Profile
    Write-Host "`n📝 Configuring PowerShell Profile..." -ForegroundColor Cyan

    $ProfilePath = $PROFILE.CurrentUserAllHosts
    $ProfileDir = Split-Path $ProfilePath -Parent

    if (-not (Test-Path $ProfileDir)) {
        New-Item -Path $ProfileDir -ItemType Directory -Force | Out-Null
    }

    $ProfileContent = @'
# PowerShell Profile - Developer Optimized

# PSReadLine Configuration
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineOption -EditMode Windows
    Set-PSReadLineOption -BellStyle None
    Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
    Set-PSReadLineKeyHandler -Chord 'Ctrl+w' -Function BackwardDeleteWord
    Set-PSReadLineKeyHandler -Chord 'Alt+d' -Function DeleteWord
    Set-PSReadLineKeyHandler -Chord 'Ctrl+LeftArrow' -Function BackwardWord
    Set-PSReadLineKeyHandler -Chord 'Ctrl+RightArrow' -Function ForwardWord
}

# Posh-Git Integration
if (Get-Module -ListAvailable -Name posh-git) {
    Import-Module posh-git
}

# Custom Aliases
Set-Alias -Name g -Value git
Set-Alias -Name k -Value kubectl
Set-Alias -Name tf -Value terraform
Set-Alias -Name py -Value python
Set-Alias -Name dc -Value docker-compose

# Custom Functions
function code-here { code . }
function open-here { explorer . }
function touch { param($file) New-Item $file -ItemType File -Force }
function mkcd { param($dir) New-Item $dir -ItemType Directory -Force | Set-Location }

# Quick Navigation
function dev { Set-Location "c:\dev" }
function projects { Set-Location "c:\Users\svenk\OneDrive\All_My_Projects" }

# Git Shortcuts
function gs { git status }
function ga { git add . }
function gc { param($msg) git commit -m $msg }
function gp { git push }
function gl { git pull }

# Docker Shortcuts
function dps { docker ps }
function di { docker images }
function dcu { docker-compose up }
function dcd { docker-compose down }

# Enhanced Prompt with Git
function prompt {
    $location = Get-Location
    $gitBranch = if (Get-Command git -ErrorAction SilentlyContinue) {
        $branch = git branch --show-current 2>$null
        if ($branch) { " [$branch]" } else { "" }
    } else { "" }

    Write-Host "PS " -NoNewline -ForegroundColor Green
    Write-Host "$location" -NoNewline -ForegroundColor Cyan
    Write-Host "$gitBranch" -NoNewline -ForegroundColor Yellow
    Write-Host " λ" -NoNewline -ForegroundColor Magenta
    return " "
}

Write-Host "✓ Developer PowerShell Profile Loaded" -ForegroundColor Green
'@

    $ProfileContent | Out-File -FilePath $ProfilePath -Encoding UTF8 -Force
    Write-Host "      ✓ PowerShell profile configured" -ForegroundColor Green
    $ConfiguredTools += "PowerShell Profile"

    # Install PowerShell Modules
    Write-Host "`n📦 Installing PowerShell Modules..." -ForegroundColor Cyan

    $PSModules = @('PSReadLine', 'posh-git', 'PowerShellGet', 'Terminal-Icons', 'PSFzf')

    foreach ($Module in $PSModules) {
        try {
            if (-not (Get-Module -ListAvailable -Name $Module)) {
                Install-Module -Name $Module -Scope CurrentUser -Force -AllowClobber -SkipPublisherCheck
                Write-Host "      ✓ Installed $Module" -ForegroundColor Green
                $ConfiguredTools += "PSModule: $Module"
            } else {
                Write-Host "      ✓ $Module already installed" -ForegroundColor Gray
            }
        } catch {
            Write-Host "      ✗ Failed to install $Module" -ForegroundColor Red
        }
    }

    # Configure Python tools
    if (Get-Command python -ErrorAction SilentlyContinue) {
        Write-Host "`n📝 Configuring Python..." -ForegroundColor Cyan

        # Upgrade pip
        python -m pip install --upgrade pip --quiet

        # Install essential Python packages
        $PythonPackages = @(
            'virtualenv',
            'pipenv',
            'poetry',
            'black',
            'flake8',
            'pylint',
            'pytest',
            'ipython',
            'jupyter',
            'requests',
            'numpy',
            'pandas'
        )

        foreach ($pkg in $PythonPackages) {
            python -m pip install $pkg --quiet 2>&1 | Out-Null
        }

        Write-Host "      ✓ Python tools installed (pip, black, pytest, jupyter, etc.)" -ForegroundColor Green
        $ConfiguredTools += "Python Packages"
    }

    # Configure Node.js global packages
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        Write-Host "`n📝 Configuring Node.js..." -ForegroundColor Cyan

        $NodePackages = @(
            'npm@latest',
            'yarn',
            'pnpm',
            'typescript',
            'ts-node',
            'nodemon',
            'eslint',
            'prettier',
            'webpack',
            'vite',
            'create-react-app',
            'create-next-app',
            '@vue/cli',
            'express-generator'
        )

        foreach ($pkg in $NodePackages) {
            npm install -g $pkg 2>&1 | Out-Null
        }

        Write-Host "      ✓ Node.js global packages installed" -ForegroundColor Green
        $ConfiguredTools += "NPM Global Packages"
    }

    # Configure VS Code settings
    if (Get-Command code -ErrorAction SilentlyContinue) {
        Write-Host "`n📝 Configuring VS Code Settings..." -ForegroundColor Cyan

        $VSCodeSettingsPath = "$env:APPDATA\Code\User\settings.json"
        $VSCodeSettingsDir = Split-Path $VSCodeSettingsPath -Parent

        if (-not (Test-Path $VSCodeSettingsDir)) {
            New-Item -Path $VSCodeSettingsDir -ItemType Directory -Force | Out-Null
        }

        $VSCodeSettings = @{
            "editor.fontSize"                            = 14
            "editor.fontFamily"                          = "Cascadia Code, Consolas, 'Courier New', monospace"
            "editor.fontLigatures"                       = $true
            "editor.tabSize"                             = 2
            "editor.insertSpaces"                        = $true
            "editor.formatOnSave"                        = $true
            "editor.formatOnPaste"                       = $true
            "editor.minimap.enabled"                     = $true
            "editor.bracketPairColorization.enabled"     = $true
            "editor.guides.bracketPairs"                 = "active"
            "editor.suggest.preview"                     = $true
            "editor.inlineSuggest.enabled"               = $true
            "editor.quickSuggestions"                    = @{
                "strings" = $true
            }
            "files.autoSave"                             = "afterDelay"
            "files.autoSaveDelay"                        = 1000
            "files.trimTrailingWhitespace"               = $true
            "files.insertFinalNewline"                   = $true
            "terminal.integrated.fontFamily"             = "Cascadia Code"
            "terminal.integrated.fontSize"               = 13
            "terminal.integrated.defaultProfile.windows" = "PowerShell"
            "workbench.colorTheme"                       = "GitHub Dark Default"
            "workbench.iconTheme"                        = "material-icon-theme"
            "git.autofetch"                              = $true
            "git.confirmSync"                            = $false
            "git.enableSmartCommit"                      = $true
            "explorer.confirmDelete"                     = $false
            "explorer.confirmDragAndDrop"                = $false
            "typescript.updateImportsOnFileMove.enabled" = "always"
            "javascript.updateImportsOnFileMove.enabled" = "always"
            "python.defaultInterpreterPath"              = "python"
            "python.formatting.provider"                 = "black"
            "python.linting.enabled"                     = $true
            "python.linting.pylintEnabled"               = $true
            "[python]"                                   = @{
                "editor.defaultFormatter" = "ms-python.black-formatter"
            }
            "[javascript]"                               = @{
                "editor.defaultFormatter" = "esbenp.prettier-vscode"
            }
            "[typescript]"                               = @{
                "editor.defaultFormatter" = "esbenp.prettier-vscode"
            }
            "[json]"                                     = @{
                "editor.defaultFormatter" = "esbenp.prettier-vscode"
            }
        }

        $VSCodeSettings | ConvertTo-Json -Depth 10 | Out-File -FilePath $VSCodeSettingsPath -Encoding UTF8 -Force
        Write-Host "      ✓ VS Code settings configured" -ForegroundColor Green
        $ConfiguredTools += "VS Code Settings"
    }
}

# ============================================
# PHASE 13: WSL2 & Linux Environment
# ============================================
Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "║  PHASE 13: WSL2 Setup                  ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Yellow

Write-Host "`n🐧 Setting up WSL2..." -ForegroundColor Cyan

# Check if WSL is installed
$WSLInstalled = wsl --status 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "   Installing WSL2..." -ForegroundColor Cyan
    wsl --install --web-download
    Write-Host "   ⚠️ WSL2 installation requires a restart" -ForegroundColor Yellow
} else {
    Write-Host "   ✓ WSL2 already installed" -ForegroundColor Green

    # Install Ubuntu if not present
    $Distros = wsl --list --quiet
    if ($Distros -notcontains "Ubuntu") {
        Write-Host "   Installing Ubuntu..." -ForegroundColor Cyan
        wsl --install Ubuntu --web-download
    } else {
        Write-Host "   ✓ Ubuntu already installed" -ForegroundColor Green
    }
}

# ============================================
# FINAL SUMMARY & AUDIT
# ============================================
$Duration = ((Get-Date) - $StartTime).TotalMinutes
$DurationFormatted = "{0:N1}" -f $Duration

Write-Host @"

╔════════════════════════════════════════════════════════════╗
║                                                            ║
║    ✅ INSTALLATION COMPLETE!                               ║
║    Duration: $DurationFormatted minutes
║                                                            ║
╚════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Green

Write-Host "📊 INSTALLATION SUMMARY" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Gray
Write-Host "   ✓ Packages Installed: $($InstalledPackages.Count)" -ForegroundColor Green
Write-Host "   ✓ Tools Configured: $($ConfiguredTools.Count)" -ForegroundColor Green

if ($FailedPackages.Count -gt 0) {
    Write-Host "   ✗ Failed Packages: $($FailedPackages.Count)" -ForegroundColor Red
    Write-Host "`nFailed packages:" -ForegroundColor Yellow
    $FailedPackages | ForEach-Object { Write-Host "      - $_" -ForegroundColor Red }
}

Write-Host "`n📝 INSTALLED TOOLS BY CATEGORY" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Gray

$InstalledPackages | Sort-Object | Format-Wide -Column 3 | Out-String | Write-Host

# Create final manifest
$ManifestPath = "$env:USERPROFILE\Documents\WindowsGovernance\Configurations\CompleteDeveloperStack.json"

$FinalManifest = @{
    Timestamp         = (Get-Date).ToString('o')
    Profile           = $Profile
    Computer          = $env:COMPUTERNAME
    DurationMinutes   = $Duration
    InstalledPackages = $InstalledPackages
    ConfiguredTools   = $ConfiguredTools
    FailedPackages    = $FailedPackages
    Statistics        = @{
        TotalPackages       = $InstalledPackages.Count
        TotalConfigurations = $ConfiguredTools.Count
        TotalFailures       = $FailedPackages.Count
        SuccessRate         = [math]::Round(($InstalledPackages.Count / ($InstalledPackages.Count + $FailedPackages.Count)) * 100, 2)
    }
}

$FinalManifest | ConvertTo-Json -Depth 5 | Out-File -FilePath $ManifestPath -Encoding UTF8
Write-Host "`n✓ Manifest exported to: $ManifestPath" -ForegroundColor Green

Write-CeremonialAudit -Action "Complete Developer Stack Installed" -Layer "Final-Setup" -Metadata $FinalManifest

Write-Host @"

╔════════════════════════════════════════════════════════════╗
║  NEXT STEPS                                                ║
╚════════════════════════════════════════════════════════════╝

1. ⚠️ RESTART YOUR COMPUTER to finalize installations

2. After restart, verify tools:
   • Open Windows Terminal
   • Test commands: python --version, node --version, git --version

3. Configure your development projects:
   • Create workspace folder: c:\dev
   • Clone your repositories
   • Set up project-specific environments

4. Customize further:
   • Edit PowerShell profile: code $PROFILE
   • Configure Git identity: git config --global user.name "Your Name"
   • Configure Git email: git config --global user.email "email@example.com"

5. Optional: Install fonts
   • Cascadia Code: winget install Microsoft.CascadiaCode
   • Fira Code: winget install FiraCode.FiraCode

╔════════════════════════════════════════════════════════════╗
║  YOUR SYSTEM IS NOW PRODUCTION-READY! 🚀                   ║
╚════════════════════════════════════════════════════════════╝

"@ -ForegroundColor White

Write-Host "Ceremony complete! Press Enter to restart computer..." -ForegroundColor Yellow
Read-Host

Restart-Computer -Confirm
