#!/usr/bin/env bash
# Pins test/lib/harness.sh's four assertions and mktemp_dir, plus
# scripts/test --mutations on a manifest that holds nothing to walk.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$here/../.." && pwd)"

. "$repo_root/test/lib/harness.sh"

fail() {
  echo "harness.test.sh: $1" >&2
  exit 1
}

# --- assert_eq -------------------------------------------------------------

assert_eq a a "a should equal a" || fail "assert_eq a a should pass"

err=$(assert_eq a b "a should equal b" 2>&1)
rc=$?
[ "$rc" -ne 0 ] || fail "assert_eq a b should fail"
assert_contains "$err" "a should equal b" \
  "assert_eq failure should put its message on stderr" || fail "message missing"

# --- assert_contains ---------------------------------------------------------

assert_contains "abc" b "b should be found in abc" || fail "assert_contains abc b should pass"

err=$(assert_contains "abc" z "z should be found in abc" 2>&1)
rc=$?
[ "$rc" -ne 0 ] || fail "assert_contains abc z should fail"
assert_contains "$err" "z should be found in abc" \
  "assert_contains failure should put its message on stderr" || fail "message missing"

# --- assert_exit -------------------------------------------------------------

(exit 2)
assert_exit 2 "should have exited 2" || fail "assert_exit 2 after exit 2 should pass"

(exit 0)
assert_exit 2 "should have exited 2" 2>/dev/null
rc=$?
[ "$rc" -ne 0 ] || fail "assert_exit 2 after exit 0 should fail"

# --- scripts/test --mutations on an empty manifest -----------------------

fixture=$(mktemp_dir)
mkdir -p "$fixture/scripts" "$fixture/test/mutations"
cp "$repo_root/scripts/test" "$fixture/scripts/test"
chmod +x "$fixture/scripts/test"
printf 'id\ttarget\tpatch\texpect-fail\n' > "$fixture/test/mutations/manifest.tsv"

out=$("$fixture/scripts/test" --mutations 2>&1)
rc=$?
[ "$rc" -eq 0 ] || fail "scripts/test --mutations on a header-only manifest should exit 0"
assert_contains "$out" "no mutations" \
  "scripts/test --mutations on a header-only manifest should say so" || fail "no mutations text missing"

# --- mktemp_dir --------------------------------------------------------------

probe_dir=$(mktemp_dir)
probe="$probe_dir/probe.sh"
cat > "$probe" <<EOF
#!/usr/bin/env bash
set -euo pipefail
. "$repo_root/test/lib/harness.sh"
d1=\$(mktemp_dir)
d2=\$(mktemp_dir)
printf '%s\n%s\n' "\$d1" "\$d2"
EOF
chmod +x "$probe"

paths=$("$probe")
d1=$(printf '%s\n' "$paths" | sed -n '1p')
d2=$(printf '%s\n' "$paths" | sed -n '2p')

[ -n "$d1" ] && [ -n "$d2" ] || fail "mktemp_dir should print a path each time"
[ "$d1" != "$d2" ] || fail "mktemp_dir called twice should give two different paths"
[ ! -d "$d1" ] || fail "mktemp_dir's first directory should be removed once the sourcing process exits"
[ ! -d "$d2" ] || fail "mktemp_dir's second directory should be removed once the sourcing process exits"

# --- scripts/test <path>: single-file mode -----------------------------
#
# The .test.sh case below targets test/cli/gitfixture.test.sh rather than
# this file: pointing it at harness.test.sh itself made the suite invoke
# itself, and every mechanism tried for bounding that recursion turned out
# to be forgeable from the environment it runs in. This removes only the
# direct path, not recursion itself — if run_one ever regressed to
# ignoring its argument, any `scripts/test <path>` would fall back to the
# whole suite, which includes this file, which would invoke `scripts/test`
# again, one level deeper each time. That is accepted rather than bounded:
# it still ends in a correct failure, just a slow one, and a slow red is a
# different problem than the silent pass this file exists to catch.

# the python suite alone, by the same argument form as a .test.sh file.
# Asserted by shape (exactly one file reported, and it names this suite),
# not by exit code: a dispatch-* mutation can legitimately make this
# suite fail on its own terms, and that must not read as this case
# failing too.
out=$("$repo_root/scripts/test" "test/unit/test_dispatch.py" 2>&1)
lines=$(printf '%s\n' "$out" | grep -cE '^(ok|FAIL)[[:space:]]')
[ "$lines" -eq 1 ] || fail "scripts/test test/unit/test_dispatch.py should print exactly one file's line, got $lines"
assert_contains "$out" "test/unit/test_dispatch.py" \
  "single-file run of the python suite should report its own line" || fail "own line missing"

# a .test.sh file other than this one (see above) — that file's line only
out=$("$repo_root/scripts/test" "test/cli/gitfixture.test.sh" 2>&1)
rc=$?
[ "$rc" -eq 0 ] || fail "scripts/test test/cli/gitfixture.test.sh should exit 0"
lines=$(printf '%s\n' "$out" | grep -cE '^(ok|FAIL)[[:space:]]')
[ "$lines" -eq 1 ] || fail "scripts/test test/cli/gitfixture.test.sh should print exactly one file's line, got $lines"
assert_contains "$out" "test/cli/gitfixture.test.sh" \
  "single-file run should report its own line" || fail "own line missing"

# a path that is not a test file: loud, not a silent fallback to everything
err=$("$repo_root/scripts/test" "test/lib/harness.sh" 2>&1 1>/dev/null)
rc=$?
[ "$rc" -ne 0 ] || fail "scripts/test with a non-test-file path should exit non-zero"
assert_contains "$err" "test/lib/harness.sh" \
  "the error should name the path that isn't a test file" || fail "path not named"

# --- TC-9, TC-10, TC-11, TC-12: the run's final-gate scenarios --------------
#
# None of these pin one script's behaviour the way the rest of test/cli/ does
# — they check the assembled repository's own shape (frontmatter, vocabulary,
# the mutation net) rather than any one skills/implement/scripts/* binary, so
# there is no more specific existing file to carry them and the plan
# authorises no new one. This file already exercises scripts/test on the real
# tree above; these run against the real tree too, never a synthetic fixture.

# frontmatter FILE — the YAML block between the first two '---' lines, or
# nothing if the file has none.
frontmatter() {
  awk 'NR==1 && $0=="---" {p=1; next} p && $0=="---" {exit} p' "$1"
}

# --- TC-9: scripts/check passes; disable-model-invocation on exactly two ---

check_out=$("$repo_root/scripts/check" 2>&1)
check_rc=$?
[ "$check_rc" -eq 0 ] || fail "TC-9: scripts/check should pass, got exit $check_rc: $check_out"

for skill in grill grill-with-docs plan epic scout refactor tests improve; do
  fm=$(frontmatter "$repo_root/skills/$skill/SKILL.md")
  ! printf '%s' "$fm" | grep -qi 'disable-model-invocation' \
    || fail "TC-9: skills/$skill/SKILL.md should carry no disable-model-invocation"
done

for skill in implement finish; do
  fm=$(frontmatter "$repo_root/skills/$skill/SKILL.md")
  printf '%s' "$fm" | grep -qi 'disable-model-invocation' \
    || fail "TC-9: skills/$skill/SKILL.md should still carry disable-model-invocation"
done

# --- TC-10: no mention of Haiku anywhere the model is documented -----------

haiku_out=$(cd "$repo_root" && grep -ri haiku skills/ agents/ references/ README.md 2>/dev/null)
[ -z "$haiku_out" ] || fail "TC-10: expected no match for haiku, found: $haiku_out"

# --- TC-11: no retired 'Checkpoint N' or '| Segment |' outside the vocabulary

checkpoint_out=$(cd "$repo_root" && grep -rn 'Checkpoint [0-9]' skills/ 2>/dev/null)
[ -z "$checkpoint_out" ] || fail "TC-11: expected no match for 'Checkpoint N', found: $checkpoint_out"

segment_col_out=$(cd "$repo_root" && grep -rn '| Segment |' skills/ 2>/dev/null)
[ -z "$segment_col_out" ] || fail "TC-11: expected no match for '| Segment |', found: $segment_col_out"

# --- TC-12: the whole net is green, and the mutation floor is met ----------
#
# scripts/test discovers this very file, so calling the bulk, self-discovering
# "scripts/test" or "scripts/test --mutations" unguarded from here would have
# it re-discover and re-run this file, reach this line again, and call them
# again — depth-wise without end for the plain command (nothing here ever
# marks the tree dirty, so no natural stop), and for --mutations, worse than
# slow: a nested sweep started while an outer one already has one manifest
# row's patch applied would try to re-apply that same patch, fail to, and
# report every such row FAILED — turning a real, correct
# "scripts/test --mutations" run red by the mere act of checking it.
#
# The two checks below are structured to make each of those impossible, not
# just unlikely:
#
# - "scripts/test" is re-proved by calling scripts/test once per discovered
#   file *other than this one*, in single-file mode. Single-file mode never
#   calls the discovery this file is caught by, so there is nothing here for
#   it to recurse into, in either direction.
# - "scripts/test --mutations" is called once, in full, but only when no
#   manifest target currently differs from HEAD — which is true exactly when
#   nothing is mid-mutation. Every child scripts/test --mutations spawns
#   while a row's patch is applied sees that row's target as dirty and skips
#   this block entirely, so the real, human- or gate-invoked sweep this test
#   exists to prove never triggers a nested one of itself.
#
# The manifest's own shape — every row naming a target and a patch that
# exist — needs neither guard: it is a local file read, nothing runs.

manifest="$repo_root/test/mutations/manifest.tsv"
[ -f "$manifest" ] || fail "TC-12: manifest.tsv should exist at $manifest"

row_count=0
while IFS=$'\t' read -r id target patch expect_fail; do
  [ -n "$id" ] || continue
  row_count=$((row_count + 1))
  [ -f "$repo_root/$target" ] || fail "TC-12: manifest row '$id' names a target that does not exist: $target"
  [ -f "$repo_root/$patch" ] || fail "TC-12: manifest row '$id' names a patch that does not exist: $patch"
done < <(tail -n +2 "$manifest")
[ "$row_count" -ge 31 ] \
  || fail "TC-12: expected at least 31 mutation rows (29 baseline + plan-check's new ones), got $row_count"

# mutation_targets_dirty — true while any manifest target differs from HEAD,
# which is true exactly while some row's patch is applied mid-sweep.
mutation_targets_dirty() {
  local t
  while IFS=$'\t' read -r _id t _patch _fail; do
    [ -n "$t" ] || continue
    git -C "$repo_root" diff --quiet -- "$t" 2>/dev/null || return 0
  done < <(tail -n +2 "$manifest")
  return 1
}

if ! mutation_targets_dirty; then
  self_path="test/cli/harness.test.sh"
  discover_other_test_paths() {
    ( cd "$repo_root" && find test -type f -name '*.test.sh' 2>/dev/null | LC_ALL=C sort
      cd "$repo_root" && find test/unit -type f -name 'test_*.py' 2>/dev/null | LC_ALL=C sort ) \
      | grep -vF "$self_path"
  }
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    out=$("$repo_root/scripts/test" "$f" 2>&1)
    rc=$?
    [ "$rc" -eq 0 ] || fail "TC-12: scripts/test $f should be green, got exit $rc: $out"
  done < <(discover_other_test_paths)

  mut_out=$("$repo_root/scripts/test" --mutations 2>&1)
  mut_rc=$?
  [ "$mut_rc" -eq 0 ] \
    || fail "TC-12: scripts/test --mutations should be green (0 survivors), got exit $mut_rc: $mut_out"
  mut_count=$(printf '%s\n' "$mut_out" | grep -cE '^MUTATION ')
  [ "$mut_count" -ge 31 ] \
    || fail "TC-12: expected at least 31 mutations reported, got $mut_count"
fi

echo "ok"
