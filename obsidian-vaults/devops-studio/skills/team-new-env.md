---
name: team-new-env
description: "Full multi-agent workflow to deploy a new environment from scratch. Covers architecture design, security baseline, cost estimation, IaC implementation, and validation. 15-20 steps across architect, security-director, sre-director, terraform-spec, k8s-spec, monitoring-spec."
argument-hint: "[env-name] [cloud-provider] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Task, AskUserQuestion
agent: architect
context: |
  !cat production/review-mode.txt 2>/dev/null || echo "full"
  !cat production/session-state/active.md 2>/dev/null
  !ls docs/decisions/ 2>/dev/null
---

## /team-new-env

Full environment provisioning workflow — from requirements to validated infrastructure.

Roles: architect, security-director, sre-director, terraform-spec, k8s-spec, cicd-spec, monitoring-spec, cost-spec

---

## Phase 1: Context Gathering

Spawn `architect` via Task.

Architect uses AskUserQuestion with tabs:

tabs:
  - Environment Name & Purpose (dev/staging/prod/sandbox)
  - Cloud Provider (AWS/GCP/Azure/multi-cloud)
  - Region & Availability Zones
  - Expected Traffic & Scale (users, RPS, data volume)
  - Team Size & Ownership
  - Compliance Requirements (SOC2/PCI/HIPAA/none)
  - Existing Infrastructure (greenfield vs brownfield)
  - Budget Constraints

Output: `production/session-state/active.md` updated with context.

Gate: none
Output: `context.md` in current working directory

---

## Phase 2: Architecture Design

Spawn `architect` via Task.

Architect designs:
- VPC/network topology (subnets, routing, peering)
- Kubernetes cluster topology (control plane, node groups/pools)
- Service mesh decision (yes/no, Istio/Linkerd)
- Database tier (managed vs self-hosted, multi-AZ)
- Storage strategy (block, object, file)
- DNS and ingress strategy
- Multi-region considerations

Gate: ARCH-DECISION

Review mode check:
- `solo` → architect self-approves with logged rationale
- `lean` → architect runs ARCH-DECISION checklist
- `full` → architect runs ARCH-DECISION, spawns security-director for input

Output: `docs/decisions/adr-<NNN>-<env-name>-architecture.md`

---

## Phase 3: Security Baseline

Spawn `security-director` via Task.

Security director defines:
- IAM strategy (roles, service accounts, OIDC federation)
- Network security zones (public/private/isolated)
- Secrets management approach (Vault/AWS Secrets Manager/GCP Secret Manager)
- Audit logging configuration
- Encryption requirements (at-rest, in-transit)
- Compliance controls mapping

Gate: SEC-BASELINE

Review mode check:
- `solo` → skip gate spawn, log baseline assumptions
- `lean` → security-director runs SEC-BASELINE gate
- `full` → security-director runs SEC-BASELINE gate with full checklist

Output: `docs/decisions/security-baseline-<env-name>.md`

---

## Phase 4: Cost Estimation

Spawn `cost-spec` via Task.

Cost specialist:
- Estimates monthly compute cost (instances/nodes)
- Estimates storage and data transfer
- Identifies Reserved/Committed Use opportunities
- Defines tagging strategy
- Sets up budget alert thresholds

Gate: COST-ESTIMATE

Review mode check:
- `solo` → skip, note "cost review deferred"
- `lean` → cost-spec produces estimate, no gate spawn
- `full` → cost-spec runs COST-ESTIMATE gate check

Output: `docs/decisions/cost-estimate-<env-name>.md`

---

## Phase 5: Implementation — Infrastructure

Spawn simultaneously (parallel):
- `terraform-spec` via Task — Terraform modules and environment config
- `k8s-spec` via Task — Kubernetes base configuration (if applicable)

terraform-spec creates:
- `terraform/modules/vpc/`
- `terraform/modules/eks/` (or GKE/AKS)
- `terraform/modules/security-groups/`
- `terraform/environments/<env-name>/main.tf`
- `terraform/environments/<env-name>/variables.tf`
- `terraform/environments/<env-name>/terraform.tfvars`

k8s-spec creates:
- `k8s/<env-name>/namespaces/`
- `k8s/<env-name>/rbac/`
- `k8s/<env-name>/network-policies/`
- `k8s/<env-name>/resource-quotas/`

Gate: ARCH-REVIEW

Review mode check:
- `solo` → implementations presented for user review
- `lean` → architect reviews terraform + k8s outputs
- `full` → architect runs ARCH-REVIEW, security-director reviews IAM + network policies

---

## Phase 6: CI/CD Pipeline Setup

Spawn `cicd-spec` via Task.
Spawn `gitops-spec` via Task (if GitOps is part of the design).

Issue both Task calls simultaneously.

cicd-spec creates:
- Pipeline definition for environment provisioning
- Environment-specific deployment workflows

gitops-spec creates (if applicable):
- GitOps repository structure
- Flux/ArgoCD bootstrap configuration
- Sync policies per environment

---

## Phase 7: Monitoring Setup

Spawn `monitoring-spec` via Task.

Monitoring spec configures:
- Prometheus scrape configs for the new environment
- Base alerting rules (node health, cluster health)
- Grafana dashboards for infrastructure golden signals
- Log aggregation pipeline

Requires SLO definitions from sre-director (read from active session state or spawn sre-director).

Gate: SRE-READY

Review mode check:
- `solo` → skip gate, note "SRE review deferred"
- `lean` → sre-director reviews monitoring config
- `full` → sre-director runs SRE-READY gate

---

## Phase 8: Security Validation

Spawn simultaneously:
- `security-scanner` via Task — scan all generated IaC and K8s manifests
- `security-director` via Task — review scan results and approve/block

Issue both Task calls, wait for security-scanner to complete first.

security-scanner scans:
- All Terraform files (tfsec, checkov)
- All K8s manifests (checkov, kube-score)
- Pipeline files (secret detection)

Gate: SEC-SCAN

---

## Phase 9: Validation Report

Compile final environment readiness report:

```markdown
# Environment Readiness Report: <env-name>

**Date:** YYYY-MM-DD
**Environment:** <env-name>
**Cloud:** <provider> / <region>

## Gate Results
| Gate          | Status  | Owner             |
|---------------|---------|-------------------|
| ARCH-DECISION | ✅/❌/⚠️ | architect         |
| SEC-BASELINE  | ✅/❌/⚠️ | security-director |
| COST-ESTIMATE | ✅/❌/⚠️ | cost-spec         |
| ARCH-REVIEW   | ✅/❌/⚠️ | architect         |
| SRE-READY     | ✅/❌/⚠️ | sre-director      |
| SEC-SCAN      | ✅/❌/⚠️ | security-scanner  |

## Deliverables
- [ ] ADR: docs/decisions/adr-NNN-<env>-architecture.md
- [ ] Security baseline: docs/decisions/security-baseline-<env>.md
- [ ] Cost estimate: docs/decisions/cost-estimate-<env>.md
- [ ] Terraform: terraform/environments/<env>/
- [ ] K8s config: k8s/<env>/
- [ ] Monitoring: monitoring/prometheus/rules/
- [ ] Runbook: docs/runbooks/<env>-operations.md

## Next Steps
1. Review terraform plan output before apply
2. Request terraform apply approval from platform team
3. Configure DNS and load balancer after provisioning
4. Run smoke tests post-deployment
```

Error Recovery:
- If any gate BLOCKED → present partial report and list blocking issues
- Always produce the report even if some phases failed
- Log BLOCKED phases to `production/session-logs/YYYY-MM-DD.md`

---

Verdict: **COMPLETE** — environment design complete, ready for provisioning approval.
Next Steps: Review terraform plan, get approval, run `/gate-check` before apply.
