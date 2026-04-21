---
name: incident-report
description: "Create a structured incident report for an active or recent incident. Documents timeline, impact, status, and immediate actions."
argument-hint: "[incident-title] [severity SEV1|SEV2|SEV3]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion
agent: sre-director
---

## /incident-report [title]

Create or update a structured incident report.

---

## Phase 1: Incident Identification

Check `production/session-logs/` for active incident files.

If existing incident found, present to user:
```
Found active incident: <filename>
```
Use AskUserQuestion: [Update existing, Create new]

If no title provided, use AskUserQuestion:
```
Incident title:
```

---

## Phase 2: Incident Data Collection

Use AskUserQuestion with tabs:

tabs:
  - Severity (SEV1/SEV2/SEV3) and current status
  - Start time (when did the incident begin?)
  - Detection time (when was it detected?)
  - Affected services/components
  - User impact (% of users affected, geographic scope)
  - Current status (investigating/mitigating/monitoring/resolved)
  - Actions taken so far

---

## Phase 3: Report Creation

Write structured incident report:

```markdown
# Incident Report: <title>

**Incident ID:** INC-YYYY-MM-DD-NNN
**Severity:** <SEV>
**Status:** <INVESTIGATING | MITIGATING | MONITORING | RESOLVED>

## Impact
- **Start Time:** YYYY-MM-DD HH:MM UTC
- **Detection Time:** YYYY-MM-DD HH:MM UTC
- **Time to Detect (TTD):** <N> minutes
- **Affected Services:** <list>
- **User Impact:** <description>
- **Business Impact:** <description>

## Current Status
<Current situation — what is working, what is not>

## Timeline
| Time (UTC) | Event |
|------------|-------|
| HH:MM | Incident started |
| HH:MM | Alert fired / detected |
| HH:MM | Incident declared |
| HH:MM | <action taken> |

## Immediate Actions
- [x] Incident declared, commander assigned
- [ ] Root cause investigation in progress
- [ ] Mitigation applied: <description>
- [ ] Stakeholders notified

## Communication Log
- HH:MM — Notified: <channels/people>

## Next Update: <time>
**Incident Commander:** <name>
**Next Steps:** <immediate next actions>
```

Write to `production/session-logs/incident-<YYYY-MM-DD-HH-MM>.md`.

---

## Phase 4: Stakeholder Notification Draft

Produce stakeholder communication template:

```
Subject: [<SEV>] <service> — <brief description>

Status: <INVESTIGATING | MITIGATED | RESOLVED>
Started: <time> UTC
Impact: <description>
Current: <what we're doing>
Next Update: <time>
```

Use AskUserQuestion:
```
Notification ready?
```
options: [Looks good, Needs revision]

---

Verdict: **COMPLETE** — incident report created.
Next Steps: Update report as situation evolves. Run `/postmortem` when resolved.
