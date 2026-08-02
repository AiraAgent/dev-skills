---
name: tests
description: Work where the tests are the deliverable — covering untested code, or repairing tests that lie. The contract is red before, green after, proved by commits. Invoke when no production behaviour is meant to change.
disable-model-invocation: true
---

# Tests as the goal

Its own entry because its verification contract is the narrowest in the pipeline:
**something has to be red first, and green afterwards, and both have to be
visible in the history.**

No production behaviour changes here. If it does, this was the wrong entry.

**Announce at start:** "Using dev-skills:tests. Nothing in production behaviour changes."

## Two shapes, and red means something different in each

Say which one this is before planning anything. They look alike and they are not.

### Covering code that has none

The code works. You are writing tests for behaviour that already exists, so a new
test **passes the moment you write it** — and a test that has never failed proves
nothing at all.

**Red comes from mutation.** For each test, before you keep it:

1. break the production code deliberately in the specific way this test claims to
   catch — wrong constant, inverted branch, dropped side effect, empty return;
2. run it and **watch it fail**;
3. restore the code and watch it pass.

A test that survives its own mutation is not a test, and it goes in the bin
rather than in the suite. That loop is the red-green cycle for coverage work, and
it is not optional — it is the only thing separating this from generating
assertions that describe whatever the code happens to do.

Do not "improve" the code while covering it. Something ugly that you find is an
observation for the report; something *wrong* that you find is a bug, and a bug
goes through `dev-skills:bug` on its own route. Pin the current behaviour and leave it.

### Repairing tests that lie

The tests exist and they are the problem: flaky, or green on code that is broken,
or asserting on mocks, or coupled to structure so they fail on every intentional
change.

**Red is the lie, reproduced.** Before any repair:

- **flaky** — reproduce the flake. Run it in a loop, under load, in a different
  order, with the seed or the clock that triggers it. A flake you cannot
  reproduce cannot be proved fixed, and "it passed twenty times" is not evidence.
  Find the actual cause: shared state, real time, ordering, an unawaited promise.
  Adding a retry or a sleep is not a repair, it is a louder silence;
- **green on broken code** — mutate as above and show it passing when it should
  not. That failure to fail is the red;
- **fails on every intentional change** — show the intentional change it fires
  on. A test that only fails on decisions is a change detector; the repair is to
  assert on the behaviour that depends on the decision instead.

## What lands in the plan

`dev-skills:plan`, with these carried explicitly:

- **which shape this is**, because the phases differ;
- **the exact scope** — which module, which test files. Test work spreads further
  than any other kind, and "while I was in there" is how a coverage task becomes
  a week;
- **the seams**: existing ones, at the highest level that still pins the
  behaviour. The ideal number of new seams is zero. A test that needs production
  code restructured before it can be written is telling you the design is wrong —
  that is a `dev-skills:refactor`, not a phase here;
- *What the final gate proves*: **red before, green after**, with the commits that
  show it;
- the **mutations** each phase will use, named up front. They are the cases, and
  cases are decisions.

## The evidence, in commits

The reviewer runs the checks on the final state, where everything is green, and
nobody is asked to take a report on trust. So red has to exist somewhere it can
be run:

- the failing or mutation-proved test lands **on its own commit**, before the
  repair;
- for a flake, the reproduction — the loop, the seed, the ordering — is written
  down where the reviewer can run it too.

Without that, "it was red before" is an unverifiable claim, and the whole contract
of this entry is that claim.

## Where this ends

Present the shape, the scope and the seams, then stop. The human invokes
`dev-skills:plan`.
