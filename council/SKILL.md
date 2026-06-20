---
name: council
description: Spawn a "council" of parallel read-only subagents to deeply explore an area of the codebase, then synthesize their findings before acting or planning. Reach for this whenever you need to UNDERSTAND code rather than just edit it — mapping an unfamiliar subsystem, tracing how something works end to end, hunting down where a confusing bug or error actually originates, auditing everything that touches a feature, or grounding a refactor/design plan in what the code really does. Trigger it even when the user doesn't say "council" or "subagents" — phrases like "how does X work", "where is X used", "investigate this error", "map out", "trace", "audit", or "plan a refactor of X" are strong signals. Skip it for trivial single-file lookups that one Read or Grep already answers, and note that it's for *understanding* code, not for dividing up implementation work — don't reach for it just because a request mentions agents or parallelism.
allowed-tools: Task, Read, Glob, Grep, LS
---

You are orchestrating a *council*: several subagents investigate one area in parallel, each from a different angle, and you fuse their reports into a single grounded picture. The point is breadth and variance — many independent looks catch things a single linear pass misses — without you personally reading the whole codebase one file at a time.

## 1. Scout before you dispatch

First, orient yourself just enough to hand out *good, non-overlapping* assignments. Skim the area of interest: find the entry points, the key files and paths, and the rough architecture (Glob/Grep for the obvious keywords; Read a couple of central files).

You are not trying to fully understand it here — you are trying to carve the space into distinct sub-questions so your subagents don't all grep the same file. Sketch a quick coverage map: the 5–12 meaningfully different angles on this area, and what's explicitly out of scope. That map is what makes the parallelism pay off instead of producing ten overlapping reports.

If the area turns out small enough that one or two reads answer it, just answer it directly — don't convene a council for a one-liner.

## 2. Convene the council

Spawn subagents in parallel with the Task tool — **one per angle** — scaling the count to the breadth you found in step 1 (default ~6–10; fewer for a narrow area, more only if it's genuinely sprawling). Flooding a small area with ten agents mostly buys redundant work and burns tokens for no extra signal.

Give each subagent a dispatch packet so it starts warm instead of re-orienting from scratch:

- **Shared context** from your scouting — entry points and key paths, pasted in. This is the main lever against repeated work: every agent inheriting your map beats every agent rediscovering it.
- **Its specific angle** — one focused question. Keep them distinct, e.g.:
  - how is X initialized / configured?
  - where is X called from, and what calls into it?
  - what does X depend on, and what depends on X?
  - what's the data / control flow through X?
  - what tests cover X, and what do they quietly assume?
  - what are the edge cases, error paths, and failure modes?
- **Variance seats** — reserve 1–2 agents for angles a straight investigation skips: "what's fragile or could go wrong here?", "is there dead, duplicated, or orphaned code around X?", "what's surprising or inconsistent?". This is where a council beats a checklist.
- **Constraints** — read-only tools only (Read, Glob, Grep, LS), no edits.
- **Return contract** — a concise structured report: for each finding, a one-line claim, the evidence as `file:line` (not "somewhere in auth"), and a confidence level. Line-level citations are what make the synthesis trustworthy enough to act on.

## 3. Synthesize, then act

When the reports land, don't concatenate them — reconcile them into one coherent picture:

- **Consolidated map** of the area: the key components, what each is responsible for, and how they connect — every claim anchored to a `file:line`.
- **Conflicts and low confidence**: where two agents disagree or a finding is shaky, resolve it by reading the actual code yourself rather than averaging guesses. Flag anything you couldn't confirm.
- **Open questions**: what the council couldn't determine, so it doesn't masquerade as settled.

Then act on the goal:

- **Implementation requested** → give a short synthesis first, so the user can catch a wrong turn before you write code, then proceed with the full context in hand.
- **Plan mode / a plan requested** → produce a detailed, grounded plan that cites specific files and line-level insights from the reports — concrete enough that someone could execute it without re-investigating from zero.

## Param reference
- `n=<number>` — override the subagent count (otherwise scaled to the area, ~6–10).
- `plan` / `plan mode` — synthesize into a plan instead of implementing.
- Topic is inferred from the rest of the prompt.

## Example invocations
- `/council n=15 how does authentication work?`
- `/council find all places we use InstancedGeometry n=5`
- `/council getting this error, investigate: <paste error>`
- `/council plan — how should we refactor the payment module?`
