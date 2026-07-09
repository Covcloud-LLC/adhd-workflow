# The ADHD Project Workflow — A Plain Guide

This is how an idea becomes shipped work without getting lost or half-built. It's built for the
way you actually work: lots of ideas, easy to start things, hard to finish them. Every step either
lowers the friction of capturing, or raises the bar for committing — on purpose.

There are **five stages**:

```
ideate  →  reason  →  plan  →  execute  →  validate
 /idea     /reason    /promote   (fresh       /wrap-up
                                  sessions,    + /verify
                                  driven by
                                  /pjm)
```

Each stage is one slash command (except *execute*, which happens in separate Claude sessions).
You run them in the current repo; they read and write that repo's `docs/`.

---

## The one-line version of each stage

| Stage | Command | What it does | Where the output goes |
|---|---|---|---|
| **Ideate** | `/idea` | Dump a raw thought to disk and get out of the way. | `docs/ideas/` |
| **Reason** | `/reason` | Decide if the idea is sound and how much thinking it needs. | a stamp on the idea (+ maybe a note in `docs/notes/`) |
| **Plan** | `/promote` | Turn a reasoned idea into a well-formed, runnable plan. | `docs/plans/` |
| **Execute** | *(fresh session)* | Run the plan's task strings and build the thing. | code |
| **Validate** | `/wrap-up` | Confirm it's done, capture what you learned, pick the next thing. | plan status + memory |

Two helper commands sit alongside these:
- `/standup` — the daily driver. Picks the ONE next thing to work on, enforces the limit of 2
  things in flight at once.
- `/pjm` — a project-manager session you keep open for a work block. It drives and tracks; it
  never builds. It hands you task strings to run in fresh sessions.
- `/design-workshop` — builds a prompt for a separate "critic" session that attacks a hard
  problem before you commit to it. `/reason` calls this when an idea needs it.

---

## Stage 1 — Ideate (`/idea`)

The whole point is **no friction**. You have a thought mid-flight. `/idea` writes it to
`docs/ideas/` and stops. It does not ask questions, flesh it out, or start building. Capture the
thought so it stops nagging you, then move on.

> Example: "What if standup also flagged branches that have gone stale?" → one file in
> `docs/ideas/standup-flag-stale-branches.md`. Done.

An idea captured this way has **not been reasoned yet.** That matters for the next stage.

---

## Stage 2 — Reason (`/reason`) — the new gate

This is the step that stops half-baked ideas from becoming plans. Its job is to make sure **no
idea reaches a plan un-reasoned** — while keeping that check nearly free for the easy ones.

`/reason` reads the idea and asks one question: **how much thinking does this need before I'd
trust a plan for it?** It sorts the idea into one of three tiers, using a simple gut check —
how much design freedom is there, how hard is it to undo, and how much blows up if you're wrong.
(This is the same gut check `/pjm` uses to decide whether a task runs on a cheap or an expensive
model.)

### The three tiers

**1. Clear** — one obvious way to build it. No real design choices. Easy to undo. Doesn't commit
you to anything big.

> Example: "Add a CI check that fails on a missing license header." There's one sensible way to
> do it.

`/reason` writes a one-line reason, stamps the idea `reasoned: clear`, and offers to go straight
into `/promote`. This is the fast lane — most ideas live here and barely feel the gate.

**2. Reasoned** — a real decision, but one with a defensible default. There's a trade-off to name,
maybe two or three ways to go, some risk — but Claude can think it through and recommend one
without needing a back-and-forth with you.

> Example: "Cache the product config." Should it be in memory or in Redis? How does it get
> invalidated? Real questions, but answerable in one pass.

`/reason` does the thinking now: names the decision, lays out the options and how each one fails,
picks one and says why. It writes that to a short note in `docs/notes/<slug>-reasoning.md` and
stamps the idea `reasoned: notes/<slug>-reasoning.md`. Now the plan can be built on a decision
instead of a shrug.

**3. Workshop-required** — wide open, hard to undo, or expensive to get wrong. This is where being
*confidently wrong* costs you the most, so it earns a real stress-test before you commit.

> Examples: a new lifecycle/state model. Load-bearing screen layout. A data contract that lots of
> other code depends on.

`/reason` **refuses** to pass it through. Instead it hands off to `/design-workshop` (below),
which builds a prompt for a separate "critic" session. It stamps the idea
`reasoned: workshop-pending (...)` — and `/promote` will not touch it until you've run the
workshop and come back.

### Two kinds of workshop

A hard problem can be hard in two different ways, so the workshop comes in two flavors:

- **design** — *is this the right thing for the user?* Attacks the UX: the wording, the layout,
  the way a user might misread it.
- **architecture** — *are we building it the right way?* Attacks the solution: the data model,
  concurrency, the shape of a contract, where state lives, what breaks under load or change.
  This one exists because you can reason out the *what* perfectly and still build the *how* wrong.

If a problem is hard on both counts, do the design pass first (it can change *what* you build),
then the architecture pass on the shape you chose.

### After a workshop

You run the workshop in a separate Opus session (paste the prompt, think it through). When you've
got your answer, come back and run `/reason` on the same idea again. It writes up the decision the
workshop reached as the reasoning note and flips the stamp to `reasoned: notes/...`. Now it's
ready to plan.

---

## Stage 3 — Plan (`/promote`)

`/promote` is the **gatekeeper**. It turns a reasoned idea into a plan that a fresh Claude session
can run cold — with real file paths, concrete tasks, and a way to verify each one.

It now checks **two** gates, and both must pass:

1. **The reasoning gate** (new): the idea must carry a `reasoned:` stamp that isn't still
   `workshop-pending`. No stamp → "run `/reason` first." This is the check that ties the whole
   thing together.
2. **The format rubric** (as before): is the plan well-formed? Clear definition of done,
   actionable tasks, each one verifiable, scoped to one deliverable, and a one-line "why."

These two gates check different things. Reason asks *"is this idea sound and thought-through?"*
Promote asks *"is the plan itself solid enough to hand off?"* An idea can pass one and fail the
other.

If it passes, `/promote` writes `docs/plans/<slug>.md` as `todo` (it does **not** start the work)
and sets the `Model` and `Effort` the plan should run at. Refusing is a normal, healthy outcome —
a weak plan promoted is worse than an idea left alone.

### The red-gate: high-effort plans start with a failing test

When a plan's `Effort` is `high` or above, `/promote` writes its correctness-sensitive task
strings differently: each one **opens with the test to write first**. The execution session must
write that named test, run it, watch it fail, and say "confirmed red" — *then* build. Why? A
session that writes the code first and the test after is grading its own homework: the test tends
to assert whatever the code already does, bugs included. A check authored at planning time, before
any implementation exists, can't be bent that way — and the mandatory red run catches tests that
accidentally test nothing. Spike, doc, and design slices are exempt (when the spec *is* the
output, there's nothing to red-test), and low/medium-effort plans keep today's plain `Verify:`
clause on purpose — this is deliberately not full TDD, just its one load-bearing idea. A `medium`
plan can opt in with a `> Red-gate: yes` header line.

---

## Stage 4 — Execute (fresh sessions, driven by `/pjm` and `/standup`)

Plans don't get built in your planning session. Each task in a plan is a **self-contained string**
— it carries its own file paths, requirements, and test expectations, so it runs cold. You paste
it into a fresh Claude session and let it build.

- `/standup` picks the ONE next thing. It enforces the rule: **no more than 2 plans in flight at
  once.** It's the only place a plan flips to `in-progress`. It also runs an **amnesty sweep**:
  recent commits and branches that match no plan or defect get flagged (`⊘ UNTRACKED`) with an
  offer to backfill a stub — no scolding, just a way back into the process.
- Every standup now renders a **board**: a compact table of *all* active plans (not just the two
  in flight) — status, slices done, next open slice, last touch, model/effort. It's terminal-only
  by default. Run `/standup --board` to also write it to `docs/BOARD.md` — a generated file,
  fully overwritten each run, safe to commit when you want a shareable snapshot of the backlog.
- Lost track of where something is? `/standup <feature>` traces that one term across ideas,
  notes, plans, defects, and branches, and tells you its lifecycle position plus the single next
  command to run.
- `/pjm` is a project-manager session you keep open for the day. It re-checks the state every
  turn (you move things between turns), runs the standup pick, puts the task string on your
  clipboard, and tells you which model/effort to run it at. It manages; it doesn't build.

### Worktrees: keeping parallel sessions out of each other's way

When `/pjm` sets up a branch for a slice, it offers a choice: check the branch out in place
(the usual way), or cut a **git worktree** — a separate copy of the repo in a sibling folder
named `<repo>-wt-<plan-id>`, on its own branch. It recommends the worktree when another session
is (or might be) working in the same repo, because two sessions sharing one working tree step on
each other's files. Otherwise the plain branch is fine — worktrees aren't mandatory. If you take
the worktree, the task string `/pjm` puts on your clipboard includes the folder path, so the
fresh session starts in the right place. When the slice is done, `/wrap-up` notices it ran in a
worktree and walks the close-out: commit the work, merge or PR it back from the main checkout,
then remove the worktree folder. A worktree you forgot about shows up in `/pjm`'s day-close
sweep — and one with uncommitted work gets flagged, never deleted.

---

## Stage 5 — Validate (`/wrap-up`)

When a slice of work is done, `/wrap-up` is the one command to run. It:
1. Confirms the slice is actually finished and marks it (a ` ✅` on the slice heading).
2. Captures what you learned — the gotchas, the decisions — into project memory.
3. Asks whether the finished work deserves a shipped doc (see **Documents** below) — and if
   the session changed code with no plan or defect behind it, offers a retroactive `/defect`
   or `/idea` so the work still leaves a trace.
4. Runs `/standup` to name the next thing.
5. Nudges `/audit-plans` only if the backlog looks messy.

`/verify` is the sharper tool underneath: it actually drives the feature end-to-end to confirm the
change works, not just that tests pass.

---

## Documents — which doc, and when

There are only two layers of documents, and the question "do I need a PRD here?" is already
answered: **you don't.** The lifecycle artifacts ARE the enterprise docs. Everything written
*before* the thing exists comes out of the five stages; everything written *after* is a
"shipped doc" with its own writer skill.

**Layer 1 — pre-build (the lifecycle owns these):**

| The enterprise doc | Our equivalent | Written by |
|---|---|---|
| PRD (what & why) | the idea file + its `Why:` | `/idea` |
| Decision record / ADR | reasoning note, workshop synthesis | `/reason` |
| TRD / work order | plan with `task:` + `Verify:` | `/promote` |
| Bug report | defect file | `/defect` |

Never create a standalone PRD or TRD. If you feel the urge, that's a sign the idea hasn't been
through `/reason` yet — the tier it assigns decides how much documentation the thinking gets.

**Layer 2 — shipped docs (post-build only):**

| Kind | For a reader who will… | Writer skill |
|---|---|---|
| spec / reference | execute against a contract (human or bot) | `/draft-spec` |
| tutorial, how-to, quickstart, brief, explanation | perform a task or understand a thing | `/draft-guide` |

Both writers share the same rules: no doc without a named reader, every claim verified against
source or the running service, and the same six-field front-matter so bots harvesting the repo
can trust what they read:

```yaml
doc-type: spec | tutorial | how-to | quickstart | brief | explanation
audience: <who reads this — never blank>
status: current | superseded-by: <path>
verified-against: <commit-sha or date>
repo: <repo name>
source: <plan/note paths>   # provenance, for regeneration
```

---

## Why the reason stage earns its place

Before, `/promote` did two jobs at once: it checked *whether the idea was any good* and it *wrote
the plan*. That meant "is this the right thing to build?" got answered in the same breath as "is
the plan well-formed?" — and the adversarial workshop was bolted on with no rule for when to use
it.

Splitting `reason` out fixes both. The workshop now has a clear trigger (the top tier of the
triage). And every idea gets a deliberate "how much should I think about this?" moment — cheap for
the easy ones, serious for the load-bearing ones. The requirement is always there; the cost scales
to the risk. That's the whole trick: **you can't skip reasoning, but reasoning an easy idea takes
five seconds.**

---

## Quick reference: the `reasoned:` stamp

The stamp lives in the idea's frontmatter and is what `/promote` reads:

| Stamp | Meaning | Can `/promote`? |
|---|---|---|
| *(none)* | Never reasoned. | No — run `/reason`. |
| `reasoned: clear` | Trivial, passed triage. | Yes. |
| `reasoned: notes/<slug>-reasoning.md` | Thought through (solo or post-workshop); decision is in the note. | Yes. |
| `reasoned: workshop-pending (design\|architecture\|both)` | Waiting on a workshop. | No — run the workshop, then re-run `/reason`. |
