# Plan Orchestrator — Subagent Per Slice - reasoning

**Decision:** Build it, as a new `/run-plan` skill, **strictly serial**, with the verification gate
implemented as a **script** rather than prose. One subagent per slice. The subagent edits files and
returns; it runs no checks, invokes no `/wrap-up`, and never touches the plan file. The
**orchestrator** — which never reads the diff and has no stake in it — runs the gate itself, reads
the exit code, commits, and appends ` ✅`. Any red, any missing check, any dirty tree, any "blocked":
halt, leave everything in place, report. Never auto-retry. The user pushes.

**Why:** The incumbent (`docs/notes/orchestrate-plan-slices-reasoning.md`) rejected autonomous
execution on two grounds. **Role collapse is now genuinely dead** — Claude Code subagents *are*
separate sessions, so the PM stance survives. **Independent verification was never a capability
problem**, and the new capability is *spawning*, not *witnessing*; that objection is cleared by a
different move entirely: make the witness a **process exit code**, and make the party that invokes
it a party with no stake in the outcome. Serial execution is what makes this possible — the tree was
green before the slice and is red after, so **that** slice broke it. Attribution is exact, with no
human and no interpretation. Parallel fan-out destroys precisely this property.

The user's intervention rate on real plans is near zero and the between-slice work is purely
mechanical (commit, push). Automating a step that contributes keystrokes and no judgment is what
automation is for.

## Options considered

- **A — Keep `/pjm run-plan` (incumbent)** — works, but has *no gate at all*: nothing checks the tree
  between slices except the user's eyes, and by their own account they aren't looking. It is not
  broken; it is tedious and unwitnessed. Retained as the escape hatch (see below), not as the
  primary path.
- **B — Parallel DAG fan-out with worktree isolation (the idea as filed)** — fails, and not on
  effort. **Isolation destroys verification.** Each agent verifies its own worktree, a tree that will
  never ship; slice A adds a config key, slice C asserts the config's key set, both green in
  isolation, red on merge, and no one ever ran a check against the merged state. A wave-level ` ✅` is
  then a claim about a counterfactual world. It also has no merge step, collides head-on with the
  no-auto-commit rule (a worktree's changes only leave it as commits), and delivers three diffs to
  review at once — converting serial machine time into *simultaneous human attention*, the scarcest
  resource in the system. Payoff on a real nine-slice plan was one wave of three.
- **C (chosen) — Serial batch runner, script gate, orchestrator as sole witness-invoker** — gives up
  all parallelism and buys back exact attribution, a machine-writable ` ✅`, a single writer on the
  plan file, per-slice commits, and an unambiguous resume point.

Two sub-options inside C were considered and rejected:

- **Subagents run `/wrap-up` and commit their own slice** (the user's first proposal) — this puts the
  party being judged in charge of its own trial. A subagent can run a narrower command than intended,
  misread red as green, delete the failing test, or simply assert it passed. None of that requires
  bad faith; it is what a helpful model does when it wants to succeed. Auditing it means reading the
  transcript, which is the review being automated away. Under serial execution the *concurrency*
  objection to leaf writes dissolves (one agent at a time, no race), but the epistemic one does not.
  **Move one thing and the design is sound: the orchestrator runs the gate.** Nothing the subagent
  *says* is then used for anything, so its trustworthiness stops mattering.
- **Subagents write the plan file** — dead on mechanics alone, before epistemics. The plan file is
  the only database and has no lock. Two writers, read-modify-write, lost update. Exactly one thing
  may write it, and it is never a leaf.

## The gate

**The check does not exist before the slice runs — the slice writes it.** Confirmed by grepping 122
`Verify:` clauses across real `ig-ratehub` and `workbench` plans: every one describes a test to be
authored ("a bundle test transforms…", "a unit test extracts…"), not a command to run. A naive
preflight would therefore go red because the *test file is missing*, not because the *behavior* is —
and at the exit-code level those are the same number.

`/promote`'s shipped red-gate papers over this by instructing the **execution session** to write the
test, run it, and "explicitly state **confirmed red**." That is a self-report by the party being
judged. It is the one place the system claims authorship independence and does not have it.

So: **two subagents per slice**, and the orchestrator witnesses every transition.

1. **Agent A — author the check only.** No implementation. Orchestrator runs it: must be **red**. Green
   means the check is vacuous or the work already exists → halt. Commit the check alone.
2. **Agent B — implement until green.** Fresh session. Orchestrator then runs, in order:
   - the slice's check → **green** (the slice did its work; a green *tree* proves nothing, since an
     agent that does nothing at all leaves a green tree);
   - the whole-tree suite → **green** (the slice broke nothing; green-before/red-after gives exact
     attribution, and only in serial);
   - `git diff` of A's committed check files → **empty**. B may not touch the test. This closes
     "delete the failing test to go green" mechanically, which was the last self-report hole in the
     design.

Then commit (one commit, slice id in the message), then ` ✅`.

Two agents per slice is affordable precisely because nothing is racing. This makes the runner
**strictly better at verification than the human-paced flow it replaces** — not merely faster.

The hard constraint holds because the user **explicitly accepted the verification in advance** — when
they authored the check at `/promote` time, with the intent loaded. The human moves from the exit gate
to the entry gate, which is where the intent actually lives.

## Two claims in the idea file that are false

Recorded so a future session doesn't rebuild on them. Both were offered as evidence that the
machinery is nearly free; both point the same direction, which is itself a signal.

- **"Every slice carries a `depends:` field."** No. `/promote` documents the line format
  (`**OPS-1 — title** · todo · depends: none`), but `/wrap-up` writes and `/standup` reads a heading
  format with no dependency field, and all five archived plans use the heading format. The DAG does
  not reliably exist. This does not matter for the chosen design: **slice order is the dependency
  graph**, it is already present in every plan ever written, and it needs no migration.
- **"`Run at:` maps onto per-agent overrides nearly directly."** Overstated. It appears once, as an
  optional per-slice override. Absence must inherit the plan's required `Model` / `Effort` header.

A **third** instance turned up on inspection: `/promote` documents `Verify:` as "a command, test, or
observable outcome," and every real clause is prose. So in three separate places the format the skills
document is not the format the plans use. **Any parser is being built against a contract that does not
hold.** `/run-plan` must validate the whole plan before running slice 1 and refuse to start, rather
than discover this at slice 4 with four commits on the branch.

General rule extracted, worth more than this feature: **every new field must have a safe default that
files written before it already satisfy.** A `depends:` field whose absence means "no dependencies"
would make every legacy plan fan out and shred itself. A `parallel-safe` marker whose absence means
"run in order" fails safe. Encode the exception, never the rule.

## Risks / open questions carried into the plan

- **The gate must be a script, not prose.** The orchestrator is a language model being asked to be a
  for-loop. A prose gate — "check that the tests pass" — is a suggestion made to something that wants
  to agree with you. One night it will decide a red test is unrelated and continue, helpfully,
  reasonably, at 2am, and destroy the independence, the attribution and the preflight-red in a single
  agreeable sentence. **If the script isn't written, don't build the runner.** Model judgment lives
  inside the subagent, where nothing it says is used.
- **Coverage is bounded by the red-gate's scope.** `/promote`'s red-gate applies to `Effort: high`+
  (or an opt-in `> Red-gate: yes`), with spike/doc/design slices exempt. Slices outside that scope
  have no executable check and the runner must halt on them. **Grep `Effort:` across real plans before
  building** — a machine that stops to ask a question every third slice is worse than pasting.
- **`/promote` needs one edit.** Today the red-gate names an executable check but says "the prose
  `Verify:` clause stays as the final gate." The runner's final gate must be a *command*. For
  red-gated slices, `Verify:` must be executable. This is a prerequisite slice, not a follow-up.
- **`/pjm run-plan` is not a duplicate — it is the handler for unwitnessable slices.** The two modes
  partition work by whether a machine witness exists. Do not delete it. Delete only the *loop*:
  `/pjm` reverts to what its first rule already says it is, a project manager that names the next
  thing, and now routes — witnessable slices to `/run-plan`, everything else to the user's hands.
  `/pjm`'s cardinal stance survives untouched; it never executed, and neither does the runner (the
  subagents do).
- **One gate, two callers, and prose cannot be factored.** Both `/run-plan` and `/wrap-up` flip ` ✅`
  and must apply the same checks. Do **not** give `/wrap-up` a "machine confirms instead of human"
  mode — that flag exists forever and one day a subagent finds it. Define the gate once as a named
  convention in `docs/notes/`, list it in `CLAUDE.md`'s conventions table beside ` ✅` and the
  `Model`/`Effort` header, and have both skills reference it. Weak, but it is how every other
  invariant here already survives across four skills.
- **Commit yes, push no.** A local commit is reversible (`git reset`); a push is outward-facing and
  is not. The no-auto-commit rule exists to keep agents out of the user's history and off their
  remotes. Let the runner commit on the branch; the user pushes. That relaxes the rule's letter and
  keeps its purpose — and it is *required*, not optional: in a shared tree with no commits, nine
  sequential slices produce **one diff**, and per-slice ` ✅` presumes a per-slice artifact that does
  not exist. Nine commits are far more unwindable than one dirty tree.
- **Git log is the in-flight state; the plan file is the durable state.** Tree and marker cannot be
  updated atomically (dual write). Work-then-mark loses a slice to a crash; mark-then-work leaves a
  silent hole. Commit-per-slice makes the commit the record: on resume, the last commit is the last
  completed slice and anything dirty on top is a partial slice to discard.
- **Resume requires a clean tree.** After a halt, the orchestrator cannot tell the failed slice's
  leftovers from the user's fix. It must refuse to start dirty. The user commits the fix or
  `reset --hard`s. That forces an explicit declaration of intent and costs nothing.
- **The plan file is hand-edited between turns.** Read once; write by matching the **slice id**, never
  a line number; re-read before each write and **abort** if the heading moved. Do not attempt to
  reconcile — merging a user's edits against an in-flight run is a research project. "The file moved
  under me, here's what finished, you drive" is always correct.
- **The orchestrator must hold no context.** Never read a diff, never read a subagent's full output.
  Slice id, exit code, sha. Each report goes straight to disk. An orchestrator that "reviews" its
  subagents' work is the rejected design wearing a new hat, and over a nine-slice run it will compact
  away exactly the early detail the user needs.
- **The runner must refuse where there is no whole-tree check.** No build, no tests, nothing that can
  exit non-zero → halt with "this repo has no witness." **This repo is that repo.** `adhd-workflow`
  has no build and no test suite; the gate has nothing to run here. The skill can be *written* here.
  It cannot be *dogfooded* here — unless the gate script itself becomes this repo's first executable
  and first test, which would be a deliberate change to what this repo is. Make it on purpose.
- **Ship additively, subtract later.** Skills are symlinked live; a new skill changes nothing until
  called, but editing `/pjm` is a production change in every repo, next session. Add `/run-plan`. Run
  it on three real plans. *Then* remove the loop from `/pjm`, with data on how much of the work it
  actually covers.
- **Stamp ` ✅` with its provenance** — `✅ (pnpm test, a1b2c3d)` vs `✅ (ken, 2026-07-09)`. Today ` ✅`
  is a fact with no source, and a reader three weeks later cannot tell how much to trust it. That
  defect exists whether or not this gets built.
- **There is no fixture namespace.** `docs/plans/` is the database, and `/standup` sweeps it, counts
  it against WIP=2, and `/audit-plans` flags it stale. A smoke-test plan is test data living in
  production: tomorrow morning `/standup` will tell the user to go work on it. Adopt a leading
  underscore (`docs/plans/_smoke-run-plan.md`), skipped by `/standup` and `/audit-plans`, matching the
  existing `_done/` convention. One line in two skills.
- **The runner cannot bootstrap itself.** The gate script is what makes the runner safe, so slices 1–2
  (write the gate + its shell tests) must be done **by hand**, the way everything is done today. Only
  then does the runner take over, gated by the thing it just helped build.
- **The smoke test must not double as the acceptance test.** A suite authored *in order to be gated by
  this runner* is not an independent witness of the runner — the tests get shaped, unconsciously,
  toward what the gate can check. Smoke the loop mechanics here, on the gate script's own shell tests.
  Do the first real drive in a repo whose suite predates the runner (`workbench`, `pnpm test`), on a
  throwaway two-slice plan where **slice 2 is deliberately made to fail** — halt-and-resume is the
  path that will actually be depended on and the one nobody ever tests.
- **Near-zero intervention may measure detection, not reliability.** It is also what a blind feedback
  loop looks like: nothing between slices was checking. Before the first run, sweep `docs/defects/`
  and recent plans for a defect that traces back to work an earlier slice had already claimed done.
  If any exist, the runner will scale the blindness, not the throughput.

## Parallelism: explicitly not built

No DAG, no `depends:`, no `parallel-safe` marker, no worktrees, no merge step. Slice order is the
graph. Revisit only if **all three** hold: `/run-plan` has completed several real plans; the halt rate
is low enough that unattended runs actually finish; and a real plan shows a wave wide enough to pay
for a merge step and the loss of green-before/red-after attribution. The last one is the hard part —
parallelism does not merely cost safety, it costs the only oracle the design has.

---

Reasoned 2026-07-09 via `/design-workshop` (architecture flavor), adversarial session. Supersedes
`docs/notes/orchestrate-plan-slices-reasoning.md` **in part**: its role-collapse objection is retired
(the surface now supports separate execution sessions); its verification objection **stands** and is
satisfied here, not waived. Its rule — "`/wrap-up` remains the only thing that marks slice headings
done" — is *amended*: the gate, not the skill, is what protects the marker, and the gate is now a
script. Builds directly on `docs/notes/tdd-first-tasks-worktree-isolation-reasoning.md`, whose
red-confirmed executable check `/run-plan` mechanically enforces for the first time.
