#!/usr/bin/env bash
# Cross-platform bootstrap wrapper (Linux / macOS / WSL / CI / containers).
# Delegates to PowerShell Core when available; falls back to Docker Compose.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROFILE="${1:-host}"
shift || true

export TMPDIR="${TMPDIR:-/tmp}"
export TEMP="${TEMP:-$TMPDIR}"
export TMP="${TMP:-$TMPDIR}"
export USERPROFILE="${USERPROFILE:-$HOME}"
export CIVIC_REPO_ROOT="$ROOT"

extra=()
for arg in "$@"; do
  case "$arg" in
    --light) extra+=(-LightMode) ;;
    --skip-deps) extra+=(-SkipDeps) ;;
    --install-service) extra+=(-InstallService) ;;
    *) extra+=("$arg") ;;
  esac
done

if command -v pwsh >/dev/null 2>&1; then
  exec pwsh -NoProfile -File "$ROOT/scripts/cross-platform/bootstrap.ps1" -Profile "$PROFILE" "${extra[@]}"
fi

echo "[bootstrap] pwsh not found; attempting profile=$PROFILE without PowerShell" >&2

case "$PROFILE" in
  check)
    echo "OS: $(uname -s) $(uname -m)"
    echo "Docker: $(command -v docker || echo missing)"
    echo "kubectl: $(command -v kubectl || echo missing)"
    echo "helm: $(command -v helm || echo missing)"
    ;;
  docker)
    command -v docker >/dev/null || { echo "docker required"; exit 1; }
    docker compose -f "$ROOT/docker/docker-compose.yml" --profile full up -d --build
    ;;
  kubernetes)
    command -v helm >/dev/null || { echo "helm required"; exit 1; }
    NS="${CIVIC_NAMESPACE:-civic}"
    kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS"
    helm upgrade --install civic "$ROOT/deploy/kubernetes/helm/civic-infrastructure" -n "$NS" --wait --timeout 10m
    ;;
  host)
    echo "Install PowerShell 7+ (https://aka.ms/powershell) then re-run:"
    echo "  $ROOT/scripts/cross-platform/bootstrap.sh host"
    exit 1
    ;;
  *)
    echo "Usage: $0 {host|docker|kubernetes|check} [--light] [--skip-deps] [--install-service]"
    exit 2
    ;;
esac
