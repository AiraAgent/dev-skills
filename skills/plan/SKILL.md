---
name: plan
description: Write the implementation plan — the contract a cold, cheap implementer builds from. Invoke before any execution, or as the entry point when a spec already exists and the human names an entry from its list.
disable-model-invocation: true
---

# Writing a plan

The plan is the artifact the whole workflow rests on. It is what lets a weak
model build well, and what lets the human step off step-by-step supervision
during execution. Everything downstream is only as good as this file.

**Announce at start:** "Using dev-skills:plan to write the implementation plan."

**A plan is always created, and always as a file.** There is no inline mode. It
is a ledger as well as a contract — its checkboxes have to live somewhere.
Length is set by the task; a short task gives a short file.

Write it to `.ai-workflow/plans/YYYY-MM-DD-<name>.md`, and make sure the
repository ignores that directory:

```bash
grep -qxF '.ai-workflow' .gitignore || printf '.ai-workflow\n' >> .gitignore
```

**Without a trailing slash** — a pattern with one matches directories only, and
in a worktree `.ai-workflow` is a symlink, which git sees as a file. If the exact
line is absent, add it; do not analyse the variants already there.

## Plan in the current tree

Planning happens where you are. The branch or worktree is created at the start of
execution, by `dev-skills:implement`, not here.

## Entry with an existing spec

A spec that produced more than one plan makes this skill a starting point of its
own: the human names an entry from its list and planning begins there. The
grilling is not repeated — the alignment is already recorded in the spec's
*Decisions taken*.

On that entry:

- read the spec whole: decisions, glossary, the plan list with its dependencies;
- check that the entries this one depends on are closed. If they are not, say so
  and do not plan on top of a result that does not exist;
- plan **only the entry named**. Neighbouring entries do not get pulled in, however
  small they look;
- **do not reopen the spec's decisions.** If a decision surfaces at plan level
  that the spec does not contain, stop and propose grilling. Do not settle it
  here.

That last one is the whole boundary between the two levels: the spec holds
decisions, the plan holds mechanics. A planner that settles something on the
spec's behalf diverges from every other plan in the list, because none of them
saw it.

Set the entry's state to *in progress* in the spec when the plan is created.
That, and `dev-skills:finish` marking it *done*, are the only writes to a spec after it
exists.

## The completeness contract

Every plan carries all of these. A section with nothing in it says so with a
dash — the dash is an assertion by the planner, not tidiness.

| Section | Why | Read by |
|---|---|---|
| **Goal** | what we are doing, in your own words | everyone; `dev-skills:finish` derives the commit message from it |
| **Spec**, or "single-cycle" | where the shared context is, if there is any | everyone |
| **Constraints** and **Out of scope** | where not to go | implementer |
| **What the final gate proves** | the verification contract for this kind of task | final reviewer |
| **Test seams** | where we check. Existing beats new, highest level that works, the ideal number of new seams is zero | implementer, reviewer |
| **Paths and existing abstractions** | so nobody researches the codebase again | implementer, reviewer |
| **Topology** | segments, checkpoints, relations, the model per segment | orchestrator |
| **Phases** | bounded units of execution, seven fields each | implementer, reviewer |
| **Final-gate scenarios** | what is actually clicked through on the live system | final gate, human at GATE 1 |
| **Ledger** | the run's record and its resume point after a compaction | orchestrator |

There is **no `Commit` section**. The Goal is enough: the actor assembling the
commit reads the goal and the result.

Seams live here rather than in the spec, because a spec does not always exist and
every plan needs them. Put them to the human as their own question.

## Anatomy of a phase

Write a phase as if the implementer is a very good engineer **who knows nothing
about this project**. They must not have to find a file, settle an approach, or
check your work. Everything they need is in the phase or in the plan's header.

"Do A, do B" is therefore not a phase. Only the header and the phases reach the
brief; anything absent from them the implementer either invents or goes looking
for — which is exactly what the plan exists to prevent.

### Decisions are fixed; mechanics are not

**Fixed exhaustively:** every path touched, including test paths; the
abstractions used, by name and with their path; which names and signatures are
public and must not change; the verification cases and the assertions they
expect; edge cases and the behaviour on them; what counts as an error and how it
shows; what not to touch and what not to introduce; order, where order carries
meaning.

**Never appears:** function bodies, test code, imports, style. That is typing,
not deciding. The planner saves nothing by omitting it, because the planner
should not be writing it at all.

**Sufficiency test:** two competent engineers reading this phase should write
functionally identical code. If they would differ in something that would have to
be redone, a decision is missing — add it. If they differ only in form, the
reviewer closes that against the repository's conventions.

Do not economise on density. A thin plan is paid for twice: once in a bad
decision, and again in the rework.

### The seven fields

The subheadings are **fixed strings**. This is not formatting: the orchestrator
cuts a phase into a brief mechanically, and mechanical assembly needs stable
anchors.

| Field | What it carries |
|---|---|
| **Becomes true** | the observable result of the phase; it also sets the phase's size |
| **Changes** | paths *and* entities: a symbol, a function, a region — not only a file |
| **How** | named abstractions with paths, plus the negative side: what not to introduce |
| **Do not touch** | only conflicts *inside* paths already granted |
| **Frozen for later phases** | names, signatures and data shapes that later phases build on |
| **Verification** | seam, file, cases with their expected assertions |
| **Steps** | the order of work, with checkboxes |

**All seven are mandatory; absence is written as a dash.** `Do not touch: —` means
"there is no neighbouring conflict", not "I forgot to think about it". There is no
other way to tell forgetfulness from a considered nothing, and in *Frozen for
later phases* that slip costs the next segment a stop. The presence of all seven
subheadings is checked by grep, with no model judgement involved.

In a typical phase three of the seven are dashes. That is cheaper than one
invisible omission.

### The form

````markdown
### Phase 3. Pressing the button switches the theme

**Becomes true**
- clicking the button toggles the theme between `light` and `dark`
- the chosen value survives a page reload

**Changes**
- `src/features/theme/ThemeToggle.tsx` — the `onClick` handler

**How**
- use the existing `useTheme` (`src/shared/theme/useTheme.ts`); it already holds
  `setTheme` and persists to `localStorage`
- do not introduce a new store or context

**Do not touch**
- the button's markup in `ThemeToggle.tsx` — it belongs to phase 2

**Frozen for later phases**
- —

**Verification**
- level: `useTheme`, file `src/shared/theme/useTheme.test.ts`
- `toggle()` with `theme='light'` → `theme` becomes `'dark'`
- `toggle()` twice → `theme` is back to `'light'`
- after remount → `theme` is read from `localStorage`
- `disabled=true`, click → `setTheme` is not called

**Steps**
- [ ] wire `useTheme` into `ThemeToggle`
- [ ] hang the toggle on `onClick`
- [ ] write the test over the four cases above
````

### Sizing a phase

The unit of review is a **segment**, and every phase in a segment is built by the
same agent. Splitting phases therefore adds no cold start; only the planner pays,
in fields written. The floor is meaning, not the cost of starting an agent.

The criterion comes from a field that is mandatory anyway:

- **from below** — a phase must have its own observable result, stated as a claim
  about behaviour or about an artifact something else relies on;
- **from above** — if *Becomes true* has to be assembled with "and" out of
  unrelated claims, that is two phases.

```text
"clicking switches the theme"           → behaviour            → a phase
"the icon file exists and is imported"  → artifact for phase 2 → a phase
"imports tidied up"                     → process              → fold into a neighbour
```

If the only verification you can invent is "it compiled", the phase has no result
of its own and does not deserve to be separate.

### Why *Do not touch* is narrow

The mechanical path check already catches everything outside *Changes*, with no
judgement at all. Repeating it under *Do not touch* duplicates a check that runs
first anyway and makes the field unreadable for a weak model.

Exactly one case is left uncovered: **someone else's region inside a permitted
file.** Phases 3 and 4 both edit `ThemeToggle.tsx` — the path is legal for both,
and the neighbour's handler is off limits. That is the content of the field, and
why it is two or three lines rather than a screen.

Global limits — versions, no new dependencies, the task's out-of-scope — live in
the header only and are not repeated per phase. "Do not introduce a new entity"
does not get its own line either: it is the negative side of a named abstraction
and is written in *How*, in the same sentence as the abstraction.

### Steps bind the implementer, not the reviewer

The implementer's brief is an **imperative**. Not "recommended", not "roughly this
order": a weak model improvises the moment it sees the word "can", and it is not
offered the choice.

The reviewer compares the diff against the **fields**, never the step list. "Did
it in a different order" is not a finding — review by the letter buys a fix round
for nothing, invisibly, because the human is on the loop rather than in it.

The asymmetry works because these are different actors reading different briefs.

The cost of a divergence differs the same way:

```text
divergence touches a field of the phase
→ stop, PLAN_CONFLICT, then the common divergence protocol

divergence touches only a step
→ the implementer adapts and continues
→ the deviation goes into the segment report
→ the orchestrator writes confirmed deviations into the plan at the checkpoint
```

Unsure whether a field is touched? Treat it as touched and stop. An error in that
direction costs one visible, cheap stop instead of a silent divergence.

## Topology

Number phases straight through. A checkpoint sits between them; a unit of
dispatch is described as "phases 1–3". **Do not introduce a term for a group of
phases** — in conversation about mechanics, "segment"; in the artifact, no new
entity appears.

**Verification is not needed after every phase.** Three phases — "add the icon
file", "put the icon in the header", "clicking switches the theme" — where the
first two are checked by grep and deserve neither a review nor a test. The one
meaningful check goes after the third and closes all three.

You **propose** where the checkpoints go; the human approves and corrects. This is
one of the points where a human in the loop is mandatory.

Three relations, marked by you and approved by the human:

| Relation | Meaning |
|---|---|
| **Sequential** | the next segment starts only after a green verdict on this one |
| **Asynchronous** | the next segment starts right after the intermediate commit, without waiting for the verdict |
| **Parallel** | two phases run at the same time; not necessarily adjacent — 1 and 4, 5 and 7 |

**Asynchronous is not the default.** Mark a specific checkpoint as asynchronous
when its possible findings cannot affect the next segment, and let the human
approve the mark with the plan. An asynchronous mark requires that the paths of
the two segments **do not intersect**; inside one segment intersection is fine,
because it all lands in one commit.

**Parallelism is not the goal of splitting.** Make it the goal and phases get cut
to avoid touching shared files, which turns one meaningful checkable phase into
thirty file-disjoint fragments. Two phases may edit the same file and still be
entirely independent — parallelise by purpose, not by file. Highlight parallelism
where it is obvious, and feel free to move a checkpoint so independent phases land
in one segment; do not cut for it. Where paths genuinely intersect, phases run
sequentially.

Assign the **model per segment** — Haiku or Sonnet by difficulty. The orchestrator
executes the assignment and does not change it silently.

```markdown
| Segment | Phases | Implementer | Why the checkpoint is here |
|---|---|---|---|
| 1 | 1 | Sonnet | everything downstream builds on this contract |
| 2 | 2, 3, 4 | Haiku | last one before the final gate |
```

## Dependencies are expressed in the producing phase

If phase 3 relies on an interface from phase 1, that is written **in phase 1**:
"interface `X` is public, the signature does not change, later work relies on it."

That is the *Frozen for later phases* field. The union of those fields across a
segment's phases is the **segment's output contract** — the thing a checkpoint
reviewer may not change with an ordinary finding.

The rule doubles as a test of the split: if a constraint cannot be stated locally,
the phases are cut in the wrong place and need regrouping — and that shows up at
plan approval rather than at a fix.

## Final-gate scenarios

The one-off half of the environment contract: what gets clicked through on the
live system. The permanent half — how the project is built and run — lives in
`CLAUDE.md`; see `dev-skills:implement`'s `environment-contract.md`.

Numbered, concrete, each with its expectation:

```markdown
1. Start the app with `mcp.enabled = true`, `transport = "stdio"`. Connect an MCP
   client to the process. Expect: a non-empty tool list, each with a name and a
   schema.
2. Restart with `transport = "http"`. Connect with a valid session. Expect: the
   same list.
3. Repeat without a token. Expect: 401.
```

The human approves this list at planning. At GATE 1 it is the checklist they work
through — they never have to work out what to check.

## Ledger

The run's record and the resume point after a compaction:

```markdown
- [ ] Checkpoint 1
- [ ] Checkpoint 2
- [ ] Final gate
- [ ] GATE 1: functional acceptance by the human
- [ ] Squash prepared
- [ ] GATE 2: code acceptance by the human
- [ ] Integrated
```

## Verification always exists

Whether the project has test infrastructure is fixed by **the plan**, not
discovered by the implementer. The expected testable scope is part of the plan.

If the project has no tests, a phase still declares verification — as an
observation or a command rather than a test: "grep to confirm the file exists and
is imported". Without it, in a project without tests, phases have no check at all
short of the final gate.

**The plan names the cases; the implementer writes the test code.** *Verification*
gives the level, the file, and the list of cases with expected assertions — what
counts as correct behaviour, which is a decision. The scaffolding — `describe`,
mocks, fixtures, render helpers — is mechanics and follows the repository's
neighbouring tests.

Where red *is* the contract — a bug, or tests as the goal — say in the phase that
the test lands as **its own commit before the implementation**, so the reviewer
can run it there and watch it fail.

## Before you present it

Read the plan against the spec, or against the conversation if there is no spec:

1. **Coverage.** Every requirement points at a phase. List anything that does not.
2. **Placeholders.** No "TBD", no "handle edge cases", no "similar to phase N".
3. **Name consistency.** A symbol frozen in phase 1 is spelled the same way in
   phase 4.
4. **Seven fields.** Every phase has all seven subheadings, dashes included.

Fix what you find inline. For interface shape and seam placement, the vocabulary
is in [codebase-design.md](references/codebase-design.md).

## The gate

Present the plan and take approval before anything is built. Show:

- the phase list, one line each;
- the topology: segments, checkpoints and their relations, with the reason for
  each checkpoint;
- the final-gate scenarios;
- the test seams, as their own question;
- anything you settled by your own judgement rather than from the spec.

Then ask:

> **This plan, as written, is what gets built. Approve?**

This is the last point where a correction is free.

## Handoff

Once approved, stop. The human invokes `dev-skills:implement`; it creates the workspace,
runs preflight, and executes. Do not create a branch or a worktree here.

## What is not in a plan

- product decisions — they are in the spec, and the plan does not reopen them;
- function bodies, test code, imports and style — typing, not decisions;
- commit text — derived from the Goal at finish;
- the other plans in the spec's list — each is planned when the human names it.
