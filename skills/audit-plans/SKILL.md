---
name: audit-plans
description: Weekly hygiene audit of docs/plans/ and docs/ideas/ in the current repo. Validates every plan against the format rubric, flags malformed/orphaned/duplicate/stale items (including ideas stuck waiting on a workshop), and recommends archival or deletion. Heavier and less frequent than /standup. Use when the user types /audit-plans, or says "audit my plans", "clean up the backlog", "are my plans well-formed", "what can I delete". Part of the ADHD project-workflow system (see [[idea]], [[reason]], [[promote]], [[standup]]).
---

# Audit plans & ideas (weekly hygiene)

`/standup` is the daily "what do I do next." This is the weekly "is the board itself healthy." It's read-mostly: you **report and recommend**, and only mutate files on explicit confirmation. Run against the **current repo**.

## Docs root (resolve this FIRST)

Before reading or writing any lifecycle doc, resolve the **docs root**:

- Let `<repo>` = basename of the current repo's git root (`basename "$(git rev-parse --show-toplevel)"`).
- If the config file `~/.config/adhd-workflow/backlog-root` exists, read it: it holds one line, the absolute path of a **backlog metarepo** (a git repo that centralizes backlog docs for many code repos) — call it `<backlog-root>`. If `<backlog-root>/<repo>/` exists, **that dir is the docs root** — `ideas/`, `plans/` (with `_done/`), `defects/`, and `BOARD.md` live directly under it (there is **no `docs/` path segment** inside the metarepo).
- Otherwise fall back to `./docs/` in the current repo, exactly as before.

Everywhere below, `docs/ideas/`, `docs/plans/`, `docs/defects/`, and `docs/BOARD.md` mean paths under the resolved docs root. **Reasoning notes are the exception: `docs/notes/` ALWAYS stays in the current code repo's own `./docs/notes/`, never the metarepo.** Paths written *inside* a plan/idea/defect are relative to the code repo, not the metarepo.

**Writing under the metarepo:** when the docs root is the metarepo, every file you create, edit, move (`git mv`), or delete there is **immediately committed and pushed**, scoped to the affected path(s): `git -C <backlog-root> add <path> && git -C <backlog-root> commit -m "<msg>" && git -C <backlog-root> push`. This is a deliberate exception to the no-auto-commit rule and applies ONLY to writes under the metarepo. Reads and writes in the code repo (reasoning notes, `scripts/slice-gate.sh`, git-based stall detection) are unchanged and are **NOT** auto-committed.


## What to check

Resolve git root. Read `docs/plans/*.md`, `docs/plans/_done/*.md`, and `docs/ideas/*.md`. Just as `_done/` is excluded from active-plan checks, **any file in `docs/plans/` whose basename begins with `_` is a fixture** — never counted toward WIP, never picked as `▶ NEXT`, never flagged stale, never archived; skip it in every check below. **`docs/notes/` is out of scope for format checks** — design/decision/reference docs live there; never flag a `docs/notes/` file as a malformed plan or drift. (The one exception: check #9 may flag a reasoning note as *stale* — staleness only, never format.)

1. **Format conformance** — every active plan must satisfy the `/promote` rubric: a definition of done, actionable tasks, a `Verify:` clause per task, scoped (~≤8 tasks), a one-line why, and the provider-qualified model header contract. A current plan has:
   - Every slice as a **`### <ID>-<n> — <title>` heading** with a `> status: <status> · depends: <...>` line directly beneath it. The heading is what `/run-plan` and `/wrap-up` stamp ` ✅` onto and what `/standup`/`/pjm` scan for the first open slice — a slice that is not a `### ` heading is invisible to all four.
   - `> Default run tier: **<Claude friendly> · <effort>** (`<claude-slug>`) · Codex **<OpenAI friendly> · <effort>** (`<openai-slug>`)` — both provider routes on one line, with exact slugs.
   - A `Run at:` line on **every** slice, naming a Claude Code tier and a Codex tier: `> Run at: Claude Code **<friendly> · <effort>** · Codex **<friendly> · <effort>**`.
   - A `Why this tier:` line on every slice that names a specific latitude or trap. A `Why this tier:` that only restates the slice title is a violation — that line exists to make the tier call falsifiable.
   - Valid slugs: OpenAI `gpt-5.5|gpt-5.4|gpt-5.4-mini|gpt-5.4-nano` with effort `none|low|medium|high|xhigh`; Claude `claude-fable-5|claude-opus-4-8|claude-sonnet-5|claude-haiku-4-5` with effort `low|medium|high|xhigh|max`, `max` treated as Claude-only/session-only and valid only for current Fable / Opus / Sonnet routes.
   Flag each violation with the specific missing piece — a missing provider, a missing `Run at:` on some slice, an invalid model slug, or an invalid provider-aware Effort. A plan that's drifted out of format is a plan that's quietly rotting.
   **Uniform-tier smell** (recommend, never flag as malformed): a multi-slice plan where every slice carries the identical tier usually means the tiers were copied rather than decided. Suggest a re-read against the ladder in `/promote` — schema/contract slices keep the top tier, example and doc slices usually downshift.
   **Legacy migration rule:** three legacy shapes are **readable, not malformed** — the previous four-line `Model:`/`OpenAI:`/`Claude:`/`Recommended:` header; unqualified `opus`, `sonnet`, `haiku`, `fable` model names; and the **bold slice dialect** (`**<ID>-n — <title>** · <status> · depends: <...>` as a paragraph line instead of a `### ` heading). Flag the header shapes for migration to a `Default run tier:` line plus per-slice `Run at:` lines; flag a bold-dialect plan for migration to `### ` slice headings — the machine skills cannot find its slices at all until it converts — and offer to convert: each bold line becomes a `### <ID>-<n> — <title>` heading with the inline `· <status> · depends: <...>` moved to a `> status:` line directly beneath (a slice already marked done keeps its ` ✅` on the new heading). Never treat any of the three as unreadable. An `Effort` present only at plan level still drives the red-gate for every slice.
2. **Status integrity** — every plan and task has a valid status (`todo`/`in-progress`/`blocked`/`done`). Flag missing or junk statuses. Flag plans where all tasks are `done` but the plan still sits in `docs/plans/` → should move to `_done/`.
3. **WIP sanity** — count `in-progress` plans. If > 2, the cap has been violated; list them and tell the user to pick 2 and re-`blocked`/`todo` the rest. (Cross-reference what `/standup` would say.)
4. **Stalled & blocked** — `git log -1 --format=%cr` per plan file. Flag `in-progress` untouched > 5 days and `blocked` items with no recorded reason or untouched > 30 days (probably dead — recommend drop).
5. **Orphaned ideas** — ideas in `docs/ideas/` older than ~30 days never promoted. Recommend: promote, or delete as stale. Capture is cheap; a graveyard of ideas is noise.
6. **Stalled reasoning** — ideas whose frontmatter `reasoned:` field is `workshop-pending (...)` and untouched > ~14 days (`git log -1 --format=%cr`). The `/reason` gate sent it to a `/design-workshop` and the workshop never came back — a pending workshop is a decision being avoided, not a decision made. Recommend: run the workshop and re-`/reason`, or drop the idea. (Do NOT flag `reasoned: clear` or `reasoned: notes/...` ideas here — those cleared the gate; if they're old and unpromoted they're already caught by #5.)
7. **Duplicates / overlap** — plans or ideas covering the same ground. Recommend a merge.
8. **`_done/` review** — confirm archived plans really are all-`done`. (Optional: note ones the user might want to fully delete, but default to keeping the archive.)
9. **Stale reasoning notes** — reasoning notes in `docs/notes/` (e.g. `*-reasoning.md`) that no active plan references AND that are untouched > ~90 days (`git log -1 --format=%cr`). Recommend: confirm the decision still holds, or mark the note superseded. This narrows the notes-out-of-scope rule above: the audit may FLAG a note as stale, but still never treats a note as a malformed plan.
10. **Doc re-verify nudge** — shipped docs whose front-matter `verified-against` commit predates significant git churn in the paths listed in their `source:` field (`git log --oneline <verified-against>.. -- <source paths>` shows real changes). Recommend a re-verify. This is a **nudge only, never a gate** — don't block or demote anything over it.

## Output shape

Group by recommended action so it's a worklist, not a wall of text:

```
FIX FORMAT
  • <plan> — missing Verify: on <task>; no definition-of-done
MIGRATE MODEL HEADERS
  • <plan> — legacy unqualified `opus` model → migrate to provider-qualified OpenAI/Claude routes
ARCHIVE → _done/
  • <plan> — all tasks done
WIP VIOLATION (3/2)
  • keep <A>, <B>; demote <C> to todo?
STALLED / DEAD
  • <plan> blocked 41d, no reason → drop?
  • <idea> captured 2026-05-01, never promoted → promote or delete?
  • <idea> workshop-pending (architecture) 23d → run the workshop + re-/reason, or drop?
DUPLICATES
  • <X> and <Y> overlap → merge?
STALE NOTES
  • <note> — referenced by no active plan, untouched 120d → confirm still true or mark superseded?
RE-VERIFY DOCS (nudge)
  • <doc> — verified-against abc1234, but source paths have 14 commits since → re-verify?
```

End with a single line: how many items are clean vs need attention — then `/standup` for the next action.

## Rules

- Read-mostly. Propose every mutation; act only on a clear yes. Batch `git mv` archival moves if the user approves several at once.
- Never delete a plan or idea without explicit confirmation, and prefer `git mv` to `_done/` (or, for ideas, deletion) over `rm` so it's recoverable.
- This is hygiene, not planning — don't write new plans here. Send substantive new work through `/promote`.
