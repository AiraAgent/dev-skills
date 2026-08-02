---
name: grill
description: Interview an idea into a shared understanding before anything is planned. Ends in alignment and a stop — no document, no code. Invoke when the task is not yet clear enough to plan.
disable-model-invocation: true
---

# Grilling an idea into a shared understanding

Turn an idea into a design both of you actually agree on, through questions.

The output is **alignment**, and then a stop. No spec file, no plan, no code. If
the work turns out to need more than one plan, `dev-skills:spec` writes the document; if
it needs one, the alignment lands in that plan's header.

**Announce at start:** "Using dev-skills:grill to work out what we are building."

<HARD-GATE>
Do not write code, scaffold anything, or invoke an implementation skill from
here. This applies to every task regardless of how simple it looks.
</HARD-GATE>

## Run the interview

Read [INTERVIEW.md](references/INTERVIEW.md) and follow it end to end — the depth rule,
facts against decisions, the order the questions come in, how the design is
presented, and the confirmation gate at the end.

That is the whole technique, and it sits in a file because
`dev-skills:grill-with-docs` and `dev-skills:improve` run the same interview and cannot invoke a
skill only the human can call.

## Where this ends

Present the design, take approval, then **stop** and say what the next step is:

- the work fits one plan → the human invokes `dev-skills:plan`;
- the work needs several → the human invokes `dev-skills:spec`, which writes the shared
  document and the list of plans.

**You invoke neither.** The human decides when to move on, and how much process
the work gets. Same rule as everywhere else here: the model proposes, the human
calls.

Nothing is written to a file. Vocabulary and hard-to-reverse decisions that
deserve to outlive the conversation belong to `dev-skills:grill-with-docs`, which is a
separate skill precisely because it leaves a durable artifact and this one does
not.

## Visual companion

A browser companion for showing mockups, diagrams and visual options during the
interview. A tool, not a mode: accepting it means it is available for the
questions that benefit, not that every question goes through a browser.

**Offer it just in time, never up front.** Wait until a question would genuinely
be clearer shown than told — a real mockup, layout or diagram question, not
merely a UI *topic*. The first time that happens, offer it as **its own message**,
with nothing else in it:

> "This next part might be easier if I show you — I can put together mockups,
> diagrams and comparisons in a browser tab as we go. It's still new and can be
> token-intensive. Want me to? I'll open it for you."

Wait for the answer. If they accept, start the server with `--open`. If they
decline, continue text-only and do not offer again unless they raise it.

**Decide per question even after they accept.** The test: would they understand
this better by seeing it than by reading it? Mockups, wireframes, layout
comparisons, architecture diagrams — browser. Requirements, conceptual choices,
trade-off lists, scope decisions — terminal. A question about a UI topic is not
automatically a visual question.

If they accept, read [visual-companion.md](references/visual-companion.md) before going on.
