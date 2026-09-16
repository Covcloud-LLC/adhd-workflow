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
                                 /pjm — or a
                                 workflow run)
```

## Who this is for

Use this if you:

- work in several AI sessions and keep losing the thread between them;
- want more structure than "ask the agent, inspect the diff, repeat";
- need plans that survive across Codex, Claude Code, branches, and worktrees;
- want the AI to execute slices, not silently decide what project to start next;
- prefer lightweight Markdown artifacts in the repo over a separate project-management app.

Do not use this if you want one prompt to fully autonomously design, implement, commit, push, and
merge a feature. The one unattended lane is a **workflow run** — your agent tool's native
orchestration (in Claude Code, the Workflow tool) driving an already-reasoned, already-promoted
plan's slices with no human between them. The workflow repo supplies the gate it runs, not the
loop. It halts at the first red instead of trying again, and merging stays yours.

## The workflow triggers

| Stage | Trigger | What it does | Output |
|---|---|---|---|
| **Ideate** | `/idea` | Dumps a raw thought to disk and gets out of the way. | `docs/ideas/` |
| **Reason** | `/reason` | Decides whether the idea is sound and how much thinking it needs. | a stamp on the idea |
| **Plan** | `/promote` | Turns a reasoned idea into a runnable plan. Refuses vague ones. | `docs/plans/` |
| **Execute** | *(fresh session)* or "use a workflow" | Runs the plan's task strings and builds the thing — by hand-off, or slice-by-slice through native orchestration under a scripted gate. | code, PR |
| **Validate** | `/wrap-up` / `$wrap-up` | Confirms it's done, captures what you learned, hands back to the driver. | plan status |

Plus the supporting cast:

- `/standup` — the daily driver. Names the ONE next action, enforces a limit of 2 things in
  flight at once, flags plans that have gone stale.
- `/pjm` — a project-manager session you keep open for a work block. It drives and tracks; it
  never builds. It hands you task strings to paste into fresh Codex or Claude Code sessions.
- `/ship` — commit, push, open a pull request, stop. It branches first if you're on the default
  branch, runs the repo's own check before committing, and never merges. Usable on its own for
  hand-written work, or after a workflow run finishes.
- `/design-workshop` — builds a prompt for a separate "critic" session that attacks a hard
  problem before you commit to it. `/reason` calls this when an idea needs it.
- `/audit-plans` — a weekly hygiene pass over the backlog.
- `/defect` and `/diagnose` — capture a bug, then root-cause it with evidence (two separate
  steps, on purpose).
- `/draft-spec` and `/draft-guide` — write the docs, *after* the thing exists.

By default everything reads and writes the **current repo's** `docs/` directory, and the skills
themselves are the only global piece. There is one optional exception: if you keep your backlogs
in one central git repo instead of per-repo `docs/` directories, write that repo's absolute path
(one line) to `~/.config/adhd-workflow/backlog-root`.
When `<backlog-root>/<repo-name>/` exists, the skills use it as the docs root for that repo —
`ideas/`, `plans/`, `defects/`, and `BOARD.md` live directly under it — and auto-commit-and-push
writes there. Lifecycle reasoning notes (the `*-reasoning.md` files `/reason` writes) follow the
docs root into `<backlog-root>/<repo-name>/notes/`; durable design, decision, and reference docs
stay in the code repo's own `docs/notes/`. No config file, no change: everything stays per-repo.

Model-sensitive handoffs are provider-qualified. A plan should name an OpenAI route, a Claude
route, and a recommended default between them for the surface you're using, for example Codex/OpenAI
`gpt-5.5 · high` or Claude Code `claude-opus-4-8 · high`.

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
not a model. A workflow run will drive a whole plan unattended, but only a plan that already
passed `/reason` and `/promote`, only serially for gated slices (parallel fan-out destroys the
attribution that makes a red meaningful), and only while the slice gate keeps exiting 0. The loop
itself is code the agent harness executes, not prose a model tries to follow. Pushing, merges,
branch pruning, plan archival, and plan status changes still require you.

**Compared with issue-tracker-first workflows:** the source of truth is the repo. Plans are
Markdown files with `task:` strings and `Verify:` clauses, not tickets that need a bot to
reinterpret them. That makes the workflow portable across tools and easy for a new agent session
to read cold.

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

Keep the clone where it is. A workflow run finds `scripts/slice-gate.sh` by following an
installed skill's symlink back into this repo, so moving or deleting the clone leaves runs
without their gate.

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

## Adoption path

Start small:

1. Install the skills.
2. In an existing repo, capture one real idea with `/idea`.
3. Run `/reason <slug>`.
4. If it passes, run `/promote <slug>`.
5. Use `/standup` or `/pjm` to get exactly one executable task string.
6. Run the task in a fresh agent session.
7. Finish with `/wrap-up`.

After that loop feels natural, add a workflow run for longer plans, `/defect` and `/diagnose`
for bugs, and `/audit-plans` as a weekly hygiene pass.

Reach for a workflow run once you notice you're approving every checkpoint without changing
anything — that's the signal the checkpoint is no longer earning its keep. Try it first on a plan
you'd be happy to `git reset --hard`.

## Running a plan unattended: native orchestration

Handing off one task string at a time and waiting for you to say "yes, next" at every slice is
fine for one slice. For a whole plan it's pure keystroke tax once your answer never changes. This
repo doesn't ship its own runner for that. Use your agent tool's native orchestration:

1. **Claude Code — the Workflow tool.** Say "use a workflow to run plan `<plan>`". The session
   writes a Workflow script from the plan's `### <id>` slices and their `task:` strings. The
   harness executes that script as code, so the loop — slice order, halt on red, never retry —
   doesn't drift the way a model following prose does. Resume a halted run by its run ID.
2. **Codex — its native subagent feature**, where your Codex build has one.
3. **Anywhere else — paste task strings** into fresh sessions, one slice at a time, with `/pjm` or
   `/standup` handing you the next one.

What this repo supplies is the **slice gate**: `scripts/slice-gate.sh` and its contract in
[`docs/notes/slice-gate-convention.md`](docs/notes/slice-gate-convention.md). Per gated slice, agent
**A** writes the failing check from the slice's `Check:` text, agent **B** implements from the
`Build:` text, and a separate verify agent runs the gate and returns its exit code for the script
to branch on. A slice earns its ` ✅` only after five facts, in order:

1. **Preflight red** — A's fresh check fails, and fails by assertion, not by failing to run.
2. **Agent B implements** — a separate agent, given only the Build text.
3. **Postflight green** — the same check now passes.
4. **Whole-tree green** — the repo's own check command passes.
5. **Check untouched** — A's files are unchanged since A committed them, additions included.

A prose gate is a suggestion made to something that wants to agree with you, so the gate is a
process exit code. Doc, example, and fixture slices that name an exemption run a weaker lane,
witnessed only by the whole-tree check, and their stamp says `single-agent`. Gated slices of one
plan run one at a time in one tree: a whole-tree check only blames the slice that broke it when
nothing else changed at the same time.

When the run finishes, the rest is yours: `/ship` to push and open a PR, then a quality pass —
`/simplify <first-slice-sha>^..HEAD`, re-run the plan's `> Check:` command, then `/code-review`
(simplify rewrites and review reads, so review last). Then `/wrap-up`.

The repo needs a whole-tree check command that can exit non-zero. A repo with no check has no
witness, and the gate refuses to run there.

## Design principles

- **Capture is cheap; commitment is expensive.** `/idea` writes a raw thought and stops.
  `/promote` refuses weak plans.
- **Reasoning scales to risk.** Obvious ideas get a quick stamp. Load-bearing ideas get a note or
  an adversarial workshop before planning.
- **Execution is delegated, not merged into planning.** Fresh sessions get one task string and a
  verification gate.
- **Green is an exit code, not an opinion.** The party that verifies a slice has no stake in it,
  and what it reports is a process exit status — never an agent's claim that the work is done.
- **One next action.** `/standup` and `/pjm` avoid menus; the nearest finish line wins.
- **State lives in the repo.** `docs/ideas/`, `docs/notes/`, `docs/plans/`, and
  `docs/defects/` are the durable memory.
- **Provider routing is explicit.** Plans can carry both Codex/OpenAI and Claude Code routes plus
  the recommended default for the current surface.

## Read more

- [`docs/adhd-workflow-guide.md`](docs/adhd-workflow-guide.md) — the plain-language walkthrough of
  all five stages. Start here.
- The design plan the system was built from (`adhd-project-workflow-system.md`) is archived in the
  author's private backlog repo, not here — the notes below carry the decisions that matter.
- [`docs/notes/slice-gate-convention.md`](docs/notes/slice-gate-convention.md) — what a
  machine-written ` ✅` is allowed to mean, and why the gate is a script.
- [`docs/notes/`](docs/notes/) — the decision notes behind specific choices.

This repo uses its own workflow on itself, so `docs/notes/` doubles as a worked example of what the
reasoning output actually looks like. Its ideas, plans, and defects live in a separate private
backlog repo, so they aren't visible here.

## Contributing

Ideas and bug reports are welcome. If you want to change a skill, capture the idea with `/idea`
and run `/reason` on it first — the stamp it produces is a much better start to a discussion than
a pull request.

## License

MIT. `output-styles/adhd.md` is adapted from
[`ayghri/i-have-adhd`](https://github.com/ayghri/i-have-adhd) (MIT) — see [NOTICE.md](NOTICE.md).
