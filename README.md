# dev-skills

A Claude Code plugin: 23 skills for planning, building, and reviewing software
work, plus the subagents and guard hooks the pipeline runs on. Each skill
documents its own use inside its `SKILL.md`; this file covers what the plugin
is, how to install it, and where its material comes from.

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

```
/plugin marketplace add bmox0/dev-skills
/plugin install dev-skills@dev-skills
```

Then restart the session. The repository carries its own
[`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json), so it is a
marketplace holding exactly one plugin — itself. Claude Code clones it, keeps it
current, and `/plugin uninstall dev-skills` takes it back out again.

What arrives is more than the table above:

- **23 skills.** Ten of them — the pipeline entries — carry
  `disable-model-invocation`, so the model cannot start them by itself. You type
  them, or they do not run.
- **3 subagents** — `implementer`, `implement-review` and `final-review`,
  dispatched by [`dev-skills:implement`](skills/implement/SKILL.md) and never
  invoked directly.
- **4 hooks** ([`hooks/hooks.json`](hooks/hooks.json)) — a session-start note
  naming the entries, plus three git guards: commit discipline on every commit,
  history surgery reserved for `dev-skills:finish` while a run is open, and
  default-branch protection in repositories that opt in with a `.branch-guard`
  file at their root.

## Licence

MIT — see [LICENSE](LICENSE).
