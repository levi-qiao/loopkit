<!--
loopkit template: loop-ledger.md — THE SINGLE SCOREBOARD.
The executor rewrites this every round. Keep it COMPACT: it is read every round,
so bloat costs tokens. When history piles up, archive the old rounds to a separate
file and carry only load-bearing facts forward in the "Starting snapshot" below.
-->

# {{PROJECT}} — Loop Ledger

> This ledger is the loop's only scoreboard. Authority order: {{AUTHORITY_LAYERS}} > this ledger. Environment facts: `ops-and-environment.md`.
> When rounds accumulate, archive to `loop-ledger-archive-<date>.md` and keep only the snapshot below. Don't open archives unless debugging.

## Status header

Current milestone: {{M1 or "single goal"}} | Round: 0 (starts at 1) | Last round net lines: —
Smallest unclosed item: {{FIRST_ITEM}}
Loop status: `active`

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

## owner-blocked (human-decision items — log the one-line question, don't decide)

{{none yet, or list}}

## Debt & gap register (log every gap here; never silently fix or ignore)

| ID | Priority | Milestone | One line |
| --- | --- | --- | --- |
| GAP-001 | P? | {{M?}} | {{...}} |

## Rounds log

<!-- Append one block per round. Format: -->
<!--
### Round N — <date>
- **Item**: ...
- **Gate**: <commands + result>
- **Change**: <what + why, 1-2 lines>
- **Verify**: <narrowest test/smoke + result>
- **Net lines**: +x/-y
- **Open**: <what's still not closed on this item>
- **Next**: <the next smallest item>
-->
