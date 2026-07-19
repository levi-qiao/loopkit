---
name: loopkit
description: Run a long-horizon coding task as a self-supervised agentic loop. Interviews the user to generate a rigorous loop prompt plus a single-source-of-truth ledger, then optionally stands up a supervisor that checkpoint-commits and corrects drift on a schedule. Use when the user wants a durable multi-round autonomous loop that stays on-spec — clear goal, verifiable gates, anti-bloat discipline, explicit red lines — instead of a one-shot change. Bilingual EN / 中文.
---

# loopkit — Agentic Loop + Supervisor

## What this skill does

Turns a vague, long-horizon request ("make this project production-ready", "get accuracy above baseline", "finish the migration") into a **disciplined autonomous loop** that a coding agent can run for many rounds without drifting, plus an optional **supervisor** that watches it and corrects course.

It produces four artifacts from a short interview:

1. **`loop-prompt.md`** — the executor prompt. One task book, one cadence, hard anti-bloat rules, explicit stop conditions and red lines.
2. **`loop-ledger.md`** — the single source of truth / scoreboard the executor rewrites every round.
3. **`ops-and-environment.md`** — durable environment facts (build commands, credentials policy, data policy) the executor consults but doesn't re-derive.
4. **`monitor-tick.md`** *(optional)* — the supervisor prompt, fired on a schedule to checkpoint-commit clean work and inject corrections.

The core idea: **the ledger is the only scoreboard**, the executor does **one item per round → verify → update ledger**, and drift is prevented by rules the executor cannot rationalize around (register-then-defer gaps, forced convergence rounds, net-line caps, red lines that halt the loop).

## When to use it

- The task spans many rounds and the user won't babysit each one.
- Success is verifiable (tests, gates, metrics) — the loop needs a definition of "done" it can check itself.
- There's a real risk of scope creep, half-finished "looks done" work, or the agent quietly changing contracts / lowering the bar.

Do **not** use it for a one-shot edit, or when success can't be verified without a human every time — say so and suggest a plain task instead.

## How to run it

### Step 1 — Interview (fill the blanks, don't assume)

Ask the user for exactly these, in order. Skip a question only if the answer is already unambiguous from context. Present tradeoffs; don't silently pick.

1. **Repos & branches.** Which repo(s), which branch each. Confirm what must never be touched (other people's uncommitted work, `main`, remote DBs).
2. **North Star.** The goal in one sentence, and — critically — **how it is verified**. Push until each goal has a checkable definition ("tests pass", "metric ≥ baseline", "gate green"), not "make it work".
3. **Milestones (optional).** If the work has ordered phases, list them M1→Mn with an **exit condition** each. If it's a single goal, skip — one milestone is fine.
4. **Gates.** The exact per-repo verification commands (test / lint / build). These become the every-round gate. If a build needs special flags (settings file, env), capture them for `ops-and-environment.md`.
5. **Red lines.** Non-negotiables that halt the loop if violated: no push without authorization, no destructive git on others' work, no secrets/real data in code/logs/commits, frozen contracts, "metrics only go up", etc.
6. **Commit authorization.** May the loop commit? Push? Or does a human/supervisor handle commits? (Default: loop implements + verifies; commits are a separate authorized step.)
7. **Supervisor?** Do they want a scheduled monitor that checkpoint-commits and corrects drift? If yes, at what interval (default 30 min)?

For anything you can reasonably decide from context, decide it and state the assumption. For anything genuinely the user's call (data policy, DB access, lowering a metric bar), it becomes a red line or an `owner-blocked` item — never decide it silently.

### Step 2 — Generate artifacts

Fill the templates in `templates/` with the interview answers:

- `templates/loop-prompt.md` → the user's `loop-prompt.md`
- `templates/ledger.md` → the user's `loop-ledger.md` (seed the status header, gate scoreboard, and an empty rounds log)
- `templates/ops-and-environment.md` → only if there are non-trivial build/env/data facts worth pinning
- `templates/monitor-tick.md` → only if they want a supervisor

Write them to a location the user picks (default: a `loop/` folder beside the target repos). Keep the ledger **compact** — it is read every round; bloat costs tokens. Carry only load-bearing history forward.

### Step 3 — Start the executor

Hand the user the generated `loop-prompt.md` and tell them to launch it in a **fresh agent context** (a new session, or their loop mechanism). The prompt points at the ledger + ops file, so the executor is self-contained.

### Step 4 — Start the supervisor (if chosen)

Schedule `monitor-tick.md` on the chosen interval. In Claude Code this is `CronCreate` with a cron like `7,37 * * * *` (every 30 min, off the :00/:30 marks so fleets don't stampede). The supervisor:

- reads the ledger + `git status` of each repo,
- checkpoint-commits clean, gate-green, complete work (never half-written state), local-only unless push is authorized,
- **corrects drift only through a file the executor reads (never by editing the ledger the executor is actively writing)** — an `owner-directives.md` the executor consults each round,
- surfaces must-decide gaps to the human instead of guessing.

## The rules that make it work (encoded in the templates)

- **One scoreboard.** The ledger is the only source of truth. Code / docs / ledger conflict → fix the ledger first.
- **One item per round → verify same round → update ledger.** No batching, no "I'll test later".
- **Forced convergence.** Every Nth round (default 5th) does zero new features — only delete dead code, merge duplication, tighten interfaces; net lines ≤ 0. A single round adding > ~400 net production lines forces the next round to converge.
- **Register-then-defer.** Any gap found mid-round is *logged in the ledger's debt register*, never silently fixed on the side and never ignored. It gets queued by priority.
- **No speculative building.** New endpoint/module/abstraction/pool requires a named real consumer in the ledger first. No compat double-paths, no v1/v2 coexistence, no parallel error systems.
- **Stop conditions.** Milestone exit all-green → write a promotion request and stop for human sign-off. All remaining items blocked → stop with an escalation report. Two rounds with no ledger/metric change → stop with a stall diagnosis. Any red line violated → stop immediately.
- **Supervisor never fights the executor.** It steers via the directives file, commits on authorization, and escalates human-only calls.

## Files in this skill

- `templates/` — the four fill-in artifacts.
- `docs/methodology.md` — the deep dive (why each rule exists, failure modes it prevents).
- `examples/add-tests-to-cli/` — a fully worked, generic example.

## 中文说明

本技能把"让这个项目达到生产标准 / 把精度做到基线以上 / 完成迁移"这类**长周期、多轮**的模糊任务，转成一套**能自治运行、不漂移**的循环，并可选配一个**监督器**定时巡检纠偏。

通过一轮简短访谈（仓库与分支、可验证的总目标、可选里程碑及出口条件、每轮门禁命令、红线、提交授权、是否要监督器及间隔），生成四份产物：`loop-prompt.md`（执行提示词）、`loop-ledger.md`（唯一记分板）、`ops-and-environment.md`（环境事实）、`monitor-tick.md`（监督器，可选）。

核心机制：**台账是唯一真相**；执行方**一轮只做一项 → 当轮验证 → 更新台账**；靠执行方无法绕过的规则防漂移（发现即登记不静默修、第 N 轮强制收敛、单轮净增行数上限、违反红线即停）。监督器**只经执行方会读的 directives 文件纠偏，绝不编辑执行方正在写的台账**，按授权做 checkpoint 提交，必须人类决定的事项上报而非擅自裁决。

面试用的问题、生成步骤、启动执行方与监督器的方式，与上文英文一致。访谈时**不要臆测**：能从上下文确定的自行决定并说明假设；真正需要用户拍板的（数据策略、数据库访问、降低指标门槛）变成红线或 `owner-blocked` 项，绝不擅自替用户决定。
