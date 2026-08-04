#!/usr/bin/env bash
# Pins skills/implement/scripts/segment-contract without --built: the
# extractor that assembles a segment's "Frozen for later phases" fields,
# using test/fixtures/plan-frozen.md as generic plan input.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$here/../.." && pwd)"

. "$repo_root/test/lib/harness.sh"

script="$repo_root/skills/implement/scripts/segment-contract"
plan="$repo_root/test/fixtures/plan-frozen.md"

fail() {
  echo "segment-contract.test.sh: $1" >&2
  exit 1
}

# run_to_file RANGE — sets $outfile and $rc in the caller. Not invoked
# through command substitution: it needs to set $rc as a real side effect,
# and command substitution would fork a subshell that loses it (the same
# reason mktemp_dir itself uses a registry file, not an array).
run_to_file() {
  local range="$1"
  local dir
  dir=$(mktemp_dir)
  outfile="$dir/out.md"
  "$script" "$plan" "$range" "$outfile" >/dev/null 2>"$dir/stderr"
  rc=$?
}

# --- RANGE=2: only phase 2's frozen lines --------------------------------

run_to_file 2
[ "$rc" -eq 0 ] || fail "RANGE=2 should exit 0"
out=$(cat "$outfile")

assert_contains "$out" "phase_two_frozen_name" \
  "range-2 must include phase 2's frozen line" || fail "phase 2 frozen missing"
! printf '%s' "$out" | grep -qF "first_frozen_name" \
  || fail "range-2 must not include phase 1's frozen content"
! printf '%s' "$out" | grep -qF "phase_three_frozen_name" \
  || fail "range-2 must not include phase 3's frozen content"
! printf '%s' "$out" | grep -qF "phase 2's own distinctive becomes-true marker" \
  || fail "range-2 must not include phase 2's own Becomes true line"

# --- RANGE=2-3: both ends inclusive ---------------------------------------

run_to_file 2-3
[ "$rc" -eq 0 ] || fail "RANGE=2-3 should exit 0"
out=$(cat "$outfile")

assert_contains "$out" "phase_two_frozen_name" \
  "range-2-3 must include phase 2 (the range's first end)" || fail "phase 2 missing"
assert_contains "$out" "phase_three_frozen_name" \
  "range-2-3 must include phase 3 (the range's last end)" || fail "phase 3 missing"

# --- a range whose phases freeze nothing: the fallback text, not an empty file --

run_to_file 4
[ "$rc" -eq 0 ] || fail "RANGE=4 should exit 0"
out=$(cat "$outfile")

assert_contains "$out" "Nothing in this segment is off limits to ordinary findings" \
  "range-4 (phase 4 freezes nothing) must show the fallback text" || fail "fallback text missing"
[ -n "$out" ] || fail "range-4 output must not be empty"

# --- the fenced block inside a phase body does not leak into the output ---

run_to_file 1
[ "$rc" -eq 0 ] || fail "RANGE=1 should exit 0"
out=$(cat "$outfile")

! printf '%s' "$out" | grep -qF "fenced_leak_name" \
  || fail "the fenced block inside phase 1's How field must not leak into the output"
assert_contains "$out" "first_frozen_name" \
  "range-1 must still include phase 1's real frozen content" || fail "phase 1 frozen missing"

# --- bad ranges -------------------------------------------------------------

err=$("$script" "$plan" "4-2" 2>&1 1>/dev/null)
rc=$?
[ "$rc" -eq 2 ] || fail "RANGE=4-2 should exit 2"
assert_contains "$err" "bad RANGE: 4-2" \
  "RANGE=4-2 should report bad RANGE: 4-2 on stderr" || fail "message missing"

err=$("$script" "$plan" "abc" 2>&1 1>/dev/null)
rc=$?
[ "$rc" -eq 2 ] || fail "RANGE=abc should exit 2"
assert_contains "$err" "bad RANGE: abc (want 3 or 2-4)" \
  "RANGE=abc should report bad RANGE: abc (want 3 or 2-4) on stderr" || fail "message missing"

# --- no RANGE at all: the usage line, not a bad-RANGE message --------------

err=$("$script" "$plan" 2>&1 1>/dev/null)
rc=$?
[ "$rc" -eq 2 ] || fail "no RANGE at all should exit 2"
assert_contains "$err" "usage: segment-contract" \
  "no RANGE at all should print the usage line" || fail "usage line missing"

echo "ok"
