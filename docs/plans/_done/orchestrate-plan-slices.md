# Orchestrate plan slices - checkpointed plan driving from `/pjm`

> Status: **done** · created 2026-07-09 · started 2026-07-09 · completed 2026-07-09
> Model: OpenAI gpt-5.5 · Effort: high
> OpenAI: gpt-5.5 · Effort: high
> Claude: claude-opus-4-8 · Effort: high
> Recommended: OpenAI gpt-5.5 · high for this Codex session; use Claude claude-opus-4-8 · high when running from Claude Code.
> Why: reduce manual driver overhead while preserving the workflow's checkpoint discipline and execute-elsewhere separation.
> Reasoning: `docs/notes/orchestrate-plan-slices-reasoning.md` - its decision to build a checkpointed `/pjm` orchestration mode, not a fully autonomous executor, is the plan constraint.

## Definition of done

`/pjm` supports a checkpointed plan-orchestration mode that can be invoked for a named plan, picks the next open slice from that plan without bypassing `/standup`'s WIP and nearest-finish-line rules, prepares the same provider-aware handoff and branch/worktree setup as ordinary PJM turns, stops at every confirmation or dirty-state checkpoint, and resumes after `/wrap-up` marks each slice done until the plan is complete.

## Acceptance criteria

- [ ] A user can ask `/pjm run-plan <plan>` or equivalent and get the next open slice for that named plan, not a vague menu.
- [ ] The mode never executes slice work in the PJM session and never marks a slice done directly; `/wrap-up` remains the only slice-completion marker.
- [ ] The mode stops for failed verification, dirty worktrees, missing route/model headers, blocked slices, branch/merge ambiguity, and commit/push/archive confirmations.
- [ ] The handoff includes the provider route, model, effort, clipboard task string, and branch/worktree recommendation just like ordinary `/pjm`.
- [ ] The public workflow docs explain the mode without implying full autonomous execution.

---

### OPS-1 - Define `/pjm run-plan` as a checkpointed orchestration mode ✅

> task: Doc/skill-prose slice; red-gate exemption applies because the workflow contract is the output. Edit `skills/pjm/SKILL.md` to add a plan-orchestration mode for `/pjm run-plan <plan>` or the closest trigger phrase that fits the skill's existing dispatch style. The mode must explicitly say it manages and delegates, not builds; it targets one named plan; it re-sweeps state every turn; it uses `/standup` rules for WIP=2, nearest finish line, stalled/drift checks, and completion checks; and it refuses to bypass `/wrap-up` for slice completion. Include the stop checkpoints from `docs/notes/orchestrate-plan-slices-reasoning.md`: failed verify, dirty worktree, missing route/model header, blocked slice, branch/merge ambiguity, and user confirmations for status/commit/push/archive. Verify: read back `skills/pjm/SKILL.md` and confirm the new mode names the trigger, the target-plan behavior, the execute-elsewhere boundary, `/standup` rule inheritance, `/wrap-up` as the only slice-done path, and every stop checkpoint.

### OPS-2 - Teach the orchestration loop to prepare and resume handoffs ✅

> task: Doc/skill-prose slice; red-gate exemption applies because this is workflow instruction text. Edit `skills/pjm/SKILL.md` so the `/pjm run-plan <plan>` loop says exactly how to prepare each handoff: find the first open slice in the named plan, pbcopy the verbatim `task:` string, show it inline, echo both provider routes plus the recommended default, offer branch setup using the existing in-place/worktree mechanics, and when a worktree is chosen prefix the copied task with the worktree path. Add the resume rule: after the execution session runs `/wrap-up`, the user returns to the same PJM session and asks to continue the run-plan loop; PJM re-sweeps the plan and either hands off the next open slice or offers plan completion/archive when all slices are marked ` ✅`. Verify: read back the new section and confirm it covers clipboard, inline task, provider route, branch/worktree setup, worktree path prefix, resume after `/wrap-up`, and all-slices-done behavior.

### OPS-3 - Align `/standup` trace/pick wording with plan orchestration ✅

> task: Doc/skill-prose slice; red-gate exemption applies because this updates workflow instructions only. Edit `skills/standup/SKILL.md` narrowly so its feature trace and `▶ NEXT` guidance stay compatible with a PJM plan-run mode: trace mode should make it easy for PJM to locate a named plan and its lifecycle position, while the normal pick remains global and still enforces nearest-finish-line. Do not make standup a plan runner, do not add a second WIP policy, and do not let `/standup <plan>` silently start or advance a plan. Verify: read back `skills/standup/SKILL.md` and confirm trace mode remains lifecycle-only, normal standup still owns the global `▶ NEXT`, WIP=2 is unchanged, and the wording supports PJM using standup's analysis without duplicating it.

### OPS-4 - Update `/wrap-up` handback wording for plan-run resumes ✅

> task: Doc/skill-prose slice; red-gate exemption applies because this is command prose. Edit `commands/wrap-up.md` so the final handback step recognizes a slice that came from `/pjm run-plan <plan>`: after reconciling status and capture, tell the user to return to the PJM session and continue the same plan-run loop, not to start fresh or let wrap-up pick the next slice. Preserve the current rule that wrap-up does not run standup unless the user is not using PJM, and preserve confirmation gates for marking slices done, committing, pushing, merging, archiving, and worktree cleanup. Verify: read back `commands/wrap-up.md` and confirm it names the plan-run handback, keeps `/pjm` as the driver, keeps `/standup` only as fallback, and leaves all confirmation gates intact.

### OPS-5 - Document and smoke-check the workflow ✅

> task: Doc/verification slice; red-gate exemption applies because this is documentation plus read-back validation. Update `docs/adhd-workflow-guide.md` and `README.md` only where they describe execution driven by `/pjm`, adding a concise explanation that `/pjm run-plan <plan>` can drive one plan slice-by-slice through checkpointed handoffs while still requiring fresh execution sessions and `/wrap-up` after each slice. Then run a markdown smoke check by reading `skills/pjm/SKILL.md`, `skills/standup/SKILL.md`, `commands/wrap-up.md`, `docs/adhd-workflow-guide.md`, and `README.md` back together and tracing a tiny imaginary two-slice plan: first slice open -> handoff -> `/wrap-up` marks ` ✅` -> return to PJM -> second slice handoff -> all slices done -> completion/archive offer. Verify: final report lists the read-back files and confirms the trace stops at every required checkpoint and never claims full autonomous execution.
