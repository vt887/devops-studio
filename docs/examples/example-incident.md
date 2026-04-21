# Example Session: SEV2 Incident Response

This example walks through a complete `/team-incident` session for a production incident.

**Scenario:** API gateway returning 503 errors, affecting 30% of users. Deployment was made 45 minutes ago.

---

## Session Start

```
User: /team-incident "API gateway 503 errors" SEV2
```

---

## Phase 1: Incident Declaration

```
[devops-studio] INCIDENT RESPONSE MODE ACTIVATED

AskUserQuestion:
  - What is broken? payments-api via API gateway — 503 errors
  - Severity: SEV2 (major — partial service degradation)
  - When did it start? ~45 minutes ago, at 14:35 UTC
  - User impact: ~30% of requests failing, EU region
  - Recent changes? Deployment at 14:30 UTC (payments-api v2.1.4)

📋 Incident record created:
  production/session-logs/incident-2026-04-21-14-35.md

Timeline:
  14:35 UTC — Incident started (estimated)
  15:20 UTC — Incident declared
```

---

## Phase 2: Immediate Assessment

```
[sre-director] Taking Incident Commander role...

Reviewing SLO burn rate:
  payments-api availability SLO: 99.9% (30-day)
  Current burn rate: 8.2x (CRITICAL - will exhaust 30-day budget in 3.5 days)
  
Error analysis:
  503s originating from: payments-api pods
  Pattern: Connection refused on port 8080
  
Recent changes:
  14:30 UTC: payments-api v2.1.4 deployed
  Change: Updated database connection pool library

Is this a security incident?
[Selected: No — SRE-led response]
```

---

## Phase 3: Parallel Investigation

```
[sre-director + k8s-spec running simultaneously]

[sre-director]:
  - Error rate: 32% of requests
  - Affected: 4/12 pods in payments-api deployment
  - Pattern: 4 pods in CrashLoopBackOff
  - Dependency graph: downstream services (order-service, checkout) failing

[k8s-spec]:
  - kubectl get pods -n payments: 4/12 in CrashLoopBackOff
  - Last successful deployment: v2.1.3 (yesterday 09:00 UTC)
  - Current deployment: v2.1.4 (14:30 UTC)
  - Container logs: "Failed to connect to database: too many open connections"
  - Database connection pool config changed in v2.1.4
```

---

## Phase 4: Mitigation Options

```
[sre-director] Presenting mitigation options:

1. ROLLBACK — Revert payments-api to v2.1.3
   Confidence: HIGH | Time: 3-5 min | Risk: LOW
   Reason: Deployment at 14:30 is confirmed cause
   
2. SCALE UP DATABASE CONNECTIONS — Increase RDS max_connections
   Confidence: MEDIUM | Time: 10-15 min | Risk: MEDIUM
   Reason: May help without rollback
   
3. HOTFIX — Patch v2.1.4 connection pool config
   Confidence: MEDIUM | Time: 30-45 min | Risk: LOW
   Reason: Clean fix but slower
```

```
AskUserQuestion: Select mitigation approach
[Selected: Option 1 — ROLLBACK]
```

---

## Phase 5: Mitigation Execution

```
[k8s-spec] Preparing rollback...

Rollback command:
  kubectl rollout undo deployment/payments-api -n payments

Current: v2.1.4 (image: myregistry.io/payments-api:v2.1.4)
Target:  v2.1.3 (image: myregistry.io/payments-api:v2.1.3)

AskUserQuestion: Execute rollback?
[Selected: Yes — execute rollback]

Executing: kubectl rollout undo deployment/payments-api -n payments
  deployment.apps/payments-api rolled back

Watching rollout status...
  payments-api: 12/12 pods running (v2.1.3) ✅

Timeline update:
  15:28 UTC — Rollback to v2.1.3 executed
  15:30 UTC — All 12 pods running successfully
```

---

## Phase 6: Verification

```
[sre-director] Verifying mitigation...

Monitoring check (15:32 UTC):
  Error rate: 0.1% (SLO: < 0.1% — borderline)
  Burn rate: 0.3x (normal)
  All pods: Running
  Database connections: Normal

15:35 UTC check:
  Error rate: 0.02% (normal)
  All green ✅

AskUserQuestion: Is the mitigation working?
[Selected: Yes — incident resolving]
```

---

## Phase 7: Communication

```
[sre-director] Drafting stakeholder communication:

Subject: [SEV2] payments-api 503 errors — MITIGATED

Impact: ~30% of payment API requests failed for EU region
Start Time: 14:35 UTC
Mitigated: 15:30 UTC
Duration: ~55 minutes

Root Cause (preliminary): Database connection pool misconfiguration
in payments-api v2.1.4 deployment. Rolled back to v2.1.3.

Current Status: MITIGATED — service fully restored
Next Update: Postmortem within 5 business days

— Platform Team

AskUserQuestion: Send notification?
[Selected: Send as-is]
```

---

## Phase 8: Resolution

```
[sre-director] Running INCIDENT-RESOLVED gate...

✅ User impact resolved (error rate 0.02%)
✅ Root cause identified (connection pool config in v2.1.4)
✅ Mitigation applied (rolled back to v2.1.3)
✅ Stakeholder communication sent
✅ Monitoring confirms SLO recovery
⬜ Postmortem: to be scheduled

[INCIDENT-RESOLVED]: APPROVE — incident closed, postmortem to be scheduled within 5 days.

Incident summary written to: production/session-logs/incident-2026-04-21-14-35.md

AskUserQuestion: Next steps?
[Selected: Schedule postmortem for later]
```

---

## Total Session Time

| Phase | Time |
|-------|------|
| Incident declaration + initial assessment | 5 min |
| Parallel investigation (sre-director + k8s-spec) | 8 min |
| Mitigation option selection | 2 min |
| Rollback execution | 5 min |
| Verification | 8 min |
| Communication draft + send | 5 min |
| Resolution + gate | 3 min |
| **Total** | **~36 min (MTTR)** |

---

## Key Observations

1. **Parallel investigation** (sre-director + k8s-spec simultaneously) saved ~5 minutes vs sequential
2. **Recent deployment flag** immediately narrowed the cause to v2.1.4
3. **Rollback first, fix later** — correct priority for SEV2 (restore service, then investigate)
4. **Gate enforcement** ensured postmortem commitment before closing incident
