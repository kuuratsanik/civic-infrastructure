# Multi-arch civic-infrastructure runtime (linux/amd64 + linux/arm64)
# PowerShell Core + portable orchestrator. Windows ceremonies are not included.
FROM mcr.microsoft.com/powershell:7.4-ubuntu-22.04

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq \
 && apt-get install -y -qq --no-install-recommends ca-certificates curl git tini \
 && rm -rf /var/lib/apt/lists/*

# Non-root user
RUN groupadd -g 10001 civic \
 && useradd -u 10001 -g civic -m -s /bin/bash civic

WORKDIR /civic
COPY --chown=civic:civic platform/ /civic/platform/
COPY --chown=civic:civic configs/platform/ /civic/configs/platform/
COPY --chown=civic:civic scripts/cross-platform/ /civic/scripts/cross-platform/
COPY --chown=civic:civic agents/modules/ /civic/agents/modules/
COPY --chown=civic:civic council/ /civic/council/
COPY --chown=civic:civic civic.ps1 civic /civic/

RUN mkdir -p /civic/var/logs /civic/var/state /civic/var/bus /civic/var/evidence /civic/var/config \
 && chown -R civic:civic /civic/var

ENV CIVIC_REPO_ROOT=/civic \
    CIVIC_DATA_ROOT=/civic/var \
    CIVIC_RUNTIME=docker \
    TEMP=/tmp \
    TMP=/tmp \
    USERPROFILE=/home/civic \
    HOME=/home/civic \
    POWERSHELL_TELEMETRY_OPTOUT=1

USER civic
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD pwsh -NoProfile -Command "Test-Path /civic/var/state/orchestrator-state.json"

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["pwsh", "-NoProfile", "-File", "/civic/scripts/cross-platform/Start-CivicOrchestrator.ps1", "-RepoRoot", "/civic"]
