---
name: bug
description: Reproduce a bug, find its root cause, and leave behind a failing test that pins it. Use for any bug, test failure, or unexpected behaviour, before proposing a fix.
---

# Diagnosing a bug

A bug is its own entry to the pipeline because its verification contract is
different from everything else: **the same case, which reproduced before, must
stop reproducing** — and a regression test has to prove it.

```text
reproduce → root cause → a failing test that pins it → stop
                                                       → the human calls dev-skills:plan
```

**Announce at start:** "Using dev-skills:bug to diagnose this before proposing anything."

This is the one entry the model may reach for on its own. A bug arrives as a
symptom, and the failure mode being guarded against — guessing at a fix — happens
in the first reply, before anyone would have thought to type a skill name.

## The iron law

```
NO FIX WITHOUT A ROOT CAUSE FIRST
```

A symptom fix is a failure, not a partial success. Until phase 1 is done you do
not propose a fix — not as a suggestion, not as "it's probably".

This holds hardest exactly where it feels most expendable: under time pressure,
when the fix looks obvious, when previous attempts failed, and when the issue
looks too simple to deserve a process. Simple bugs have root causes too, and
systematic work is *faster* than guess-and-check.

## Phase 1: root cause

1. **Read the error properly.** All of it, including the stack trace. Note line
   numbers, paths, codes. It often contains the answer.
2. **Reproduce it consistently.** What exact steps trigger it? Every time? If you
   cannot reproduce it, gather more data — do not guess. A reproduction you
   cannot repeat cannot prove a fix either.
3. **Check what changed.** Recent commits, new dependencies, configuration,
   environment differences.
4. **Instrument the boundaries, in a multi-component system.** Before proposing
   anything, log what enters and what leaves each component, and check that
   configuration and environment actually propagate. One run gives you evidence
   of *where* it breaks; then investigate that component and no other.
5. **Trace the data backwards.** Where does the bad value originate? What passed
   it in? Keep going up until you reach the source. Fix at the source, not where
   it surfaced. The full technique is in
   [root-cause-tracing.md](references/root-cause-tracing.md).

## Phase 2: pattern

1. **Find something similar that works** in this codebase.
2. **Read the reference implementation completely** if you are following a
   pattern. Every line, not a skim.
3. **List every difference** between the working and the broken thing, however
   small. "That cannot matter" is where the cause hides.
4. **Understand what it depends on** — components, configuration, environment,
   assumptions.

## Phase 3: hypothesis

1. **State one hypothesis**, specifically: "X is the root cause, because Y."
2. **Test it minimally** — the smallest possible change, one variable.
3. **Verify before continuing.** Worked → phase 4. Did not → form a *new*
   hypothesis. Never stack a second fix on top of a first that did not work.
4. **Say when you do not know.** "I do not understand X" is a usable answer;
   pretending is not.

**After three failed hypotheses, stop and question the architecture.** The
pattern to recognise: each fix uncovers new shared state or coupling somewhere
else, each fix would need "massive refactoring", each fix creates a new symptom.
That is not a failed hypothesis, it is the wrong shape — and it is a conversation
with your human partner, not a fourth attempt.

## Phase 4: the failing test

The diagnosis is not finished until the bug is pinned by a test.

- the **simplest possible reproduction**, automated if the project has a test
  framework, a one-off script if it does not;
- it must **fail now**, for the reason you diagnosed — watch it fail and read the
  message;
- it lands as **its own commit, before any fix**. That is what lets a reviewer
  run it on that commit and watch it fail with their own eyes, rather than
  believing a report.

Then **stop**.

## Where this ends

Report: the reproduction, the root cause with its evidence, and the failing test.
Then say what the next step is — the human invokes `dev-skills:plan`, and the fix is
planned and built like any other work.

The size of the bug changes the shape of that plan, not the route. A one-line
cause gets a one-phase plan; a cause that runs through three layers gets several.
There is no separate branch for a big bug, because the diagnosis is identical.

**You do not fix it here.** The temptation is strongest right now, with the cause
fresh and the change looking trivial — which is exactly why the boundary is
here, where it can be seen, rather than somewhere further along where it cannot.

## Red flags — stop and go back to phase 1

- "Quick fix now, investigate later"
- "Just try changing X and see"
- Several changes at once, then run the tests
- "Skip the test, I'll check by hand"
- "It's probably X"
- "I don't fully understand this, but this might work"
- "The pattern says X, but I'll adapt it"
- Listing fixes before tracing the data
- **"One more attempt", after two have failed**
- **Each fix reveals a new problem somewhere else**

Signals from your human partner that mean the same thing: "is that not
happening?" (you assumed instead of verifying), "will it show us…?" (you should
have gathered evidence), "stop guessing", "we're stuck?".

## When there really is no root cause

If systematic investigation genuinely lands on environmental, timing-dependent or
external behaviour: you have completed the process. Write down what you
investigated, implement the appropriate handling — retry, timeout, a real error
message — and add whatever makes the next occurrence legible.

But 95% of "no root cause" is incomplete investigation.

## Supporting techniques

- [root-cause-tracing.md](references/root-cause-tracing.md) — trace a bug backwards through
  the call stack to its original trigger.
- [defense-in-depth.md](references/defense-in-depth.md) — where to add validation once the
  root cause is known.
- [condition-based-waiting.md](references/condition-based-waiting.md) — replace arbitrary
  timeouts with condition polling.
