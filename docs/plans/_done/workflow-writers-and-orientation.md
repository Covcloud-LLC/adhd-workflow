# Workflow writers & orientation — doc taxonomy, writer skills, and recoverability fixes

> Status: **done** · created 2026-07-07 · completed 2026-07-07
> Model: fable · Effort: medium
> Home: cross-repo system (skills are global in `~/.claude/skills/`), so the plan lives in the
> dotfiles repo. Every slice edits `~/.claude` only.
> Why: the process fails by disorientation (circumvented hotfixes, forgotten next steps, lost
> feature state) and by ad-hoc "which document?" confusion — fix with recoverability + a fixed
> two-layer doc taxonomy, never with harder gates.
> Reasoning: `docs/notes/workflow-writers-and-orientation-reasoning.md` — its decisions are
> inputs here, not up for re-litigation.

## Definition of done

All seven slices landed in `~/.claude`. Smoke pass in one real repo shows: `/draft-spec` and
`/draft-guide` produce drafts carrying the six-field front-matter with grep-verified facts;
`/standup` surfaces untracked work and answers `/standup <feature>`; `/wrap-up` queues a doc
task for a contract-touching slice; every workflow skill ends with a breadcrumb line.

## Acceptance criteria

- [ ] A contract change can go idea → plan → build → spec draft with no hand-typed front-matter
      and no "which doc do I need?" decision.
- [ ] A hotfix chat session's work shows up in the next `/standup` as `⊘ UNTRACKED` with a
      backfill offer.
- [ ] `/standup <feature>` answers "where is X and what's the next command" from repo state.
- [ ] No new gate, ceremony, or hand-written document kind was introduced.

---

### WWO-1 — New `/draft-spec` skill (reference/contract writer) **Run at: fable · high** ✅

> task: Create `~/.claude/skills/draft-spec/SKILL.md`, the shipped-docs writer for
> reference/contract material (Diátaxis "reference"). First read
> `~/.claude/docs/notes/workflow-writers-and-orientation-reasoning.md` (decisions §2–3) and
> `~/.claude/skills/draft-guide/SKILL.md` (match its frontmatter/description conventions and its
> verification discipline). Requirements: (1) audience is developers AND context-collecting
> bots; refuse to draft if no named reader — ask, never invent. (2) Register: tables, schemas,
> field lists; no narrative prose. (3) Verification rule: every field name, path, enum value,
> and example payload must be grepped against the actual emitting/consuming source (or a live
> endpoint) before it's written — cite where each was verified; unverifiable values get a
> literal `‹VERIFY›` marker, never a guess. (4) Emit the six-field front-matter block
> (doc-type/audience/status/verified-against/repo/source) automatically, with
> `verified-against` set to the current commit SHA. (5) One fact, one home — link to existing
> docs instead of duplicating; refuse how-to/tutorial requests and point to `/draft-guide`.
> (6) Output goes to the repo's shipped-docs dir (e.g. `docs/reference/`), and the skill offers
> to update the repo's `docs/README.md` index. (7) Ends with a handoff report (what was
> verified, `‹VERIFY›` gaps) and the breadcrumb line. Verify: smoke-run in a real repo
> against an existing contract — the draft's
> every field name greps in source, all six front-matter fields are present, and the skill
> refused (or asked) when invoked with no audience.

### WWO-2 — Extend `/draft-guide` (quickstart, brief, explanation modes + front-matter) **Run at: fable · high** ✅

> task: Edit `~/.claude/skills/draft-guide/SKILL.md`. First read
> `~/.claude/docs/notes/workflow-writers-and-orientation-reasoning.md` (decisions §1–3). Changes:
> (1) Extend the mode list from {tutorial, how-to} to {tutorial, how-to, quickstart, brief,
> explanation}, each with a one-line pick test: quickstart = shortest path to first success,
> tutorial-shaped but minimal; brief = post-build knowledge transfer to another dev/stakeholder
> (what this is, why it exists, how it behaves, gotchas), sourced from the plan + reasoning
> note + diff; explanation = promotion of an existing `docs/notes/` reasoning note into a
> shipped doc (transform, don't rewrite from scratch). (2) Drop the "refuse explanation" rule;
> KEEP refusing pure reference material — point to `/draft-spec`. (3) Emit the same six-field
> front-matter block as `/draft-spec` (doc-type/audience/status/verified-against/repo/source).
> (4) Keep the existing verification discipline, reading-level rubric, house-voice matching,
> and "state the mode + one-line reason before drafting" rule unchanged — the mode statement is
> now mandatory across all five modes. (5) End with the breadcrumb line. Verify: the mode table
> lists five modes each with a pick test; the front-matter template is present; a smoke run on
> an existing reasoning note (any repo) produces an explanation draft carrying the front-matter.

### WWO-3 — `/standup` upgrades: amnesty sweep, defect sweep, `<feature>` argument ✅

> task: Edit `~/.claude/skills/standup/SKILL.md`. Three additions, decisions §4–5 of
> `~/.claude/docs/notes/workflow-writers-and-orientation-reasoning.md`. (a) **Amnesty sweep** —
> after the existing drift check, scan recent git activity (~14d lookback: branches + commits)
> for work matching no plan in `docs/plans/` and no defect in `docs/defects/`; report it under a
> new `⊘ UNTRACKED` output section and OFFER to backfill a plan stub or defect file (retroactive
> capture, stamped as such). Never scold, never auto-write, allow a batch "dismiss all" so chore
> noise doesn't nag. (b) **Defect sweep** — read `docs/defects/*.md`; open blocker/high-severity
> defects and `diagnosed` defects with a ready fix compete for the `▶ NEXT` pick (a diagnosed
> blocker beats starting a new plan slice; use the same nearest-finish-line logic). Add a
> `✚ DEFECTS` line to the output shape. (c) **`<feature>` argument** — `/standup <term>` traces
> the term across `docs/ideas/`, `docs/notes/`, `docs/plans/` (incl. `_done/`), `docs/defects/`,
> and git branches, then reports the lifecycle position ("reasoned, unpromoted") and the SINGLE
> next command — instead of the normal board review. Update the output-shape block for all
> three. Verify: read-back shows the three additions + updated output shape; smoke-run in a repo
> with an unplanned branch → `⊘ UNTRACKED` offer appears; `/standup <known-feature>` answers
> position + next command.

### WWO-4 — `/wrap-up` doc-task nudge + knowledge-routing rule ✅

> task: Edit `~/.claude/commands/wrap-up.md`, per decisions §1–3 of
> `~/.claude/docs/notes/workflow-writers-and-orientation-reasoning.md`. (1) Insert a new step
> between "Capture knowledge" and "Next action": **Queue shipped-doc work** — scan the finished
> slice for doc-worthy surfaces: a changed public/shipped contract → queue a `/draft-spec` task;
> new user-facing behavior → queue a `/draft-guide` how-to or brief task; durable decision
> rationale worth publishing → queue a `/draft-guide` explanation task (promoting the reasoning
> note). "Queue" = append a task line to the owning plan (or the repo's docs backlog) naming the
> audience, the mode, and the source artifact paths — NEVER write the doc inline, and skip the
> step silently when no surface qualifies. Gate rule: a contract-change spec task BLOCKS plan
> completion (the plan can't move to `_done/` while it's open); all other doc tasks are nudges.
> (2) In the existing Capture step, add the routing rule: project memory = context for future
> Claude sessions; `docs/notes/` = for humans and the repo record; a fact goes to whichever
> reader needs it (both only when both do). Verify: read-back — the sequence shows the new step
> with the gate rule, and the capture step carries the routing rule.

### WWO-5 — Gate hardening: `/promote` acceptance criteria + `/audit-plans` staleness checks ✅

> task: Two small edits, decisions §1 and §3 of
> `~/.claude/docs/notes/workflow-writers-and-orientation-reasoning.md`. (1)
> `~/.claude/skills/promote/SKILL.md`: add a rubric row — a plan for a user-facing feature must
> carry an explicit `## Acceptance criteria` checklist of observable behaviors (backend/internal
> plans exempt); add the optional section to the house-format template. (2)
> `~/.claude/skills/audit-plans/SKILL.md`: add two checks — (a) reasoning notes in `docs/notes/`
> referenced by no active plan and untouched > ~90d → recommend "confirm still true or mark
> superseded" (this narrows the existing notes-out-of-scope rule: audit may now FLAG note
> staleness but still never treats notes as malformed plans); (b) shipped docs whose
> front-matter `verified-against` predates significant git churn in their `source:` paths →
> recommend re-verify (nudge only, never a gate). Add both to the audit output shape. Verify:
> read-back of both files shows the additions and the updated output shapes.

### WWO-6 — Breadcrumbs: every skill ends by naming the single next command ✅

> task: Edit the workflow skills so each ends its report with ONE line naming the single next
> command in the lifecycle (decision §5 of
> `~/.claude/docs/notes/workflow-writers-and-orientation-reasoning.md` — recoverability, not new
> commands). Mapping: `~/.claude/skills/idea/SKILL.md` → "when ready: `/reason <slug>`";
> `~/.claude/skills/defect/SKILL.md` → "`/diagnose <slug>` when you want the root cause";
> `~/.claude/skills/diagnose/SKILL.md` → keep the existing fix handoff, add "or `/promote` if
> the fix is plan-sized"; `~/.claude/skills/reason/SKILL.md` → confirm the existing
> chain-into-`/promote` offer satisfies the rule (no change if so);
> `~/.claude/skills/promote/SKILL.md` → "`/standup` starts it when a WIP slot opens";
> `~/.claude/skills/audit-plans/SKILL.md` → "then `/standup` for the next action";
> `~/.claude/commands/wrap-up.md` → confirm the existing point-to-`/pjm` close satisfies the
> rule. `/standup` and `/pjm` are terminal drivers — no breadcrumb needed. Hold each addition to
> ~1 line; do not restructure any skill. Verify: grep each listed file for its breadcrumb line;
> diff shows ≤2 added lines per file.

### WWO-7 — Taxonomy docs: global `CLAUDE.md` rules + workflow guide update ✅

> task: Two doc edits, decisions §1 and §4 of
> `~/.claude/docs/notes/workflow-writers-and-orientation-reasoning.md`. (1)
> `~/.claude/CLAUDE.md`, in the ADHD-workflow section: add two concise rules (~8 lines total) —
> **doc taxonomy** ("the lifecycle owns all pre-build documents: idea / reasoning note / plan /
> defect ARE the PRD/TRD/spec equivalents — never create a standalone PRD or TRD; shipped docs
> are post-build only, via `/draft-spec` for contracts and `/draft-guide` for prose, both
> emitting the six-field front-matter") and **retro-capture nudge** ("any session that made
> substantive code changes with no plan or defect referencing them should offer retroactive
> `/defect` or `/idea` capture before ending"). (2) `~/.claude/docs/adhd-workflow-guide.md`: add
> a "Documents" section with the two-layer taxonomy table (enterprise-doc → lifecycle-artifact
> mapping + the shipped-doc kinds and their writer skills), the six-field front-matter block,
> and update the stage walkthrough to mention the wrap-up doc nudge and standup's amnesty sweep
> + `<feature>` query. Match the guide's existing plain voice. Verify: read-back — CLAUDE.md
> additions ≤ ~8 lines; the guide renders the taxonomy table and mentions both new standup
> behaviors.
