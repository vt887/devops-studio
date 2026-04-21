#!/usr/bin/env bash
# pre-compact.sh — Runs before Claude compacts the conversation context.
# Saves critical session state so it can be restored after compaction.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SESSION_STATE="${REPO_ROOT}/production/session-state/active.md"
SESSION_LOGS_DIR="${REPO_ROOT}/production/session-logs"
TODAY=$(date -u +"%Y-%m-%d")
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SESSION_LOG="${SESSION_LOGS_DIR}/${TODAY}.md"

echo "[devops-studio] Pre-compact: saving session state..."

# Append compaction notice to session log
if [ -f "${SESSION_LOG}" ]; then
  echo "- ${NOW} — Context compaction triggered (state saved)" >> "${SESSION_LOG}"
fi

# Ensure active.md has a compaction notice
if [ -f "${SESSION_STATE}" ]; then
  # Add compaction marker if not already present
  if ! grep -q "COMPACTED" "${SESSION_STATE}"; then
    echo "" >> "${SESSION_STATE}"
    echo "## ⚠️ Context Compacted at ${NOW}" >> "${SESSION_STATE}"
    echo "Resume by reading this file and continuing from the last recorded step." >> "${SESSION_STATE}"
  fi
fi

echo "[devops-studio] Pre-compact: state saved to ${SESSION_STATE}"
