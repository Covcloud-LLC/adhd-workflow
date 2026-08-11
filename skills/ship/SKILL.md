---
name: ship
description: Commit the current work, push the branch, and open a pull request — one command for the whole hand-off. Branches first if you're on the default branch, runs the repo's own check before committing, and stops at the open PR without merging. Use when the user types /ship, or says "commit push and raise a PR", "ship this", "open a PR for this", "put this up for review". Part of the ADHD project-workflow system — [[run-plan]] invokes it to finish a clean run.
argument-hint: '[PR title or short description] [--draft] [--no-check]'
---

# Ship: commit → push → PR

Take the work that's already in the working tree and get it to an open pull request. Three
mechanical steps, one invocation, no questions in the middle.

**Invoking `/ship` IS the commit-and-push approval.** The standing rule (never auto-commit, never
auto-push) is lifted for this invocation only. It does not carry to the next turn, and it never
extends to merging — `/ship` stops at the open PR. Merging stays a separate, deliberate act.

## Step 0: Read the state

```bash
git status --porcelain            # what's uncommitted
git rev-parse --abbrev-ref HEAD   # current branch
git log --oneline @{u}.. 2>/dev/null || git log --oneline -5   # unpushed commits, if any
gh pr view --json number,url,state 2>/dev/null                 # PR already open for this branch?
```

Four states, four paths — pick one and say which:

| State | What `/ship` does |
|---|---|
| Dirty tree, feature branch | commit → push → PR |
| Clean tree, unpushed commits | push → PR (nothing to commit; say so) |
| Dirty tree, **on the default branch** | branch first (Step 2), then commit → push → PR |
| PR already open for this branch | commit → push → report the existing PR URL, do **not** open a second |

Nothing to do at all (clean tree, nothing unpushed, no PR): say so in one line and stop. Don't
manufacture an empty commit.

## Step 1: Run the repo's check — before committing

Find the check the way a new contributor would: `CLAUDE.md` / `AGENTS.md` naming a whole-tree
command, then `package.json` scripts (`test`, `check`, `lint`), then `Makefile`, then an obvious
`scripts/check.sh`. Run the first one you find.

Run it **un-piped** and read `$?` immediately — under zsh, `$PIPESTATUS` is not a thing and a
piped check silently reads as passed.

- **Green** → continue.
- **Red** → **stop**. Report the failing output and the command. Do not commit. Shipping red is
  the exact failure this step exists to prevent.
- **No check found** → say plainly that none was found and continue. Absence of a check is not a
  pass, and the user should know which it was.
- `--no-check` in `$ARGUMENTS` → skip this step entirely, and say in the final report that it was
  skipped.

## Step 2: Branch, if needed

Only when Step 0 found you on the repo's default branch (`main`/`master` — read it from
`gh repo view --json defaultBranchRef -q .defaultBranchRef.name`, don't assume).

Name it from the work, not from the date: `<type>/<short-slug>`, where `<type>` is one of
`feat`, `fix`, `docs`, `chore`, `refactor`, `test`. Derive the slug from what actually changed.

```bash
git checkout -b <type>/<short-slug>
```

Say the branch name in the report. Never rename or reset an existing branch.

## Step 3: Commit

**Stage only the files that belong to this change.** Never `git add -A`, never `git commit -am`.
List the paths explicitly:

```bash
git add <path> [<path>...]
```

If `git status` shows files you did not touch this session, do **not** stage them — name them in
the report as left behind, and let the user decide. Sweeping up unrelated work is the failure mode
this rule exists to prevent.

Write the message yourself from the actual diff — a summary line under ~70 chars in the
imperative ("Add X", not "Added X"), then a blank line, then a short body only if the *why* isn't
obvious from the diff. End with whatever `Co-Authored-By:` trailer your harness's own commit rule
specifies, naming the model actually running — in Claude Code that is:

```
Co-Authored-By: Claude <model> <noreply@anthropic.com>
```

Don't copy a model name out of this file; it will be stale by the time you read it.

If the branch already has commits and the tree is clean, skip this step — there is nothing to
commit, and that is a normal state, not a problem.

## Step 4: Push

```bash
git push -u origin HEAD
```

`-u` so the branch tracks on the first push and later `git push` calls need no arguments. If the
push is rejected (someone else pushed), **stop and report** — do not force, do not rebase without
being asked.

## Step 5: Open the PR

Title: the **non-flag part** of `$ARGUMENTS` if the user gave one, otherwise the commit summary
line. Strip `--draft` and `--no-check` first — arguments that are nothing but flags mean **no
title was provided**, not a PR called `--no-check`. For a branch with several commits, write a
title that covers all of them rather than echoing the last one.

Body — short, and about the change, not about the process:

```markdown
## What

<1–3 sentences: what this changes and why>

## Verification

<the check command and its result, or "no check found in this repo">

<the PR-body attribution line your harness's own rule specifies, if it has one>
```

Same rule as the commit trailer in Step 3: name the surface actually running. In Claude Code that
line is `🤖 Generated with [Claude Code](https://claude.com/claude-code)`; under Codex or any other
surface it is theirs, or absent. Don't paste Claude's line from a session that isn't Claude's.

Pass the body on **stdin**, never as a `--body` argument — it is multi-line Markdown and will
contain quotes and backticks sooner or later, and `--body "<body>"` breaks on exactly that:

```bash
gh pr create --title "<title>" --body-file -    # add --draft when $ARGUMENTS has it
```

If `gh` reports no remote, no upstream repo, or missing auth, stop and report the exact error —
the commit and push already landed, so say that too, so the user knows where things stand.

## Step 6: Report

Five lines, no prose:

```
Shipped: <branch>
Commit:  <sha> <summary>
Check:   <command> — green | red | none found | skipped (--no-check)
PR:      <url>  [draft]
Left uncommitted: <paths, or "nothing">
```

Then one line naming the next action — usually reviewing the PR, or `/apply-pr-feedback <n>` once
a bot has reviewed it.

## What `/ship` never does

- **Never merges.** Not with `--admin`, not "since checks passed", not when asked nicely mid-run.
  A merge is a separate decision with its own approval.
- **Never force-pushes** or rewrites history (`rebase`, `reset --hard`, `commit --amend` on
  something already pushed).
- **Never stages files it did not touch**, and never `git add -A`.
- **Never commits over a red check** unless `--no-check` was passed explicitly.
- **Never posts** review comments, replies, or PR comments beyond the one PR body it creates.
