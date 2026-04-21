---
name: team-migration
description: "Multi-agent workflow to migrate an application between cloud providers or major infrastructure changes. 20-30 steps covering assessment, architecture, security, cost, implementation plan, and cutover strategy."
argument-hint: "[service-name] [source-cloud] [target-cloud] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Task, AskUserQuestion
agent: architect
context: |
  !cat production/review-mode.txt 2>/dev/null || echo "full"
  !cat production/session-state/active.md 2>/dev/null
  !ls docs/decisions/ 2>/dev/null
---

## /team-migration

Cloud migration workflow — assessment to cutover planning.

Roles: architect, security-director, sre-director, cost-spec, terraform-spec, k8s-spec, cicd-spec

---

## Phase 1: Migration Scope Assessment

Spawn `architect` via Task.

Architect uses AskUserQuestion with tabs:

tabs:
  - Service/Application Name and Description
  - Source Cloud Provider & Region
  - Target Cloud Provider & Region
  - Migration Driver (cost/compliance/performance/vendor-exit)
  - Current Architecture (stateless/stateful, dependencies)
  - Data Volume (databases, storage, data classification)
  - SLA Requirements During Migration (acceptable downtime)
  - Target Timeline

Output: Migration scope document in `production/session-state/active.md`

---

## Phase 2: Discovery & Dependency Mapping

Spawn `architect` via Task.

Architect maps:
- All services to be migrated (prioritized list)
- External dependencies (third-party APIs, DNS, certificates)
- Data dependencies (databases, message queues, caches)
- Network dependencies (peering, VPNs, Direct Connect)
- IAM and authentication dependencies
- CI/CD pipeline dependencies

Use AskUserQuestion to confirm the dependency map is complete.

Output: `docs/decisions/migration-dependency-map.md`

---

## Phase 3: Migration Strategy Selection

Spawn `architect` via Task.

Architect presents migration patterns:

1. **Lift & Shift (Rehost)** — move as-is, minimal changes
2. **Replatform** — minor cloud-native optimizations
3. **Repurchase** — move to different SaaS/PaaS
4. **Refactor** — re-architect for cloud-native
5. **Retire** — decommission service

For each service in scope, recommend strategy.

Gate: ARCH-DECISION

Review mode check:
- `solo` → architect self-approves
- `lean` → architect runs ARCH-DECISION gate
- `full` → architect + security-director + sre-director review simultaneously

Output: `docs/decisions/adr-NNN-migration-strategy.md`

---

## Phase 4: Security & Compliance Review

Spawn `security-director` via Task.

Security director reviews:
- Data classification and transfer requirements
- Cross-cloud IAM federation strategy
- Certificate migration plan
- Secrets migration (no plaintext transfer)
- Compliance implications of target cloud
- Network security during migration (dual-stack period)

Gate: SEC-BASELINE (for target environment)

Output: `docs/decisions/migration-security-plan.md`

---

## Phase 5: Cost Analysis

Spawn `cost-spec` via Task.

Cost specialist analyzes:
- Current cloud spend (source)
- Projected target cloud spend
- Migration execution costs (egress fees, tooling)
- Break-even timeline for migration investment
- Reserved/Committed Use recommendations for target

Gate: COST-ESTIMATE

Output: `docs/decisions/migration-cost-analysis.md`

---

## Phase 6: Target Architecture Design

Spawn simultaneously:
- `terraform-spec` via Task — target environment IaC
- `k8s-spec` via Task — workload manifests for target (if applicable)
- `cicd-spec` via Task — updated pipelines for target cloud

Outputs:
- `terraform/environments/<target-env>/`
- `k8s/<target-env>/`
- CI/CD pipeline updates

Gate: ARCH-REVIEW (after all three complete)

---

## Phase 7: Migration Execution Plan

Spawn `sre-director` via Task.

SRE director designs:
- Migration phases with rollback points
- Traffic cutover strategy (DNS-based, load balancer, feature flag)
- Data migration approach (sync/async, tooling)
- Parallel run period (dual-stack validation)
- Rollback decision criteria and procedure
- Communication plan for stakeholders

Use AskUserQuestion:
```
Review the migration execution plan. Approve to proceed?
```
options: [Approve, Request changes, Need more analysis]

Output: `docs/runbooks/migration-execution-plan.md`

---

## Phase 8: Monitoring & Observability Migration

Spawn `monitoring-spec` via Task.

Monitoring spec:
- Sets up target cloud monitoring infrastructure
- Configures dual monitoring during parallel run
- Defines migration success metrics
- Creates migration-specific dashboards and alerts

Gate: SRE-READY

---

## Phase 9: Security Scan — Target Architecture

Spawn `security-scanner` via Task.

Scan all target environment IaC and manifests.

Gate: SEC-SCAN

---

## Phase 10: Migration Readiness Report

Compile final migration readiness report:

```markdown
# Migration Readiness Report

**Service:** <name>
**Source:** <cloud> / <region>
**Target:** <cloud> / <region>
**Date:** YYYY-MM-DD

## Gate Summary
| Gate | Status | Owner |
|------|--------|-------|
| ARCH-DECISION | | architect |
| SEC-BASELINE  | | security-director |
| COST-ESTIMATE | | cost-spec |
| ARCH-REVIEW   | | architect |
| SRE-READY     | | sre-director |
| SEC-SCAN      | | security-scanner |

## Migration Phases
1. Target environment provisioning
2. Data replication initiation
3. Application deployment to target
4. Parallel run validation (N days)
5. Traffic cutover (canary → 100%)
6. Source decommission (after N days of stable operation)

## Risk Register
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|

## Rollback Criteria
<conditions that trigger rollback>

## Success Criteria
<measurable criteria that define migration success>
```

Error recovery: Always produce partial report if any phase is BLOCKED.

---

Verdict: **COMPLETE** — migration plan ready for execution approval.
Next Steps: Get stakeholder sign-off, run dry-run of Phase 1, schedule maintenance window.
