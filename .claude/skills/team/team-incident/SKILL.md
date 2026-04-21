---
name: team-incident
description: "Production incident response workflow. Immediate triage, investigation, mitigation, and communication coordination. Roles: sre-director, k8s-spec for rollback, security-director for security incidents."
argument-hint: "[incident-description] [severity SEV1|SEV2|SEV3]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Task, AskUserQuestion
agent: sre-director
context: |
  !cat production/review-mode.txt 2>/dev/null || echo "full"
  !ls production/session-logs/incident-*.md 2>/dev/null
---

## /team-incident

Production incident response workflow. Time-critical — minimize questions, maximize speed.

Roles: sre-director (lead), k8s-spec (rollback), security-director (if security event), monitoring-spec (observability)

---

## Phase 1: Incident Declaration

Use AskUserQuestion:

```
🚨 INCIDENT DETECTED — Quick triage:
```

tabs:
  - What is broken? (service/component name)
  - Severity (SEV1=critical/SEV2=major/SEV3=minor)
  - When did it start? (approximate time)
  - Current impact (users affected, revenue impact)
  - What changed recently? (deployments, config changes)

Create incident record immediately:
Write to `production/session-logs/incident-<YYYY-MM-DD-HH-MM>.md`:

```markdown
# Incident: <title>
**Severity:** <SEV>
**Declared:** <timestamp>
**Incident Commander:** <user>
**Status:** INVESTIGATING

## Timeline
- HH:MM — Incident declared
```

---

## Phase 2: Immediate Assessment

Spawn `sre-director` via Task (Incident Commander role).

SRE director:
- Reviews available monitoring data and alerts
- Confirms severity and blast radius
- Determines if this is a security incident (route to security-director if yes)
- Establishes incident communication channel
- Assigns investigation roles

Use AskUserQuestion:
```
Is this a security incident (unauthorized access, data breach, attack)?
```
options: [Yes — escalate to security-director, No — SRE-led response, Unsure — investigate both]

---

## Phase 3: Parallel Investigation

For SEV1/SEV2 — spawn simultaneously:
- `sre-director` via Task — review SLO burn rate, error rates, dependency graph
- `k8s-spec` via Task — review recent deployments, pod health, node status

For security incidents — also spawn:
- `security-director` via Task — threat assessment

Update incident timeline after each agent reports.

---

## Phase 4: Mitigation Options

SRE director presents mitigation options ranked by speed and confidence:

```
Mitigation Options (fastest first):
1. ROLLBACK — revert last deployment (if deployment caused incident)
   Confidence: HIGH | Time: 5-10 min | Risk: LOW
   
2. SCALE OUT — add capacity (if resource exhaustion)
   Confidence: MEDIUM | Time: 2-5 min | Risk: LOW
   
3. TRAFFIC SHIFT — route to healthy region/cluster
   Confidence: HIGH | Time: 1-3 min | Risk: MEDIUM
   
4. FEATURE FLAG — disable problematic feature
   Confidence: HIGH | Time: 1-2 min | Risk: LOW (if flag exists)
   
5. CIRCUIT BREAKER — enable circuit breaker for failing service
   Confidence: MEDIUM | Time: 5-15 min | Risk: MEDIUM
```

Use AskUserQuestion:
```
Select mitigation approach:
```
options: [list mitigation options + "Investigate more before acting"]

---

## Phase 5: Mitigation Execution

Based on selected mitigation:

**Rollback path:**
- Spawn `k8s-spec` via Task to prepare rollback manifest/command
- Present rollback command for user confirmation before execution
- Execute only after explicit user approval

**Scale out path:**
- Spawn `k8s-spec` via Task to adjust HPA/replica count
- Present change for confirmation

**Traffic shift:**
- Spawn `k8s-spec` via Task to update ingress/service configuration

Update incident timeline with mitigation action.

Gate: none (speed is priority in incident response)

---

## Phase 6: Verification

After mitigation applied:

Spawn `sre-director` via Task to verify:
- Error rate returning to normal
- SLO burn rate decreasing
- User impact resolving

Use AskUserQuestion:
```
Is the mitigation working?
```
options: [Yes — incident resolving, No — escalate, Partial — try additional mitigation]

Update incident status to MITIGATED or ESCALATED.

---

## Phase 7: Communication

SRE director drafts stakeholder communication:

```
Subject: [SEV<N>] <service> incident — <status>

Impact: <what was/is affected>
Start Time: <HH:MM UTC>
Current Status: <INVESTIGATING | MITIGATED | RESOLVED>
Next Update: <HH:MM UTC>

<brief description of what happened and what we're doing>
```

Use AskUserQuestion:
```
Communication ready for sending?
```
options: [Send as-is, Revise first, Skip (internal only)]

---

## Phase 8: Resolution

When incident is resolved:

Update incident record with:
- Resolution time
- Total duration
- Root cause (preliminary)
- Mitigation applied

Gate: INCIDENT-RESOLVED (sre-director)

Write final incident summary to `production/session-logs/incident-<YYYY-MM-DD>.md`.

Use AskUserQuestion:
```
Incident resolved. Next steps?
```
options:
  - Run /postmortem now
  - Schedule postmortem for later
  - Skip (SEV3 only)

---

Verdict: **COMPLETE** — incident mitigated and documented.
Next Steps: Run `/postmortem` within 5 business days.
