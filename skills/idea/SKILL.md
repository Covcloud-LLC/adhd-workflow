---
name: idea
description: Frictionless capture of a raw idea into docs/ideas/ of the current repo. Use when the user types /idea, or says "capture this idea", "jot this down", "note this for later", "park this thought". Writes one low-friction file and stops — does NOT promote, plan, or start work. Part of the ADHD project-workflow system (see [[promote]], [[standup]], [[audit-plans]]).
---

# Capture an idea (and get out of the way)

The whole point is **low friction**. The user has a thought mid-flight; your job is to get it onto disk so the novelty stops hijacking their attention — then stop. Do **not** ask clarifying questions, do **not** flesh it out, do **not** promote it to a plan, do **not** start building. Capture and return.

## Docs root (resolve this FIRST)

Before reading or writing any lifecycle doc, resolve the **docs root**:

- Let `<repo>` = basename of the current repo's git root (`basename "$(git rev-parse --show-toplevel)"`).
- If the config file `~/.config/adhd-workflow/backlog-root` exists, read it: it holds one line, the absolute path of a **backlog metarepo** (a git repo that centralizes backlog docs for many code repos) — call it `<backlog-root>`. If `<backlog-root>/<repo>/` exists, **that dir is the docs root** — `ideas/`, `plans/` (with `_done/`), `defects/`, and `BOARD.md` live directly under it (there is **no `docs/` path segment** inside the metarepo).
- Otherwise fall back to `./docs/` in the current repo, exactly as before.

Everywhere below, `docs/ideas/`, `docs/plans/`, `docs/defects/`, and `docs/BOARD.md` mean paths under the resolved docs root. **Reasoning notes follow the docs root too**: `docs/notes/` means `<backlog-root>/<repo>/notes/` when a metarepo is configured, and `./docs/notes/` in the code repo otherwise. Only lifecycle reasoning notes (`*-reasoning.md`, written by `/reason`) live there — durable design, decision, and reference docs stay in the code repo's own `./docs/notes/` and never move. Paths written *inside* a plan/idea/defect are relative to the code repo, not the metarepo.

**Writing under the metarepo:** when the docs root is the metarepo, every file you create, edit, move (`git mv`), or delete there is **immediately committed and pushed**, scoped to the affected path(s): `git -C <backlog-root> add <path> && git -C <backlog-root> commit -m "<msg>" && git -C <backlog-root> push`. This is a deliberate exception to the no-auto-commit rule and applies ONLY to writes under the metarepo. Reads and writes in the code repo (`scripts/slice-gate.sh`, git-based stall detection, durable `docs/notes/` reference docs) are unchanged and are **NOT** auto-committed.


## Steps

1. Resolve the repo's ideas dir: `docs/ideas/` relative to the git root (`git rev-parse --show-toplevel`). Create it if missing.
2. Derive a short kebab-case slug from the thought (e.g. "what if standup also flagged stale branches" → `standup-flag-stale-branches`).
3. Get today's date: `date +%Y-%m-%d`.
4. Write `docs/ideas/<slug>.md`:

```markdown
---
name: <slug>
created: <YYYY-MM-DD>
status: idea
---

# <Title Case of the idea>

**What:** <one or two sentences — the idea itself, in the user's words>
**Why:** <one line — why it might matter / what problem it scratches. If the user didn't say, write "(not yet articulated)" — do NOT invent a rationale.>

<Any extra detail the user gave, verbatim. Nothing more.>
```

5. Confirm in one line: the path written and the title. Then one breadcrumb line — "when ready: `/reason <slug>`" — and nothing else. No summary, no "would you like me to…".

## Rules

- If the slug collides with an existing idea file, append `-2`, `-3`, etc.
- Never write to `docs/plans/`. Ideas are not plans until `/promote` passes the quality gate.
- If the user's thought is genuinely empty (no content), ask only "What's the idea?" — that's the one allowed question.
