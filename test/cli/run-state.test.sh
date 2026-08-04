#!/usr/bin/env bash
# Pins skills/implement/scripts/run-state: begin writes the marker and
# refuses a second one, show prints it, end removes every marker. Every
# invocation runs with a throwaway gitfixture repository as the working
# directory — run-state resolves its own repository from the cwd, and a case
# that forgot this would write a RUN marker into the repository these tests
# themselves live in.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$here/../.." && pwd)"

. "$repo_root/test/lib/harness.sh"
. "$repo_root/test/lib/gitfixture.sh"

runstate="$repo_root/skills/implement/scripts/run-state"

fail() {
  echo "run-state.test.sh: $1" >&2
  exit 1
}

# run_runstate REPO [ARGS...] — sets $out and $rc in the caller. Called as a
# plain statement, never wrapped in $(...), for the same reason
# test/cli/preflight.test.sh's run_preflight is: $rc has to survive the call.
run_runstate() {
  local repo="$1"
  shift
  out=$(cd "$repo" && "$runstate" "$@" 2>&1)
  rc=$?
}

marker_of() {
  # marker_of OUT — pulls the "marker: <path>" line begin prints on success.
  printf '%s\n' "$1" | sed -n 's/^marker: //p'
}

# --- begin on a clean fixture: exit 0, marker written with every field ------

repo1=$(gitfixture_new)
base_sha=$(git -C "$repo1" rev-parse HEAD)
gitfixture_commit "$repo1" "chore: second commit" >/dev/null
[ "$base_sha" != "$(git -C "$repo1" rev-parse HEAD)" ] \
  || fail "test setup: BASE and HEAD must differ for the base= assertion to mean anything"
plan1=$(gitfixture_plan "$repo1")

run_runstate "$repo1" begin "$plan1" "$base_sha"
[ "$rc" -eq 0 ] || fail "begin on a clean fixture should exit 0"

marker1=$(marker_of "$out")
[ -f "$marker1" ] || fail "begin should print the marker path it wrote, and it should exist: $marker1"
content1=$(cat "$marker1")

assert_contains "$content1" "plan=$plan1" "marker should carry plan=" || fail "plan= missing"
assert_contains "$content1" "base=" "marker should carry base=" || fail "base= missing"
assert_contains "$content1" "branch=" "marker should carry branch=" || fail "branch= missing"
assert_contains "$content1" "tree=$repo1" "marker should carry tree=" || fail "tree= missing"
assert_contains "$content1" "started=" "marker should carry started=" || fail "started= missing"

# --- base= is the full SHA of BASE, not of HEAD ------------------------------

got_base=$(sed -n 's/^base=//p' "$marker1")
assert_eq "$base_sha" "$got_base" "base= must equal the SHA passed as BASE" \
  || fail "base= is not the argument's SHA"

started=$(sed -n 's/^started=//p' "$marker1")
case "$started" in
  [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z) : ;;
  *) fail "started= should match YYYY-MM-DDTHH:MM:SSZ, got: $started" ;;
esac

# --- begin a second time: exit 3, a run-in-progress message, first marker intact

plan1b=$(gitfixture_plan "$repo1" "$repo_root/test/fixtures/plan-frozen.md")
run_runstate "$repo1" begin "$plan1b" "$base_sha"
[ "$rc" -eq 3 ] || fail "a second begin should exit 3"
assert_contains "$out" "a run is already in progress" \
  "the second begin should name a run already in progress" || fail "message missing"
content1_after=$(cat "$marker1")
assert_eq "$content1" "$content1_after" \
  "the first marker must be unchanged by a refused second begin" || fail "first marker changed"

# --- show with no run: exit 1, no run in progress ----------------------------

repo4=$(gitfixture_new)
run_runstate "$repo4" show
[ "$rc" -eq 1 ] || fail "show with no run should exit 1"
assert_contains "$out" "no run in progress" "show should say no run in progress" \
  || fail "message missing"

# --- end after begin: marker gone, exit 0; end again: exit 1 ----------------

repo5=$(gitfixture_new)
plan5=$(gitfixture_plan "$repo5")
run_runstate "$repo5" begin "$plan5" HEAD
[ "$rc" -eq 0 ] || fail "test setup: begin for the end case should succeed"
marker5=$(marker_of "$out")

run_runstate "$repo5" end
[ "$rc" -eq 0 ] || fail "end after begin should exit 0"
[ ! -f "$marker5" ] || fail "end should remove the marker"

run_runstate "$repo5" end
[ "$rc" -eq 1 ] || fail "end with nothing left to clear should exit 1"

# --- begin with a bad BASE: exit 2, bad BASE ---------------------------------

repo6=$(gitfixture_new)
plan6=$(gitfixture_plan "$repo6")
run_runstate "$repo6" begin "$plan6" not-a-real-ref
[ "$rc" -eq 2 ] || fail "begin with a bad BASE should exit 2"
assert_contains "$out" "bad BASE" "the bad-BASE message should be printed" \
  || fail "message missing"

# --- begin with a missing plan file: exit 2 ----------------------------------

repo7=$(gitfixture_new)
missing_plan="$repo7/does-not-exist.md"
run_runstate "$repo7" begin "$missing_plan" HEAD
[ "$rc" -eq 2 ] || fail "begin with a missing plan file should exit 2"
assert_contains "$out" "no such plan file: $missing_plan" \
  "the missing-plan message should name the path" || fail "message missing"

# --- two markers on disk: end removes both, exits 0 --------------------------

repo8=$(gitfixture_new)
plan8=$(gitfixture_plan "$repo8")
run_runstate "$repo8" begin "$plan8" HEAD
[ "$rc" -eq 0 ] || fail "test setup: begin for the two-marker case should succeed"

# begin refuses a second run, so the extra marker is written straight to disk
# under a different plan name, as the phase's How field directs.
other_dir=$(mktemp_dir)
plan8b="$other_dir/other-plan.md"
printf '# Other Plan\n' > "$plan8b"
gitfixture_marker "$repo8" "$plan8b" HEAD >/dev/null

run_runstate "$repo8" end
[ "$rc" -eq 0 ] || fail "end with two markers should exit 0"
remaining=$(cd "$repo8" && find .ai-workflow/run -name RUN 2>/dev/null)
[ -z "$remaining" ] || fail "end should remove every marker, found: $remaining"

echo "ok"
