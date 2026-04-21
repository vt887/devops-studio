# Gate Definitions — DevOps Studio

Quality gates define the mandatory checks before progressing to critical phases.

Gates are enforced based on review mode:
- **full** — all gates active, director agents spawn for validation
- **lean** — only ARCH-DECISION and SEC-BASELINE gates are fully active; others are self-checked
- **solo** — gates are logged but not enforced; no agent spawning

---

## ARCH-DECISION

**Gate ID:** ARCH-DECISION
**Owner:** architect
**Required for:** `/team-new-env`, `/team-migration`, `/architecture-decision`, `/brainstorm` (when direction selected)

**Purpose:** Ensures every significant architecture decision is properly documented and evaluated before implementation begins.

**Checklist:**
- [ ] ADR document created with all required sections
- [ ] At least 2 alternatives considered and documented
- [ ] Cost impact estimated (even if approximate)
- [ ] Security implications described
- [ ] Rollback strategy defined
- [ ] SLO/reliability impact assessed
- [ ] Team consensus or decision authority documented

**Verdict Format:**
```
[ARCH-DECISION]: APPROVE
[ARCH-DECISION]: CONCERNS [list of concerns] — can proceed with documented acceptance
[ARCH-DECISION]: REJECT [list of blockers] — must resolve before proceeding
```

---

## SEC-BASELINE

**Gate ID:** SEC-BASELINE
**Owner:** security-director
**Required for:** `/team-new-env`, `/team-migration`, `/team-security-audit`

**Purpose:** Ensures security foundations are established before infrastructure is provisioned.

**Checklist:**
- [ ] IAM strategy documented with least-privilege verified
- [ ] Network security zones defined (ingress/egress rules explicit)
- [ ] Secrets management approach defined (no plaintext secrets)
- [ ] Audit logging enabled for all critical resources
- [ ] Encryption-at-rest configured for all data stores
- [ ] Encryption-in-transit configured (TLS 1.2+)
- [ ] Compliance requirements mapped to controls

**Verdict Format:**
```
[SEC-BASELINE]: APPROVE
[SEC-BASELINE]: CONCERNS [list] — can proceed with remediation plan
[SEC-BASELINE]: REJECT [list] — blocking security requirements not met
```

---

## COST-ESTIMATE

**Gate ID:** COST-ESTIMATE
**Owner:** cost-spec
**Required for:** `/team-new-env`, `/team-migration`, `/cost-review`

**Purpose:** Ensures cost impact is understood and within budget before committing to an architecture.

**Checklist:**
- [ ] Monthly cost estimate produced (with confidence range)
- [ ] Cost estimate reviewed against approved budget
- [ ] Top 3 cost drivers identified
- [ ] Reserved/Committed Use opportunities identified
- [ ] Tagging strategy defined for cost allocation
- [ ] Budget alerts configured (80% + 100% thresholds)

**Verdict Format:**
```
[COST-ESTIMATE]: APPROVE — estimated $X/month, within budget
[COST-ESTIMATE]: CONCERNS [cost driver list] — over budget, optimization needed
[COST-ESTIMATE]: REJECT — estimate exceeds budget by >20%, requires architecture revision
```

---

## ARCH-REVIEW

**Gate ID:** ARCH-REVIEW
**Owner:** architect
**Required for:** `/team-new-env` (after IaC generation), `/team-migration` (after target architecture)

**Purpose:** Validates that implementation (Terraform, K8s manifests) matches the approved architecture design.

**Checklist:**
- [ ] All generated IaC files match the approved ADR
- [ ] Resource naming conventions followed
- [ ] Remote state configuration correct
- [ ] No secrets in generated code
- [ ] Required tags present on all resources
- [ ] Module structure follows project standards
- [ ] Output values documented

**Verdict Format:**
```
[ARCH-REVIEW]: APPROVE
[ARCH-REVIEW]: CONCERNS [list] — minor deviations, document and proceed
[ARCH-REVIEW]: REJECT [list] — significant deviations from approved architecture
```

---

## SRE-READY

**Gate ID:** SRE-READY
**Owner:** sre-director
**Required for:** `/team-new-env`, `/team-migration` (before production cutover)

**Purpose:** Ensures the system is operationally ready — monitored, alerted, documented, and on-call covered.

**Checklist:**
- [ ] SLOs defined for all user-facing services
- [ ] Four golden signals monitored (Latency, Traffic, Errors, Saturation)
- [ ] Alert for every SLO with appropriate burn rate thresholds
- [ ] Runbook exists for every alert
- [ ] On-call rotation configured
- [ ] Failure mode analysis completed
- [ ] Deployment rollback procedure documented and tested

**Verdict Format:**
```
[SRE-READY]: APPROVE
[SRE-READY]: CONCERNS [list] — monitoring gaps, document and set remediation timeline
[SRE-READY]: REJECT [list] — critical observability missing, cannot go live
```

---

## SEC-SCAN

**Gate ID:** SEC-SCAN
**Owner:** security-director (via security-scanner)
**Required for:** `/team-new-env`, `/team-migration`, `/team-security-audit`

**Purpose:** Validates that all generated infrastructure code passes automated security scanning.

**Checklist:**
- [ ] tfsec/checkov scan completed on all Terraform code — zero CRITICAL findings
- [ ] checkov/kube-score scan completed on all K8s manifests — zero CRITICAL findings
- [ ] Secrets detection scan completed — zero leaked secrets
- [ ] All HIGH findings either fixed or risk-accepted with documented justification
- [ ] SBOM generated for container images (if applicable)
- [ ] Scan results dated within last 7 days

**Verdict Format:**
```
[SEC-SCAN]: APPROVE — zero critical, N high (risk-accepted with justification)
[SEC-SCAN]: CONCERNS [HIGH findings list] — can proceed with remediation plan
[SEC-SCAN]: REJECT [CRITICAL findings list] — must remediate before proceeding
```

---

## INCIDENT-RESOLVED

**Gate ID:** INCIDENT-RESOLVED
**Owner:** sre-director
**Required for:** `/team-incident` (before closing), `/postmortem` (opening check)

**Purpose:** Ensures incidents are properly closed with documentation and follow-up committed.

**Checklist:**
- [ ] Immediate user impact is fully resolved
- [ ] Root cause identified (or investigation ongoing with named owner)
- [ ] Postmortem scheduled (within 5 business days for SEV1/SEV2)
- [ ] Action items created with owners and due dates
- [ ] Stakeholder communication sent (resolved status)
- [ ] Monitoring confirms service returned to normal SLO

**Verdict Format:**
```
[INCIDENT-RESOLVED]: APPROVE — incident closed, postmortem scheduled
[INCIDENT-RESOLVED]: CONCERNS [list] — minor items outstanding, can close
[INCIDENT-RESOLVED]: REJECT [list] — impact ongoing or postmortem not committed
```
