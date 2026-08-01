# Run /code-review and /simplify after /run-plan completes — reasoning

**Decision:** `/run-plan` **recommends** the quality pass in its end-of-run report; it never
invokes one. On a **clean completion only**, the report names the order **`/simplify` → re-run the
plan's `> Check:` command → `/code-review`**. Nothing is added to the per-slice loop, and no
skill gains a dependency on a slash command that may not exist.

**Why:** `/simplify` *applies fixes*. Any edit after a slice's postflight invalidates its
` ✅ (<command>, <sha_A>)` stamp — the marker names a command that went green against a tree that
no longer exists. And a code review is a model verdict about a diff, which is precisely what
`/run-plan`'s §2 invariants forbid the orchestrator from acting on. Recommending keeps both out
of the gated path while still putting the pass in front of the user at the moment it's useful.

## What I verified (not assumed)

- The installed `code-review:code-review` is a **plugin command that reviews a GitHub pull
  request** — it drives `gh pr diff` / `gh pr view` and posts a PR comment
  (`~/.claude/plugins/marketplaces/claude-plugins-official/plugins/code-review/commands/code-review.md`).
  `/run-plan` commits and **never pushes** (§1), so there is no PR at end-of-run. That variant
  cannot run there at all.
- The working-diff `/code-review` — the one `/simplify`'s and `/review`'s own descriptions point
  at — is a CLI built-in with no file on disk. Its `ultra` form is documented as
  "user-triggered and billed; you cannot launch it yourself."
- `/simplify` is likewise a built-in with no `SKILL.md`. Neither exists in Codex, and these
  skills are dual-provider by design. A hard invocation dependency would silently no-op for
  other installs.
- There *is* a model-invocable path: the installed **`code-simplifier` agent** (Agent tool),
  which `/run-plan` already knows how to spawn. That makes option B below mechanically possible —
  it is rejected on design grounds, not capability grounds.

## Options considered

- **A — inside the per-slice loop** (simplify + review after each slice) — breaks both
  invariants at once: post-stamp mutation on every slice, and a model verdict inside the gated
  loop. Also multiplies cost by slice count and buries the run in findings.
- **B — a post-run stage inside `/run-plan`** that spawns the `code-simplifier` agent, re-runs
  the whole-tree check, then spawns a review agent. Mechanically possible, and the orchestrator
  already spawns agents. Rejected: it puts the orchestrator back in the business of deciding
  which findings to act on, and simplify's edits land as an unstamped commit outside any slice —
  so every ` ✅` in the plan now describes a tree that no longer exists. Fixing that honestly
  means a re-gate stage: new machinery and new invariants around the one thing this repo got
  right.
- **C — recommend in the end-of-run report (chosen)** — `/run-plan` §5 already ends with a
  report and §6 already invokes `/wrap-up`. One line in that report costs nothing, adds no
  invariant, creates no dependency that breaks in Codex, and hands the human the pass at the
  same moment `/wrap-up` hands them the reconciliation seat.
- **D — attach the review half to `/ship` instead** — `/ship` opens the PR, where the PR-based
  `code-review:code-review` works natively. A good follow-on, but it does not answer the question
  asked: the pass wanted is on the run's output, *before* the PR.

## Order — the idea's open question

**Simplify first, then review. Not both, not review-first.**

Simplify rewrites; review reads. Reviewing first means reviewing code that is about to change,
then re-reviewing after. Simplifying after a review can undo or invalidate the findings you just
paid for. `/simplify`'s own description settles it — it does quality only and defers bug-hunting
to `/code-review` — so the sequence simplify → whole-tree check → code-review reads the final
tree exactly once. A "both" sandwich doubles the cost and buys nothing.

## Risks / open questions carried into the plan

- **Clean completion only.** A halt leaves a red tree; recommending a quality pass on a red tree
  is wrong. The line must be suppressed on both halt kinds (red-gate and question).
- **The stamps go stale if the user accepts simplify's edits.** The recommendation has to say
  so plainly and tell the user to re-run the plan's `> Check:` command afterward. Open: whether
  that is only a sentence in the report, or also a line appended to the plan file recording that
  the tree moved after stamping.
- **Two things are named `code-review`.** The plan must name which one it means (the working-diff
  built-in), and degrade to saying nothing — not to a broken instruction — when neither the
  built-in nor the plugin is available (Codex, or a fresh install).
- **Scope to `/run-plan` only.** `/wrap-up` also runs after hand-driven slices; putting the same
  line there would nag once per slice. Leaning `/run-plan`'s report alone, but the plan should
  make that call explicitly.
