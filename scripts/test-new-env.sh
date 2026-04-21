#!/usr/bin/env bash
# test-new-env.sh — Dry-run validator for the /team-new-env workflow.
# Verifies that all expected framework pieces exist and are reachable.
# Does NOT actually provision infrastructure — only checks the scaffolding.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "${REPO_ROOT}"

echo "=== DevOps Studio — /team-new-env Dry Run ==="
echo

PASS=0
FAIL=0

check() {
  local label="$1"
  local path="$2"
  if [ -e "${path}" ]; then
    echo "  [OK]   ${label}: ${path}"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] ${label}: ${path} — missing"
    FAIL=$((FAIL + 1))
  fi
}

echo "-- 1. Entry point and routing --"
check "CLAUDE.md" "CLAUDE.md"
check "settings.json" ".claude/settings.json"
echo

echo "-- 2. Agents required for /team-new-env --"
check "architect" ".claude/agents/directors/architect.md"
check "security-director" ".claude/agents/directors/security-director.md"
check "sre-director" ".claude/agents/directors/sre-director.md"
check "terraform-spec" ".claude/agents/specialists/terraform-spec.md"
check "k8s-spec" ".claude/agents/specialists/k8s-spec.md"
check "cicd-spec" ".claude/agents/specialists/cicd-spec.md"
check "gitops-spec" ".claude/agents/specialists/gitops-spec.md"
check "monitoring-spec" ".claude/agents/specialists/monitoring-spec.md"
check "cost-spec" ".claude/agents/specialists/cost-spec.md"
check "security-scanner" ".claude/agents/specialists/security-scanner.md"
echo

echo "-- 3. Skill --"
check "team-new-env SKILL" ".claude/skills/team/team-new-env/SKILL.md"
check "onboarding start" ".claude/skills/onboarding/start/SKILL.md"
echo

echo "-- 4. Gates required by the workflow --"
check "gate-definitions" ".claude/gates/gate-definitions.md"
check "verdict-format" ".claude/gates/verdict-format.md"
for gate in ARCH-DECISION SEC-BASELINE COST-ESTIMATE ARCH-REVIEW SRE-READY SEC-SCAN; do
  if grep -q "Gate ID:.*${gate}" ".claude/gates/gate-definitions.md" 2>/dev/null || \
     grep -q "^## ${gate}" ".claude/gates/gate-definitions.md" 2>/dev/null; then
    echo "  [OK]   gate defined: ${gate}"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] gate missing: ${gate}"
    FAIL=$((FAIL + 1))
  fi
done
echo

echo "-- 5. Rules files --"
for domain in terraform kubernetes cicd security gitops; do
  check "rules/${domain}" ".claude/rules/${domain}/rules.md"
done
echo

echo "-- 6. Hooks --"
for hook in session-start.sh session-detect-context.sh pre-compact.sh log-decision.sh validate-before-apply.sh post-gate-check.sh; do
  check "hook: ${hook}" ".claude/hooks/${hook}"
  if [ -e ".claude/hooks/${hook}" ] && [ ! -x ".claude/hooks/${hook}" ]; then
    echo "  [WARN] ${hook} is not executable"
  fi
done
echo

echo "-- 7. Runtime state --"
check "review-mode.txt" "production/review-mode.txt"
check "session-state/active.md" "production/session-state/active.md"
check "session-logs dir" "production/session-logs"
echo

echo "-- 8. ADR template --"
check "adr-001-template" "docs/decisions/adr-001-template.md"
echo

echo "-- 9. Agent frontmatter sanity --"
for agent in .claude/agents/directors/*.md .claude/agents/specialists/*.md; do
  [ -e "$agent" ] || continue
  name=$(basename "$agent" .md)
  if ! head -2 "$agent" | grep -q "^---"; then
    echo "  [FAIL] ${name}: missing frontmatter"
    FAIL=$((FAIL + 1))
    continue
  fi
  for field in name description tools model tier; do
    if ! awk '/^---$/{c++} c==1' "$agent" | grep -q "^${field}:"; then
      echo "  [FAIL] ${name}: missing field '${field}'"
      FAIL=$((FAIL + 1))
    fi
  done
  echo "  [OK]   ${name}: frontmatter valid"
  PASS=$((PASS + 1))
done
echo

echo "-- 10. Skill frontmatter sanity --"
for skill in $(find .claude/skills -name "SKILL.md"); do
  name=$(basename "$(dirname "$skill")")
  if ! head -2 "$skill" | grep -q "^---"; then
    echo "  [FAIL] skill ${name}: missing frontmatter"
    FAIL=$((FAIL + 1))
    continue
  fi
  for field in name description user-invocable allowed-tools; do
    if ! awk '/^---$/{c++} c==1' "$skill" | grep -q "^${field}:"; then
      echo "  [FAIL] skill ${name}: missing field '${field}'"
      FAIL=$((FAIL + 1))
    fi
  done
  echo "  [OK]   skill ${name}: frontmatter valid"
  PASS=$((PASS + 1))
done
echo

echo "=== Summary ==="
echo "  Pass: ${PASS}"
echo "  Fail: ${FAIL}"
echo

if [ "${FAIL}" -gt 0 ]; then
  echo "Dry run FAILED — fix missing pieces before invoking /team-new-env"
  exit 1
fi

echo "Dry run PASSED — /team-new-env is structurally ready to invoke"
echo "Next step: set review mode in production/review-mode.txt and run /start"
exit 0
