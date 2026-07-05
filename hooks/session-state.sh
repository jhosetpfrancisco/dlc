#!/usr/bin/env bash
# DLC session-state — SessionStart hook.
#
# If the current directory belongs to a DLC-managed workspace, surface the
# live-state header so every session starts knowing where the project stands.
# Prints nothing (exit 0) outside DLC workspaces — the hook is silent there.

first_existing() {
  for f in "$@"; do
    if [ -f "$f" ]; then
      printf '%s' "$f"
      return 0
    fi
  done
  return 1
}

manifest="$(first_existing dlc/repos.md docs/dlc/repos.md)" || exit 0

echo "-- DLC workspace -- manifest: $manifest"

state="$(first_existing STATE.md STATUS.md ESTADO.md docs/STATE.md docs/STATUS.md docs/ESTADO.md)" || {
  echo "No live-state file found (STATE.md / STATUS.md). Consider creating one."
  exit 0
}

mod="$(date -r "$state" '+%Y-%m-%d' 2>/dev/null || echo '?')"
echo "Live state: $state (last modified: $mod) -- first lines:"
head -n 15 "$state"
echo "-- Run /dlc:ctx <repo> before working on a repo --"
exit 0
