---
name: finish
description: Close out a run — squash it into one commit, put that commit in front of the human, and integrate it. Invoke once the functional gate (GATE 1) is green.
disable-model-invocation: true
---

# Finishing a run

The phases, the fix rounds and the checkpoint commits were scaffolding for a run
that is now over. What lands is **one commit**.

**Announce at start:** "Using dev-skills:finish to close out this run."

You make the judgement calls — is it done, what does the message say, what did
the human choose. `scripts/finish` performs the git, and refuses to act on any
state it does not recognise. Do not do this by hand: hand-run history surgery is
exactly what `finish-guard` blocks while a run is open.

## The order

```text
functional gate green
→ scripts/finish preflight   branch, run base, range, clean tree, no half-done ops
→ recovery ref on the current HEAD
→ git reset --soft <run base>
→ one commit, its message derived from the plan's Goal
→ tree hashes compared before and after
→ GATE 2: the human reads one commit as one diff
→ merge (fast-forward only) / rebase / leave as is
→ cleanup, only after integration is proven, and only our own worktree
```

`reset --soft` is deliberate. It touches neither the index nor the working tree,
so a conflict is impossible by construction and the equivalence of the trees is
*guaranteed* rather than checked — the script only confirms the hashes match. On
any refusal the state is left staged: nothing is lost and everything is visible.

## 1. Preflight

```bash
scripts/finish preflight
```

It reads `.ai-workflow/run/<plan>/RUN` for the plan and the base, and refuses on
a detached HEAD, on the default branch, on a dirty tree, on a half-finished merge
or rebase, on an empty range, or on a base that is no longer an ancestor of HEAD.
Two markers is also a refusal, naming both.

A refusal is information, not an obstacle. Settle what it names and run it again.

## 2. The message

Derive it from the plan's **Goal**, not from the diff. That text was written
before the code and approved at the plan gate; a message reconstructed from a
diff describes what changed, which the diff already says, instead of what it was
for.

Subject: Conventional Commits — `commit-guard` requires it. Body: what and why,
in a few lines. No trailers, no session links, no co-authors.

Write it to a file and show the draft to the human before committing.

```bash
scripts/finish squash <message file>
```

The script writes a recovery ref at the pre-squash HEAD first, and reports it.
`scripts/finish recover` puts everything back.

## 3. GATE 2

Show the human **one commit**: the message and the whole diff — exactly the unit
that will land on the base.

This is a different question from GATE 1. The first asks *does the system work*;
this one asks *what code are we merging*. Reading code at the first gate turns it
into diff-reading instead of a real check of behaviour, which is why they are
separate and in this order.

It is also the natural catcher for what no single checkpoint could see: an
abstraction duplicated between segments, a convention broken across the branch.

**On refusal, nothing is repaired in place and nothing is amended.** The work
goes back to the orchestrator: a remediation segment **on top of** the squashed
commit, the ordinary implementer + reviewer pair, then `dev-skills:final-review` over what
was affected, then the functional gate, then `dev-skills:finish` again — which squashes
the two commits into one.

## 4. If the base has moved

```bash
scripts/finish rebase
```

The rule is proportional to the overlap, not "any rebase invalidates everything":

```text
clean rebase, base changes do not touch the run's paths
→ both approvals stand, integrate

clean rebase, base touched the same paths
→ final-review re-runs the affected scenarios
→ the functional gate covers only those

rebase with conflicts
→ resolving a conflict is a code change
→ an ordinary remediation segment, then the usual path
```

The overlap is computed mechanically — `git diff old_base..new_base --name-only`
against the run's paths — with no model judgement. The script prints it.

## 5. Integration

Put the three to the human and wait. The decision is theirs.

1. **Merge into the base** — `scripts/finish integrate --ff-only`. Fast-forward
   only: the run's commit was built on that base, and if it will not fast-forward
   the base has moved and the answer is a rebase, not a merge commit papering
   over it.
2. **Push and open a pull request** — the worktree stays; review feedback is
   fixed there.
3. **Leave as is** — nothing is deleted, nothing is removed.

Discarding the work is not on the menu. It happens only when the human asks for
it in so many words.

## 6. Afterwards

**Mark the spec entry done.** If the plan names a spec, set that entry's state to
*done* in the plan list. Together with `dev-skills:plan` setting *in progress*, those are
the only two writes to a spec after it exists.

**Close the run:**

```bash
../implement/scripts/run-state end
```

That removes `RUN` from the run's artifact directory. The marker is what arms
`finish-guard`; leave it and the next ordinary piece of work in this repository
meets a block it did not earn. Everything else in that directory stays.

**Cleanup:** `scripts/finish cleanup`, and only after integration is proven. It
removes only a worktree under `.worktrees/` or `worktrees/` — one this workflow
created. A worktree the host environment owns is never touched. On "leave as is",
nothing is removed at all.

**The artifacts stay.** The spec and the plan remain in `.ai-workflow` after
integration. There is no automatic cleanup: deletion is irreversible and disk is
cheap, so deciding what is no longer needed stays with the human.

## Rationalisations

| Excuse | Reality |
|---|---|
| "I'll just squash it by hand, it's three commands" | The script writes a recovery ref and compares tree hashes. By hand you get neither, and `finish-guard` blocks it anyway. |
| "`SQUASH_MSG` is already written" | It is every branch message concatenated with SHAs and dates. It moves the noise out of `git log` and into one commit body. Write the message from the Goal. |
| "GATE 2 is the same review again" | GATE 1 asked whether it works. This asks what we are merging. It is the only place duplication between segments is visible. |
| "The human said the feature is good, that covers the code" | Two gates, two questions. Approving behaviour is not approving a diff. |
| "It's a small change, merge without fast-forward" | A non-fast-forward means the base moved. Rebase, then integrate. |
| "The PR is up, the worktree is clutter" | Feedback gets fixed in that worktree. It stays until the work lands. |
| "This other worktree looks stale, I'll remove it too" | Only worktrees this workflow created. Everything else belongs to the host. |
| "The plan is finished with, delete it" | Deletion is irreversible and disk is cheap. The human decides when it goes. |
