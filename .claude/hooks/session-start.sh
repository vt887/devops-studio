#!/usr/bin/env bash
# session-start.sh — Runs at the start of every DevOps Studio session
# Initializes session state, checks review mode, and logs session start.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SESSION_STATE_DIR="${REPO_ROOT}/production/session-state"
SESSION_LOGS_DIR="${REPO_ROOT}/production/session-logs"
REVIEW_MODE_FILE="${REPO_ROOT}/production/review-mode.txt"

# Ensure production directories exist
mkdir -p "${SESSION_STATE_DIR}"
mkdir -p "${SESSION_LOGS_DIR}"

# Initialize review mode if not set
if [ ! -f "${REVIEW_MODE_FILE}" ]; then
  echo "full" > "${REVIEW_MODE_FILE}"
  echo "[devops-studio] Review mode initialized to: full"
fi

REVIEW_MODE=$(cat "${REVIEW_MODE_FILE}" | tr -d '[:space:]')
TODAY=$(date -u +"%Y-%m-%d")
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SESSION_LOG="${SESSION_LOGS_DIR}/${TODAY}.md"

# Initialize today's session log if it doesn't exist
if [ ! -f "${SESSION_LOG}" ]; then
  cat > "${SESSION_LOG}" << EOF
# Session Log — ${TODAY}

**Started:** ${NOW}
**Review Mode:** ${REVIEW_MODE}

## Events

EOF
  echo "[devops-studio] Session log created: ${SESSION_LOG}"
fi

# Append session start event to log
echo "- ${NOW} — Session started (review mode: ${REVIEW_MODE})" >> "${SESSION_LOG}"

echo "[devops-studio] Session started | mode=${REVIEW_MODE} | log=${SESSION_LOG}"
