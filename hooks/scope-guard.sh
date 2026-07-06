#!/usr/bin/env bash
# DLC scope-guard — PreToolUse hook for Edit/Write/NotebookEdit/Bash.
#
# Enforces the per-session repo scope pinned by /dlc:ctx. Instructions fade
# from a compacted context; this guard does not — it runs on every tool call,
# outside the context window, so the session can "forget" its scope and still
# be unable to write outside it.
#
# Mechanics:
#   - /dlc:ctx pins the scope by running:  echo DLC-SCOPE-SET repo=<id> dir=<dir>
#     This hook intercepts the marker on the Bash payload, binds it to the
#     session_id it sees on stdin, and records it in `.dlc/scope.<session_id>`
#     at the workspace root. `echo DLC-SCOPE-CLEAR` removes the pin.
#   - With a pin, file writes (Edit/Write/NotebookEdit) are allowed only:
#     inside the pinned repo dir, in the workspace shared area (any path not
#     inside another sub-repo), or outside any git repo (temp/scratch/memory).
#     Writes into another sub-repo, or into a git repo outside the workspace,
#     exit 2 with a message that re-anchors the model to its scope.
#   - Without a pin, writes inside any sub-repo exit 2: run /dlc:ctx first.
#   - Bash commands that run a mutating git verb inside another sub-repo
#     (via `git -C <dir>` or `cd <dir>`) are blocked. Escape hatch after an
#     explicit owner confirmation: prefix the command with DLC_ALLOW_CROSS=1.
#   - Owner kill switch: create `.dlc/scope-off` in the workspace root.
#
# A "sub-repo" is any first-level directory of the workspace with its own
# `.git`. Outside DLC workspaces (no manifest) the hook is a silent no-op.
# No JSON parser is assumed (bare Git Bash on Windows has no jq): fields are
# extracted with plain-text scans, which is safe here because the keys we
# read appear unescaped only at the JSON level we care about.

payload="$(cat)"

# Only act inside a DLC workspace, and honor the owner kill switch.
[ -f dlc/repos.md ] || [ -f docs/dlc/repos.md ] || exit 0
[ -f .dlc/scope-off ] && exit 0

# ---------- helpers ----------

# norm <path> — JSON-unescape backslashes, force forward slashes, lowercase
# (Windows FS is case-insensitive), map `c:` to `/c`, strip trailing slash.
norm() {
  printf '%s' "$1" \
    | sed -e 's/\\\\/\//g' -e 's/\\/\//g' \
    | tr '[:upper:]' '[:lower:]' \
    | sed -e 's/^\([a-z]\):/\/\1/' -e 's/\/\{1,\}/\//g' -e 's/\/$//'
}

# json_str <key> — first string value of "key" in the payload.
json_str() {
  printf '%s' "$payload" \
    | grep -oE '"'"$1"'"[[:space:]]*:[[:space:]]*"(\\.|[^"\\])*"' \
    | head -n 1 \
    | sed -e 's/^"[^"]*"[[:space:]]*:[[:space:]]*"//' -e 's/"$//'
}

tool="$(json_str tool_name)"
sid="$(json_str session_id | tr -cd 'A-Za-z0-9._-')"
[ -n "$sid" ] || sid="default"
scope_file=".dlc/scope.$sid"

# ---------- pin / clear markers (Bash only) ----------

if [ "$tool" = "Bash" ]; then
  marker="$(printf '%s' "$payload" \
    | grep -oE 'DLC-SCOPE-SET +repo=[A-Za-z0-9._-]+ +dir=[A-Za-z0-9._/-]+' \
    | head -n 1)"
  if [ -n "$marker" ]; then
    repo="$(printf '%s' "$marker" | sed 's/.*repo=\([A-Za-z0-9._-]*\).*/\1/')"
    dir="$(printf '%s' "$marker" | sed -e 's/.* dir=\([A-Za-z0-9._/-]*\).*/\1/' -e 's/\/$//')"
    if [ ! -d "$dir" ]; then
      echo "DLC scope-guard: cannot pin scope — directory '$dir' does not exist under $(pwd). Check the repo dir in the manifest." >&2
      exit 2
    fi
    mkdir -p .dlc
    [ -f .dlc/.gitignore ] || printf '*\n' > .dlc/.gitignore
    printf 'repo=%s\ndir=%s\n' "$repo" "$dir" > "$scope_file"
    exit 0
  fi
  if printf '%s' "$payload" | grep -q 'DLC-SCOPE-CLEAR'; then
    rm -f "$scope_file"
    exit 0
  fi
fi

# ---------- load pin + discover sub-repos ----------

pinned_repo="" pinned_dir=""
if [ -f "$scope_file" ]; then
  pinned_repo="$(sed -n 's/^repo=//p' "$scope_file" | head -n 1)"
  pinned_dir="$(sed -n 's/^dir=//p' "$scope_file" | head -n 1)"
fi

subrepos=""
for d in */; do
  d="${d%/}"
  [ -d "$d" ] && [ -e "$d/.git" ] && subrepos="$subrepos $d"
done

nws="$(norm "$(pwd)")"

# ---------- file-writing tools ----------

case "$tool" in
  Edit|Write|NotebookEdit)
    fp="$(json_str file_path)"
    [ -n "$fp" ] || fp="$(json_str notebook_path)"
    [ -n "$fp" ] || exit 0
    nfp="$(norm "$fp")"
    case "$nfp" in /*) : ;; *) nfp="$nws/$nfp" ;; esac

    case "$nfp" in
      "$nws"/*)
        rel="${nfp#"$nws"/}"
        seg1="${rel%%/*}"
        hit=""
        for d in $subrepos; do
          [ "$seg1" = "$(norm "$d")" ] && hit="$d"
        done
        if [ -n "$hit" ]; then
          if [ -z "$pinned_dir" ]; then
            echo "DLC scope-guard: no repo scope is pinned for this session and '$fp' is inside sub-repo '$hit'. Run /dlc:ctx <repo> to load its context and pin the scope before writing there." >&2
            exit 2
          fi
          if [ "$seg1" != "$(norm "$pinned_dir")" ]; then
            echo "DLC scope-guard: this session is pinned to repo '$pinned_repo' ($pinned_dir/). Writing to '$fp' (sub-repo '$hit/') is OUT OF SCOPE. Stay inside $pinned_dir/ and the workspace docs. If the owner explicitly asked for changes in '$hit', run /dlc:ctx for that repo first." >&2
            exit 2
          fi
        fi
        ;;
      *)
        # Outside the workspace: with a pin, block writes into any git repo.
        if [ -n "$pinned_dir" ]; then
          d="$nfp" i=0
          while [ $i -lt 40 ]; do
            d="$(dirname "$d")"
            case "$d" in /|.|"") break ;; esac
            if [ -e "$d/.git" ]; then
              echo "DLC scope-guard: this session is pinned to repo '$pinned_repo' inside $(pwd). Writing to '$fp' targets a git repo OUTSIDE this workspace ('$d') — out-of-workspace repos are read-only reference under DLC policy. Report to the owner instead of editing it." >&2
              exit 2
            fi
            i=$((i + 1))
          done
        fi
        ;;
    esac
    ;;
esac

# ---------- Bash: mutating git in another sub-repo ----------

if [ "$tool" = "Bash" ] && [ -n "$pinned_dir" ]; then
  case "$payload" in *DLC_ALLOW_CROSS=1*) exit 0 ;; esac
  if printf '%s' "$payload" | grep -qE 'git[^|;&]*(commit|push| add |reset|checkout|rebase|merge|restore|cherry-pick|stash)'; then
    npin="$(norm "$pinned_dir")"
    for d in $subrepos; do
      [ "$(norm "$d")" = "$npin" ] && continue
      if printf '%s' "$payload" | grep -qE "(git[[:space:]]+-C[[:space:]]+[\\\\\"']*(\./)?$d|cd[[:space:]]+[\\\\\"']*(\./)?$d)"; then
        echo "DLC scope-guard: this session is pinned to repo '$pinned_repo' ($pinned_dir/) but this command runs a mutating git operation inside '$d/'. OUT OF SCOPE. If the owner explicitly confirmed it, re-run prefixed with DLC_ALLOW_CROSS=1." >&2
        exit 2
      fi
    done
  fi
fi

exit 0
