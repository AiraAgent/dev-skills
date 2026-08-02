#!/usr/bin/env bash
# PreToolUse(Bash) — while a run is open, history surgery goes through
# dev-skills:finish and nowhere else.
#
# Armed only by a run marker (.ai-workflow/run/<plan>/RUN, written by
# dev-skills:implement and cleared by dev-skills:finish). Outside a run this hook does nothing:
# an unconditional block on reset/merge/rebase would break ordinary work in every
# repository, which is why the marker exists at all.
#
# The script itself is not exempted and does not need to be: PreToolUse sees the
# command the model runs (`finish squash …`), and the git calls inside the
# script never pass through a hook.
#
# Fail-open: on any parsing error the command is allowed. A guard that blocks by
# accident is worse than one that misses.

input="$(cat 2>/dev/null || true)"
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null || true)"
[ -z "$cmd" ] && exit 0

# Cheap pre-filter: nothing here concerns a command without git in it.
printf '%s' "$cmd" | grep -qE '(^|[;&|[:space:]])git([[:space:]]|$)' || exit 0

root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[ -z "$root" ] && exit 0
runs="$root/.ai-workflow/run"
[ -d "$runs" ] || exit 0

marker="$(find "$runs" -mindepth 2 -maxdepth 2 -name RUN -type f 2>/dev/null | head -1)"
[ -n "$marker" ] || exit 0

plan="$(sed -n 's/^plan=//p' "$marker" 2>/dev/null | head -1)"

deny() {
  jq -cn --arg r "$1" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}' \
    2>/dev/null
  exit 0
}

blocked() {
  deny "Blocked by finish-guard: a run is in progress (plan: ${plan:-unknown}), so $1

$2

If this run is over, clear the marker: dev-skills:implement's scripts/run-state end"
}

# --- history surgery that belongs to dev-skills:finish ------------------------------
if printf '%s' "$cmd" | grep -qE 'git[[:space:]]+reset[[:space:]]+(-[[:alnum:]]*[[:space:]]+)*--(hard|soft|mixed|merge|keep)'; then
  blocked "moving HEAD is dev-skills:finish's job." \
    "The squash is 'finish squash <message file>' — it writes a recovery ref first and compares tree hashes after. To undo one: 'finish recover'. Unstaging a path ('git reset -- <path>') is not blocked."
fi

if printf '%s' "$cmd" | grep -qE 'git[[:space:]]+rebase' \
   && ! printf '%s' "$cmd" | grep -qE 'git[[:space:]]+rebase[[:space:]]+--(continue|abort|skip|quit|edit-todo)'; then
  blocked "rebasing is dev-skills:finish's job." \
    "Use 'finish rebase' — it reports how the base moved and whether it touched this run's paths, which decides whether the approvals still stand. Finishing an in-progress rebase (--continue / --abort / --skip) is not blocked."
fi

if printf '%s' "$cmd" | grep -qE 'git[[:space:]]+merge' \
   && ! printf '%s' "$cmd" | grep -qE 'git[[:space:]]+merge[[:space:]]+--(abort|continue|quit)'; then
  blocked "integrating is dev-skills:finish's job." \
    "Use 'finish integrate --ff-only', after GATE 2. Fast-forward is the only mode offered: anything else means the base moved, and the answer to that is a rebase."
fi

# --- things that destroy the run's recovery points --------------------------
if printf '%s' "$cmd" | grep -qE 'git[[:space:]]+commit[[:space:]]+(.*[[:space:]])?--amend'; then
  blocked "amending would move an already-reviewed range under the reviewer's feet." \
    "Fixes land as separate commits on top. Everything collapses into one commit at dev-skills:finish anyway."
fi

if printf '%s' "$cmd" | grep -qE 'git[[:space:]]+(branch[[:space:]]+(-[[:alnum:]]*[[:space:]]+)*(-d|-D|--delete)|worktree[[:space:]]+remove)'; then
  blocked "the run's branch and worktree are its recovery points." \
    "Cleanup happens in 'finish cleanup', after integration is proven — and only for a worktree this workflow created."
fi

if printf '%s' "$cmd" | grep -qE 'git[[:space:]]+push[[:space:]]+.*(--force([^-]|$)|--force-with-lease|[[:space:]]-f([[:space:]]|$))'; then
  blocked "a force-push during a run rewrites what the reviewers already read." \
    "A rejected push means the remote moved. Investigate; force-push only on your human partner's explicit request, after the run is closed."
fi

exit 0
