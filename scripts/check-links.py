#!/usr/bin/env python3
"""Check the reference layer of the dev-skills tree.

Walks skills/, agents/ and hooks/ (recursively) plus the repository root's
own *.md files (root only, not recursive — this does not descend into
.ai-workflow/ or other root-level directories), reads every .md file, and
checks three things line by line (skipping anything inside a fenced code
block):

  R1 file links      - [text](target) resolves to a file that exists
  R2 namespace        - dev-skills:<name> names a skill under skills/ or an
                        agent under agents/
  R3 legacy tokens     - ds-<name>, diagnose, brainstorming,
                        test-driven-development, grill-me, to-plan,
                        to-implement are findings unless allowlisted

An R3 finding is suppressed by scripts/link-allow.txt, one
`path:line:token` entry per line: suppression applies only when the named
token is the one found at that exact path and line, so a different token on
the same line — or a second legacy token sharing the line with an
allowlisted one — is still reported. An allowlist entry that matches
nothing in the tree today, because the line moved, the token isn't there
anymore, or the file is gone, is itself a finding, reported as ALLOWLIST.
A malformed entry (missing the `:token` field) is refused outright: the
check prints the problem to stderr and exits 1 rather than guessing at what
was meant.

Exit code is 0 when there are no findings, 1 otherwise.
"""

import os
import re
import sys
from collections import namedtuple
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
WALK_DIRS = ("skills", "agents", "hooks")
ALLOWLIST_PATH = Path(__file__).resolve().parent / "link-allow.txt"
SKILLS_DIR = REPO_ROOT / "skills"
AGENTS_DIR = REPO_ROOT / "agents"

RULES = ("R1", "R2", "R3", "ALLOWLIST")

FENCE_RE = re.compile(r"^\s*`{3,}")
LINK_RE = re.compile(r"\[([^\]]*)\]\(([^)]+)\)")
SCHEME_RE = re.compile(r"^[A-Za-z][A-Za-z0-9+.-]*:")
NAMESPACE_RE = re.compile(r"\bdev-skills:([A-Za-z0-9][A-Za-z0-9-]*)")
DS_TOKEN_RE = re.compile(r"\bds-[A-Za-z0-9][A-Za-z0-9-]*\b")
LEGACY_WORDS = (
    "diagnose",
    "brainstorming",
    "test-driven-development",
    "grill-me",
    "to-plan",
    "to-implement",
)
LEGACY_WORD_RE = re.compile(
    r"\b(" + "|".join(re.escape(w) for w in LEGACY_WORDS) + r")\b"
)

# path:line:token — path has no colons in this tree, line is digits, token
# is a bare word (letters, digits, hyphens). Anything else, including the
# old two-field path:line form, fails to match and is refused as malformed.
ALLOW_ENTRY_RE = re.compile(
    r"^(?P<path>[^:\s][^:]*):(?P<lineno>\d+):(?P<token>[A-Za-z0-9][A-Za-z0-9-]*)$"
)

AllowEntry = namedtuple("AllowEntry", ("path", "lineno", "token"))


class AllowlistError(Exception):
    """Raised when scripts/link-allow.txt contains a malformed entry."""


def find_md_files():
    files = []
    for entry in REPO_ROOT.glob("*.md"):
        if entry.is_file():
            files.append(entry)
    for d in WALK_DIRS:
        base = REPO_ROOT / d
        if not base.is_dir():
            continue
        for root, _dirs, names in os.walk(base):
            for name in names:
                if name.endswith(".md"):
                    files.append(Path(root) / name)
    return sorted(files)


def parse_allowlist_entry(raw, source_lineno):
    m = ALLOW_ENTRY_RE.match(raw)
    if not m:
        raise AllowlistError(
            f"link-allow.txt:{source_lineno}: malformed entry {raw!r} "
            "(expected 'path:line:token')"
        )
    return AllowEntry(m.group("path"), int(m.group("lineno")), m.group("token"))


def load_allowlist():
    entries = []
    if ALLOWLIST_PATH.exists():
        for source_lineno, raw in enumerate(
            ALLOWLIST_PATH.read_text(encoding="utf-8").splitlines(), start=1
        ):
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            entries.append(parse_allowlist_entry(line, source_lineno))
    return entries


def build_allow_index(entries):
    index = {}
    for i, entry in enumerate(entries):
        index.setdefault((entry.path, entry.lineno, entry.token), []).append(i)
    return index


def iter_unfenced_lines(path):
    """Yield (lineno, line) for every line not inside a fenced code block."""
    in_fence = False
    text = path.read_text(encoding="utf-8")
    for lineno, line in enumerate(text.splitlines(), start=1):
        if FENCE_RE.match(line):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        yield lineno, line


def rel(path):
    return str(path.relative_to(REPO_ROOT))


def check_r1(path, lineno, line, findings):
    for m in LINK_RE.finditer(line):
        target = m.group(2).strip()
        if SCHEME_RE.match(target):
            continue
        if target.startswith("#"):
            continue
        target_path = target.split("#", 1)[0]
        resolved = (path.parent / target_path).resolve()
        if not resolved.exists():
            findings["R1"].append(
                f"{rel(path)}:{lineno}: R1 dangling link '{target}'"
            )


def check_r2(path, lineno, line, findings):
    for m in NAMESPACE_RE.finditer(line):
        name = m.group(1)
        skill_file = SKILLS_DIR / name / "SKILL.md"
        agent_file = AGENTS_DIR / f"{name}.md"
        if not skill_file.is_file() and not agent_file.is_file():
            findings["R2"].append(
                f"{rel(path)}:{lineno}: R2 unknown skill 'dev-skills:{name}'"
            )


def check_r3(path, lineno, line, findings, allow_index, allow_matched):
    path_key = rel(path)
    key = f"{path_key}:{lineno}"
    tokens = [m.group(0) for m in DS_TOKEN_RE.finditer(line)]
    tokens += [m.group(0) for m in LEGACY_WORD_RE.finditer(line)]
    for token in tokens:
        idxs = allow_index.get((path_key, lineno, token))
        if idxs:
            for i in idxs:
                allow_matched[i] = True
            continue
        findings["R3"].append(f"{key}: R3 legacy token '{token}'")


def main():
    try:
        allow_entries = load_allowlist()
    except AllowlistError as exc:
        print(exc, file=sys.stderr)
        return 1

    allow_index = build_allow_index(allow_entries)
    allow_matched = [False] * len(allow_entries)

    findings = {rule: [] for rule in RULES}

    for path in find_md_files():
        for lineno, line in iter_unfenced_lines(path):
            check_r1(path, lineno, line, findings)
            check_r2(path, lineno, line, findings)
            check_r3(path, lineno, line, findings, allow_index, allow_matched)

    for i, entry in enumerate(allow_entries):
        if not allow_matched[i]:
            findings["ALLOWLIST"].append(
                f"{entry.path}:{entry.lineno}: ALLOWLIST entry does not match "
                f"token '{entry.token}' at that location"
            )

    for rule in RULES:
        for msg in findings[rule]:
            print(msg)

    total = 0
    for rule in RULES:
        count = len(findings[rule])
        total += count
        print(f"{rule}: {count} finding{'s' if count != 1 else ''}")

    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
