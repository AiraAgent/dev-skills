#!/usr/bin/env bash
# Pins skills/implement/scripts/preflight: the findings it reports today and
# the exit code that follows (0 clean, 1 findings, 2 not a repository). Every
# case runs against its own throwaway gitfixture_new repository.
#
# Also pins --parallel, which answers a different question — do these phases'
# write-sets intersect — and needs no repository at all, only a plan. Its cases
# run against test/fixtures/plan-writesets.md.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$here/../.." && pwd)"

. "$repo_root/test/lib/harness.sh"
. "$repo_root/test/lib/gitfixture.sh"

script="$repo_root/skills/implement/scripts/preflight"

fail() {
  echo "preflight.test.sh: $1" >&2
  exit 1
}

write_good_claude_md() {
  cat > "$1/CLAUDE.md" <<'EOF'
## Environment

**Build.** none
**Typecheck.** none
**Lint.** none
**Tests.** none
**Single test file.** none
**Dev server.** none
**E2E.** none
**Runtime.** none

**bootstrap.** none
**link.** none
EOF
}

write_claude_md_missing_link() {
  cat > "$1/CLAUDE.md" <<'EOF'
## Environment

**bootstrap.** none
EOF
}

# run_preflight REPO [ARGS...] — sets $out and $rc in the caller. Called as a
# plain statement, never wrapped in $(...): $rc has to survive the call, and
# wrapping the call itself in command substitution would fork a subshell that
# loses it (test/cli/segment-contract.test.sh's run_to_file hit the same
# thing; the fix there is the same one applied here).
run_preflight() {
  local repo="$1"
  shift
  out=$(cd "$repo" && "$script" "$@" 2>&1)
  rc=$?
}

# --- on main (the default), CLAUDE.md present -> default-branch finding, exit 1

repo1=$(gitfixture_new)
write_good_claude_md "$repo1"
run_preflight "$repo1"

assert_contains "$out" "on the default branch (main)" \
  "the default-branch finding should name main" || fail "default-branch finding missing"
[ "$rc" -eq 1 ] || fail "default-branch case should exit 1"

# --- non-default branch, clean tree, tracked .gitignore, full CLAUDE.md
# -> preflight clean, exit 0
#
# The .gitignore has to be committed for this to be the clean case at all: a
# fixture without one leaves preflight creating it, and an untracked .gitignore
# is a finding of its own, tested further down.

repo2=$(gitfixture_new)
gitfixture_branch "$repo2" work
gitfixture_gitignore "$repo2"
write_good_claude_md "$repo2"
run_preflight "$repo2"

assert_contains "$out" "preflight clean" \
  "a clean fixture should report preflight clean" || fail "not reported clean"
[ "$rc" -eq 0 ] || fail "clean case should exit 0"

# --- gitfixture_dirty -> the uncommitted-changes finding names 1 staged, 1 unstaged

repo3=$(gitfixture_new)
gitfixture_dirty "$repo3"
run_preflight "$repo3"

assert_contains "$out" "uncommitted changes (1 staged, 1 unstaged)" \
  "the dirty-tree finding should name one staged and one unstaged path" \
  || fail "uncommitted-changes finding missing"

# --- no .gitignore -> it is created with exactly .ai-workflow, fixed: line printed

repo4=$(gitfixture_new)
gitfixture_branch "$repo4" work
write_good_claude_md "$repo4"
[ ! -f "$repo4/.gitignore" ] || fail "test setup: fixture should start without a .gitignore"
run_preflight "$repo4"

assert_contains "$out" "fixed: added '.ai-workflow' to .gitignore" \
  "the fixed: line should be printed" || fail "fixed line missing"
[ -f "$repo4/.gitignore" ] || fail "gitignore should have been created"
gi_content=$(cat "$repo4/.gitignore")
assert_eq ".ai-workflow" "$gi_content" \
  "the .gitignore line must be .ai-workflow with no trailing slash" \
  || fail "gitignore content mismatch"

# --- CLAUDE.md missing **link** -> that finding fires, **bootstrap** does not

repo5=$(gitfixture_new)
gitfixture_branch "$repo5" work
write_claude_md_missing_link "$repo5"
run_preflight "$repo5"

assert_contains "$out" "no 'link' field in CLAUDE.md" \
  "the missing-link finding should fire" || fail "link finding missing"
! printf '%s' "$out" | grep -qF "no 'bootstrap' field" \
  || fail "bootstrap finding should not fire when bootstrap is present"

# --- outside any repository -> exit 2, not a git repository

bare=$(mktemp_dir)
run_preflight "$bare"

[ "$rc" -eq 2 ] || fail "outside a repository should exit 2"
assert_contains "$out" "not a git repository" \
  "the not-a-git-repository message should be printed" || fail "message missing"

# --- a plan path that does not exist -> the no such plan file finding

repo7=$(gitfixture_new)
gitfixture_branch "$repo7" work
write_good_claude_md "$repo7"
missing_plan="$repo7/does-not-exist.md"
[ ! -f "$missing_plan" ] || fail "test setup: plan path should not exist"
run_preflight "$repo7" "$missing_plan"

assert_contains "$out" "no such plan file: $missing_plan" \
  "the missing-plan finding should name the path" || fail "missing-plan finding missing"

# --- a .gitignore preflight had to create is untracked -> that is a finding
#
# The fixture starts with no .gitignore at all, so the block above creates one
# and leaves it untracked. Left unsaid, the run commits it on the branch and
# integration then collides with the untracked copy in the main checkout — and
# git reports that as a refused checkout, which reads like the base has moved.

repo8=$(gitfixture_new)
gitfixture_branch "$repo8" work
write_good_claude_md "$repo8"
run_preflight "$repo8"

assert_contains "$out" ".gitignore is not tracked" \
  "an untracked .gitignore should be a finding" || fail "untracked-gitignore finding missing"

# ...and once it is committed, the finding is gone.

git -C "$repo8" add .gitignore >/dev/null 2>&1
git -C "$repo8" commit -q -m "chore: ignore .ai-workflow"
run_preflight "$repo8"

! printf '%s' "$out" | grep -qF ".gitignore is not tracked" \
  || fail "a tracked .gitignore must not raise the finding"

# --- --parallel: disjoint write-sets -> exit 0, the group may run ----------
#
# No repository: --parallel reads a plan and nothing else, and is answered
# before the run's own checks are reached.

wsplan="$repo_root/test/fixtures/plan-writesets.md"

out=$("$script" --parallel "$wsplan" 2 3 2>&1); rc=$?
[ "$rc" -eq 0 ] || fail "disjoint write-sets should exit 0"
assert_contains "$out" "write-sets disjoint" \
  "disjoint write-sets should say so" || fail "disjoint message missing"

# --- a path inside a fenced block is an example, never a write -------------

out=$("$script" --parallel "$wsplan" 1 3 2>&1); rc=$?
[ "$rc" -eq 0 ] || fail "phases 1 and 3 should be disjoint"
! printf '%s' "$out" | grep -qF "src/fenced/never-a-write.ts" \
  || fail "a path inside a fenced block must not be read as a write"

# --- --parallel: intersecting write-sets -> exit 1, naming the shared path --

out=$("$script" --parallel "$wsplan" 2 4 2>&1); rc=$?
[ "$rc" -eq 1 ] || fail "intersecting write-sets should exit 1"
assert_contains "$out" "intersect: phases 2 and phases 4 both write" \
  "the intersection should name both sides" || fail "intersect line missing"
assert_contains "$out" "src/api/client.ts" \
  "the intersection should name the shared path" || fail "shared path not named"

# --- one clash in a group of three is still a refusal ----------------------

out=$("$script" --parallel "$wsplan" 2 3 4 2>&1); rc=$?
[ "$rc" -eq 1 ] || fail "one clash among three ranges should still exit 1"

# --- --parallel needs at least two ranges, and rejects a bad one -----------

out=$("$script" --parallel "$wsplan" 2 2>&1); rc=$?
[ "$rc" -eq 2 ] || fail "--parallel with one range should exit 2"

out=$("$script" --parallel "$wsplan" 2 abc 2>&1); rc=$?
[ "$rc" -eq 2 ] || fail "--parallel with a bad range should exit 2"
assert_contains "$out" "bad RANGE: abc" \
  "a bad range should be named" || fail "bad-range message missing"

echo "ok"
