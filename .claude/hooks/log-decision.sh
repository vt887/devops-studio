#!/usr/bin/env bash
# log-decision.sh — Runs after Write/Edit tool use.
# Logs significant file changes to the session log for audit trail.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SESSION_LOGS_DIR="${REPO_ROOT}/production/session-logs"
TODAY=$(date -u +"%Y-%m-%d")
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SESSION_LOG="${SESSION_LOGS_DIR}/${TODAY}.md"

# Get the file that was written (passed as argument or from environment)
WRITTEN_FILE="${1:-${CLAUDE_TOOL_OUTPUT:-}}"

# Only log significant files (ADRs, runbooks, security docs, session state)
if [ -z "${WRITTEN_FILE}" ]; then
  exit 0
fi

# Determine log entry based on file path
LOG_ENTRY=""

case "${WRITTEN_FILE}" in
  *docs/decisions/adr-*)
    ADR_NAME=$(basename "${WRITTEN_FILE}" .md)
    LOG_ENTRY="📋 ADR created/updated: ${ADR_NAME}"
    ;;
  *docs/decisions/security-baseline*)
    LOG_ENTRY="🔒 Security baseline updated: $(basename "${WRITTEN_FILE}")"
    ;;
  *docs/decisions/cost-estimate*)
    LOG_ENTRY="💰 Cost estimate updated: $(basename "${WRITTEN_FILE}")"
    ;;
  *docs/decisions/postmortem*)
    LOG_ENTRY="📊 Postmortem updated: $(basename "${WRITTEN_FILE}")"
    ;;
  *docs/runbooks/*)
    LOG_ENTRY="📖 Runbook updated: $(basename "${WRITTEN_FILE}")"
    ;;
  *production/session-state/active.md)
    LOG_ENTRY="🔄 Session state updated"
    ;;
  *terraform/*)
    LOG_ENTRY="🏗️  Terraform file updated: ${WRITTEN_FILE#"${REPO_ROOT}/"}"
    ;;
  *k8s/*)
    LOG_ENTRY="☸️  K8s manifest updated: ${WRITTEN_FILE#"${REPO_ROOT}/"}"
    ;;
  *)
    # Don't log routine file changes
    exit 0
    ;;
esac

# Append to session log
if [ -n "${LOG_ENTRY}" ] && [ -f "${SESSION_LOG}" ]; then
  echo "- ${NOW} — ${LOG_ENTRY}" >> "${SESSION_LOG}"
fi
