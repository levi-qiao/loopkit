# The loopkit methodology

Every rule here exists to prevent a specific, observed failure mode of long-running agent loops. This document explains the *why* so you can adapt the rules without breaking them.

## 1. One scoreboard (the ledger)

**Rule:** a single `loop-ledger.md` is the only source of truth. When code, docs, and ledger disagree, the ledger is fixed first, then the code.

**Prevents:** *state fragmentation.* Without one canonical place, round 30 rediscovers a decision made in round 5, re-opens a closed question, or builds a thing that already exists. The ledger is small on purpose — it's read every round, so it must stay cheap. When it grows, archive old rounds and carry forward only load-bearing facts in a "starting snapshot".

## 2. One item per round → verify same round → update ledger

**Rule:** each round picks the single smallest unclosed item, implements it, verifies it with the narrowest test/gate/smoke, and records the result — all in one round.

**Prevents:** *batching debt and fake progress.* Batching hides which change broke a gate. "I'll test later" becomes "never". Verifying in the same round means "done" always means "verified to closure", not "written".

## 3. Forced convergence rounds

**Rule:** every Nth round (default 5) does zero new features — only deletion, de-duplication, interface tightening; net lines ≤ 0. A single round adding more than the net-line cap (default 400) forces the next round to converge.

**Prevents:** *monotonic growth.* Agents add far more readily than they remove. Without a periodic forcing function, the codebase only grows, and complexity compounds until the loop can no longer reason about it. Convergence rounds are where the loop pays down what it borrowed.

## 4. Register-then-defer

**Rule:** any gap found mid-round is logged in the ledger's debt register with a priority and queued for a later round. Never silently patched now; never dropped.

**Prevents:** two opposite failures at once — *scope explosion* (fixing every gap you trip over turns one item into ten) and *silent loss* (noticing a bug and forgetting it). Registering makes gaps visible and schedulable without derailing the current item.

## 5. No speculative building

**Rule:** before adding any endpoint / module / protocol / config / pool, register its real consumer in the ledger. No consumer → don't build. No compat double-paths, no v1/v2 coexistence, no parallel error systems, no second delivery channels.

**Prevents:** *"might need it later" bloat* and *two-truths architecture.* The most expensive drift is a second way to do something that already has a way. Requiring a named consumer kills speculative abstractions at the door.

## 6. Stop conditions

**Rule:** three ways to stop cleanly —
- **Milestone exit all-green** → write a promotion request, stop for human sign-off.
- **All remaining items blocked** → stop with an escalation report.
- **Two rounds with no ledger/metric change** → stop with a stall diagnosis.

And one way to stop hard: **any red-line violation halts the loop immediately.**

**Prevents:** *spinning.* A loop with no stop condition burns tokens re-touching the same untouchable items. Explicit stops turn "stuck" into a signal instead of silent churn.

## 7. Red lines

**Rule:** a short list of non-negotiables that halt the loop: no push without authorization, no destructive git on others' work, no secrets/real data in code/logs/commits, frozen contracts stay frozen, metrics only go up (a regressing change is rolled back the same round).

**Prevents:** *irreversible or unsafe actions.* These are the things you cannot undo cheaply — a bad push, a leaked key, a silently lowered accuracy bar. They are absolute, not heuristics.

## 8. Supervisor separation

**Rule:** if you run a supervisor, it observes, checkpoint-commits authorized clean work, and corrects drift **only through a directives file the executor reads** — never by editing the ledger the executor is actively writing. Human-only decisions are escalated, not guessed.

**Prevents:** *write contention and authority confusion.* Two agents editing the same scoreboard corrupt it. The directives file is a one-way channel: supervisor writes, executor reads. Checkpoint commits are the supervisor's job precisely because commit authorization is a red line for the executor.

---

## Tuning

The numbers (convergence every 5, 400-line cap, 30-minute tick) are defaults, not dogma. Tune them in the interview to your project's rhythm. What must not change is the *shape*: a single scoreboard, one-item rounds with same-round verification, a forcing function against growth, visible-and-deferred gaps, hard stop conditions, and absolute red lines. Remove any one of those and the loop drifts.
