---
name: verify
description: Run a repo's "green" definition — the exact build/lint/test commands the workspace DLC manifest declares for it — and report pass/fail honestly. With no argument, infer the repo from the changed files. Use before handing work to the user and before /dlc:ship.
argument-hint: "[repo] (optional — inferred from the changed files if omitted)"
---

Target repo: `$ARGUMENTS`. If empty, infer it from the files changed in this session (`git status` across the workspace repos) and state the inference out loud before running anything.

1. Resolve the workspace manifest (same search order as `/dlc:ctx`: `./dlc/repos.md` → `./docs/dlc/repos.md` → `DLC:` pointer in the workspace `CLAUDE.md`). No manifest → suggest `/dlc:init` and STOP.
2. Read the repo's **Green** entry. It is an ordered chain of commands. If the repo has no green definition, say so and suggest adding one to the manifest — do NOT invent one on the spot.
3. Check prerequisites the manifest mentions (services up, env vars, docker) and warn the user before running anything long or heavy (e2e suites, container builds).
4. Run each command **from the repo's own directory**, in order. Stop at the first failure.
5. Report:
   - ✅ **GREEN** — only if EVERY step passed.
   - ❌ **RED** — which step failed, the relevant output excerpt (not the full dump), and your read on the cause.
6. Never soften a failure ("mostly passing", "should be fine"). Red is red — the owner decides what to do with it.

This skill VERIFIES; it does not fix. If something fails, report and wait — fix only if the user already asked you to.
