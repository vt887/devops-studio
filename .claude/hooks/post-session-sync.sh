#!/usr/bin/env bash
# post-session-sync.sh — Runs at SessionEnd.
# Copies session logs and ADRs to the Obsidian vault (if configured).
# Silent no-op if OBSIDIAN_VAULT env var is not set.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Vault path from env var (configured in .claude/settings.json or user env)
VAULT="${OBSIDIAN_VAULT:-}"

if [ -z "${VAULT}" ]; then
  # No vault configured — nothing to sync, silent exit
  exit 0
fi

if [ ! -d "${VAULT}" ]; then
  echo "[devops-studio] OBSIDIAN_VAULT set but directory does not exist: ${VAULT}"
  echo "[devops-studio] Skipping sync. Create the directory or unset OBSIDIAN_VAULT."
  exit 0
fi

# Target subdirectories inside vault
VAULT_SESSIONS="${VAULT}/sessions"
VAULT_DECISIONS="${VAULT}/decisions"
VAULT_RETROS="${VAULT}/retrospectives"
VAULT_RUNBOOKS="${VAULT}/runbooks"

mkdir -p "${VAULT_SESSIONS}" "${VAULT_DECISIONS}" "${VAULT_RETROS}" "${VAULT_RUNBOOKS}"

SYNCED=0

# Sync session logs
if [ -d "${REPO_ROOT}/production/session-logs" ]; then
  for f in "${REPO_ROOT}/production/session-logs"/*.md; do
    [ -e "$f" ] || continue
    [ "$(basename "$f")" = ".gitkeep" ] && continue
    cp -f "$f" "${VAULT_SESSIONS}/"
    SYNCED=$((SYNCED + 1))
  done
fi

# Sync ADRs and decision documents
if [ -d "${REPO_ROOT}/docs/decisions" ]; then
  for f in "${REPO_ROOT}/docs/decisions"/*.md; do
    [ -e "$f" ] || continue
    cp -f "$f" "${VAULT_DECISIONS}/"
    SYNCED=$((SYNCED + 1))
  done
fi

# Sync retrospectives
if [ -d "${REPO_ROOT}/docs/retrospectives" ]; then
  for f in "${REPO_ROOT}/docs/retrospectives"/*.md; do
    [ -e "$f" ] || continue
    cp -f "$f" "${VAULT_RETROS}/"
    SYNCED=$((SYNCED + 1))
  done
fi

# Sync runbooks
if [ -d "${REPO_ROOT}/docs/runbooks" ]; then
  for f in "${REPO_ROOT}/docs/runbooks"/*.md; do
    [ -e "$f" ] || continue
    cp -f "$f" "${VAULT_RUNBOOKS}/"
    SYNCED=$((SYNCED + 1))
  done
fi

# Generate/update vault index
cat > "${VAULT}/00-index.md" << EOF
# DevOps Studio Knowledge Base

**Last sync:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")
**Source repo:** ${REPO_ROOT}

## Sections

- [[sessions]] — session logs (audit trail of every workflow run)
- [[decisions]] — ADRs, security baselines, cost estimates, postmortems
- [[retrospectives]] — what worked, what did not
- [[runbooks]] — operational procedures

## Recent Sessions

$(ls -t "${VAULT_SESSIONS}"/*.md 2>/dev/null | head -10 | while read f; do
  echo "- [[$(basename "${f}" .md)]]"
done)

## Recent Decisions

$(ls -t "${VAULT_DECISIONS}"/*.md 2>/dev/null | head -10 | while read f; do
  echo "- [[$(basename "${f}" .md)]]"
done)
EOF

echo "[devops-studio] Obsidian sync: ${SYNCED} files → ${VAULT}"
