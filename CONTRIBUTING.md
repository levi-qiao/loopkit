# Contributing to graphkit

Thanks for helping! graphkit is deliberately small — a skill, five templates, docs, and two worked examples. Contributions that keep it that way are the most welcome.

## Good contributions

- **Real-world tunings** of the defaults (convergence interval, net-line cap, tick cadence) with a note on the project shape they suited.
- **New worked examples** in `examples/` — must be fully generic and secret-free (see below).
- **Clarity fixes** to the templates or `docs/methodology.md`.
- **Translations** — the skill and READMEs ship EN + 中文; more languages welcome, mirror the existing structure.
- **Adapters** for other agent runtimes (the templates are agent-agnostic Markdown; scheduling/skill packaging is the runtime-specific part).

## Hard rules

- **No secrets, no real client data, ever** — in examples, fixtures, docs, or commit messages. Examples must use fictional projects.
- **Keep it minimal.** New abstraction or config in the templates needs a concrete motivating case. graphkit preaches anti-bloat; the repo should practice it.
- **Don't break the shape.** The methodology's load-bearing parts (single scoreboard, one-item rounds with same-round verification, a forcing function against growth, register-then-defer, hard stop conditions, absolute red lines, and a supervisor node whose context is separate from the executor's) are the product. Tune the numbers, not the shape.

## How to submit

1. Fork and branch.
2. Make the change; if you touched an example, sanity-check that its ledger and executor prompt still tell a coherent story.
3. Open a PR describing the failure mode your change addresses or the tuning it documents.

By contributing, you agree your contributions are licensed under the [MIT License](LICENSE).
