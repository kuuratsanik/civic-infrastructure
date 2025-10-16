# Windows 11 Pro Complete Development Package Manifest

This file contains the **complete curated list** of packages for a Windows 11 Pro civic infrastructure installation optimized for professional software development.

## 🎯 Installation Profiles

Choose a profile based on your development focus:

- **All**: Complete stack (100+ tools)
- **FullStack**: Web development (front + back)
- **Backend**: Server-side development
- **Frontend**: Client-side development
- **DevOps**: Infrastructure & automation
- **DataScience**: ML, analytics, visualization

## 📦 Complete Package Lists

### Essential Development Tools

```json
{
    "winget_packages": [
        {
            "id": "Microsoft.PowerShell",
            "name": "PowerShell 7",
            "category": "development",
            "priority": "high"
        },
        {
            "id": "Microsoft.VisualStudioCode",
            "name": "Visual Studio Code",
            "category": "development",
            "priority": "high"
        },
        {
            "id": "Git.Git",
            "name": "Git",
            "category": "development",
            "priority": "high"
        },
        {
            "id": "Docker.DockerDesktop",
            "name": "Docker Desktop",
            "category": "development",
            "priority": "medium"
        },
        {
            "id": "Microsoft.WindowsTerminal",
            "name": "Windows Terminal",
            "category": "development",
            "priority": "medium"
        }
    ],
    "vscode_extensions": [
        {
            "id": "ms-vscode.PowerShell",
            "name": "PowerShell",
            "category": "language",
            "priority": "high"
        },
        {
            "id": "ms-vscode-remote.remote-wsl",
            "name": "Remote - WSL",
            "category": "remote",
            "priority": "high"
        },
        {
            "id": "ms-vscode-remote.remote-containers",
            "name": "Remote - Containers",
            "category": "remote",
            "priority": "medium"
        },
        {
            "id": "ms-azuretools.vscode-docker",
            "name": "Docker",
            "category": "development",
            "priority": "medium"
        },
        {
            "id": "eamodio.gitlens",
            "name": "GitLens",
            "category": "git",
            "priority": "medium"
        },
        {
            "id": "github.copilot",
            "name": "GitHub Copilot",
            "category": "ai",
            "priority": "low"
        }
    ],
    "powershell_modules": [
        {
            "name": "PSReadLine",
            "version": "latest",
            "category": "shell",
            "priority": "high"
        },
        {
            "name": "posh-git",
            "version": "latest",
            "category": "git",
            "priority": "medium"
        },
        {
            "name": "PowerShellGet",
            "version": "latest",
            "category": "package-management",
            "priority": "high"
        }
    ]
}
```

## Usage

This manifest can be used with the Developer Cockpit ceremony to ensure consistent package installation across systems.

## Customization

Modify priorities and add/remove packages based on your specific requirements:

- **high**: Essential packages installed first
- **medium**: Important packages installed after essentials
- **low**: Optional packages installed last
