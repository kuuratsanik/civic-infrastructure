#!/usr/bin/env bash
# Idempotent install for civic-infrastructure on Linux / macOS / WSL / Cloud Agents.
# Provisions PowerShell 7 + Pester and Windows→POSIX env shims so scripts run portably.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"

echo "[install] civic-infrastructure root=$ROOT os=$OS"

install_pwsh_linux() {
  if command -v pwsh >/dev/null 2>&1; then
    echo "[install] PowerShell already present: $(pwsh --version)"
    return
  fi
  echo "[install] Installing PowerShell 7..."
  if command -v apt-get >/dev/null 2>&1; then
    tmp_deb="$(mktemp --suffix=.deb)"
    # Best-effort Ubuntu package; fall back to snap/direct if needed
    if wget -q https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb -O "$tmp_deb" 2>/dev/null; then
      sudo dpkg -i "$tmp_deb" || true
      rm -f "$tmp_deb"
      sudo apt-get update -qq
      sudo apt-get install -y -qq powershell
    else
      echo "[install] apt package feed unavailable — install pwsh manually: https://aka.ms/powershell"
      exit 1
    fi
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y powershell
  else
    echo "[install] Unsupported Linux package manager. Install PowerShell 7 from https://aka.ms/powershell"
    exit 1
  fi
}

install_pwsh_macos() {
  if command -v pwsh >/dev/null 2>&1; then
    echo "[install] PowerShell already present: $(pwsh --version)"
    return
  fi
  if command -v brew >/dev/null 2>&1; then
    brew install --cask powershell
  else
    echo "[install] Install Homebrew then: brew install --cask powershell"
    exit 1
  fi
}

case "$OS" in
  linux*) install_pwsh_linux ;;
  darwin*) install_pwsh_macos ;;
  *)
    echo "[install] Unsupported OS '$OS'. On Windows use winget install Microsoft.PowerShell"
    exit 1
    ;;
esac

# Windows→POSIX environment portability shim
if [[ "$OS" == linux* ]]; then
  echo "[install] Writing /etc/profile.d/10-civic-infra-env.sh ..."
  sudo tee /etc/profile.d/10-civic-infra-env.sh >/dev/null <<'EOS'
# Civic Infrastructure portability shims
export TMPDIR="${TMPDIR:-/tmp}"
export TEMP="${TEMP:-$TMPDIR}"
export TMP="${TMP:-$TMPDIR}"
export USERPROFILE="${USERPROFILE:-$HOME}"
export CIVIC_REPO_ROOT="${CIVIC_REPO_ROOT:-}"
EOS
  sudo chmod 0644 /etc/profile.d/10-civic-infra-env.sh
fi

export TMPDIR="${TMPDIR:-/tmp}"
export TEMP="${TEMP:-$TMPDIR}"
export TMP="${TMP:-$TMPDIR}"
export USERPROFILE="${USERPROFILE:-$HOME}"

echo "[install] Ensuring Pester (>=5) is installed..."
pwsh -NoProfile -Command '
  $have = Get-Module -ListAvailable Pester | Where-Object { $_.Version -ge [version]"5.0.0" }
  if (-not $have) {
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    Install-Module -Name Pester -Scope CurrentUser -Force -SkipPublisherCheck
    Write-Host "[install] Pester installed."
  } else {
    Write-Host "[install] Pester already present: $($have[0].Version)"
  }
'

chmod +x "$ROOT/civic" "$ROOT/scripts/cross-platform/"*.sh 2>/dev/null || true

echo "[install] Running capability check..."
"$ROOT/civic" check || pwsh -NoProfile -File "$ROOT/civic.ps1" check

echo "[install] Done. Next: ./civic host --light   or   ./civic docker --light"
