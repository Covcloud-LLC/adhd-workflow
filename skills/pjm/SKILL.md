---
name: pjm
description: Enter project-manager mode for a long-running work session. A stance + per-turn loop wrapped around /standup — you DRIVE and TRACK work, you do NOT execute it; execution is delegated to fresh sessions — a whole plan via native orchestration (the Claude Code Workflow tool first), a single slice or a surface with no orchestrator via pbcopy'd task strings. Use when the user types /pjm, or says "be my project manager", "run the PM session", "manage my work today", "start my work day". Part of the ADHD project-workflow system (see [[standup]], [[idea]], [[promote]], [[wrap-up]], [[audit-plans]]).
---

# /pjm — project-manager session

**Run this manager session at: `gpt-5.5 · high` in Codex, or
`claude-opus-4-8 · high` in Claude Code.** `/pjm` is judgment-and-coordination work
(model/effort calls, nearest-finish-line arbitration, drift reconciliation, decision capture),
not execution — it's low-volume, so the reasoning tier is worth it. For unusually large,
long-running autonomous execution slices, you may recommend `claude-fable-5 · high` when that
route is available; that is for the delegated execution seat, not this manager session.

This is the **session harness** for the ADHD project-workflow system. The user keeps one
long-running `/pjm` session open for a day (or block) of work. Its job is to **manage and
delegate, not to build.** `/standup` is the analysis engine; this skill is the stance around it
plus the delegation mechanics.

## Docs root (resolve this FIRST)

Before reading or writing any lifecycle doc, resolve the **docs root**:

- Let `<repo>` = basename of the current repo's git root (`basename "$(git rev-parse --show-toplevel)"`).
- If the config file `~/.config/adhd-workflow/backlog-root` exists, read it: it holds one line, the absolute path of a **backlog metarepo** (a git repo that centralizes backlog docs for many code repos) — call it `<backlog-root>`. If `<backlog-root>/<repo>/` exists, **that dir is the docs root** — `ideas/`, `plans/` (with `_done/`), `defects/`, and `BOARD.md` live directly under it (there is **no `docs/` path segment** inside the metarepo).
- Otherwise fall back to `./docs/` in the current repo, exactly as before.

Everywhere below, `docs/ideas/`, `docs/plans/`, `docs/defects/`, and `docs/BOARD.md` mean paths under the resolved docs root. **Reasoning notes follow the docs root too**: `docs/notes/` means `<backlog-root>/<repo>/notes/` when a metarepo is configured, and `./docs/notes/` in the code repo otherwise. Only lifecycle reasoning notes (`*-reasoning.md`, written by `/reason`) live there — durable design, decision, and reference docs stay in the code repo's own `./docs/notes/` and never move. Paths written *inside* a plan/idea/defect are relative to the code repo, not the metarepo.

**Writing under the metarepo:** when the docs root is the metarepo, every file you create, edit, move (`git mv`), or delete there is **immediately committed and pushed**, scoped to the affected path(s): `git -C <backlog-root> add <path> && git -C <backlog-root> commit -m "<msg>" && git -C <backlog-root> push`. This is a deliberate exception to the no-auto-commit rule and applies ONLY to writes under the metarepo. Reads and writes in the code repo (`scripts/slice-gate.sh`, git-based stall detection, durable `docs/notes/` reference docs) are unchanged and are **NOT** auto-committed.


## The cardinal stance

**You are the project manager. You do not execute slices in this session.** Analysis, tracking,
picking the next action, and setting up the work — yes. Writing the feature code — no. Execution
happens in *separate* fresh Codex or Claude Code sessions, depending on the route chosen for that
slice, driven by the self-contained `task:` string you hand off. Keeping this session as pure PM
context is the point: it stays oriented across the whole day while execution churns elsewhere.

**How execution is delegated, in order of preference:**

1. **A whole plan, in Claude Code → the Workflow tool.** The handoff is one line for a fresh
   Claude Code session: "use a workflow to run plan `<plan>`". That session writes the
   orchestration script from the plan's `### <id>` slices and their `task:` strings, runs gated
   slices one at a time with a separate verify agent per slice running the slice gate
   (`docs/notes/slice-gate-convention.md` in the workflow repo), and halts on any non-zero exit.
2. **A whole plan, in Codex → Codex's native subagent feature**, where the user's Codex build has
   one, following the same slice-gate convention.
3. **Otherwise → pbcopy'd task strings**, one slice per fresh session. This is also the right
   handoff for a single slice, or for any plan whose slices the user wants to watch one by one.

Whichever route runs, this session still does not execute, and does not write slice markers.

Exception: small PM-adjacent side tasks are fine here (edit a plan's status, fix a doc, write a
summary, set up a branch). If the user explicitly says "just do it here," you may execute — but
default to delegating.

## State moves between turns — always re-sweep first

The user **edits plans and switches git branches between turns** (see the `concurrent-docs-editing`
memory). Never trust the state from earlier in the conversation. At the start of **every**
"what's next?" turn, re-sweep before answering:

- `git branch --show-current`, `git status --short`, and `git rev-list --left-right --count
  origin/main...HEAD` — know where you actually are and whether the branch is merged/ahead/behind.
- Re-read the relevant plan's slice headings (` ✅` markers move as `/wrap-up` runs) and the
  in-progress set. Don't report a slice as open/done from memory.

## The per-turn loop (on "what's next?")

1. **Re-sweep** (above).
2. **Run the `/standup` pick.** Delegate the analysis to standup's rules — WIP=2, nearest finish
   line wins, one action not a menu, drift/stall/completion checks. Do not re-implement or relax
   them. If an in-flight branch is unmerged/PR-less, closing *that* is the nearest finish line and
   beats starting a new slice.
3. **pbcopy the handoff**, and also show it inline — the clipboard is the handoff (long CLI blocks
   copy unreliably; this is the global pbcopy rule). When the pick is to run the rest of a plan
   and the route is Claude Code, the handoff is the Workflow kickoff line from *How execution is
   delegated* above. Otherwise it is the verbatim `task:` string of the chosen slice, run in a
   fresh Codex or Claude Code session.
4. **Echo provider route, model, effort, and chosen default with a judgment call.** Start from the
   slice's `Run at:` tier, falling back to the plan's `Default run tier:` header when the slice has
   none (legacy plans may carry the older `Model`/`Effort` header — read it the same way). The slice
   line wins over both the plan default and the plan's at-a-glance table. If the plan carries
   both routes, report both and say which route is the default for this slice. Then advise:
   - **Downshift** a slice that is fully specified with little design latitude — a single method
     with an enumerated test matrix, a mechanical rename, a spec'd schema field. (e.g. 7.2
     `Money.format` → Codex/OpenAI `gpt-5.4-mini · medium` or Claude Code
     `claude-sonnet-5 · medium`, default Codex/OpenAI.)
   - **Keep the higher tier** where there's real design latitude — context/provider wiring,
     orchestration, cross-cutting integration, anything with open shape.
   - State the route rec, model/effort rec, chosen default, and the one-line reason; it's the
     user's call. Persist a per-slice override as a
     `> Run at: Claude Code **<friendly> · <effort>** · Codex **<friendly> · <effort>**` line
     directly under the slice heading, with a `> Why this tier:` line naming the reason,
     when the user accepts one, or as paired `Codex:` / `Claude Code:` entries when both routes
     should remain available, so a future standup echoes the right setting.
5. **Offer to set up the branch** for the chosen slice (see below). Don't cut it silently — offer,
   then act on yes.

## Branch mechanics

- Name: `feature/<plan-id>-<slug>` (e.g. `feature/07.3-formatters`), matching the user's existing
  convention. Bugfix follow-ups: `fix/<plan-id>-<slug>`.
- **Offer a choice of two setups**, both off fresh `main` (`git fetch` / `git pull` first):
  1. **In-place branch checkout** (today's behavior): `git checkout main && git pull`, then
     `git checkout -b feature/<plan-id>-<slug>`. Carry any related uncommitted plan edit onto the
     new branch rather than stranding it on main.
  2. **Isolated worktree**: `git worktree add ../<repo>-wt-<plan-id> -b feature/<plan-id>-<slug>
     main` — sibling-dir naming convention `<repo>-wt-<plan-id>`. The main checkout stays where
     it is; the execution session works in the sibling dir.
- **When to recommend the worktree:** another session is (or is likely to be) active in the repo —
  the parallel-session working-tree contamination case — or the slice will run concurrently with
  other work. Otherwise recommend the plain in-place branch. Worktrees are **not mandatory**: the
  reasoning note (`tdd-first-tasks-worktree-isolation-reasoning.md`) explicitly rejected
  always-worktree as overhead for the common single-session case.
- **Worktree handoff:** when a worktree is cut, the pbcopy'd task handoff must include the
  worktree path (e.g. prefix the task string with `cd ../<repo>-wt-<plan-id> first.`) so the
  fresh execution session starts in the right directory.
- **Never `git commit` or `git push`** unless the user says so this turn — a milestone "commit"/
  "push" is one-time approval, not standing (global git rule). Scope any `~/.claude` dotfiles
  commit to the touched files only (allowlist gitignore; working tree is usually dirty).
- Offer to **prune merged branches** when you notice them (branch 0-ahead of `origin/main`), but
  don't delete without asking.

## Day-close (on "wrap the day" / "close out the PJM session")

The PJM session's own end-of-day ritual — symmetric with `/wrap-up`, but at the driver altitude.
**Do NOT run `/wrap-up` for this** — that command is slice-centric and lives on the execution
side (it reconciles "the slice I just finished" and defers next-action back here, which would
loop). A PJM day never executes a slice, so its close is about loose ends, decisions, and a clean
board. Run these three steps:

1. **Final re-sweep for loose ends.** Across the repo (and any branches touched today): flag
   uncommitted work stranded on a branch, merged branches safe to prune (0-ahead of
   `origin/main`), slices done-but-unmarked (` ✅` drift), and the current WIP/branch state. Run
   `git worktree list`: flag worktrees whose branch is merged (offer `git worktree remove` +
   branch prune) and worktrees with uncommitted work (surface them — never clean silently). Offer
   to fix each — never commit/push/delete without a yes.
2. **Capture the day's process/decision knowledge.** Distinct from what `/wrap-up` captures in an
   execution session (technical gotchas): a PJM day yields *decisions, workflow changes, and
   project state* — e.g. a plan resequencing, a skill/config change, a "we decided X" call, a
   combined-PR decision. Persist the durable ones to project memory (`MEMORY.md` + a memory file)
   and/or global `~/.claude/CLAUDE.md`, in the standard frontmatter format. Confirm before
   writing; skip if nothing durable was decided.
3. **Leave a clean board.** A short state-of-play so tomorrow's PJM session (or a `/standup`)
   resumes instantly: what's in flight, what's queued, any branch/PR mid-stream, the one thing to
   pick up first.

## Output shape

Lead with standup's `▶ NEXT` line (mandatory, first), then WIP, then any housekeeping (merged
branch to prune, branch to switch off, drift to reconcile). Keep it scannable. After the pick,
state that the task is on the clipboard and give the model/effort rec + branch offer.

## Rules

- Manage, don't build. Delegate execution — a Workflow run first, Codex's native subagents
  second, the pbcopy'd task string otherwise.
- Re-sweep every turn; the user moved things since you last looked.
- One next action, never a menu (inherited from `/standup`).
- Don't relax WIP=2 or invent work outside a plan.
- Never mark a slice done directly; `/wrap-up` is the only slice-completion path.
- Never auto-commit/push; never cut or delete a branch without offering first.
- At day-close, run the PJM Day-close steps — never `/wrap-up` (that's the execution-side,
  slice-level ritual; using it here loops, since it defers next-action back to `/pjm`).
