# Wrap Up

End-of-task **umbrella** ritual — the one trigger to run when you finish a task (a plan
*slice*). It runs a fixed sequence against the **current repo** so you remember one thing, not
five: reconcile plan status → capture knowledge → queue shipped-doc work → hand the next
action to the `/pjm` session → nudge weekly hygiene only when it's actually needed.

This normally runs in an **execution session** (the one that just ran the slice), where the
just-finished work and its learnings are fresh. The "what's next" decision is NOT wrap-up's job
in the current model — the long-running `/pjm` session owns it (see step 4).

**Cardinal rule: never flip a status silently.** Recommend the change, then act on the user's
confirmation. Only persist things actually discussed or demonstrated — never fabricate.

## Sequence

### 1. Reconcile plan status (slice-level)

- Identify the slice just finished from the conversation (e.g. `7.1`). If it's ambiguous or no
  slice was finished, ask (or skip this step for a mid-task capture and say so).
- **Confirm before writing:** "Mark `<plan>` `<slice>` done? [y]". On `y`, append ` ✅` to that
  slice's `### <id> — …` heading in `docs/plans/<plan>.md`. This trailing ` ✅` is the
  **canonical slice-done marker** that `/standup` reads to pick the next action — without it,
  standup will re-offer the slice you just finished.
- Ensure the plan's top-level `Status:` is `in-progress` if it was `todo` (a finished slice
  means the plan is underway). Leave it alone if already `in-progress`.
- **Plan completion:** count slice headings. If every `### ` slice is now ` ✅` — ignoring
  slices explicitly delegated/moved/dropped (e.g. "→ see Plan 08") — recommend flipping
  `Status: → done` **and** `git mv docs/plans/<plan>.md docs/plans/_done/`. Confirm each before
  doing it.
- Never invent a slice that isn't in the plan. `docs/notes/` is out of scope (not task-tracked).
- **Worktree handling** (add-on when the slice ran in a git worktree, not the main checkout).
  Detect the worktree context: `git rev-parse --git-common-dir` differs from `.git`, or the cwd
  matches the `<repo>-wt-<plan-id>` sibling-dir convention from `/pjm`'s branch mechanics. If
  detected, after the slice's status reconciliation above, offer the **finish sequence** — each
  step gated on the user's confirmation, per the cardinal rule:
  1. Ensure the work is **committed on the slice branch** (offer the commit; never commit
     silently — global git rule applies).
  2. Hand back to the **main checkout** for merge/PR — **never merge silently**; offer the
     merge or PR step and let the user drive it.
  3. Once the branch is merged or pushed, offer `git worktree remove <path>` (+ pruning the
     branch if merged).
  If the worktree still has **uncommitted changes**, flag it plainly and stop there — **never
  auto-clean** a dirty worktree.

### 2. Capture knowledge

Scan the current conversation for anything worth persisting:

- **Feedback the user gave** — corrections, preferences, "don't do X", confirmations of
  non-obvious approaches.
- **Things about the user** — role changes, new responsibilities, domain knowledge, tool
  preferences.
- **Project context** — ongoing work, decisions, deadlines, blockers, architectural choices and
  their rationale.
- **External references** — URLs, dashboards, tickets, doc locations, channels.
- **Cross-project insights** — patterns/conventions that apply beyond this repo.

**Routing rule:** project memory = context for future Claude sessions; `docs/notes/` = for
humans and the repo record. A fact goes to whichever reader needs it — both only when both do.

Then:

1. **Project memory (if applicable):** read the project's `MEMORY.md` index (in the project's
   `.claude/projects/` memory dir); check whether to update an existing memory vs. create one;
   write/update the memory file(s) in the standard frontmatter format; update the `MEMORY.md`
   index. Skip if nothing project-specific was learned.
2. **Global `~/.claude/CLAUDE.md` (if applicable):** for anything universal (communication /
   coding / workflow preferences, cross-project relationships), add or update the relevant
   section, keeping it concise. Skip if nothing universal was learned.

### 3. Queue shipped-doc work

Scan the finished slice for doc-worthy surfaces:

- **A changed public/shipped contract** (schema, API, payload) → queue a `/draft-spec` task.
- **New user-facing behavior** → queue a `/draft-guide` how-to or brief task.
- **Durable decision rationale worth publishing** → queue a `/draft-guide` explanation task
  (promoting the reasoning note).

"Queue" = append a task line to the owning plan (or the repo's docs backlog) naming the
**audience**, the **mode**, and the **source artifact paths**. **NEVER write the doc inline**
here. If no surface qualifies, skip this step silently.

**Gate rule:** a contract-change spec task **blocks plan completion** — the plan cannot move to
`_done/` (step 1's completion flip) while it's open. All other doc tasks are nudges.

### 4. Next action — hand off to the driver

The **`/pjm`** session is the single driver of "what's next" (next-action pick, model/effort
rec, branch setup — it wraps `/standup` for the analysis). **Do NOT run `/standup` here.** A
wrap-up in an execution session that also names the next action competes with `/pjm` to drive —
the exact re-decision tax the system fights — and tempts this session into *starting* the next
slice, breaking the execute-elsewhere separation. End by telling the user: reconcile + capture
done — switch to your `/pjm` session and ask "what's next?".

**Fallback:** if the user says they're not running a `/pjm` session, invoke the **`standup`**
skill here instead — it owns the `▶ NEXT` line (paste-ready `task:` string + `[model · effort]`),
the WIP=2 check, and stalled/drift flags. Don't duplicate its logic; just run it.

### 5. Weekly-hygiene nudge (conditional — do NOT auto-run)

`/audit-plans` is the heavy weekly pass; never run it automatically. Suggest it in **one line**
only if a hygiene smell surfaced during steps 1 or 4: a plan missing `Model`/`Effort`/`Status`,
an `in-progress` plan flagged stalled, malformed/orphaned/duplicate plans, or standup itself
recommended it.

## Report

- Slice/plan status change(s) made (each was confirmed).
- Memories created or updated (with type); any `CLAUDE.md` changes. If nothing was worth
  persisting, say so — that's fine.
- Doc tasks queued (audience · mode · source paths), noting whether any is a completion-blocking
  spec task. If none qualified, omit this line.
- The next-action hand-off: point the user to their `/pjm` session (or, in the fallback case,
  the `▶ NEXT` line from standup).
- The audit-plans nudge, if triggered.
