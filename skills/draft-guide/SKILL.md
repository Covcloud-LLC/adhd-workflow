---
name: draft-guide
description: Draft a prose-shaped Diátaxis doc for the CURRENT repo's shipped docs as a technically-verified first draft for the user's own voice pass — not ship-final prose. Five modes: tutorial, how-to, quickstart, brief (post-build knowledge transfer), explanation (promote a docs/notes/ reasoning note). Matches the repo's house voice by reading sibling docs, pulls the audience from the plan/doc header (never invents one), verifies every command/output/money amount against source or the running service before writing it, holds a plain-technical reading level (no academic register), and stamps the six-field shipped-doc front-matter. Use when the user types /draft-guide, or says "draft a tutorial/how-to/quickstart/walkthrough", "write a guide for X", "write the brief for X", "promote this reasoning note into a doc". Reference/contract material belongs to /draft-spec.
---

# /draft-guide — draft a prose-shaped shipped doc

Produce a **technically-verified first draft** of a prose-shaped doc (tutorial, how-to, quickstart,
brief, or explanation) for the current repo's docs.
The output is raw material for the user's own voice pass — **not** ship-final prose. Get the facts
right, get the structure right, hold the reading level; leave the final voice to the user.

`$ARGUMENTS` = the topic, a backlog ID (e.g. `AUTH-3`), or a target file path. If it's a backlog ID,
read its `task:` and `Verify:` lines from `docs/plans/` first — they define the scope and the gate.

## What this does / does not do

- **Does:** choose the right Diátaxis mode, match house voice, verify every fact, stamp the six-field
  shipped-doc front-matter, write a draft to the target path, and hand back a note saying what was
  checked.
- **Does NOT:** publish or claim the doc is final. **Does NOT** invent numbers, outputs, or field
  names. **Does NOT** touch `docs/plans/` status — `/standup` owns status.

## Step 1 — Pick the mode (Diátaxis)

State the mode and one-line reason *before* drafting — **mandatory for all five modes**.

| Mode | Pick test (one line) |
|---|---|
| **Tutorial** | Reader needs to *learn by doing* — one hand-held narrative, start → finish, single happy path. |
| **How-to** | Competent reader has a *specific goal* — independent, goal-first recipes ("To do X, …"). |
| **Quickstart** | Shortest path to *first success* — tutorial-shaped but minimal: fewest steps, no detours, no theory. |
| **Brief** | *Post-build knowledge transfer* to another dev/stakeholder — what this is, why it exists, how it behaves, gotchas. Source it from the plan + reasoning note + diff. |
| **Explanation** | An existing `docs/notes/` reasoning note deserves *promotion to a shipped doc* — **transform the note, don't rewrite from scratch**; the process already wrote the raw material. |

Mode discipline:
- **Tutorial**: no branching, no alternatives, no edge-case catalog. "You will build…".
- **How-to**: each recipe stands alone; troubleshooting at the end is fine.
- **Quickstart**: if it needs a second path or a concept section, it's a tutorial — say so and re-pick.
- **Brief**: written for a named human reader (a teammate, a stakeholder), not a bot index.
- **Explanation**: keep the source note's decisions and reasoning; strip lifecycle scaffolding
  (verdict stamps, open questions already resolved), re-register for a reader who wasn't in the room.

If the request is really **reference material** (a field/knob list, a schema, a contract), say so and
stop — point to `/draft-spec`. Don't smuggle a spec into prose.

## Step 2 — Ground in the current repo (before writing a word)

1. **Read 2–3 sibling docs** in the target directory. Absorb the house voice, heading style, link
   conventions, and how examples are formatted. Match them — do not impose a generic template.
2. **Take the audience from the source, never assume it.** Look in this order: the plan's audience
   section, the target doc's mode/audience header, an existing sibling's header. If none states it,
   ask the user — don't guess. A plan that names its audience (e.g. *newcomers*) settles it.
3. **One home per concept.** If a concept already has an explanation doc (e.g. `concepts.md`), **link
   to it** instead of re-explaining. Reference, don't duplicate.

## Step 3 — Reading level & technical detail (the rubric)

This is the part to get right. The default failure mode is academic prose; avoid it.

**Target reader.** A competent developer who is new to *this* system. Calibrate to a strong official
framework tutorial — Stripe docs, the Django tutorial, a good engineering blog. **Not** a research
paper, **not** a marketing page.

**Reading level.**
- Plain, direct technical prose. Most sentences under ~25 words. Active voice, present tense.
- One idea per paragraph. Concrete nouns over abstractions.
- Lead with the answer; cut preamble.

**Banned register** (these are the academic tells):
- Throat-clearing: "It is worth noting that…", "In order to…", "It should be mentioned…".
- Hedging stacks: "it may potentially be possible that…".
- Nominalizations where a verb works ("performs a calculation of" → "calculates").
- Needless Latinate vocabulary; "utilize" → "use"; "in the event that" → "if".
- "We will now proceed to…". Just do the thing.
- Adverbs that don't change meaning.

**Jargon.** Define on first use OR link to the explanation doc. Never assume a term landed.

**Technical detail.**
- Show real code/config/values, not paraphrase. A runnable example + its **actual** output beats a
  description of what would happen.
- Tables for contracts and field lists; prose for the narrative thread.
- **Show, then explain:** lead each step with the artifact (YAML / JSON / command), then 1–3 lines on
  why. Mirror the achieved voice of the repo's existing how-to.

## Step 4 — Verify every claim before you write it (non-negotiable)

Every command, output, file path, field name, and **money amount** must be checked against source code
or the **running service** — not produced from reasoning.

- Run the command and quote its real output. Hit the endpoint and quote the real response.
- **Never hand-compute a value the system produces.** Money is the sharpest case: if the repo carries
  amounts as decimal strings with a pinned rounding mode, a float you worked out in your head will be
  subtly wrong and read as authoritative. Quote what the code actually returned. Check the repo's
  conventions (its `CLAUDE.md`, its model/schema) for how such values are represented.
- For worked examples, drive the real thing — call the live service with a real fixture, run the real
  script — and pull every value from what came back.
- If a value can't be verified right now, write `‹VERIFY›` in its place rather than guess, and list it
  in the handoff. A marked gap is fine; an invented number is not.

## Step 5 — Stamp the front-matter (automatic, never hand-typed)

Emit the same six-field block `/draft-spec` uses, at the top of the draft. Fill every field yourself:

```yaml
doc-type: tutorial | how-to | quickstart | brief | explanation   # the mode from Step 1
audience: <the named reader from Step 2 — never blank>
status: current
verified-against: <current commit SHA — run `git rev-parse --short HEAD`>
repo: <repo name>
source: <the plan/note/diff paths this was drafted from>
```

`verified-against` is the SHA at which Step 4's checks were run — it's how `/audit-plans` later
detects staleness. If verification hit a live endpoint instead of source, note that alongside the
SHA. For **explanation** mode, `source:` must name the promoted `docs/notes/` file; for **brief**
mode, the plan + reasoning note it was sourced from.

## Step 6 — Hand off (don't claim it's final)

Write the draft to the target path, then report:
- **Mode** chosen and why.
- **Voice source** — which sibling docs you matched.
- **Verified** — what you checked and how (commands run, endpoints hit, fixture used).
- **`‹VERIFY›` gaps** — anything left unverified.
- A plain line: *"Draft for your voice pass — re-voice in your own words, then optionally run the
  read-only factcheck."*

Then the breadcrumb: *next → `/wrap-up` if this closes a queued doc task, otherwise `/standup` for
the next action.*

## Self-audit before handing off

Reject your own draft if any of these are true:
- Any invented number, output, or field name.
- Academic tone slipped in (re-scan against the banned register).
- It re-explains a concept that already has a home doc.
- A *tutorial* offers more than one path, a *how-to* reads as one long story, a *quickstart* grew
  theory or branches, or an *explanation* rewrote its source note from scratch instead of
  transforming it.
- Any front-matter field is missing.
- Any money amount is unverified, or rendered as a float.
