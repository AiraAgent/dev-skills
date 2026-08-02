#!/usr/bin/env python3
"""Check the reference layer of the dev-skills tree.

Walks skills/, agents/ and hooks/ from the repo root, reads every .md file,
and checks three things line by line (skipping anything inside a fenced
code block):

  R1 file links      - [text](target) resolves to a file that exists
  R2 namespace        - dev-skills:<name> names a skill under skills/ or an
                        agent under agents/
  R3 legacy tokens     - ds-<name>, diagnose, brainstorming,
                        test-driven-development, grill-me, to-plan,
                        to-implement are findings unless allowlisted

Exit code is 0 when there are no findings, 1 otherwise.
"""

import os
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
WALK_DIRS = ("skills", "agents", "hooks")
ALLOWLIST_PATH = Path(__file__).resolve().parent / "link-allow.txt"
SKILLS_DIR = REPO_ROOT / "skills"
AGENTS_DIR = REPO_ROOT / "agents"

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


def find_md_files():
    files = []
    for d in WALK_DIRS:
        base = REPO_ROOT / d
        if not base.is_dir():
            continue
        for root, _dirs, names in os.walk(base):
            for name in names:
                if name.endswith(".md"):
                    files.append(Path(root) / name)
    return sorted(files)


def load_allowlist():
    allowed = set()
    if ALLOWLIST_PATH.exists():
        for line in ALLOWLIST_PATH.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            allowed.add(line)
    return allowed


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


def check_r3(path, lineno, line, findings, allowed):
    key = f"{rel(path)}:{lineno}"
    if key in allowed:
        return
    tokens = [m.group(0) for m in DS_TOKEN_RE.finditer(line)]
    tokens += [m.group(0) for m in LEGACY_WORD_RE.finditer(line)]
    for token in tokens:
        findings["R3"].append(f"{key}: R3 legacy token '{token}'")


def main():
    allowed = load_allowlist()
    findings = {"R1": [], "R2": [], "R3": []}

    for path in find_md_files():
        for lineno, line in iter_unfenced_lines(path):
            check_r1(path, lineno, line, findings)
            check_r2(path, lineno, line, findings)
            check_r3(path, lineno, line, findings, allowed)

    for rule in ("R1", "R2", "R3"):
        for msg in findings[rule]:
            print(msg)

    total = 0
    for rule in ("R1", "R2", "R3"):
        count = len(findings[rule])
        total += count
        print(f"{rule}: {count} finding{'s' if count != 1 else ''}")

    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
