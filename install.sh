#!/usr/bin/env bash
# The installer. Symlinks this repo's root at ~/.claude/skills/dev-skills, so
# Claude Code loads it as an @skills-dir plugin: skills/ is scanned flat and
# implicitly, agents/ is discovered from the plugin root, and hooks/hooks.json
# wires the guard hooks. One link, and an edit in this repo is picked up live
# — no reinstall. It only ever creates that link, and never touches a real
# file or directory it didn't make.
#
# It also sweeps away what the old per-skill, per-agent install left behind:
# any dangling symlink under ~/.claude/skills or ~/.claude/agents — target
# gone, because the tree that install pointed at doesn't exist at those paths
# any more — and, under ~/.claude/agents only, any symlink named after one of
# this plugin's own agents whose target is a same-named file under another
# checkout's agents/ directory *and* that checkout's own
# .claude-plugin/plugin.json has a top-level "name" of "dev-skills" —
# checked with python3, not string-matched, so a nested "name" (e.g. under
# "author") can't false-match. If the manifest is missing, isn't valid JSON,
# or python3 isn't on PATH, that link is left alone: unverifiable ownership
# means no prune. That case is the three agent links (implementer,
# implement-review, final-review) the old install made straight to
# agents/*.md: their targets never moved, so the dangling sweep can't see
# them, and left alone they'd survive as user-level agents duplicating the
# plugin's own — including when install.sh is run from a different dev-skills
# checkout than the one those stale links point into. Both sweeps stop at the
# same line: never a real file, never a link pointing somewhere unrelated.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DEST="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
AGENTS_DEST="${CLAUDE_AGENTS_DIR:-$HOME/.claude/agents}"
LINK_NAME="dev-skills"

DRY=0 REPLACE=0
for a in "$@"; do
  case "$a" in
    --dry-run) DRY=1 ;;
    --replace) REPLACE=1 ;;
    *) echo "usage: $0 [--dry-run] [--replace]" >&2; exit 64 ;;
  esac
done

mkdir -p "$SKILLS_DEST" "$AGENTS_DEST"

linked=0 skipped=0 collided=0 replaced=0 pruned=0 py3_warned=0

link_one() {
  local src="$1" target="$2" name="$3"

  if [[ -L "$target" && "$target" -ef "$src" ]]; then
    echo "  ok        $name (already linked here)"
    skipped=$((skipped+1))
    return
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    if [[ $REPLACE -eq 1 ]]; then
      if [[ $DRY -eq 1 ]]; then
        echo "  would replace $name"
      else
        rm -rf "$target"
        ln -s "$src" "$target"
        echo "  replaced  $name"
      fi
      replaced=$((replaced+1))
      return
    fi
    echo "  COLLIDE   $name (exists and isn't our link — use --replace)" >&2
    collided=$((collided+1))
    return
  fi

  if [[ $DRY -eq 1 ]]; then
    echo "  would link $name"
  else
    ln -s "$src" "$target"
    echo "  linked    $name"
  fi
  linked=$((linked+1))
}

link_one "$ROOT" "$SKILLS_DEST/$LINK_NAME" "$LINK_NAME"

prune_dangling() {
  local dest="$1" link
  for link in "$dest"/*; do
    [[ -L "$link" ]] || continue
    [[ -e "$link" ]] && continue
    if [[ $DRY -eq 1 ]]; then
      echo "  would prune $(basename "$link") -> $(readlink "$link") (target gone)"
    else
      rm "$link"
      echo "  pruned    $(basename "$link") (target gone)"
    fi
    pruned=$((pruned+1))
  done
}

# True when $1 is a readable, valid-JSON plugin manifest whose top-level
# "name" is exactly "dev-skills". Anything short of that — file missing,
# JSON invalid, python3 unavailable — is treated as "can't verify", so the
# caller must not prune: false, not an error, is the deliberate default.
manifest_names_dev_skills() {
  local manifest="$1"
  [[ -f "$manifest" ]] || return 1
  if ! command -v python3 >/dev/null 2>&1; then
    if [[ $py3_warned -eq 0 ]]; then
      echo "install.sh: python3 not found on PATH — skipping the agent-link manifest check, so no stale agent links will be pruned" >&2
      py3_warned=1
    fi
    return 1
  fi
  python3 -c '
import json, sys
try:
    with open(sys.argv[1], "r", encoding="utf-8") as f:
        data = json.load(f)
except Exception:
    sys.exit(1)
sys.exit(0 if isinstance(data, dict) and data.get("name") == "dev-skills" else 1)
' "$manifest"
}

prune_repo_links() {
  # Only under $dest, only a symlink, and only when its basename matches one
  # of this plugin's own agent files (from $ROOT/agents/*.md), it resolves to
  # a regular file with that same name inside a directory literally named
  # "agents", *and* that directory's parent has a .claude-plugin/plugin.json
  # whose top-level "name" is "dev-skills" (see manifest_names_dev_skills).
  # The shape check alone (agents/<name>.md) isn't enough — that's the
  # generic layout of any Claude Code plugin — so the manifest check is what
  # proves the target belongs to a dev-skills checkout rather than merely
  # looking like one. A real file or directory, a link whose basename isn't
  # one of ours, or one that resolves anywhere else, is left alone.
  local dest="$1" link name resolved parent root manifest
  for link in "$dest"/*; do
    [[ -L "$link" ]] || continue
    [[ -e "$link" ]] || continue
    name="$(basename "$link")"
    [[ -f "$ROOT/agents/$name" ]] || continue
    resolved="$(realpath "$link" 2>/dev/null || true)"
    [[ -n "$resolved" ]] || continue
    [[ -f "$resolved" ]] || continue
    parent="$(dirname "$resolved")"
    [[ "$(basename "$resolved")" == "$name" && "$(basename "$parent")" == "agents" ]] || continue
    root="$(dirname "$parent")"
    manifest="$root/.claude-plugin/plugin.json"
    manifest_names_dev_skills "$manifest" || continue
    if [[ $DRY -eq 1 ]]; then
      echo "  would prune $(basename "$link") -> $(readlink "$link") (now served by the $LINK_NAME plugin)"
    else
      rm "$link"
      echo "  pruned    $(basename "$link") (now served by the $LINK_NAME plugin)"
    fi
    pruned=$((pruned+1))
  done
}

prune_dangling "$SKILLS_DEST"
prune_dangling "$AGENTS_DEST"
prune_repo_links "$AGENTS_DEST"

echo
echo "linked: $linked  replaced: $replaced  pruned: $pruned  already-present: $skipped  collisions: $collided"
[[ $collided -gt 0 ]] && exit 2 || exit 0
