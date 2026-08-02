# The interview

The technique itself. It lives in a file rather than in `dev-skills:grill`'s body because
other skills run the same interview inside their own frame, and a user-invoked
skill cannot be reached by anything but the human typing its name.

## The instruction

Interview me relentlessly about every aspect of this until we reach a shared
understanding. Walk down each branch of the decision tree, resolving dependencies
between decisions one-by-one. For each question, provide your recommended answer.

Ask the questions one at a time, waiting for feedback on each question before
continuing. Asking multiple questions at once is bewildering.

If a *fact* can be found by exploring the environment (filesystem, tools, etc.),
look it up rather than asking me. The *decisions*, though, are mine — put each
one to me and wait for my answer.

Do not act on it until I confirm we have reached a shared understanding.

---

That is the whole technique, and the four paragraphs are load-bearing in their
own right. Everything below is this project's addition to them.

The fact/decision split is the one that decays first. "Look it up rather than
asking" was written for a live conversation; read inside another skill's frame it
becomes licence to settle *decisions* alone too, and the interview turns into the
model talking to itself.

## Depth scales; the alignment does not

"Every aspect" is scaled to the work. A clear rearrangement of two buttons does
not need a long design interview; a new subsystem does. What does not scale is
*whether* you and the human end up meaning the same thing — that is required
either way, and on a small task it may take one restatement and a yes.

"This is too simple to need a design" is where unexamined assumptions do their
most expensive work. Keep the design short instead of skipping it.

## Around the interview

- **Look at the project first.** Files, docs, recent commits — this is the
  fact-finding the instruction asks for. Checking a premise (does that component
  exist, where does the theme live) is part of grilling, not a reason to reach
  for another skill. Reach for `dev-skills:scout` only when you genuinely need a map of
  unfamiliar territory.
- **Check the scope early.** If the request describes several independent
  subsystems, say so before spending questions on the details of something that
  has to be decomposed first.
- **Offer two or three approaches** with their trade-offs, lead with the one you
  recommend and say why. Cut ruthlessly — every approach loses whatever nobody
  asked for.
- **Present the design in sections**, each scaled to its own complexity: a few
  sentences where it is straightforward, a couple of hundred words where it is
  not. Ask after each whether it still looks right.
- **Cover** the shape of the thing, how the pieces talk, what happens when it
  fails, and how it will be checked.
- **Be ready to go back.** A question that lands badly usually means an earlier
  answer was understood differently by the two of you.

## Designing so it can be built and checked

- Break the system into units with one clear purpose each, talking through
  well-defined interfaces, understandable and testable on their own.
- For each unit you should be able to say what it does, how it is used, and what
  it depends on. If you cannot say what it does without describing its internals,
  the boundary is in the wrong place.
- In an existing codebase, follow the patterns already there. Where existing code
  genuinely gets in the way of this work, include the targeted improvement in the
  design — the way a careful developer improves the code they are working in. Do
  not propose unrelated refactoring.
