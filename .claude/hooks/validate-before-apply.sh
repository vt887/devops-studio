#!/usr/bin/env bash
# validate-before-apply.sh — Runs before Bash tool use.
# Guards against dangerous commands being run without gates in full/lean mode.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
REVIEW_MODE_FILE="${REPO_ROOT}/production/review-mode.txt"

# Get the command that is about to run
COMMAND="${CLAUDE_TOOL_INPUT:-${1:-}}"

if [ -z "${COMMAND}" ]; then
  exit 0
fi

REVIEW_MODE=$(cat "${REVIEW_MODE_FILE}" 2>/dev/null | tr -d '[:space:]' || echo "full")

# In solo mode, skip validation
if [ "${REVIEW_MODE}" = "solo" ]; then
  exit 0
fi

# Check for dangerous infrastructure commands
DANGEROUS=false
REASON=""

# Terraform apply without explicit approval indicator
if echo "${COMMAND}" | grep -qE "terraform\s+apply" && ! echo "${COMMAND}" | grep -q "\-auto-approve"; then
  DANGEROUS=true
  REASON="terraform apply requires explicit gate approval (ARCH-REVIEW) and user confirmation"
fi

# Production kubectl commands
if echo "${COMMAND}" | grep -qE "kubectl\s+(delete|apply|patch|scale|rollout)" && \
   echo "${COMMAND}" | grep -q "prod\|production"; then
  DANGEROUS=true
  REASON="kubectl write operations on production require gate approval"
fi

# Direct secret operations
if echo "${COMMAND}" | grep -qE "(aws|gcloud|az)\s+secretsmanager\s+(put|create|delete|update)"; then
  DANGEROUS=true
  REASON="secrets management operations require security-director approval"
fi

# Warn on dangerous commands
if [ "${DANGEROUS}" = "true" ]; then
  echo "[devops-studio] ⚠️  VALIDATION WARNING: ${REASON}"
  echo "[devops-studio] Review mode: ${REVIEW_MODE} — Ensure gate has been checked before proceeding."
  # We warn but don't block — the gate check is the primary control
fi

exit 0
