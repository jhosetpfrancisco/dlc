---
name: ctx
description: Load the operational context for one repo of the current workspace before working on it — entry docs in order, commands, hard rules, "green" definition, and dangers, all read from the workspace DLC manifest. Use whenever a task targets a specific repo.
argument-hint: "[repo] — a repo id listed in the workspace manifest"
---

You are about to work on repo **$ARGUMENTS** of the current workspace. Load its context before touching anything.

## 1. Resolve the manifest

Look for the workspace manifest in this order (first hit wins):

1. `./dlc/repos.md`
2. `./docs/dlc/repos.md`
3. A line starting with `DLC:` in the workspace `CLAUDE.md` pointing to a manifest path
4. If the current directory is a sub-repo, repeat 1–3 from its parent directory (the workspace root)

If no manifest exists: say so, suggest running `/dlc:init`, and STOP. Do not improvise a context.

## 2. Load the context (in this exact order)

1. Read the **Workspace section** of the manifest (live-state file, policies file, shared docs, out-of-workspace references).
2. Read the **live-state file** it names (e.g. `STATE.md`) — at least its TL;DR and the section about this repo.
3. Read the manifest **entry for the requested repo**. If the id is not listed, print the valid repo ids and STOP.
4. Read, IN ORDER, every entry doc listed for the repo. Do not skip any. If one is missing on disk, report it as manifest drift instead of guessing around it.
5. Read the **policies file** if you have not read it in this session (hard rules apply to every change).

## 3. Pin the write scope

Resolve the repo's **directory** from its manifest entry (the directory named in the repo heading, without the trailing slash) and run this exact Bash command from the workspace root:

```
echo DLC-SCOPE-SET repo=$ARGUMENTS dir=<repo-dir>
```

The `scope-guard` hook intercepts the marker and binds this session to that directory: from now on, file writes outside `<repo-dir>/` (plus the workspace shared docs) are mechanically blocked — the pin lives outside the context window, so it survives compaction. Re-running `/dlc:ctx` with another repo moves the pin; `echo DLC-SCOPE-CLEAR` removes it. If the command errors saying the directory does not exist, the manifest has drift — report it, do not guess a different directory.

## 4. Confirm with the operational card

Print a short card so the user knows the context is loaded:

- **Repo:** what it is, stack
- **Scope:** pinned to `<repo-dir>/` — writes elsewhere are blocked by the scope-guard hook
- **Commands:** dev · build · green (verification)
- **Hard rules:** the non-negotiables that apply here
- **Dangers:** DBs it may/may not touch, version pins, out-of-workspace references
- **Docs loaded:** the list you actually read

Then continue with the task (or ask for it if none was given).

## Rules

- The manifest is DATA maintained by the owner — trust it over your assumptions, but report contradictions between manifest and reality (missing files, ghost commands) instead of silently working around them.
- Never modify the manifest from this skill; that is `/dlc:init`'s (or the owner's) job.
