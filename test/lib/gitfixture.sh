#!/usr/bin/env bash
# The throwaway repository every test/cli/*.test.sh that drives a git-writing
# script needs, so that pinning preflight, run-state and finish never touches
# the repository these tests themselves live in.
#
# Sourced after test/lib/harness.sh — every repository this file hands out is
# built with gitfixture_new, which is built on mktemp_dir, so cleanup rides
# harness.sh's own EXIT trap and needs no separate teardown here.
#
# gitfixture_new     -> prints the repository path
# gitfixture_plan REPO [SRC]   -> writes a plan file, prints its path
# gitfixture_gitignore REPO    -> commits a .gitignore carrying .ai-workflow
# gitfixture_dirty REPO        -> leaves one staged and one unstaged change
# gitfixture_commit REPO MSG   -> one commit, prints its SHA
# gitfixture_branch REPO NAME  -> creates and checks out a branch
# gitfixture_marker REPO PLAN BASE -> writes
#   REPO/.ai-workflow/run/<plan-basename>/RUN with plan=, base=, branch= and
#   tree= lines; prints the marker's path
#
# Every helper that takes a REPO argument refuses to run when that path
# resolves inside the repository this file itself lives in — the one thing a
# fixture must never be.

# Captured once, from where this file lives on disk rather than from the
# caller's cwd at call time: later phases run their cases with a fixture as
# the working directory, and a check based on cwd would then be comparing the
# fixture against itself.
_gitfixture_real_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && git rev-parse --show-toplevel 2>/dev/null)"

_gitfixture_guard() {
  local repo="$1" top
  top="$(git -C "$repo" rev-parse --show-toplevel 2>/dev/null)" || return 0
  case "$top" in
    "$_gitfixture_real_root"|"$_gitfixture_real_root"/*)
      echo "gitfixture: refusing — $repo resolves inside the repository under work ($_gitfixture_real_root)" >&2
      return 1
      ;;
  esac
  return 0
}

gitfixture_new() {
  local dir
  dir=$(mktemp_dir)
  git -C "$dir" init -q -b main
  # mktemp_dir's raw path can run through a symlink (macOS's /tmp ->
  # /private/tmp, TMPDIR under /var/folders -> /private/var/folders); resolve
  # to the same physical path `git rev-parse --show-toplevel` reports, so a
  # caller comparing the two sees them equal. Cleanup already rides the raw
  # path registered inside mktemp_dir above, so this reassignment does not
  # affect it — the two paths remove the same directory either way.
  dir="$(git -C "$dir" rev-parse --show-toplevel)"
  git -C "$dir" config user.email "fixture@example.com"
  git -C "$dir" config user.name "gitfixture"
  printf '# fixture\n' > "$dir/README.md"
  git -C "$dir" add README.md
  git -C "$dir" commit -q -m "chore: initial commit"
  echo "$dir"
}

gitfixture_plan() {
  local repo="$1" src="${2:-}"
  _gitfixture_guard "$repo" || return 1
  local dest="$repo/plan.md"
  if [ -n "$src" ]; then
    cp "$src" "$dest"
  else
    printf '# Fixture Plan\n' > "$dest"
  fi
  echo "$dest"
}

# The state preflight wants to find rather than have to create: the ignore line
# already there, and the file already tracked. A fixture without this is the
# untracked-.gitignore case, which is a finding in its own right.
gitfixture_gitignore() {
  local repo="$1"
  _gitfixture_guard "$repo" || return 1
  printf '.ai-workflow\n' > "$repo/.gitignore"
  git -C "$repo" add .gitignore
  git -C "$repo" commit -q -m "chore: ignore .ai-workflow"
}

gitfixture_dirty() {
  local repo="$1"
  _gitfixture_guard "$repo" || return 1
  printf 'staged line\n' >> "$repo/README.md"
  git -C "$repo" add README.md
  printf 'unstaged line\n' >> "$repo/README.md"
}

gitfixture_commit() {
  local repo="$1" msg="$2"
  _gitfixture_guard "$repo" || return 1
  # A real tree change, not --allow-empty: a caller squashing several of
  # these needs the tree to actually differ commit to commit, so that
  # preserving vs. discarding the range is something an assertion can tell
  # apart.
  printf '%s\n' "$msg" >> "$repo/CHANGELOG.txt"
  git -C "$repo" add CHANGELOG.txt
  git -C "$repo" commit -q -m "$msg"
  git -C "$repo" rev-parse HEAD
}

gitfixture_branch() {
  local repo="$1" name="$2"
  _gitfixture_guard "$repo" || return 1
  git -C "$repo" checkout -q -b "$name"
}

gitfixture_marker() {
  local repo="$1" plan="$2" base="$3"
  _gitfixture_guard "$repo" || return 1
  local slug dir
  slug=$(basename "$plan" .md)
  dir="$repo/.ai-workflow/run/$slug"
  mkdir -p "$dir"
  {
    echo "plan=$plan"
    echo "base=$(git -C "$repo" rev-parse "$base")"
    echo "branch=$(git -C "$repo" rev-parse --abbrev-ref HEAD)"
    echo "tree=$repo"
  } > "$dir/RUN"
  echo "$dir/RUN"
}
