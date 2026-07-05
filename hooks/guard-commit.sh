#!/usr/bin/env bash
# DLC guard-commit — PreToolUse hook for Bash tool calls.
#
# Blocks, with exit 2 (blocking error; the message goes back to the model):
#   1. `git commit` whose message carries an AI co-author trailer or an
#      AI-generated footer. Engine default: never ship AI-attributed commits.
#      A profile/policy layer may opt out (allow_ai_coauthor: true) — in that
#      case edit or disable this hook; the engine cannot read markdown here.
#   2. `git push --force` (any variant) — history rewrites always need a
#      separate, explicit confirmation from the owner. Escape hatch once
#      confirmed: prefix the command with DLC_ALLOW_FORCE=1.
#
# Reads the tool-call JSON from stdin. No JSON parser is assumed (a bare Git
# Bash on Windows has no jq): a plain-text scan is enough because we only need
# to know whether the strings co-occur in the same command payload.

payload="$(cat)"

case "$payload" in
  *"git commit"*)
    if printf '%s' "$payload" | grep -qiE 'co-authored-by:.{0,80}(claude|anthropic|copilot|gemini|codex)|generated with.{0,40}(claude|copilot|gemini|codex|ai)'; then
      echo "DLC guard: the commit message contains an AI co-author trailer or AI-generated footer. Engine policy forbids AI-attributed commits — rewrite the message with the owner's identity only." >&2
      exit 2
    fi
    ;;
esac

case "$payload" in
  *"DLC_ALLOW_FORCE=1"*)
    exit 0
    ;;
  *"git push"*)
    if printf '%s' "$payload" | grep -qE 'git push[^"]{0,160}(--force|[[:space:]]-f([[:space:]]|$))'; then
      echo "DLC guard: force-push blocked. It requires a separate, explicit confirmation from the owner. If that confirmation was already given in this conversation, re-run the command prefixed with DLC_ALLOW_FORCE=1." >&2
      exit 2
    fi
    ;;
esac

exit 0
