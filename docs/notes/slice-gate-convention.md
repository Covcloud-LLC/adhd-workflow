# The slice gate — the convention behind a machine-written ` ✅`

> Named convention: **the slice gate**. Implementation: `scripts/slice-gate.sh`.
> Readers: `/run-plan` (runs the gate per slice) and `/wrap-up` (defers to it for gate-stamped slices).
> Sits beside the ` ✅` marker and the `Model`/`Effort` header in `CLAUDE.md`'s conventions table.

A trailing ` ✅` on a `### <id>` slice heading claims the slice is done. When a machine writes
that marker, this convention defines — once, by name — what must have been witnessed first.
Both `/run-plan` and `/wrap-up` flip ` ✅`, and prose cannot be factored into a shared function,
so the gate is defined here and referenced by name, the way ` ✅` and the `Model`/`Effort`
header already are.

## The five facts, in order

A slice may be marked ` ✅` only after all five, in this order:

1. **Preflight red** — the slice's check, freshly authored by agent A, fails.
2. **Agent B implements** — a separate session, given only the Build text, does the work.
3. **Postflight green** — the same check now passes.
4. **Whole-tree green** — the repo's whole-tree check passes.
5. **Check untouched** — agent A's check files are exactly as A committed them.

## Who runs it

The **orchestrator — never a subagent — runs each step** and obeys the exit code without
interpretation. A subagent's report is never an input to the gate: nothing an agent *says*
about red, green, blocked, or done is used for anything. The gate decides by process exit code
alone; no model is in the decision path.

A repo with **no whole-tree check has no witness, and the gate cannot run there.** No build, no
tests, nothing that can exit non-zero → refuse with "this repo has no witness." In this repo
the whole-tree check is `bash scripts/check.sh`.

## Fact one, precisely: what counts as red

*(Specified here; implemented in RUN-3b.)*

A red is only evidence when the check is red **for the reason the slice claims** — a failing
assertion, not a failure to run. `preflight` shells out to the check command; a check file that
does not exist (exit 127), a syntax error (exit 2), and a typo'd path are all non-zero, and to
a naive gate they are the same number as a genuine assertion failure. That gate green-lights
agent B on a check that never ran.

The contract:

- `preflight` takes the check **paths** as well as the check command, and requires every named
  path to **exist and be non-empty** before running anything. A missing or empty check path is
  a **harness error** — halt.
- Check exit **1** is the only genuine red → proceed. Real suites — vitest, jest, pytest, a
  plain shell test — fail their assertions with 1; higher codes mean the suite failed to *run*.
- Check exit **0** is a vacuous check, or the work already exists → halt.
- Any other exit — **2 through 125 (interpreter/usage errors) and ≥ 126 (not executable, not
  found)** — is a **harness error** → halt, with a stderr message distinct from the
  vacuous-green case. The gate itself exits **2** for a harness error (against **0** = genuine
  red, proceed; **1** = vacuous green, halt) so the orchestrator reports "the check could not
  run," never "the check was already green."

## Fact five, precisely: what counts as untouched

*(Specified here; implemented in RUN-3b.)*

`git diff --name-only <agent-a-sha> -- <check-paths>` catches every modification to a tracked
check file, working-tree or committed. It **cannot see a file agent B adds** under a check
path, because `git diff` reports only tracked files. An added file is a real threat, not a
technicality: check paths may be directories, and test harnesses execute what they find — a new
`conftest.py` is auto-loaded by pytest, a glob-driven runner picks up any file dropped beside
the tests — so an addition can neuter assertions without editing a byte of them.

The decision: **tighten.** The authoritative assertion is the pair, and both must be empty:

- `git diff --name-only <agent-a-sha> -- <check-paths>` — modifications, including committed ones;
- `git status --porcelain -- <check-paths>` — additions, and uncommitted modifications.

Neither alone suffices: `git status` cannot see a committed modification, and `git diff` cannot
see an untracked addition. Either command producing any output fails fact five.

## Why `/wrap-up` keeps the human confirm

`/wrap-up`'s confirm-before-flip is the gate for **hand-run** slices, where the human is the
witness. It must never gain a "machine confirms instead of human" mode or flag: that flag
exists forever, and one day a subagent finds it and uses it on itself. Work with a machine
witness goes through `/run-plan`, which runs this gate; everything else keeps the human. The
two modes partition work by whether a witness exists — there is no third mode.

## Provenance

A gate-written marker carries its witness: ` ✅ (<check-command>, <sha>)` — the command the
orchestrator observed go green and the commit of the slice's landed work. A bare ` ✅` is a
hand-confirmed one; a reader three weeks later can tell how much to trust each.
