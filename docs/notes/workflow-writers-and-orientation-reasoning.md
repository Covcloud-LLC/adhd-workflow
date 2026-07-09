# Workflow refinement (writers + orientation) — reasoning

**Decision:** Keep the five-stage lifecycle as-is. Add a two-layer document taxonomy (the
lifecycle owns all pre-build artifacts; two writer skills own all post-build "shipped" docs),
and fix the three observed failures with recoverability mechanisms (amnesty sweep, breadcrumbs,
a "where am I?" query) — never with harder gates.

**Why:** The observed failures (circumvention via hotfix chats, forgetting the next step,
losing track of a feature's position, PRD/TRD confusion) are all *orientation* failures, not
gate-quality failures. The fix is making state recoverable from the repo, and making every
document decision pre-answered so it's never decided ad hoc.

## The core decisions

### 1. No PRD/TRD — the lifecycle already emits their equivalents

PRD/TRD/functional-spec taxonomy exists to coordinate role handoffs between separate people.
Solo-plus-bots doesn't have those handoffs. Mapping:

| Enterprise doc | Our equivalent | Emitted by |
|---|---|---|
| PRD (what & why) | idea file + its `Why:` | `/idea` |
| Decision record / ADR | reasoning note, workshop synthesis | `/reason` |
| TRD / work order | plan with `task:` + `Verify:` | `/promote` |
| Bug report | defect file | `/defect` |

**Rule:** the lifecycle owns everything pre-build. The only documents outside it are shipped
docs, written after the thing exists. "Do I need a PRD here?" is answered by which tier
`/reason` assigned — never decided per instance.

Pre-build acceptance criteria (the "feature brief, before" sense) live in the plan: `/promote`
requires an explicit `## Acceptance criteria` checklist for user-facing features. The post-build
knowledge-transfer brief is a shipped doc (guide writer).

### 2. Two writer skills, split by what the reader does

- **`/draft-spec`** — reader (human or bot) will *execute against a contract*. Fact-dense:
  tables, schemas, exact field names grep-verified against the emitting/consuming source. No
  narrative.
- **`/draft-guide`** (extended) — reader will *perform a task or understand a thing*. Modes:
  tutorial, how-to, quickstart, brief (post-build knowledge transfer), explanation (a transform
  of an existing reasoning note — the process already wrote its raw material).

Shared spine: no doc without a named reader (refuse otherwise) · verify every claim against
source or the running service · one fact, one home · six-field front-matter (below).

### 3. Bots are first-class readers — standardize front-matter once

Cross-repo harvesting (e.g. `rating-platform-kb`) is frequent, so shipped-doc front-matter is a
contract. Six fields, emitted by the writer skills, never hand-typed:

```yaml
doc-type: spec | tutorial | how-to | quickstart | brief | explanation
audience: <who reads this — never blank>
status: current | superseded-by: <path>
verified-against: <commit-sha or date>
repo: <repo name>
source: <plan/note paths>   # provenance, for regeneration
```

Plus a per-repo `docs/README.md` index as the harvester entry point. A stale spec is worse than
none for a bot reader — hence `verified-against` + an `/audit-plans` staleness nudge.

### 4. Circumvention: amnesty, not enforcement

The observed pattern is hotfix chat sessions that skip capture. The missing front door is
`/defect` (hotfixes are bug-shaped), and no gate prevents the pattern — so reconcile after the
fact: a session-level nudge (offer retroactive capture when a session changed code with no
plan/defect referencing it) + a `/standup` amnesty sweep (commits/branches matching no plan or
defect → offer a backfill stub). Never scold, never block.

### 5. Orientation: breadcrumbs + a "where am I?" query, no new command

Every skill ends by naming the single next command in the lifecycle. `/standup <feature>`
traces a term across ideas/notes/plans/defects/branches and reports lifecycle position + next
command. Rejected: a new `/next` dispatcher command — a 12th command is more surface area for
the same forgetting.

## Options considered

- **Adopt PRD/TRD document kinds** — rejected: pure theatre at solo scale; duplicates what the
  lifecycle artifacts already carry; creates a new "which doc?" decision per feature, which is
  the exact confusion being fixed.
- **One mega writer skill** — rejected: spec-writing and prose-writing have different
  verification disciplines and registers; one skill with a giant mode switch invites register
  bleed. Two skills with a shared spine (chosen).
- **Writer as a subagent auto-run from `/wrap-up`** — rejected for now: auto-generated docs
  with no named reader is doc theatre. Wrap-up *queues* a doc task; a fresh session runs it
  cold like any other task string.
- **Harder gates against circumvention** — rejected: the gates are fine; the failure is
  disorientation. Amnesty + recoverability (chosen) shortens the path back into the process
  instead of hardening it.
- **New `/next` dispatcher command** — rejected: breadcrumbs + `/standup <feature>` reuse
  commands already in muscle memory.

## Risks / open questions carried into the plan

- Amnesty sweep noise: repos with many chore commits could over-flag. Keep it a compact
  `⊘ UNTRACKED` section with a batch-dismiss, and tune the lookback (~14d).
- `/draft-guide` mode sprawl: five modes risks blurred Diátaxis boundaries. Keep the "state the
  mode + one-line reason before drafting" rule mandatory.
- `verified-against` staleness check could false-alarm on heavy-churn repos — keep it a nudge,
  never a gate.
- Front-matter schema must stay stable once harvesters depend on it — treat field renames as a
  breaking change requiring a sweep.
- Breadcrumb edits touch every skill — hold each to ~1 line so skills don't bloat.

Stress-tested in an end-to-end architecture discussion (AI process-expert session), 2026-07-07;
this note is the synthesis.
