# DevOps Studio — Real-World Scenarios

5 реальних сценаріїв, під які спроектовано агентів, skills і gates. Якщо задача не підпадає під жоден з цих патернів — ймовірно, її треба розв'язувати однобічно без orchestrator-у.

Кожен сценарій має:
- **Trigger** — ознаки, що запускати саме цей workflow
- **Skill** — точка входу
- **Roles** — які агенти задіяні
- **Gates** — обов'язкові перевірки
- **Outputs** — артефакти на виході
- **Risks** — на що звернути увагу

---

## 1. New Environment from Scratch

**Trigger:** «потрібно підняти новий dev/staging/prod», «нам нарізають окрему AWS-акаунт/GCP-проект», «запускаємо платформу з нуля».

| Поле | Значення |
|---|---|
| **Skill** | `/team-new-env [env-name] [cloud]` |
| **Steps** | 9 фаз, 15-20 дій |
| **Roles** | architect → terraform-spec, k8s-spec, cicd-spec, gitops-spec; security-director → security-scanner; sre-director → monitoring-spec; cost-spec |
| **Gates** | ARCH-DECISION → SEC-BASELINE → COST-ESTIMATE → ARCH-REVIEW → SRE-READY → SEC-SCAN |
| **Outputs** | ADR, security baseline, cost estimate, `terraform/environments/<env>/`, `k8s/<env>/`, monitoring config, validation report |
| **Risks** | Немає greenfield-припущення — якщо акаунт/VPC вже існує, починати з discovery. Tagging і remote state налаштовуються в Phase 5, не пізніше. Cost gate блокує >20% overbudget — планувати буфер. |
| **Mode hint** | `full` для prod, `lean` для staging, `solo` для sandbox |

---

## 2. Cloud Migration

**Trigger:** «переносимо з AWS на GCP», «виходимо з vendor lock-in», «консолідація в один cloud», «repatriation з managed на self-hosted».

| Поле | Значення |
|---|---|
| **Skill** | `/team-migration [service] [source] [target]` |
| **Steps** | 10 фаз, 20-30 дій |
| **Roles** | architect (lead), security-director, sre-director, cost-spec, terraform-spec, k8s-spec, cicd-spec, monitoring-spec |
| **Gates** | ARCH-DECISION (migration strategy) → SEC-BASELINE (target) → COST-ESTIMATE (egress + parallel run) → ARCH-REVIEW → SRE-READY → SEC-SCAN |
| **Outputs** | Migration strategy ADR, dependency map, cross-cloud security plan, side-by-side cost analysis, target IaC, execution plan з rollback criteria |
| **Risks** | Data egress fees — типово недооцінюються. Certificate and DNS handoff — найчастіше блокер cutover-а. Stateful workloads потребують окремого data-migration етапу. Parallel run period не можна скорочувати заради економії. |
| **Mode hint** | завжди `full` — ціна помилки висока |

---

## 3. Production Incident (SEV1/SEV2)

**Trigger:** «сервіс лежить», «p99 латенція вистрелила», «alert в PagerDuty», «клієнти скаржаться».

| Поле | Значення |
|---|---|
| **Skill** | `/team-incident [desc] [SEV1\|SEV2\|SEV3]` |
| **Steps** | 8 фаз |
| **Roles** | sre-director (Incident Commander), k8s-spec (rollback), security-director (якщо security event), monitoring-spec |
| **Gates** | INCIDENT-RESOLVED (тільки на закритті) — gates під час самої реакції **навмисно вимкнено**, швидкість > процес |
| **Outputs** | Incident timeline `production/session-logs/incident-*.md`, mitigation log, stakeholder communication, preliminary root cause |
| **Risks** | Не робити rollback наосліп — спочатку підтвердити що саме deploy причина. При security-події route в security-director **негайно**, не через sre-director. AskUserQuestion на кожен крок — щоб mitigation не виконався без explicit approval. |
| **Mode hint** | завжди `lean` — не блокує на gates, але зберігає auditable log |
| **Follow-up** | `/postmortem` обов'язково в межах 5 business days для SEV1/SEV2 |

---

## 4. New Microservice in Existing Platform

**Trigger:** «додаємо новий сервіс foo-api», «команда X хоче свою deployment», «треба розгорнути новий компонент в існуючому кластері».

| Поле | Значення |
|---|---|
| **Skill chain** | `/brainstorm` → `/architecture-decision` → delegate до specialists (terraform-spec, k8s-spec, cicd-spec) |
| **Steps** | 10-15 дій (коротше за new-env, бо платформа готова) |
| **Roles** | architect (вирішує де розгортати), k8s-spec (manifests + HPA + NetworkPolicy), cicd-spec (pipeline), gitops-spec (якщо GitOps), security-director (RBAC + secrets), monitoring-spec (SLO + alerts) |
| **Gates** | ARCH-DECISION (якщо новий pattern) → ARCH-REVIEW → SEC-SCAN → SRE-READY |
| **Outputs** | ADR (якщо декомпонент non-trivial), `k8s/<namespace>/<service>/`, CI/CD pipeline, SLO definition, runbook |
| **Risks** | Не створювати новий namespace/cluster під кожен сервіс — спершу подивитись на існуючі патерни. NetworkPolicy **обов'язково** — default-deny + explicit allow. ServiceAccount per workload, не default. |
| **Mode hint** | `lean` — стандартний платформний flow |

---

## 5. Full Security Audit

**Trigger:** «готуємось до SOC2/PCI audit», «новий compliance scope», «квартальний security review», «після incident з security implication».

| Поле | Значення |
|---|---|
| **Skill** | `/team-security-audit [scope]` |
| **Steps** | 10 фаз, 12-18 дій |
| **Roles** | security-director (lead auditor), security-scanner (automated scans), architect (architecture review), cost-spec (cost of controls) |
| **Gates** | SEC-BASELINE review + SEC-SCAN на все |
| **Outputs** | Automated scan результати, compliance mapping (SOC2/PCI/ISO), risk register, remediation roadmap (P1 week-1, P2 month-1, P3 quarter), audit report |
| **Risks** | Автоматичні сканери дають false positives — кожен CRITICAL має бути triaged людиною. IAM review — найбільший blind spot (scanners не бачать semantic least-privilege). Compliance mapping без явного framework-у — marnastvo часу. |
| **Mode hint** | `full` — це весь сенс аудиту |
| **Follow-up** | Наступний аудит за 90 днів для high-risk remediation, за 180 для full |

---

## Коли НЕ запускати team-* workflow

Якщо задача:
- **One-shot fix** (підняти replica count, додати одну alert rule) → просто спавн відповідного specialist-а напряму через `Task`, без skill-а.
- **Exploration** (читання коду, пошук залежностей) → `Explore` агент або Grep/Glob напряму.
- **Question-answer** («як працює X?») → route в відповідного director-а без повного workflow.
- **Local dev** (тестування Terraform-модуля на своїй машині) → solo mode + `terraform-spec` напряму.

team-* workflow виправдані лише коли координація 3+ ролей, або коли критичність вимагає gates.
