---
name: review
description: Review code the human points at — a PR, a branch, a file, a tree — against the same criteria the pipeline's reviewers use. Outside a run, and it never fixes anything. Invoke to have code judged rather than built.
---

# Reviewing code on request

The same standard the pipeline applies inside a run, pointed at whatever the
human names.

**Announce at start:** "Using dev-skills:review to judge this against the shared
criteria."

## Why this exists next to the built-in review

The built-in review does not know the **producible-source rule**, so it offers
taste as findings — exactly what the reviewers inside a run are constrained
against. A review that mixes cited defects with preferences costs more to read
than it saves, because someone has to re-derive which is which.

This skill reads the same criteria file that `dev-skills:implement-review` and
`dev-skills:final-review` read. Sharpening the standard sharpens all three, and none of them
can drift from the others.

## Scope comes from the human

Ask for it if it is not given: a PR, a branch against a base, a range of commits,
a directory, a file. Then pin it once, as a command, and review exactly that:

```bash
git diff <base>...HEAD          # a branch, against the merge base
git diff <from>..<to>           # a fixed range
```

Confirm the range resolves and is non-empty before going further. A bad ref
should fail here.

**Say what the scope excludes**, in the report. Unchanged code that a finding
depends on is out of reach, and a reader who does not know that will read silence
as approval.

## The criteria

Read [CRITERIA.md](../review-criteria/references/CRITERIA.md) and apply it end
to end: the producible-source rule, findings versus observations, judging by
intent rather than by a step list, the smell baseline, repository conventions,
how tests are judged.

This skill does not restate it. One home, three readers.

## What is different here

Inside a run the scope comes from a plan. Here it does not, so two things change:

- **there is no phase to judge against.** The question becomes: does the code do
  what its own surroundings say it should — the repository's conventions, the
  patterns already there, the tests, the PR description or issue if there is one.
  Ask for that intent if none is available; without it you can judge the code but
  not whether it is the right code, and the report must say so;
- **there is no fix loop.** You report, and stop.

Where an originating issue or spec *is* available, judge against it too, and keep
those findings separate from the ones about how the code is written. A change can
follow every convention and implement the wrong thing; reporting them together
lets one hide the other.

## Report

- **Findings**, most serious first, each with its cited source and a file and
  line.
- **Observations** — true, out of scope, non-blocking.
- **What could not be judged** from the scope given, and why.

You judge. You do not fix, you do not edit, you do not commit. If the human wants
the findings applied, that is ordinary work and it goes through planning like any
other.
