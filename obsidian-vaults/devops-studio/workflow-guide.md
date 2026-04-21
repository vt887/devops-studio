# DevOps Studio — Workflow Guide

## Overview

DevOps Studio is a multi-agent orchestration framework for structured infrastructure and platform engineering workflows. It provides specialized AI agents, quality gates, and skill-based workflows that mirror real DevOps team coordination.

## Getting Started

### 1. Start a Session

```
/start
```

This will:
- Detect existing project context
- Load or create session state
- Present available workflows
- Check current review mode

### 2. Choose Your Review Mode

Edit `production/review-mode.txt`:

| Mode | Description | Use When |
|------|-------------|----------|
| `full` | All gates active, all directors spawn | Production decisions, compliance-sensitive work |
| `lean` | Only critical gates (ARCH-DECISION, SEC-BASELINE) | Regular feature work, staging environments |
| `solo` | No gates, single-agent execution | Rapid iteration, exploration, drafting |

### 3. Select a Workflow

---

## Core Workflows

### Design Workflows

#### `/brainstorm [topic]`
Explore solution space before committing. Use when:
- Evaluating technology choices
- Planning a new service or platform component
- Comparing cloud provider options

#### `/architecture-decision [title]`
Create a formal ADR. Use when:
- Committing to a technology choice
- Changing an established pattern
- Making a decision that affects multiple teams

#### `/design-review [document]`
Review existing designs. Use when:
- Validating a design before implementation starts
- Getting multi-director review on a proposal
- Checking an existing implementation against standards

---

### Team Workflows (Multi-Agent)

#### `/team-new-env [name] [cloud]`
**Scenario:** Deploy a new environment from scratch

**Steps:** 9 phases, 15-20 actions
**Roles:** architect, security-director, sre-director, terraform-spec, k8s-spec, cicd-spec, monitoring-spec, cost-spec

**Gates:** ARCH-DECISION → SEC-BASELINE → COST-ESTIMATE → ARCH-REVIEW → SRE-READY → SEC-SCAN

**Output:**
- ADR for architecture decisions
- Security baseline document
- Cost estimate
- Terraform modules and environment config
- Kubernetes base configuration
- Monitoring configuration
- Validation report

---

#### `/team-migration [service] [source] [target]`
**Scenario:** Migrate application between cloud providers

**Steps:** 10 phases, 20-30 actions
**Roles:** architect, security-director, sre-director, cost-spec, terraform-spec, k8s-spec, cicd-spec

**Gates:** ARCH-DECISION → SEC-BASELINE → COST-ESTIMATE → ARCH-REVIEW → SRE-READY → SEC-SCAN

**Output:**
- Migration strategy ADR
- Dependency map
- Security migration plan
- Cost analysis (source vs target)
- Target architecture IaC
- Migration execution plan with rollback

---

#### `/team-incident [description] [SEV1|SEV2|SEV3]`
**Scenario:** Production incident response

**Steps:** 8 phases
**Roles:** sre-director (IC), k8s-spec (rollback), security-director (if security event)

**Gate:** INCIDENT-RESOLVED

**Output:**
- Incident timeline
- Mitigation steps
- Root cause (preliminary)
- Stakeholder communication

---

#### `/team-security-audit [scope]`
**Scenario:** Full security audit of infrastructure

**Steps:** 10 phases, 12-18 actions
**Roles:** security-director (lead), security-scanner, architect, cost-spec

**Gates:** SEC-SCAN + SEC-BASELINE review

**Output:**
- Automated scan results
- Compliance mapping
- Risk assessment
- Remediation roadmap
- Audit report

---

### Review Workflows

#### `/gate-check [GATE-ID]`
Manually validate a specific quality gate. Use to check readiness before a critical operation.

Available gates: `ARCH-DECISION`, `SEC-BASELINE`, `COST-ESTIMATE`, `ARCH-REVIEW`, `SRE-READY`, `SEC-SCAN`, `INCIDENT-RESOLVED`

#### `/cost-review [scope]`
Cloud cost analysis and FinOps recommendations.

#### `/security-review [component]`
Security review of a specific component or configuration.

---

### Production Operations

#### `/incident-report [title]`
Document an active or recent incident. Creates structured incident record.

#### `/postmortem [incident-id]`
Blameless post-incident review. Use within 5 business days of SEV1/SEV2 resolution.

#### `/adr [title]`
Quick ADR creation for decisions already made.

#### `/runbook [service] [type]`
Generate operational runbook for a service or procedure.

---

## Agent Hierarchy

```
architect (director — opus)
  ├── Owns: ARCH-DECISION, ARCH-REVIEW gates
  ├── Delegates to: terraform-spec, k8s-spec, cicd-spec, gitops-spec
  └── Escalates to: security-director (security concerns)

security-director (director — opus)
  ├── Owns: SEC-BASELINE, SEC-SCAN, SEC-REVIEW gates
  ├── Delegates to: security-scanner, cost-spec
  └── Can block any deployment on security grounds

sre-director (director — opus)
  ├── Owns: SRE-READY, INCIDENT-RESOLVED gates
  ├── Delegates to: monitoring-spec
  └── Leads all incident response
```

---

## Session State

DevOps Studio maintains state across conversations:

- **`production/session-state/active.md`** — Current session context (skill, phase, decisions)
- **`production/session-logs/YYYY-MM-DD.md`** — Audit trail of all decisions and events
- **`production/review-mode.txt`** — Current review mode (full/lean/solo)

State is saved automatically and restored on `/start`.

---

## Hooks

Lifecycle hooks run automatically:

| Hook | When | Purpose |
|------|------|---------|
| `session-start.sh` | Session start | Initialize logs, check review mode |
| `session-detect-context.sh` | Session start | Detect existing infrastructure |
| `pre-compact.sh` | Before compaction | Save session state |
| `log-decision.sh` | After Write/Edit | Audit trail for key files |
| `validate-before-apply.sh` | Before Bash | Warn on dangerous commands |
| `post-gate-check.sh` | After Task | Log gate verdicts |

---

## Examples

See `docs/examples/` for full session walkthroughs:
- `example-new-env.md` — Complete new environment deployment
- `example-incident.md` — SEV2 production incident response
