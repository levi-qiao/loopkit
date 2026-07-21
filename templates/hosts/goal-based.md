<!--
graphkit host adapter — GOAL-BASED hosts (executor node).
Use when the runtime owns a long-running "goal" primitive that runs to completion and
raises its own done signal (Grok /goal; Codex delegated task). Replace {{RUN_DIR}}.
Only the executor runs in the goal; the supervisor is always a separate host (loop-based.md).
-->

# Goal-based hosts — executor node

A **goal host** takes one task, keeps it alive on its own, and runs round after round to
completion without being re-invoked. The launcher is a **thin pointer** at the run files,
never a paste of the whole prompt — so a restart is the same one-liner and the goal's
progress UI can't drift from the ledger.

Bind the host's completion to the ledger, not to "gates are green": mark the goal **done
only** when the ledger holds a promotion request or run status `exit-ready`. Milestone
items still open = not done.

## Grok `/goal`

Paste into Grok `/goal` (replace `{{RUN_DIR}}`):

```text
/goal You are the executor node of a graphkit run. Obey ONLY these files; do not fold
their contents into this goal text — re-read them each round.
  instructions : {{RUN_DIR}}/executor.md
  scoreboard   : {{RUN_DIR}}/ledger.md      (single source of truth)
  corrections  : {{RUN_DIR}}/directives.md  (read-only to you)
  environment  : {{RUN_DIR}}/ops.md
Run continuously: each round = smallest unclosed ledger item → verify same round →
update ledger → start the next round. Do NOT stop to ask "shall I continue?"; keep going
until a stop condition in executor.md fires. If the session ends, a new /goal with this
same block resumes from the ledger. completed=true ONLY when the ledger has a promotion
request or run status `exit-ready`. You are ONLY the executor: never edit directives.md,
never act as supervisor.
```

## Codex delegated task (desktop / cloud / `codex exec`)

Codex runs the task to completion in an **isolated sandbox off your GitHub repo**, then
returns a diff/PR. Two consequences specific to this host:

- **The run directory must be committed.** The sandbox only sees committed repo state, so
  `.graphkit/<slug>/` (ledger, directives, ops) must be in git, and the executor must
  **commit its ledger update each round** or the next round starts blind. Confirm commit
  authorization in the interview before choosing this host.
- **Done = the ledger, not the diff.** A returned diff with milestone items still open is
  not completion; re-delegate a follow-up "continue from the ledger" task.

Task prompt (desktop "delegate a task", or `codex exec "<this>"`):

```text
You are the executor node of a graphkit run. Read and obey {{RUN_DIR}}/executor.md and its
ledger {{RUN_DIR}}/ledger.md (single source of truth); read {{RUN_DIR}}/directives.md and
{{RUN_DIR}}/ops.md. Do rounds — smallest unclosed ledger item → verify → update AND commit
the ledger — until a stop condition in executor.md fires (milestone exit-ready / blocked /
stall / red line). Do not edit directives.md; do not act as supervisor.
```
