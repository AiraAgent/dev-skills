# dev-skills

A Claude Code plugin: 23 skills for planning, building, and reviewing software
work, installed as a single `@skills-dir` symlink. Each skill documents its own
use inside its `SKILL.md`; this file covers what the plugin is, how to install
it, and where its material comes from.

## Skills

| Skill | What it's for |
|---|---|
| [`dev-skills:bootstrap`](skills/bootstrap/SKILL.md) | injected at session start; states the one rule and lists what exists |
| [`dev-skills:bug`](skills/bug/SKILL.md) | reproduce a bug, find its root cause, leave behind a failing test that pins it |
| [`dev-skills:commit-work`](skills/commit-work/SKILL.md) | review and stage changes, split them into logical commits, write clear messages |
| [`dev-skills:domain-modeling`](skills/domain-modeling/SKILL.md) | build and sharpen a project's glossary, and record an ADR when one is earned |
| [`dev-skills:finish`](skills/finish/SKILL.md) | close out a run into one commit and hand it to the human |
| [`dev-skills:grill`](skills/grill/SKILL.md) | interview an idea into a shared understanding before anything is planned |
| [`dev-skills:grill-with-docs`](skills/grill-with-docs/SKILL.md) | grilling that also captures glossary terms and ADRs as they settle |
| [`dev-skills:guardrails`](skills/guardrails/SKILL.md) | set up Claude Code hooks that block dangerous git commands |
| [`dev-skills:implement`](skills/implement/SKILL.md) | execute an approved plan, from workspace through the final gate |
| [`dev-skills:improve`](skills/improve/SKILL.md) | scan a codebase for deepening opportunities, then work through one |
| [`dev-skills:merge-conflicts`](skills/merge-conflicts/SKILL.md) | resolve an in-progress git merge or rebase conflict |
| [`dev-skills:plan`](skills/plan/SKILL.md) | write the implementation plan a cold, cheap implementer can build from |
| [`dev-skills:pre-commit`](skills/pre-commit/SKILL.md) | set up Husky pre-commit hooks with lint-staged and type checking |
| [`dev-skills:prototype`](skills/prototype/SKILL.md) | build a throwaway prototype to answer a design question |
| [`dev-skills:refactor`](skills/refactor/SKILL.md) | restructure, migrate, or upgrade code without changing its behaviour |
| [`dev-skills:research`](skills/research/SKILL.md) | investigate a question against primary sources and capture the findings |
| [`dev-skills:review`](skills/review/SKILL.md) | review code against the same criteria the pipeline's own reviewers use |
| [`dev-skills:review-criteria`](skills/review-criteria/SKILL.md) | the shared standard for what counts as a review finding |
| [`dev-skills:scout`](skills/scout/SKILL.md) | map unfamiliar code and answer a specific question about it, read-only |
| [`dev-skills:spec`](skills/spec/SKILL.md) | write the spec that holds a body of work too large for one plan |
| [`dev-skills:tdd`](skills/tdd/SKILL.md) | the red-green-refactor discipline the implementer builds by |
| [`dev-skills:tests`](skills/tests/SKILL.md) | cover untested code, or repair tests that lie |
| [`dev-skills:writing-great-skills`](skills/writing-great-skills/SKILL.md) | design, audit, or edit a skill so it behaves predictably |

## Install

```bash
git clone https://github.com/bmox0/dev-skills.git
cd dev-skills
./install.sh
```

Then restart the Claude Code session. `install.sh` symlinks this repository's
root at `~/.claude/skills/dev-skills` — one link — and Claude Code loads it
from there as an `@skills-dir` plugin.

## Derivation

Two upstream projects contributed material to this plugin, both MIT licensed.
`LICENSE` names both authors alongside bmox0, and the split is worth stating
plainly rather than leaving a reader to work it out by comparison.

**`mattpocock/skills`**, by Matt Pocock, is the larger source: seventeen files,
including eight skills carried over whole — `prototype`, `research`,
`pre-commit`, `guardrails`, `merge-conflicts`, `improve`, `domain-modeling`,
and `writing-great-skills` — plus three of `plan`'s reference files.

[`obra/superpowers`](https://github.com/obra/superpowers), by Jesse Vincent, is
where this plugin started. The pipeline itself has since been rebuilt, but five
files still carry its text directly: `bug`'s four references
(`root-cause-tracing.md`, `defense-in-depth.md`, `condition-based-waiting.md`,
`condition-based-waiting-example.ts`) and `grill/references/visual-companion.md`.

Everything else in the tree is original to this plugin.

## Licence

MIT — see [LICENSE](LICENSE).
