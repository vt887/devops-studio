---
name: architecture-decision
description: "Create a formal Architecture Decision Record (ADR) for a significant infrastructure or platform decision. Spawns architect for design, security-director and sre-director for validation, enforces ARCH-DECISION gate."
argument-hint: "[decision-title] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Task, AskUserQuestion
agent: architect
---

## /architecture-decision [title]

Formal ADR creation workflow. Use when committing to a significant architectural direction.

---

## Phase 1: Context Loading

Read `production/review-mode.txt`
Read `production/session-state/active.md`
List existing ADRs in `docs/decisions/` (to determine next ADR number)

If no title provided, use AskUserQuestion:
```
What decision are you making?
(e.g., "Adopt Kubernetes for container orchestration", "Use Terraform for IaC", "Multi-region active-active strategy")
```

---

## Phase 2: Decision Context Gathering

Spawn `architect` via Task to gather:

Use AskUserQuestion with tabs:

tabs:
  - Context: What is the problem or opportunity?
  - Drivers: What forces/constraints drive this decision?
  - Scope: What systems/teams are affected?
  - Timeline: When must this decision be made?

---

## Phase 3: Alternatives Analysis

Architect agent enumerates at least 2 alternatives (required by ARCH-DECISION gate):

For each alternative:
- Description
- Pros / Cons
- Estimated cost impact
- Security implications
- Operational complexity

Use AskUserQuestion:
```
Have all relevant alternatives been considered?
```
options: [Yes — proceed, No — add more alternatives]

---

## Phase 4: Decision Selection

Use AskUserQuestion:
```
Which option do you select as the decision?
```
options: [list alternatives + "Combination/hybrid approach"]

Architect documents:
- **Decision** — the chosen option
- **Rationale** — why this option over others
- **Trade-offs accepted** — what we're knowingly accepting

---

## Phase 5: Gate Check — ARCH-DECISION

Review mode check:
- `solo` → self-check only, log result
- `lean` → spawn `architect` to run gate checklist
- `full` → spawn `architect` + `security-director` + `sre-director` simultaneously

Gate checklist (ARCH-DECISION):
- [ ] ADR document created with all sections
- [ ] At least 2 alternatives considered
- [ ] Cost impact estimated
- [ ] Security implications described
- [ ] Rollback strategy defined
- [ ] SLO impact assessed

If CONCERNS or REJECT → present issues and loop back to Phase 3 or 4.

---

## Phase 6: ADR Creation

Write `docs/decisions/adr-NNN-<kebab-case-title>.md` using the ADR template.

ADR template:
```markdown
# ADR-NNN: <Title>

**Date:** YYYY-MM-DD
**Status:** Accepted
**Deciders:** <team/roles>

## Context
<What is the situation that requires a decision?>

## Decision Drivers
- <driver 1>
- <driver 2>

## Considered Alternatives
### Option A: <name>
<description, pros, cons>

### Option B: <name>
<description, pros, cons>

## Decision
We will adopt **Option X** because <rationale>.

## Consequences
**Positive:**
- <positive consequence>

**Negative:**
- <accepted trade-off>

## Security Implications
<security-director notes>

## Cost Impact
<estimated monthly delta>

## Rollback Strategy
<how to undo this decision if needed>

## SLO Impact
<reliability implications>
```

---

## Phase 7: Implementation Planning

Use AskUserQuestion:
```
Decision documented. What's next?
```
options:
  - Create implementation plan now
  - Delegate to specialist (terraform-spec / k8s-spec / cicd-spec)
  - Schedule for later (save to session state)

Log ADR creation to `production/session-logs/YYYY-MM-DD.md`.
Update `production/session-state/active.md`.

---

Verdict: **COMPLETE** — ADR created at `docs/decisions/adr-NNN-<title>.md`
Next Steps: `/design-review` to review implementation, or delegate to specialists.
