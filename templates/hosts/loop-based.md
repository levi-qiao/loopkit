<!--
graphkit host adapter — LOOP-BASED hosts (executor + supervisor).
Use when the runtime has no run-to-completion goal: an external loop — a review/follow-up
cycle (Cursor background agent), a slash-command (Claude /loop), cron, or a shell while —
re-invokes the node each round and it resumes from the ledger. Replace {{RUN_DIR}},
{{INTERVAL}}. CLI flags are the official non-interactive entrypoints — verify against your version.
-->

# Loop-based hosts — executor + supervisor

A **loop host** has no goal primitive; something outside re-invokes the node each round.
The node keeps no memory between invocations because the **ledger is the memory** — every
invocation reads it, does one round, writes it back, exits. The loop stops when the ledger
reaches `exit-ready` / `stalled`, or all items are blocked.

## Executor — one round per invocation

Same instruction each time: *"Read `{{RUN_DIR}}/executor.md` and its ledger; do the single
smallest unclosed round; update the ledger; stop."*

| Host | Loop entrypoint (executor) | Notes |
| --- | --- | --- |
| **Cursor** (background agent) | Point the agent at `{{RUN_DIR}}/executor.md`; each round is a **follow-up in that task's chat**: "do the next ledger round". CLI: `cursor-agent -p --force --trust "<one-round instruction>"` in a `while` loop | desktop agent iterates by review/follow-up; `-p` = headless print, `--force --trust` skips dialogs, wrap in `timeout` (can hang) |
| **Claude Code** | `/loop` on `executor.md`, or a `CronCreate` tick | native re-invocation; no shell |
| **Any shell** | `while :; do <agent-cli> "<one-round instruction>"; sleep {{INTERVAL}}; done` | break when the ledger says `exit-ready`; keep stop logic in the ledger, not the shell |

The loop is dumb on purpose — it re-invokes; the executor decides when to stop by writing
the ledger status. Don't push round logic into the shell or the follow-up text.

## Supervisor — a fresh clean context each tick

The supervisor is inherently scheduled: each tick a **new** context reading only durable
state (ledger + `git status`). Never inside the executor's loop, session, or task chat —
that shared context is what the method keeps clean.

| Host | Schedule entrypoint (supervisor) |
| --- | --- |
| **Claude Code** | `CronCreate` off the hour, e.g. `7,37 * * * *`, prompt = `{{RUN_DIR}}/supervisor.md` |
| **Cursor / shell** | a **separate** background agent or `cron`/`while … sleep {{INTERVAL}}` invoking the CLI once on `supervisor.md` — a different process from the executor loop |

Give it a **strong** model (cold-read drift-judging is the hardest call); it fires ~2×/hr
so it stays cheap. It only reads the ledger and appends to `directives.md`; never writes the ledger.

## No runtime at all? You are the loop

Any fresh chat is a host: paste `Read and follow {{RUN_DIR}}/executor.md`, then re-send
"continue" each round. State lives in the ledger, so stopping and resuming loses nothing —
this is just turn-based babysitting; prefer a loop above.
