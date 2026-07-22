<!--
graphkit template: directives.md — the ONE-WAY corrections edge.
Seeded near-empty at generation time into the run directory. The supervisor node
appends here; the executor node reads it each round and folds open items into the
round — it never writes this file. History is append-only: entries are never
edited or deleted, only superseded by a later entry.
On a successor run, copy still-in-force STANDING items into the new run's file.
-->

# {{PROJECT}} — Directives (supervisor → executor, one-way)

## STANDING (always in force — carried across runs; treat like red lines)

<!-- Also the home for OWNER PRE-AUTHORIZATIONS decided at interview time: an
     owner-only action the executor MAY do autonomously once an objective evidence
     bar is met (owner retro-reviews). This is what keeps a loop whose own work is
     owner-only (e.g. dropping dead tables) from stalling on propose-and-wait.
     Format: S-001 · PRE-AUTH — <action> is authorized once <checkable evidence bar>; apply via <reversible method>. -->

{{none yet, or items carried over from the previous run — including owner pre-authorizations from the interview}}

## Corrections (numbered, append-only)

<!-- Format: D-001 · <date> — one-line problem → expected action -->

(none yet)
