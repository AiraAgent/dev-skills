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
out=$("$repo_root/scripts/test" "test/unit/test_segment_dispatch.py" 2>&1)
lines=$(printf '%s\n' "$out" | grep -cE '^(ok|FAIL)[[:space:]]')
[ "$lines" -eq 1 ] || fail "scripts/test test/unit/test_segment_dispatch.py should print exactly one file's line, got $lines"
assert_contains "$out" "test/unit/test_segment_dispatch.py" \
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

echo "ok"
