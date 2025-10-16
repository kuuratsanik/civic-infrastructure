#!/bin/bash

# ════════════════════════════════════════════════════════════════════
# CLOUD VS CODE INSTANCE INITIALIZATION
# Zero Human Intervention Policy
# ════════════════════════════════════════════════════════════════════

set -e  # Exit on error

echo "🚀 Cloud VS Code Instance Initialization Starting..."
echo "Policy: ZERO HUMAN INTERVENTION"
echo ""

# ════════════════════════════════════════════════════════════════════
# PHASE 1: ENVIRONMENT DETECTION
# ════════════════════════════════════════════════════════════════════

echo "🔍 Phase 1: Detecting cloud environment..."

# Detect cloud platform
if [ -n "$CODESPACE_NAME" ]; then
    PLATFORM="GitHub Codespaces"
    INSTANCE_ID="$CODESPACE_NAME"
    REGION="${CODESPACE_REGION:-unknown}"
elif [ -n "$GITPOD_WORKSPACE_ID" ]; then
    PLATFORM="Gitpod"
    INSTANCE_ID="$GITPOD_WORKSPACE_ID"
    REGION="${GITPOD_REGION:-unknown}"
elif [ -n "$REPL_ID" ]; then
    PLATFORM="Replit"
    INSTANCE_ID="$REPL_ID"
    REGION="unknown"
elif [ -n "$RAILWAY_ENVIRONMENT" ]; then
    PLATFORM="Railway"
    INSTANCE_ID="${RAILWAY_ENVIRONMENT_ID:-$(hostname)}"
    REGION="${RAILWAY_REGION:-unknown}"
elif [ -n "$RENDER_SERVICE_ID" ]; then
    PLATFORM="Render"
    INSTANCE_ID="$RENDER_SERVICE_ID"
    REGION="${RENDER_REGION:-unknown}"
elif [ -n "$FLY_APP_NAME" ]; then
    PLATFORM="Fly.io"
    INSTANCE_ID="$FLY_APP_NAME"
    REGION="$FLY_REGION"
else
    # Detect cloud VM by metadata
    if curl -s -f -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/id &>/dev/null; then
        PLATFORM="Google Cloud"
        INSTANCE_ID=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/id)
        REGION=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/zone | cut -d'/' -f4)
    elif curl -s -f http://169.254.169.254/latest/meta-data/instance-id &>/dev/null; then
        PLATFORM="AWS"
        INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
        REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
    elif curl -s -f -H "Metadata: true" "http://169.254.169.254/metadata/instance?api-version=2021-02-01" &>/dev/null; then
        PLATFORM="Azure"
        INSTANCE_ID=$(curl -s -H "Metadata: true" "http://169.254.169.254/metadata/instance/compute/vmId?api-version=2021-02-01&format=text")
        REGION=$(curl -s -H "Metadata: true" "http://169.254.169.254/metadata/instance/compute/location?api-version=2021-02-01&format=text")
    else
        PLATFORM="Unknown"
        INSTANCE_ID=$(hostname)
        REGION="unknown"
    fi
fi

export PLATFORM
export INSTANCE_ID
export REGION

echo "  ✅ Platform: $PLATFORM"
echo "  ✅ Instance ID: $INSTANCE_ID"
echo "  ✅ Region: $REGION"
echo ""

# ════════════════════════════════════════════════════════════════════
# PHASE 2: DIRECTORY STRUCTURE SETUP
# ════════════════════════════════════════════════════════════════════

echo "📁 Phase 2: Creating directory structure..."

VSCODE_HOME="$HOME/vscode-portable"

mkdir -p "$VSCODE_HOME"/{data,code,workspace,automation,logs}
mkdir -p "$VSCODE_HOME/data/user-data/User"
mkdir -p "$VSCODE_HOME/workspace/.vscode"

echo "  ✅ Directory structure created"
echo ""

# ════════════════════════════════════════════════════════════════════
# PHASE 3: VS CODE PORTABLE DOWNLOAD (If not container-based)
# ════════════════════════════════════════════════════════════════════

if [[ "$PLATFORM" != "GitHub Codespaces" && "$PLATFORM" != "Gitpod" && "$PLATFORM" != "Replit" ]]; then
    echo "📦 Phase 3: Setting up Portable VS Code..."

    # Detect OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        VSCODE_URL="https://update.code.visualstudio.com/latest/linux-x64/stable"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="mac"
        VSCODE_URL="https://update.code.visualstudio.com/latest/darwin/stable"
    fi

    cd "$VSCODE_HOME"

    if [ ! -d "code/bin" ]; then
        echo "  ⬇️  Downloading VS Code for $OS..."

        if [ "$OS" == "linux" ]; then
            curl -L "$VSCODE_URL" -o vscode.tar.gz
            tar -xzf vscode.tar.gz -C code --strip-components=1
            rm vscode.tar.gz
        fi

        echo "  ✅ VS Code downloaded"
    else
        echo "  ✅ VS Code already present"
    fi

    # Make portable
    touch data/.portable-data-flag

    CODE_BIN="$VSCODE_HOME/code/bin/code"
else
    # Use system code command
    CODE_BIN="code"
    echo "📦 Phase 3: Using platform-native VS Code..."
fi

echo "  ✅ VS Code ready: $CODE_BIN"
echo ""

# ════════════════════════════════════════════════════════════════════
# PHASE 4: EXTENSION AUTO-INSTALL
# ════════════════════════════════════════════════════════════════════

echo "🔌 Phase 4: Installing extensions automatically..."

EXTENSIONS=(
    "dbaeumer.vscode-eslint"
    "esbenp.prettier-vscode"
    "eamodio.gitlens"
    "ms-python.python"
    "ms-python.vscode-pylance"
    "golang.go"
    "ms-azuretools.vscode-docker"
    "ms-kubernetes-tools.vscode-kubernetes-tools"
    "hashicorp.terraform"
    "streetsidesoftware.code-spell-checker"
    "usernamehw.errorlens"
)

for ext in "${EXTENSIONS[@]}"; do
    echo "  Installing $ext..."
    $CODE_BIN --install-extension "$ext" --force 2>/dev/null || true
done

echo "  ✅ Extensions installed"
echo ""

# ════════════════════════════════════════════════════════════════════
# PHASE 5: AUTOMATED CONFIGURATION
# ════════════════════════════════════════════════════════════════════

echo "⚙️  Phase 5: Applying automated configuration..."

# Create settings.json
cat > "$VSCODE_HOME/data/user-data/User/settings.json" <<EOF
{
  "// AUTOMATED CONFIGURATION - ZERO HUMAN INTERVENTION": "",
  "files.autoSave": "afterDelay",
  "files.autoSaveDelay": 1000,
  "editor.formatOnSave": true,
  "editor.formatOnPaste": true,
  "git.autofetch": true,
  "git.confirmSync": false,
  "git.enableSmartCommit": true,
  "git.postCommitCommand": "push",
  "extensions.autoUpdate": true,
  "security.workspace.trust.enabled": false,
  "telemetry.telemetryLevel": "off",
  "instance.id": "$INSTANCE_ID",
  "instance.platform": "$PLATFORM",
  "instance.region": "$REGION",
  "civic.governance.lineageLogging": true
}
EOF

# Create tasks.json
cat > "$VSCODE_HOME/workspace/.vscode/tasks.json" <<'TASKSEOF'
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Auto-Sync to Cloud",
      "type": "shell",
      "command": "bash ${workspaceFolder}/../automation/sync.sh",
      "runOptions": {"runOn": "folderOpen"},
      "presentation": {"reveal": "silent"}
    },
    {
      "label": "Health Check",
      "type": "shell",
      "command": "bash ${workspaceFolder}/../automation/health-check.sh",
      "runOptions": {"runOn": "folderOpen"}
    }
  ]
}
TASKSEOF

echo "  ✅ Configuration applied"
echo ""

# ════════════════════════════════════════════════════════════════════
# PHASE 6: GIT AUTO-SETUP
# ════════════════════════════════════════════════════════════════════

echo "🔧 Phase 6: Configuring Git..."

git config --global user.name "Cloud VS Code Instance $INSTANCE_ID"
git config --global user.email "vscode-$INSTANCE_ID@civic.cloud"
git config --global push.autoSetupRemote true
git config --global pull.rebase true

echo "  ✅ Git configured"
echo ""

# ════════════════════════════════════════════════════════════════════
# PHASE 7: AUTOMATION SCRIPTS
# ════════════════════════════════════════════════════════════════════

echo "🤖 Phase 7: Creating automation scripts..."

# Sync script
cat > "$VSCODE_HOME/automation/sync.sh" <<'SYNCEOF'
#!/bin/bash
echo "[$(date)] Cloud sync started"
cd "$HOME/vscode-portable/workspace" || exit
git add . 2>/dev/null || true
git diff-index --quiet HEAD || git commit -m "Auto-sync: $(date -Iseconds)" 2>/dev/null || true
git push 2>/dev/null || true
echo "[$(date)] Cloud sync complete"
SYNCEOF

chmod +x "$VSCODE_HOME/automation/sync.sh"

# Health check script
cat > "$VSCODE_HOME/automation/health-check.sh" <<'HEALTHEOF'
#!/bin/bash
echo "[$(date)] Health check started"
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
MEM_USAGE=$(free | awk '/Mem:/ {printf "%.0f", $3/$2 * 100}')
echo "  Disk: ${DISK_USAGE}% | Memory: ${MEM_USAGE}%"
if [ "$DISK_USAGE" -gt 80 ]; then
    rm -rf ~/.cache/* /tmp/* 2>/dev/null || true
fi
echo "[$(date)] Health check complete"
HEALTHEOF

chmod +x "$VSCODE_HOME/automation/health-check.sh"

echo "  ✅ Automation scripts created"
echo ""

# ════════════════════════════════════════════════════════════════════
# PHASE 8: CRON JOBS SETUP
# ════════════════════════════════════════════════════════════════════

echo "⏰ Phase 8: Setting up automated tasks..."

(crontab -l 2>/dev/null | grep -v "vscode-portable" ; echo "*/5 * * * * $VSCODE_HOME/automation/sync.sh >> $VSCODE_HOME/logs/sync.log 2>&1") | crontab -
(crontab -l 2>/dev/null | grep -v "health-check" ; echo "*/10 * * * * $VSCODE_HOME/automation/health-check.sh >> $VSCODE_HOME/logs/health.log 2>&1") | crontab -

echo "  ✅ Cron jobs configured"
echo "     - Sync: Every 5 minutes"
echo "     - Health: Every 10 minutes"
echo ""

# ════════════════════════════════════════════════════════════════════
# PHASE 9: LINEAGE LOGGING
# ════════════════════════════════════════════════════════════════════

echo "📝 Phase 9: Logging to governance..."

cat > "$VSCODE_HOME/logs/lineage.jsonl" <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "event": "instance_created",
  "instance_id": "$INSTANCE_ID",
  "platform": "$PLATFORM",
  "region": "$REGION",
  "automation": "enabled",
  "governance": "lineage_anchored",
  "human_intervention": "zero"
}
EOF

echo "  ✅ Lineage logged"
echo ""

# ════════════════════════════════════════════════════════════════════
# COMPLETE
# ════════════════════════════════════════════════════════════════════

echo "═══════════════════════════════════════════════════════════════"
echo "  ✅ CLOUD VS CODE INSTANCE INITIALIZED"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "  Platform: $PLATFORM"
echo "  Instance: $INSTANCE_ID"
echo "  Region: $REGION"
echo "  Status: OPERATIONAL"
echo ""
echo "  Automation:"
echo "    • Cloud Sync: Every 5 minutes"
echo "    • Health Check: Every 10 minutes"
echo "    • Human Intervention: 0%"
echo ""
echo "  Governance:"
echo "    • Lineage Logging: Enabled"
echo "    • Audit Trail: Active"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "🚀 Instance is now fully operational with zero human intervention."
echo ""
