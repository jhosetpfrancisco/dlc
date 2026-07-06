#!/usr/bin/env bash
# DLC scope-remind — UserPromptSubmit hook.
#
# Injects one line of context on every user prompt so the pinned scope
# survives long sessions and compactions. Silent outside DLC workspaces.

payload="$(cat)"

[ -f dlc/repos.md ] || [ -f docs/dlc/repos.md ] || exit 0
[ -f .dlc/scope-off ] && exit 0

sid="$(printf '%s' "$payload" \
  | grep -oE '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' \
  | head -n 1 | sed -e 's/^"[^"]*"[[:space:]]*:[[:space:]]*"//' -e 's/"$//' \
  | tr -cd 'A-Za-z0-9._-')"
[ -n "$sid" ] || sid="default"

scope_file=".dlc/scope.$sid"
if [ -f "$scope_file" ]; then
  repo="$(sed -n 's/^repo=//p' "$scope_file" | head -n 1)"
  dir="$(sed -n 's/^dir=//p' "$scope_file" | head -n 1)"
  echo "DLC scope: pinned to repo '$repo' — writes allowed only in $dir/ and the workspace shared docs. Any other repo requires /dlc:ctx first."
else
  echo "DLC: no repo scope pinned in this session — run /dlc:ctx <repo> before modifying any sub-repo."
fi
exit 0
