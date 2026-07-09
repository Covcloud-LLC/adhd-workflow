---
name: audit-plans
description: Weekly hygiene audit of docs/plans/ and docs/ideas/ in the current repo. Validates every plan against the format rubric, flags malformed/orphaned/duplicate/stale items (including ideas stuck waiting on a workshop), and recommends archival or deletion. Heavier and less frequent than /standup. Use when the user types /audit-plans, or says "audit my plans", "clean up the backlog", "are my plans well-formed", "what can I delete". Part of the ADHD project-workflow system (see [[idea]], [[reason]], [[promote]], [[standup]]).
---

# Audit plans & ideas (weekly hygiene)

`/standup` is the daily "what do I do next." This is the weekly "is the board itself healthy." It's read-mostly: you **report and recommend**, and only mutate files on explicit confirmation. Run against the **current repo**.

## What to check

Resolve git root. Read `docs/plans/*.md`, `docs/plans/_done/*.md`, and `docs/ideas/*.md`. Just as `_done/` is excluded from active-plan checks, **any file in `docs/plans/` whose basename begins with `_` is a fixture** — never counted toward WIP, never picked as `▶ NEXT`, never flagged stale, never archived; skip it in every check below. **`docs/notes/` is out of scope for format checks** — design/decision/reference docs live there; never flag a `docs/notes/` file as a malformed plan or drift. (The one exception: check #9 may flag a reasoning note as *stale* — staleness only, never format.)

1. **Format conformance** — every active plan must satisfy the `/promote` rubric: a definition of done, actionable tasks, a `Verify:` clause per task, scoped (~≤8 tasks), a one-line why, and the provider-qualified model header contract. A current plan has:
   - `> Model: <OpenAI|Claude> <model-id> · Effort: <provider-valid effort>` for the recommended default route.
   - `> OpenAI: <gpt-5.5|gpt-5.4|gpt-5.4-mini|gpt-5.4-nano> · Effort: <none|low|medium|high|xhigh>`.
   - `> Claude: <claude-fable-5|claude-opus-4-8|claude-sonnet-5|claude-haiku-4-5> · Effort: <low|medium|high|xhigh|max>`, with `max` treated as Claude-only/session-only and valid only for current Fable / Opus / Sonnet routes.
   - `> Recommended: ...` choosing the default between the OpenAI and Claude routes for the current surface.
   Flag each violation with the specific missing piece — including a missing provider, missing route line, invalid model slug, or invalid provider-aware Effort. A plan that's drifted out of format is a plan that's quietly rotting. **Legacy migration rule:** old active plans using unqualified `opus`, `sonnet`, `haiku`, or `fable` are readable legacy plans; flag them for migration to a provider-qualified route such as `Claude claude-opus-4-8` plus explicit OpenAI / Claude route lines, not as unreadable or malformed.
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
