---
name: promote
description: The plan gatekeeper. Promotes an idea from docs/ideas/ into a well-formed plan in docs/plans/ ONLY if it has passed the /reason gate AND passes a specificity/actionability/clarity rubric; otherwise refuses and names the gaps. Use when the user types /promote, or says "promote this idea", "turn this into a plan", "make a backlog for X". Part of the ADHD project-workflow system (see [[idea]], [[reason]], [[standup]], [[audit-plans]]).
---

# Promote an idea → plan (quality gate)

You are a **gatekeeper**, not a yes-man. The user has ADHD and starts more than they finish; a vague plan is a future abandoned project. Your job is to **refuse** ideas that aren't ready and tell the user exactly what's missing — or, if ready, emit a plan in the repo's house format. Refusing is a success, not a failure.

This gate enforces **quality**. It does NOT enforce the WIP limit — promoting to a `todo` backlog is healthy capture-and-defer. The WIP=2 cap on *starting* work is enforced by `/standup`.

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
2. Read the idea. Read one or two existing plans in `docs/plans/` (e.g. the largest backlog) to match the **exact house format** — header block, `**ID — Title** · STATUS · depends:` item lines, indented `> task:` strings, and `Verify:` clauses.
3. Run the **rubric** below. If the idea lacks the substance to satisfy it, you have two moves:
   - If the missing pieces are things only the user knows (scope, acceptance criteria, which files), **refuse**: list each failed criterion and the specific question that would fix it. Stop. Do not write a plan.
   - If you can responsibly infer the missing structure from the repo and the idea, draft it — but show the user the inferences and let them correct before finalizing.
4. On pass: write `docs/plans/<slug>.md` in house format with `status: todo` (promotion does NOT start work). Decompose into tasks, each with a self-contained `task:` string and a `Verify:` clause. If the plan's `Effort` is `high`+ (or it carries `> Red-gate: yes`), apply the **red-gate authoring rule** below to each correctness-sensitive task and set the whole-tree `> Check:` header. Set the provider-qualified **`Model` and provider-aware `Effort`** header fields plus the OpenAI / Claude route lines (see *Model & provider-aware Effort* below). Then **remove the idea file** from `docs/ideas/` (it has graduated) — or note it if the user wants it kept.
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

## House format (match the repo, this is the shape)

```markdown
# <Title> — <one-line outcome>

> Status: **todo** · created <YYYY-MM-DD>
> Model: <OpenAI gpt-5.5|OpenAI gpt-5.4|OpenAI gpt-5.4-mini|OpenAI gpt-5.4-nano|Claude claude-fable-5|Claude claude-opus-4-8|Claude claude-sonnet-5|Claude claude-haiku-4-5> · Effort: <provider-valid effort>
> OpenAI: <gpt-5.5|gpt-5.4|gpt-5.4-mini|gpt-5.4-nano> · Effort: <none|low|medium|high|xhigh>
> Claude: <claude-fable-5|claude-opus-4-8|claude-sonnet-5|claude-haiku-4-5> · Effort: <low|medium|high|xhigh|max>
> Recommended: <OpenAI|Claude> <model-id> · <effort> for <current surface>; use <other provider> <model-id> · <effort> when running there
> Red-gate: yes   <!-- optional: opt a medium plan into the red-gate rule; omit otherwise -->
> Check: <whole-tree check command, e.g. pnpm test>   <!-- the repo's whole-tree check; required for /run-plan to drive the plan -->
> Why: <one line>

## Definition of done
<the observable end state>

## Acceptance criteria   <!-- required for user-facing features; omit for backend/internal plans -->
- [ ] <observable behavior a user can see/do>
- [ ] <...>

---

**<ID>-1 — <task title>** · todo · depends: none
> task: Check: <the concrete test file/case agent A authors, with its key assertions — and nothing else>. Build: <the implementation work, self-contained: paths, contract, behavior>. Verify: <runnable command naming the check, e.g. pnpm test -t "<ID>-1">.

**<ID>-2 — <task title>** · todo · depends: <ID>-1   <!-- plain shape: exempt or non-red-gated slices -->
> task: <self-contained prompt: paths, contract, behavior, tests>. Verify: <command/test/observable proof>.
```

The `Check:` header names the command that proves the whole tree still works (build + full test
suite). `/run-plan` refuses to drive a plan without it — no whole-tree check means no witness
that a slice broke nothing. It is optional for plans that will only ever be hand-run.

Use a short uppercase ID prefix derived from the slug. Statuses used across the system: `todo` · `in-progress` · `blocked` · `done`. Match whatever the repo's existing plans already use if they differ.

The `Model` line is the recommended default route for the current surface, and it must be provider-qualified. The `OpenAI` and `Claude` lines preserve the alternate provider route so a future session can run the same plan from Codex or Claude Code without re-deciding the model.

**Legacy migration rule:** old active plans may still use unqualified `opus`, `sonnet`, `haiku`, or `fable` in the `Model` line. Do not copy that shape into new plans. Flag those old plans for migration to a provider-qualified route such as `Claude claude-opus-4-8` plus explicit OpenAI / Claude route lines; do not treat them as unreadable.

## Red-gate authoring rule (provider-aware Effort `high`+)

When the plan's provider-aware `Effort` is `high`, `xhigh`, or Claude-only `max`, each
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
`> Model:` line); that applies this rule below `high`.

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

Every plan carries a recommended **execution model** and **reasoning effort** so future-you (or a new session) runs it at the right cost/care setting without re-deciding. Set a provider-qualified default route, an OpenAI route, a Claude route, and the `Recommended` line that chooses between them for the current surface. Add a half-line rationale after the plan body if the choice isn't obvious.

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
