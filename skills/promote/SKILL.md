---
name: promote
description: The plan gatekeeper. Promotes an idea from docs/ideas/ into a well-formed plan in docs/plans/ ONLY if it has passed the /reason gate AND passes a specificity/actionability/clarity rubric; otherwise refuses and names the gaps. Use when the user types /promote, or says "promote this idea", "turn this into a plan", "make a backlog for X". Part of the ADHD project-workflow system (see [[idea]], [[reason]], [[standup]], [[audit-plans]]).
---

# Promote an idea → plan (quality gate)

You are a **gatekeeper**, not a yes-man. The user has ADHD and starts more than they finish; a vague plan is a future abandoned project. Your job is to **refuse** ideas that aren't ready and tell the user exactly what's missing — or, if ready, emit a plan in the repo's house format. Refusing is a success, not a failure.

This gate enforces **quality**. It does NOT enforce the WIP limit — promoting to a `todo` backlog is healthy capture-and-defer. The WIP=2 cap on *starting* work is enforced by `/standup`.

## Docs root (resolve this FIRST)

Before reading or writing any lifecycle doc, resolve the **docs root**:

- Let `<repo>` = basename of the current repo's git root (`basename "$(git rev-parse --show-toplevel)"`).
- If the config file `~/.config/adhd-workflow/backlog-root` exists, read it: it holds one line, the absolute path of a **backlog metarepo** (a git repo that centralizes backlog docs for many code repos) — call it `<backlog-root>`. If `<backlog-root>/<repo>/` exists, **that dir is the docs root** — `ideas/`, `plans/` (with `_done/`), `defects/`, and `BOARD.md` live directly under it (there is **no `docs/` path segment** inside the metarepo).
- Otherwise fall back to `./docs/` in the current repo, exactly as before.

Everywhere below, `docs/ideas/`, `docs/plans/`, `docs/defects/`, and `docs/BOARD.md` mean paths under the resolved docs root. **Reasoning notes follow the docs root too**: `docs/notes/` means `<backlog-root>/<repo>/notes/` when a metarepo is configured, and `./docs/notes/` in the code repo otherwise. Only lifecycle reasoning notes (`*-reasoning.md`, written by `/reason`) live there — durable design, decision, and reference docs stay in the code repo's own `./docs/notes/` and never move. Paths written *inside* a plan/idea/defect are relative to the code repo, not the metarepo.

**Writing under the metarepo:** when the docs root is the metarepo, every file you create, edit, move (`git mv`), or delete there is **immediately committed and pushed**, scoped to the affected path(s): `git -C <backlog-root> add <path> && git -C <backlog-root> commit -m "<msg>" && git -C <backlog-root> push`. This is a deliberate exception to the no-auto-commit rule and applies ONLY to writes under the metarepo. Reads and writes in the code repo (`scripts/slice-gate.sh`, git-based stall detection, durable `docs/notes/` reference docs) are unchanged and are **NOT** auto-committed.


## The reasoning precondition (check FIRST, before the rubric)

An idea must clear the `/reason` gate before it can become a plan. Read the idea's frontmatter
`reasoned:` field:

- **missing** → refuse. "This hasn't been reasoned yet — run `/reason <idea>` first." Stop. Do not
  write a plan. (An idea captured by `/idea` and never reasoned has no `reasoned:` field.)
- **`workshop-pending (…)`** → refuse. "This idea is waiting on a `<flavor>` workshop — run it,
  then re-run `/reason` to close the gate." Stop.
- **`clear`** or **`notes/<…>-reasoning.md`** → precondition met. If it points at a note, read the
  note — its Decision / chosen option / carried risks are inputs to the plan; the plan must reflect
  them, not re-litigate them. Proceed to the rubric.

This is a *separate* gate from the rubric below. `/reason` decided the idea is sound and
thought-through; the rubric decides the *plan artifact* is well-formed enough to run cold. Both
must pass.

## Steps

1. Resolve git root. Find the target idea in `docs/ideas/` (by slug, title, or the path/name the user gave). If ambiguous, list candidates and ask which. **Run the reasoning precondition above — refuse if it fails.**
2. Read the idea. Read one or two existing plans in `docs/plans/` (e.g. the largest backlog) to match the **exact house format** — header block, `### <ID>-<n> — <Title>` slice headings each with a `> status:` line directly beneath, indented `> task:` strings, and `Verify:` clauses.
3. Run the **rubric** below. If the idea lacks the substance to satisfy it, you have two moves:
   - If the missing pieces are things only the user knows (scope, acceptance criteria, which files), **refuse**: list each failed criterion and the specific question that would fix it. Stop. Do not write a plan.
   - If you can responsibly infer the missing structure from the repo and the idea, draft it — but show the user the inferences and let them correct before finalizing.
4. On pass: draft the whole plan — but **read it back before anything is written to disk.**
   - Decompose into tasks, each with a self-contained `task:` string and a `Verify:` clause. Set the plan's **`> Default run tier:`** header and a **`> Run at:`** line on every slice (see *Run tiers: per slice, not per plan* below for the shape, and *Model & provider-aware Effort* for which slug and effort to pick). Never emit the legacy `Model:`/`OpenAI:`/`Claude:`/`Recommended:` block. If the effort on a slice — or the plan default, for slices with no `Run at:` line — is `high`+ (or the plan carries `> Red-gate: yes`), apply the **red-gate authoring rule** below to each correctness-sensitive task and set the whole-tree `> Check:` header.
   - With the slices drafted and **no file created yet**, write the brief and the decision delta from them (see *The brief and the decision delta*), and present **ONE** message containing exactly three things: the **brief**, the **decision delta** (or the explicit "None — …" line), and the question **"Write it?"** Then stop and wait for the user's yes.
   - **One message, one yes.** Do not follow it with a second rubric, a confirmation checklist, or a round of questions — the user has ADHD and a second gate is where a ready plan dies. If they correct something, fold the correction into the draft and re-ask in the same one-message shape.
   - On yes: write `docs/plans/<slug>.md` in house format with `status: todo` (promotion does NOT start work), then **remove the idea file** from `docs/ideas/` (it has graduated) — or note it if the user wants it kept — and commit/push if the docs root is the metarepo. Exactly as before; the read-back changes when you write, not what you write.

   Why read back *before* writing: under the metarepo every write is committed and pushed the moment it lands, so a plan written and then corrected costs a push-then-amend churn in shared history. Reading back first makes the first commit the right one. The habit is worth keeping in a plain `docs/` repo too — the brief is where a wrong decomposition shows itself.
5. Report: the plan path, the task count, and that it's `todo` (not started). If the user is already at the WIP cap (2 plans `in-progress`), add one line: "You have 2 in flight — this waits as `todo` until one finishes. Good." Do not offer to start it; end with the one breadcrumb line: "`/standup` starts it when a WIP slot opens."

## The rubric — refuse unless ALL pass

| Criterion | Pass test |
|---|---|
| **Outcome / definition of done** | There's a clear end state. "Improve X" fails; "X does Y, verified by Z" passes. |
| **Actionable tasks** | Decomposes into concrete tasks naming real paths/contracts/behavior — not "research" or "think about". |
| **Verifiable** | Each task has a `Verify:` clause: a command, test, or observable outcome that proves it's done. For red-gated tasks this must be a runnable command — see the red-gate authoring rule. |
| **Scoped** | Fits one plan (~≤8 tasks / one coherent deliverable). If it's multiple independently-valuable phases, it's a *program* — refuse and tell the user to split it into separate plans. |
| **Why** | A one-line motivation survives, so future-you remembers the point. |
| **Acceptance criteria (user-facing features)** | A plan for a user-facing feature must carry an explicit `## Acceptance criteria` checklist of observable behaviors — what a user can see/do when it ships. Backend/internal plans are exempt (their `Verify:` clauses suffice). |
| **Brief + decision delta** | The plan artifact carries BOTH `## What this plan will actually do` (one to two present-tense sentences per slice, no file paths) and `## Decisions this plan makes` (every choice the decomposition added, or the exact line "None — the reasoning note settled everything"). No exemptions; an omitted section fails. |

## House format (match the repo, this is the shape)

```markdown
# <Title> — <one-line outcome>

> Status: **todo** · created <YYYY-MM-DD>
> Default run tier: **<Claude friendly-name> · <effort>** (`<claude-slug>`) · Codex **<OpenAI friendly-name> · <effort>** (`<openai-slug>`) — **each slice overrides this**; read the `Run at:` line on the slice you are starting.
> Red-gate: yes   <!-- optional: opt a medium plan into the red-gate rule; omit otherwise -->
> Check: <whole-tree check command, e.g. pnpm test>   <!-- the repo's whole-tree check; required for /run-plan to drive the plan -->
> Why: <one line>

## Run tiers at a glance

| Slice | What it is | Claude Code | Codex |
| --- | --- | --- | --- |
| **<ID>-1** | <five-word gist> | **<friendly> · <effort>** | <friendly> · <effort> |
| **<ID>-2** | <five-word gist> | **<friendly> · <effort>** | <friendly> · <effort> |

Exact model IDs: `<the slugs used above>`. If a slice's `Run at:` line and this table ever
disagree, **the slice line wins.**

## Definition of done
<the observable end state>

## What this plan will actually do
<one to two present-tense sentences per slice, in plain language, no file paths — written for a
human skimming this a week from now>

## Decisions this plan makes
- <a choice the decomposition introduced that the reasoning note / idea did not settle>
- <...>
<!-- if the decomposition introduced no new choices, this section still appears, containing
     exactly one line: None — the reasoning note settled everything -->

## Acceptance criteria   <!-- required for user-facing features; omit for backend/internal plans -->
- [ ] <observable behavior a user can see/do>
- [ ] <...>

---

### <ID>-1 — <task title>
> status: todo · depends: none
> Run at: Claude Code **<friendly-name> · <effort>** · Codex **<friendly-name> · <effort>**
> Why this tier: <one line naming the specific latitude or trap that sets the tier>
> task: Check: <the concrete test file/case agent A authors, with its key assertions — and nothing else>. Build: <the implementation work, self-contained: paths, contract, behavior>. Verify: <runnable command naming the check, e.g. pnpm test -t "<ID>-1">.

### <ID>-2 — <task title>   <!-- plain shape: exempt or non-red-gated slices -->
> status: todo · depends: <ID>-1
> Run at: Claude Code **<friendly-name> · <effort>** · Codex **<friendly-name> · <effort>**
> Why this tier: <one line>
> task: <self-contained prompt: paths, contract, behavior, tests>. Verify: <command/test/observable proof>.
```

**A slice IS its `### <ID>-<n> — <title>` heading.** The whole toolchain keys on that heading:
`/run-plan` and `/wrap-up` append the ` ✅` done marker to it, `/standup` and `/pjm` pick the
first heading without one. A slice written any other way is invisible to all four. Status and
dependencies live on the `> status: <status> · depends: <...>` line directly under the heading —
never inline in the heading itself. (An older bold dialect — `**<ID>-n — <title>** · todo ·
depends: none` as a paragraph line — exists in legacy plans; it is readable history, but never
emit it. `/audit-plans` flags it for migration.)

The `Check:` header names the command that proves the whole tree still works (build + full test
suite). `/run-plan` refuses to drive a plan without it — no whole-tree check means no witness
that a slice broke nothing. It is optional for plans that will only ever be hand-run.

Use a short uppercase ID prefix derived from the slug. Statuses used across the system: `todo` · `in-progress` · `blocked` · `done`. Match whatever the repo's existing plans already use if they differ.

### The brief and the decision delta (both required)

`## What this plan will actually do` is the **brief** — one to two present-tense sentences per
slice, plain language, no file paths, no slice IDs needed. It is for a human skimming, not for an
execution session.

Write it **after the slices are drafted, never before.** It is a mirror of the `task:` strings, so
it can only be written once they exist. That is the point: if the brief and the `task:` strings
disagree — the brief promises something no slice does, or a slice does something the brief never
mentions — **that is a bug in the plan, not a wording problem.** Fix the decomposition, then
re-mirror it.

`## Decisions this plan makes` is the **decision delta**: every choice the decomposition
introduced that the reasoning note or the idea did not already settle. Splitting one behavior
across two slices, picking a format, choosing where something lives, deciding what is out of
scope — each is a decision, and each is invisible if it only exists implicitly inside a `task:`
string. If the decomposition genuinely introduced none, the section is **still present** and
contains exactly:

```
None — the reasoning note settled everything
```

An **omitted** section is never acceptable — "no delta" and "nobody looked" have to be
distinguishable a month from now. Silence reads as the second one.

**Legacy migration rule:** plans written before these two sections existed carry neither. They are
**readable legacy**, never malformed — do not warn about them, do not refuse to work with them. But
never emit a new plan without both. `/audit-plans` flags them for migration, and you may offer to
backfill.

### Run tiers: per slice, not per plan

Both provider routes are still recorded and a default is still named — that contract is settled
(`docs/notes/openai-model-routing-for-workflow-skills-reasoning.md`) and this format keeps it. What
changed is **granularity and rendering**: one `Default run tier:` line instead of four near-duplicate
`Model:` / `OpenAI:` / `Claude:` / `Recommended:` lines, and a real per-slice call on each slice.

- **Friendly names on the slice lines** (`Opus 4.8 · high`), because that line is read at handoff
  time by a human deciding what to launch. **Exact slugs once**, in the `Default run tier:` line and
  under the at-a-glance table, because that is the machine-checkable part. Valid slugs are unchanged:
  OpenAI `gpt-5.5|gpt-5.4|gpt-5.4-mini|gpt-5.4-nano` with effort `none|low|medium|high|xhigh`; Claude
  `claude-fable-5|claude-opus-4-8|claude-sonnet-5|claude-haiku-4-5` with effort
  `low|medium|high|xhigh|max` (`max` is Claude-only and session-only).
- **Use this ladder** unless the plan argues otherwise: **Opus 4.8 · high ↔ GPT-5.5 · high** for
  design latitude; **Sonnet 5 · high ↔ GPT-5.5 · medium** for authoring against settled semantics
  that still has a trap in it; **Sonnet 5 · medium ↔ GPT-5.4-mini · medium** for mechanical work.
  Reserve `claude-fable-5 · high` for large long-running autonomous slices.
- **Make real calls, not a uniform copy.** A plan whose every slice carries the same tier has not
  been thought about. The usual split: schema/contract/orchestration slices keep the top tier
  because their shape decisions propagate; example, fixture, and doc slices downshift. Say which in
  one line.
- **Model and effort move independently.** Downshifting the model does not mean downshifting effort.
  A slice whose task string enumerates every case but where a careless pass ships a plausible wrong
  answer — arithmetic in a worked example, a mutation check that is easy to fake — is a
  **`Sonnet 5 · high`** slice. Ask two questions: *how much is left to decide* (sets the model) and
  *how expensive is a quiet mistake* (sets the effort).
- **`Why this tier:` is required** and must name the specific latitude or trap, not restate the
  slice title. "Sets the entity shape five later slices inherit" is a reason; "important slice" is
  not.

**Legacy migration rule:** old active plans may carry the previous four-line
`Model:`/`OpenAI:`/`Claude:`/`Recommended:` header, or unqualified `opus`, `sonnet`, `haiku`, `fable`
model names. Both are **readable legacy**, never malformed. Do not copy either shape into new plans.
Flag them for migration to a `Default run tier:` line plus per-slice `Run at:` lines, and offer to
convert. A plan with no model header at all still degrades gracefully — see the red-gate rule below.

## Red-gate authoring rule (provider-aware Effort `high`+)

The trigger reads the **slice's own** `Run at:` effort, falling back to the plan's
`Default run tier:` effort when a slice carries no `Run at:` line. This is why effort is worth
setting per slice: a `medium` authoring slice in an otherwise `high` plan is not forced into a
Check/Build split it has nothing to gain from, and a `high`-effort slice in an otherwise `medium`
plan gets the discipline it needs.

When that effort is `high`, `xhigh`, or Claude-only `max`, each
**correctness-sensitive** task's `task:` string splits into two **explicitly labelled parts**,
so the check and the implementation can be authored by different sessions and the red can be
witnessed by a party with no stake in it (the slice-gate convention —
`docs/notes/slice-gate-convention.md` in the workflow repo):

- **Check:** what agent A authors — the concrete test file/case to create, with the key
  assertions sketched in the task string where the contract is known at planning time. The
  Check part contains the check and **nothing else**: no implementation work.
- **Build:** what agent B implements — the actual work, self-contained as always (paths,
  contract, behavior), written so it can run without seeing the Check text.

For red-gated tasks, `Verify:` must be a **runnable command that names the check** — e.g.
`Verify: pnpm test -t "XLCT-1"` or `Verify: bash tests/gate_test.sh` — never a description of
a test to be written. `/run-plan` executes exactly this command as the gate's preflight and
postflight; a `Verify:` it cannot execute halts the plan at validation, before slice 1 runs.

When a red-gated slice is **hand-run** instead (no `/run-plan`), the execution session keeps
the same discipline through the split: author the Check first, run it, state **"confirmed
red"**, then do the Build.

A `medium` plan may opt in by carrying a `> Red-gate: yes` header line (add it below the
`> Default run tier:` line); that applies this rule below `high`, to every slice.

**Exemptions** (apply even in `high`+ plans): spike/exploratory, doc, and design slices are
exempt — where the spec is the output, there is nothing to red-test; the task string should say
which exemption applies, and needs no Check/Build split.

**Graceful degradation:** plans/repos without an `Effort` header get no red-gate, no
Check/Build split, and no runnable-`Verify:` requirement — never refuse or warn a legacy repo
over it.

Rationale (do not strip): independently-authored checks decorrelate spec-misread errors; the red
run catches vacuous tests; a runnable `Verify:` moves "confirmed red" from a self-report by the
session being judged to an exit code observed by the orchestrator; this is deliberately NOT full
TDD (no micro-cycles, no delete-premature-code rule) per the reasoning note.

## Model & provider-aware Effort

Every plan carries a recommended **execution model** and **reasoning effort** so future-you (or a new session) runs it at the right cost/care setting without re-deciding. Both provider routes are named on one `> Default run tier:` line, and each slice carries its own `> Run at:` line with a required `Why this tier:` — see *Run tiers: per slice, not per plan* above for that shape. This section is the ladder you pick from.

- **OpenAI models** — for Codex/OpenAI routes, use exact current slugs: `gpt-5.5` for complex reasoning, coding, and correctness-sensitive professional work; `gpt-5.4` when the work still needs a strong frontier model but cost matters more; `gpt-5.4-mini` for well-understood localized changes, subagents, and lower-latency work; `gpt-5.4-nano` only for trivial high-volume/mechanical work.
- **Claude models** — for Claude Code routes, use exact current slugs: `claude-opus-4-8` for complex agentic coding and enterprise-grade correctness work; `claude-fable-5` for the rare highest-capability long-running autonomous work where available; `claude-sonnet-5` for the best speed/intelligence balance on well-understood work; `claude-haiku-4-5` for trivial fast mechanical sweeps.
- **Provider-aware Effort** — scale to *correctness-sensitivity × ambiguity × blast radius*:
  - `low` — trivial, mechanical, hard to get wrong (rename, doc tweak, config bump).
  - `medium` — well-specified, localized change with a clear verify gate.
  - `high` — money/decimal/kernel paths, security, cross-module refactors, or any real design ambiguity. **Default for this kind of repo when unsure.**
  - `xhigh` — the gnarliest only: subtle numeric/concurrency reasoning, or large ambiguous refactors where a wrong call is expensive.
  - `max` — Claude Code only, session-only, and only for current Fable / Opus / Sonnet models when `xhigh` still is not enough.

OpenAI effort supports `none`, `low`, `medium`, `high`, and `xhigh`. Claude Code effort supports `low`, `medium`, `high`, `xhigh`, and session-only `max` on current Fable / Opus / Sonnet models. Do not put OpenAI-only `none` on a Claude route, and do not put Claude-only `max` on an OpenAI route.

When in doubt for a correctness-critical Codex session, prefer `OpenAI gpt-5.5 · high`; for the same work in Claude Code, prefer `Claude claude-opus-4-8 · high`. Lighter well-scoped work can route to `OpenAI gpt-5.4-mini · medium` and `Claude claude-sonnet-5 · medium`.

## Rules

- Refusing is the default when in doubt. A weak plan promoted is worse than an idea left in `docs/ideas/`.
- Do not invent acceptance criteria the user never implied just to force a pass. Ask.
- Never set a new plan to `in-progress`. Promotion ends at `todo`.
