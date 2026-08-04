#!/usr/bin/env bash
# Pins skills/finish/scripts/finish's squash and recover: squash collapses the
# run's commits into one, records a recovery ref at the pre-squash HEAD, and
# preserves the tree exactly; recover restores that state from a named attempt;
# a non-Conventional subject is refused before anything is reset.
#
# Every invocation runs with a throwaway gitfixture repository as the working
# directory — finish resolves its own repository root from the cwd, and a
# case that forgot this would run squash or recover against the repository
# these tests themselves live in.
#
# The single-ref behaviour this file used to pin is gone, replaced by migration
# commit (4) with numbered, immutable refs under
# refs/dev-skills/recovery/<branch>/<attempt>. The two cases at the bottom are
# what that replacement bought: a second squash records a second attempt instead
# of overwriting the first, and recover refuses to guess which one was meant.
# A single ref could not survive a second squash — it would end up pointing at
# the first squashed commit, and the pre-squash state would be unreachable at
# exactly the moment somebody wanted it.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$here/../.." && pwd)"

. "$repo_root/test/lib/harness.sh"
. "$repo_root/test/lib/gitfixture.sh"

finish="$repo_root/skills/finish/scripts/finish"

fail() {
  echo "finish.test.sh: $1" >&2
  exit 1
}

# run_finish REPO [ARGS...] — sets $out and $rc in the caller. Called as a
# plain statement, never wrapped in $(...): $rc has to survive the call, the
# same reason test/cli/preflight.test.sh's run_preflight is written this way.
run_finish() {
  local repo="$1"
  shift
  out=$(cd "$repo" && "$finish" "$@" 2>&1)
  rc=$?
}

# --- fixture: a branch with three real commits ahead of the run's base, and
# a marker pointing base= at the commit the branch started from. All four of
# cmd_preflight's requirements (a branch of its own, a marker, a clean tree,
# a non-empty base..HEAD range) have to hold before squash is reachable at
# all, whichever message is handed to it.

repo1=$(gitfixture_new)
gitfixture_branch "$repo1" work
start_sha=$(git -C "$repo1" rev-parse HEAD)
gitfixture_commit "$repo1" "feat: one" >/dev/null
gitfixture_commit "$repo1" "feat: two" >/dev/null
head_before_squash=$(gitfixture_commit "$repo1" "feat: three")
plan1=$(gitfixture_plan "$repo1")
gitfixture_marker "$repo1" "$plan1" "$start_sha" >/dev/null

pre_tree=$(git -C "$repo1" rev-parse 'HEAD^{tree}')

# --- a non-Conventional subject is refused before anything is reset --------
#
# Tried first, against the fully-prepared fixture above: if this check were
# ever bypassed, the squash below would actually succeed instead of being
# refused, which is exactly what distinguishes "refused" from "never got far
# enough to be tested".

msgdir_bad=$(mktemp_dir)
badmsg="$msgdir_bad/bad-subject.txt"
printf 'not a conventional commit subject\n' > "$badmsg"

run_finish "$repo1" squash "$badmsg"
[ "$rc" -ne 0 ] || fail "a non-Conventional subject should have been refused"
assert_contains "$out" "not Conventional Commits" \
  "the refusal should say why" || fail "refusal message missing"
head_after_bad=$(git -C "$repo1" rev-parse HEAD)
assert_eq "$head_before_squash" "$head_after_bad" \
  "HEAD must be unchanged when the message is refused" || fail "HEAD moved despite refusal"

# --- recover with no ref at all: non-zero, and it says so -------------------
#
# A separate, minimal fixture: cmd_recover never calls resolve_marker or
# cmd_preflight, so nothing beyond a repository is needed.

repo_norecover=$(gitfixture_new)
run_finish "$repo_norecover" recover
[ "$rc" -ne 0 ] || fail "recover with no ref should be non-zero"
assert_contains "$out" "no recovery ref" \
  "recover with no ref should say so" || fail "message missing"

# --- squash: exactly one commit above base, tree preserved, recovery ref ---

msgdir_good=$(mktemp_dir)
goodmsg="$msgdir_good/good-subject.txt"
printf 'feat: squash the run into one commit\n' > "$goodmsg"

run_finish "$repo1" squash "$goodmsg"
[ "$rc" -eq 0 ] || fail "squash with a Conventional subject should exit 0"

count=$(git -C "$repo1" rev-list --count "$start_sha..HEAD")
assert_eq "1" "$count" "squash should leave exactly one commit above base" \
  || fail "commit count wrong"

post_tree=$(git -C "$repo1" rev-parse 'HEAD^{tree}')
assert_eq "$pre_tree" "$post_tree" "the tree must survive the squash" \
  || fail "tree changed across the squash"

recovery_sha=$(git -C "$repo1" rev-parse refs/dev-skills/recovery/work/1)
assert_eq "$head_before_squash" "$recovery_sha" \
  "attempt 1 should resolve to the pre-squash HEAD" || fail "recovery ref wrong"

# --- recover with no attempt: lists, changes nothing, non-zero -------------
#
# A default here would be a silent rollback to whichever state the script
# guessed at, which is the one thing a recovery must never do.

head_before_listing=$(git -C "$repo1" rev-parse HEAD)
run_finish "$repo1" recover
[ "$rc" -ne 0 ] || fail "recover with no attempt should be non-zero"
assert_contains "$out" "finish recover <attempt>" \
  "it should say how to name one" || fail "usage hint missing"
assert_eq "$head_before_listing" "$(git -C "$repo1" rev-parse HEAD)" \
  "listing the attempts must not move HEAD" || fail "HEAD moved while listing"

# --- a second squash records a second attempt and leaves the first alone ---
#
# This is the whole reason the refs are numbered. Under a single overwritten
# ref, attempt 1 would now point at the first squashed commit and the state it
# was recorded for would be unreachable.

first_squash_head=$(git -C "$repo1" rev-parse HEAD)
gitfixture_commit "$repo1" "fix: something the acceptance asked for" >/dev/null
head_before_second_squash=$(git -C "$repo1" rev-parse HEAD)

msg2="$msgdir_good/second-subject.txt"
printf 'feat: squash the run again\n' > "$msg2"
run_finish "$repo1" squash "$msg2"
[ "$rc" -eq 0 ] || fail "the second squash should exit 0"

assert_eq "$head_before_squash" "$(git -C "$repo1" rev-parse refs/dev-skills/recovery/work/1)" \
  "attempt 1 must still point where it did" || fail "attempt 1 was overwritten"
assert_eq "$head_before_second_squash" "$(git -C "$repo1" rev-parse refs/dev-skills/recovery/work/2)" \
  "attempt 2 should be the pre-second-squash HEAD" || fail "attempt 2 wrong"

# --- recover NAMES its attempt, and reaches the older one ------------------

run_finish "$repo1" recover 1
[ "$rc" -eq 0 ] || fail "recover 1 should exit 0"
assert_eq "$head_before_squash" "$(git -C "$repo1" rev-parse HEAD)" \
  "recover 1 should restore the first pre-squash HEAD" || fail "HEAD not restored"
git -C "$repo1" rev-parse --verify --quiet refs/dev-skills/recovery/work/1 >/dev/null \
  || fail "the recovery ref should still exist after recover"

# --- an attempt that does not exist is refused, not rounded to a neighbour --

head_before_bad_attempt=$(git -C "$repo1" rev-parse HEAD)
run_finish "$repo1" recover 99
[ "$rc" -ne 0 ] || fail "an unknown attempt should be non-zero"
assert_eq "$head_before_bad_attempt" "$(git -C "$repo1" rev-parse HEAD)" \
  "an unknown attempt must not move HEAD" || fail "HEAD moved on an unknown attempt"

# --- integrate: the three answers, and they are told apart ------------------
#
# `integrate` used to report "not a fast-forward — <base> has moved" for every
# failure, including one that had nothing to do with the graph: an untracked
# file in the main checkout standing where a tracked one was about to land.
# That message sends the human to `finish rebase`, which cannot help. These
# cases pin that the graph question is now asked separately from the working
# tree's answer.
#
# A worktree is needed to reach the collision at all: the main checkout has to
# be a second working tree, holding an untracked copy of a path the branch
# carries as tracked.

# make_worktree MAIN NAME BRANCH -> prints the worktree path
make_worktree() {
  local main="$1" name="$2" branch="$3" dir
  dir="$(mktemp_dir)/$name"
  git -C "$main" worktree add -q -b "$branch" "$dir" >/dev/null 2>&1
  echo "$dir"
}

# --- a clean fast-forward integrates ---------------------------------------

repo_ff=$(gitfixture_new)
wt_ff=$(make_worktree "$repo_ff" wt feature)
gitfixture_commit "$wt_ff" "feat: work done in the worktree" >/dev/null

run_finish "$wt_ff" integrate --ff-only
[ "$rc" -eq 0 ] || fail "a clean fast-forward should exit 0: $out"
assert_contains "$out" "fast-forward" \
  "a successful integration should say so" || fail "success message missing"
assert_eq "$(git -C "$wt_ff" rev-parse HEAD)" "$(git -C "$repo_ff" rev-parse main)" \
  "main should now be at the branch's HEAD" || fail "main did not advance"

# --- the base really has moved -> that is what it says ----------------------

repo_moved=$(gitfixture_new)
wt_moved=$(make_worktree "$repo_moved" wt feature)
gitfixture_commit "$wt_moved" "feat: on the branch" >/dev/null
gitfixture_commit "$repo_moved" "feat: on main, after the branch started" >/dev/null

run_finish "$wt_moved" integrate --ff-only
[ "$rc" -ne 0 ] || fail "integrating onto a moved base should be non-zero"
assert_contains "$out" "not a fast-forward" \
  "a moved base should be named as such" || fail "moved-base message missing"

# --- an untracked file in the way is NOT reported as a moved base ----------

repo_clash=$(gitfixture_new)
wt_clash=$(make_worktree "$repo_clash" wt feature)
printf 'from the branch\n' > "$wt_clash/collides.txt"
git -C "$wt_clash" add collides.txt
git -C "$wt_clash" commit -q -m "feat: add a file the main checkout also has"
printf 'untracked, in the way\n' > "$repo_clash/collides.txt"

run_finish "$wt_clash" integrate --ff-only
[ "$rc" -ne 0 ] || fail "a working-tree collision should be non-zero"
! printf '%s' "$out" | grep -qF "not a fast-forward" \
  || fail "a working-tree collision must not be reported as a moved base"
assert_contains "$out" "collides.txt" \
  "the failure should name the file in the way" || fail "the colliding path is not named"

echo "ok"
