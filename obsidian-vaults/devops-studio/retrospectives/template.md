# Retrospective: <session or workflow name>

**Date:** YYYY-MM-DD
**Workflow:** <skill used, e.g., /team-new-env staging aws>
**Review Mode:** <full|lean|solo>
**Duration:** <N hours>
**Participants:** <user, agents spawned>

---

## Context

<What was the goal? What triggered this workflow?>

---

## What Went Well

- <positive observation 1 — specific, not generic>
- <positive observation 2>
- <positive observation 3>

---

## What Went Poorly

- <friction point 1 — what slowed us down>
- <friction point 2>
- <friction point 3>

---

## Gates Performance

| Gate | Verdict | Value Added? | Friction? |
|------|---------|--------------|-----------|
| ARCH-DECISION | APPROVE/CONCERNS/REJECT | yes/no | yes/no |
| SEC-BASELINE | | | |
| COST-ESTIMATE | | | |
| ARCH-REVIEW | | | |
| SRE-READY | | | |
| SEC-SCAN | | | |

Gates that blocked without clear reason — candidates for removal or mode downgrade.

---

## Agent Performance

| Agent | Role | Useful? | Needed? |
|-------|------|---------|---------|
| architect | | yes/no | yes/no |
| security-director | | | |
| terraform-spec | | | |
| ... | | | |

---

## Time Breakdown

| Phase | Estimated | Actual | Delta |
|-------|-----------|--------|-------|
| 1. Context gathering | | | |
| 2. Architecture design | | | |
| ... | | | |

Comparison: same task without DevOps Studio would take ~<N> hours of manual coordination.

---

## Action Items

| # | Item | Owner | Due |
|---|------|-------|-----|
| 1 | | | |
| 2 | | | |

Typical items after retro:
- Update rules in `.claude/rules/<domain>/rules.md` based on learnings
- Add/remove gate based on signal-to-noise ratio
- Refine skill phases that dragged
- Update scenario doc if new pattern discovered

---

## Lessons for Next Time

<2-3 specific things to change in the framework itself, not in the infrastructure being built>

---

## Framework Changes Proposed

- [ ] <e.g., "Add a new gate: NETWORK-REVIEW for multi-region workloads">
- [ ] <e.g., "Merge COST-ESTIMATE into ARCH-DECISION — too much context switching">
- [ ] <e.g., "Add parallel spawn for Phase X in /team-migration">
