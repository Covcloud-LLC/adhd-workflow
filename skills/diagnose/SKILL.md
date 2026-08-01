---
name: diagnose
description: Investigate a captured defect in docs/defects/, find the ROOT CAUSE with evidence, and recommend a specific fix — without applying it. Reproduces the failure, traces the real code path to the mechanism, checks git history for causation, treats the reporter's hunch as a lead not a verdict, and writes the diagnosis back to the defect file. Use when the user types /diagnose, or says "root-cause this bug", "why is this broken", "diagnose the defect", "find the root cause". Part of the defect workflow (see [[defect]]).
---

# /diagnose — root-cause a defect + recommend a fix

**Run guidance.** This is investigation and judgment, not pattern-matching: reproduce the
failure, trace it to the real mechanism, and **prove** the cause before you name it. In
Codex/OpenAI, run normal diagnoses at `gpt-5.5 · high`. In Claude Code, run normal diagnoses at
`claude-opus-4-8 · high`. Default recommendation when both are available: Codex/OpenAI
`gpt-5.5 · high`. Mention `claude-fable-5 · high` only for larger long-running autonomous work
where it is available; this skill recommends a fix and stops rather than executing it.

The deliverable is a root cause backed by evidence plus a specific recommended fix. It does
**not** apply the fix — the user decides and it lands in a separate step.

## Docs root (resolve this FIRST)

Before reading or writing any lifecycle doc, resolve the **docs root**:

- Let `<repo>` = basename of the current repo's git root (`basename "$(git rev-parse --show-toplevel)"`).
- If the config file `~/.config/adhd-workflow/backlog-root` exists, read it: it holds one line, the absolute path of a **backlog metarepo** (a git repo that centralizes backlog docs for many code repos) — call it `<backlog-root>`. If `<backlog-root>/<repo>/` exists, **that dir is the docs root** — `ideas/`, `plans/` (with `_done/`), `defects/`, and `BOARD.md` live directly under it (there is **no `docs/` path segment** inside the metarepo).
- Otherwise fall back to `./docs/` in the current repo, exactly as before.

Everywhere below, `docs/ideas/`, `docs/plans/`, `docs/defects/`, and `docs/BOARD.md` mean paths under the resolved docs root. **Reasoning notes follow the docs root too**: `docs/notes/` means `<backlog-root>/<repo>/notes/` when a metarepo is configured, and `./docs/notes/` in the code repo otherwise. Only lifecycle reasoning notes (`*-reasoning.md`, written by `/reason`) live there — durable design, decision, and reference docs stay in the code repo's own `./docs/notes/` and never move. Paths written *inside* a plan/idea/defect are relative to the code repo, not the metarepo.

**Writing under the metarepo:** when the docs root is the metarepo, every file you create, edit, move (`git mv`), or delete there is **immediately committed and pushed**, scoped to the affected path(s): `git -C <backlog-root> add <path> && git -C <backlog-root> commit -m "<msg>" && git -C <backlog-root> push`. This is a deliberate exception to the no-auto-commit rule and applies ONLY to writes under the metarepo. Reads and writes in the code repo (`scripts/slice-gate.sh`, git-based stall detection, durable `docs/notes/` reference docs) are unchanged and are **NOT** auto-committed.


## Steps

1. **Find the defect.** In `docs/defects/`, by slug/title or the most recently created `open` one.
   If ambiguous, list candidates and ask. Read it — the symptom, expected/actual, repro, and the
   reporter's **hunches** (a lead to test, not a conclusion). Note the `branch` — reproduce there.
2. **Reproduce first.** Drive the failing path for real — run the code, hit the endpoint, exercise
   the flow, write a failing test. If you **cannot** reproduce it, say so plainly and ask for the
   missing repro detail; do **not** invent a cause for a bug you can't observe.
3. **Trace to root cause.** Read the **actual** code path (not a guess); follow the data/state to
   where it breaks. **Verify causation before blaming anything:** `git log`/`git blame` the suspect
   lines to see whether a recent change is really responsible; confirm a library/tool's *real*
   behavior instead of assuming it. Confirm or refute the reporter's hunch with evidence — say
   which. Distinguish the **root cause** from the **symptom** and from mere correlation.
4. **State the root cause with evidence.** The exact `file:line` + the mechanism: a concrete
   input/state → the wrong output/crash, and *why*. Flag your **confidence** and call out any
   inferential leaps (don't overstate).
5. **Recommend a specific fix.** What to change, where (`file:line`), and why it addresses the
   **root cause, not the symptom**. Note blast radius / risk and what to verify after. If fixes
   compete, recommend one and name the tradeoff. A change that only hides the symptom is labeled as
   such.
6. **Write it back + hand off.** Append a `## Diagnosis (<date>)` section to the defect file (root
   cause, evidence, recommended fix, confidence) and flip `status: → diagnosed`. Then offer a
   **paste-ready fix task string** (paths + the change + a verify step) for a fresh build session —
   or `/promote` if the fix is plan-sized.
   **Do not apply the fix here** unless the user explicitly says "fix it" — and if they do, verify
   it (reproduce → confirm the repro now passes) before reporting done.

## Rules

- **Evidence over assertion.** Back every causal claim with something you read or ran — code, a
  log, git history, a repro. Never blame a recent change without checking history first (the user's
  standing rule).
- **Reproduce before diagnosing.** No repro → say so; don't guess.
- **Hunch is a lead, not a verdict.** Confirm or refute the reporter's theory explicitly.
- **Root cause, not symptom.** Trace the mechanism; flag any symptom-only patch.
- **Recommend, don't apply.** The fix is a separate, user-owned step (paste-ready task string, or
  `/promote` to a plan if it's substantial work).
