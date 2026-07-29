# The ADHD Workflow

A lightweight operating system for developers building with AI coding agents.

Most AI coding workflows make code generation faster. That is useful, but it creates a second
problem: decisions, plans, branch state, and half-finished work now move faster than your memory
can track. This repo provides portable workflow prompts/skills that turn AI-assisted development
into a repeatable loop: capture the idea, reason about it, promote it into a runnable plan,
delegate execution to fresh agent sessions, and reconcile the result before starting the next
slice.

It is deliberately boring infrastructure for agentic development. The workflow does not try to be
an autonomous engineering manager. It keeps the human in the driver seat, gives the agent a
well-formed task, and leaves evidence in the repo so tomorrow's session can recover the state.

```
ideate  →  reason  →  plan  →  execute  →  validate
 /idea     /reason   /promote   (fresh      /wrap-up
                                 sessions,
                                 driven by
                                 /pjm — or
                                 /run-plan)
```

## Who this is for

Use this if you:

- work in several AI sessions and keep losing the thread between them;
- want more structure than "ask the agent, inspect the diff, repeat";
- need plans that survive across Codex, Claude Code, branches, and worktrees;
- want the AI to execute slices, not silently decide what project to start next;
- prefer lightweight Markdown artifacts in the repo over a separate project-management app.

Do not use this if you want one prompt to fully autonomously design, implement, commit, push, and
merge a feature. The one unattended lane is `/run-plan`, and it only runs *inside* an
already-reasoned, already-promoted plan: it drives that plan's slices with no human between them,
but it never pushes, never merges, and halts at the first red instead of trying again.

## Install

The workflow itself is not Codex-specific. The same repo-native artifacts and handoff strings are
meant to work from Codex or Claude Code. The installer below targets Codex's local skill layout;
Claude Code users can use the same skill text from `skills/` in their Claude Code skill setup.

```bash
git clone https://github.com/<you>/adhd-workflow.git
cd adhd-workflow
./install.sh
```

The script symlinks each skill into `${CODEX_HOME:-~/.codex}/skills/`, including `wrap-up`, so
the skills are available in **every** repo you open from Codex. This repo stays the source of
truth — edit a skill here and the change is live in your next compatible agent session. In Codex,
start a new session, then type `/idea` or explicitly invoke `$idea` in any project.

Use `--force` to replace files already at those paths (they get backed up to `<name>.bak`), and
`--uninstall` to remove the symlinks.

Keep the clone where it is. `/run-plan` resolves `scripts/slice-gate.sh` by following its own
skill symlink back into this repo, so moving or deleting the clone leaves that skill without its
gate — and it refuses to run rather than falling back to judgment.

The installer also links everything in `output-styles/` into
`${CODEX_HOME:-~/.codex}/output-styles/`. Those are **Claude Code only** — output styles have no
Codex equivalent, so under Codex the directory is created and then ignored.

Claude Code reads output styles from its own config directory, so the default `CODEX_HOME` puts
them somewhere Claude Code will never look. Point `CODEX_HOME` at your Claude config directory
when you install:

```bash
CODEX_HOME=~/.claude ./install.sh
```

Then select the style with `/config` → Output style → `ADHD`, or set `"outputStyle": "ADHD"` in
`settings.json`. It shapes the prose around a skill's report, never the report format itself.

## The workflow triggers

| Stage | Trigger | What it does | Output |
|---|---|---|---|
| **Ideate** | `/idea` | Dumps a raw thought to disk and gets out of the way. | `docs/ideas/` |
| **Reason** | `/reason` | Decides whether the idea is sound and how much thinking it needs. | a stamp on the idea |
| **Plan** | `/promote` | Turns a reasoned idea into a runnable plan. Refuses vague ones. | `docs/plans/` |
| **Execute** | *(fresh session)* or `/run-plan` | Runs the plan's task strings and builds the thing — by hand-off, or slice-by-slice under a scripted gate. | code |
| **Validate** | `/wrap-up` / `$wrap-up` | Confirms it's done, captures what you learned, hands back to the driver. | plan status |

Plus the supporting cast:

- `/standup` — the daily driver. Names the ONE next action, enforces a limit of 2 things in
  flight at once, flags plans that have gone stale.
- `/pjm` — a project-manager session you keep open for a work block. It drives and tracks; it
  never builds. It hands you task strings to paste into fresh Codex or Claude Code sessions.
  `/pjm run-plan <plan>` can drive one plan slice-by-slice through checkpointed handoffs, but
  each slice still runs in a fresh execution session and must come back through `/wrap-up`
  before PJM continues to the next slice.
- `/run-plan <plan>` — the hands-off version of that loop, for when the handoffs are pure
  keystrokes. It drives a plan's open slices serially with no human between them. See below.
- `/design-workshop` — builds a prompt for a separate "critic" session that attacks a hard
  problem before you commit to it. `/reason` calls this when an idea needs it.
- `/audit-plans` — a weekly hygiene pass over the backlog.
- `/defect` and `/diagnose` — capture a bug, then root-cause it with evidence (two separate
  steps, on purpose).
- `/draft-spec` and `/draft-guide` — write the docs, *after* the thing exists.

By default everything reads and writes the **current repo's** `docs/` directory, and the skills
themselves are the only global piece. There is one optional exception:

if you keep your backlogs in one central git repo instead of per-repo `docs/`
directories, write that repo's absolute path (one line) to `~/.config/adhd-workflow/backlog-root`.
When `<backlog-root>/<repo-name>/` exists, the skills use it as the docs root for that repo —
`ideas/`, `plans/`, `defects/`, and `BOARD.md` live directly under it — and auto-commit-and-push
writes there. Reasoning notes always stay in the code repo's own `docs/notes/`. No config file,
no change: everything stays per-repo.

Model-sensitive handoffs are provider-qualified. A plan should name an OpenAI route, a Claude
route, and a recommended default between them for the surface you're using, for example Codex/OpenAI
`gpt-5.5 · high` or Claude Code `claude-opus-4-8 · high`.

## Running a plan unattended: `/run-plan`

`/pjm run-plan <plan>` stops between every slice to hand you a task string. When your answer at
that checkpoint is always "yes, next," the checkpoint is costing keystrokes and buying nothing.
`/run-plan <plan>` removes it: it drives every open slice of one plan, serially, in plan order,
with no human in between.

The session that drives the run is an **orchestrator**, not a reviewer. Per slice it spawns two
subagents — **A** gets only the slice's `Check:` text and writes the failing check; **B** gets only
the `Build:` text and implements until it passes. Neither one commits, reads the plan file, or runs
the gate. The orchestrator reads *nothing* either subagent says; each subagent's narrative goes to a
scratch dir outside the repo.

What it acts on instead is a script — `scripts/slice-gate.sh` — and its exit code. A slice earns
its ` ✅` only after five machine-observed facts, in order:

1. **Preflight red** — A's fresh check fails, and fails by assertion, not by failing to run.
2. **Agent B implements** — a separate session, given only the Build text.
3. **Postflight green** — the same check now passes.
4. **Whole-tree green** — the repo's own check command passes.
5. **Check untouched** — A's files are unchanged since A committed them, additions included.

The reasoning is in [`docs/notes/slice-gate-convention.md`](docs/notes/slice-gate-convention.md):
a prose gate is a suggestion made to something that wants to agree with you, so the gate is a
process exit code and no model sits in the decision path.

What that buys you, and what it costs:

- **It halts, it never retries.** Any red, any harness error, any missing check: stop, leave the
  tree exactly as it is, report the slice id, the failing command, its exit code, and the scratch
  paths. A flaky-looking red is still a red — retrying would be interpretation.
- **It refuses before slice 1, not at slice 4.** No whole-tree `> Check:` header, a red or
  unrunnable baseline, a dirty working tree, or an open slice with neither a `Check:`/`Build:`
  split nor a declared exemption — it names the offender and won't start.
- **A subagent can ask exactly one question, before it builds.** It writes the question to a file
  and exits 3; the run halts and prints the question verbatim. You answer by *editing the slice's
  task string* and re-invoking — so the answer lands where the next cold session reads it too.
- **Doc, example, and fixture slices run a weaker gate,** single-agent, witnessed only by the
  whole-tree check — and the stamp says `single-agent` so a reader three weeks later knows no
  independent check existed.
- **It commits, and it never pushes.** Two commits per two-agent slice (check, then build plus the
  stamped plan file) and one per single-agent slice, each tagged with the slice id. Resume reads
  `git log`, not the ` ✅` markers.
- **It ends by invoking `/wrap-up` itself** — once per run, not per slice — so the run finishes by
  handing you the reconciliation seat with the report already on screen.

Two requirements: the driving surface needs **real subagents** (Claude Code today, not Codex), and
the repo needs a whole-tree check command that can exit non-zero. A repo with no check has no
witness, and the gate refuses to run there.

## How this differs from other AI-centric workflows

**Compared with Brainstorm -> Spec -> Plan -> Ship flows:** this workflow agrees that vague
prompts should not go straight to code. The difference is where the structure lives. Brainstorm
first workflows usually produce a design/spec artifact, then move toward implementation. This repo
keeps the whole lifecycle in small repo-native files: ideas, reasoning notes, executable plans,
defects, wrap-up records, and archived completed plans. The goal is not only a better first spec;
it is recoverable state across many agent sessions.

**Compared with Refine/Plan/Act workflows:** this adds a hard reasoning gate before planning and a
hard wrap-up gate after execution. `/promote` refuses unreasoned or vague ideas. `/wrap-up`
reconciles slice status, captures knowledge, and returns control to `/pjm` instead of letting the
execution session drift into the next task.

**Compared with autonomous multi-agent systems:** the automation is narrow and the verification is
not a model. `/run-plan` will drive a whole plan unattended, but only a plan that already passed
`/reason` and `/promote`, only serially (parallel fan-out destroys the attribution that makes a
red meaningful), and only while a script keeps exiting 0. The driving session holds no opinion
about the work and never reads the diff. Pushes, merges, branch pruning, plan archival, and plan
status changes still require you.

**Compared with issue-tracker-first workflows:** the source of truth is the repo. Plans are
Markdown files with `task:` strings and `Verify:` clauses, not tickets that need a bot to
reinterpret them. That makes the workflow portable across tools and easy for a new agent session
to read cold.

## Design principles

- **Capture is cheap; commitment is expensive.** `/idea` writes a raw thought and stops.
  `/promote` refuses weak plans.
- **Reasoning scales to risk.** Obvious ideas get a quick stamp. Load-bearing ideas get a note or
  an adversarial workshop before planning.
- **Execution is delegated, not merged into planning.** Fresh sessions get one task string and a
  verification gate.
- **Green is an exit code, not an opinion.** The party that verifies a slice has no stake in it,
  and what it reads is a process exit status — never an agent's report that the work is done.
- **One next action.** `/standup` and `/pjm` avoid menus; the nearest finish line wins.
- **State lives in the repo.** `docs/ideas/`, `docs/notes/`, `docs/plans/`, and
  `docs/defects/` are the durable memory.
- **Provider routing is explicit.** Plans can carry both Codex/OpenAI and Claude Code routes plus
  the recommended default for the current surface.

## Adoption path

Start small:

1. Install the skills.
2. In an existing repo, capture one real idea with `/idea`.
3. Run `/reason <slug>`.
4. If it passes, run `/promote <slug>`.
5. Use `/standup` or `/pjm` to get exactly one executable task string.
6. Run the task in a fresh agent session.
7. Finish with `/wrap-up`.

After that loop feels natural, add `/pjm run-plan <plan>` for longer plans, `/defect` and
`/diagnose` for bugs, and `/audit-plans` as a weekly hygiene pass.

Reach for `/run-plan <plan>` once you notice you're approving every checkpoint without changing
anything — that's the signal the checkpoint is no longer earning its keep. Try it first on a plan
you'd be happy to `git reset --hard`.

## Read more

- [`docs/adhd-workflow-guide.md`](docs/adhd-workflow-guide.md) — the plain-language walkthrough of
  all five stages. Start here.
- [`docs/plans/_done/adhd-project-workflow-system.md`](docs/plans/_done/adhd-project-workflow-system.md)
  — the design plan the system was built from.
- [`docs/notes/slice-gate-convention.md`](docs/notes/slice-gate-convention.md) — what a
  machine-written ` ✅` is allowed to mean, and why the gate is a script.
- [`docs/notes/`](docs/notes/) — the decision notes behind specific choices.

This repo uses its own workflow on itself, so those directories double as a worked example of what
the output actually looks like.

## Contributing

Ideas and bug reports are welcome. If you want to change a skill, capture the idea with `/idea`
and run `/reason` on it first — the stamp it produces is a much better start to a discussion than
a pull request.

## License

MIT. `output-styles/adhd.md` is adapted from
[`ayghri/i-have-adhd`](https://github.com/ayghri/i-have-adhd) (MIT) — see [NOTICE.md](NOTICE.md).
