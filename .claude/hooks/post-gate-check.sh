#!/usr/bin/env bash
# post-gate-check.sh — Runs after Task tool use (agent spawning).
# Logs gate check results to session log when agents produce gate verdicts.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SESSION_LOGS_DIR="${REPO_ROOT}/production/session-logs"
TODAY=$(date -u +"%Y-%m-%d")
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SESSION_LOG="${SESSION_LOGS_DIR}/${TODAY}.md"

# Get agent output (passed from tool output or environment)
AGENT_OUTPUT="${CLAUDE_TOOL_OUTPUT:-${1:-}}"

if [ -z "${AGENT_OUTPUT}" ]; then
  exit 0
fi

# Look for gate verdict patterns in agent output
GATE_VERDICT=""

# Pattern: [GATE-ID]: APPROVE | CONCERNS [...] | REJECT [...]
if echo "${AGENT_OUTPUT}" | grep -qE "\[(ARCH-DECISION|ARCH-REVIEW|SEC-BASELINE|SEC-SCAN|SEC-REVIEW|SRE-READY|COST-ESTIMATE|INCIDENT-RESOLVED)\]:"; then
  GATE_VERDICT=$(echo "${AGENT_OUTPUT}" | grep -oE "\[(ARCH-DECISION|ARCH-REVIEW|SEC-BASELINE|SEC-SCAN|SEC-REVIEW|SRE-READY|COST-ESTIMATE|INCIDENT-RESOLVED)\]:\s*(APPROVE|CONCERNS|REJECT)[^$]*" | head -1)
fi

# Log gate verdict if found
if [ -n "${GATE_VERDICT}" ] && [ -f "${SESSION_LOG}" ]; then
  # Determine emoji based on verdict
  if echo "${GATE_VERDICT}" | grep -q "APPROVE"; then
    ICON="✅"
  elif echo "${GATE_VERDICT}" | grep -q "CONCERNS"; then
    ICON="⚠️"
  else
    ICON="❌"
  fi

  echo "- ${NOW} — ${ICON} Gate verdict: ${GATE_VERDICT}" >> "${SESSION_LOG}"
  echo "[devops-studio] Gate result logged: ${GATE_VERDICT}"
fi

exit 0
