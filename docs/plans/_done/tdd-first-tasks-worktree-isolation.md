# TDD-first task strings + worktree isolation — red-gated acceptance checks and contamination-proof slice execution

> Status: **done** · created 2026-07-08 · started 2026-07-08 · completed 2026-07-08
> Model: fable · Effort: medium
> Home: cross-repo system (skills are global in `~/.claude/skills/` + `~/.claude/commands/`), so
> the plan lives in the dotfiles repo. Every slice edits `~/.claude` only.
> Why: post-hoc `Verify:` lets a cold execution session grade its own homework (anchored/vacuous
> tests, premature "done"), and parallel sessions have already contaminated a shared working tree.
> Reasoning: `docs/notes/tdd-first-tasks-worktree-isolation-reasoning.md` — its decision
> (independence + red-gate, effort-scaled; worktrees as a `/pjm` offer, not a mandate) and carried
> risks are inputs here, not up for re-litigation.

## Definition of done

`/promote` authors task strings whose acceptance checks are executable and red-confirmed-first for
Effort `high`+ plans (prose `Verify:` unchanged for lower tiers and exempt slice types); `/pjm`'s
branch mechanics offer a git worktree instead of an in-place checkout, defaulting to worktree when
parallel sessions are likely; `/wrap-up` and the `/pjm` day-close handle worktree lifecycle (merge-
back, cleanup, stranded-worktree detection); the plain-language walkthrough doc describes both.
Repos whose existing plans lack `Model`/`Effort` headers degrade gracefully (no red-gate, no error).

## Acceptance criteria

- [ ] Promoting an Effort-`high` idea produces task strings that open with a named failing test to
      write first, and instruct the session to run it, see red, and *say so* before implementing.
- [ ] Promoting an Effort-`low`/`medium` idea produces task strings unchanged from today's shape.
- [ ] Spike/doc/design slices are exempt even in `high` plans, with the exemption stated in the skill.
- [ ] On a slice start, `/pjm` offers "worktree or in-place branch?", recommending worktree when
      another session is (or is likely) active.
- [ ] After a slice finishes in a worktree, `/wrap-up` offers merge-back + `git worktree remove`;
      a forgotten worktree shows up in the `/pjm` day-close loose-end sweep.

---

### TDDW-1 — `/promote`: red-gate authoring rule for task strings ✅

> task: Edit `~/.claude/skills/promote/SKILL.md`. In the task-decomposition guidance (step 4 + the house-format section), add a **red-gate authoring rule**: when the plan's `Effort` is `high`, `xhigh`, or `max`, each correctness-sensitive task's `task:` string must OPEN with the executable acceptance check — name the concrete test file/case to write FIRST (sketching the key assertions in the task string itself where the contract is known at planning time), and instruct the execution session to run it, confirm it FAILS, and explicitly state "confirmed red" before writing any implementation. The prose `Verify:` clause stays as the final gate (unchanged role). Add the exemptions verbatim: spike/exploratory, doc, and design slices are exempt even in `high`+ plans — where the spec is the output, there is nothing to red-test; the task string should say which exemption applies. Add graceful degradation: plans/repos without an `Effort` header get no red-gate (never refuse or warn a legacy repo over it). Add one sentence of rationale so future edits don't strip it: independently-authored checks decorrelate spec-misread errors; the red run catches vacuous tests; this is deliberately NOT full TDD (no micro-cycles, no delete-premature-code rule) per the reasoning note. Also add `medium` opt-in: a plan may carry a `> Red-gate: yes` header line to apply the rule below `high`. Verify: read-back shows the rule, exemptions, degradation, opt-in, and rationale in the skill; then draft (do not save) a sample task string for a hypothetical Effort-`high` money-path task and confirm it opens with the named failing test + "confirm red and say so" instruction, and a sample for an Effort-`medium` plan without the opt-in header and confirm it is unchanged from today's shape.

### TDDW-2 — `/pjm`: worktree offer in branch mechanics ✅

> task: Edit `~/.claude/skills/pjm/SKILL.md` § Branch mechanics. Where the skill currently offers to cut `feature/<plan-id>-<slug>` off fresh `main`, extend the offer to a choice: in-place branch checkout (today's behavior) OR an isolated worktree — `git worktree add ../<repo>-wt-<plan-id> -b feature/<plan-id>-<slug> main` (sibling dir naming convention `<repo>-wt-<plan-id>`). State when to RECOMMEND the worktree: another session is or is likely to be active in the repo this session (the parallel-session working-tree contamination case), or the slice will run concurrently with other work; otherwise recommend the plain branch (worktrees are not mandatory — cite the reasoning note's rejection of always-worktree). The pbcopy'd handoff must then include the worktree path so the fresh execution session starts in the right directory. Add to the Day-close loose-end sweep: `git worktree list` — flag worktrees whose branch is merged (offer `git worktree remove` + branch prune) and worktrees with uncommitted work (surface, never clean silently). Verify: read-back shows the two-option offer with the recommend-when rule, the naming convention, the handoff-includes-path requirement, and the day-close `git worktree list` sweep.

### TDDW-3 — `/wrap-up`: worktree-aware slice completion ✅

> task: Edit `~/.claude/commands/wrap-up.md`. Step 1 (reconcile plan status) currently assumes the slice ran on a branch in the main checkout. Add worktree handling: detect a worktree context (`git rev-parse --git-common-dir` differs from `.git`, or the cwd matches the `<repo>-wt-<plan-id>` convention from `/pjm`); after the slice's status reconciliation, offer the finish sequence — ensure work is committed on the slice branch, then hand back to the main checkout for merge/PR (never merge silently), then offer `git worktree remove <path>` once the branch is merged or pushed. Flag — never auto-clean — a worktree left with uncommitted changes. Keep the cardinal never-flip-silently rule intact; this is an ADD to step 1, not a rewrite. Verify: read-back shows worktree detection, the commit→merge-back→remove offer sequence gated on confirmation, and the uncommitted-work flag.

### TDDW-4 — Walkthrough guide: document both behaviors ✅

> task: Edit `~/.claude/docs/adhd-workflow-guide.md` (the plain-language walkthrough of the workflow system). Add short sections describing (a) the red-gate: high-effort plans ship task strings that start with a failing test, why (the execution session can't grade its own homework), the exemptions, and that low-effort work is deliberately untouched; (b) worktree isolation: when `/pjm` offers a worktree, the sibling-dir naming, and how `/wrap-up` closes one out. Match the guide's existing plain, non-jargon voice; keep the two sections to a few paragraphs total. Verify: `grep -n "red\|worktree" ~/.claude/docs/adhd-workflow-guide.md` shows both sections, and read-back confirms the described behavior matches what TDDW-1/2/3 actually put in the skills (write this slice LAST).
