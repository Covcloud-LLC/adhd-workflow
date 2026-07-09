---
name: run-plan
description: Serial plan orchestrator — drives a plan's open slices to completion with no human between slices. Two subagents per slice (one authors the check, one implements); the orchestrator alone runs the scripted verification gate (scripts/slice-gate.sh) and obeys its exit code without interpretation. Use when the user types /run-plan <plan>, or says "run this plan", "execute the plan", "drive this plan to done". Halts on any red, never retries, resumes from git log. Part of the ADHD project-workflow system (see [[pjm]], [[wrap-up]], [[standup]], [[promote]]).
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

## 0 · Validate before slice 1 — refuse loudly, not at slice 4

Read the plan from the current repo's `docs/plans/<plan>.md`. Then check ALL of these, and on
any failure **name the offending slice (or header) and refuse to start**:

1. The plan carries a whole-tree **`> Check:`** header naming a runnable command.
2. Run that command once. Exit 0 → baseline green, proceed. Exit 126/127 → this repo has **no
   witness**; refuse. Any other non-zero → the tree is already red; refuse (a red baseline
   destroys attribution).
3. The working tree is **clean** (`git status --porcelain` is empty). Dirty → refuse.
4. Every **open** slice (no trailing ` ✅`) has: an explicit **Check:** / **Build:** split in its
   task string, and a **`Verify:`** that is a runnable command — not a description of a test to
   be written. A doc/spike/design slice (exempt per `/promote`'s red-gate rule) has no machine
   witness: name it and refuse — hand-run those via [[pjm]], or split the plan.
5. Create a scratch directory OUTSIDE the repo (`mktemp -d`) for subagent reports. Reports never
   land in the tree — the tree belongs to the slices.

## 1 · The per-slice loop — strictly serial, in plan order

For each open slice, top to bottom:

1. **Spawn agent A** with the slice's **Check: text only** — plus: "Author the check described.
   Implement nothing else. Do not run the plan's other commands, do not read the plan file, do
   not commit. Write your notes to `<scratch>/<slice-id>-A.md`." A returns; you read **nothing**
   it says.
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
- **Model tier**: spawn A and B at the plan's `Model` / `Effort` header (per-slice `Run at:`
  overrides it when present).

## 3 · Failure = halt

Any red gate, any harness error, any blocked/failed subagent, any missing check: **halt
immediately.** Leave the working tree exactly as it is — no cleanup, no `git checkout`, no
second try, ever. A flaky-looking red is still a red; retrying is interpretation. Report: the
slice id, the exact failing command, its exit code, and the scratch-dir paths. The resume point
is already in `git log`.

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
the halt (slice id + failing command + exit code) if any, whole-tree check status, scratch-dir
path, and the reminder that nothing was pushed. If every slice is now ` ✅`, recommend the plan's
completion flip but do not perform it — that is `/wrap-up`'s call with the user present.

End with the single breadcrumb: when the run is over — halted or done — run `/wrap-up` to
reconcile the plan and capture what was learned.
