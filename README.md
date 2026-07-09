# The ADHD Workflow

A set of Codex skills that take an idea from "I just thought of this" to "it's shipped"
without it getting lost or half-built along the way.

It is built for the way a lot of us actually work: lots of ideas, easy to start things, hard to
finish them. Every command in it either **lowers the friction of capturing** an idea or **raises
the bar for committing** to one. That trade is the whole design.

If you are learning to code with an AI assistant, the hard part usually isn't getting code
written — it's keeping track of what you decided, what's half-done, and what to do next. This is
a system for that.

```
ideate  →  reason  →  plan  →  execute  →  validate
 /idea     /reason   /promote   (fresh      /wrap-up
                                 sessions,
                                 driven by
                                 /pjm)
```

## Install

Requires Codex.

```bash
git clone https://github.com/<you>/adhd-workflow.git
cd adhd-workflow
./install.sh
```

The script symlinks each skill into `${CODEX_HOME:-~/.codex}/skills/` and `/wrap-up` into `${CODEX_HOME:-~/.codex}/commands/`,
so the skills are available in **every** repo you open. This repo stays the source of truth — edit
a skill here and the change is live in your next session. Start a new Codex session, then
type `/idea` in any project.

Use `--force` to replace files already at those paths (they get backed up to `<name>.bak`), and
`--uninstall` to remove the symlinks.

## The commands

| Stage | Command | What it does | Output |
|---|---|---|---|
| **Ideate** | `/idea` | Dumps a raw thought to disk and gets out of the way. | `docs/ideas/` |
| **Reason** | `/reason` | Decides whether the idea is sound and how much thinking it needs. | a stamp on the idea |
| **Plan** | `/promote` | Turns a reasoned idea into a runnable plan. Refuses vague ones. | `docs/plans/` |
| **Execute** | *(fresh session)* | Runs the plan's task strings and builds the thing. | code |
| **Validate** | `/wrap-up` | Confirms it's done, captures what you learned, picks the next thing. | plan status |

Plus the supporting cast:

- `/standup` — the daily driver. Names the ONE next action, enforces a limit of 2 things in
  flight at once, flags plans that have gone stale.
- `/pjm` — a project-manager session you keep open for a work block. It drives and tracks; it
  never builds. It hands you task strings to paste into fresh sessions.
- `/design-workshop` — builds a prompt for a separate "critic" session that attacks a hard
  problem before you commit to it. `/reason` calls this when an idea needs it.
- `/audit-plans` — a weekly hygiene pass over the backlog.
- `/defect` and `/diagnose` — capture a bug, then root-cause it with evidence (two separate
  steps, on purpose).
- `/draft-spec` and `/draft-guide` — write the docs, *after* the thing exists.

Everything reads and writes the **current repo's** `docs/` directory. Nothing is global except
the skills themselves.

## The one idea worth stealing

`/reason` sits between capture and planning, and it's the piece that makes the rest work. It asks
one question of every idea — *how much thinking does this need before I'd trust a plan for it?* —
and sorts it into three tiers based on how much design freedom there is, how hard it is to undo,
and how much blows up if you're wrong.

A trivial idea gets a one-line stamp and passes through in five seconds. A load-bearing one earns
a written decision note, or gets refused outright until you've run an adversarial workshop on it.
The requirement is always there; the cost scales to the risk.

**You can't skip reasoning, but reasoning an easy idea takes five seconds.**

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
