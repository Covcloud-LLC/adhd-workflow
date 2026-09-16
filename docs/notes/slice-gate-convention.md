# The slice gate — the convention behind a machine-written ` ✅`

> Named convention: **the slice gate**. Implementation: `scripts/slice-gate.sh`.
> Readers: any orchestrator that runs a plan's slices (the Claude Code Workflow tool today), and
> `/wrap-up` (defers to it for gate-stamped slices).
> Sits beside the ` ✅` marker and the run-tier header in `CLAUDE.md`'s conventions table.

A trailing ` ✅` on a `### <id>` slice heading claims the slice is done. When a machine run writes
that marker, this convention defines — once, by name — what must have been witnessed first. A
workflow run and `/wrap-up` both flip ` ✅`, and prose cannot be factored into a shared function,
so the gate is defined here and referenced by name.

## The five facts, in order

A slice may be marked ` ✅` by a machine run only after all five, in this order:

1. **Preflight red** — the slice's check, freshly authored by agent A, fails.
2. **Agent B implements** — a separate agent, given only the Build text, does the work.
3. **Postflight green** — the same check now passes.
4. **Whole-tree green** — the repo's whole-tree check (the plan's `> Check:` header) passes.
5. **Check untouched** — agent A's check files are exactly as A committed them.

## Who runs it

The **orchestrator** is whatever runs the loop — today a Claude Code Workflow script. It decides
by exit code alone. No model's opinion about red, green, blocked, or done is an input.

A Workflow script has no filesystem or process access, so it cannot run the gate itself. A
**verify agent** runs `slice-gate.sh` and returns the exit code in a schema field; the script
branches on that field. The verify agent must be neither agent A nor agent B. Its only job is
to run one command un-piped and report `$?`. **Say this plainly: the exit code reaches the
script as an agent's report, not as a process the script observed.** What keeps that report
honest is that the reporter wrote neither the check nor the code and has nothing else to do.

A repo with **no whole-tree check has no witness, and the gate cannot run there.** No build, no
tests, nothing that can exit non-zero → refuse with "this repo has no witness." In this repo the
whole-tree check is `bash scripts/check.sh`.

**Finding the script from a code repo.** The gate lives in the workflow repo, not the code repo.
Resolve it through any installed skill's symlink: `readlink ~/.claude/skills/promote` (or
`~/.codex/skills/promote`) names `<workflow-repo>/skills/promote`; the script is
`<workflow-repo>/scripts/slice-gate.sh`.

## One slice as Workflow steps

**Before slice 1, the launching session cuts a branch.** On a clean tree, cut
`feat/<plan-slug>` off the default branch and run the workflow there — never on the default branch
itself. A run that commits every slice onto the default branch cannot become a PR afterwards
without moving commits, and `/ship` on a clean default branch would push it directly. If `HEAD` is
some other branch that does not already carry this plan's `<slice-id>:` commits, stop and ask:
landing a plan on top of unrelated work is the user's decision.

For a slice with a Check/Build split:

1. Agent A gets only the Check text and writes the check. It implements nothing.
2. Derive A's check paths with `git status --porcelain -uall`. Without `-uall`, git collapses a
   new untracked directory to one line, the check path becomes the whole directory, and agent B's
   implementation inside it then fails fact five by construction.
3. The verify agent commits A's check alone, message `<slice-id>: check` (use `--no-verify`: a
   pre-commit typecheck fails by construction on a red check), and returns that sha — `sha-A` — in
   its schema result.
4. Verify agent runs `slice-gate.sh preflight <check-cmd> <check-paths…>`. The script halts unless
   the exit is **0** (genuine red). 1 = vacuous green, 2 = harness error; both halt.
5. Agent B gets only the Build text and implements.
6. Verify agent runs `slice-gate.sh postflight <check-cmd> <tree-cmd> <check-paths…> <sha-A>`. The
   script halts unless the exit is **0**.
7. The same verify agent commits the build, message `<slice-id>: build`, and returns that sha.
   Commits are the verify agent's job because it is the one agent whose only work is mechanical;
   A and B never commit.

For a slice whose task string names a red-gate exemption (doc, spike, design, below the red-gate
threshold): one agent does the work, a verify agent runs the whole-tree check, and the script
halts unless it exits 0 and then commits the slice (`<slice-id>: build`). The stamp says
`single-agent`.

On any halt: stop, leave the tree as it is, never retry. The last `<slice-id>: build` commit is the
last finished slice — that is the resume point, whether or not any marker was written. The user
fixes the plan or the code, commits the fix or resets to that commit, and resumes the workflow by
run ID on a clean tree.

**Who writes the marker, and who commits it.** No slice agent writes the plan file. The workflow
returns, per slice, its id, lane, check command, `sha-A`, and build sha. After it returns — clean
or halted — the session that launched it writes each finished slice's stamp, matching the slice by
id and re-reading the plan first. Then it commits the stamps: when the plan lives in a backlog
metarepo, the metarepo write rule already commits and pushes them; when the plan lives in the code
repo, commit them as one `<plan-slug>: stamp slices` commit on the run's branch, so the tree is
clean for the next resume or for `/ship`. A stamp that never gets written loses nothing: the
commits still record the work, and `/wrap-up` can confirm the slice by hand.

**After the run, a quality pass changes the witnessed tree.** If the user runs `/simplify` over
the run's commits and accepts its edits, each stamp's `(<command>, <sha>)` describes a tree that
no longer exists. Re-run the plan's `> Check:` command after accepting them; leave the stamps as
they are — they record what the gate saw, at that sha — and review last.

**Gated slices of one plan run serially, in one tree.** A whole-tree check that was green before a
slice and red after it blames that slice — but only when slices run one at a time on the same
tree. Parallel agents in separate worktrees each verify a tree that will never ship; two slices
can pass alone and fail together, and nobody ran the check on the merge. So `parallel()` and
worktree isolation are for independent or ungated work, not for the gated slices of one plan.

## Why a script, and why two agents

**A script, not prose.** A prose gate — "check that the tests pass" — is a suggestion made to
something that wants to agree with you. One night a model decides a red test is unrelated and
continues. An exit code cannot be talked past.

**Two agents, not one.** The check does not exist before the slice runs; the slice writes it. If
the agent that writes the check also writes the code, a misread spec produces a wrong test and
code that passes it — the same mistake twice. Separate authorship breaks that correlation, and
fact five stops agent B from deleting or weakening the check to go green.

**The human moves to the entry gate.** The user accepts the check when they accept the plan at
`/promote` time, with the intent loaded. That is where a human's judgment actually applies.

## Fact one, precisely: what counts as red

A red is only evidence when the check is red **for the reason the slice claims** — a failing
assertion, not a failure to run. `preflight` shells out to the check command; a check file that
does not exist (exit 127), a syntax error (exit 2), and a typo'd path are all non-zero, and to a
naive gate they are the same number as a genuine assertion failure. That gate green-lights agent
B on a check that never ran.

The contract:

- `preflight` takes the check **paths** as well as the check command, and requires every named
  path to **exist and be non-empty** before running anything. A missing or empty check path is a
  **harness error** — halt.
- Check exit **1** is the only genuine red → proceed. Real suites — vitest, jest, pytest, a plain
  shell test — fail their assertions with 1; higher codes mean the suite failed to *run*.
- Check exit **0** is a vacuous check, or the work already exists → halt.
- Any other exit — **2 through 125 (interpreter/usage errors) and ≥ 126 (not executable, not
  found)** — is a **harness error** → halt, with a stderr message distinct from the vacuous-green
  case. The gate itself exits **2** for a harness error (against **0** = genuine red, proceed;
  **1** = vacuous green, halt) so the orchestrator reports "the check could not run," never "the
  check was already green."

## Fact five, precisely: what counts as untouched

`git diff --name-only <agent-a-sha> -- <check-paths>` catches every modification to a tracked
check file, working-tree or committed. It **cannot see a file agent B adds** under a check path,
because `git diff` reports only tracked files. An added file is a real threat, not a
technicality: check paths may be directories, and test harnesses execute what they find — a new
`conftest.py` is auto-loaded by pytest, a glob-driven runner picks up any file dropped beside the
tests — so an addition can neuter assertions without editing a byte of them.

The decision: **tighten.** The authoritative assertion is the pair, and both must be empty:

- `git diff --name-only <agent-a-sha> -- <check-paths>` — modifications, including committed ones;
- `git status --porcelain -- <check-paths>` — additions, and uncommitted modifications.

Neither alone suffices: `git status` cannot see a committed modification, and `git diff` cannot
see an untracked addition. Either command producing any output fails fact five. (This postflight
read deliberately does **not** use `-uall`: the collapsed form still reports any addition.)

## Why `/wrap-up` keeps the human confirm

`/wrap-up`'s confirm-before-flip is the gate for **hand-run** slices, where the human is the
witness. It must never gain a "machine confirms instead of human" mode or flag: that flag exists
forever, and one day a subagent finds it and uses it on itself. Work with a machine witness goes
through a gated workflow run; everything else keeps the human. The two partition work by whether
a witness exists — there is no third mode.

## Provenance

A gate-written marker carries its witness: ` ✅ (<check-command>, <sha>)` — the command the verify
agent ran green and the commit of agent A's check. An exempt slice's marker is
` ✅ (<check-command>, single-agent)`. A bare ` ✅` is a hand-confirmed one; a reader three weeks
later can tell how much to trust each.
