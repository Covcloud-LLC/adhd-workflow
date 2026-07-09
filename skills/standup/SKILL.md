---
name: standup
description: The daily ADHD driver. Reviews plans in the current repo, enforces the WIP=2 limit, flags stalled/drifted plans via git, sweeps for untracked work and open defects, archives completed ones, and ends by naming ONE next action. With an argument (/standup <feature-or-plan>) it instead traces that item across ideas/notes/plans/defects/branches and reports its lifecycle position + the single next command without starting or advancing it. Use when the user types /standup, or says "what should I work on", "daily standup", "where did I leave off", "what's in flight", "where is <feature> at". Part of the ADHD project-workflow system (see [[idea]], [[promote]], [[defect]], [[audit-plans]]).
---

# Daily standup (single repo)

The user has ADHD: too many open loops, novelty bias, weak task object-permanence. This ritual fights all three. It runs against the **current repo** (the user runs it per-repo). The cardinal rule: **end by naming ONE next action, not a menu.** A list is a re-decision tax the user pays by doing nothing.

## Feature trace mode: `/standup <feature-or-plan>`

If the user passes an argument (`/standup <term>`) — other than the `--board` flag below — **skip the board review entirely** and answer "where is this item in the lifecycle and what's its next command?":

1. Search for the term (case-insensitive, incl. obvious slug variants) across `docs/ideas/`, `docs/notes/`, `docs/plans/` (**including `_done/`**), `docs/defects/`, and git branch names (`git branch -a`). If it matches a plan slug/path, treat the plan file as the primary evidence and include its current status, slice count, and first open slice title so `/pjm run-plan <plan>` can locate the target without re-doing discovery.
2. From the hits, place the item in the lifecycle: captured (idea only) → reasoned (idea has a `reasoned:` stamp / a reasoning note exists) → promoted (plan exists, `todo`) → in-progress (plan `in-progress` / matching branch) → done (in `_done/`); defects layer on top (open / diagnosed / fixed).
3. Report the position in one line (e.g. "reasoned, unpromoted") plus the evidence paths, and
   name the **SINGLE next command** in the lifecycle (`/reason`, `/promote`, plain `/standup` for
   the global start/pick, `/pjm run-plan <plan>` for a PJM-targeted plan lane, `/diagnose`,
   `/wrap-up`, …). No board output, no `▶ NEXT` pick.
4. Trace mode is read-only. It must not flip `todo`→`in-progress`, mark a slice done, archive a plan, select a repo-wide `▶ NEXT`, or treat `/standup <plan>` as a request to start or advance that plan. Starting a plan remains a confirmed action from the normal global standup pick, and slice completion remains `/wrap-up`.
5. If nothing matches, say so and suggest the closest-named items found.

Output shape for trace mode:

```
◎ <term>: <lifecycle position>
  evidence: <path(s)> · branch <name> (if any) · plan status/slices (if matched)
→ next: /<command> <target>
```

## WIP limit

**At most 2 plans may be `in-progress`, with 1 `in-progress` task each.** This is enforced HERE — `/standup` is the only place a plan goes `in-progress`. If the user is at the cap, you do not start anything new; you point them at finishing what's in flight.

## Steps

1. Resolve git root. Read every plan in `docs/plans/*.md` (skip `docs/plans/_done/`, and — by the same convention — skip any file whose basename begins with `_`: **underscore-prefixed plans are fixtures**, never counted toward WIP, never picked as `▶ NEXT`, never flagged stalled, never archived). Parse each plan's status and its per-slice statuses. **A slice heading (`### <id> — …`) ending in ` ✅` is done**; slices without it are open (ignore slices explicitly delegated/moved/dropped, e.g. "→ see Plan 08"). This marker is written by `/wrap-up`. **`docs/notes/` is out of scope** — it holds design/decision/reference docs, not task-tracked plans; never read it or flag its files as drift.
2. **WIP check:** count plans with status `in-progress`. Report `N/2`.
3. **Stalled check:** for each `in-progress` plan, `git log -1 --format=%cr -- <plan-file>` and, where the plan names source paths, check recent commits touching them. Flag any `in-progress` plan untouched > **5 days** as stalled — the user likely abandoned it. For each stalled plan force a decision: resume, mark `blocked` (with why), or drop.
4. **Drift check:** plan says `in-progress` but no recent commits relate to it → flag "status may be stale, reconcile."
5. **Amnesty sweep (untracked work):** scan recent git activity — branches and commits from the last **~14 days** (`git log --since="14 days ago" --format="%h %cr %s"` plus `git for-each-ref --sort=-committerdate refs/heads/`) — for work that matches **no plan** in `docs/plans/` and **no defect** in `docs/defects/`. Report matches under a `⊘ UNTRACKED` section and **offer** to backfill: a plan stub via the normal format, or a defect file if it's bug-shaped — stamped as retroactive capture (e.g. `> Backfilled retroactively by /standup amnesty sweep, <date>`). Rules: **never scold** (this is amnesty, not enforcement), **never auto-write** (offer only, write on confirmation), and always allow a batch **"dismiss all"** so chore/noise commits don't nag every standup. Keep the section compact — group related commits into one line per apparent piece of work.
6. **Defect sweep:** read `docs/defects/*.md` (skip if the dir doesn't exist). Note each defect's status/severity. Two classes **compete for the `▶ NEXT` pick**: open **blocker/high-severity** defects, and **`diagnosed`** defects with a ready recommended fix. Summarize the rest on a `✚ DEFECTS` line (counts by status).
7. **Completion check:** any plan whose slices are all ` ✅` (or delegated/dropped) → recommend `git mv` to `docs/plans/_done/` and offer to do it.
8. **Pick the ONE next action globally** (priority order). This is the repo-wide `▶ NEXT` pick
   that `/pjm` may use as its analysis engine; do not narrow it to a named plan unless that plan
   already wins under the same WIP, nearest-finish-line, defect, drift, and completion rules. Echo
   the owning plan's `Model` + `Effort` on the `▶ NEXT` line so a fresh session can run it at the
   right setting without reopening the plan. If the plan carries provider-specific routes, report both routes and the chosen default
   (e.g. Codex/OpenAI `gpt-5.5 · high`; Claude Code `claude-opus-4-8 · high`;
   default Codex/OpenAI).
   If the plan is missing model/effort fields, say so and suggest `/audit-plans`.
   a. A **diagnosed blocker/high defect** beats starting a new plan slice — a ready fix is the nearest finish line there is. Quote the defect's recommended fix as the task. Apply the same nearest-finish-line logic between defects and in-progress slices: whichever is closest to done wins.
   b. An `in-progress` plan — the **nearest finish line** always wins over starting something new. Pick its **first slice not marked ` ✅`** and quote that slice's `task:` string verbatim so it's paste-ready for a fresh Codex or Claude Code session, depending on the selected route.
   c. If nothing is `in-progress` and WIP < 2: offer to **start** the top `todo` plan's first task — flip that plan to `in-progress` (this is the start-time WIP gate) and quote the task.
   d. If at WIP cap (2 in-progress) and the user wants to start a `todo`: **refuse.** Name the two in-progress plans and tell them to finish or explicitly drop one first.

## Output shape (tight — lead with the action)

```
▶ NEXT: <ID>-<n> in <plan> — <title>  [default: <route> <model> · <effort>; also: <other route> <model> · <effort>]
  task: <verbatim task string>

WIP: <N>/2 in progress
  • <plan A> — <in-progress task> (last touched <relative time>)
  • <plan B> — ...
⚠ Stalled (>5d): <plan> — last touched <time> → resume / block / drop?
✓ Complete: <plan> → move to _done/? [y]
~ Drift: <plan> says in-progress but no related commits in <time>
✚ DEFECTS: <n> open (<n> blocker/high, <n> diagnosed) — <name the ones competing for NEXT>
⊘ UNTRACKED (last 14d): <branch/commit group> — <one-line guess at what it is>
  → backfill plan stub / defect file / dismiss all?

BOARD (all active plans)
plan                 status       slices  next open slice           last touch   route · model · effort
<slug>               in-progress  2/5     03 — <slice title>        2 days ago   Codex/OpenAI* gpt-5.5 · high / Claude Code claude-opus-4-8 · high
<slug>               todo         0/3     01 — <slice title>        3 weeks ago  Codex/OpenAI gpt-5.4-mini · medium / Claude Code* claude-fable-5 · high
```

The `BOARD` table lists **every** plan in `docs/plans/*.md` except `_done/` and underscore-prefixed fixtures — including `todo` and `blocked` plans the sections above don't show. Columns: plan slug; status (`todo`/`in-progress`/`blocked`); slices done/total (count ` ✅` slice headings vs total slice headings); next open slice id + title (first slice heading without ` ✅`); last-touched (`git log -1 --format=%cr -- <plan-file>`); the plan's route/model/effort summary. Mark the chosen default with `*` when both provider routes are present. Build it from the step-1 parse — do **not** re-read the plans. Keep it a compact monospace table that fits a terminal; truncate long titles. Omit the table entirely when there are zero active plans. **On a plain `/standup`, the board is ephemeral — rendered to the terminal only, never written to disk.** Persisting it is opt-in via `--board` below.

## `--board`: persist the board to `docs/BOARD.md`

`/standup --board` runs a **normal, full standup** (all steps above, same output) AND additionally writes the BOARD table to **`docs/BOARD.md`** at the repo root's `docs/` — deliberately NOT `docs/plans/`, so the file sits structurally outside step 1's `docs/plans/*.md` sweep and can never self-parse as a plan.

Rules:

- **Full overwrite, never a merge.** The file is regenerated from the plan files on every `--board` run; whatever was there is replaced.
- The file opens with this header line (fill in today's date):
  `<!-- generated by /standup --board on <date> — do not edit; regenerated each run -->`
- **Anti-churn guarantee: a routine `/standup` with no flag writes NO file.** Only an explicit `--board` touches disk, so plain daily standups never dirty the working tree.
- Relationship to a hand-maintained per-project index (e.g. workbench's `docs/plans/00-master-index.md`): `--board` is the generated equivalent; the two may coexist, and converging them is out of scope here.

Omit any section that's empty. Keep it scannable. The `▶ NEXT` line is mandatory and always first. (Trace mode `/standup <feature-or-plan>` uses its own shape above instead.)

## Rules

- One next action. If you're tempted to list three, you've failed the format — pick the one nearest done.
- Never silently flip statuses. Recommend, then act on confirmation (except you may flip a `todo`→`in-progress` when the user accepts the offered start).
- Don't invent work that isn't in a plan or a defect file. If there are none, say so and suggest `/idea` then `/promote` (or `/defect` for bugs).
- Stale threshold is 5 days; if the repo clearly moves slower/faster, say what you used.
