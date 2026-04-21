---
name: cost-review
description: "Cloud cost analysis and optimization review. Spawns cost-spec to analyze current spend, identify waste, recommend optimizations, and produce FinOps report."
argument-hint: "[scope: all|compute|storage|network|specific-service] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Task, AskUserQuestion
agent: cost-spec
---

## /cost-review [scope]

Cloud cost analysis and FinOps optimization workflow.

---

## Phase 1: Cost Review Scope

Use AskUserQuestion:

```
Cost review scope:
```

tabs:
  - Cloud Provider & Account
  - Time Period (last 30/60/90 days)
  - Scope (all resources / specific services / new architecture)
  - Cost Anomalies (any unexpected spikes to investigate?)
  - Budget Target (what's the monthly budget?)
  - Optimization Priority (cost reduction / performance / reserved vs on-demand)

---

## Phase 2: Current State Analysis

Spawn `cost-spec` via Task.

Cost specialist reviews:
- Current monthly spend by service category
- Top 10 most expensive resources
- Underutilized resources (CPU < 20%, memory < 30%)
- Unattached storage volumes
- Idle load balancers
- Data transfer costs
- Reserved Instance / Committed Use coverage percentage

Read Terraform configs to understand resource inventory:
- Scan `terraform/` directory for resource types and counts
- Identify instance types in use

---

## Phase 3: IaC Cost Estimation (if applicable)

If Terraform files exist, cost-spec runs Infracost analysis:

```markdown
## Infracost Analysis
Resource: <name>    Monthly: $<cost>
Resource: <name>    Monthly: $<cost>
...
Total estimated monthly cost: $<total>
```

---

## Phase 4: Optimization Recommendations

Cost specialist produces recommendations:

```markdown
## Optimization Opportunities

### Quick Wins (implement in < 1 week)
1. <recommendation> — Estimated savings: $<amount>/month
2. <recommendation> — Estimated savings: $<amount>/month

### Medium Term (1-4 weeks)
1. <recommendation> — Estimated savings: $<amount>/month

### Strategic (1-3 months)
1. Reserved Instances/Savings Plans — Estimated savings: $<amount>/month
   Recommendation: X% coverage, <1yr/3yr> term
```

---

## Phase 5: Tagging & Cost Allocation Review

Cost specialist checks:
- Are all resources tagged with required tags?
- Can cost be allocated by team/service/environment?
- Are budget alerts configured?

Gate: COST-ESTIMATE (if this is for a new architecture)

---

## Phase 6: Cost Report

Produce cost report:

```markdown
# Cost Review Report

**Date:** YYYY-MM-DD
**Period:** <time period>
**Cloud Provider:** <provider>

## Current Spend
Total Monthly: $<amount>
vs. Budget: <over/under/at> by $<delta>

## Top Cost Drivers
1. <service> — $<amount>/mo (<percent>%)
2. <service> — $<amount>/mo (<percent>%)

## Waste Identified
<list of unused/underutilized resources>

## Savings Opportunities
Total potential savings: $<amount>/month
- Quick wins: $<amount>/month
- Reserved/Committed: $<amount>/month

## Recommended Actions
Priority 1: <action> — Owner: <team>
Priority 2: <action> — Owner: <team>
```

Write to `docs/decisions/cost-review-YYYY-MM-DD.md`.

---

Verdict: **COMPLETE** — cost review complete.
Next Steps: Implement quick wins, schedule Reserved Instance purchases, set up budget alerts.
