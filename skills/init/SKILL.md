---
name: init
description: Integrate the DLC engine into a workspace — discover its repos, detect stacks and commands, locate specs and live-state docs, and generate the DLC manifest (repos + policies) as a DRAFT for the owner to review. Also audits gaps (repos without docs, missing verification commands, stale state). Run from the workspace root.
argument-hint: "[--audit] to only re-run the gap report against an existing manifest"
---

You are integrating (or auditing) the DLC engine in the current workspace. Everything you produce is a **draft the owner reviews** — propose, don't impose.

## 0. Audit-only mode

If `$ARGUMENTS` contains `--audit`: skip generation. Re-run only step 4 against the existing manifest and reality. Report drift: manifest entries pointing to missing files, commands that no longer exist, repos on disk missing from the manifest, live-state files contradicting each other or the code.

## 1. Discover

- **Repos:** first-level directories containing `.git` (plus the root itself if it is a repo). List project-looking directories that are NOT git as "unversioned".
- **Stack per repo:** by ecosystem manifests only — `package.json` (read its `scripts`), `go.mod` + `Makefile` (read targets), `pyproject.toml`, `Cargo.toml`, `pom.xml`/`build.gradle`, `*.tf`, `Dockerfile`, `nx.json`. Never assume a language.
- **Knowledge per repo:** `CLAUDE.md`, `README*`, live-state files (`STATE.md`, `STATUS.md` or local-language equivalents), `docs/` folders in the repo, and spec folders in a workspace-level `docs/`.

## 2. Propose the manifest (drafts, from the engine templates)

Using `${CLAUDE_PLUGIN_ROOT}/templates/` as the base, create:

- **`dlc/repos.md`** — or `docs/dlc/repos.md` when the workspace root is not itself a git repo but has a docs area. One section per repo: what it is · entry docs IN READING ORDER (heuristic: live state → repo specs → shared contracts) · commands (dev/build) · **Green** (the verification chain; when none exists, propose one and mark it `⚠ proposed`) · dangers and hard rules found in existing docs.
- **`dlc/policies.md`** — branch policy (deduce from `git log` and existing branches; ask when unclear) · commit identity (from `git config`) · language · workspace-wide hard rules found in CLAUDE.md/docs · destructive-operations list.
- **`dlc/changes/`** directory (with `archive/` inside).
- For repos WITHOUT a `CLAUDE.md`: a thin draft from `templates/claude-md-thin.md` (pointer to specs, hard rules, green). Present these as drafts too.

Write the drafts, then STOP and ask the owner to review and correct them. Commit nothing.

## 3. Wire the workspace (after the owner approves)

Add one pointer line to the workspace `CLAUDE.md` (create a minimal one if absent):

```
DLC: <path-to>/repos.md — manifest read by the /dlc:* skills.
```

## 4. Gap report (always, generation or audit)

End with a numbered list: repos without CLAUDE.md · without green commands · without entry docs · state files that contradict each other or reality · documented commands that do not exist · references pointing outside the workspace. This is the owner's hygiene backlog — report it, never fix it silently.
