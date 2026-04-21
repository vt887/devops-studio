---
name: brainstorm
description: "Facilitate structured brainstorming for a DevOps or architecture problem. Explores multiple approaches, trade-offs, and constraints before committing to a direction."
argument-hint: "[topic] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Task, AskUserQuestion
agent: architect
---

## /brainstorm [topic]

A structured exploration skill. Use before making architecture decisions to map the solution space.

---

## Phase 1: Topic Definition

If no topic argument provided, ask:

Use AskUserQuestion:
```
What DevOps/architecture problem are you brainstorming?
(e.g., "container orchestration strategy", "multi-region DR", "service mesh adoption")
```

Load context:
- Read `production/session-state/active.md`
- Check `docs/decisions/` for related ADRs
- Check `production/review-mode.txt`

---

## Phase 2: Constraint Gathering

Use AskUserQuestion to establish boundaries:

```
Before we explore solutions, let's define constraints:
```

tabs:
  - Cloud Provider & Region (required)
  - Team Size & Skill Level (required)
  - Budget Range (required)
  - Timeline (required)
  - Existing Tech Stack (if any)
  - Compliance Requirements (if any)

---

## Phase 3: Solution Space Exploration

Spawn `architect` via Task to generate 3 approaches.

For each approach, architect provides:
1. **Name** — short memorable name
2. **Description** — 2-3 sentences
3. **Pros** — 3-5 bullet points
4. **Cons** — 3-5 bullet points
5. **Complexity** — Low / Medium / High
6. **Cost** — $ / $$ / $$$
7. **Time to implement** — estimate
8. **Best for** — when to choose this

Review mode check:
- `solo` → architect generates options, no director review
- `lean` → spawn architect only
- `full` → spawn architect, then spawn security-director and sre-director to evaluate each option

---

## Phase 4: Trade-off Matrix

Present a comparison table:

```
| Criterion         | Option A | Option B | Option C |
|-------------------|----------|----------|----------|
| Complexity        |          |          |          |
| Cost              |          |          |          |
| Time to implement |          |          |          |
| Security posture  |          |          |          |
| Operational toil  |          |          |          |
| Team fit          |          |          |          |
| Vendor lock-in    |          |          |          |
```

---

## Phase 5: Direction Selection

Use AskUserQuestion:

```
Based on the analysis above, which direction would you like to explore further?
```

options:
  - Option A — [name]
  - Option B — [name]
  - Option C — [name]
  - Hybrid — combine elements from multiple options
  - None — need more information first

---

## Phase 6: Next Steps

Based on selection, recommend:
- If ready to decide → `/architecture-decision`
- If needs more detail → specific research questions to answer
- If needs cost validation → `/cost-review`
- If security unclear → `/security-review`

Write brainstorm summary to `production/session-logs/YYYY-MM-DD.md`.

---

Verdict: **COMPLETE** — brainstorm complete, direction selected.
Next Steps: Run `/architecture-decision` to formalize the chosen approach into an ADR.
