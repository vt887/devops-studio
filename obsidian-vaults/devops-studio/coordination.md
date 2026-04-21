# Agent Coordination Rules

Як агенти DevOps Studio координуються між собою. Читається разом з `delegation-map.md` і `.claude/gates/gate-definitions.md`.

---

## 1. When to Parallelize

Спавнити агентів паралельно (single message, multiple Task calls) тільки якщо:

- Outputs незалежні одне від одного (жоден з них не читає output іншого).
- Розподіл роботи за доменами, не за кроками.
- Немає shared state, який треба оновити послідовно.

Типові паралельні пари:
- `terraform-spec` + `k8s-spec` (різні технологічні стеки)
- `security-scanner (IaC)` + `security-scanner (K8s)` + `security-scanner (secrets)` (різні scan targets)
- `architect` + `security-director` + `sre-director` на `/design-review` (незалежні перспективи)

Ніколи не паралелити:
- `security-scanner` і `security-director` — director читає scanner output.
- `architect` і specialists, яким він делегує — specialists чекають на ADR.

---

## 2. When to Escalate

Specialist має escalate до director якщо:

- Рішення виходить за scope специалізації (k8s-spec бачить IAM policy vs architect decision).
- Знайдено security concern, не описаний в ADR/baseline.
- Вимагається override правила з `.claude/rules/<domain>/rules.md` — ніколи не override самому.
- Не вистачає context-у з попередньої фази (gate не пройшов або output відсутній).

Escalation — не відмова від задачі. Це `BLOCKED` верdict з причиною, і продовження після відповіді від director-а.

Director має escalate до користувача якщо:

- Два director-а не згодні (див. Conflict Resolution у delegation-map.md).
- Cost >20% over budget.
- Security verdict = REJECT, але користувач просить proceed.
- SLO compromise, який вимагає business decision.

---

## 3. Context Handoff Format

Коли агент A спавнить агента B через `Task`, prompt B **обов'язково** містить:

```
[Context from A]
- Prior decision: <ADR-NNN or session-log entry>
- What's already done: <files/sections complete>
- Your deliverable: <exact output path>
- Rules to follow: <.claude/rules/<domain>/rules.md>
- Gate B must produce: <GATE-ID>
- Escalate back if: <specific conditions>
- Review mode: <full|lean|solo>
```

Ніколи не спавнити агента з prompt-ом типу "зроби наступну фазу" — завжди explicit handoff.

---

## 4. Gate Check Protocol

Перед тим як orchestrator продовжує до наступної фази:

1. Прочитати verdict з попередньої Task call.
2. Парсити `[GATE-ID]: VERDICT_TYPE` з output-у.
3. Логувати в `production/session-logs/YYYY-MM-DD.md` через `post-gate-check.sh` hook.
4. Перевірити дію:
   - `APPROVE` → continue
   - `CONCERNS` → log concern, ask user чи proceed
   - `REJECT` → loop back до phase, що створила проблему, або abort
5. Оновити `production/session-state/active.md` з поточною фазою.

Review mode modifier:
| Mode | Behavior |
|---|---|
| `full` | Директор спавниться, формальний verdict |
| `lean` | Self-check проти checklist для non-critical gates; directors лише для ARCH-DECISION і SEC-BASELINE |
| `solo` | No spawn, log self-check |

---

## 5. Session State Ownership

Файли, які **тільки orchestrator** (DevOps Studio entry point) оновлює:

- `production/session-state/active.md` — current phase, skill, decisions
- `production/session-logs/YYYY-MM-DD.md` — audit trail

Файли, які агенти створюють/оновлюють:

- `docs/decisions/adr-*.md` — architect
- `docs/decisions/security-baseline-*.md`, `postmortem-*.md`, `cost-estimate-*.md` — relevant director
- `docs/decisions/slo-*.md` — sre-director
- `docs/runbooks/*.md` — sre-director, k8s-spec, terraform-spec
- `terraform/`, `k8s/`, `monitoring/`, `.github/workflows/`, `gitops/` — відповідні specialists

Правило: якщо агент пише в файл, що йому не належить — це bug. Escalate замість write.

---

## 6. Error Recovery Protocol

Кожен team-* skill має обробляти BLOCKED агентів:

1. Продовжувати інші незалежні phases якщо можливо.
2. Завжди produce **partial report** з чітким списком completed / blocked / skipped.
3. Blocked phase → log причину в session log з `BLOCKED:` prefix.
4. Надати користувачеві AskUserQuestion з опціями: [resolve blocker now, accept partial and continue, abort].

Не падати тихо — partial output кращий за silent abort.

---

## 7. Memory and Context

Агенти мають `memory: project` — тобто зберігають context в проектному scope. Не в user scope, не в session scope.

Що це означає практично:
- Після `/compact` агент має re-read session state перед продовженням.
- ADR-и і session logs є source of truth — якщо agent's "memory" конфліктує з файлом, файл виграє.
- Між sessions агент не зберігає нічого — тільки те, що комітнуте в репо.

---

## 8. Human-in-the-Loop Checkpoints

AskUserQuestion є **обов'язковим** на:

- Вибір між options (alternatives in ADR, mitigation strategies)
- Production-affecting action (apply, deploy, rollback, traffic shift)
- Budget override (>20% over)
- Security override (accepting CONCERNS або REJECT)
- Gate override ("proceed despite REJECT with justification")

AskUserQuestion **не треба** на:

- Pure information gathering (читання файлів, grep)
- Within-scope generation (specialist пише manifest по затвердженому ADR)
- Internal phase transitions (Phase 2 → Phase 3 в рамках того ж skill-а)

Золоте правило: якщо дія незворотна або видна поза твоєю machine — запитай.
