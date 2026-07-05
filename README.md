# dlc — a personal AI-DLC engine for Claude Code

**Your development lifecycle as a Claude Code plugin.** Workspace-agnostic and
language-agnostic: the engine discovers your repos, loads the right context
before every task, and enforces a plan → approve → build → verify → ship
discipline — while every fact about *your* projects stays in *your* workspaces.

Inspired by [AWS AI-DLC](https://aws.amazon.com/blogs/devops/ai-driven-development-life-cycle/)
([`awslabs/aidlc-workflows`](https://github.com/awslabs/aidlc-workflows)) and by
the spec-driven ecosystem ([spec-kit](https://github.com/github/spec-kit),
[OpenSpec](https://github.com/Fission-AI/OpenSpec), [Kiro](https://kiro.dev)) —
but built for **one senior engineer working with Claude Code across many
repos**, not for an enterprise team. It steals the good mechanics (inline
clarification questions, adaptive execution plans with declared skipped stages,
units of work, blocking constraints) and drops the team ceremony.

## The rule that makes it work

> **The engine contains logic. It never contains data.**

Everything specific is resolved at runtime through a 3-layer cascade — later
layers win:

| Layer | Where it lives | What it holds |
|---|---|---|
| 1 · Engine defaults | this repo (public) | the lifecycle, conventions, templates with fictional data |
| 2 · Personal profile | `~/.claude/dlc/profile.md` (your machine) | your identity, language, global preferences |
| 3 · Workspace manifest | `dlc/` or `docs/dlc/` in each workspace | repos, commands, spec reading order, "green" definitions, branch policy, hard rules |

That is why this repo can be public: there is nothing of any real project in it.

## Install

```
/plugin marketplace add jhosetpfrancisco/dlc
/plugin install dlc@dlc
```

## Getting started in a workspace

```
/dlc:init          # discovers repos, drafts the manifest — you review it
/dlc:ctx api       # loads the operational context of one repo
...work: plan → approve → build...
/dlc:verify api    # runs that repo's "green" definition, reports honestly
/dlc:ship api      # gated commit+push, per the workspace branch policy
```

## Skills

| Skill | What it does |
|---|---|
| `/dlc:init` | Discover repos, detect stack/commands/docs, generate the manifest as a **draft**; `--audit` re-runs only the gap report |
| `/dlc:ctx <repo>` | Load a repo's context: entry docs in order + operational card (commands, hard rules, dangers, green) |
| `/dlc:verify [repo]` | Run the repo's green definition and report honestly — red is red |
| `/dlc:ship <repo>` | Commit gate: identity check, conventional message, branch policy, no AI attribution; reports the SHA |
| `/dlc:feature` | *(roadmap)* Adaptive S/M/L change cycle: inline questions file → execution plan with declared skips → slices with checkboxes |
| `/dlc:archive` | *(roadmap)* Anti-spec-drift: merge the change's deltas back into the specs, update the live state, archive the change folder |

## Hooks

- **guard-commit** (`PreToolUse` on Bash): blocks commits carrying AI co-author
  trailers or "generated with" footers, and blocks force-pushes (escape hatch:
  prefix with `DLC_ALLOW_FORCE=1` after an explicit owner confirmation).
- **session-state** (`SessionStart`): if the cwd is a DLC workspace, prints the
  live-state header so every session starts oriented.

## Design tenets

1. **Propose, don't impose** — everything the engine generates is a draft the owner reviews.
2. **Adaptive by size** — a typo fix must never pay a feature's ceremony (S/M/L).
3. **Red is red** — verification results are reported verbatim, never softened.
4. **The manifest is data** — skills read it; only `/dlc:init` (plus the owner) writes it.
5. **No AI-attributed commits** — engine default, overridable by profile, enforced by hook.

## License

MIT — see [LICENSE](LICENSE).
