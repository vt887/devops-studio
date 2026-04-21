#!/usr/bin/env bash
# new-adr.sh — Scaffold a new ADR with the next sequential number.
# Usage: ./scripts/new-adr.sh "ADR Title Here"

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
DECISIONS_DIR="${REPO_ROOT}/docs/decisions"
TEMPLATE="${DECISIONS_DIR}/adr-001-template.md"

if [ $# -lt 1 ]; then
  echo "Usage: $0 \"ADR Title Here\""
  exit 1
fi

TITLE="$*"

# Derive kebab-case slug
SLUG=$(echo "${TITLE}" \
  | tr '[:upper:]' '[:lower:]' \
  | sed 's/[^a-z0-9]/-/g' \
  | sed 's/-\+/-/g' \
  | sed 's/^-//;s/-$//')

# Find highest existing ADR number (excluding the template)
HIGHEST=0
if [ -d "${DECISIONS_DIR}" ]; then
  for f in "${DECISIONS_DIR}"/adr-*.md; do
    [ -e "$f" ] || continue
    # Skip template
    [ "$(basename "$f")" = "adr-001-template.md" ] && continue
    num=$(basename "$f" | sed -E 's/^adr-([0-9]+)-.*/\1/')
    # Strip leading zeros
    num=$((10#${num}))
    if [ "${num}" -gt "${HIGHEST}" ]; then
      HIGHEST="${num}"
    fi
  done
fi

NEXT=$((HIGHEST + 1))
# If nothing exists yet, start at 002 (001 is the template)
if [ "${NEXT}" -lt 2 ]; then
  NEXT=2
fi

PADDED=$(printf "%03d" "${NEXT}")
OUTFILE="${DECISIONS_DIR}/adr-${PADDED}-${SLUG}.md"

if [ -e "${OUTFILE}" ]; then
  echo "File already exists: ${OUTFILE}"
  exit 1
fi

TODAY=$(date -u +"%Y-%m-%d")

if [ -e "${TEMPLATE}" ]; then
  # Copy template and rewrite header
  cp "${TEMPLATE}" "${OUTFILE}"
  # Cross-platform sed in-place
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "1s/.*/# ADR-${PADDED}: ${TITLE}/" "${OUTFILE}"
    sed -i '' "s/^\*\*Date:\*\* YYYY-MM-DD/\*\*Date:\*\* ${TODAY}/" "${OUTFILE}"
    sed -i '' "s/^\*\*Status:\*\* Template/\*\*Status:\*\* Proposed/" "${OUTFILE}"
  else
    sed -i "1s/.*/# ADR-${PADDED}: ${TITLE}/" "${OUTFILE}"
    sed -i "s/^\*\*Date:\*\* YYYY-MM-DD/\*\*Date:\*\* ${TODAY}/" "${OUTFILE}"
    sed -i "s/^\*\*Status:\*\* Template/\*\*Status:\*\* Proposed/" "${OUTFILE}"
  fi
else
  # Fallback minimal stub
  cat > "${OUTFILE}" << EOF
# ADR-${PADDED}: ${TITLE}

**Date:** ${TODAY}
**Status:** Proposed
**Deciders:** architect

## Context

## Decision

## Consequences

## Security Implications

## Cost Impact

## Rollback Strategy
EOF
fi

echo "Created: ${OUTFILE}"
echo
echo "Next steps:"
echo "  1. Edit ${OUTFILE} — fill in Context, Decision, Alternatives."
echo "  2. Run /gate-check ARCH-DECISION to validate."
echo "  3. Update Status from 'Proposed' to 'Accepted' after approval."
