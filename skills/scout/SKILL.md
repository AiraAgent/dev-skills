---
name: scout
description: Map unfamiliar code and answer a specific question about how it works. Read-only — it produces an explanation, never an edit. Invoke before planning in territory you do not know.
disable-model-invocation: true
---

# Scouting the code

Answer one question about how existing code works, with paths and symbols, and
change nothing.

**Announce at start:** "Using dev-skills:scout to map this before we plan anything."

The result is an explanation to the human. Nothing is written to a file unless
they ask, nothing is edited, nothing is committed. If you find a bug while
scouting, name it and move on — fixing it is a different route.

## When this is the right entry, and when it is not

**It is** when you are about to plan work in a subsystem nobody in this
conversation understands yet, or when the human asks how something works and the
answer needs real reading rather than a guess.

**It is not** for checking a premise. "Does that component exist", "where does the
theme live", "is there already a hook for this" — those are one grep, and they
are part of grilling or planning, not a reason to start a separate route. A skill
invoked to answer a question you could answer in two tool calls costs more than
it saves.

It is also not a step toward choosing how much process the work gets. That choice
belongs to the human, and scouting exists to inform them, not to classify the
task.

## Name the question first

Say what you are looking for before you start looking, in one sentence, and check
it with the human if the request was broad. "How does a request get from the
route to the database" is a question. "Understand the backend" is not, and it is
how a scout turns into an unbounded read of the whole repository.

The question sets the boundary. When you reach an answer, stop — do not map the
neighbouring subsystem because you are already there.

## How to read

1. **Find the entry points.** Where does this thing start — a route, a command, a
   handler, an event, a mount?
2. **Follow one real path end to end**, rather than reading every file at one
   layer. A single traced path teaches more than three layers skimmed, and it is
   what tells you which abstractions actually matter.
3. **Name the abstractions that carry weight**, with their paths. What is
   reusable, what is a one-off, what everything routes through.
4. **Find the seams** — the places behaviour can be changed without editing in
   that place. That is what any future plan will be built against.
5. **Read the tests.** They document intended behaviour more honestly than
   comments, and they show where the existing test seams are.
6. **Note what surprised you.** A convention that is not followed, two ways of
   doing the same thing, a layer that is bypassed. That is the part a plan needs
   most and the part no one thinks to ask about.

Follow imports and call sites rather than guessing at names. Where the code
contradicts what you were told, say so — the contradiction is the finding.

## What you report

- the answer to the question, in plain terms;
- the path through the code, as an ordered list of files and symbols;
- the abstractions that matter, with paths;
- the seams, and which of them already have tests;
- what surprised you;
- what you did **not** look at, and why — an honest boundary is worth more than
  the appearance of completeness.

Cite paths and symbols everywhere. A map without coordinates is an opinion.

## Where this ends

Stop. Say what the next step could be — grilling if there is a decision to make,
planning if there is not — and let the human call it.
