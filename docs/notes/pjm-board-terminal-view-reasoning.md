# PJM Board: Auto-Refreshing Cross-Repo Status Terminal View — reasoning

**Decision:** Build it as **two independent deliverables**, board first. (1) A single-file,
zero-dependency **Node** script in `scripts/`, read-only, that renders the cross-repo board from
plan files + git and owns **its own refresh loop** (no `watch(1)`). (2) The `/wrap-up` ledger
append, sequenced **after** `executive-wrapup-in-skill-reports`, so the product-level sentence has
one author.

**Why:** The board is useful before any ledger line exists, because "what we just did" has a
three-tier fallback — ledger sentence → title of the last ` ✅` slice → `git log -1 --format=%s`.
That fallback is what lets the two halves ship apart, and it means the board degrades to *useful*
rather than to *blank* on a repo that has never been wrapped up.

## Options considered

- **A — bash/zsh + `jq` scanner.** Matches the repo's existing shell-only shape (`install.sh`,
  `scripts/slice-gate.sh`). *Fails:* the work is markdown parsing — YAML frontmatter, counting
  ` ✅` slice headings, finding the first heading without one — which is exactly the class of
  sed/awk logic that goes silently wrong rather than erroring, and this repo's own global rules
  already document a zsh word-splitting trap that no-ops loops without failing. `jq` is present on
  this machine (`/usr/bin/jq`) but is not stock macOS, so a published repo would be adding a real
  external dependency to read its own ledger.
- **B — single-file Node, zero npm deps, no `package.json` (chosen).** JSONL parses natively, the
  line-regex work is honest in JS, and it adds no build step. *Why it wins:* it keeps the repo's
  "no build, no deps" property true; the only new prerequisite is a Node binary, which anyone
  running this toolchain already has.
- **C — extend `/standup --board` to go cross-repo.** Reuses a board renderer that already exists
  and already knows the parse rules. *Fails on the premise:* `/standup` is a Claude skill, so every
  refresh costs a session and tokens — the whole point here is a continuous, zero-token view. It is
  also single-repo by construction (it resolves the docs root from the cwd's git root).

## Risks / open questions carried into the plan

- **`watch(1)` is not installed on macOS** — verified: `command -v watch` finds nothing. Do not
  spec `watch -n 30`. The script takes `--watch <seconds>` and does its own clear-and-re-render,
  with single-shot as the default so it stays pipeable.
- **Node here is nvm-managed** (`~/.nvm/versions/node/v24.16.0/bin/node`), not a system path, so a
  non-login shell or spawned subshell may not have it. Use a `#!/usr/bin/env node` shebang, state
  the prerequisite in the README, and fail with a readable message rather than a stack trace.
- **`/wrap-up` does not author a product-level sentence today** — verified: its Report section
  lists status changes, memories, doc tasks, reasoning-note disposition, and the hand-off, with no
  "what now works" line. Rule 11 of the ADHD output style supplies that shape in Claude Code only,
  which is precisely the gap `executive-wrapup-in-skill-reports` exists to close. Sequence the
  ledger hook after it, or the hook has to define the sentence itself and the two definitions will
  drift.
- **The ledger is append-only, so its field names are a contract.** Fields may be added; existing
  ones are never renamed or repurposed. The reader tolerates unknown fields, tolerates missing
  optional ones, and **skips malformed lines** — a half-written line from an interrupted append
  must not blank the board.
- **Parse-rule duplication is the main drift risk.** The script must mirror the skills' docs-root
  resolution exactly (read `~/.config/adhd-workflow/backlog-root`; prefer `<backlog-root>/<repo>/`;
  else `./docs/`) and apply the same exclusions `/standup` applies (`_done/`, underscore-prefixed
  fixtures, `BOARD.md`). State the parse rules once in the plan as a spec both sides cite.
- **`scripts/check.sh` must gain a `node --check` step** for the new file, mirroring its existing
  `bash -n` steps — otherwise the repo's only gate silently ignores it.
- **Read-only is the safety property, and it should be stated as one:** no writes to any scanned
  repo, no network, no `git fetch`.
- **Config placement is confirmed, not assumed.** `~/.claude/pjm/repos.json` is invisible to the
  dotfiles allowlist gitignore (`*` ignores everything, `!*/` only permits traversal, and `*.json`
  is re-ignored except `settings.json`; `*.jsonl` likewise). It genuinely must be machine-local
  because it holds absolute paths. Consequence for a published repo: the script does nothing until
  configured, so ship an example `repos.json` **in the repo** and say so in the README.
