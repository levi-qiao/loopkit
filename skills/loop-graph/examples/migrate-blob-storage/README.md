# Example: migrate blob storage out of the database

A fully worked, **generic** example — no real project, no secrets. Where [`add-tests-to-cli`](../add-tests-to-cli/) shows the smallest possible run (single goal, three rounds, empty directives), this one shows the parts of the shape that only appear on a longer, riskier task: milestones, a pilot before a cohort-scale operation, a forced convergence round, an owner-only stop, a supervisor directive catching self-reported evidence — and **the non-skippable milestone gate** blocking advancement until the supervisor independently audits and releases the boundary.

## The scenario

`shutterlog` is a fictional photo-journal web app. Uploaded photos live as blobs in its `attachments` database table; the goal is to move them to an S3-compatible object store without breaking a public URL contract:

> New uploads go to the object store; every legacy photo is backfilled and verified complete; `/photos/<id>` keeps resolving for every existing id; then (and only then) the blob column can be dropped.

The run works against a **staging dump** — production credentials are a red line.

## What the interview produced

- **Repo/branch:** `shutterlog` on `feature/object-storage`. Never touch `main`.
- **Milestones:** M1 dual path (new uploads → store, reads fall through store → blob) → M2 backfill, verified complete → M3 cutover + drop the blob column (**owner sign-off — destructive**).
- **Gates:** `pytest tests/test_storage.py -q` (narrow), `pytest -q` + `scripts/smoke_serve.sh` (full — fetches 20 known photo ids, compares bytes).
- **Red lines:** no blob deleted before its object is checksum-verified; the `/photos/<id>` contract is frozen; staging only; no push; a change that reddens a previously-green test is reverted the same round.
- **Owner-only list:** schema DDL (the column drop), anything touching production, lowering a gate.
- **Supervisor:** every 30 min, clean context each tick.

## What happened in the run

The ledger shows eight rounds. Two sequences are worth reading closely:

**The drift catch (Rounds 4–6).** The executor ran the full backfill and recorded M2 as verified — on the evidence of the migration script's **own** "4,812 processed" counter. Inside the executor's context that number looked like proof; the script had printed it, after all. The supervisor, reading the ledger cold, saw self-generated evidence where an independent proof belonged and wrote `D-001` (in `directives.md`): produce a primary-key set diff between the table and a fresh object-store listing, plus a checksum sample. The diff found 3 rows the script had silently dropped — a swallowed per-row exception had counted failures as processed. Round 6 fixes them and proves the diff empty.

**The milestone gate (Rounds 7–8).** After Round 6 closes M2's exit conditions, the executor sets `Milestone gate: pending-audit` and **keeps looping** — it doesn't idle. Round 7 works GAP-001 debt (content-type sniffing for the 41 NULL rows) while parked at the boundary. Between rounds, the supervisor's scheduled tick fires: from clean context it re-runs `verify_backfill.py`, the full test suite, and the smoke script, inspects the diff for undisclosed shortcuts, and — satisfied — appends `D-002` (an acceptance directive releasing the gate). Round 8: the executor reads D-002, flips the gate to `passed`, advances to M3, and immediately hits the owner-only DDL → `owner-blocked`.

## The points

**Self-generated evidence.** The executor wasn't lying in Round 4; it was reasoning from a context that contained the script's cheerful output. A same-context loop would reason from the same evidence. A clean-context supervisor never saw the script run, so "the script says so" carries no weight — only an independent listing does.

**The gate cannot be skipped.** Round 7 shows the executor productively parked: it cannot self-certify milestone completion, but it doesn't stall either — it burns down debt while the supervisor independently verifies the boundary. The gate is a **tracked ledger flag** (not prose the executor can reinterpret), and advancing while it reads `pending-audit` is a red line. This means a milestone boundary always gets a clean-context audit before the run crosses it — even when no human is watching.
