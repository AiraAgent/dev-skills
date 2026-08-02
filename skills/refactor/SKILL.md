---
name: refactor
description: Restructure code, or migrate and upgrade, under one contract — the observable behaviour does not change. Invoke when the change of shape is the goal, not a side effect of building something.
disable-model-invocation: true
---

# Refactoring, migration, upgrade

One entry, because these share a verification contract that nothing else in the
pipeline has: **the observable behaviour is the same afterwards.** Not "better",
not "still fine" — the same.

**Announce at start:** "Using dev-skills:refactor. The contract here is that behaviour
does not change."

If what you actually want is a different behaviour, this is the wrong entry. Go
through `dev-skills:grill`.

## What belongs here, and what does not

**Here:** restructuring as the goal. A dependency or runtime upgrade. A migration
from one library, API or pattern to another. Splitting a file that has grown into
several responsibilities. Moving a layer behind a seam.

**Not here:** small refactoring that comes along with other work. That stays
inside the plan of the task it belongs to — a phase, not an entry. A separate
route for it would cost more process than the change.

**Not here either:** anything where the answer to "does the behaviour change?" is
"a little". A little is a behaviour change, and it needs the ordinary route.

## Invariance is proved, not asserted

This is the whole skill. Everything else is planning.

**The existing tests are the instrument.** They must pass, unchanged, before and
after. A refactor that requires editing its own tests has either changed
behaviour or the tests were coupled to the structure rather than the behaviour —
and you have to know which before going further.

- Tests had to change because they asserted on internals → say so, and say what
  the new assertion is against. That is a finding about the tests, not licence.
- Tests had to change because the behaviour changed → stop. Wrong entry.

**Where coverage is missing, write characterisation tests first.** Pin the current
behaviour — including the parts you think are wrong — before touching anything.
They are the only evidence you will have, and they must be written and committed
*before* the restructuring, on their own commit.

A characterisation test asserts what the code does today, not what it should do.
If you find yourself wanting to fix something while writing one, write it down as
an observation and leave the behaviour alone.

**For a migration or upgrade,** the invariance instrument is the same, plus the
release notes: read what the new version actually changed, and name every
behaviour difference it introduces before starting. An upgrade whose breaking
changes you have not read is not a migration, it is an experiment.

## The route

1. **Map it** if the territory is unfamiliar — `dev-skills:scout`. You cannot promise
   invariance over code you have not read.
2. **Grill only if there is a decision.** Which target pattern, which library,
   which of two structures — that is a decision and it goes through `dev-skills:grill`.
   Where the target is obvious, skip it.
3. **Plan it** — `dev-skills:plan`, with three things the ordinary plan does not carry:
   - *What the final gate proves* is **invariance**: name the behaviours that must
     still hold and how they are observed;
   - the **public surface that must not change**, by name — every signature,
     export and route the outside world depends on;
   - the **characterisation tests** as their own early phase, with their own
     commit, where coverage is missing.
4. **Build it** — `dev-skills:implement`, like anything else.

## What makes a good phase here

Refactoring splits badly along "files touched" and well along **one structural
move at a time**: extract this, then move that, then delete the old path. Each
move keeps the tests green on its own, which is what makes a checkpoint mean
something.

A phase whose *Becomes true* is "the code is cleaner" is not a phase. "The
callers of `X` now go through `Y`, and `X` is gone" is.

Deleting the old path is a phase, not an afterthought. A migration that leaves
both paths alive has not migrated anything — it has doubled the surface, and the
next reader has no way to know which one is real.

## The trap

The gap between "this is equivalent" and "this is equivalent as far as the tests
go" is where refactors break things. When you notice that gap — an untested
branch, an implicit ordering, a side effect nobody asserted — that is a
characterisation test, written now, not a note for later.
