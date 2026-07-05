---
name: ship
description: Commit-and-push gate. Only after the user validated the change — verifies committer identity, message convention, and branch policy (resolved from workspace policies → personal profile → git config), then commits, pushes, and reports the SHA. Never invoke on your own initiative.
argument-hint: "[repo] [optional intent for the commit message]"
---

Shipping is the LAST act of a change. Verify ALL preconditions; abort loudly if any fails:

1. **User validation happened.** The user explicitly validated this change in this conversation ("validated", "ship it", or equivalent). If not: STOP. Plan approval is NOT ship approval.
2. **Green ran.** `/dlc:verify` passed for this repo after the last edit. If not, run it now; ship only on GREEN.
3. **Clean scope.** `git status` in the repo shows only the intended changes. Unrelated files → ask before including them.

## Resolve the shipping policy (cascade — later layers win)

1. **Engine defaults:** conventional commits (`type(scope): subject`), single branch `main`, and **no AI co-author trailers, no "generated with" footers — ever** (a policy layer may opt out with `allow_ai_coauthor: true`; absent that, it is absolute).
2. **Personal profile:** `~/.claude/dlc/profile.md` — default commit identity, language, personal overrides.
3. **Workspace policies file** (named by the manifest, e.g. `dlc/policies.md`): branch policy (single branch · dual-branch · integration branch · PR-based), workspace commit identity, message language/conventions.

## Execute

1. **Identity check:** `git -C <repo> config user.name` / `user.email` must match the resolved identity. Mismatch → STOP and report. Never commit under a different identity, never under an AI identity.
2. **Compose the message:** conventional commit, imperative, scoped; body only if it adds real information; in the language the policies dictate.
3. **Commit**, then apply the branch policy exactly as the policies file spells it (e.g. dual-branch: commit on `main` → point the second branch at `main` → push both).
4. **Report:** SHA · branch(es) · full message · remote.

If the push is rejected (diverged remote): report and stop — do NOT force-push. Force-pushes always need a separate, explicit owner confirmation, and the guard hook blocks them by default.
