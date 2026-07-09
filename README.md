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
                                 /pjm)
```

## Who this is for

Use this if you:

- work in several AI sessions and keep losing the thread between them;
- want more structure than "ask the agent, inspect the diff, repeat";
- need plans that survive across Codex, Claude Code, branches, and worktrees;
- want the AI to execute slices, not silently decide what project to start next;
- prefer lightweight Markdown artifacts in the repo over a separate project-management app.

Do not use this if you want one prompt to fully autonomously design, implement, commit, push, and
merge a feature. This workflow is optimized for checkpointed human control, not unattended
end-to-end automation.

## Install

The workflow itself is not Codex-specific. The same repo-native artifacts and handoff strings are
meant to work from Codex or Claude Code. The installer below targets Codex's local skill/command
layout; Claude Code users can use the same skill text from `skills/` and `commands/` in their
Claude Code skill/command setup.

```bash
git clone https://github.com/<you>/adhd-workflow.git
cd adhd-workflow
./install.sh
```

The script symlinks each skill into `${CODEX_HOME:-~/.codex}/skills/`, including `wrap-up`, so
the skills are available in **every** repo you open from Codex. It also installs legacy command
copies for surfaces that still load command prompts. This repo stays the source of truth — edit a
skill here and the change is live in your next compatible agent session. In Codex, start a new
session, then type `/idea` or explicitly invoke `$idea` in any project.

Use `--force` to replace files already at those paths (they get backed up to `<name>.bak`), and
`--uninstall` to remove the symlinks.

## The workflow triggers

| Stage | Trigger | What it does | Output |
|---|---|---|---|
| **Ideate** | `/idea` | Dumps a raw thought to disk and gets out of the way. | `docs/ideas/` |
| **Reason** | `/reason` | Decides whether the idea is sound and how much thinking it needs. | a stamp on the idea |
| **Plan** | `/promote` | Turns a reasoned idea into a runnable plan. Refuses vague ones. | `docs/plans/` |
| **Execute** | *(fresh session)* | Runs the plan's task strings and builds the thing. | code |
| **Validate** | `/wrap-up` / `$wrap-up` | Confirms it's done, captures what you learned, hands back to the driver. | plan status |

Plus the supporting cast:

- `/standup` — the daily driver. Names the ONE next action, enforces a limit of 2 things in
  flight at once, flags plans that have gone stale.
- `/pjm` — a project-manager session you keep open for a work block. It drives and tracks; it
  never builds. It hands you task strings to paste into fresh Codex or Claude Code sessions.
  `/pjm run-plan <plan>` can drive one plan slice-by-slice through checkpointed handoffs, but
  each slice still runs in a fresh execution session and must come back through `/wrap-up`
  before PJM continues to the next slice.
- `/design-workshop` — builds a prompt for a separate "critic" session that attacks a hard
  problem before you commit to it. `/reason` calls this when an idea needs it.
- `/audit-plans` — a weekly hygiene pass over the backlog.
- `/defect` and `/diagnose` — capture a bug, then root-cause it with evidence (two separate
  steps, on purpose).
- `/draft-spec` and `/draft-guide` — write the docs, *after* the thing exists.

Everything reads and writes the **current repo's** `docs/` directory. Nothing is global except
the skills themselves.

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

**Compared with autonomous multi-agent systems:** this is intentionally less automatic. `/pjm`
can drive a named plan slice-by-slice, but each slice still runs in a fresh execution session and
must come back through `/wrap-up`. Commits, pushes, branch pruning, plan archival, and status
changes require confirmation.

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

## Read more

- [`docs/adhd-workflow-guide.md`](docs/adhd-workflow-guide.md) — the plain-language walkthrough of
  all five stages. Start here.
- [`docs/plans/_done/adhd-project-workflow-system.md`](docs/plans/_done/adhd-project-workflow-system.md)
  — the design plan the system was built from.
- [`docs/notes/`](docs/notes/) — the decision notes behind specific choices.

This repo uses its own workflow on itself, so those directories double as a worked example of what
the output actually looks like.

## Contributing

Ideas and bug reports are welcome. If you want to change a skill, capture the idea with `/idea`
and run `/reason` on it first — the stamp it produces is a much better start to a discussion than
a pull request.

## License

MIT
