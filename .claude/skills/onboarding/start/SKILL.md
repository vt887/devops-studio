---
name: start
description: "Onboarding skill that assesses the current DevOps Studio session context, detects existing state, and guides the user to the right workflow."
argument-hint: "[--reset]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, AskUserQuestion
context: |
  !cat production/review-mode.txt 2>/dev/null || echo "full"
  !cat production/session-state/active.md 2>/dev/null || echo "no active session"
  !ls docs/decisions/ 2>/dev/null | head -20
---

## /start

Entry point for DevOps Studio. Run this at the beginning of every session.

---

## Phase 1: Load Session State

Read `production/session-state/active.md`.

- **If file exists and has content**: Present the active context to the user.
  ```
  📋 Active Session Found:
  <content of active.md>
  
  Resume this session? (yes/no)
  ```
  Use AskUserQuestion with:
  - tabs: [Resume, Start Fresh]

- **If file is empty or does not exist**: Proceed to Phase 2.
- **If `--reset` flag provided**: Clear active.md and proceed to Phase 2.

---

## Phase 2: Read Review Mode

Read `production/review-mode.txt`.

If file does not exist, write `full` to it and note: "Review mode defaulted to: full"

Display:
```
⚙️ Review Mode: <mode>
   full  = all gates active, directors spawn for validation
   lean  = only critical gates (ARCH-DECISION, SEC-BASELINE)
   solo  = no gates, single-agent execution
```

---

## Phase 3: Context Detection

Check for existing project artifacts:
- `terraform/` directory → Terraform project detected
- `k8s/` directory → Kubernetes project detected
- `docs/decisions/*.md` → ADRs found (count them)
- `production/session-logs/` → Previous session logs exist

Present detection summary:
```
🔍 Project Context Detected:
  - Infrastructure: [Terraform | Kubernetes | None detected]
  - ADRs: [N documents found | None]
  - Previous sessions: [N logs found | First session]
```

---

## Phase 4: Workflow Selection

Present available workflows to the user via AskUserQuestion:

```
🚀 DevOps Studio — What would you like to do?

Design & Planning:
  /brainstorm              — Explore ideas before committing to architecture
  /architecture-decision   — Make a formal architecture decision (creates ADR)
  /design-review           — Review an existing design or proposal

Team Workflows (multi-agent):
  /team-new-env            — Deploy a new environment from scratch
  /team-migration          — Migrate application between cloud providers
  /team-incident           — Respond to a production incident
  /team-security-audit     — Full security audit of infrastructure

Review & Gates:
  /gate-check              — Run a specific quality gate manually
  /cost-review             — Analyze and optimize cloud costs
  /security-review         — Security review of a specific component

Production Operations:
  /incident-report         — Document an active incident
  /postmortem              — Run a post-incident review
  /adr                     — Create a standalone ADR
  /runbook                 — Generate an operational runbook

Or describe your task in plain language.
```

options:
  - /team-new-env
  - /team-migration
  - /team-incident
  - /team-security-audit
  - /brainstorm
  - /architecture-decision
  - other (describe)

---

## Phase 5: Initialize Session Log

Write to `production/session-logs/YYYY-MM-DD.md` (use current date):

```markdown
# Session Log — YYYY-MM-DD

**Started:** HH:MM UTC
**Review Mode:** <mode>
**Context:** <detected context>

## Events
```

Update `production/session-state/active.md` with:
```markdown
# Active Session

**Date:** YYYY-MM-DD
**Review Mode:** <mode>
**Current Skill:** /start → <selected workflow>
**Status:** In Progress
```

---

Verdict: **COMPLETE** — session initialized, routing to selected workflow.
