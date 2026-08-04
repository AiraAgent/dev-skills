#!/usr/bin/env bash
# Pins skills/finish/scripts/finish's squash and recover: squash collapses the
# run's commits into one, writes a recovery ref at the pre-squash HEAD, and
# preserves the tree exactly; recover restores the pre-squash state from that
# ref; a non-Conventional subject is refused before anything is reset.
#
# Every invocation runs with a throwaway gitfixture repository as the working
# directory — finish resolves its own repository root from the cwd, and a
# case that forgot this would run squash or recover against the repository
# these tests themselves live in.
#
# This also pins the single-ref behaviour that migration commit (4) deliberately
# replaces with numbered refs — expected to fail there, loudly, and not to be
# softened to survive it.
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

# --- recover with no ref: non-zero, no recovery ref -------------------------
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

recovery_sha=$(git -C "$repo1" rev-parse refs/finish/recovery)
assert_eq "$head_before_squash" "$recovery_sha" \
  "the recovery ref should resolve to the pre-squash HEAD" || fail "recovery ref wrong"

# --- recover: HEAD back at the pre-squash commit, ref still there ----------

run_finish "$repo1" recover
[ "$rc" -eq 0 ] || fail "recover should exit 0"
head_after_recover=$(git -C "$repo1" rev-parse HEAD)
assert_eq "$head_before_squash" "$head_after_recover" \
  "recover should restore the pre-squash HEAD" || fail "HEAD not restored"
git -C "$repo1" rev-parse --verify --quiet refs/finish/recovery >/dev/null \
  || fail "the recovery ref should still exist after recover"

echo "ok"
