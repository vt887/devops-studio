# Agent Delegation Map

Хто кому делегує, хто до кого escalate-ить, хто володіє якими gates.

---

## Tier Hierarchy

```
Tier 1 — DIRECTORS (model: opus)
├── architect           — ARCH-DECISION, ARCH-REVIEW
├── security-director   — SEC-BASELINE, SEC-SCAN, SEC-REVIEW
└── sre-director        — SRE-READY, INCIDENT-RESOLVED

Tier 2 — SPECIALISTS (model: sonnet)
├── terraform-spec
├── k8s-spec
├── cicd-spec
├── gitops-spec
├── monitoring-spec
├── cost-spec
└── security-scanner
```

---

## Delegation Tree (хто кому делегує вниз)

```
architect
  ├──→ terraform-spec    (IaC implementation)
  ├──→ k8s-spec          (cluster + workload manifests)
  ├──→ cicd-spec         (pipeline design)
  └──→ gitops-spec       (Flux/ArgoCD setup)

security-director
  ├──→ security-scanner  (automated scans)
  └──→ cost-spec         (cost of security controls)

sre-director
  └──→ monitoring-spec   (metrics, logs, traces, alerts)
```

---

## Escalation Paths (хто кому escalate-ить нагору)

```
terraform-spec ──security concern──→ security-director
terraform-spec ──architecture──────→ architect

k8s-spec       ──RBAC/netpol──────→ security-director
k8s-spec       ──topology────────→ architect
k8s-spec       ──SLO/monitoring──→ sre-director  (via monitoring-spec)

cicd-spec      ──secrets─────────→ security-director
cicd-spec      ──strategy───────→ architect
cicd-spec      ──GitOps handoff─→ gitops-spec

gitops-spec    ──controller RBAC→ security-director
gitops-spec    ──manifest shape─→ k8s-spec
gitops-spec    ──CI handoff─────→ cicd-spec

monitoring-spec──alert thresholds→ sre-director
monitoring-spec──storage cost───→ cost-spec

cost-spec      ──arch change────→ architect
cost-spec      ──sec cost──────→ security-director

security-scanner──CRITICAL finding→ security-director  (immediately)

architect      ──security override→ security-director  (has veto on sec grounds)
architect      ──reliability─────→ sre-director

security-director ──arch requirements→ architect
sre-director      ──infra for SRE───→ architect
```

---

## Gate Ownership Matrix

| Gate | Owner | Triggers | Blocks |
|---|---|---|---|
| ARCH-DECISION | architect | `/team-new-env`, `/team-migration`, `/architecture-decision`, `/brainstorm` | Implementation phases |
| ARCH-REVIEW | architect | After IaC generation | Terraform apply |
| SEC-BASELINE | security-director | `/team-new-env`, `/team-migration`, `/team-security-audit` | Provisioning |
| SEC-SCAN | security-director (via security-scanner) | After IaC generated | Production deploy |
| SEC-REVIEW | security-director | `/security-review` | Component approval |
| SRE-READY | sre-director | Before prod cutover | Production go-live |
| COST-ESTIMATE | cost-spec | `/team-new-env`, `/team-migration`, `/cost-review` | Budget sign-off |
| INCIDENT-RESOLVED | sre-director | `/team-incident` closure | Incident close |

---

## Conflict Resolution (коли директори не згодні)

Priority order при конфлікті:

1. **security-director has VETO** на security grounds — може блокувати будь-яке рішення архітекта.
2. **sre-director has BLOCK** на production deployment без монторингу — але не overriding архітектурний вибір, тільки production gate.
3. **architect has final say** на технологічний вибір, якщо security і SRE обмеження задоволені.
4. **cost-spec CONCERNS не блокують** — лише вимагають documented acceptance (за винятком >20% over budget → REJECT).

Якщо директори зайшли в deadlock — ескалація до користувача через AskUserQuestion з викладеними аргументами кожної сторони.

---

## Parallel Spawn Patterns

Де skills вимагають одночасного спавну:

| Skill | Parallel spawn |
|---|---|
| `/team-new-env` Phase 5 | `terraform-spec` + `k8s-spec` |
| `/team-new-env` Phase 8 | `security-scanner` + `security-director` |
| `/team-migration` Phase 6 | `terraform-spec` + `k8s-spec` + `cicd-spec` |
| `/team-security-audit` Phase 3 | `security-scanner` ×3 (IaC, K8s, secrets) |
| `/team-incident` Phase 3 | `sre-director` + `k8s-spec` (+ `security-director` якщо security event) |
| `/design-review` Phase 3 (full mode) | `architect` + `security-director` + `sre-director` |
| `/brainstorm` Phase 3 (full mode) | `architect` → then `security-director` + `sre-director` |

**Правило:** паралелити тільки те, де outputs незалежні. Sequential якщо output одного агента — input іншого.

---

## Context Handoff Conventions

Коли агент A делегує агенту B, передати через Task prompt:

1. **What was decided** — посилання на ADR або session-log entry
2. **What B needs to produce** — конкретний output path
3. **Constraints** — rules file до якого приривати (`.claude/rules/<domain>/rules.md`)
4. **Gate B must pass** — який verdict очікується
5. **Escalation signals** — коли B має escalate назад до A замість продовжувати

Приклад handoff prompt від architect → terraform-spec:

```
Architect-decided: ADR-007 — 3-AZ VPC with private subnets only, NAT Gateway HA.
Produce: terraform/modules/vpc/ (main.tf, variables.tf, outputs.tf, README.md)
Follow: .claude/rules/terraform/rules.md
Gate: ARCH-REVIEW checklist must pass
Escalate if: you need to add public subnet, or IAM policy required beyond VPC scope.
```
