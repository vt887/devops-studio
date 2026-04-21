---
name: design-review
description: "Review an existing design, proposal, or implementation plan. Spawns relevant directors to evaluate quality, security, reliability, and cost. Produces a structured verdict with action items."
argument-hint: "[path-to-design-doc] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Task, AskUserQuestion
agent: architect
---

## /design-review [path]

Structured design review workflow. Use to validate any design before implementation.

---

## Phase 1: Document Loading

If path provided → read the specified document.
If no path → use AskUserQuestion:
```
What would you like to review?
```
options:
  - An ADR (select from docs/decisions/)
  - An implementation plan (select from docs/runbooks/)
  - Terraform configuration (specify path)
  - Kubernetes manifests (specify path)
  - CI/CD pipeline (specify path)
  - Paste the design inline

Read `production/review-mode.txt`

---

## Phase 2: Review Scope Definition

Use AskUserQuestion:
```
Which aspects should this review focus on?
```
tabs (multi-select):
  - Architecture correctness
  - Security posture
  - Reliability and SLO impact
  - Cost efficiency
  - Operational readiness
  - Compliance requirements

---

## Phase 3: Director Reviews

Read review mode:

**solo mode:**
- Single-agent review covering all selected aspects
- No director spawning

**lean mode:**
- Spawn `architect` for architecture review
- Spawn `security-director` for security review (always in lean)

**full mode:**
- Spawn `architect` via Task — architecture review
- Spawn `security-director` via Task — security review
- Spawn `sre-director` via Task — reliability review
- Issue all three Task calls simultaneously

Each reviewer produces:
- **APPROVE** — no concerns
- **APPROVE WITH CONCERNS** — issues documented, can proceed with caution
- **REJECT** — blocking issues that must be resolved

---

## Phase 4: Consolidated Review Report

Compile results into structured report:

```markdown
# Design Review Report

**Document:** <title>
**Date:** YYYY-MM-DD
**Review Mode:** <mode>

## Architecture Review (architect)
Verdict: <APPROVE | CONCERNS | REJECT>
<findings>

## Security Review (security-director)
Verdict: <APPROVE | CONCERNS | REJECT>
<findings>

## Reliability Review (sre-director)
Verdict: <APPROVE | CONCERNS | REJECT>
<findings>

## Overall Verdict
<APPROVED | APPROVED WITH CONDITIONS | BLOCKED>

## Action Items
| # | Issue | Severity | Owner | Status |
|---|-------|----------|-------|--------|
```

---

## Phase 5: Resolution Path

If any REJECT:
- Present blocking issues
- Use AskUserQuestion:
  ```
  How would you like to resolve the blocking issues?
  ```
  options: [Revise the design now, Delegate to specialist, Schedule for later, Override with justification]

If APPROVE WITH CONCERNS:
- Document concerns in ADR or session log
- Use AskUserQuestion: [Proceed with concerns documented, Resolve first]

Log review to `production/session-logs/YYYY-MM-DD.md`.

---

Verdict: **COMPLETE** — review report produced.
Next Steps: Address action items, then proceed to implementation.
