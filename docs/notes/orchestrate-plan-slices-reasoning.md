# Orchestrate Plan Slices - reasoning

**Decision:** Build this as a checkpointed orchestration mode around `/pjm` rather than as a fully autonomous executor. The useful thing is not "do every slice without the user"; it is "keep choosing the next slice, preparing the right handoff, waiting for verified completion, reconciling status through `/wrap-up`, and then continuing." The first implementation should probably be `/pjm run-plan <plan>` or a thin `orchestrate-plan` skill that explicitly delegates to `/pjm`, `/standup`, and `/wrap-up`.
**Why:** `/pjm` already owns the driver seat: re-sweeping state, choosing the nearest finish line, copying task strings, advising model/effort, and offering branch/worktree setup. A parallel command that bypasses those rules would duplicate the workflow's most load-bearing guardrails.

## Options considered
- **Standalone command that executes all slices automatically** — tempting, but it collapses PM and execution into one session, risks marking work done without independent verification, and fights the reason this workflow uses fresh execution sessions.
- **New top-level `orchestrate-plan` skill** — clearer trigger and easier to discover, but likely duplicates `/pjm` unless it is explicitly a wrapper around the existing driver.
- **`/pjm` orchestration mode (chosen)** — keeps one driver, one WIP policy, one branch/worktree setup path, and one wrap-up handoff while reducing manual "what next?" repetition.

## Risks / open questions carried into the plan
- The orchestration loop must stop at every checkpoint that needs judgment: failed verify, dirty worktree, missing route/model header, blocked slice, branch/merge ambiguity, or user confirmation for status/commit/push/archive.
- The tool should not pretend Codex can safely spawn and supervise independent execution sessions unless the actual surface supports that. MVP should produce paste-ready handoffs and resume from plan state after the user reports completion.
- `/wrap-up` remains the only thing that marks slice headings done. Orchestration may invoke or route to it, but must not silently append ` ✅`.
- Decide whether the public trigger is `/pjm run-plan <plan>` only, or a small `orchestrate-plan` skill whose body says "delegate to `/pjm` orchestration mode."
- The plan should include a smoke run on a tiny two-slice markdown-only plan to prove the loop stops and resumes correctly.
