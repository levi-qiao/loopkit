# Example: harden a CLI's date parser

A fully worked, **generic** example — no real project, no secrets. It shows what loopkit generates from an interview and what the ledger looks like a few rounds in.

## The scenario

`taskcat` is a fictional to-do CLI. Its natural-language date parser (`"next fri"`, `"in 3 days"`, `"2026-07-31"`) is the buggy, under-tested part. The goal:

> Bring `taskcat`'s date parser to green: a test for every documented input form, all passing, no regressions elsewhere.

Single goal, no milestones. The user authorized **local commits** (no push), and wanted a **supervisor** every 30 minutes.

## What the interview produced

- **Repo/branch:** `taskcat` on `feature/date-parser-tests`. Never touch `main`.
- **North Star:** every input form in `docs/date-formats.md` has a passing test; `pytest` green; no other suite regresses.
- **Gate:** `pytest -q` (full) and `pytest tests/test_dates.py -q` (narrow).
- **Red lines:** no push; no reformatting untouched code; a change that reddens any previously-green test is reverted the same round.
- **Commit auth:** loop implements + verifies; the supervisor commits clean green rounds locally.
- **Supervisor:** yes, every 30 min.

The generated `loop-prompt.md` and `loop-ledger.md` are in this folder. The ledger shows three rounds already run — including a **register-then-defer** in Round 2 (a timezone bug found while writing a test, logged as `GAP-002` instead of fixed on the spot) and that gap being picked up in Round 3.

## The point

Notice what the loop *didn't* do: it didn't add a config system for date formats, didn't refactor the parser "while it was in there", and didn't fix the timezone bug the instant it saw it. It logged it, finished the item in front of it, and scheduled the fix. That restraint is the whole game.
