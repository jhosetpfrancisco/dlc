#!/usr/bin/env bash
# DLC session-state — SessionStart hook.
#
# Runs on session startup AND after every context compaction (SessionStart
# fires again with source "compact"). If the current directory belongs to a
# DLC-managed workspace, surface the live-state header — and, when a repo
# scope is pinned for this session, re-inject the repo's operational card
# from the manifest so the model stays anchored even after its context was
# summarized. Prints nothing (exit 0) outside DLC workspaces.

payload="$(cat)"

first_existing() {
  for f in "$@"; do
    if [ -f "$f" ]; then
      printf '%s' "$f"
      return 0
    fi
  done
  return 1
}

json_str() {
  printf '%s' "$payload" \
    | grep -oE '"'"$1"'"[[:space:]]*:[[:space:]]*"[^"]*"' \
    | head -n 1 | sed -e 's/^"[^"]*"[[:space:]]*:[[:space:]]*"//' -e 's/"$//'
}

manifest="$(first_existing dlc/repos.md docs/dlc/repos.md)" || exit 0

echo "-- DLC workspace -- manifest: $manifest"

state="$(first_existing STATE.md STATUS.md ESTADO.md docs/STATE.md docs/STATUS.md docs/ESTADO.md)"
if [ -n "$state" ]; then
  mod="$(date -r "$state" '+%Y-%m-%d' 2>/dev/null || echo '?')"
  echo "Live state: $state (last modified: $mod) -- first lines:"
  head -n 15 "$state"
else
  echo "No live-state file found (STATE.md / STATUS.md). Consider creating one."
fi

# Prune scope pins from long-dead sessions.
[ -d .dlc ] && find .dlc -maxdepth 1 -name 'scope.*' -mtime +7 -exec rm -f {} + 2>/dev/null

sid="$(json_str session_id | tr -cd 'A-Za-z0-9._-')"
[ -n "$sid" ] || sid="default"
src="$(json_str source)"
scope_file=".dlc/scope.$sid"

if [ -f "$scope_file" ]; then
  repo="$(sed -n 's/^repo=//p' "$scope_file" | head -n 1)"
  dir="$(sed -n 's/^dir=//p' "$scope_file" | head -n 1)"
  echo ""
  echo "-- DLC scope pinned for this session: repo '$repo' -> $dir/ --"
  if [ "$src" = "compact" ]; then
    echo "Context was just COMPACTED. The operational card below is authoritative — re-read the repo's entry docs before further code changes. Writes outside $dir/ stay blocked by the scope-guard hook."
  fi
  echo "Manifest entry for '$repo':"
  awk -v id="$repo" '/^## /{p=($2==id)} p' "$manifest"
else
  echo "-- Run /dlc:ctx <repo> before working on a repo (it also pins the write scope) --"
fi
exit 0
