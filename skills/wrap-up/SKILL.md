---
name: wrap-up
description: End-of-task umbrella ritual for finishing a plan slice in the current repo. Use when the user types /wrap-up, invokes $wrap-up, says "wrap up this slice", "finish this task", "mark this slice done", or needs to reconcile completed execution work. Confirms before changing status, captures knowledge, queues shipped-doc work, and hands the next action back to /pjm. Part of the ADHD project-workflow system (see [[standup]], [[pjm]], [[draft-spec]], [[draft-guide]], [[audit-plans]]).
---

# Wrap Up

End-of-task **umbrella** ritual — the one trigger to run when you finish a task (a plan
*slice*). It runs a fixed sequence against the **current repo** so you remember one thing, not
five: reconcile plan status → capture knowledge → queue shipped-doc work → hand the next
action to the `/pjm` session → nudge weekly hygiene only when it's actually needed.

This normally runs in an **execution session** (the one that just ran the slice), where the
just-finished work and its learnings are fresh. `/run-plan` also invokes this skill itself when
a run ends (clean or halted) — machine invocation changes **nothing** below: every
confirm-before-writing rule holds, and there is no machine-confirm mode (the slice-gate
convention says why there never will be). The "what's next" decision is NOT wrap-up's job
in the current model — the long-running `/pjm` session owns it (see step 5).

**Cardinal rule: never flip a status silently.** Recommend the change, then act on the user's
confirmation. Only persist things actually discussed or demonstrated — never fabricate.

## Docs root (resolve this FIRST)

Before reading or writing any lifecycle doc, resolve the **docs root**:

- Let `<repo>` = basename of the current repo's git root (`basename "$(git rev-parse --show-toplevel)"`).
- If the config file `~/.config/adhd-workflow/backlog-root` exists, read it: it holds one line, the absolute path of a **backlog metarepo** (a git repo that centralizes backlog docs for many code repos) — call it `<backlog-root>`. If `<backlog-root>/<repo>/` exists, **that dir is the docs root** — `ideas/`, `plans/` (with `_done/`), `defects/`, and `BOARD.md` live directly under it (there is **no `docs/` path segment** inside the metarepo).
- Otherwise fall back to `./docs/` in the current repo, exactly as before.

Everywhere below, `docs/ideas/`, `docs/plans/`, `docs/defects/`, and `docs/BOARD.md` mean paths under the resolved docs root. **Reasoning notes follow the docs root too**: `docs/notes/` means `<backlog-root>/<repo>/notes/` when a metarepo is configured, and `./docs/notes/` in the code repo otherwise. Only lifecycle reasoning notes (`*-reasoning.md`, written by `/reason`) live there — durable design, decision, and reference docs stay in the code repo's own `./docs/notes/` and never move. Paths written *inside* a plan/idea/defect are relative to the code repo, not the metarepo.

**Writing under the metarepo:** when the docs root is the metarepo, every file you create, edit, move (`git mv`), or delete there is **immediately committed and pushed**, scoped to the affected path(s): `git -C <backlog-root> add <path> && git -C <backlog-root> commit -m "<msg>" && git -C <backlog-root> push`. This is a deliberate exception to the no-auto-commit rule and applies ONLY to writes under the metarepo. Reads and writes in the code repo (`scripts/slice-gate.sh`, git-based stall detection, durable `docs/notes/` reference docs) are unchanged and are **NOT** auto-committed.


## Sequence

### 1. Reconcile plan status (slice-level)

- Identify the slice just finished from the conversation (e.g. `7.1`). If it's ambiguous or no
  slice was finished, ask (or skip this step for a mid-task capture and say so).
- **Confirm before writing:** "Mark `<plan>` `<slice>` done? [y]". On `y`, append ` ✅` to that
  slice's `### <id> — …` heading in `docs/plans/<plan>.md`. This trailing ` ✅` is the
  **canonical slice-done marker** that `/standup` reads to pick the next action — without it,
  standup will re-offer the slice you just finished.
- **The slice gate** (the convention in the workflow repo's own `./docs/notes/slice-gate-convention.md`
  — a durable note, which stays in the code repo whether or not a metarepo is configured)
  is the other legitimate writer of this marker: `/run-plan`'s orchestrator stamps a slice
  ` ✅ (<command>, <sha>)` only after the gate's five machine facts pass, or
  ` ✅ (<command>, single-agent)` for a red-gate-exempt slice witnessed by the whole-tree check
  alone (the weaker of the two — the provenance says which). A slice arriving with a
  provenance-stamped marker is already done — reconcile around it, don't re-confirm it. For
  hand-run slices the user's confirm above IS the gate; wrap-up has no machine-confirm mode and
  must never gain one (the convention note says why).
- Ensure the plan's top-level `Status:` is `in-progress` if it was `todo` (a finished slice
  means the plan is underway). Leave it alone if already `in-progress`.
- **Plan completion:** count slice headings. If every `### ` slice is now ` ✅` — ignoring
  slices explicitly delegated/moved/dropped (e.g. "→ see Plan 08") — recommend flipping
  `Status: → done` **and** `git mv docs/plans/<plan>.md docs/plans/_done/`. Confirm each before
  doing it.
- Never invent a slice that isn't in the plan. Notes are out of scope here (not task-tracked) —
  both the code repo's durable `./docs/notes/` reference docs and the lifecycle reasoning notes
  under the docs root. A spent reasoning note is step 4's business, not this step's.
- **Worktree handling** (add-on when the slice ran in a git worktree, not the main checkout).
  Detect the worktree context: `git rev-parse --git-common-dir` differs from `.git`, or the cwd
  matches the `<repo>-wt-<plan-id>` sibling-dir convention from `/pjm`'s branch mechanics. If
  detected, after the slice's status reconciliation above, offer the **finish sequence** — each
  step gated on the user's confirmation, per the cardinal rule:
  1. Ensure the work is **committed on the slice branch** (offer the commit; never commit
     silently — global git rule applies).
  2. Hand back to the **main checkout** for merge/PR/push — **never merge or push silently**;
     offer the merge, PR, or push step and let the user drive it.
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

**Routing rule:** project memory = context for future execution sessions; `docs/notes/` = for
humans and the repo record. In Claude Code, project memory means the `.claude/projects/` memory
files below. In Codex, use whatever project-memory surface is actually available; if there isn't
one, skip memory writes rather than inventing a path. A fact goes to whichever reader needs it —
both only when both do.

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

### 4. Retire a spent reasoning note (confirm before deleting)

A reasoning note is **interim state**, not repo content. It exists to carry a decision from idea to
plan, and its life ends when the thing it fed exists: an ADR, shipped code, a spec, a guide, or a
paragraph in `CLAUDE.md`. At that point the note is a second, staler copy of a decision that now
lives somewhere better — the exact drift that makes a future session trust the wrong artifact.

**Run this step only when step 1 flipped the whole plan to done.** A note feeds a plan, not a
slice; it stays live while any slice of that plan is open.

1. **Find the note.** Look for `docs/notes/<plan-slug>-reasoning.md` **under the resolved docs
   root** — i.e. `<backlog-root>/<repo>/notes/<plan-slug>-reasoning.md` when a metarepo is
   configured, `./docs/notes/<plan-slug>-reasoning.md` in the code repo otherwise. Also read the
   plan's design-authority line (plans name it as `Design authority: <path>`); that path is
   written code-repo-relative, and older plans were written when notes lived in the code repo, so
   resolve its basename under the docs root **first** and fall back to the literal path in the
   code repo if nothing is there. If the plan names none and no matching note exists, skip this
   step silently. Whichever repo the note turns out to live in is the repo you delete it from in
   sub-step 4 — record it.
2. **Decide whether it is spent** — name the artifact that absorbed it. "The code merged" is not
   enough on its own; say *where the reasoning now lives*: ADR NNNN, a `docs/reference/` spec, a
   shipped guide, a `CLAUDE.md` paragraph, or a comment at a named path. If you cannot name one,
   it is not spent — leave it and say why.
3. **Check the four blockers.** Any one of them means do not delete:
   - **Step 3 queued it as a doc source.** A note queued for a `/draft-guide` explanation is still
     the input to unwritten work. It retires when that doc ships, not now.
   - **Something still cites it.** Grep for the note in **both repos** — the code repo (ADRs,
     `CLAUDE.md`, `README`, durable notes) *and* the backlog metarepo (plans, ideas, defects,
     `BOARD.md`), when one is configured. A live citation in either repo means deleting the note
     strands a reference. Either update the citing artifact in the same breath (see sub-step 4 —
     the fix lands differently depending on which repo holds it), or keep the note.

     The note now has **two spellings**: `docs/notes/<file>` (the code-repo spelling, which plans
     also use because paths written inside a plan are code-repo-relative) and `notes/<file>` (the
     metarepo spelling). Search **both spellings in both roots** — a plan in the metarepo may
     carry the code-repo spelling, and a durable code-repo note may cite the metarepo one:

     ```
     grep -rn --fixed-strings "docs/notes/<file>" <code-repo-root>
     grep -rn --fixed-strings "notes/<file>"      <code-repo-root>
     grep -rn --fixed-strings "docs/notes/<file>" <backlog-root>/<repo>/
     grep -rn --fixed-strings "notes/<file>"      <backlog-root>/<repo>/
     ```

     **Precision rule (unchanged, now with a second way to trip it):** match the **full path as
     written**, never a trailing fragment. A bare `docs/notes/<file>` pattern also matches
     `other-repo/docs/notes/<file>`, and a cross-repo citation from an unrelated repo is not a
     local one. The `notes/<file>` spelling is *itself* a trailing fragment of `docs/notes/<file>`
     and of `<backlog-root>/other-repo/notes/<file>`, so read every hit and keep only the ones
     whose full path resolves to **this** note in one of these two repos. Discard the rest — do
     not let a foreign repo's citation block the delete, and do not double-count one citation
     because both spellings matched the same line.
   - **It holds parked or out-of-scope content** nothing is going to consume. That is not an
     interim note, it is a specification wearing a note's filename. Do not delete it and do not
     leave it mis-filed — flag it for rehoming into the **code repo** (an ADR appendix, or
     `docs/reference/` marked out of scope) and move on. When the note sits in the metarepo, that
     rehoming is a cross-repo move, not a rename — flag it, don't perform it here.
   - **Its plan is not actually complete.** Re-read the slice headings in the plan (under the
     docs root); a missing ` ✅` beats your recollection.
4. **Confirm, then delete.** State the note, the artifact that absorbed it, and that git history
   retains it — cite the SHA it was last modified in (`git -C <root> log -1 --format=%H -- <path>`,
   where `<root>` is whichever repo holds the note), so a future session can retrieve it. Delete
   only on an explicit yes. **How you delete depends on which repo holds the note** (sub-step 1
   recorded it):
   - **Note in the backlog metarepo.** This is a metarepo write, so it is **committed and pushed
     immediately**, scoped to that path, exactly like every other metarepo write:
     `git -C <backlog-root> rm <repo>/notes/<file> && git -C <backlog-root> commit -m "<msg>" && git -C <backlog-root> push`.
   - **Note in the code repo** (no metarepo configured, or the note never moved). Delete the file
     and **do not commit** — the no-auto-commit rule holds in the code repo; the user commits the
     deletion themselves.

   **Fixing inbound citations now spans two repos**, and the two halves commit differently:
   - A citing artifact **in the metarepo** is fixed in the **same metarepo commit** as the delete
     — `git -C <backlog-root> add <citing path>` alongside the `git rm`, then one commit and push
     scoped to both paths.
   - A citing artifact **in the code repo** is a **separate code-repo edit that is NOT
     auto-committed**. Make the edit, then leave it in the working tree and tell the user plainly
     that it is uncommitted and waiting on them. Never fold a code-repo edit into the metarepo
     commit.

   Because the metarepo half self-commits and the code-repo half does not, a delete can ship
   while a code-repo citation still points at the deleted file. Make the code-repo edit before
   you run the metarepo delete, and say in the report which files are left uncommitted.

Delete rather than archive. Unlike a plan going to `_done/`, a spent note's content is not lost —
it moved into the artifact you named in step 2, and git holds the original (in whichever repo the
note lived in).

### 5. Next action — hand off to the driver

The **`/pjm`** session is the single driver of "what's next" (next-action pick, provider route,
model/effort rec, branch setup — it wraps `/standup` for the analysis). **Do NOT run `/standup`
here.** A wrap-up in an execution session that also names the next action competes with `/pjm` to
drive — the exact re-decision tax the system fights — and tempts this session into *starting* the
next slice, breaking the execute-elsewhere separation.

If this slice came from **`/pjm run-plan <plan>`**, end by telling the user: reconcile + capture
done — return to that same `/pjm` session and continue the same plan-run loop for `<plan>`. Do
not start a fresh PJM session, do not let wrap-up pick the next slice, and do not ask the user to
run a plain "what's next?" standup-style decision.

Otherwise, end by telling the user: reconcile + capture done — switch to your `/pjm` session and
ask "what's next?".

**Fallback:** if the user says they're not running a `/pjm` session, invoke the **`standup`**
skill here instead — it owns the `▶ NEXT` line (paste-ready `task:` string + default route,
alternate route when present, model, and effort), the WIP=2 check, and stalled/drift flags. Don't
duplicate its logic; just run it.

### 6. Weekly-hygiene nudge (conditional — do NOT auto-run)

`/audit-plans` is the heavy weekly pass; never run it automatically. Suggest it in **one line**
only if a hygiene smell surfaced during steps 1, 4, or 5: a plan missing `Model`/`Effort`/`Status`,
an `in-progress` plan flagged stalled, malformed/orphaned/duplicate plans, or standup itself
recommended it.

## Report

- Slice/plan status change(s) made (each was confirmed).
- Memories created or updated (with type); any `CLAUDE.md` changes. If nothing was worth
  persisting, say so — that's fine.
- Doc tasks queued (audience · mode · source paths), noting whether any is a completion-blocking
  spec task. If none qualified, omit this line.
- The reasoning note's disposition, when a completed plan named one: deleted (naming the artifact
  that absorbed it), kept (naming which blocker held it), or flagged for rehoming. On a delete,
  say which repo held the note — and if it was the metarepo, that the delete is already committed
  and pushed there, plus any code-repo citation fix left **uncommitted** for the user. Omit the
  line when the plan named no note or no plan completed.
- The next-action hand-off: point the user to their `/pjm` session; if the slice came from
  `/pjm run-plan <plan>`, explicitly tell them to return to that same session and continue the
  same plan-run loop for `<plan>` (or, in the fallback case, the `▶ NEXT` line from standup,
  including the OpenAI route, Claude route, and chosen default when the plan carries them).
- The audit-plans nudge, if triggered.
