---
name: defect
description: Frictionless capture of a defect/bug into docs/defects/ of the current repo — the symptom, expected-vs-actual, repro (if known), and your initial hunches about the cause. Use when the user types /defect, or says "log a bug", "capture this defect", "something's broken", "note this bug for later". Writes one file and stops — does NOT investigate, root-cause, or fix (that's /diagnose). Part of the defect workflow (see [[diagnose]]).
---

# Capture a defect (and get out of the way)

The point is **low friction**. The user hit a bug mid-flight; your job is to get their observation
and hunches onto disk so they can keep moving — then stop. Do **not** read the code to explain it,
do **not** root-cause it, do **not** fix it. That's `/diagnose`. Capture and return.

## Steps

1. Resolve the repo's defects dir: `docs/defects/` relative to the git root
   (`git rev-parse --show-toplevel`). Create it if missing.
2. Derive a short kebab-case slug from the symptom (e.g. "premium doesn't refresh after editing a
   limit" → `premium-no-refresh-on-limit-edit`).
3. Get today's date: `date +%Y-%m-%d`. Also capture the current branch
   (`git branch --show-current`) — a bug is often branch-specific.
4. Write `docs/defects/<slug>.md`:

```markdown
---
name: <slug>
created: <YYYY-MM-DD>
status: open
severity: <if the user said (blocker/high/medium/low); else "unassessed">
branch: <current branch>
---

# <Title — the symptom in a phrase>

**Symptom:** <what the user saw — their words>
**Expected:** <what should have happened — if said; else "(not captured)">
**Actual:** <what happened instead — if distinct from symptom; else "(not captured)">
**Repro:** <steps to reproduce, if given; else "(not captured)">
**Hunches:** <the user's initial thoughts on the cause — VERBATIM; "(none yet)" if none given>
**Where seen:** <URL / screen / endpoint / data / build — whatever the user mentioned>

<Any extra detail the user gave, verbatim. Nothing more.>
```

5. Confirm in one line: the path written and the title. Then one breadcrumb line —
   "`/diagnose <slug>` when you want the root cause" — and nothing else. No diagnosis, no "shall I investigate".

## Rules

- Capture the user's **observation** and **hunches** — do NOT verify, diagnose, or fix. The hunch
  is recorded as a *lead for `/diagnose`*, never as a confirmed cause.
- Don't interrogate. Fill what the user gave; mark the rest `(not captured)`. The one allowed
  question, only if the thought is genuinely empty: "What's the defect?"
- Slug collision → append `-2`, `-3`.
- Never write to `docs/plans/`. A defect stays a defect until `/diagnose` root-causes it and the
  fix lands (a big fix may then graduate to a plan via `/promote`).
