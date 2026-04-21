---
name: postmortem
description: "Run a structured blameless post-incident review. Reviews the incident timeline, identifies root causes, documents action items. Spawns sre-director to lead the process."
argument-hint: "[incident-id or date]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Task, AskUserQuestion
agent: sre-director
---

## /postmortem [incident-id]

Blameless post-incident review workflow.

---

## Phase 1: Incident Loading

If incident-id or date provided:
- Look for `production/session-logs/incident-<id>.md`
- Load incident timeline and data

If not found or not provided, use AskUserQuestion:
```
Which incident are you reviewing?
```
options: [list available incident files from production/session-logs/]

---

## Phase 2: Context Gathering

Spawn `sre-director` via Task (postmortem facilitator).

SRE director uses AskUserQuestion to gather:

tabs:
  - Who attended the postmortem?
  - What was the actual impact (users, revenue, duration)?
  - What went well during the response?
  - What went poorly during the response?
  - Were there any near-misses that didn't make things worse?

---

## Phase 3: Timeline Reconstruction

SRE director facilitates timeline reconstruction:

```
Complete Timeline:
| Time | Event | Who |
|------|-------|-----|
| HH:MM | <what happened> | <system/person> |
```

Use AskUserQuestion to validate the timeline is complete.

---

## Phase 4: Root Cause Analysis

Spawn `sre-director` via Task.

Apply **5 Whys** methodology:
- Why did the incident occur?
  - Why? → <answer>
    - Why? → <answer>
      - Why? → <answer>
        - Why? → <answer>
          - Why? → ROOT CAUSE

Also identify:
- **Contributing factors** — conditions that made it worse
- **Detection gap** — why wasn't it caught sooner?
- **Response gap** — why did it take longer than ideal to mitigate?

---

## Phase 5: Blameless Review

SRE director facilitates:

Key questions (never about people, always about systems):
1. How could the system have prevented this automatically?
2. What monitoring/alerting was missing?
3. What documentation/runbook was missing or unclear?
4. Was the on-call process followed? If not, why?
5. Did the tooling support fast response?

---

## Phase 6: Action Items

Generate action items with format:

```markdown
| # | Action | Type | Owner | Due | Priority |
|---|--------|------|-------|-----|----------|
| 1 | <specific action> | Preventive/Detective/Mitigating | <role> | YYYY-MM-DD | P1/P2/P3 |
```

Types:
- **Preventive** — stop this from happening again
- **Detective** — detect it faster if it does happen
- **Mitigating** — reduce impact if it does happen

Use AskUserQuestion: [Action items complete and assigned?]

---

## Phase 7: Postmortem Document

Write postmortem to `docs/decisions/postmortem-YYYY-MM-DD-<service>.md`:

```markdown
# Postmortem: <incident title>

**Date of Incident:** YYYY-MM-DD
**Postmortem Date:** YYYY-MM-DD
**Severity:** SEV<N>
**Duration:** <N> hours/minutes
**Author:** sre-director
**Status:** COMPLETE

## Executive Summary
<2-3 sentence summary of what happened, impact, and key fix>

## Impact
- Users affected: <N> or <percentage>
- Duration: <N> minutes
- Services affected: <list>
- Business impact: <description>

## Timeline
| Time UTC | Event |
|----------|-------|
...

## Root Cause
<Clear, specific root cause statement — what was the technical root cause>

## Contributing Factors
- <factor 1>
- <factor 2>

## What Went Well
- <positive 1>
- <positive 2>

## What Went Poorly
- <issue 1>
- <issue 2>

## Action Items
| # | Action | Type | Owner | Due | Priority |
|---|--------|------|-------|-----|----------|

## Lessons Learned
<key takeaways for the organization>
```

---

## Phase 8: Follow-up

Gate: INCIDENT-RESOLVED (sre-director)

Use AskUserQuestion:
```
Postmortem complete. Next steps:
```
options:
  - Assign action items in tracking system
  - Share with broader team
  - Schedule 30-day action item review
  - All of the above

Log to `production/session-logs/YYYY-MM-DD.md`.

---

Verdict: **COMPLETE** — postmortem documented.
Next Steps: Track action items to completion, review at 30-day mark.
