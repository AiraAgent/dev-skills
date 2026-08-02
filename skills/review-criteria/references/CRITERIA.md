# Review criteria

The standard every code review in this workflow judges against. Three seats read
this file, and nothing else defines what a finding is:

| Seat | Where its scope comes from |
|---|---|
| `dev-skills:implement-review` | the plan — the **fields** of the phases in one segment |
| `dev-skills:final-review` | the plan's final-gate scenarios, driven on a running system |
| `dev-skills:review` | whatever the human pointed at — a PR, a file, a tree |

One file, so sharpening the standard sharpens all three at once and none of them
can drift from the others.

## The producible-source rule

**A blocking finding cites its source.** One of four:

- a convention this repository documents;
- a pattern that **already exists** in the code, named with its path;
- a requirement of the phase under review;
- a constraint from the plan's header.

Cannot show the source? It is not a finding, and it is not written down.

> "I don't like this name" does not pass.
> "Handlers of this kind live in `hooks/` in this project, this one is inside the
> component" passes.

The rule exists because correctness is settled before any code is read — the
reviewer runs the checks first — so what remains is the territory of taste, and
the search for smells has no natural floor. Without a source requirement,
"green means no remarks" buys a fix round at every checkpoint, and buys it
invisibly: the human is *on* the loop, not in it, and never sees the round that
was not worth running.

## Two classes, and only two

**Finding** — blocking. Cited, and it goes back to the implementer.

**Observation** — recorded, never blocking, never extends a loop. Anything true
but outside this review's scope lands here.

There is no third severity.

## Judge the fields, not the steps

The plan binds the implementer with an ordered list of steps. It does **not**
bind the reviewer with one.

Compare the diff against the phase's fields — *becomes true*, *changes*, *how*,
*do not touch*, *frozen for later phases*, *verification*. "Did it in a different
order" is not a finding. So is "did it in fewer steps", and "combined two steps".
Review by the step list and the review degenerates into letter-matching, which
buys a fix round for nothing.

## Paths are checked first, mechanically

Before any code is read: `git diff --name-only` against the union of the
*changes* fields of the phases under review. A file outside that union is a
finding immediately.

This runs first because going out of bounds is improvisation in observable form,
and catching it needs no judgement at all — two lists, compared. It is the only
defence against a weak model that rests on nothing but git.

Then the checks — tests, lint, typecheck, build. Red goes straight back to the
implementer; the code is not read. Debugging stack traces and build noise is not
the reviewer's work, and hunting smells in a segment whose tests fail is wasted.

## Tests are part of the diff

The plan names the cases; the implementer writes the test code. Because a weak
model writes it, the tests are reviewed like any other code, and two findings
are always available:

- **the test does not cover a case the phase declared** — cite the case;
- **the test masks the defect** — it passes on an implementation that is wrong,
  asserts on a mock rather than on behaviour, or computes its expectation with
  the code under test.

A test that could only fail through a crash, a missing selector, or the removal
of the mock itself is not a test. So is one that fires on every intentional
change and sleeps through accidental ones.

## The smell baseline

Fowler's smells (*Refactoring*, ch. 3). They apply even where a repository
documents nothing — which is what makes this a baseline rather than a standard.

Two rules bind every use. **The repository overrides:** a documented standard
always wins, and where it endorses what the baseline would flag, the smell is
suppressed. **Every entry is a judgement call** — "possible Feature Envy", never
a violation. Skip anything tooling already enforces.

Visible inside one segment's diff — `dev-skills:implement-review` owns these:

- **Mysterious Name** — a name that does not reveal what it does or holds. → rename; if no honest name comes, the design is murky.
- **Primitive Obsession** — a primitive standing in for a domain concept. → give the concept its own small type.
- **Data Clumps** — the same few fields keep travelling together. → bundle them into one type.
- **Feature Envy** — a method reaching into another object's data more than its own. → move it onto the data it envies.
- **Repeated Switches** — the same cascade on the same type recurs. → polymorphism, or one shared map.
- **Message Chains** — a long `a.b().c().d()` the caller should not depend on. → hide the walk.
- **Middle Man** — a unit that mostly delegates onward. → cut it.
- **Refused Bequest** — a subclass ignoring most of what it inherits. → composition.
- **Speculative Generality** — abstraction for a need the plan does not have. → delete it.

Visible only once segments are assembled — `dev-skills:final-review` and `dev-skills:review` own
these; a reviewer holding one segment's diff structurally cannot see them:

- **Duplicated Code** — the same logic shape in more than one place. Two segments built by two cold implementers, neither having seen the other, is the case that produces it.
- **Shotgun Surgery** — one logical change forcing scattered edits.
- **Divergent Change** — one module edited for several unrelated reasons.

## Repository conventions

Read what the repository says about how its code is written — `CLAUDE.md`,
`CONTRIBUTING.md`, `CODING_STANDARDS.md`, `CONTEXT.md` for vocabulary — and
judge the part decidable from the diff in hand: naming, import style, error
handling, the pattern already used in that area.

Documented conventions are hard: they cite themselves. Everything else needs an
existing pattern in the code to point at.

## What is never a finding

- **A different order, or fewer steps.** The steps bind the implementer only.
- **Anything the plan mandates.** A plan requirement that looks like a defect is
  a `PLAN_CONFLICT`, not a finding: it stops and goes to the orchestrator, who
  takes it to the human. Do not quietly overrule the plan, and do not quietly
  swallow the defect because the plan asked for it.
- **A decision an earlier segment already closed.** Accepted work is not
  reopened; the reviewer confirms the related phases were checked and moves on.
- **Anything tooling enforces.** Formatting a linter fixes is not review.
- **Style the repository has never stated and never demonstrated.** That is the
  producible-source rule, and it is the most common way this review goes wrong.

## What a stated rationale is worth

Nothing. "Left it deliberately", "kept it simple per YAGNI" — that is the author
grading their own work. Judge the code. The rationale belongs in the
conversation about the finding, not in the decision whether to raise it.

## The frozen contract

A checkpoint reviewer **never changes the segment's declared output contract**
through an ordinary finding. That contract is the union of the *frozen for later
phases* fields of the segment's phases: the names, signatures and data shapes
that later phases were told to build on.

Needing one of them changed is a `PLAN_CONFLICT` — it stops and escalates. It is
not a finding, because a later phase has already been briefed against it, and a
review that quietly renames it leaves the next implementer looking for an
abstraction that no longer exists.

Only what is explicitly named in those fields is frozen. Everything else the
segment produced is ordinary territory — otherwise this rule would stop being a
guard on asynchrony and start being a ban on findings.
