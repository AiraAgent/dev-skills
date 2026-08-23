---
name: handoff
description: Pack this session into a document a fresh agent continues from — the work, or the thinking. Type it when you are about to move to a new chat.
disable-model-invocation: true
---

# Handing a session over

The next agent has none of this conversation. What you write here is everything
it gets.

**Announce at start:** "Using dev-skills:handoff to pack this session for a fresh
context."

<HARD-GATE>
Writing the handoff is not the moment to finish the work. Do not fix what you
notice while writing, do not run the build, do not commit. Ask, write, hand
over.
</HARD-GATE>

## What this is for

**Continuation**, in one of two directions: the new session carries the *work*
forward, or it carries the *thinking* forward. Both start from a context that is
full here and empty there.

It is not a brief for a task nobody has started. That is `dev-skills:grill` and
then `dev-skills:plan`, and they produce a better one than this ever will.

## Ask once, then write

Two things decide the shape, and you ask only about the ones the request did not
already answer:

1. **What does the new session do** — carry the work forward, or carry the
   thinking forward? Take the entry it starts from too, when it is obvious or
   named: `dev-skills:bug`, `dev-skills:grill`, `dev-skills:plan`, plain
   conversation.
2. **File, or text in the chat?**

One turn, both questions in it. Then write the document. Nothing else is asked,
and nothing is asked after.

## Do not go looking

No `git`, no `grep`, no reading files, no subagents, no verification pass. Write
from what this session already holds.

Three reasons, and each one is load-bearing:

- What makes a handoff worth anything is the layer that exists *only* in this
  conversation — what was tried and failed, why a decision went the way it did,
  what the human corrected. Everything else the next agent reads faster than you
  can quote it.
- The session asked for a handoff is nearly always the session that ran out of
  room. Spending its last context re-deriving is spending the exact resource the
  handoff exists to save.
- A stale fact is worse than a missing one. Verified an hour ago is not verified.

So: **a fact you are not certain of is written as uncertain.** Not omitted, not
asserted — marked. "The dev server was running as of this writing" costs nothing
and cannot mislead; "the profile is not logged in" once sent a fresh agent to ask
the human for something it already had.

## The core

Every handoff carries these, whichever direction it goes:

- **The goal**, in one sentence.
- **The repository**, as an absolute path. Not the branch — that is the fastest
  thing here to go stale, and the new session may not be on it.
- **What is decided, and why.** The reason is the part that survives; a decision
  without one gets reopened.
- **What is out of scope**, and the hard constraints — including the project
  conventions someone would otherwise violate on their first edit.

## The tail

### Carrying the work forward

- What is done, and what shows it — the test that passes, the commit, the output.
- What is left.
- The paths that matter, with receipts (below).
- The commands: how to run it, how to check it.
- **Approaches already tried and abandoned**, so the next agent does not walk
  them again.
- Anything in the working tree that is not a deliverable: instrumentation to
  strip, a scratch file to revert, edits the human is making in parallel.
- The state of the environment — what is running, what is logged in — as of this
  writing.

### Carrying the thinking forward

- **Where the decision tree stands**: what was asked, what was answered, which
  branches are untouched.
- **What the human rejected, and why.** The next session is obliged to
  recommend an answer to every question it asks; without this list it will
  recommend what has already been turned down.
- **Agreed against proposed** — what the human confirmed, kept apart from what
  is still only the model's suggestion. Handing the second over as the first is
  how a design acquires decisions nobody made.
- The vocabulary that settled, where a term now means something specific.

## What earns a place

- **Receipts.** A checkable claim carries what checks it: `path:line`, a commit
  hash, a command. The failure this prevents is not confusion — a fresh agent
  does not get confused, it silently re-derives, and an uncited claim costs it
  twenty tool calls to rebuild.
- **Absolute paths** for anything outside the repository — reference checkouts,
  a second repository, a directory named only by convention here.
- **Link, do not copy.** An epic, a plan, an ADR, the reports of an open run:
  name the path. Copying it in guarantees the two disagree later.
- **A rejection only with its reason.** With one it is load-bearing; without one
  it is a list of everything anyone said all day.
- **No secrets.** Keys, tokens, passwords, personal data — out.
- **Length follows the task.** Long enough that nothing has to be re-derived,
  short enough that it is read rather than skimmed.
- **Name the entry** the new session starts from, so its first move is not a
  guess.

## Handing it over

**To a file** — `.ai-workflow/handoff/YYYY-MM-DD-<name>.md`, and make sure the
repository ignores that directory:

```bash
grep -qxF '.ai-workflow' .gitignore || printf '.ai-workflow\n' >> .gitignore
```

Without a trailing slash — a pattern with one matches directories only, and in a
worktree `.ai-workflow` is a symlink, which git sees as a file. If the exact line
is absent, add it; do not analyse the variants already there.

Then give the human the path, and nothing else. They open the new session with
it.

**To the chat** — the whole document in a single fenced block, with no commentary
wrapped around it. Anything outside the fence gets copied along with it, and a
handoff has already been corrupted that way once: a terminal status line landed
in the middle of one, took a paragraph with it, and no one noticed.
