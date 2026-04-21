---
name: security-review
description: "Security review of a specific component, configuration, or design. Spawns security-director for assessment and security-scanner for automated checks. Produces security verdict."
argument-hint: "[component: terraform|k8s|cicd|network|iam|full] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Task, AskUserQuestion
agent: security-director
---

## /security-review [component]

Focused security review for a specific component or configuration.

---

## Phase 1: Review Scope

If component argument provided, focus on that area.

Otherwise, use AskUserQuestion:
```
What would you like to review for security?
```
options:
  - Terraform/IaC configuration
  - Kubernetes manifests
  - CI/CD pipeline configuration
  - Network architecture
  - IAM and access controls
  - Container images and Dockerfile
  - Application configuration and secrets
  - Full infrastructure review

---

## Phase 2: Context Loading

Read `production/review-mode.txt`
Read `production/session-state/active.md`

Check for existing security baselines in `docs/decisions/security-baseline-*.md`.

---

## Phase 3: Automated Scanning

Based on scope, spawn `security-scanner` via Task:

**Terraform scope:**
- tfsec scan on `terraform/` directory
- checkov scan on `terraform/` directory

**Kubernetes scope:**
- checkov scan on `k8s/` directory
- kube-score analysis

**CI/CD scope:**
- Secrets detection in `.github/workflows/` or `.gitlab-ci.yml`
- Pipeline privilege analysis

**Full scope:**
- All of the above simultaneously

---

## Phase 4: Manual Security Review

Spawn `security-director` via Task.

Review mode check:
- `solo` → security-director reviews all areas alone
- `lean` → security-director reviews high-risk areas
- `full` → security-director conducts full review with formal gate check

Security director evaluates:
- Principle of least privilege
- Attack surface exposure
- Sensitive data handling
- Defense in depth layers
- Known vulnerability patterns

---

## Phase 5: Findings Triage

Security director triages all findings:

```markdown
## Security Findings

### Critical (block immediately)
| Finding | Resource | Risk | Remediation |
|---------|----------|------|-------------|

### High (remediate before deployment)
| Finding | Resource | Risk | Remediation |

### Medium (remediate within 90 days)
| Finding | Resource | Risk | Remediation |

### Low (backlog)
| Finding | Resource | Risk | Remediation |
```

---

## Phase 6: Security Verdict

Gate check: SEC-REVIEW

Review mode check:
- `solo` → self-issued verdict
- `lean` → security-director issues verdict
- `full` → security-director issues formal gate verdict

Verdict format:
```
[SEC-REVIEW]: APPROVE — No critical or high findings.
[SEC-REVIEW]: CONCERNS [HIGH: <list>] — Can proceed with documented acceptance.
[SEC-REVIEW]: REJECT [CRITICAL: <list>] — Must remediate before proceeding.
```

---

## Phase 7: Remediation Planning

If CONCERNS or REJECT:

Use AskUserQuestion:
```
Security review found issues. How to proceed?
```
options:
  - Remediate critical issues now (spawn specialists)
  - Accept risk with justification (document in ADR)
  - Defer to next sprint (create tickets)

Log security review to `production/session-logs/YYYY-MM-DD.md`.

---

Verdict: **COMPLETE** — security review report produced.
Next Steps: Address findings per remediation plan.
