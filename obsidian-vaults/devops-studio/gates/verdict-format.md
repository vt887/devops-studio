# Gate Verdict Format — DevOps Studio

Standard format for all gate verdicts issued by director agents.

## Verdict Structure

Every gate verdict must follow this exact format:

```
[GATE-ID]: VERDICT_TYPE [optional details]
```

### Verdict Types

| Type | When to Use | Blocks Progress? |
|------|-------------|------------------|
| `APPROVE` | All criteria met | No |
| `CONCERNS [...]` | Minor issues, can proceed with caution | No (with documentation) |
| `REJECT [...]` | Blocking issues that must be resolved | Yes |

---

## Format Examples

### APPROVE

```
[ARCH-DECISION]: APPROVE
All checklist items verified. ADR-003 created with 3 alternatives, cost estimate of $2,400/month, security review complete, rollback via Terraform destroy documented.
```

```
[SEC-BASELINE]: APPROVE
IAM strategy documented with least-privilege. Network zones defined. Vault configured for secrets. CloudTrail enabled. All data stores encrypted. TLS 1.3 configured.
```

```
[SRE-READY]: APPROVE
SLOs defined for all 3 user-facing services. Golden signals monitored. Burn rate alerts configured. Runbooks created for all 7 alerts. On-call rotation set up. Deployment rollback tested.
```

### CONCERNS

```
[ARCH-REVIEW]: CONCERNS [tagging incomplete on RDS resources, module README missing]
Implementation broadly matches ADR-003. Two minor issues documented above. Proceed with commitment to fix within this sprint.
```

```
[COST-ESTIMATE]: CONCERNS [estimated $3,200/month is 7% over the $3,000 target]
Architecture is sound. Cost overrun is primarily NAT Gateway data processing. Recommend Reserved NAT Gateway or PrivateLink for internal traffic. Can proceed — team accepts the overage pending optimization.
```

### REJECT

```
[SEC-SCAN]: REJECT [CRITICAL: S3 bucket public access not blocked (terraform/modules/storage/main.tf:45), CRITICAL: RDS password hardcoded (terraform/environments/prod/main.tf:89)]
2 critical findings must be remediated before proceeding. See security-scan report for details.
```

```
[SEC-BASELINE]: REJECT [IAM wildcard actions on production DynamoDB, no encryption on staging RDS, no audit logging configured]
3 blocking security requirements not met. Remediation required before environment provisioning can proceed.
```

---

## Partial Verdict (when some checklist items cannot be evaluated)

```
[SRE-READY]: CONCERNS [items 3-4 could not be evaluated — monitoring stack not deployed yet]
Items 1, 2, 5, 6, 7 verified. Items 3 (burn rate alerts) and 4 (runbook URLs) require monitoring stack deployment. Recommend proceeding to monitoring deployment and re-running gate before production cutover.
```

---

## Gate Log Entry Format

When logging gate results to session log (`production/session-logs/YYYY-MM-DD.md`):

```markdown
- HH:MM UTC — Gate: [ARCH-DECISION]: APPROVE | Owner: architect | Skill: /team-new-env Phase 2
- HH:MM UTC — Gate: [SEC-BASELINE]: CONCERNS [encryption gap] | Owner: security-director | Action: remediation plan added to ADR
- HH:MM UTC — Gate: [SEC-SCAN]: REJECT [2 CRITICAL] | Owner: security-scanner | Blocking phase 8
```

---

## Review Mode Behavior

| Gate | full | lean | solo |
|------|------|------|------|
| ARCH-DECISION | director spawn | director spawn | self-check + log |
| SEC-BASELINE | director spawn | director spawn | self-check + log |
| COST-ESTIMATE | director spawn | self-check | log only |
| ARCH-REVIEW | director spawn | director spawn | self-check + log |
| SRE-READY | director spawn | director spawn | self-check + log |
| SEC-SCAN | director spawn | self-check | log only |
| INCIDENT-RESOLVED | director spawn | self-check | self-check |
