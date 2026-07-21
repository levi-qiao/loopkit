# Example: migrate blob storage out of the database

A second fully worked, **generic** example — no real project, no secrets. Where [`add-tests-to-cli`](../add-tests-to-cli/) shows the smallest possible run (single goal, three rounds, empty directives), this one shows the parts of the shape that only appear on a longer, riskier task: milestones, a pilot before a cohort-scale operation, a forced convergence round, an owner-only stop — and a supervisor directive actually firing.

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

The ledger in this folder shows six rounds. The one worth reading closely is Round 4: the executor ran the full backfill and recorded M2 as verified — on the evidence of the migration script's **own** "4,812 processed" counter. Inside the executor's context that number looked like proof; the script had printed it, after all. The supervisor, reading the ledger cold, saw self-generated evidence where an independent proof belonged and wrote `D-001` (in `directives.md`): produce a primary-key set diff between the table and a fresh object-store listing, plus a checksum sample. The diff found 3 rows the script had silently dropped — a swallowed per-row exception had counted failures as processed. Round 6 fixes them, proves the diff empty, and stops at the M3 gate for the owner's sign-off, because dropping a column is not the graph's call to make.

## The point

The executor wasn't lying in Round 4; it was reasoning from a context that contained the script's cheerful output. That is exactly the failure a same-context loop cannot catch — the evidence that misled the worker is the evidence the reviewer would reason from too. A clean-context node never saw the script run, so "the script says so" carries no weight; only an independent listing does. One directive, one round of honest re-verification, and a count-match that would have shipped 3 missing photos became an empty set diff instead.
