# Promote: plain-language brief + decision-delta section — reasoning

**Decision:** Fix plan-vs-intent drift inside `/promote`, not with a new lifecycle stage. Two
additive sections in the house format — a plain-language `## What this plan will actually do`
brief (1–2 present-tense sentences per slice, no file paths) and a `## Decisions this plan makes`
delta list (every choice the decomposition introduced that the reasoning note didn't settle) —
plus a mandatory read-back of both sections that gets the user's yes **before** the plan file is
written. Optionally, `/run-plan` echoes the brief at launch.

**Why:** The drift is born during `/promote`'s decomposition — turning an approach into slices
forces micro-decisions (file layout, scope in/out, contract shapes, ordering) that were never
reasoned, and today they live only inside machine-shaped `task:` strings the user can't skim.
The rubric checks the plan *runs cold*; nothing checks it *matches intent*. Put the human
checkpoint exactly where the unreasoned decisions are created, and make it cheap.

## Options considered

- **A — new lifecycle stage (a "design"/"brief" step between `/reason` and `/promote`)** — fails:
  adds friction to every idea, against the system's scaled-minimalism principle; and it sits
  *before* the decomposition, so it can't review the micro-decisions that don't exist yet. The
  drift it's meant to catch is created downstream of it.
- **B — additive sections + pre-write read-back in `/promote` (chosen)** — the checkpoint lands
  at the moment the decisions are made, by the session that made them, while the "why" is still
  in context. Additive to the house format, so `/run-plan`, `/standup`, `/wrap-up`, and
  `/audit-plans` (which key on headers and `### <ID>-n` slice headings) keep working unchanged.
  Also honors the doc-taxonomy rule: the plan stays the single pre-build artifact — no standalone
  brief doc.
- **C — late gate only (`/run-plan` preflight ack)** — fails as the primary fix: it fires after
  the plan aged in `todo`, does nothing at authoring time, and cuts against `/run-plan`'s design
  (no human between slices; observed intervention rate ≈ 0 means an ack prompt there gets
  rubber-stamped). Kept only as an optional echo — print the brief, don't block on it.

## Design decisions settled here (so the plan doesn't re-litigate)

- **Both sections are required in new plans.** Plans without them are *readable legacy*, never
  malformed — same treatment as the old four-line model header. `/audit-plans` flags for
  migration; nothing refuses to run them.
- **Section order:** brief goes right after `## Definition of done`; decision-delta directly
  after the brief. Both above the `---` that starts the slices.
- **The brief is written after the slices are drafted,** as a human-readable mirror of the
  `task:` strings — never before. A brief↔task-string mismatch is a bug in the plan.
- **An empty delta must be explicit:** "None — the reasoning note settled everything." An empty
  section proves the check ran; a missing one doesn't.
- **The read-back happens before the file is written.** This matters in metarepo mode, where
  every write is auto-committed and pushed — read-back-then-write avoids push-then-amend churn.
  Keep it one message (brief + delta + "write it?"), not an interrogation.
- **Edit surface:** `promote/SKILL.md` (house format + steps + rubric line), `audit-plans/SKILL.md`
  (one flag rule), `run-plan/SKILL.md` (optional launch echo). Nothing else reads these sections.

## Risks / open questions carried into the plan

- **Brief drift on later plan edits.** Nothing re-verifies brief↔task-string consistency after
  promotion (e.g. a hand-edited slice). Cheapest mitigation: an `/audit-plans` spot-check line.
  Decide in the plan whether that's v1 or deferred.
- **Read-back friction.** If the read-back turns into a second rubric, small plans get expensive
  and the gate gets skipped. It must stay one message, one yes.
- **Source of past surprises is unconfirmed** (visible-but-unparsed task strings vs. executing
  agents exceeding them). Note: `/run-plan` has driven ~0 real external plans so far, so the
  surprises came from hand-run execution sessions. The brief helps at promote time either way;
  if an agent is later observed exceeding its task string, capture that as a `/defect` against
  `/run-plan` — this change does not address it.
