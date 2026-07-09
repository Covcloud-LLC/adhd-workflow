# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this repo is

The ADHD workflow: a set of Claude Code **skills** (plus one command) that carry an idea through
five stages — `ideate → reason → plan → execute → validate` — via `/idea`, `/reason`, `/promote`,
fresh execution sessions, and `/wrap-up`. It is published for other people to install.

There is **no application code, no build, and no test suite.** Every artifact is markdown. The
"product" is the prose inside `skills/*/SKILL.md`.

```
skills/<name>/SKILL.md   the 11 skills — this is the product
commands/wrap-up.md      the one slash command that isn't a skill
install.sh               symlinks skills + commands into ~/.claude
docs/                    this repo's own ideas/notes/plans (see "Dogfooding")
```

## The critical gotcha: edits here are live

`install.sh` **symlinks** `skills/<name>` into `~/.claude/skills/<name>`. The user's own daily
workflow, in every repo they open, runs from these files. There is no build step and no staging
copy — editing a skill here changes the user's next session.

So: treat a skill edit like a production change. Read the whole `SKILL.md` before editing it, and
never make a speculative edit "to see what happens."

## Working on a skill

Each skill is a single `SKILL.md` with YAML frontmatter:

```yaml
---
name: promote
description: <what it does> Use when the user types /promote, or says "…", "…". Part of the ADHD project-workflow system (see [[idea]], [[reason]]).
---
```

- The **`description` is the dispatch mechanism.** Claude Code reads it to decide whether to
  invoke the skill, so it must name the trigger phrases explicitly. A vague description makes a
  skill that never fires.
- Skills reference each other with `[[name]]` wiki-links inside the description and body.
- A skill's final report ends with **one breadcrumb line** naming the next command in the
  lifecycle — `/idea` closes with "when ready: `/reason <slug>`". Preserve that when editing; it's
  what keeps the chain walkable, and it's why the skills end without a summary or a "would you
  like me to…".
- The skills address the user's ADHD directly and are deliberately blunt about it (`/promote`
  "refusing is a success, not a failure"). Keep that voice. It is load-bearing, not decoration.

Skills always read and write the **current repo's** `docs/` directory — never a global path and
never a hardcoded absolute path. The only global thing is the skill file itself.

## Shared conventions the skills depend on

Changing any of these means changing several skills at once:

| Convention | Meaning | Written by | Read by |
|---|---|---|---|
| `reasoned:` frontmatter stamp on an idea | passed the reasoning gate | `/reason` | `/promote` |
| trailing ` ✅` on a `### <id>` slice heading | that slice is done | `/wrap-up` | `/standup` |
| `Model` + `Effort` header on a plan | what tier to execute it at | `/promote` | `/standup`, `/audit-plans` |
| WIP cap of 2 `in-progress` plans | the finish-what-you-start rule | — | `/standup` (the only place a plan goes `in-progress`) |
| `docs/plans/_done/` | completed plans are archived, never deleted | `/wrap-up` | `/audit-plans` |

`docs/plans/` is **task-tracked work only.** Design, decision, and reference docs go in
`docs/notes/`.

## Dogfooding

This repo uses its own workflow on itself. `docs/ideas/`, `docs/notes/`, and `docs/plans/_done/`
hold real artifacts, and they double as the worked example readers learn from — so they should
stay well-formed.

To change a skill, capture the idea with `/idea` and run `/reason` on it first, rather than
editing the skill directly. The one exception is a typo or broken link.

Note that the archived plans in `docs/plans/_done/` describe editing paths under `~/.claude/…`.
That is historical: the skills lived in a dotfiles repo before this one. Don't "fix" those paths —
they're a record of what was done at the time.

## Verifying a change

The only executable thing here is `install.sh`. Test it against a throwaway config dir rather than
the real `~/.claude`:

```bash
bash -n install.sh                                # syntax
CLAUDE_CONFIG_DIR=$(mktemp -d) ./install.sh       # link into a sandbox
```

Exercise the paths that matter: a clean install, an idempotent re-run, a conflicting existing
file (skips), `--force` (backs up to `.bak`), and `--uninstall` (must leave symlinks pointing
elsewhere alone).

For a skill change, there's nothing to run. Verify by reading it back and walking the skill's own
steps against this repo's `docs/`.
