---
name: apply-pr-feedback
description: Review PR feedback critically, apply only the suggestions you concur with, and explain your reasoning for each decision. Pass --merge to also commit, push, and merge the branch once the checks pass.
argument-hint: '<PR number or URL> [--merge]'
---

# Apply PR Feedback

Review feedback on a pull request, critically evaluate each comment, and apply only the changes you agree with as an experienced developer. You are expected to exercise independent judgment — not blindly accept every suggestion.

> **Solo-repo note:** Ken is the only human on this repo; reviews come from bots
> (`copilot-pull-request-reviewer`, `chatgpt-codex-connector`). Bot findings are
> plausible-but-sometimes-wrong — verify every claim against the actual code/behavior before
> applying (run the code path, check the tool's real matching semantics, etc.). Never post
> replies to bot comments; report the triage in the conversation instead.

## Step 0: Resolve the PR

If $ARGUMENTS is empty, detect the current branch and find its open PR using `gh pr view --json number,url,title,headRefName`. If no PR is found, ask the user to provide a PR number.

Otherwise, parse $ARGUMENTS as a PR number or URL.

## Step 1: Fetch all review feedback

Use `gh` CLI to retrieve:

```bash
# PR review comments (inline code comments)
gh api repos/{owner}/{repo}/pulls/{number}/comments --paginate

# PR reviews (top-level review bodies)
gh api repos/{owner}/{repo}/pulls/{number}/reviews --paginate

# PR issue comments (general conversation)
gh api repos/{owner}/{repo}/issues/{number}/comments --paginate

# Current PR diff (for staleness filtering in Step 2)
gh pr diff {number}
```

Filter out:

- Your own comments (bot-authored or from the current user)
- Resolved/outdated comment threads where the author marked them resolved
- Pure acknowledgment comments ("LGTM", "looks good", thumbs-up reactions)

## Step 1b: Diff-aware staleness filtering

Compare each inline comment's target (file path + line range) against the current PR diff:

1. If the **file** no longer exists in the diff (was removed from the PR or reverted), skip the comment entirely — note it as "stale (file no longer in diff)" in the summary.
2. If the **commented lines have been modified** since the review was posted, skip the comment — note it as "stale (code already changed since review)". To detect this, compare the `original_line`/`line` and `diff_hunk` from the comment against the current diff. If the hunk no longer matches, the code has moved on.
3. If the comment targets lines that are **unchanged** in the current diff, it is still relevant — keep it.

This prevents wasting effort on feedback that was already addressed by subsequent pushes. Log all stale-filtered comments in the summary under a **Stale (skipped)** section so the user has visibility.

## Step 2: Categorize each feedback item

For each substantive piece of feedback, classify it:

| Category                   | Description                                                            |
| -------------------------- | ---------------------------------------------------------------------- |
| **Bug/Correctness**        | Points out actual bugs, logic errors, race conditions, security issues |
| **Architecture/Design**    | Suggests structural changes, different abstractions, module boundaries |
| **Convention/Style**       | Code style, naming, formatting, project convention adherence           |
| **Performance**            | Optimization suggestions                                               |
| **Nit/Preference**         | Subjective preferences, minor cosmetic suggestions                     |
| **Question/Clarification** | Reviewer asking for explanation, not requesting a change               |

Weigh all feedback equally regardless of category. Evaluate every item on its own merits using the criteria in Step 3.

## Step 3: Critical evaluation

For EACH feedback item, evaluate it against these criteria:

1. **Is it correct?** Does the suggestion actually fix a problem or improve the prose/script? Verify by reading the relevant file and, for skill prose, walking the skill's own steps against this repo's `docs/`.
2. **Does it align with project patterns?** Check `CLAUDE.md`, `AGENTS.md`, the settled decisions in `docs/notes/*-reasoning.md`, and `docs/notes/slice-gate-convention.md`. Reject suggestions that contradict the locked invariants:
   - **The product is the prose, and it is live.** `skills/*/SKILL.md` are symlinked into `~/.claude/skills/` — an edit here changes Ken's next session in every repo. Read the whole `SKILL.md` before changing it; no speculative edits.
   - **Settled decisions stay settled.** `docs/notes/*-reasoning.md` and `docs/plans/_done/` record decisions that were reasoned or adversarially workshopped. A bot suggestion that quietly reverses one (e.g. re-adding parallelism to `/run-plan`, giving `/wrap-up` a machine-confirm mode, letting subagents commit or write the plan file) is rejected and reported, however locally sensible it looks.
   - **The slice gate is mechanical.** The orchestrator — never a subagent — runs `scripts/slice-gate.sh` and obeys exit codes without interpretation. Reject anything that moves gate judgment into a model's prose or a subagent's self-report.
   - **The ADHD voice is load-bearing.** The skills address the user's ADHD bluntly ("refusing is a success"). Reject wording changes that sand that off into generic politeness — it is function, not tone.
   - **Skill conventions hold:** the frontmatter `description` is the dispatch mechanism (trigger phrases must survive edits); skills cross-reference with `[[name]]` wiki-links; each lifecycle skill ends with one breadcrumb line; skills read/write the current repo's `docs/` (or the configured backlog metarepo) — never a hardcoded personal path.
   - **Historical artifacts are records.** Archived plans in `docs/plans/_done/` describe the world as it was (old paths, old dialects where noted). Don't "fix" history to match the present.
   - **No new stack.** The only code is POSIX shell (`install.sh`, `scripts/`, `tests/`) with zero dependencies. Reject suggestions adding languages, packages, or build tooling.
3. **Is the scope appropriate?** Reject suggestions that balloon scope beyond the PR's intent (e.g., "while you're here, restructure this entire skill"). Substantive skill changes go through the repo's own lifecycle (`/idea` → `/reason` → `/promote`), not a PR comment.
4. **Is there a better alternative?** Sometimes the reviewer identifies a real problem but suggests a suboptimal fix. In that case, address the underlying concern your way.
5. **Does it introduce risk?** Reject changes that could break existing behavior without clear justification — remembering that "behavior" here includes how four skills agree on shared conventions (the marker shapes, the docs-root rule, the dialect). A change to one skill that desyncs the others is a break, even though nothing executes.

## Step 4: Apply accepted changes

For each accepted feedback item:

1. Read the relevant file(s) — for a skill, the whole `SKILL.md`, not just the flagged lines
2. Make the change
3. Ensure surrounding prose still makes sense — and if the change touches a shared convention (marker shape, dialect, docs-root, gate contract), sweep the other skills that state it and keep them in agreement
4. If the change touches `scripts/` or `tests/`, run `bash scripts/check.sh`

Do NOT apply changes one-by-one in isolation — consider interactions between multiple feedback items that touch the same skill or the same cross-skill convention.

> **Toolchain note:** plain POSIX shell and markdown only. No package manager, no build. `install.sh` is tested against a sandbox (`CODEX_HOME=$(mktemp -d) ./install.sh`), never the real `~/.claude`.

## Step 5: Run verification

After all changes are applied, run the whole-tree check from the repo root:

```bash
bash scripts/check.sh    # shell syntax + the slice gate's test suite
```

If it fails, determine whether the failure is caused by your changes. Fix if so; flag if pre-existing.

> **Prose-only PRs:** when the PR touches only `skills/`, `docs/`, or `README`, `check.sh` exercises none of it — run it anyway (it is cheap and catches accidental script edits), but say plainly that the real verification is reading the changed prose back and walking its steps against this repo's `docs/`, and do that.

## Step 6: Produce the feedback resolution summary

Output a structured summary to the conversation:

### Applied

For each applied item:

- **File:line** — what the reviewer said (paraphrased)
- **Action**: what you changed and why you agree

### Applied with modification

For items where you agreed with the concern but took a different approach:

- **File:line** — what the reviewer said
- **Action**: what you did instead and why

### Declined

For each declined item:

- **File:line** — what the reviewer said
- **Reason**: clear, respectful explanation of why you disagree

### Needs discussion

For items that are judgment calls or require product/architecture input:

- **File:line** — what the reviewer said
- **Question**: what needs to be decided before acting

### Stale (skipped)

For comments filtered out by diff-aware staleness detection:

- **File:line** — what the reviewer said
- **Reason**: "file no longer in diff" or "code already changed since review"

### Questions to answer

For reviewer questions that don't require code changes:

- **Comment**: the question
- **Suggested response**: the answer, in the conversation (not posted to the PR — solo repo)

## Step 7: Ship the branch — only with `--merge`

**Off by default.** Run this step only when `$ARGUMENTS` contains `--merge`. Ken's standing rule is
that Claude does not commit or push; the flag on this invocation is the one-time approval that lifts
it for this PR only. Never infer it from approval-shaped words in the conversation ("looks good",
"ship it"), and never carry it into a later invocation.

Stop before committing — and name the gate that stopped you — if any of these hold:

| Gate | Why it blocks |
| --- | --- |
| Step 5's check did not run, or failed | Merging unverified prose is the failure this repo's gate exists to prevent |
| The summary has any **Needs discussion** item | The user hasn't ruled yet; merging decides it for them |
| `git status --porcelain` shows changes you did not make in Step 4 | Unrelated work would ride along in the commit |
| `git rev-parse --abbrev-ref HEAD` is the repo's default branch | There is no PR branch to merge |
| `gh pr view <number> --json reviewDecision,mergeStateStatus` reports a required review that is not approved, or a PR that is not mergeable | The repo's own rules outrank the flag |

**Declined** items are not a blocker — declining some is the point of this skill.

Then, in order:

1. Commit the Step 4 changes on the PR branch as one commit:
   `pr-feedback: <n> items from #<number>`, with the `Co-Authored-By` trailer the global rule
   requires. Stage only the files you touched — never `git add -A`.
2. `git push` to the PR branch.
3. Wait for checks: `gh pr checks <number> --watch`. If any check fails, **stop and report which** —
   do not merge. If the repo reports no checks at all, say so plainly and continue; absence of CI is
   not a pass.
4. Read the repo's allowed merge methods
   (`gh repo view --json squashMergeAllowed,mergeCommitAllowed,rebaseMergeAllowed`) and use the
   repo's own setting rather than assuming — prefer squash when it is allowed:
   `gh pr merge <number> --squash --delete-branch`.
5. Report the resulting commit sha, the merge method used, and that the branch was deleted.

> **Sibling-repo note:** the skills in `skills/*/SKILL.md` are symlinked live into `~/.claude/skills/`.
> A merge that lands a skill edit changes Ken's next session in every repo the moment it hits `main`
> — so state in the ship report which skills the merge just made live.

$ARGUMENTS
