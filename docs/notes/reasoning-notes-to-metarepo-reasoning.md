# Move Reasoning Notes To The Metarepo — reasoning

**Decision:** Drop the reasoning-note carve-out. A `*-reasoning.md` note follows the resolved docs
root like every other lifecycle doc — metarepo when one is configured, `./docs/notes/` otherwise —
and inherits the metarepo's auto-commit-and-push. Durable design/decision/reference docs stay in
the code repo's `docs/notes/`; they were never in scope.

**Why:** The carve-out's stated reason — the note lives in the code repo "because that is where it
gets consumed" — proves too much. Plans are consumed in the code repo too (their task strings name
code-repo paths, and `/run-plan` executes them against code-repo files), and plans live in the
metarepo without trouble. Consumption location was never the test. Ownership lifecycle is, and a
reasoning note's lifecycle is identical to an idea's: written by a lifecycle skill, read by the
next lifecycle skill, deleted when it has been consumed. It belongs where ideas, plans, and
defects already live.

The cost of the carve-out is concrete and recurring: `/reason` writes an uncommitted file into the
code repo, and `skills/run-plan/SKILL.md:49` (step 0, check 4) refuses to start on a dirty tree.
So the reasoning gate reliably blocks the execution stage that follows it. Writing *this* note
dirtied the worktree in exactly that way.

## Options considered

- **A — Move reasoning notes to the metarepo (chosen).** Removes the friction at its source: the
  metarepo's existing commit-and-push rule keeps the code repo clean, with no new exception to the
  no-auto-commit rule. Collapses two dialects of "where does a lifecycle doc live" into one. Costs
  a coordinated edit across ten skills, and needs a stated convention for how a plan in the
  metarepo cites a note in the metarepo.

- **B — Keep the note in the code repo and auto-commit it there.** Preserves the current
  convention and keeps the note next to the code. Rejected: it extends auto-commit from the
  metarepo into the code repo, where the standing rule is that the human commits. It would drop a
  lone docs commit onto whatever feature branch happens to be checked out — a bigger and more
  surprising change than moving a file, in exchange for keeping a rationale that does not hold up.

- **C — Relax `/run-plan`'s clean-tree gate to ignore `docs/notes/`.** Cheapest by far: one check
  in one skill. Rejected: it treats the symptom. The tree is still dirty, so anything else that
  reads a clean tree — CI, another harness, the user's own read of `git status` — still trips. It
  also erodes a gate that exists to protect attribution, to accommodate a file that has no reason
  to be there. Note that the *postflight* gate is already scoped to check paths
  (`scripts/slice-gate.sh:134`), so this option buys nothing for attribution safety that the gate
  does not already have.

## Risks / open questions carried into the plan

- **Ten skills carry the carve-out sentence verbatim** (`wrap-up`, `run-plan`, `promote`,
  `standup`, `diagnose`, `idea`, `audit-plans`, `defect`, `pjm`, `reason`). They must change in one
  commit or the lifecycle splits into two disagreeing halves. The global `CLAUDE.md` paragraph "A
  reasoning note is interim state" states the same rule and is the user's own file — needs their
  edit or explicit sign-off.

- **Scope boundary must be explicit in the plan:** only `*-reasoning.md` lifecycle notes move.
  `docs/notes/slice-gate-convention.md` is a durable reference doc and stays. If the plan does not
  name this boundary, the next reader will move the whole directory.

- **Citation paths become cross-repo.** `/promote` writes a `Design authority: <path>` line and
  `/wrap-up` (skill lines 131, 143–144) scans for inbound citations, already warning that a bare
  `docs/notes/<file>` pattern wrongly matches `other-repo/docs/notes/<file>`. The plan must state
  how a plan cites a note once both live in the metarepo, and update that matching rule.

- **`/wrap-up` step 4 deletes the note** when a plan completes. In the metarepo that delete is a
  commit-and-push, and its "fix every inbound citation in the same commit" requirement now spans
  two repos. Its four hold-back blockers need re-reading against the new location.

- **`/draft-guide` explanation mode** consumes a note by path (skill lines 38, 121, and its
  `description`) and stamps it as `source:`. It must resolve the docs root rather than assume
  `docs/notes/`. `/audit-plans` check #9 (stale reasoning notes) has the same assumption.

- **The no-metarepo path must stay byte-identical to today.** Published users fall back to
  `./docs/notes/`, unchanged. If the fallback drifts, the carve-out comes back wearing a
  different name.

- **Nine existing notes in this repo's `docs/notes/`** need a migrate-or-leave call. Leaving them
  is defensible (they are already committed, so they dirty nothing) but leaves two locations in
  play during the transition.
