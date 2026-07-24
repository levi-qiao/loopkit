<!--
graphkit template: ledger.md — THE SINGLE SCOREBOARD (shared state between nodes).
The executor node rewrites this every round; the supervisor node only reads it.
Keep it COMPACT: on a fresh-context host it is re-read every round, so its size is a
per-round token tax — an unbounded Rounds log makes each round cost more than the last
(O(n²) over a run). Hard rule: keep only the last {{KEEP_ROUNDS|5}} round entries here;
when a new round pushes past that, move the oldest into `rounds-archive.md`
(append-only, never re-read each round). Carry durable facts in the "Starting
snapshot" below; update the durable sections in place, never by appending.
-->

# {{PROJECT}} — graphkit Ledger

> This ledger is the run's only scoreboard. Authority order: {{AUTHORITY_LAYERS}} > this ledger. Environment facts: `ops.md`. Corrections from the supervisor: `directives.md`.
> Rounds log holds only the last {{KEEP_ROUNDS|5}} rounds; older rounds live in `rounds-archive.md` beside this file (append-only) — don't open it unless debugging. Everything a fresh round needs is the snapshot + durable sections below.

## Status header

Current milestone: {{M1 or "single goal"}} | Round: 0 (starts at 1) | Last round net lines: —
Smallest unclosed item: {{FIRST_ITEM}}
Convergence: fires at {{CONVERGE_EVERY|5}} rounds since last **or** +{{NET_LINE_CAP|400}} net lines, whichever first | since last: 0 rounds / +0 net | **next round converges: no**
Milestone gate: `open`   <!-- open | pending-audit | passed. Only meaningful for multi-milestone runs with a supervisor; single-goal / no-supervisor runs leave it `n/a`. The executor sets it `pending-audit` when it closes the current milestone's last exit condition (promotion requested, executor keeps looping — does NOT advance); the supervisor re-verifies the boundary and, on pass, appends an acceptance directive; the executor flips it `passed` only when that directive lands, and only then starts the next milestone. Advancing while this is `pending-audit` is a red line. -->
Run status: `active`   <!-- active | paused | exit-ready | stalled | closed. A terminal status (exit-ready/stalled/closed) is the signal for both loops to stop themselves. Note: `pending-audit` on the Milestone gate is NOT a terminal Run status — the executor keeps looping. -->

---

## Starting snapshot (carried-forward — replaces bulk history)

{{SNAPSHOT — everything a fresh executor needs and nothing it doesn't:
- what's already done (closed milestones, with one-line evidence),
- current state of the in-progress milestone,
- baseline metric anchors (for reference, not to be passed off as current measurements),
- working-tree alignment (branch tips, any uncommitted state to reconcile first),
- still-in-force constraints distilled from any prior directives.
Keep it tight.}}

---

## Gate scoreboard

| Gate | Status | Evidence / next action |
| --- | --- | --- |
| {{exit condition 1}} | open / in-progress / closed / owner-blocked | {{...}} |

## Metric snapshot (if the goal is metric-driven)

| Metric | Baseline | Current |
| --- | --- | --- |
| {{metric}} | {{baseline}} | {{measured or "pending"}} |

## owner-blocked (genuinely case-by-case human-decision items — log the one-line question, don't decide)

<!-- Only items with NO standing authorization. If a STANDING pre-authorization in
     directives.md covers the action and its evidence bar is met, execute it — it does
     not belong here. This list is for calls that truly need the owner case by case. -->

{{none yet, or list}}

## Debt & gap register (log every gap here; never silently fix or ignore)

| ID | Priority | Milestone | One line |
| --- | --- | --- | --- |
| GAP-001 | P? | {{M?}} | {{...}} |

## Rounds log — last {{KEEP_ROUNDS|5}} only (older → `rounds-archive.md`)

<!-- ONE TERSE LINE per round — this section is re-read every round, so keep it small.
When appending would exceed {{KEEP_ROUNDS|5}} lines, cut the oldest and append it
verbatim to `rounds-archive.md`. Never let history pile up here. Line format: -->
<!-- - R<n> <date> | <item> | gate: <result> | net +x/-y | <VLM/metric delta, or —> | open: <what's left, or —> | next: <next item> -->

<!-- You MAY keep only the CURRENT round as a short multi-line block when it carries
detail the supervisor must see this tick (e.g. a promotion request's evidence);
collapse it to the one-line form once the next round starts. -->
