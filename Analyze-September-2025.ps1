#Requires -Version 5.1
<#
.SYNOPSIS
    Automated September 2025 Article Analysis
.DESCRIPTION
    Fetches and analyzes all 10 articles from September 2025
    using the same proven workflow as October 2025
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$WorkspaceRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$OutputDir = Join-Path $WorkspaceRoot "september-2025"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "September 2025 Analysis Automation" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Article metadata
$articles = @(
  @{
    Title    = "MINIX Elite EU715-AI Review The Mini PC Designed for AI and Home Labs"
    URL      = "https://www.virtualizationhowto.com/2025/09/minix-elite-eu715-ai-review-the-mini-pc-designed-for-ai-and-home-labs/"
    Date     = "September 30, 2025"
    Category = "Home Lab"
    Filename = "01-minix-elite-eu715-ai-review.md"
  },
  @{
    Title    = "Why Pangolin is the one reverse proxy I'd pick if I was starting my home lab today"
    URL      = "https://www.virtualizationhowto.com/2025/09/why-pangolin-is-the-one-reverse-proxy-id-pick-if-i-was-starting-my-home-lab-today/"
    Date     = "September 29, 2025"
    Category = "Home Lab"
    Filename = "02-pangolin-reverse-proxy.md"
  },
  @{
    Title    = "The First Hardware I Always Buy for Any Home Lab"
    URL      = "https://www.virtualizationhowto.com/2025/09/the-first-hardware-i-always-buy-for-any-home-lab/"
    Date     = "September 26, 2025"
    Category = "Home Lab"
    Filename = "03-first-hardware-home-lab.md"
  },
  @{
    Title    = "Nginx Proxy Manager vs NPMplus Which One is Better for Your Home Lab?"
    URL      = "https://www.virtualizationhowto.com/2025/09/nginx-proxy-manager-vs-npmplus-which-one-is-better-for-your-home-lab/"
    Date     = "September 25, 2025"
    Category = "Containers"
    Filename = "04-nginx-proxy-manager-vs-npmplus.md"
  },
  @{
    Title    = "Best Docker containers for Docker Desktop in 2025"
    URL      = "https://www.virtualizationhowto.com/2025/09/best-docker-containers-for-docker-desktop-in-2025/"
    Date     = "September 24, 2025"
    Category = "Networking"
    Filename = "05-best-docker-containers-2025.md"
  },
  @{
    Title    = "5 Things You Should Know About OPNsense Before You Install It"
    URL      = "https://www.virtualizationhowto.com/2025/09/5-things-you-should-know-about-opnsense-before-you-install-it/"
    Date     = "September 23, 2025"
    Category = "Windows"
    Filename = "06-opnsense-5-things.md"
  },
  @{
    Title    = "Windows 11 25H2 ISOs and Enablement Package Download Released Ahead of Launch"
    URL      = "https://www.virtualizationhowto.com/2025/09/windows-11-25h2-isos-and-enablement-package-download-released-ahead-of-launch/"
    Date     = "September 22, 2025"
    Category = "Windows"
    Filename = "07-windows-11-25h2-isos.md"
  },
  @{
    Title    = "Why Your Mini PC's NVMe Drive Isn't as Fast as You Think"
    URL      = "https://www.virtualizationhowto.com/2025/09/why-your-mini-pcs-nvme-drive-isnt-as-fast-as-you-think/"
    Date     = "September 22, 2025"
    Category = "Mini PC & Server"
    Filename = "08-mini-pc-nvme-performance.md"
  },
  @{
    Title    = "The First Services I Always Spin Up in Any Home Lab"
    URL      = "https://www.virtualizationhowto.com/2025/09/the-first-services-i-always-spin-up-in-any-home-lab/"
    Date     = "September 19, 2025"
    Category = "Home Lab"
    Filename = "09-first-services-home-lab.md"
  },
  @{
    Title    = "Proxmox Enhanced Configuration Utility (PECU): The Ultimate Proxmox VE GPU Toolkit for 2025"
    URL      = "https://www.virtualizationhowto.com/2025/09/proxmox-enhanced-configuration-utility-pecu-the-ultimate-proxmox-ve-gpu-toolkit-for-2025/"
    Date     = "September 18, 2025"
    Category = "Proxmox"
    Filename = "10-proxmox-pecu-gpu-toolkit.md"
  }
)

Write-Host "Found $($articles.Count) articles to analyze`n" -ForegroundColor Green

# Create article index
$indexContent = @"
# September 2025 Articles - Analysis Index

**Analysis Date**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Total Articles**: $($articles.Count)
**Source**: https://www.virtualizationhowto.com/2025/9/

## Article List

"@

for ($i = 0; $i -lt $articles.Count; $i++) {
  $article = $articles[$i]
  $indexContent += @"
### $($i + 1). $($article.Title)
- **Date**: $($article.Date)
- **Category**: $($article.Category)
- **URL**: $($article.URL)
- **Analysis File**: articles/$($article.Filename)

"@
}

$indexContent += @"

## Analysis Status

This index will be updated as articles are analyzed.

- [ ] Article 1: MINIX Elite EU715-AI Review
- [ ] Article 2: Pangolin Reverse Proxy
- [ ] Article 3: First Hardware for Home Lab
- [ ] Article 4: Nginx Proxy Manager vs NPMplus
- [ ] Article 5: Best Docker Containers 2025
- [ ] Article 6: OPNsense 5 Things
- [ ] Article 7: Windows 11 25H2 ISOs
- [ ] Article 8: Mini PC NVMe Performance
- [ ] Article 9: First Services Home Lab
- [ ] Article 10: Proxmox PECU GPU Toolkit

## Next Steps

1. Analyze each article (automated via GitHub Copilot)
2. Create implementation roadmap
3. Create executive summary
4. Log to blockchain (Record #11)

---

*Generated by Analyze-September-2025.ps1*
"@

$indexPath = Join-Path $OutputDir "article-index.md"
Set-Content -Path $indexPath -Value $indexContent -Encoding UTF8
Write-Host "[SUCCESS] Created article-index.md`n" -ForegroundColor Green

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Ready for AI Analysis" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Next: GitHub Copilot will analyze each article" -ForegroundColor Yellow
Write-Host "Progress will be tracked in article-index.md`n" -ForegroundColor Gray
