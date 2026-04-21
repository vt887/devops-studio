#!/usr/bin/env bash
# session-detect-context.sh — Detects the current project context at session start.
# Reports detected infrastructure components to guide agent routing.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

echo "[devops-studio] Detecting project context..."

CONTEXT_ITEMS=()

# Detect infrastructure components
if [ -d "${REPO_ROOT}/terraform" ]; then
  TF_COUNT=$(find "${REPO_ROOT}/terraform" -name "*.tf" 2>/dev/null | wc -l | tr -d ' ')
  CONTEXT_ITEMS+=("terraform:${TF_COUNT} .tf files")
fi

if [ -d "${REPO_ROOT}/k8s" ]; then
  K8S_COUNT=$(find "${REPO_ROOT}/k8s" -name "*.yaml" -o -name "*.yml" 2>/dev/null | wc -l | tr -d ' ')
  CONTEXT_ITEMS+=("kubernetes:${K8S_COUNT} manifests")
fi

if [ -d "${REPO_ROOT}/helm" ]; then
  CONTEXT_ITEMS+=("helm:charts found")
fi

if [ -d "${REPO_ROOT}/gitops" ]; then
  CONTEXT_ITEMS+=("gitops:configured")
fi

if [ -d "${REPO_ROOT}/.github/workflows" ]; then
  WF_COUNT=$(find "${REPO_ROOT}/.github/workflows" -name "*.yml" -o -name "*.yaml" 2>/dev/null | wc -l | tr -d ' ')
  CONTEXT_ITEMS+=("github-actions:${WF_COUNT} workflows")
fi

if [ -d "${REPO_ROOT}/monitoring" ]; then
  CONTEXT_ITEMS+=("monitoring:configured")
fi

# Count ADRs
ADR_COUNT=$(find "${REPO_ROOT}/docs/decisions" -name "adr-*.md" 2>/dev/null | wc -l | tr -d ' ')
if [ "${ADR_COUNT}" -gt 0 ]; then
  CONTEXT_ITEMS+=("adrs:${ADR_COUNT} decisions documented")
fi

# Check for active session state
if [ -f "${REPO_ROOT}/production/session-state/active.md" ] && [ -s "${REPO_ROOT}/production/session-state/active.md" ]; then
  CONTEXT_ITEMS+=("session:active state found")
fi

# Output detection results
if [ ${#CONTEXT_ITEMS[@]} -eq 0 ]; then
  echo "[devops-studio] Context: greenfield project (no infrastructure detected)"
else
  echo "[devops-studio] Context detected:"
  for item in "${CONTEXT_ITEMS[@]}"; do
    KEY="${item%%:*}"
    VALUE="${item#*:}"
    echo "  - ${KEY}: ${VALUE}"
  done
fi

# Write context summary to session state
SESSION_STATE="${REPO_ROOT}/production/session-state/active.md"
if [ ! -f "${SESSION_STATE}" ]; then
  NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  cat > "${SESSION_STATE}" << EOF
# Active Session

**Date:** $(date -u +"%Y-%m-%d")
**Started:** ${NOW}
**Review Mode:** $(cat "${REPO_ROOT}/production/review-mode.txt" 2>/dev/null || echo "full")
**Current Skill:** none
**Status:** Ready

## Detected Context
EOF
  for item in "${CONTEXT_ITEMS[@]}"; do
    echo "- ${item}" >> "${SESSION_STATE}"
  done
fi
