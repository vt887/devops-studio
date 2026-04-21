---
name: team-security-audit
description: "Full security audit workflow for infrastructure. Spawns security-director for strategy, security-scanner for automated scanning, and produces compliance-ready audit report. 12-18 steps."
argument-hint: "[scope: all|terraform|k8s|cicd|network] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Task, AskUserQuestion
---

## /team-security-audit

Comprehensive security audit workflow for DevOps infrastructure.

Roles: security-director (lead), security-scanner (automated), architect (architecture review), cost-spec (security controls cost)

---

## Phase 1: Audit Scope Definition

Spawn `security-director` via Task.

Security director uses AskUserQuestion with tabs:

tabs:
  - Audit Scope (all infrastructure / specific components)
  - Compliance Framework (SOC2/PCI-DSS/ISO27001/HIPAA/CIS Benchmark/none)
  - Cloud Provider & Environment
  - Audit Trigger (scheduled/incident/compliance/pre-certification)
  - Previous Audit Results (if available, load from docs/decisions/)
  - Risk Tolerance (conservative/standard/startup)

Write audit plan to `production/session-state/active.md`.

---

## Phase 2: Asset Discovery

Spawn `architect` via Task to enumerate all infrastructure components:

- Terraform resources (scan terraform/ directory)
- Kubernetes workloads (scan k8s/ directory)
- CI/CD pipelines (scan .github/workflows/ or .gitlab-ci.yml)
- GitOps configurations (scan gitops/ directory)
- Active network resources

Output: Asset inventory in audit report skeleton.

---

## Phase 3: Automated Scanning

Spawn simultaneously (parallel):
- `security-scanner` via Task — IaC scan (tfsec, checkov)
- `security-scanner` via Task — K8s scan (checkov, kube-score)
- `security-scanner` via Task — Secrets detection (gitleaks patterns)

Issue all three Task calls simultaneously.

Each scanner produces findings in format:
```
| Finding | Severity | Resource | CIS Control | Status |
```

---

## Phase 4: IAM & Access Review

Spawn `security-director` via Task.

Security director reviews:
- IAM roles and policies (least privilege check)
- Service account permissions (K8s and cloud)
- Cross-account access patterns
- MFA enforcement status
- Access key rotation status
- Privileged access management

---

## Phase 5: Network Security Review

Spawn `security-director` via Task.

Security director reviews:
- Security group / firewall rules (ingress/egress)
- Network policies (Kubernetes)
- Public endpoint exposure (what's publicly accessible)
- VPC peering and routing
- WAF and DDoS protection
- TLS/certificate status and expiry

---

## Phase 6: Secrets & Configuration Review

Spawn `security-scanner` via Task for secrets detection.

Security director reviews:
- Secrets management approach (Vault/AWS SM/GCP SM)
- Environment variable usage in workloads
- ConfigMap/Secret handling in K8s
- Pipeline secrets configuration
- Encryption key management (KMS)

---

## Phase 7: Compliance Mapping

Spawn `security-director` via Task.

Based on selected compliance framework, map findings:
- Identify controls that are MET
- Identify controls that are PARTIAL
- Identify controls that are MISSING
- Estimate remediation effort for PARTIAL and MISSING

Review mode check:
- `solo` → skip framework mapping, document findings only
- `lean` → map to CIS Benchmark only
- `full` → full compliance framework mapping

---

## Phase 8: Risk Assessment

Security director produces risk assessment:

For each finding category:
- **Risk Level**: Critical / High / Medium / Low
- **Exploitability**: Easy / Medium / Hard
- **Impact**: data breach / service disruption / compliance violation
- **Priority**: immediate / 30-day / 90-day / backlog

---

## Phase 9: Audit Report

Compile comprehensive audit report:

```markdown
# Security Audit Report

**Date:** YYYY-MM-DD
**Scope:** <scope>
**Compliance Framework:** <framework>
**Auditor:** security-director + security-scanner

## Executive Summary
- Critical findings: N
- High findings: N
- Medium findings: N
- Low findings: N
- Overall risk posture: <HIGH/MEDIUM/LOW>

## Findings

### Critical Findings (require immediate action)
| ID | Finding | Resource | Remediation | Owner |
|----|---------|----------|-------------|-------|

### High Findings (resolve within 30 days)
| ID | Finding | Resource | Remediation | Owner |
|----|---------|----------|-------------|-------|

### Medium Findings (resolve within 90 days)
...

### Low Findings (backlog)
...

## Compliance Status
| Control | Status | Gap | Remediation Effort |
|---------|--------|-----|-------------------|

## Remediation Roadmap
Phase 1 (Week 1): Critical findings
Phase 2 (Month 1): High findings
Phase 3 (Quarter): Medium findings

## Next Audit: YYYY-MM-DD
```

Write to `docs/decisions/security-audit-YYYY-MM-DD.md`.
Log to `production/session-logs/sec-audit-YYYY-MM-DD.md`.

---

## Phase 10: Remediation Delegation

Use AskUserQuestion:
```
Audit complete. How would you like to proceed with remediation?
```
options:
  - Start with critical findings now (spawn security-director + specialists)
  - Create remediation tickets/tasks
  - Schedule remediation sprint
  - Review findings only (no action yet)

---

Verdict: **COMPLETE** — audit report at `docs/decisions/security-audit-YYYY-MM-DD.md`
Next Steps: Address critical findings immediately, schedule remediation for high findings.
