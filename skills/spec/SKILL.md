---
name: spec
description: Write the spec that holds a body of work too large for one plan — shared decisions, vocabulary, and the list of plans it breaks into. Invoke when a single plan cannot cover the work.
disable-model-invocation: true
---

# Writing a spec

A spec is the document that holds a system whole **when it has to be broken into
several plans**. It carries what those plans share: the decisions they all
follow, the vocabulary they all use, and the list of plans with the dependencies
between them.

**Announce at start:** "Using dev-skills:spec to write the spec for this work."

## When there is no spec

One plan means no spec. The plan's header already carries the outcome, the
constraints, the out-of-scope list and what the final gate proves.

The trigger is not size. It is **whether the work produces more than one plan**.

The human decides. You may say what you see: "this is large enough that either
half of it leaves the scope, or we fix it with a spec and split it." Then wait.

## What goes in

Write it to `.ai-workflow/specs/YYYY-MM-DD-<topic>.md`. See *Storage* below.

**Goal.** What the system should be able to do, in one paragraph.

**Result from the user's side.** What the person using it does, and sees, in
their own terms. Not components — behaviour.

**Constraints.** What is fixed for every plan below: transports, dependency
limits, version floors, mechanisms that must be reused rather than replaced.

**Out of scope.** What this body of work does not include. Name the things a
reader would reasonably assume were included.

**Decisions taken.** The heart of the document: decisions common to all the
plans, each with the reason that settled it. Every plan is bound by them and
**no plan reopens them**. This is the section that makes the spec worth writing
— it is what stops plan 3 from quietly contradicting plan 1, which nobody would
notice until integration.

**Glossary.** The terms already carried into `CONTEXT.md` that every plan must
use identically. Names only; the definitions live in `CONTEXT.md`.

**Plans.** A list, not a backlog — see below.

**ADR candidate**, if one arose. A proposal, never an action: name the decision
and the trade-off, and say it is worth recording. Writing it is the human's
call, and it happens through `dev-skills:domain-modeling`.

**What is not in this spec.** An explicit section: no file paths, no signatures,
no code, no phases, no checkboxes, no implementation order, no estimates, no
instructions to an implementer. All of that belongs to a plan. The spec outlives
changes to the code; a plan is stale after the merge it describes. That is why
they are separate documents, and this section is how the separation stays real.

## The list of plans

```markdown
| # | Plan | State | Depends on |
|---|---|---|---|
| 1 | Transport and tool registration | ready to plan | — |
| 2 | First tool over the service layer | — | 1 |
| 3 | Call log and access revocation | — | 1 |
| 4 | Settings UI | — | 1, 3 |
```

An entry is **a line in this spec, not an artifact**. It becomes a plan only
when the human names it and invokes `dev-skills:plan`. Nothing is created ahead of time,
nothing has to be maintained, and the whole list dies with the spec.

This is what separates it from a ticket layer: tickets were files with their own
contract, created in advance, and they outlived their usefulness by default.

**Two actors move the State column, and only two:** `dev-skills:plan` sets *in progress*
when it creates the plan, `dev-skills:finish` sets *done* after integration is proven.
Everything else in the spec is edited by the human.

The split is not doctrine. If planning reveals that 2 and 3 fit in one cycle,
they merge — the list is corrected, not defended.

## Sizing an entry

Each entry must be coverable by **one plan** and end in a state someone can
check. "Add MCP to the app" is a spec; "tooling", "backend", "UI" are entries.

The split is not fixed in advance. A small tool may let backend and UI share one
plan; a full backend service is planned and verified on its own, and only then
is the UI planned.

Do not introduce a level between spec and plan.

## Storage

`.ai-workflow/` inside the repository. Outside it, these become system litter you
forget about; inside, they die with the repository.

Before the first write, make sure the repository ignores the directory:

```bash
grep -qxF '.ai-workflow' .gitignore || printf '.ai-workflow\n' >> .gitignore
```

**Without a trailing slash.** A pattern with one matches directories only, and
in a worktree `.ai-workflow` is a symlink, which git sees as a file. Do not
analyse what other variants are already there — if the exact line is absent, add
it.

## After the spec

Present it and take approval. Then stop.

The next step is the human's to call: they name an entry from the list, and
`dev-skills:plan` starts from it. Do not begin planning entry 1 because it is obviously
first.
