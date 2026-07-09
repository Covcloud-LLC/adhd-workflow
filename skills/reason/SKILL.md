---
name: reason
description: The reasoning gate between capture and planning. Triages an idea in docs/ideas/ by how much thinking it needs — clear (pass straight through), solo-reasoned (write a short decision note), or workshop-required (refuse until an adversarial session is run) — and stamps a verdict that /promote requires. Use when the user types /reason, or says "reason about this idea", "is this idea sound", "sanity-check this before I plan it", "does this need a workshop". Part of the ADHD project-workflow system (see [[idea]], [[promote]], [[design-workshop]], [[standup]]).
---

# /reason — the reasoning gate (ideate → **reason** → plan)

**Run guidance.** This is judgment work: deciding whether an idea is the right thing to build,
built the right way, and how much thinking it needs before it earns a plan. In Codex/OpenAI, run
normal passes at `gpt-5.5 · high`. In Claude Code, run normal passes at
`claude-opus-4-8 · high`. Default recommendation when both are available: Codex/OpenAI
`gpt-5.5 · high`. Mention `claude-fable-5 · high` only for larger long-running autonomous work
where it is available; this gate is usually short judgment, not execution.

It sits between `/idea` (capture) and `/promote` (plan). Its whole job is to make sure **no idea
reaches a plan un-reasoned** — while keeping that requirement nearly free for the ideas that don't
need much.

The power is in *requiring* the step; the minimalism is in *scaling* it. Most ideas are `clear`
and pass through in seconds. A few are load-bearing and get held back until they're stress-tested.
You decide which, using one axis you already use elsewhere.

## The triage axis

The same axis `/pjm` uses to pick a model tier: **design latitude × reversibility × blast
radius.** Low on all three → `clear`. A real decision with a defensible default → `reasoned`.
Wide-open, hard to reverse, or expensive-if-wrong → `workshop-required`.

| Tier | When | What you do | Verdict stamp |
|---|---|---|---|
| **clear** | One obvious implementation. No user-facing design latitude. Reversible. No cross-cutting or architectural commitment. (Add a field, add a CI gate, a mechanical extension.) | State the one-line rationale. Offer to chain straight into `/promote`. | `reasoned: clear` |
| **reasoned** | A real decision with a defensible default — a tradeoff to name, 2–3 approaches to weigh, some risk — but you can reason to a recommendation *without* human-in-loop divergence. | Do the reasoning pass inline. Write a short decision note to `docs/notes/`. | `reasoned: notes/<slug>-reasoning.md` |
| **workshop-required** | Wide solution space, load-bearing, or hard to reverse. Either the **UX** has genuine divergence (`design`) or the **solution approach** is uncertain and being confidently wrong is expensive (`architecture`) — or both. | Refuse. Hand off to `/design-workshop` with the right flavor. Stay blocked. | `reasoned: workshop-pending (design\|architecture\|both)` |

**Two workshop flavors** — pick by *what* is uncertain:
- **design** — how the user experiences it: affordances, microcopy, information architecture. "Is
  this the right thing for the user?"
- **architecture** — how it's built: data model, concurrency, contract shape, where state lives,
  boundaries, blast radius. "We reasoned the *what* well, but might build the *how* wrong."

When both are uncertain, run design first (it can change what you build), then architecture.

## Steps

1. **Find the idea.** Resolve git root. Locate the target in `docs/ideas/` by slug/title/path.
   If ambiguous, list candidates and ask which. Read it.
2. **Triage** against the axis above. Read whatever repo context you need to judge latitude and
   blast radius (adjacent plans, `architecture-decisions.md`, the code the idea touches). State
   the tier and the one-line reason *before* acting — the user can overrule the tier.
3. **Act by tier:**
   - **clear** → Stamp `reasoned: clear` in the idea's frontmatter and add a one-line
     `**Reasoning:**` note to the body. Tell the user it's ready to `/promote`, and offer to
     chain straight into it (this is the frictionless path — don't make them re-invoke).
   - **reasoned** → Do the pass now: name the decision, lay out 2–3 options with how each fails,
     recommend one with the why. Write it to `docs/notes/<slug>-reasoning.md` (see shape below).
     Stamp `reasoned: notes/<slug>-reasoning.md`. Tell the user it's ready to `/promote`.
   - **workshop-required** → Do NOT write a note or a plan. Pick the flavor(s). Invoke the
     `design-workshop` skill, passing the problem **and the flavor**, so it builds and pbcopies
     the adversarial kickoff for a separate provider-qualified workshop session. Stamp
     `reasoned: workshop-pending (<flavor>)`. Stop. The idea is blocked from `/promote` until the
     user runs the workshop and comes back.
4. **After a workshop** (user returns with the synthesis): they re-run `/reason` on the same
   idea. Read their synthesis, write/finalize `docs/notes/<slug>-reasoning.md` capturing the
   decision the workshop reached, and flip the stamp to `reasoned: notes/<slug>-reasoning.md`.
   Now it's ready to `/promote`.

## The reasoning note (`docs/notes/<slug>-reasoning.md`)

Short. It records the decision so `/promote` and future-you don't re-litigate it.

```markdown
# <Idea title> — reasoning

**Decision:** <the approach we're committing to, one or two sentences>
**Why:** <the load-bearing reason>

## Options considered
- **<A>** — <how it fails / why not>
- **<B> (chosen)** — <why it wins>
- **<C>** — <how it fails / why not>

## Risks / open questions carried into the plan
- <anything the plan must handle that this pass surfaced>

<If this came from a workshop: one line — "Stress-tested in a <design|architecture> workshop
<date>; the synthesis above reflects it.">
```

## Rules

- **Never write a plan.** That's `/promote`. This step ends at a verdict stamp (+ a note, for the
  middle tier). Keep the two gates distinct: `/reason` gates "is this sound and thought-through";
  `/promote` gates "is the plan artifact well-formed to run cold."
- **Default toward the cheaper tier, but don't wave through blast radius.** If an idea touches a
  public contract, money math, a lifecycle/state model, load-bearing IA, or anything hard to
  reverse, it is at least `reasoned` and probably `workshop-required` — even if the idea *sounds*
  small.
- **The tier is the user's call.** State your triage and reason; they can bump it up or down. If
  they bump it down below what blast radius warrants, say so once, then honor it.
- **Don't run the workshop here.** `workshop-required` hands off to `/design-workshop`, which
  produces a kickoff for a *separate* session. This session does not critique the design itself.
- **`clear` must stay frictionless.** No note, no ceremony — one line and an offer to chain into
  `/promote`. If the gate makes trivial ideas expensive, it will get skipped, and then it protects
  nothing.
