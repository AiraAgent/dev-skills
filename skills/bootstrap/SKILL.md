---
name: bootstrap
description: Injected at session start. States one rule — do not start building a task silently — and names the entries that exist.
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to do a specific job, ignore this. Your
brief is your instructions.
</SUBAGENT-STOP>

# Before you start building

There is a workflow in this environment for turning a task into reviewed,
integrated code. It is invoked **by the human, never by you.**

## The one rule

```text
a pinpoint edit in a place the human named   → just do it
anything that looks like a task              → stop and offer the route
```

Do not begin implementing a task off a bare prompt. Say what you would reach for,
and let them call it:

> "This looks like a task rather than a one-line edit. `dev-skills:grill` to work out
> what we're building, then `dev-skills:plan` — say the word."

That is the whole rule. You are not routing anything and you are not invoking
anything.

The boundary between "pinpoint edit" and "task" is your judgement, and it will
sometimes be wrong. It is a cheap kind of wrong: it shows up as one unnecessary
question, not as a context filled with work nobody asked for.

## What exists

Entries — the human types one:

| | |
|---|---|
| `dev-skills:grill` | the task is not clear yet; interview it into a shared understanding |
| `dev-skills:grill-with-docs` | same, and it also captures vocabulary and earned ADRs |
| `dev-skills:bug` | a bug: reproduce, find the cause, pin it with a failing test |
| `dev-skills:scout` | explain how existing code works; read-only |
| `dev-skills:refactor` | restructure, migrate, upgrade — behaviour must not change |
| `dev-skills:tests` | the tests are the deliverable: cover code, or repair tests that lie |

Then the pipeline: `dev-skills:spec` (only when the work needs more than one plan) →
`dev-skills:plan` → `dev-skills:implement` → `dev-skills:finish`.

Outside a run: `dev-skills:review`, `dev-skills:improve`, `dev-skills:research`, `dev-skills:prototype`,
`dev-skills:domain-modeling`.

`dev-skills:bug` is the one entry you may reach for yourself — a bug arrives as a
symptom, and the mistake it prevents happens in the first reply.

The human's instructions — `CLAUDE.md`, and whatever they just said — outrank all
of this.
