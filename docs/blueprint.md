# DevOps Studio — Design Blueprint

**Purpose:** single reviewable design artifact for Phase B of `1.md`. Covers agents, gates, key skills, delegation, review modes. Markdown-only; no code.

**Status:** draft v1 — for user review before implementation is frozen.

---

## 0. Review Modes

Read from `production/review-mode.txt`. Default `full`.

| Mode | Gates spawned | Director spawns | Parallelism | Use when |
|------|---------------|-----------------|-------------|----------|
| `full` | all 7 | all critical phases | yes | production work, new env, migration, audit |
| `lean` | `ARCH-DECISION`, `SEC-BASELINE` only; rest = self-check | critical phases only | yes | routine microservice onboarding, sev2 incident |
| `solo` | none spawned — log-only | none | no | prototyping, learning, sev1 incident (speed > ceremony) |

Rule: mode never weakens a REJECT verdict; it only controls whether the gate **spawns an agent** vs. **self-checks**. A human override (`gate-check --override`) must be logged with justification.

---

## 1. Agent Roster (10 agents, 2 tiers)

### Tier 1 — Directors (model: `opus`)

#### `architect`
- **Role:** DevOps architect — platform topology, tech selection, cross-service integration
- **Delegates to:** `terraform-spec`, `k8s-spec`, `cicd-spec`, `gitops-spec`
- **Escalates to:** `security-director` (security concern), `sre-director` (reliability concern)
- **Gates owned:** `ARCH-DECISION`, `ARCH-REVIEW`
- **CAN:** choose cloud/region, pick tech stack, author ADRs, approve cross-team contracts
- **CANNOT:** apply terraform, deploy to prod, modify IAM policy, bypass security gates
- **Skills:** `architecture-decision`, `design-review`, `brainstorm`, `adr`

#### `security-director`
- **Role:** security posture, IAM strategy, threat model, compliance mapping
- **Delegates to:** `security-scanner`, `cost-spec` (when controls have cost impact)
- **Escalates to:** human (any incident with confirmed data exposure)
- **Gates owned:** `SEC-BASELINE`, `SEC-SCAN`, `SEC-REVIEW`
- **CAN:** define IAM model, set network policies, block on CRITICAL findings, require SEC-REVIEW
- **CANNOT:** approve own scan findings, override `ARCH-DECISION`, modify production IAM without ADR
- **Skills:** `security-review`, `team-security-audit`

#### `sre-director`
- **Role:** reliability, SLO/SLI/error-budget, incident command, capacity planning
- **Delegates to:** `monitoring-spec`, `k8s-spec` (for rollback operations)
- **Escalates to:** `security-director` (if incident has security dimension)
- **Gates owned:** `SRE-READY`, `INCIDENT-RESOLVED`
- **CAN:** define SLOs, run incidents, trigger rollback, require runbook before prod
- **CANNOT:** approve insecure mitigations, skip postmortem on sev1/sev2
- **Skills:** `team-incident`, `incident-report`, `postmortem`, `runbook`

### Tier 2 — Specialists (model: `sonnet`)

#### `terraform-spec`
- **Role:** Terraform IaC — modules, state, provider config, env separation
- **Escalates to:** `architect` (design), `security-director` (IAM/secrets)
- **Rules:** `.claude/rules/terraform/rules.md`
- **CAN:** write modules, plan changes, validate state — **CANNOT:** apply without gate

#### `k8s-spec`
- **Role:** Kubernetes manifests, Helm charts, RBAC, NetworkPolicy, HPA
- **Escalates to:** `architect` (cluster topology), `security-director` (pod security)
- **Rules:** `.claude/rules/kubernetes/rules.md`

#### `cicd-spec`
- **Role:** pipeline design — GitHub Actions / GitLab CI / Jenkins
- **Escalates to:** `security-director` (secrets, OIDC), `architect` (deploy topology)
- **Rules:** `.claude/rules/cicd/rules.md`

#### `gitops-spec`
- **Role:** Flux / ArgoCD configuration, repo structure, sync policies
- **Escalates to:** `architect` (repo layout), `security-director` (cluster access)
- **Rules:** `.claude/rules/gitops/rules.md`

#### `monitoring-spec`
- **Role:** Prometheus, Grafana, Alertmanager, Loki, OTEL, SLO burn rules
- **Escalates to:** `sre-director` (SLO definitions, alert routing)

#### `cost-spec`
- **Role:** FinOps — infracost, reserved instances, budget forecast, cost attribution
- **Escalates to:** `architect` (architectural cost drivers)
- **Gates owned:** `COST-ESTIMATE`

#### `security-scanner`
- **Role:** automated scanning — `tfsec`, `checkov`, `trivy`, `gitleaks`, OWASP dep-check
- **Escalates to:** `security-director` (CRITICAL/HIGH findings)
- **Output:** findings table `| Finding | Severity | Resource | CIS Control | Status |`

---

## 2. Gate Definitions (7 gates)

Verdict format (all gates): `[GATE-ID]: APPROVE | CONCERNS [reasons] | REJECT [reasons]`

### `ARCH-DECISION`
- **Owner:** `architect`
- **Required for:** `/team-new-env`, `/team-migration`, `/architecture-decision`, `/team-security-audit` (Phase 2)
- **Checklist:**
  - [ ] ADR document created in `docs/decisions/adr-*.md`
  - [ ] ≥2 alternatives documented with trade-offs
  - [ ] Cost impact noted (order of magnitude at least)
  - [ ] Security implications described
  - [ ] Rollback / reversal path defined
  - [ ] Dependencies on other services/teams listed

### `ARCH-REVIEW`
- **Owner:** `architect`
- **Required for:** `/team-new-env` (Phase 5), `/team-migration` (Phase 6), new-microservice workflow
- **Checklist:**
  - [ ] Implementation matches approved ADR
  - [ ] Follows `rules/terraform/rules.md` + `rules/kubernetes/rules.md`
  - [ ] Resource tagging complete (`Environment`, `Project`, `Team`, `ManagedBy`, `CostCenter`)
  - [ ] No hardcoded secrets, regions, or account IDs
  - [ ] Module versioning pinned; no unpinned sources
  - [ ] Observability hooks in place (metrics, logs, traces)

### `SEC-BASELINE`
- **Owner:** `security-director`
- **Required for:** `/team-new-env`, `/team-migration`, `/team-security-audit`
- **Checklist:**
  - [ ] IAM strategy documented (least privilege, MFA, OIDC for CI)
  - [ ] Secrets management chosen (Vault / cloud SM / Sealed Secrets)
  - [ ] Network segmentation defined (VPC, NetworkPolicy, egress rules)
  - [ ] Encryption at rest + in transit (TLS 1.2+, CMK/KMS)
  - [ ] Audit logging enabled + retention set
  - [ ] Compliance framework mapped if applicable (SOC2 / PCI / CIS)

### `SEC-SCAN`
- **Owner:** `security-director` (executed by `security-scanner`)
- **Required for:** `/team-new-env` (Phase 6), `/team-migration` (Phase 7), `/team-security-audit` (Phase 3), new-microservice
- **Checklist:**
  - [ ] IaC scan passed (`tfsec` + `checkov`, no HIGH/CRITICAL)
  - [ ] Container image scan passed (`trivy`, no HIGH/CRITICAL)
  - [ ] Secrets scan clean (`gitleaks`, no findings)
  - [ ] K8s manifest scan passed (`checkov` / `kube-score`)
  - [ ] Dependency scan recent (<24h for prod paths)
  - [ ] Findings that remain are triaged with SLA per severity

### `SEC-REVIEW`
- **Owner:** `security-director`
- **Required for:** `/team-security-audit` (Phase 9), post-incident with security dimension
- **Checklist:**
  - [ ] Threat model reviewed against current architecture
  - [ ] Compliance controls mapped: MET / PARTIAL / MISSING
  - [ ] Remediation roadmap with owners and SLAs
  - [ ] Residual risk documented and accepted
  - [ ] Next audit date scheduled

### `COST-ESTIMATE`
- **Owner:** `cost-spec`
- **Required for:** `/team-new-env`, `/team-migration`, `/cost-review`
- **Checklist:**
  - [ ] Monthly cost estimate produced (infracost or equivalent)
  - [ ] Reserved / savings-plan opportunities flagged
  - [ ] Data-egress costs called out
  - [ ] Budget threshold set; alert configured
  - [ ] Cost attribution (tags) verified

### `SRE-READY`
- **Owner:** `sre-director`
- **Required for:** `/team-new-env`, `/team-migration`, new-microservice, pre-prod promotion
- **Checklist:**
  - [ ] SLOs defined with SLI source documented
  - [ ] Burn-rate alerts configured (multi-window, multi-burn)
  - [ ] Runbook exists in `docs/runbooks/` for top-N alert paths
  - [ ] Rollback procedure tested in staging
  - [ ] On-call rotation + escalation chain defined
  - [ ] Dashboards published (RED/USE-style)

### `INCIDENT-RESOLVED`
- **Owner:** `sre-director`
- **Required for:** closing `/team-incident` workflow
- **Checklist:**
  - [ ] Mitigation verified (SLIs back in budget for ≥30 min)
  - [ ] Root cause identified or hypothesis recorded
  - [ ] Temporary workarounds documented + tracked for removal
  - [ ] Customer comms sent (status page + channel)
  - [ ] Postmortem scheduled within 5 business days (sev1/sev2)

---

## 3. Delegation Map

```
                          ┌─────────────────────────┐
                          │         HUMAN           │
                          │  (creative director,    │
                          │   approves overrides)   │
                          └───────────┬─────────────┘
                                      │
        ┌─────────────────────────────┼─────────────────────────────┐
        ▼                             ▼                             ▼
  ┌───────────┐               ┌──────────────────┐         ┌───────────────┐
  │ architect │◄─escalate──── │ security-director│ ────────│  sre-director │
  │  (opus)   │               │      (opus)      │         │    (opus)     │
  └─────┬─────┘               └────────┬─────────┘         └───────┬───────┘
        │                              │                           │
   delegates                      delegates                   delegates
        │                              │                           │
   ┌────┼───────┬──────────┬──────┐    │                           │
   ▼    ▼       ▼          ▼      ▼    ▼                           ▼
 ┌────┐┌────┐ ┌─────┐  ┌──────┐ ┌───────────────┐          ┌───────────────┐
 │tfs ││k8s │ │cicd │  │gitops│ │security-      │          │ monitoring-   │
 │pec ││spec│ │spec │  │spec  │ │scanner        │          │ spec          │
 └────┘└────┘ └─────┘  └──────┘ └───────────────┘          └───────────────┘
                                       │
                                       │ cost implications
                                       ▼
                                 ┌───────────┐
                                 │ cost-spec │
                                 └───────────┘
```

**Escalation rules:**
- Any specialist → director (of same domain) within 1 turn if blocked
- `architect` → `security-director` on security concern (mandatory, not advisory)
- `architect` → `sre-director` on reliability concern affecting SLO
- Any director → human on scope/budget/timeline conflict
- Conflicting verdicts between directors → human adjudicates; log in session state

**Parallel-spawn patterns (explicit):**
- `/team-new-env` Phase 3: `security-director` + `cost-spec` in parallel
- `/team-security-audit` Phase 3: three `security-scanner` spawns (IaC, K8s, secrets) in parallel
- `/team-migration` Phase 4: `security-director` + `cost-spec` + `sre-director` in parallel

---

## 4. Skill Phase Breakdowns (4 key skills)

Format per phase: `Phase N | Agent | Actions | Gate | Output`

### 4.1 `/team-new-env` — new environment from zero (15–22 steps)

| # | Agent | Actions | Gate | Output |
|---|-------|---------|------|--------|
| 1 | orchestrator | gather context via `AskUserQuestion` (cloud, region, env type, team, compliance, budget) | — | `session-state/active.md` |
| 2 | `architect` | topology design: VPC, cluster, service mesh, data tier, DNS, CI/CD path | `ARCH-DECISION` | `docs/decisions/adr-NNN.md` |
| 3a | `security-director` | IAM model, secrets solution, NetworkPolicy baseline, encryption | `SEC-BASELINE` | `docs/decisions/security-baseline-NNN.md` |
| 3b | `cost-spec` | infracost + RI/SP analysis, budget threshold | `COST-ESTIMATE` | `docs/decisions/cost-estimate-NNN.md` |
| 4 | `architect` | consolidate 2+3a+3b; present summary via `AskUserQuestion` (proceed/revise) | — | approval log |
| 5a | `terraform-spec` | modules + env root (`terraform/environments/<env>/`) | `ARCH-REVIEW` | `terraform/` |
| 5b | `k8s-spec` | namespaces, base manifests, NetworkPolicy, PDB, RBAC | `ARCH-REVIEW` | `k8s/` |
| 5c | `cicd-spec` | pipeline per mandatory stages (validate→test→build→scan→deploy) | `ARCH-REVIEW` | `.github/workflows/` or equivalent |
| 5d | `monitoring-spec` | Prometheus rules, Grafana dashboards, SLO burn alerts | — | `monitoring/` |
| 6 | `security-scanner` | scan all generated IaC + manifests + pipeline; triage findings | `SEC-SCAN` | `session-logs/sec-scan-YYYY-MM-DD.md` |
| 7 | `sre-director` | SLO validation, runbook skeleton, on-call verification | `SRE-READY` | `docs/runbooks/` |
| 8 | orchestrator | partial report; `AskUserQuestion` on next action (apply / review / defer) | — | verdict line |

Parallel: 3a∥3b, 5a∥5b∥5c∥5d.
Critical path: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8.

### 4.2 `/team-incident` — production incident (8–14 steps, lean by default)

| # | Agent | Actions | Gate | Output |
|---|-------|---------|------|--------|
| 1 | orchestrator | severity triage via `AskUserQuestion` (sev1/sev2/sev3, scope, impact) | — | `session-logs/incident-YYYY-MM-DD-HHMM.md` |
| 2 | `sre-director` | assemble bridge — declare incident commander, scribe, comms | — | status post #1 |
| 3 | `monitoring-spec` | pull SLI + correlated metrics, identify deviation window | — | metrics snapshot |
| 4 | `sre-director` | hypothesis — rollback / config / capacity / dependency | — | hypothesis log |
| 5 | `k8s-spec` or `cicd-spec` | execute mitigation (rollback / scale / toggle) — **gated by human approval in full mode** | — | command log |
| 6 | `monitoring-spec` | verify mitigation — SLI back in budget for ≥30 min | — | verification snapshot |
| 7 | `security-director` | (conditional) if security-relevant — forensic scope check | — | security note |
| 8 | `sre-director` | close incident | `INCIDENT-RESOLVED` | incident close record |
| 9 | `sre-director` | schedule postmortem (sev1/sev2 mandatory, within 5 business days) | — | calendar entry |

In `solo` mode: steps 2, 5, 8 are self-checks; incident still logged. In `lean`: step 5 still requires human approval for prod-touching commands.

### 4.3 `/team-security-audit` — full audit (12–18 steps)

| # | Agent | Actions | Gate | Output |
|---|-------|---------|------|--------|
| 1 | `security-director` | scope + framework selection (SOC2 / PCI / CIS / ISO27001 / none) | — | audit plan |
| 2 | `architect` | asset inventory (terraform resources, k8s workloads, pipelines, GitOps) | — | inventory |
| 3 | `security-scanner` ×3 ∥ | IaC scan ∥ K8s scan ∥ secrets scan | `SEC-SCAN` | 3× findings tables |
| 4 | `security-director` | IAM + access review (least priv, MFA, rotation, PAM) | — | IAM findings |
| 5 | `security-director` | network review (SGs, NetworkPolicy, public exposure, WAF, TLS) | — | network findings |
| 6 | `security-director` | secrets + encryption review | — | secrets findings |
| 7 | `security-director` | compliance mapping — MET / PARTIAL / MISSING | — | mapping table |
| 8 | `security-director` | risk assessment per category (exploitability × impact × priority) | — | risk matrix |
| 9 | `security-director` | audit report compilation | `SEC-REVIEW` | `docs/decisions/security-audit-YYYY-MM-DD.md` |
| 10 | orchestrator | remediation delegation — `AskUserQuestion` (start critical / create tickets / schedule sprint / review-only) | — | next-step plan |

Step 3 is the single largest parallel spawn — three scanners simultaneously.

### 4.4 `/architecture-decision` — single ADR (5–8 steps)

| # | Agent | Actions | Gate | Output |
|---|-------|---------|------|--------|
| 1 | orchestrator | frame decision — context, forces, constraints via `AskUserQuestion` | — | decision brief |
| 2 | `architect` | generate ≥2 alternatives with trade-offs (cost, ops, risk, fit) | — | alternatives draft |
| 3 | `architect` | recommend one, justify, list dependencies | — | recommendation |
| 4 | `cost-spec` | (conditional, if spend >$X/mo) cost impact | `COST-ESTIMATE` (if triggered) | cost note |
| 5 | `security-director` | (conditional, if security-touching) implications | `SEC-BASELINE` (if triggered) | security note |
| 6 | `architect` | write ADR using `docs/decisions/adr-001-template.md` structure | `ARCH-DECISION` | `docs/decisions/adr-NNN.md` |
| 7 | orchestrator | offer follow-ups (design-review, implementation plan, runbook) | — | next-step list |

Triggers: `COST-ESTIMATE` fires only if estimated new spend >$500/mo. `SEC-BASELINE` fires if ADR touches IAM, network, secrets, or data.

---

## 5. Open Questions for Review

Items I want explicit user sign-off on before freezing:

1. **Director count = 3.** Should `platform-director` (separate from `architect`) exist for cross-domain product decisions? Current design folds this into `architect`.
2. **`cost-spec` ownership.** It's a specialist today but owns `COST-ESTIMATE` gate. Should a `finops-director` tier be introduced if cost becomes a first-class concern?
3. **Incident mode default.** Currently `lean` by default for `/team-incident`. Alternative: always start `solo` and escalate to `lean`/`full` only if sev1 declared.
4. **Parallel-spawn ceiling.** Max parallel specialists set at 4 (Phase 5 of `/team-new-env`). Raise to 6 to cover gitops + security-scanner concurrently?
5. **`SEC-REVIEW` gate placement.** Currently only on `/team-security-audit`. Should it also gate production deploys with SEC-SCAN findings > N?
6. **Human-in-the-loop checkpoints.** Explicit list: prod apply, prod deploy, destructive rollback, IAM change, secret rotation, override of any REJECT verdict. Is this set complete?

---

## 6. What's Intentionally Out of Scope (v1)

- `data-engineer` / `ml-ops` agents (separate studio if needed)
- Multi-tenant SaaS operator logic (different domain)
- Cost optimization autopilot (human-in-the-loop only)
- Automatic runbook execution (runbooks are human-executable docs in v1)
- Cross-repo orchestration (single-repo focus for v1)
