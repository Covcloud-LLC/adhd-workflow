# TDD-First Task Strings and Worktree Isolation — reasoning

**Decision:** Don't adopt TDD as a mandate. Adopt the narrower principle that survives the agentic
translation: **independently-authored, executable acceptance checks, red-confirmed before
implementation, gated by the plan's Effort tier** — templated into `/promote`'s task-string
authoring rules. Worktree isolation lands as an option in `/pjm`'s branch mechanics (offer a
worktree instead of a branch checkout when cutting a slice), not as a mandatory phase.

**Why:** The parts of TDD that manage human psychology don't transfer to agents; the part that
does — author the check before the implementation exists — attacks failure modes that are *worse*
in agents: anchoring (post-hoc tests assert what the code does, encoding the agent's own bugs into
green tests), vacuous tests (mocking the thing under test — a confirmed-red first run catches this
mechanically), and premature victory claims (a pre-existing failing test is an objective gate the
agent can't talk past). The load-bearing property is **authorship independence**, not temporal
ritual: if the same context misreads the spec, it writes a wrong test and implements to it —
correlated errors. `/promote` already authors `Verify:` clauses cold, from the idea and reasoning
note, before any execution session exists — the gap is only that they're prose instead of
executable contracts.

## Options considered

- **A — Full Superpowers-style TDD mandate** (RED-GREEN-REFACTOR micro-cycles, delete code written
  before a failing test) — fails: the micro-cycle cadence is a human working-memory prosthetic
  (agents hold the full spec in context; forcing 2–5-minute cycles is token burn); "delete
  premature code" is discipline theater for a boredom problem agents don't have; same-agent
  test-first still leaves spec-misread errors correlated; and ceremony on trivial slices is how
  process gets skipped on all slices.
- **B (chosen) — Independence + red-gate, effort-scaled** — for correctness-sensitive slices
  (Effort `high`+), the task string names the concrete failing test to write first (ideally
  sketching its assertions in the plan itself), with red confirmed before implementation. Low-tier
  mechanical slices keep plain post-hoc `Verify:`. Keeps the agent-failure-mode protection, drops
  the human-ergonomics ritual.
- **C — Status quo (prose `Verify:` only)** — fails: post-hoc, and the execution session grades
  its own homework; nothing catches a vacuous or anchored test; "done" claims rest on the agent's
  self-report.

**Worktree isolation:**
- **A — Mandatory worktree per slice** (Superpowers phase 2) — fails: overhead for the common
  single-session case; most slices don't run concurrently.
- **B (chosen) — Offered in `/pjm` branch mechanics** — when cutting a slice branch, offer a
  worktree instead of a checkout, defaulting to yes when another session is (or is likely to be)
  active. Directly addresses the parallel-session working-tree contamination that already bit us
  once on a real project.
- **C — Do nothing** — the contamination risk is recurring, not hypothetical.

## Risks / open questions carried into the plan

- Exact edit surface: `/promote` (task-string template gains the failing-test-first instruction for
  Effort `high`+; standard exemptions for spike/doc/design slices where the spec is the output),
  `/pjm` step 5 (worktree offer + naming), possibly `/standup` (echo the check type on `▶ NEXT`).
- Phrasing matters: the task string must make a cold session *confirm red and say so* before
  implementing — otherwise the instruction degrades into post-hoc testing.
- Effort-tier threshold: default `high`+ for the red-gate; confirm whether `medium` money-path
  slices should opt in per-plan.
- Worktree lifecycle: cleanup/merge-back flow and how `/wrap-up` handles a slice finished in a
  worktree (stranded-work detection currently assumes branches).
- These are global skills used across repos — roll out without breaking repos whose plans have no
  Effort headers yet.

Reasoned inline 2026-07-08 (session comparing the workflow system against obra/superpowers v6.x);
the synthesis above imports that assessment.
