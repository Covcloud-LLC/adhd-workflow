# Update the workflow guide for /run-plan and the slice gate

> created 2026-07-09 · captured by /wrap-up (doc-work queue from the plan-orchestrator plan)

`docs/adhd-workflow-guide.md` — the plain-language walkthrough readers install from — predates
`/run-plan`. It doesn't mention the sixth command, the slice gate, the Check/Build task split
`/promote` now authors, or the `> Check:` plan header. Someone installing the skills today gets
a runner the guide never explains.

Doc work, not code: a `/draft-guide` pass (how-to/brief mode) over the guide.

- **Audience:** people who install the workflow (the repo's public readers).
- **Sources:** `skills/run-plan/SKILL.md`, `docs/notes/slice-gate-convention.md`,
  `docs/notes/plan-orchestrator-subagent-per-slice-reasoning.md`,
  `docs/plans/_done/plan-orchestrator-subagent-per-slice.md` (RUN-6/RUN-7 report blocks).
- **Non-blocking** — queued as a nudge, not a contract-change spec task.
