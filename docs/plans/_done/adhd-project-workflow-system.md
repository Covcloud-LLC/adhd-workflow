# ADHD Project-Workflow System — capture → reason → gate → focus → archive

> Status: **done** · created 2026-06-25 · completed 2026-06-25
> Home: this is a **cross-repo** system (skills are global in `~/.claude/skills/`), so the design
> doc lives in the dotfiles repo's `docs/plans/_done/`, not in any single project repo. Built and
> dogfooded in a real project repo on 2026-06-25.
> Why: I start more than I finish and leave repos in disarray. The fix isn't better
> plans (my plan format is already good) — it's closing **open loops**: a hard WIP
> limit, frictionless capture so novelty goes to disk instead of hijacking the
> session, and a daily ritual that names ONE next action instead of a menu.
> Skills live globally in `~/.claude/skills/` (synced via dotfiles) but operate on
> the **current repo** — I run them per-repo.

## The model

Lifecycle of a thought:

```
/idea ──► docs/ideas/<slug>.md        (status: idea — raw, low bar)
   │
/reason (reasoning gate) ──► stamps `reasoned:` on the idea          ← triages by how much thinking it needs
   │    clear · reasoned (docs/notes/<slug>-reasoning.md) · workshop-required (→ /design-workshop)
   │
/promote (quality gate) ──► docs/plans/<slug>.md   (status: todo)   ← requires the reasoned: stamp; refuses vague ideas
   │
/standup (start-time WIP gate, cap=2) ──► status: in-progress       ← refuses a 3rd start
   │
   ▼
docs/plans/_done/<slug>.md            (archived, not deleted)
```

The five stages: **ideate (`/idea`) → reason (`/reason`) → plan (`/promote`) → execute (fresh
sessions, driven by `/pjm`/`/standup`) → validate (`/wrap-up` + `/verify`).**

Three ADHD levers, mapped to where they're enforced:

| Lever | Failure it fixes | Enforced by |
|---|---|---|
| **Frictionless capture** | New idea derails in-flight work | `/idea` — writes & stops, no questions |
| **Reasoning gate** | Un-reasoned idea → plan built on a shrug; hard call decided confidently-wrong | `/reason` — triages by latitude × reversibility × blast radius; workshop-required blocks `/promote` |
| **Quality gate** | Vague plan → future abandoned project | `/promote` — rubric + reasoned: stamp precondition, refuses on fail |
| **WIP=2 limit** | Too many open loops at once | `/standup` — only place a plan goes `in-progress` |
| **Single next action** | A list is a re-decision tax paid by doing nothing | `/standup` — mandatory `▶ NEXT` line, one item |
| **Stalled detection** | Abandoned work invisible | `/standup` + `/audit-plans` — git last-touched > 5d |
| **Object permanence / reward** | Finished work vanishes, loop loses momentum | `_done/` archive (not delete) |

## Statuses

`idea` (ideas only) · `todo` · `in-progress` · `blocked` · `done`. WIP cap applies to
`in-progress` **plans** (≤2), each with ≤1 `in-progress` task.

Separately, an idea carries a **`reasoned:` stamp** (frontmatter) set by `/reason`, orthogonal to
the plan statuses above: `clear` · `notes/<slug>-reasoning.md` (thought-through) ·
`workshop-pending (design|architecture|both)` (blocks `/promote` until the workshop is run).

## The reason gate (triage by how much thinking an idea needs)

Three tiers on one axis — **design latitude × reversibility × blast radius** (the same axis `/pjm`
uses to pick a model tier):

- **clear** — one obvious build, reversible, no design latitude → one-line rationale, pass straight
  to `/promote`. The frictionless fast lane; most ideas live here.
- **reasoned** — a real decision with a defensible default → a solo pass, written to a short
  `docs/notes/<slug>-reasoning.md` decision note.
- **workshop-required** — wide-open, load-bearing, or expensive-if-wrong → refuse, hand off to
  `/design-workshop` (flavor **design** = UX, or **architecture** = solution correctness), block
  `/promote` until the workshop synthesis comes back.

The power is in *requiring* the step; the minimalism is in *scaling* it — the check is always
there, but reasoning an easy idea takes seconds.

## The promote rubric (refuse unless all pass)

**Precondition:** the idea must carry a `reasoned:` stamp that isn't `workshop-pending` (the reason
gate above). Then: definition of done · actionable tasks (real paths/contracts) · a `Verify:`
clause per task · scoped (~≤8 tasks; bigger = a *program*, split it) · a one-line why · a
`Model` + `Effort` header. The two gates are distinct: `/reason` gates "is this sound and
thought-through," `/promote` gates "is the plan artifact well-formed to run cold."

## Cadence

- `/idea` — whenever a thought strikes. Cheap.
- `/reason` — after capture, before planning. Cheap for easy ideas; routes hard ones to a workshop.
- `/standup` — **daily**, per active repo. The ritual. Ends with one action.
- `/promote` — when a reasoned idea is ripe (or to find out it isn't).
- `/audit-plans` — **weekly**, per repo. Board hygiene (now also flags ideas stuck
  `workshop-pending` > 14d).

---

## Build backlog

**ADHD-1 — `/idea` capture skill** · done · depends: none
> task: Global skill at `~/.claude/skills/idea/SKILL.md`. Writes `docs/ideas/<slug>.md`
> (kebab slug, frontmatter `name/created/status: idea`, What/Why body) and stops — no
> questions, no promotion. Verify: `/idea <thought>` creates the file and returns one
> confirmation line. ✅ Created 2026-06-25.

**ADHD-2 — `/promote` quality gate** · done · depends: ADHD-1
> task: Global skill at `~/.claude/skills/promote/SKILL.md`. Reads an idea, applies the
> rubric, refuses with named gaps on fail, else emits a house-format plan
> (`status: todo`) and removes the idea file. Does NOT enforce WIP. Verify: a vague idea
> is refused with specific gaps; a ripe one yields a well-formed `todo` plan. ✅ Created.

**ADHD-3 — `/standup` daily driver + WIP gate** · done · depends: ADHD-2
> task: Global skill at `~/.claude/skills/standup/SKILL.md`. Reads `docs/plans/*.md`,
> reports WIP N/2, flags stalled (git last-touch >5d) and drifted plans, recommends
> `_done/` archival, and ends with one `▶ NEXT` action (nearest finish line first).
> Enforces WIP=2 at the todo→in-progress transition. Verify: with 2 in-progress plans,
> refuses to start a 3rd; otherwise names one paste-ready task. ✅ Created.

**ADHD-4 — `/audit-plans` weekly hygiene** · done · depends: ADHD-2
> task: Global skill at `~/.claude/skills/audit-plans/SKILL.md`. Validates plans against
> the rubric, flags malformed/orphaned/duplicate/stalled/WIP-violating items, groups
> recommendations by action, mutates only on confirmation (prefer `git mv` to `_done/`).
> Verify: run in a repo with a malformed plan and a stale idea → both flagged with the
> fix. ✅ Created.

**ADHD-5 — Seed `docs/ideas/` + `docs/plans/_done/` in active repos** · done · depends: ADHD-3
> task: In each repo I actively run this system in, create `docs/ideas/.gitkeep` and
> `docs/plans/_done/.gitkeep` so the dirs exist before first use. Verify: `/standup` and
> `/idea` run without having to create dirs on the fly. ✅ first repo seeded 2026-06-25;
> the skills also create the dirs on demand, so seeding is a convenience, not a blocker.

**ADHD-6 — (deferred) global multi-repo sweep** · todo · depends: ADHD-3
> task: A `/standup-all` that fans out a read-only scan agent per repo in a registry and
> synthesizes a cross-repo "which repo has abandoned work" view. Deferred — start
> single-repo per the 2026-06-25 decision; revisit if per-repo runs prove insufficient.
> Verify: N/A until picked up.

**ADHD-7 — (deferred) scheduled standup nudge** · todo · depends: ADHD-3
> task: Optional `/schedule` cloud routine that runs `/standup` each morning and posts a
> summary, for days I forget the manual ritual. Deferred — manual-first per the decision;
> add only if I find I skip it. Verify: N/A until picked up.

---

> **Closeout (2026-06-25):** Core system (ADHD-1–5) built and dogfooded end-to-end in a live repo.
> ADHD-6 (multi-repo `/standup-all`) and ADHD-7 (scheduled nudge) are deferred enhancements, gated
> on the single-repo manual flow proving insufficient — recapture as fresh ideas if/when that happens.

---

## Update — reason stage added (2026-07-06)

Formalized the pipeline into **five stages** (ideate → reason → plan → execute → validate) by
inserting a **reason** gate between `/idea` and `/promote`. The trigger: `/promote` was doing two
jobs — checking whether an idea was any good *and* writing the plan — and the adversarial workshop
was bolted on with no rule for when it fired.

What shipped (committed to dotfiles `18fe3ec`):
- **New `/reason` skill** — triages an idea into `clear` / `reasoned` / `workshop-required` on the
  latitude × reversibility × blast-radius axis, and stamps a `reasoned:` verdict on the idea. Runs
  at Opus (judgment work). The requirement is enforced by a single stamp check; cost scales to risk.
- **`/promote` precondition** — refuses to plan an idea whose `reasoned:` stamp is missing or still
  `workshop-pending`. Kept explicitly distinct from the format rubric (two gates, different jobs).
- **`/design-workshop` flavor axis** — added an **architecture** flavor alongside **design**: it
  attacks the *solution* (data model, concurrency, contract shape, blast radius), for the case
  where the *what* was reasoned right but the *how* may be built wrong. One template, two swap-in
  ROLE / HOW-TO-RUN blocks. `/reason` picks the flavor on a workshop-required idea.
- **`/audit-plans`** — new hygiene check: flags ideas stuck `workshop-pending` > ~14d (a pending
  workshop is a decision being avoided).
- **Plain-language guide** at `~/.claude/docs/adhd-workflow-guide.md` walks the whole five-stage
  process.

Not (yet) reflected in the older sections above: `/wrap-up` (end-of-task umbrella / validate stage)
and `/pjm` (project-manager driver session) were added between the original closeout and this
update; see the `My ADHD workflow system` bullet in `~/.claude/CLAUDE.md` for the current
authoritative summary.
