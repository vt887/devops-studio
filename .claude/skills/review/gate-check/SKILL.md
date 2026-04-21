---
name: gate-check
description: "Manually run a specific quality gate check. Use to validate readiness before a critical operation or to check if a previous gate result is still valid."
argument-hint: "[GATE-ID: ARCH-DECISION|SEC-BASELINE|COST-ESTIMATE|ARCH-REVIEW|SRE-READY|SEC-SCAN|INCIDENT-RESOLVED]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Task, AskUserQuestion
---

## /gate-check [GATE-ID]

Manual gate validation. Use before critical operations or to verify readiness.

---

## Phase 1: Gate Selection

If GATE-ID provided, proceed to Phase 2.

Otherwise, use AskUserQuestion:
```
Which gate would you like to check?
```
options:
  - ARCH-DECISION — Architecture decision readiness
  - SEC-BASELINE — Security baseline readiness
  - COST-ESTIMATE — Cost estimation completeness
  - ARCH-REVIEW — Implementation review readiness
  - SRE-READY — SRE and monitoring readiness
  - SEC-SCAN — Security scan validation
  - INCIDENT-RESOLVED — Incident resolution verification

---

## Phase 2: Load Gate Definition

Read `.claude/gates/gate-definitions.md`.
Load the specific gate definition for the selected GATE-ID.
Read `production/review-mode.txt`.

---

## Phase 3: Pre-Check Context

Check for relevant artifacts:

**ARCH-DECISION:**
- Look for `docs/decisions/adr-*.md` (most recent)
- Check that alternatives section is populated
- Verify cost impact section exists

**SEC-BASELINE:**
- Look for `docs/decisions/security-baseline-*.md`
- Check IAM strategy section

**COST-ESTIMATE:**
- Look for `docs/decisions/cost-estimate-*.md`
- Check for monthly estimate figures

**ARCH-REVIEW:**
- Look for `terraform/` or `k8s/` directories
- Check for recent file modifications

**SRE-READY:**
- Look for `docs/decisions/slo-*.md`
- Check for `monitoring/prometheus/rules/`

**SEC-SCAN:**
- Look for recent scan reports in `production/session-logs/sec-scan-*.md`
- Check scan date (is it fresh enough?)

**INCIDENT-RESOLVED:**
- Look for `production/session-logs/incident-*.md`
- Check incident status field

---

## Phase 4: Gate Execution

Read review mode:

**solo mode:**
- Self-check all gate criteria
- Produce verdict without spawning agents

**lean mode:**
- For ARCH-DECISION, ARCH-REVIEW: spawn `architect`
- For SEC-BASELINE, SEC-SCAN: spawn `security-director`
- For SRE-READY: spawn `sre-director`
- For COST-ESTIMATE: self-check
- For INCIDENT-RESOLVED: self-check

**full mode:**
- Spawn the gate owner agent (per gate definition)
- Gate owner runs through full checklist
- Produce formal verdict

---

## Phase 5: Verdict Presentation

Present gate result:

```
Gate: <GATE-ID>
Owner: <agent>
Date: YYYY-MM-DD HH:MM UTC

Checklist:
  ✅ <criterion 1>
  ✅ <criterion 2>
  ❌ <criterion 3> — MISSING: <what's missing>
  ⚠️ <criterion 4> — CONCERN: <description>

Verdict: [GATE-ID]: APPROVE | CONCERNS [...] | REJECT [...]
```

Log gate result to `production/session-logs/YYYY-MM-DD.md`.

---

## Phase 6: Resolution (if not APPROVE)

If CONCERNS or REJECT:

Use AskUserQuestion:
```
Gate <GATE-ID> requires attention. How would you like to proceed?
```
options:
  - Address issues now (spawn relevant agent)
  - Override with justification (document reason)
  - Defer (log as known issue, continue at risk)

---

Verdict: **COMPLETE** — gate check complete.
