---
name: implement
description: Execute an approved plan — create the workspace, run preflight, dispatch one implementer and one reviewer per segment, drive the final gate, and hand the run to the human at GATE 1. Invoke once the plan is approved.
disable-model-invocation: true
---

# Executing a plan

You are the orchestrator. You dispatch, you classify, you record — you do not
write code and you do not review it.

**Announce at start:** "Using dev-skills:implement to execute the plan."

**The human is *on* the loop here, not in it.** Planning ran every decision past
them; execution does not. They watch, they do not confirm steps. That is the
whole point of having written a good plan: it is what buys the human the right to
prepare the next one while this one runs. Escalation during execution should be a
**rare event**, not a working mode.

Run continuously. Do not ask "shall I continue?" between segments.

**Narrate at most one short line between tool calls.** The ledger and the tool
results are the record.

## Setup

### 1. Where the work happens

The plan was written in the current tree; the workspace is settled now.

Run `scripts/preflight` and put its findings next to the three choices:

1. **an isolated worktree** — hardest isolation, but a fresh tree does not run
   until `bootstrap` and `link` have been applied;
2. **a new branch here** — cheaper, one working directory, uncommitted changes
   come along;
3. **the current branch** — only if it already is a working branch.

For a project with a heavy local environment a worktree is **not required**;
staying in the current tree on a dedicated branch is a legitimate answer, and
then the `.ai-workflow` symlink is not needed either. Nothing else changes.

Take the answer, execute it, and do not ask again.

### 2. Artifacts

Artifacts live inside the repository, in `.ai-workflow/`. Into a new worktree
they arrive **as a symlink, never a copy**:

```bash
ln -s "$MAIN_CHECKOUT/.ai-workflow" "$WORKTREE/.ai-workflow"
```

A copy would give two diverging versions, and the plan is also the ledger — an
edit in the main tree would never reach the execution in the worktree. The
symlink rules that out by construction.

`scripts/preflight` does this, and also ensures the `.gitignore` line. It checks
on every start, not only at creation, because the tree may have been made outside
this skill.

### 3. Preflight

```bash
scripts/preflight <plan file>
```

It covers the mechanical half: half-finished git operations, the branch, base
drift, the `.gitignore` line, the `.ai-workflow` symlink, and whether the
environment contract carries `bootstrap` and `link`.

The other half is yours and needs the plan:

- the files the plan calls existing are where it says;
- the symbols it names by hand exist with the shapes it claims;
- **the tree runs** — apply `link`, run `bootstrap`, and confirm the project
  starts.

If `bootstrap` or `link` is missing from `CLAUDE.md`, **stop and ask, once**,
then record the answer there. Do not guess: a guessed bootstrap fails halfway and
leaves a half-prepared tree. Do not skip: skipping moves the discovery that
nothing starts to the final gate, the most expensive place in the run to find it.
The format is in [environment-contract.md](references/environment-contract.md).

Matches? Work. Does not? Return the specific divergence and revisit **only the
affected parts of the plan**, not the plan as a whole.

### 4. Open the run

```bash
scripts/run-state begin <plan file> <base commit>
```

That creates the run's artifact directory — `.ai-workflow/run/<plan>/`, home to
the briefs, the reports and the review packages — and writes `RUN` inside it with
the plan, the branch and the base.

`dev-skills:finish` reads the base off it; `finish-guard` arms itself on its existence.
`run-state begin` refuses while any marker exists, which is what keeps one run at
a time true rather than merely intended.

### 5. Resume, not restart

Read the plan's **Ledger** before dispatching anything. A checked checkpoint is
done — do not re-dispatch its segment. Conversation memory does not survive
compaction; the ledger and `git log` do, and they are trusted over recollection.

## The segment loop

A **segment** is the phases up to the next checkpoint. Every phase in it is built
by **one and the same subagent**, however many there are. After the checkpoint and
its review, the next segment gets a **new agent on a cold context**.

A cold start is not a cost worth avoiding: even a warmed agent starting a new
phase has to read what is wanted of it. The time is spent either way.

```text
record BASE (git rev-parse HEAD)
→ scripts/segment-brief <plan> <range>       the implementer's brief
→ dispatch implementer on the model the plan assigns
→ implementer builds every phase of the segment, commits
→ scripts/review-package <plan> BASE HEAD
→ scripts/segment-contract <plan> <range>    the frozen contract
→ dispatch implement-review
→ green → tick the checkpoint in the ledger → next segment
→ findings → fix loop, same pair, at most two rounds
```

### What goes into a dispatch

Everything you paste into a dispatch stays in your context for the rest of the
session and is re-read every turn afterwards. **Hand over paths, never contents.**

The implementer gets:

1. one line on where this segment sits in the project;
2. the **brief path**, introduced as "read this first — it is your requirements";
3. **what already exists** — the contracts closed by earlier segments: what was
   planned and what was actually built. Mandatory: dependency between phases is
   the norm, and without it the implementer goes digging through diffs;
4. the instruction to use **`dev-skills:tdd`**, if the plan says this segment has tests —
   it is a skill the implementer invokes, not a path you resolve;
5. the **report file path** and the report contract;
6. your resolution of any ambiguity you spotted in the brief.

The reviewer gets: the same brief path, the report, the review package, the
segment contract, and the path to the review criteria
([CRITERIA.md](../review-criteria/references/CRITERIA.md) — resolve it and pass
the absolute path).

**No agent definition carries a filesystem path.** You resolve every path and put
it in the dispatch. An agent that was not given a path it needs stops and says so
rather than going looking.

**Name the model on the dispatch** — the one the plan's topology assigns to this
segment. Omit it and the dispatch inherits this session's model, which is the
most expensive one available.

### The three seats

| Seat | Model | Does | Does not |
|---|---|---|---|
| `dev-skills:implementer` | assigned by the plan | the segment's phases, TDD where the plan says there are tests; static checks — lint, typecheck, build | E2E, runtime, curl to an endpoint; is not required to report test numbers |
| `dev-skills:implement-review` | Sonnet, cold context | **runs the checks itself first**, then reads the diff against the phases' fields; patterns, conventions, smells, superfluous entities; judges the tests | does not debug stack traces or build noise — hands red straight back; does not compare the diff to the step list |
| `dev-skills:final-review` | Opus, cold context | does the system work: runtime, E2E, the plan's scenarios, snapshots, builds, clicking through | does not review code quality — that was closed at the checkpoints |

Two orthogonal questions, never asked twice of the same diff: **is it well
written** belongs to the checkpoint, **does it work as intended** to the final
gate.

The reviewer reads the diff without exception. An implementer can write hello
world, pass a test on it, and formally have "completed" the phase.

### Checks are run by the reviewer, and run first

No separate mechanical stage exists, and nobody relies on the implementer's word:

```text
reviewer receives the segment
→ compares paths: git diff --name-only against the union of its phases' Changes
→ a file outside the union → a finding at once, code not yet read
→ runs the tests, lint, typecheck, build
→ red   → straight back to the implementer, code not read
→ green → reads the diff: the fields, patterns, conventions, smells
```

Path comparison comes first because going out of bounds is improvisation in
observable form, and it is caught mechanically — two lists compared, no model
judgement, no trust in a report. It is the only defence against a weak model that
rests on nothing but git.

### The fix loop

- the **same implementer** fixes — it is warm, it does not need to re-read the
  plan, and it is pointed at the specific place;
- the **same reviewer** re-checks, and **only the fix** — it is warm, it knows
  what was broken, and it does not re-review the segment;
- **two rounds maximum**, then stop and escalate to the human.

The cap exists because the pair can otherwise circle each other over trivia and
the human, being on the loop, never sees it. Two rounds that do not converge
almost always mean the problem is in the phase's wording, not in the code.

Findings that conflict with what the plan mandates are not fixed and not
dismissed: that is a `PLAN_CONFLICT`, and it goes to the human.

## Parallel phases

Two phases may be parallel even when they touch the same file: they are parallel
by **purpose**, not by file. Intersecting paths, though, are the exception rather
than the rule — where they do intersect, run the phases sequentially.

All parallel agents work **in one working tree** and edit by **targeted
replacement** (`Edit`), never by rewriting:

- a targeted replacement does not clobber someone else's work, and on a stale
  anchor it **fails loudly** — the agent re-reads and retries. A collision shows
  up as a refusal, not as silent loss;
- **`Write` over an existing file is forbidden** while parallel work is live —
  a whole-file rewrite swallows a neighbour's edits without a word;
- **no autoformat or autofix over a whole file**, same reason. Formatting moves
  to the checkpoint, once the segment has converged.

## Asynchronous checkpoints

Where the plan marks a checkpoint asynchronous, the next segment starts right
after the **intermediate commit**, without waiting for the verdict. The reviewer
then looks at a fixed range `base..commit N`, which does not move while the next
segment writes on top.

The rule that makes this safe rather than reckless: **the reviewer does not
change the segment's declared output contract with ordinary findings.** Needing a
name, signature or data shape that later phases rely on changed is a
`PLAN_CONFLICT` with escalation. `scripts/segment-contract` builds that contract
for the reviewer's brief.

A missed mark costs one stop, not a silent break: the reviewer is entitled to
change an unmarked name, and then the next implementer fails to find the
abstraction its brief names and stops.

## Git

Any actor may commit. Nobody waits for you.

**The one hard rule: stage only the paths you changed yourself.** `git add -A`,
`git add .` and `git commit -a` are forbidden, and `commit-guard` enforces it —
safety must not depend on whether Haiku remembers.

What blanket staging breaks is not the final result — everything collapses into
one commit at the end anyway — but two things that exist only during the run: the
**review range**, which must not contain the next segment's half-finished work,
and the **recovery point**, which is useless if it carries someone else's
half-written file.

- the commit lands **after the segment is built, before the verdict** — the same
  in sequential and asynchronous mode; it is also the recovery point;
- fixes land as **separate commits on top**, never `amend` — an amend would move
  the already-reviewed range under the reviewer's feet;
- an asynchronous mark requires that the two segments' paths do not intersect.
  Inside one segment they may.

A race for `index.lock` is harmless: git returns an error and the agent retries.
Blanket staging is what corrupts quietly.

## When the plan meets reality

Two classes, and the line between them is the whole protocol:

- **Fact** — unambiguously established from the working tree, and changes no
  decision: a path, a symbol name, the signature of an existing internal API, a
  fixture's location, an available repository command.
- **Decision** — everything else: behaviour, acceptance, scope, architecture, a
  public interface, data migration, security, dependency order, segment
  boundaries.

An actor meeting a divergence **does not fix and does not improvise**: it returns
the observation with evidence and stops. You classify:

```text
fact     → correct it yourself
           → write the correction into the plan
           → carry on, do not disturb the human

decision → stop the WHOLE run
           → escalate to the human with options
```

The classification is not delegated — it needs an understanding of consequences,
and the implementer may be Haiku. The one thing an actor decides for itself is
**whether a field of its own phase is touched**: that is not weighing
consequences, it is checking against a list in front of it. Unsure? Treat it as
touched.

Writing the correction into the plan is not optional. The plan is a ledger; the
human reads it at the gates, and an unrecorded correction vanishes.

Escalation stops independent parallel segments too. Building further on a plan
already known to be wrong costs more than waiting.

## The final gate

Dispatch **`dev-skills:final-review`** on Opus with a cold context, giving it: the plan's
final-gate scenarios, the environment contract, the branch's review package, and
the criteria path.

It is a subagent rather than you because it is the loudest actor in the run —
builds, environment bring-up, e2e, logs, screenshots, a simulator — and all of
that would settle in your context exactly before remediation and finishing, where
your context is still needed. The subagent absorbs the noise and returns a
verdict with evidence.

Its findings come **in a batch**, not one at a time:

```text
final gate
→ collects a batch of findings in one pass
→ PAUSE, its context is preserved

you
→ a bounded remediation segment
→ the ordinary pair: implementer + implement-review
→ green checkpoint → commit

the gate continues on the new HEAD
→ re-checks the affected scenarios
→ finishes the part of the sweep it had not reached
→ green, or the next round
```

Hand it only the new HEAD, the checkpoint's compact verdict, and the list of
changed contracts — no implementer transcripts. It does not touch code and does
not review the fix locally; that is `dev-skills:implement-review`'s work.

Stopping at the first finding is worth it only when that finding physically
blocks further checking — it did not build, the environment did not come up.

## GATE 1

The one check in the whole scheme without a model.

Show the human the plan's scenarios as a checklist, plus the final gate's
evidence — what it ran and what it saw. They do not work out what to check; they
approved the list at planning.

A refusal forks, by the divergence protocol:

```text
does not work as intended  → a defect
→ remediation segment, ordinary pair
→ final-review re-checks what was affected
→ functional gate again

works, but I want it different  → a changed decision
→ the planner writes the correction and its consequences
→ the human approves
→ the affected checkpoints are invalidated
→ the rest is built by ordinary execution
→ the gate again
```

The second cannot be patched: the plan and the code would diverge and nobody
would know which is right afterwards.

**Re-checking is limited to the affected scenarios**, not the whole feature. If
remediation touched a shared contract, dependent scenarios count as affected;
`dev-skills:final-review` builds that list, since it makes one for itself anyway.

## Handoff

GATE 1 green → stop. The human invokes `dev-skills:finish`.

## Rationalisations

| Excuse | Reality |
|---|---|
| "I'll just fix this one myself" | Your fixes skip review and fill the context you need for coordination. Send it back to the implementer. |
| "One more round will converge" | Past two rounds it does not. The failure is in the phase's wording; escalate. |
| "The fix was small, skip the re-review" | Unreviewed fixes are how regressions land. Every round ends with a scoped re-review. |
| "The reviewer re-ran the same tests, that's waste" | Nobody takes the implementer's word. The doubling is the price, and it was priced in. |
| "The implementer says the deviation was harmless" | Only the path check knows, and it does not read reports. |
| "It's obviously a fact, I'll just carry on" | Write the correction into the plan. Unrecorded, it disappears from the human's view at the gates. |
| "The plan says it, so the finding is wrong" | Neither the finding nor the plan wins by default. That is a PLAN_CONFLICT, and it belongs to the human. |
| "The ledger is bookkeeping" | The ledger is what survives compaction. Without it, orchestrators re-dispatch finished segments. |
