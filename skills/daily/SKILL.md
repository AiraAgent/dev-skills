---
name: daily
description: >
  Daily is the user's personal task tracker; the `daily` CLI reads and changes
  its tasks. Use when the user names Daily about tasks (also spelled "дейли"),
  asks about their own day or to-dos without naming it ("what do I have today",
  "what was I doing on Monday", "что у меня сегодня"), or wants a task
  captured, completed, rescheduled, searched, estimated or time-logged.
---

# Daily

The CLI is its own source of truth: `daily --help`, `daily <command> --help`,
`daily schema --json` (the whole contract in one call). The index below is a
cheat sheet — where it disagrees with `--help`, `--help` wins.

## Every run

- **`--json`.** The human table truncates task content to the column width and
  drops the tail silently — the user's tasks are written in Russian, where this
  happens almost every row. Read JSON and compose the reply yourself.
- **Empty is not proof.** With no scope flags every command works inside the
  project active in the desktop app — state you cannot see. If a read comes
  back empty, or what the user asked about is missing from it, run it again
  with `--all` and say that you widened the search.
- **Compute dates, don't reason them.** `date +%F` today, `date -v+1d +%F`
  tomorrow, `date -v-1d +%F` yesterday, `date -v+mon +%F` next Monday.
- **Leave `--force` alone.** `delete` moves a task to the trash and `restore`
  brings it back. `--force` deletes permanently, and with no id it empties the
  whole trash — only on an explicit request, and confirm even then.

## Reading

One call, then retell it. Quote a task by its full first `content` line rather
than a truncated one, and convert times and estimates into minutes and hours
yourself.

## Creating

Write a **ticket**, not a note to self: it has to still make sense in a month
with none of this conversation in context. `content` is markdown, and the shape
the user already writes is summary → symptom → fix:

```markdown
# Attachments are saved with the wrong extension

Files under `~/Library/Application Support/Daily/assets/<id>.png` are WebP
inside — the extension is copied blindly from the source name. External tools
choke on it: each file needs `sips -s format png` before anything will open it.

Fix: detect the real format from the signature at save time and write the
matching extension, plus a migration for what is already in assets.
```

- **The first line is the summary, and the list view shows nothing else — cut
  at 60 characters.** Lead with `# ` and make it a specific self-contained
  claim inside that budget: "Attachments are saved with the wrong extension",
  not "fix the bug" and not a sentence that dies mid-word.
- **One task, one outcome.** Two unrelated fixes are two tasks.
- **Carry the evidence.** Exact paths, commands, error text, versions — in
  backticks or a fenced block. A bug states what happened against what was
  expected. What you had to run to find this out, the reader should not have to
  rediscover.
- **End on the definition of done** — the concrete change that closes the task,
  never "look into it".
- Write the task itself in the language the user is speaking, not in the
  language of this skill; their tracker is in Russian.
- Keep it scannable: short paragraphs or a bullet list, no headings past the
  first.

Multi-line content needs ANSI-C quoting — inside `"…"` a `\n` is stored
literally, as two characters:

```sh
daily tasks add $'# Summary line\n\nSymptom paragraph.\n\nFix: …' \
  --tag Daily --tag Bug --json
```

**Tag it.** Read `daily tags --json` and tag only from that list — `--tag`
silently creates whatever you name, so a typo becomes a permanent tag. The
scheme is **area + type**: `Bug`, `Feature` and `Ideas` are the closed set of
type tags, everything else in the list is an area (a product or a life bucket).
Almost every task carries an area; a type tag rides along only when the task
plainly is one, never alone, and two areas never share a task. Predict the area
from the content — if you cannot, ask which rather than guessing.

**Offer an estimate when the task is a chunk of work to be planned into a day**
— a fix, a feature, a chore with known steps — and not for a reminder or a
quick capture. Propose a figure rather than asking an open question, in the
granularity the user works in: 30m, 1h, 2h. Apply it with
`daily tasks estimate <id> <minutes>` once they answer, or pass `--estimate` at
creation if they already named one.

Creating itself needs no confirmation: it is additive and `delete` walks it
back. Show the content you wrote and the returned id.

## Changing

**1. Find the task.** Read `daily tasks <date> --json` or
`daily tasks search "<query>" --json` and match it against what the user
described. Done when you hold the **full id** (21 characters) and the first
`content` line of that exact task. Never pass a prefix the user typed straight
into a mutation: it resolves inside the active project, and resolving uniquely
does not mean it landed on the task they meant.

**2. Show it and wait for yes.** One line: the task's content → what will
happen to it. More than one candidate — list them and ask which. Done when the
user has confirmed; until then, do not run the mutation.

**3. Apply and verify.** Mutate with the full id and `--json`. Done when the
response is `ok: true` **and** the changed field in `data.task` matches what
you promised. A non-zero exit is a result, not a malfunction: 2 invalid or
ambiguous, 3 not found, 4 refused, 5 sync failed. Report which one; do not
retry blindly.

## Command index

```
Read    daily today · daily tasks [YYYY-MM-DD] · daily task <id> · daily tasks deleted
        daily tasks search "<query>" · daily projects · daily tags
Write   daily tasks add "<text>" [--date --time --tag --tags --estimate --project]
        daily tasks done|reactivate|discard|restore <id>
        daily tasks move <id> <YYYY-MM-DD> [--time HH:MM]
        daily tasks update <id> "<text>"    (replaces the content wholesale)
        daily tasks estimate <id> <minutes> (replaces the estimate)
        daily tasks log-time <id> <minutes> (adds to time spent)
        daily tasks tag add|remove <id> <tag>
Scope   --project <id|exact name> · --all (beats --project)
```

- In JSON, `estimatedTime` and `spentTime` are **seconds**, while the flags
  take minutes.
- `tasks add --tag` creates an unknown tag on the spot; `tasks tag add` needs
  one that already exists (`daily tags --json` lists names and ids).
- `--project` takes an exact case-sensitive name or an id; prefer ids in
  automation. In JSON, projects live under `branches`.
