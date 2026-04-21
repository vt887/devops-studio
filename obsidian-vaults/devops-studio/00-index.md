# DevOps Studio — Knowledge Base

**Source repo:** `/Users/tymoshv/MyPetProjects/devops-studio`
**Vault type:** reference + session archive
**Last manual seed:** 2026-04-20

Цей vault — дзеркало DevOps Studio фреймворка. Після кожної сесії хук `post-session-sync.sh` копіює сюди `session-logs/`, `docs/decisions/`, `docs/retrospectives/`, `docs/runbooks/`.

---

## Agents

### Directors (tier 1, opus)
- [[agents/architect]] — ARCH-DECISION, ARCH-REVIEW
- [[agents/security-director]] — SEC-BASELINE, SEC-SCAN, SEC-REVIEW
- [[agents/sre-director]] — SRE-READY, INCIDENT-RESOLVED

### Specialists (tier 2, sonnet)
- [[agents/terraform-spec]]
- [[agents/k8s-spec]]
- [[agents/cicd-spec]]
- [[agents/gitops-spec]]
- [[agents/monitoring-spec]]
- [[agents/cost-spec]]
- [[agents/security-scanner]]

---

## Skills

### Onboarding
- [[skills/start]] — `/start`

### Design
- [[skills/brainstorm]] — `/brainstorm`
- [[skills/architecture-decision]] — `/architecture-decision`
- [[skills/design-review]] — `/design-review`

### Team workflows (multi-agent)
- [[skills/team-new-env]] — new environment from scratch
- [[skills/team-migration]] — cloud-to-cloud migration
- [[skills/team-incident]] — production incident response
- [[skills/team-security-audit]] — full security audit

### Review
- [[skills/gate-check]]
- [[skills/cost-review]]
- [[skills/security-review]]

### Production
- [[skills/incident-report]]
- [[skills/postmortem]]
- [[skills/adr]]
- [[skills/runbook]]

---

## Gates

- [[gates/gate-definitions]] — full checklists
- [[gates/verdict-format]] — `[GATE-ID]: APPROVE|CONCERNS|REJECT`

Gates defined:
- `ARCH-DECISION` — architect
- `ARCH-REVIEW` — architect
- `SEC-BASELINE` — security-director
- `SEC-SCAN` — security-director (via security-scanner)
- `SEC-REVIEW` — security-director
- `COST-ESTIMATE` — cost-spec
- `SRE-READY` — sre-director
- `INCIDENT-RESOLVED` — sre-director

---

## Rules (domain standards)

- [[rules/terraform]]
- [[rules/kubernetes]]
- [[rules/cicd]]
- [[rules/security]]
- [[rules/gitops]]

---

## Framework Documentation

- [[scenarios]] — 5 real-world scenarios, triggers, roles, risks
- [[delegation-map]] — who delegates to whom, escalation paths
- [[coordination]] — parallelization, handoff, human-in-the-loop rules
- [[workflow-guide]] — user-facing quick-start

---

## Decisions (ADR archive)

- [[decisions/adr-001-template]] — template

Sync location: `decisions/` — populated from `docs/decisions/` on session end.

---

## Sessions

Session logs are synced here from `production/session-logs/`.

Naming pattern: `YYYY-MM-DD.md` (daily) and `incident-YYYY-MM-DD-HH-MM.md` (incidents).

---

## Retrospectives

- [[retrospectives/template]] — template

Synced from `docs/retrospectives/`.

---

## Runbooks

Synced from `docs/runbooks/`.

---

## Useful Queries (Dataview, якщо увімкнено)

```dataview
LIST FROM "decisions"
WHERE contains(file.name, "adr-") AND !contains(file.name, "template")
SORT file.name DESC
```

```dataview
TABLE file.mtime AS "Last Modified"
FROM "sessions"
SORT file.mtime DESC
LIMIT 10
```

---

## Conventions

- **Obsidian wiki-links** `[[path/to/file]]` працюють без `.md`.
- **Tags** поки не налаштовані — додавай `#adr`, `#incident`, `#sev1`, `#security` по потребі в frontmatter документів.
- **Backlinks** — кожен ADR посилається назад на scenario/skill що його створив.
- **Graph view** — activate в Obsidian щоб бачити зв'язки між ADR ↔ runbooks ↔ incidents.
