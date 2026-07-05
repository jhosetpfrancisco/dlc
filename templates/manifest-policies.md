# DLC manifest — policies
<!-- Workspace-level policies. The /dlc:ship gate and the planning skills read   -->
<!-- this file. Workspace DATA — belongs here, never to the public engine.       -->

## Commits
- **Identity:** Jane Doe <jane@example.com> (must match `git config` in every repo)
- **Convention:** conventional commits — `feat(scope):`, `fix(scope):`, `chore:`, `docs:`
- **AI attribution:** forbidden (no co-author trailers, no generated-with footers) — engine default

## Branches
- **Policy:** single `main`
  <!-- alternatives, spell the chosen one out completely:
       · dual branches: commit on main → `git branch -f master main` → `git push origin main master`
       · integration branch: commit and push to `staging`; `main` only via PR
       · PR-based: never push to the default branch directly                       -->
- **Force-push / history rewrites:** always need a separate explicit confirmation

## Language & style
- **Code identifiers:** English
- **UI copy / comments / commit messages:** (your choice)

## Hard rules (blocking constraints — the plan of every non-trivial change must check them)
1. <e.g. "UI primitives come only from the design-system registry — never hand-rolled">
2. <e.g. "never touch prod DB / prod infra without a separate confirmation">

## Destructive operations (separate confirmation ALWAYS — plan approval is not enough)
- force-push · hard reset over pushed history · deleting branches
- DB migrations against prod · bulk data scripts
- cloud resource deletion · publishing packages · touching secrets/env files
