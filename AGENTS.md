# AGENTS.md

Guidance for Codex when working in this repository.

## What this repo is

The ADHD workflow: a set of Codex **skills** that carry an idea through
five stages — `ideate → reason → plan → execute → validate` — via `/idea`, `/reason`, `/promote`,
fresh execution sessions, and `/wrap-up`. It is published for other people to install. The
installed package is Codex-native, but live workflow prose should make execution handoffs portable
between Codex/OpenAI and Claude Code when both routes are relevant.

The "product" is the prose inside `skills/*/SKILL.md`. The repo also carries one piece of real
code: the **slice gate** (`scripts/slice-gate.sh`), the machine witness `/run-plan` uses to mark
slices done, with its test suite in `tests/gate_test.sh`. There is still no build; the whole-tree
check is `bash scripts/check.sh`.

```
skills/<name>/SKILL.md   the 13 skills — this is the product
install.sh               symlinks skills into ~/.codex
scripts/slice-gate.sh    the slice gate — see docs/notes/slice-gate-convention.md
scripts/check.sh         the whole-tree check: shell syntax + the gate's tests
tests/gate_test.sh       the gate's test suite (bash tests/gate_test.sh)
docs/                    this repo's own notes (see "Dogfooding")
```

## The critical gotcha: edits here are live

`install.sh` **symlinks** `skills/<name>` into `${CODEX_HOME:-~/.codex}/skills/<name>`. The user's own daily
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

- The **`description` is the dispatch mechanism.** Codex reads it to decide whether to
  invoke the skill, so it must name the trigger phrases explicitly. A vague description makes a
  skill that never fires.
- Skills reference each other with `[[name]]` wiki-links inside the description and body.
- A skill's final report ends with **one breadcrumb line** naming the next command in the
  lifecycle — `/idea` closes with "when ready: `/reason <slug>`". Preserve that when editing; it's
  what keeps the chain walkable, and it's why the skills end without a summary or a "would you
  like me to…".
- The skills address the user's ADHD directly and are deliberately blunt about it (`/promote`
  "refusing is a success, not a failure"). Keep that voice. It is load-bearing, not decoration.

Skills read and write the **current repo's** `docs/` directory by default — never a hardcoded
absolute path. The one sanctioned indirection is the optional **backlog metarepo**: when
`~/.config/adhd-workflow/backlog-root` names a metarepo and it has a dir for the current repo,
the lifecycle skills resolve their docs root there instead (see any skill's "Docs root"
section; lifecycle reasoning notes follow the docs root, but durable design/decision/reference
docs in `docs/notes/` stay in the code repo). Beyond that, the only global thing is
the skill file itself.

## Shared conventions the skills depend on

Changing any of these means changing several skills at once:

| Convention | Meaning | Written by | Read by |
|---|---|---|---|
| `reasoned:` frontmatter stamp on an idea | passed the reasoning gate | `/reason` | `/promote` |
| trailing ` ✅` on a `### <id>` slice heading | that slice is done | `/wrap-up` | `/standup` |
| `> Default run tier:` header on a plan | both provider routes + effort, for slices with no override | `/promote` | `/standup`, `/pjm`, `/audit-plans`, `/run-plan` |
| `> Run at:` line on a slice | the tier that slice runs at; always beats the plan default | `/promote` | `/standup`, `/run-plan` |
| WIP cap of 2 `in-progress` plans | the finish-what-you-start rule | — | `/standup` (the only place a plan goes `in-progress`) |
| `docs/plans/_done/` | completed plans are archived, never deleted | `/wrap-up` | `/audit-plans` |
| the slice gate — `scripts/slice-gate.sh` | the five machine facts behind a machine-written ` ✅`; see `docs/notes/slice-gate-convention.md` | orchestrator only (never a subagent) | `/run-plan`, `/wrap-up` |
| `## What this plan will actually do` + `## Decisions this plan makes` sections, read back before write | the plan's brief and the decisions the decomposition added | `/promote` | `/audit-plans` (flag + drift spot-check), `/run-plan` (launch echo) |

The legacy four-line `Model:`/`OpenAI:`/`Claude:`/`Recommended:` header is **readable but
deprecated** — `/promote` must never emit it, and `/audit-plans` flags it for migration.

`docs/plans/` is **task-tracked work only.** Durable design, decision, and reference docs stay in
the code repo's `docs/notes/` and never move. Lifecycle reasoning notes (`*-reasoning.md`, written
by `/reason`) are different: they are not durable docs, so they resolve under the docs root like
plans and ideas — the metarepo's `notes/` when one is configured, `./docs/notes/` otherwise.

## Dogfooding

This repo uses its own workflow on itself, but its lifecycle docs are **not** in this repo. The
maintainer's `~/.config/adhd-workflow/backlog-root` points at a backlog metarepo with a dir for
this repo, so the skills resolve the docs root there: `ideas/`, `plans/` (with `_done/`),
`defects/`, and lifecycle reasoning notes (`notes/`) live in that metarepo. Only durable
design/decision/reference docs stay in this repo's `docs/notes/`, and that folder doubles as the
worked example readers learn from — so it should stay well-formed.

The nine reasoning notes that existed before this convention were not bulk-migrated. Eight of them
stay in this repo's `docs/notes/` alongside `slice-gate-convention.md`; the ninth — this plan's own
reasoning note — moved to the metarepo as the first live example.

Consequence: if you are looking for a plan, idea, or reasoning note for this repo and it isn't
under `docs/`, that is expected, not a missing file. Resolve the docs root the way the skills do (read
`~/.config/adhd-workflow/backlog-root`, then look for `<backlog-root>/adhd-workflow/`) instead of
assuming a path.

To change a skill, capture the idea with `/idea` and run `/reason` on it first, rather than
editing the skill directly. The one exception is a typo or broken link.

When editing current live workflow behavior, make the surface explicit: Codex/OpenAI route, Claude
Code route, and the recommended default between them. Don't mechanically replace every "Claude
session" with "Codex session"; if a passage is describing the Claude Code path, say that.

Some archived plans in that metarepo describe editing paths under `~/.codex/…` directly. That is
historical: the skills lived in a dotfiles repo before this one. Don't "fix" those paths — they're
a record of what was done at the time.

## Verifying a change

The whole-tree check is `bash scripts/check.sh` — it syntax-checks the shell scripts and runs the
gate's test suite (`bash tests/gate_test.sh`). Run it after touching anything under `scripts/` or
`tests/`.

For `install.sh`, test against a throwaway config dir rather than the real `~/.codex` (the
installer reads `CODEX_HOME`):

```bash
bash -n install.sh                        # syntax
CODEX_HOME=$(mktemp -d) ./install.sh      # link into a sandbox
```

Exercise the paths that matter: a clean install, an idempotent re-run, a conflicting existing
file (skips), `--force` (backs up to `.bak`), and `--uninstall` (must leave symlinks pointing
elsewhere alone).

For a skill change, there's nothing to run. Verify by reading it back and walking the skill's own
steps against this repo's `docs/`.
