---
name: adr
description: "Create a standalone Architecture Decision Record (ADR) document. Lightweight version of /architecture-decision for quick documentation of decisions already made."
argument-hint: "[decision-title]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, AskUserQuestion
agent: architect
---

## /adr [title]

Quick ADR creation for documenting decisions.

---

## Phase 1: ADR Number

List files in `docs/decisions/` matching `adr-*.md`.
Determine next ADR number (highest existing + 1, start at 001 if none).

If no title provided, use AskUserQuestion:
```
What decision are you documenting?
```

---

## Phase 2: Decision Details

Use AskUserQuestion with tabs:

tabs:
  - Context: What problem or opportunity prompted this decision?
  - Decision: What was decided?
  - Rationale: Why was this chosen over alternatives?
  - Alternatives Considered: What else was evaluated?
  - Consequences: What are the positive and negative outcomes?
  - Status: Proposed / Accepted / Deprecated / Superseded

---

## Phase 3: Security & Cost Impact

Use AskUserQuestion:

```
Does this decision have security or cost implications?
```
options: [Yes — document them, No — mark as N/A, Unsure — flag for review]

If yes, gather:
- Security implications (IAM, network, data exposure)
- Cost delta (estimated monthly impact)

---

## Phase 4: ADR Writing

Write `docs/decisions/adr-NNN-<kebab-case-title>.md`:

```markdown
# ADR-NNN: <Title>

**Date:** YYYY-MM-DD
**Status:** <Proposed | Accepted | Deprecated | Superseded by ADR-NNN>
**Deciders:** <roles/names>

## Context
<What is the situation or problem this decision addresses?>

## Decision
We will **<decision statement>**.

## Rationale
<Why this decision was made over alternatives>

## Alternatives Considered

### Option A: <name>
<description>
- Pros: <list>
- Cons: <list>

### Option B: <name>
<description>
- Pros: <list>
- Cons: <list>

## Consequences

### Positive
- <outcome>

### Negative / Trade-offs
- <accepted trade-off>

## Security Implications
<N/A | description of security impact>

## Cost Impact
<N/A | estimated monthly delta>

## Rollback
<How to undo this decision if needed>

## References
- <link or document>
```

---

## Phase 5: Log

Append to `production/session-logs/YYYY-MM-DD.md`:
```
ADR created: adr-NNN-<title>.md
```

---

Verdict: **COMPLETE** — ADR created at `docs/decisions/adr-NNN-<title>.md`
