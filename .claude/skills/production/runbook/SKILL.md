---
name: runbook
description: "Generate an operational runbook for a service, process, or procedure. Spawns sre-director and relevant specialists to document operational procedures."
argument-hint: "[service-name] [type: operations|deployment|incident|backup|scaling]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Task, AskUserQuestion
agent: sre-director
---

## /runbook [service] [type]

Generate structured operational runbook.

---

## Phase 1: Runbook Scope

If service and type not provided, use AskUserQuestion:

```
What runbook are you creating?
```

tabs:
  - Service/Component Name
  - Runbook Type:
    - Operations — daily operational procedures
    - Deployment — how to deploy this service
    - Incident — how to respond to incidents for this service
    - Backup & Recovery — backup and restore procedures
    - Scaling — how to scale this service
    - Migration — how to migrate/upgrade this service
  - Target Audience (on-call engineer / platform team / all)
  - Automation Level (fully automated / semi-automated / manual)

---

## Phase 2: Context Loading

Check for existing documentation:
- ADRs related to this service in `docs/decisions/`
- Kubernetes manifests in `k8s/`
- Terraform resources in `terraform/`
- Monitoring configs in `monitoring/`
- Existing runbooks in `docs/runbooks/`

---

## Phase 3: Runbook Generation

Spawn `sre-director` via Task.

Spawn relevant specialists as needed:
- `k8s-spec` — for Kubernetes operational procedures
- `terraform-spec` — for infrastructure procedures
- `monitoring-spec` — for monitoring and alerting procedures

SRE director structures the runbook with all required sections.

---

## Phase 4: Runbook Writing

Write `docs/runbooks/<service>-<type>-runbook.md`:

```markdown
# <Service> — <Type> Runbook

**Service:** <name>
**Version:** 1.0
**Last Updated:** YYYY-MM-DD
**Owner:** <team>
**On-call Escalation:** <contact>

## Overview
<Brief description of the service and purpose of this runbook>

## Prerequisites
- [ ] Access to: <list required access>
- [ ] Tools required: <list tools>
- [ ] Read: <any prerequisite documentation>

## Key Resources
| Resource | Location/URL |
|----------|-------------|
| Dashboards | <grafana url> |
| Logs | <log URL> |
| Alerts | <alertmanager url> |
| Repository | <git url> |
| ADR | docs/decisions/adr-NNN-<service>.md |

## Procedures

### <Procedure 1>
**When to use:** <condition>
**Time to complete:** <estimate>
**Risk level:** Low / Medium / High

Steps:
1. <step with command if applicable>
   ```bash
   <command>
   ```
   Expected output: `<output>`
   
2. <step>
   Verify: <how to verify this step succeeded>

Rollback: <how to undo if something goes wrong>

---

### <Procedure 2>
...

## Monitoring & Alerts

### Key Metrics
| Metric | Normal Range | Alert Threshold | Dashboard |
|--------|-------------|-----------------|-----------|

### Common Alerts
| Alert | Meaning | Action |
|-------|---------|--------|

## Troubleshooting

### Symptom: <problem description>
**Likely Cause:** <causes>
**Check:**
1. <diagnostic step>
**Fix:**
1. <resolution step>

## Escalation
| Situation | Escalate To | Contact |
|-----------|------------|---------|
| SEV1 | On-call SRE | <pagerduty> |
| Security incident | Security on-call | <contact> |

## Changelog
| Date | Change | Author |
|------|--------|--------|
| YYYY-MM-DD | Initial version | sre-director |
```

---

## Phase 5: Validation

Use AskUserQuestion:
```
Runbook draft complete. Review?
```
options: [Approve as-is, Request changes, Add more procedures]

Log creation to `production/session-logs/YYYY-MM-DD.md`.

---

Verdict: **COMPLETE** — runbook at `docs/runbooks/<service>-<type>-runbook.md`
Next Steps: Review with on-call team, add runbook URL to alert annotations.
