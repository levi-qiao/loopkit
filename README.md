<div align="center">

# 🛰️ graphkit

**Run a long coding task as a small graph of agent nodes — not one drifting loop.**

A [Claude Code](https://claude.com/claude-code) skill that turns *"make this production-ready"* into an **executor node** that does the work and a **clean-context supervisor node** that watches it from *outside* the executor's context window and corrects drift before it compounds.

*graphkit is **graph engineering** made concrete — the shift from tuning one agent loop to wiring specialized agent roles into a graph. Two roles today, more on the way.*

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
![Claude Code Skill](https://img.shields.io/badge/Claude%20Code-Skill-8A2BE2)

English · [简体中文](README.zh-CN.md)

</div>

---

## The problem

Hand an agent a big, vague goal — *"get this repo to production quality"*, *"push accuracy above baseline"*, *"finish the migration"* — and over dozens of rounds it drifts:

- it **scope-creeps**: new abstractions, v2 endpoints, "flexible" config nobody asked for;
- it fakes **"looks done"**: tests with no production call site, features that compile but do nothing;
- it quietly **lowers the bar**: changes a frozen contract, regresses a metric, "improves" adjacent code;
- it **loses the thread**: no single source of truth, so round 30 contradicts round 5.

And here's the trap: **the agent can't catch this in itself.** It's running *inside the same context that drifted* — the polluted history that made it cut the corner is the history it reasons from. Ask it "are you still on-spec?" and it will confidently say yes. So you end up babysitting every round anyway.

## The idea: from loop engineering to graph engineering

**Loop engineering** is what most of us do today: take one long-lived agent loop and try to make it smarter — better prompts, more reminders, a bigger context window. It plateaus, because the loop's own history is the thing corrupting its judgment.

**Graph engineering** is the alternative: design a small graph of *specialized agent roles*, each booting with its own clean context, connected only by durable, inspectable state. graphkit is that idea made concrete for one scenario — long-horizon coding — starting with the smallest useful graph, two roles:

- 🛠️ **Executor node** — does the work, one item per round, against a single ledger.
- 🛰️ **Supervisor node** — boots with a **fresh, clean context every tick**, reads *only* the ledger + git tree, and judges the run from the outside — the way a reviewer would. It catches the drift the executor structurally *can't* see in itself, because it was never in the room when the corner was cut.

Two roles today; the graph is designed to grow — see the [roadmap](#roadmap-more-node-roles).

The nodes talk only through inspectable state — a ledger, a git tree, a one-way directives file — so the discipline is baked into the wiring, not into hoping the agent stays honest:

- 🧾 **One scoreboard.** A single `ledger.md` is the only source of truth. Code, docs, and ledger disagree → fix the ledger first.
- 🎯 **One item per round → verify same round → update ledger.** No batching, no "I'll test later."
- 🧹 **Forced convergence.** Every 5th round adds zero features — only deletes dead code and tightens interfaces (net lines ≤ 0). A round that adds >400 net lines forces the next to converge.
- 📌 **Register-then-defer.** Every gap found mid-round is *logged*, never silently patched, never ignored.
- 🚧 **Red lines that halt the run.** No push without authorization, no destructive git on others' work, no secrets in commits, frozen contracts stay frozen, metrics only go up.
- 🛰️ **Clean-context supervisor.** A scheduled node checkpoint-commits clean work and corrects drift — and wasteful method, like a full-cohort run with no pilot — **through a one-way directives file — never by editing the ledger the executor is writing, and never by sharing its context.** It decides by default: only a short owner-only list ever escalates to you, so the run doesn't stall waiting for a human.

> **Graph-structured agents without a framework.** No LangGraph, no Python runtime, no orchestration server — the nodes and edges are plain Markdown files a coding agent already understands.

## How it works

```mermaid
flowchart LR
    U([You]) -->|"/graphkit"| I[Interview:<br/>goal · gates · red lines]
    I --> G[Generate the graph]
    G --> EX[executor.md]
    G --> LG[ledger.md]
    G --> DIR[directives.md]
    G --> OPS[ops.md]
    G --> SV[supervisor.md]
    EX -->|fresh context| EXE((Executor node))
    EXE <-->|reads / rewrites| LG
    SV -->|clean context, every 30 min| SUP((Supervisor node))
    SUP -->|reads only| LG
    SUP -->|corrections| DIR
    DIR -->|read each round| EXE
    SUP -->|checkpoint commit| GIT[(git)]
    SUP -->|human-only gaps| U
```

The executor node runs the work against the ledger. The supervisor node — a **separate agent with a clean context** — watches from outside, commits clean checkpoints, and injects course-corrections through a one-way directives edge. The two never share a context and never fight over a file.

## Run it cheap: one smart brain, a cheap workforce

Because the nodes **share no context** — they talk only through Markdown — each node can run on a **different model**. And graphkit's discipline is exactly what makes a *cheap* executor safe to unleash:

- its ambition is capped at **one item per round** — it can't run off and build a framework;
- the rules live **outside the model**, in the ledger and directives file — not in a giant prompt it has to remember;
- a **smart supervisor is watching** for the mistakes a weak model makes, and corrects them before they compound.

So you spend frontier-model tokens only where judgment actually pays off:

| Node | Runs | Give it… | Why |
| --- | --- | --- | --- |
| **Authoring** (`/graphkit` interview) | once | your best model | designing gates, red lines & milestones is the judgment call |
| 🛠️ **Executor** | every round, all day | a **cheap / fast agent** — Cursor's budget tier, Grok, a local model, an OSS coder | it just follows an explicit ledger one step at a time; the graph structurally forbids scope creep |
| 🛰️ **Supervisor** | every ~30 min | a **strong model** | catching drift from a cold read is the hardest call — but it fires rarely, so it's cheap in aggregate |

The executor prompt is plain Markdown pointing at plain Markdown — **paste it into whichever agent is cheapest**; it doesn't have to be Claude. You get frontier-grade reliability on the grind at a fraction of the token bill, because the expensive reasoning is concentrated in the setup and the occasional audit — not burned on every round.

## Quickstart

1. **Install the skill** — one line:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/levi-qiao/graphkit/main/install.sh | sh
   ```

   <sub>Prefer to do it by hand? `git clone https://github.com/levi-qiao/graphkit ~/.claude/skills/graphkit`</sub>

2. **Invoke it** in Claude Code:

   ```
   /graphkit
   ```

   Answer the short interview (repos & branches, the goal + how it's verified, milestones, gate commands, red lines, commit authorization, whether you want the supervisor node). graphkit writes the whole graph into a fresh `.graphkit/<date-slug>/` directory in your repo — **one directory per run**; a new run never edits an old run's files, it distills their learnings into its own starting snapshot. ([What each generated file does →](#map-of-a-run--the-files-graphkit-generates))

3. **Start the executor node.** graphkit hands you an `executor.md` — paste it into a fresh agent context and let it run. It's plain Markdown pointing at your ledger, so this can be a **cheap agent** (Cursor's budget tier, Grok, a local model) — it doesn't have to be Claude. Loop it however you like (a `while` + wake, a cron, or just re-paste each round).

4. **Start the supervisor node** (optional, recommended). graphkit schedules `supervisor.md` on your interval; each tick is a **fresh clean context** that watches, checkpoints, and corrects. Point this one at a **strong model** — it runs rarely, and its whole value is catching what the cheap executor can't.

> No Claude Code? The `templates/` are plain Markdown — fill them in by hand and the methodology still works with any agent runtime.

## Map of the repo — what each file is for

You never edit these by hand; know what they are so nothing feels magic:

| Path | What it is |
| --- | --- |
| [`SKILL.md`](SKILL.md) | The skill itself — the interview + generation flow Claude Code runs when you type `/graphkit`. |
| [`templates/`](templates/) | Blank node & edge templates the skill fills in per run. No Claude Code? Fill them in by hand — the methodology works in any agent runtime. |
| [`docs/methodology.md`](docs/methodology.md) | The *why*: every rule, and the failure mode it exists to prevent. Read when a rule feels arbitrary. |
| [`examples/add-tests-to-cli/`](examples/add-tests-to-cli/) | A finished run to skim — what a real executor + ledger look like three rounds in. **Best first read.** |

## Map of a run — the files `/graphkit` generates

Each run gets a fresh `.graphkit/<date-slug>/` in *your* repo. Five files — here's who writes each one and what you do with it:

| File | Who writes it | What you do with it |
| --- | --- | --- |
| `executor.md` | generated once | **Paste it into a fresh agent context** — that starts the executor node. Cheapest agent you have is fine. |
| `ledger.md` | the executor, every round | **Read it to follow the run.** It's the single source of truth: goals, gates, round log, open gaps. |
| `directives.md` | the supervisor (one-way) | Corrections land here; the executor reads it each round. You can append an order of your own anytime. |
| `ops.md` | any node, append-only | Durable environment/build/data facts, so no node re-discovers them from scratch. |
| `supervisor.md` | generated once | The supervisor node's prompt. In Claude Code it's scheduled for you; each tick is a clean context. |

## When to use it (and when not to)

**Use it** when the task spans many rounds, success is verifiable (tests / gates / metrics), and there's real risk of scope creep or a quietly lowered bar.

**Don't** use it for a one-shot edit, or when every step needs a human to judge success — a plain task is better there.

## FAQ

**Why call it a graph and not just "a loop with a monitor"?** Because the load-bearing property is that the supervisor is a *different node with its own clean context*, connected to the executor only by inspectable edges (the ledger, git, the directives file). That separation — not the schedule — is what lets it catch drift the executor can't. It's the same reason multi-agent frameworks model runs as graphs; graphkit just does it with Markdown instead of a runtime.

**Does this only work with Claude Code?** The skill packaging and the `CronCreate`-based supervisor scheduling are Claude Code features, but the nodes and edges are plain Markdown — the methodology is agent-agnostic. In fact the intended setup is *mixed*: author the graph once with a frontier model, then run the executor node on whatever agent is cheapest.

**Can I really run the executor on a cheap model?** Yes — that's the design. A weak model scope-creeps and fakes "done" when you hand it a vague goal; graphkit hands it a *tiny, explicit* one instead (one ledger item, verify, stop), keeps the rules outside its context, and puts a smart supervisor on watch. The structure does the reasoning the cheap model can't, so you pay frontier prices only for authoring + the occasional audit.

**Won't a fixed 5th-round convergence be arbitrary?** It's a default; the interview lets you tune the interval and the net-line cap. The point is that *some* forcing function exists, not the exact number.

**Can a node commit / push on its own?** Only if you authorize it in the interview. The safe default: the executor implements and verifies; commits are a separate authorized step (often the supervisor's job), and push is never automatic.

## Roadmap: more node roles

Executor + supervisor is the *smallest* useful graph, not the whole idea. Since a role is just a Markdown node plus an inspectable edge — no framework, no runtime — the graph can grow one file at a time. Planned roles include a **red-team reviewer** (adversarially probes "done" claims), a **scout/researcher** (explores options off the critical path and reports into the ledger), and a **test oracle** (owns the gates so the executor can't grade its own homework). If graph engineering as a practice interests you, these are great first PRs.

## Contributing

Issues and PRs welcome — see [CONTRIBUTING.md](CONTRIBUTING.md). If graphkit saved you a weekend of babysitting an agent, a ⭐ helps others find it.

## License

[MIT](LICENSE) © 2026 levi-qiao
