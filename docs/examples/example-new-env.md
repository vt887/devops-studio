# Example Session: New Environment Deployment

This example walks through a complete `/team-new-env` session in **full** review mode.

**Scenario:** Deploying a new `staging` environment on AWS for the `payments-service` team.

---

## Session Start

```
User: /start
```

```
📋 No active session found.
⚙️  Review Mode: full

🔍 Project Context Detected:
  - ADRs: 2 documents found
  - Previous sessions: 3 logs found

🚀 DevOps Studio — What would you like to do?
[Selected: /team-new-env]
```

---

## Phase 1: Context Gathering

```
[architect] Gathering environment requirements...

AskUserQuestion:
  - Environment Name: staging-payments
  - Cloud Provider: AWS / us-east-1
  - Scale: 50k RPS peak, 10 microservices
  - Team Size: 8 engineers
  - Compliance: PCI-DSS (card data handled)
  - Budget: $8,000/month max
```

---

## Phase 2: Architecture Design

```
[architect] Designing environment topology...

Proposed architecture:
- VPC: 10.20.0.0/16
- 3 AZs (us-east-1a/b/c)
- Public subnets: ALB, NAT Gateways
- Private subnets: EKS nodes (m5.xlarge x3 initial)
- Isolated subnets: RDS Aurora PostgreSQL (Multi-AZ)
- Service mesh: No (complexity vs benefit for 10 services)
- K8s: EKS 1.29, managed node groups

AskUserQuestion: Approve this architecture?
[Selected: Approve — proceed to gate check]
```

**Gate: ARCH-DECISION**

```
[architect] Running ARCH-DECISION gate...

✅ ADR-003 created: staging-payments-architecture.md
✅ 3 alternatives considered (ECS Fargate, EKS, GKE)
✅ Cost estimate: $6,800/month (±15%)
✅ Security implications: PCI DSS scope defined
✅ Rollback: terraform destroy procedure documented
✅ SLO target: 99.9% availability

[ARCH-DECISION]: APPROVE
Proceeding to security baseline.
```

---

## Phase 3: Security Baseline

```
[security-director] Defining PCI-DSS security baseline...

- IAM: OIDC federation for EKS nodes + CI/CD
- Network: CDE in isolated subnet, WAF on ALB
- Secrets: AWS Secrets Manager + KMS CMK
- Audit: CloudTrail (all regions), VPC Flow Logs
- Encryption: EBS gp3 encrypted, RDS encrypted, TLS 1.3

[SEC-BASELINE]: APPROVE
PCI-DSS controls mapped. Cardholder data environment isolated in separate subnet with strict NetworkPolicies.
```

---

## Phase 4: Cost Estimation

```
[cost-spec] Running cost analysis...

Estimated monthly breakdown:
  EKS: 3x m5.xlarge = $420
  RDS Aurora (Multi-AZ): $1,200
  ALB + WAF: $380
  NAT Gateways (3): $320
  Data transfer: $180
  CloudWatch/CloudTrail: $140
  Secrets Manager: $60
  Misc (ECR, etc): $100
  ─────────────────────────
  Total: ~$2,800/month

Well under $8,000 budget.

[COST-ESTIMATE]: APPROVE — $2,800/month estimated, $5,200 under budget.
Recommend 1-year Reserved Instances for EKS nodes ($280/month savings).
```

---

## Phase 5: Implementation

```
[terraform-spec + k8s-spec] Running in parallel...

terraform-spec creates:
  terraform/modules/vpc/
  terraform/modules/eks/
  terraform/modules/rds-aurora/
  terraform/modules/alb/
  terraform/environments/staging-payments/

k8s-spec creates:
  k8s/staging-payments/namespaces/
  k8s/staging-payments/rbac/
  k8s/staging-payments/network-policies/
  k8s/staging-payments/resource-quotas/
```

**Gate: ARCH-REVIEW**

```
[architect] Reviewing generated IaC...

✅ VPC matches approved design
✅ EKS module uses approved node type and version
✅ RDS in isolated subnet as specified
⚠️ CONCERN: RDS backup retention set to 7 days; PCI requires 90 days

[ARCH-REVIEW]: CONCERNS [RDS backup retention]
Backup retention updated to 90 days. Proceeding.
```

---

## Phase 7: Monitoring

```
[monitoring-spec] Configuring observability stack...

- Prometheus scrape configs for EKS
- Grafana dashboards: cluster health, node metrics, pod resources
- Alertmanager: SNS → PagerDuty routing
- Base alerts: node not ready, pod crash loop, memory pressure

[sre-director] Running SRE-READY gate...

✅ SLOs defined for payments-api, checkout-service, webhook-service
✅ Golden signals monitored
✅ Burn rate alerts configured
⚠️ CONCERN: Runbooks not yet created for 3 new alerts

[SRE-READY]: CONCERNS [runbooks missing for 3 alerts]
Runbooks scheduled for creation in next sprint.
```

---

## Phase 8: Security Scan

```
[security-scanner] Scanning all generated code...

tfsec: 0 critical, 2 high, 5 medium
  HIGH: IMDSv1 not disabled on EKS nodes → FIXED
  HIGH: KMS key rotation not enabled → FIXED

checkov: 0 critical, 3 high, 8 medium
  HIGH findings: 2 fixed, 1 risk-accepted (documented)

kube-score: 3 high (missing resource limits on base manifests) → FIXED

[security-scanner] → [security-director]
[SEC-SCAN]: APPROVE
0 critical findings. All HIGH findings resolved or risk-accepted with justification.
```

---

## Phase 9: Final Report

```
# Environment Readiness Report: staging-payments

Gate Results:
  ARCH-DECISION: ✅ APPROVE
  SEC-BASELINE:  ✅ APPROVE
  COST-ESTIMATE: ✅ APPROVE ($2,800/month)
  ARCH-REVIEW:   ⚠️ CONCERNS (resolved — RDS backup updated)
  SRE-READY:     ⚠️ CONCERNS (runbooks scheduled)
  SEC-SCAN:      ✅ APPROVE

Deliverables:
  ✅ ADR-003: staging-payments-architecture.md
  ✅ Security baseline: security-baseline-staging-payments.md
  ✅ Cost estimate: cost-estimate-staging-payments.md
  ✅ Terraform: terraform/environments/staging-payments/
  ✅ K8s config: k8s/staging-payments/
  ✅ Monitoring: monitoring/prometheus/rules/

Next Steps:
  1. Review: terraform plan -out=staging-payments.plan
  2. Get team lead approval on plan output
  3. Apply: terraform apply staging-payments.plan
  4. Verify: kubectl get nodes -n staging-payments
  5. Create runbooks for 3 outstanding alerts
```

---

## Total Session Time

| Phase | Time |
|-------|------|
| Context gathering | 5 min |
| Architecture design + ARCH-DECISION gate | 12 min |
| Security baseline + SEC-BASELINE gate | 8 min |
| Cost estimation + COST-ESTIMATE gate | 5 min |
| IaC generation + ARCH-REVIEW gate | 15 min |
| Monitoring setup + SRE-READY gate | 8 min |
| Security scan + SEC-SCAN gate | 10 min |
| **Total** | **~63 min** |
