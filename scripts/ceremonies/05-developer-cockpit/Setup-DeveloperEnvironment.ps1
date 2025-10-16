<#
.SYNOPSIS
    Developer Cockpit Ceremony - Setup development environment for Windows 11 Pro
    
.DESCRIPTION
    Configures the developer environment layer including VS Code, WSL2, 
    containers, and package managers following civic infrastructure principles.
    
.NOTES
    Layer: 05-Developer-Cockpit
    Requires: Administrator privileges
    Duration: ~15 minutes
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$SkipWSL,
    [switch]$SkipDocker,
    [switch]$SkipVSCodeExtensions,
    [switch]$WhatIf
)

# Import the civic governance module
$ModulePath = Join-Path $PSScriptRoot "..\..\modules\CivicGovernance.psm1"
Import-Module $ModulePath -Force

Write-Host "🚀 Developer Cockpit Ceremony" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

Write-Host "`n📦 Phase 1: Package Manager Foundation" -ForegroundColor Yellow

# Check and install Winget if needed
if ($PSCmdlet.ShouldProcess("Winget", "Verify installation")) {
    try {
        $WingetPath = Get-Command winget -ErrorAction SilentlyContinue
        if ($WingetPath) {
            Write-Host "   ✓ Winget is available" -ForegroundColor Green
            $WingetVersion = (winget --version).Trim()
            Write-Host "     Version: $WingetVersion" -ForegroundColor Gray
        } else {
            Write-Host "   ⚠️ Winget not found - install from Microsoft Store" -ForegroundColor Yellow
        }
        
        Write-CeremonialAudit -Action "Check Winget" -Layer "Developer-Cockpit" -Metadata @{
            Available = ($null -ne $WingetPath)
            Version = $WingetVersion
        }
    } catch {
        Write-Warning "Failed to check Winget: $($_.Exception.Message)"
    }
}

# Install/verify PowerShell 7
if ($PSCmdlet.ShouldProcess("PowerShell 7", "Install/verify")) {
    try {
        $PS7Path = Get-Command pwsh -ErrorAction SilentlyContinue
        if ($PS7Path) {
            Write-Host "   ✓ PowerShell 7 is available" -ForegroundColor Green
            $PS7Version = (pwsh --version).Split(' ')[1]
            Write-Host "     Version: $PS7Version" -ForegroundColor Gray
        } else {
            Write-Host "   📥 Installing PowerShell 7..." -ForegroundColor Cyan
            if (Get-Command winget -ErrorAction SilentlyContinue) {
                winget install Microsoft.PowerShell --accept-source-agreements --accept-package-agreements
                Write-Host "   ✓ PowerShell 7 installed" -ForegroundColor Green
            } else {
                Write-Host "   ⚠️ Install PowerShell 7 manually from GitHub releases" -ForegroundColor Yellow
            }
        }
        
        Write-CeremonialAudit -Action "Install PowerShell 7" -Layer "Developer-Cockpit" -Metadata @{
            Available = ($null -ne $PS7Path)
            Version = $PS7Version
        }
    } catch {
        Write-Warning "Failed to install PowerShell 7: $($_.Exception.Message)"
    }
}

Write-Host "`n🐧 Phase 2: WSL2 Configuration" -ForegroundColor Yellow

if (-not $SkipWSL) {
    if ($PSCmdlet.ShouldProcess("WSL2", "Configure")) {
        try {
            # Check if WSL is available
            $WSLStatus = wsl --status 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "   ✓ WSL2 is available" -ForegroundColor Green
                
                # List installed distributions
                $WSLDistros = wsl --list --quiet
                if ($WSLDistros) {
                    Write-Host "   📋 Installed distributions:" -ForegroundColor Gray
                    $WSLDistros | ForEach-Object { Write-Host "     - $_" -ForegroundColor Gray }
                } else {
                    Write-Host "   📥 No WSL distributions installed" -ForegroundColor Yellow
                    Write-Host "     Install Ubuntu: wsl --install Ubuntu" -ForegroundColor Gray
                }
            } else {
                Write-Host "   📥 Installing WSL2..." -ForegroundColor Cyan
                wsl --install --web-download
                Write-Host "   ✓ WSL2 installation initiated (reboot required)" -ForegroundColor Green
            }
            
            Write-CeremonialAudit -Action "Configure WSL2" -Layer "Developer-Cockpit" -Metadata @{
                Available = ($LASTEXITCODE -eq 0)
                Distributions = $WSLDistros
            }
        } catch {
            Write-Warning "Failed to configure WSL2: $($_.Exception.Message)"
        }
    }
}

Write-Host "`n🐳 Phase 3: Container Environment" -ForegroundColor Yellow

if (-not $SkipDocker) {
    if ($PSCmdlet.ShouldProcess("Docker Desktop", "Install/verify")) {
        try {
            $DockerPath = Get-Command docker -ErrorAction SilentlyContinue
            if ($DockerPath) {
                Write-Host "   ✓ Docker is available" -ForegroundColor Green
                $DockerVersion = (docker --version).Split(' ')[2].TrimEnd(',')
                Write-Host "     Version: $DockerVersion" -ForegroundColor Gray
            } else {
                Write-Host "   📥 Installing Docker Desktop..." -ForegroundColor Cyan
                if (Get-Command winget -ErrorAction SilentlyContinue) {
                    winget install Docker.DockerDesktop --accept-source-agreements --accept-package-agreements
                    Write-Host "   ✓ Docker Desktop installation initiated" -ForegroundColor Green
                } else {
                    Write-Host "   ⚠️ Install Docker Desktop manually from docker.com" -ForegroundColor Yellow
                }
            }
            
            Write-CeremonialAudit -Action "Install Docker Desktop" -Layer "Developer-Cockpit" -Metadata @{
                Available = ($null -ne $DockerPath)
                Version = $DockerVersion
            }
        } catch {
            Write-Warning "Failed to install Docker Desktop: $($_.Exception.Message)"
        }
    }
}

Write-Host "`n💻 Phase 4: VS Code Environment" -ForegroundColor Yellow

# Install/verify VS Code
if ($PSCmdlet.ShouldProcess("Visual Studio Code", "Install/verify")) {
    try {
        $CodePath = Get-Command code -ErrorAction SilentlyContinue
        if ($CodePath) {
            Write-Host "   ✓ VS Code is available" -ForegroundColor Green
            $CodeVersion = (code --version).Split("`n")[0]
            Write-Host "     Version: $CodeVersion" -ForegroundColor Gray
        } else {
            Write-Host "   📥 Installing VS Code..." -ForegroundColor Cyan
            if (Get-Command winget -ErrorAction SilentlyContinue) {
                winget install Microsoft.VisualStudioCode --accept-source-agreements --accept-package-agreements
                Write-Host "   ✓ VS Code installed" -ForegroundColor Green
            } else {
                Write-Host "   ⚠️ Install VS Code manually from code.visualstudio.com" -ForegroundColor Yellow
            }
        }
        
        Write-CeremonialAudit -Action "Install VS Code" -Layer "Developer-Cockpit" -Metadata @{
            Available = ($null -ne $CodePath)
            Version = $CodeVersion
        }
    } catch {
        Write-Warning "Failed to install VS Code: $($_.Exception.Message)"
    }
}

# Install essential VS Code extensions
if (-not $SkipVSCodeExtensions -and (Get-Command code -ErrorAction SilentlyContinue)) {
    if ($PSCmdlet.ShouldProcess("VS Code Extensions", "Install essential extensions")) {
        $EssentialExtensions = @(
            'ms-vscode.PowerShell',
            'ms-vscode-remote.remote-wsl',
            'ms-vscode-remote.remote-containers',
            'ms-azuretools.vscode-docker',
            'eamodio.gitlens',
            'github.copilot',
            'ms-vscode.vscode-json'
        )
        
        Write-Host "   📦 Installing essential VS Code extensions..." -ForegroundColor Cyan
        foreach ($Extension in $EssentialExtensions) {
            try {
                code --install-extension $Extension --force
                Write-Host "     ✓ $Extension" -ForegroundColor Green
            } catch {
                Write-Host "     ✗ Failed to install $Extension" -ForegroundColor Red
            }
        }
        
        Write-CeremonialAudit -Action "Install VS Code Extensions" -Layer "Developer-Cockpit" -Metadata @{
            Extensions = $EssentialExtensions
        }
    }
}

Write-Host "`n⚙️ Phase 5: Development Tools" -ForegroundColor Yellow

# Install Git
if ($PSCmdlet.ShouldProcess("Git", "Install/verify")) {
    try {
        $GitPath = Get-Command git -ErrorAction SilentlyContinue
        if ($GitPath) {
            Write-Host "   ✓ Git is available" -ForegroundColor Green
            $GitVersion = (git --version).Split(' ')[2]
            Write-Host "     Version: $GitVersion" -ForegroundColor Gray
        } else {
            Write-Host "   📥 Installing Git..." -ForegroundColor Cyan
            if (Get-Command winget -ErrorAction SilentlyContinue) {
                winget install Git.Git --accept-source-agreements --accept-package-agreements
                Write-Host "   ✓ Git installed" -ForegroundColor Green
            } else {
                Write-Host "   ⚠️ Install Git manually from git-scm.com" -ForegroundColor Yellow
            }
        }
        
        Write-CeremonialAudit -Action "Install Git" -Layer "Developer-Cockpit" -Metadata @{
            Available = ($null -ne $GitPath)
            Version = $GitVersion
        }
    } catch {
        Write-Warning "Failed to install Git: $($_.Exception.Message)"
    }
}

Write-Host "`n📋 Phase 6: Export Development Manifest" -ForegroundColor Yellow

# Create development environment manifest
if ($PSCmdlet.ShouldProcess("Development Manifest", "Create")) {
    $ManifestPath = "$env:USERPROFILE\Documents\WindowsGovernance\Configurations\DeveloperCockpit.json"
    
    $DeveloperManifest = @{
        Timestamp = (Get-Date).ToString('o')
        Computer = $env:COMPUTERNAME
        Tools = @{
            Winget = @{
                Available = ($null -ne (Get-Command winget -ErrorAction SilentlyContinue))
                Version = if (Get-Command winget -ErrorAction SilentlyContinue) { (winget --version).Trim() } else { $null }
            }
            PowerShell7 = @{
                Available = ($null -ne (Get-Command pwsh -ErrorAction SilentlyContinue))
                Version = if (Get-Command pwsh -ErrorAction SilentlyContinue) { (pwsh --version).Split(' ')[1] } else { $null }
            }
            Git = @{
                Available = ($null -ne (Get-Command git -ErrorAction SilentlyContinue))
                Version = if (Get-Command git -ErrorAction SilentlyContinue) { (git --version).Split(' ')[2] } else { $null }
            }
            VSCode = @{
                Available = ($null -ne (Get-Command code -ErrorAction SilentlyContinue))
                Version = if (Get-Command code -ErrorAction SilentlyContinue) { (code --version).Split("`n")[0] } else { $null }
            }
            Docker = @{
                Available = ($null -ne (Get-Command docker -ErrorAction SilentlyContinue))
                Version = if (Get-Command docker -ErrorAction SilentlyContinue) { (docker --version).Split(' ')[2].TrimEnd(',') } else { $null }
            }
        }
        Configuration = @{
            WSLSkipped = $SkipWSL
            DockerSkipped = $SkipDocker
            ExtensionsSkipped = $SkipVSCodeExtensions
        }
    }
    
    $DeveloperManifest | ConvertTo-Json -Depth 3 | Out-File -FilePath $ManifestPath -Encoding UTF8
    Write-Host "   ✓ Developer manifest exported" -ForegroundColor Green
    
    Set-ConfigurationAnchor -ConfigName "DeveloperCockpit" -ConfigPath $ManifestPath -Layer "Developer-Cockpit"
}

Write-Host "`n🎭 Developer Cockpit Ceremony Complete!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host "Your development environment has been configured with civic governance." -ForegroundColor White
Write-Host "Review the manifest: $ManifestPath" -ForegroundColor Gray
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Restart VS Code to load extensions" -ForegroundColor Gray
Write-Host "2. Configure WSL2 distribution if needed" -ForegroundColor Gray
Write-Host "3. Set up Docker Desktop configuration" -ForegroundColor Gray
Write-Host "4. Run UI Ritual ceremony for interface customization" -ForegroundColor Gray

# Final audit entry
Write-CeremonialAudit -Action "Developer Cockpit Ceremony Complete" -Layer "Developer-Cockpit" -Metadata @{
    ManifestPath = $ManifestPath
    ToolsConfigured = @('Winget', 'PowerShell7', 'Git', 'VSCode', 'Docker')
}