---
name: tdd
description: "Use when writing tests — the red-green-refactor cycle and the discipline around it: one test at a time, verify red before green, the simplest code that passes. Read by the implementer when a segment has tests."
user-invocable: false
---

# Test discipline

Handed to the implementer when the plan says the segment has tests. **Whether
there are tests is the plan's decision, not yours** — the plan names the seam,
the file, and the cases. This file is how you write them once it has.

## The cases are given; the code is yours

The phase's *verification* field names the level, the file, and each case with
the assertion it expects. That is a decision, and it was made before you were
dispatched.

Everything around it is mechanics and is yours: `describe` blocks, fixtures,
mocks, render helpers, setup. Write them the way the neighbouring tests in this
repository write them.

Do not add cases the phase did not name, and do not drop one because it looks
covered by another. A case you think is wrong is a `PLAN_CONFLICT` — stop and
report it.

## The iron law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Wrote the code first? Delete it and start over from the test. Not "keep it as
reference", not "adapt it while writing the test", not "look at it once more".
Delete means delete — code you adapt into a test is a test written afterwards,
and it passes the moment you write it, which proves nothing.

## Red — green — refactor

**RED.** One test, one behaviour, a name that says what should happen.

**Verify red. Mandatory, never skipped.** Run it and confirm three things: it
fails rather than errors, the message is the one you expected, and it fails
because the behaviour is missing — not because of a typo or a bad import.

- It passes → you are testing behaviour that already exists. The test is wrong.
- It errors → fix the error and re-run until it fails properly.

If you did not watch it fail, you do not know it tests the right thing. This is
the whole of TDD; the rest is bookkeeping.

**GREEN.** The simplest code that passes. No options nobody asked for, no
generality the phase does not need, no improving the code next door.

**Verify green.** The test passes, its neighbours still pass, and the output is
clean — no warnings, no stray errors.

**REFACTOR.** Only once green. Remove duplication, improve names, extract
helpers, stay green, add no behaviour.

## Proving red when red is the contract

For a bug fix and for tests-as-the-goal, the failing test is the deliverable, and
nobody sees it fail unless it exists on its own commit.

**Commit the test before the implementation.** The reviewer checks out that
commit, runs it, and watches it fail — no report to trust, no judgement to make.
For every other kind of task this is not required.

## Two rules that keep a test honest

**Name the break it catches.** Before writing the body, answer: what production
change would make this fail, and is that change a bug or a decision? A test that
can only fail on a deliberate decision — a constant's value, exact wording,
private structure — fires on every redesign and sleeps through every bug.

**Derive the expectation by hand.** A value computed by the code under test, or
by its helpers, passes no matter what that code does:

```typescript
// mirror assertion — the same builder computes both sides, always true
const expected = buildSearchQuery({ tag: 'urgent' });
expect(buildSearchQuery({ tag: 'urgent' })).toBe(expected);

// hand-derived literal
expect(buildSearchQuery({ tag: 'urgent' })).toBe('tag:"urgent"');
```

## Mocks

**Assert on the real thing, never on the mock.** An assertion that passes because
the mock is present and fails because it is absent says nothing about your code.
If the mock is what you are checking, unmock it or delete the assertion.

**Mock at the right level.** Learn the real method's side effects before
replacing it. Mock the slow or external operation and keep everything the test
depends on real — a mock that swallows a write some later assertion reads makes
the test pass while the integration breaks.

**Mirror the real structure completely.** Mock every documented field, not only
the ones this test reads. Partial mocks fail silently.

**Production classes carry production methods only.** Cleanup only tests need
lives in test utilities, never as a `destroy()` on the production class.

**When mock setup outgrows the test, stop mocking.** Use the real components.

## The mutation check

Before you call it done, mentally mutate the production code. At least one test
should fail for each of these:

- a wrong constant or argument;
- the wrong branch taken;
- a missing state change or side effect;
- an empty or default return;
- missing validation for zero, empty, null, unauthorised, or malformed input.

A mutation nothing catches means either the behaviour is unprotected or the test
is tautological. Both are yours to fix before reporting.

## Warning signs

- Setup and assertion share the same object, guaranteeing equality.
- The test can only fail through a crash or a missing selector.
- It fails on every intentional change and never on an accidental one.
- The expected value hides behind a loop, a builder, or a helper.
- It greps source text instead of running the thing and checking what happened.
- It exists for coverage and checks no outcome or side effect.
- An assertion names a `*-mock` test id.
- Mock setup is more than half the test, or you cannot say why the mock is there.
