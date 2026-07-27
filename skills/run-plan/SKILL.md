---
name: run-plan
description: Serial plan orchestrator — drives a plan's open slices to completion with no human between slices. Two subagents per slice (one authors the check, one implements); slices whose task string names a red-gate exemption run single-agent, gated on the whole-tree check. The orchestrator alone runs the scripted verification gate (scripts/slice-gate.sh) and obeys its exit code without interpretation. Use when the user types /run-plan <plan>, or says "run this plan", "execute the plan", "drive this plan to done". Halts on any red or on a pre-build question from a subagent, never retries, resumes from git log, and invokes [[wrap-up]] when the run ends. Part of the ADHD project-workflow system (see [[pjm]], [[wrap-up]], [[standup]], [[promote]]).
---

# Run a plan — serial, gated, unwitnessed by no one

You are the **orchestrator**: a for-loop with a checkbook, not a reviewer. You spawn subagents,
run a script, read exit codes, commit, and write one marker. You hold no opinion about the work.
Model judgment lives **inside the subagents**, where nothing they say is used for anything; every
green you act on is a **process exit code you observed yourself**. A prose gate is a suggestion
made to something that wants to agree with you — so the gate is a script, and you obey it
without interpretation. If the script is missing, you do not run.

The gate and its contract: `scripts/slice-gate.sh`, defined in
`docs/notes/slice-gate-convention.md` (both in the workflow repo — resolve the script relative
to this skill file's real location: the skill directory is a symlink into the workflow repo, and
the script lives at `<workflow-repo>/scripts/slice-gate.sh`). The five facts, in order: preflight
red on the slice's check → agent B implements → postflight green on the same check → whole-tree
green → agent A's check files untouched. Only then does ` ✅` get written.

## Docs root (resolve this FIRST)

Before reading or writing any lifecycle doc, resolve the **docs root**:

- Let `<repo>` = basename of the current repo's git root (`basename "$(git rev-parse --show-toplevel)"`).
- If the config file `~/.config/adhd-workflow/backlog-root` exists, read it: it holds one line, the absolute path of a **backlog metarepo** (a git repo that centralizes backlog docs for many code repos) — call it `<backlog-root>`. If `<backlog-root>/<repo>/` exists, **that dir is the docs root** — `ideas/`, `plans/` (with `_done/`), `defects/`, and `BOARD.md` live directly under it (there is **no `docs/` path segment** inside the metarepo).
- Otherwise fall back to `./docs/` in the current repo, exactly as before.

Everywhere below, `docs/ideas/`, `docs/plans/`, `docs/defects/`, and `docs/BOARD.md` mean paths under the resolved docs root. **Reasoning notes are the exception: `docs/notes/` ALWAYS stays in the current code repo's own `./docs/notes/`, never the metarepo.** Paths written *inside* a plan/idea/defect are relative to the code repo, not the metarepo.

**Writing under the metarepo:** when the docs root is the metarepo, every file you create, edit, move (`git mv`), or delete there is **immediately committed and pushed**, scoped to the affected path(s): `git -C <backlog-root> add <path> && git -C <backlog-root> commit -m "<msg>" && git -C <backlog-root> push`. This is a deliberate exception to the no-auto-commit rule and applies ONLY to writes under the metarepo. Reads and writes in the code repo (reasoning notes, `scripts/slice-gate.sh`, git-based stall detection) are unchanged and are **NOT** auto-committed.


## 0 · Validate before slice 1 — refuse loudly, not at slice 4

Read the plan from the current repo's `docs/plans/<plan>.md`. Then check ALL of these, and on
any failure **name the offending slice (or header) and refuse to start**:

1. The plan's slices are **`### <id> — <title>` headings** (the only dialect this runner speaks —
   the ` ✅` stamp lands on that heading). A plan whose slices are legacy bold paragraph lines
   (`**<ID>-n — …** · status · depends: …`) has no slices you can find or stamp: refuse and point
   at `/audit-plans`, which offers the conversion.
2. The plan carries a whole-tree **`> Check:`** header naming a runnable command.
3. Run that command once. Exit 0 → baseline green, proceed. Exit 126/127 → this repo has **no
   witness**; refuse. Any other non-zero → the tree is already red; refuse (a red baseline
   destroys attribution).
4. The working tree is **clean** (`git status --porcelain` is empty). Dirty → refuse.
5. Every **open** slice (no trailing ` ✅` marker on its heading) has a **`Verify:`** that is a
   runnable command — not a description of a test to be written — and either an explicit
   **Check:** / **Build:** split in its task string, or a **named exemption** (see the
   single-agent lane below). A non-exempt slice with no Check/Build split is a real authoring
   defect: name it and refuse.
6. Create a scratch directory OUTSIDE the repo (`mktemp -d`) for subagent reports. Reports never
   land in the tree — the tree belongs to the slices.

## 1 · The per-slice loop — strictly serial, in plan order

For each open slice, top to bottom, first pick its lane. **A slice whose task string names its
exemption runs the single-agent lane** (section 1b) — `/promote` requires an exempt slice to say
so in the task text ("Exempt from the Check/Build split…", "Exemption: example/fixture-authoring
slice", "Doc slice (red-gate exempt)…"), so the task string is the detector; you do not judge
whether a slice *deserves* the exemption, only whether it declares one. Everything else runs the
two-agent loop below. A non-exempt slice with no Check/Build split never runs — that was refused
at step 0.

1. **Spawn agent A** with the slice's **Check: text only** — plus: "Author the check described.
   Implement nothing else. Do not run the plan's other commands, do not read the plan file, do
   not commit. Write your notes to `<scratch>/<slice-id>-A.md`. If the task is genuinely
   ambiguous — two readings that produce materially different checks — and you have **not yet
   written anything**, write the question to `<scratch>/<slice-id>-QUESTION.md` and exit with
   code 3; do not guess, and do not ask once you have started writing." A returns; you read
   **nothing** it says — but if `<slice-id>-QUESTION.md` exists (or A exited 3), take the
   **question exit** (section 3b).
2. **A's check paths are defined by git, not by A's report**: they are exactly the paths
   `git status --porcelain` now lists. If it lists nothing, halt (A produced no check).
3. **Preflight**: run `bash <gate> preflight '<Verify-command>' <check-paths...>` — directly,
   never through a pipe or a chained `&&` off an echo; capture `$?` immediately (a piped gate
   invocation silently loses the exit code under zsh).
   - exit 0 → genuine red, proceed.
   - exit 1 → the check is already green: vacuous check, or the work already exists. **Halt.**
   - exit 2 → harness error (missing/empty check, check couldn't run). **Halt.**
4. **Commit A's check alone**: `git add <check-paths>` and commit as `<slice-id>: check`,
   with `--no-verify`: a pre-commit typecheck or lint hook fails **by construction** on a check
   that references API the Build hasn't written yet — that red is the point, not a defect.
   Hooks run normally on the build commit, which must satisfy them. Record the sha — `sha_A`.
5. **Spawn agent B** with the slice's **Build: text only** — plus: "Implement until
   `<Verify-command>` passes. Do not modify or add anything under `<check-paths>` — the check
   is committed and the gate diffs it. Do not read the plan file, do not commit. Write your
   notes to `<scratch>/<slice-id>-B.md`." B returns; you read **nothing** it says.
6. **Postflight**: run `bash <gate> postflight '<Verify-command>' '<Check-header-command>'
   <check-paths...> <sha_A>`. It asserts, in order: slice check **green**, whole-tree **green**,
   and check paths **untouched** since `sha_A` (both `git diff --name-only sha_A` and
   `git status --porcelain`, scoped to the check paths, empty — an added file fails it too).
   Any exit ≠ 0 → **Halt.**
7. **Stamp and land**: append ` ✅ (<Verify-command>, <sha_A>)` to the slice's `### <id>` heading
   — provenance is the command that went green and the check commit it ran against. Then commit
   B's work **and** the stamped plan file together as `<slice-id>: <slice title>`. The marker
   and the work land atomically; a crash before this commit leaves no marker and a dirty tree,
   which resume (below) treats as a partial slice.
8. Next slice.

Two commits per slice, both tagged with the slice id. **Commit, never push** — a local commit is
reversible; a push is not. The user pushes.

## 1b · The single-agent lane — exempt slices

Doc, example/fixture, and spike slices are exempt from the Check/Build split by `/promote`'s own
red-gate rule — there is no separate check to author, because the artifact is its own check or
there is nothing to red-test. Refusing them would refuse plans `/promote` told the user to
write. They run, with a weaker gate:

1. **Spawn one agent** with the slice's **whole task string** — plus: "Do not read the plan
   file, do not commit. Write your notes to `<scratch>/<slice-id>.md`. If the task is genuinely
   ambiguous and you have **not yet written anything**, write the question to
   `<scratch>/<slice-id>-QUESTION.md` and exit with code 3; do not guess, and do not ask once
   you have started writing." No A/B pair. The agent returns; you read **nothing** it says —
   but if `<slice-id>-QUESTION.md` exists (or the agent exited 3), take the **question exit**
   (section 3b).
2. **No preflight, no check-files-untouched assertion.** There is no independent check to go
   red and no agent-A files to protect — skip both, deliberately, not silently.
3. **Postflight**: run the plan's whole-tree **`> Check:`** command directly (un-piped, `$?`
   immediately). Exit 0 → proceed. Anything else → **Halt.**
4. **Stamp and land**: append ` ✅ (<Check-header-command>, single-agent)` to the slice's
   `### <id>` heading and commit the work and the stamped plan file together as
   `<slice-id>: <slice title>`. One commit, not two.

**This gate is weaker, and the stamp says so.** The two-agent stamp names a check authored by a
party with no stake in the implementation; `single-agent` in the provenance tells a reader three
weeks later that no independent check existed. It is still honest work, not a rubber stamp: an
exempt slice's output lands in territory the whole-tree command already covers — everything
under `examples/` is validated by the repo's own check command — so the work has a witness, just
not an independent one. What the weaker gate cannot catch is an agent that does *less* than the
task asked; the whole-tree green only proves it broke nothing.

## 2 · Invariants — the design is these, not the loop

- **Only you run the gate.** No subagent invokes `slice-gate.sh`, runs `/wrap-up`, writes the
  plan file, or produces a verdict you act on. A subagent's "it passes now" is not an input.
- **You never read a diff or a subagent's output.** You handle three datums per slice: slice id,
  exit code, sha. Each agent's narrative goes straight to disk in the scratch dir; if the user
  wants the story, the files are there.
- **You are the sole writer of the plan file.** Write by matching the `### <slice-id>` heading
  text — never a line number. **Re-read the file immediately before each write**; if the heading
  you matched at start has changed or moved, **abort the run** and tell the user what completed.
  Do not reconcile a concurrent hand-edit — "the file moved under me, here's what finished, you
  drive" is always correct.
- **Model tier**: spawn A and B at the slice's `Run at:` tier, falling back to the plan's
  `Default run tier:` header when the slice carries no `Run at:` line. The slice line always wins —
  over the plan default and over the plan's at-a-glance table. Legacy plans may carry the older
  `Model:` / `Effort:` header instead; read it the same way and do not refuse over it.

## 3 · Failure = halt

Any red gate, any harness error, any blocked/failed subagent, any missing check: **halt
immediately.** Leave the working tree exactly as it is — no cleanup, no `git checkout`, no
second try, ever. A flaky-looking red is still a red; retrying is interpretation. Report: the
slice id, the exact failing command, its exit code, and the scratch-dir paths. The resume point
is already in `git log`.

## 3b · The question exit — bounded, pre-build only

A subagent that hits a **genuine ambiguity** may surface it instead of guessing — through one
narrow door, code **3** (the gate already owns 0, 1, and 2): it writes the question to
`<scratch>/<slice-id>-QUESTION.md` and exits 3, having written **nothing else**.

- **You relay; you never interpret.** On the question exit: halt the run, name the slice, and
  print the question file **verbatim**. Do not answer it, do not guess, do not rank the options,
  do not add your own reading of the task. An orchestrator with an opinion about the work is the
  rejected design wearing a new hat.
- **A question is legal only before the build starts** — agent A, or the single agent of an
  exempt slice, before it has written anything. Agent B has no question exit, and neither does
  any agent that has already started writing: once implementation has begun, the answer is
  **halt**, not negotiate. A mid-build question is usually "I got stuck" wearing a question
  mark, and letting it reopen the task is how an orchestrator turns into a chat session — the
  task string was accepted at `/promote` time; if it stops being executable mid-build, that is a
  failure to report, not a conversation to have.
- **Resume is the normal resume.** The user answers by **editing the slice's task string** to
  remove the ambiguity, then re-invoking `/run-plan`, which resumes from `git log` exactly as
  after any halt. There is no answer-passing channel — the fixed task string IS the answer, and
  it lands where the answer belongs: in the plan, where the next cold session reads it too.

## 4 · Resume

On re-invocation for the same plan:

- **Refuse to resume on a dirty tree.** The failed slice's leftovers and the user's fix are
  indistinguishable; make the user declare intent — commit the fix, or `git reset --hard` back
  to the last slice commit — then run again.
- Reconstruct completed slices from **`git log`** (the `<slice-id>:` commits), not from the
  ` ✅` markers — the log is the in-flight state, the markers are the durable state. A slice with
  a landed build commit but no marker gets its marker re-stamped, not re-run. Resume at the
  first slice with no build commit.
- Re-run step 0's validation in full before continuing.

## 5 · Report

When the run halts or completes, report: slices completed this run (id → build-commit sha),
the halt if any — **labelled by kind**: a **red-gate halt** (slice id + failing command + exit
code) or a **question halt** (slice id + the question file printed verbatim + the reminder that
the answer is an edit to that slice's task string, then re-invoke `/run-plan`) — whole-tree
check status, scratch-dir path, and the reminder that nothing was pushed. If every slice is now ` ✅`, recommend the plan's
completion flip but do not perform it — that is `/wrap-up`'s call with the user present.

## 6 · End of run — invoke `/wrap-up` yourself

When the run ends — clean completion **or** halt, either kind — deliver the report above, then
**invoke the `wrap-up` skill** rather than ending with a breadcrumb telling the user to run it.
Once per run, never per slice: the ` ✅` stamp already reconciled each slice mechanically, and
`/wrap-up` is a session-level ritual — running it nine times in a nine-slice run would grind its
confirms into noise the user stops reading. Machine invocation changes nothing about `/wrap-up`
itself: it keeps every confirm-before-writing rule — it still asks before flipping plan status
or archiving to `_done/`, and it must never gain a machine-confirms mode (the slice-gate
convention says why). That is the point of calling it: the run ends by handing the human the
reconciliation seat with the report already on screen, instead of leaving a chore behind.
