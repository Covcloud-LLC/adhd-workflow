# OpenAI and Claude model routing for workflow skills — recommend both, then choose

> Status: **in-progress** · created 2026-07-09 · started 2026-07-09
> Model: gpt-5.5 · Effort: high
> OpenAI: gpt-5.5 · high
> Claude: claude-opus-4-8 · high
> Recommended: OpenAI gpt-5.5 · high for this Codex session; use Claude Opus 4.8 · high when running the same plan from Claude Code.
> Home: this repo is the source of truth; installed skills are symlinked into `${CODEX_HOME:-~/.codex}`.
> Why: model names are now part of the workflow contract, and unqualified provider labels make future sessions run the right workflow at the wrong runtime.
> Reasoning: `docs/notes/openai-model-routing-for-workflow-skills-reasoning.md` — its provider-qualified routing decision and carried compatibility risks are inputs here, not up for re-litigation.

## Definition of done

The live workflow skills and user-facing workflow docs consistently provide provider-qualified
runtime guidance: each model-sensitive handoff includes an OpenAI/Codex recommendation and a
Claude/Claude Code recommendation, then names the default recommendation for the current surface.
High-judgment workflow commands recommend OpenAI `gpt-5.5 · high` for Codex sessions and Claude
`claude-opus-4-8 · high` for Claude Code sessions, with `claude-fable-5 · high` reserved for
larger long-running autonomous work where available. Lighter execution or subagent work can route
to OpenAI `gpt-5.4-mini` or Claude `claude-sonnet-5`; trivial mechanical work can route lower only
when current docs confirm the exact model. The separate `Effort` axis remains provider-aware.

## Acceptance criteria

- [ ] `/promote` writes or teaches provider-qualified route recommendations: OpenAI option,
      Claude option, and a recommended default between them.
- [ ] `/audit-plans` validates the provider-aware `Model` + `Effort` contract and recommends
      migrations for old unqualified headers without treating historical plans as broken.
- [ ] `/reason`, `/design-workshop`, `/diagnose`, `/pjm`, and `/standup` describe fresh Codex
      and Claude Code sessions where relevant, and choose between the OpenAI and Claude route.
- [ ] The workflow guide and command copy explain that `Model` is a runtime recommendation,
      `Effort` is provider-aware reasoning budget, and the default route depends on the active
      surface.
- [ ] A final `rg` sweep shows no accidental one-provider rewrite in live files; remaining old
      labels are either explicit compatibility text or archived history.

---

### OMR-1 — Provider-qualified plan model/effort contract

> task: Doc/skill-prose slice; red-gate exemption applies. Edit `skills/promote/SKILL.md` and `skills/audit-plans/SKILL.md` to make the plan header contract provider-qualified, not OpenAI-only. First verify the current official sources (`https://developers.openai.com/codex/models`, `https://developers.openai.com/api/docs/models`, `https://developers.openai.com/api/docs/guides/latest-model`, `https://platform.claude.com/docs/en/about-claude/models/overview`, and `https://code.claude.com/docs/en/model-config`) so exact model slugs and effort levels are not copied from stale memory. Update `/promote`'s house-format template and Model & effort guidance so a plan can carry both routes, for example an OpenAI recommendation, a Claude recommendation, and a "recommended default" chosen between them for the current surface. Use OpenAI `gpt-5.5`, `gpt-5.4`, and `gpt-5.4-mini` as appropriate; add `gpt-5.4-nano` only if current docs expose that exact model ID. Use Claude `claude-opus-4-8`, `claude-fable-5`, `claude-sonnet-5`, and `claude-haiku-4-5` as appropriate. Preserve provider-aware Effort: OpenAI supports `none|low|medium|high|xhigh`; Claude Code supports `low|medium|high|xhigh|max` on current Fable/Opus/Sonnet models, with `max` described as Claude-only/session-only. In `/audit-plans`, validate the new provider-qualified contract and add a legacy rule: old active plans using unqualified `opus`, `sonnet`, `haiku`, or `fable` should be flagged for migration to a provider-qualified route, not treated as unreadable or malformed. Verify: read back both files; both mention `gpt-5.5`, `claude-opus-4-8`, provider-aware Effort, and the legacy migration rule.

### OMR-2 — High-judgment skills recommend OpenAI and Claude

> task: Doc/skill-prose slice; red-gate exemption applies. Edit `skills/reason/SKILL.md`, `skills/design-workshop/SKILL.md`, and `skills/diagnose/SKILL.md` so their run guidance gives both a Codex/OpenAI route and a Claude Code route, then names the default recommendation. For normal judgment work, recommend `gpt-5.5 · high` in Codex and `claude-opus-4-8 · high` in Claude Code. For the rare deepest one-shot workshop case, recommend `gpt-5.5 · xhigh` in Codex and either `claude-opus-4-8 · xhigh` or Claude-only `max` if the skill explicitly wants session-only deepest reasoning; mention `claude-fable-5 · high` only for larger long-running autonomous work where it is available. Keep the underlying triage/workshop behavior unchanged. Verify: read back the changed run-guidance sections; `rg -n "Run this at Opus|claude-opus-4-8|gpt-5.5|claude-fable-5" skills/reason/SKILL.md skills/design-workshop/SKILL.md skills/diagnose/SKILL.md` confirms old unqualified Opus wording is gone and provider-qualified routes are present.

### OMR-3 — Driver skills surface both routes in handoffs

> task: Doc/skill-prose slice; red-gate exemption applies. Edit `skills/pjm/SKILL.md` and `skills/standup/SKILL.md` so the daily-driver flow echoes both provider recommendations and the chosen default. `/pjm` should say the manager session itself should use `gpt-5.5 · high` when running in Codex or `claude-opus-4-8 · high` when running in Claude Code; it may recommend `claude-fable-5 · high` for large long-running autonomous slices where available. Describe execution as fresh Codex or Claude Code sessions depending on the selected route, not only one surface. Update examples such as `Money.format -> sonnet/medium` to provider-qualified examples. `/standup` should keep echoing each plan's `Model` + `Effort`, but teach it to report both provider routes and the chosen default when the plan carries them. Verify: read back the changed sections; examples include both OpenAI and Claude routes, and old unqualified `sonnet`/`opus`/`fable` labels appear only in legacy-compatibility wording.

### OMR-4 — Public workflow docs explain dual-provider routing

> task: Doc/skill-prose slice; red-gate exemption applies. Edit `docs/adhd-workflow-guide.md`, `commands/wrap-up.md`, `README.md`, and `AGENTS.md` only where they describe current live workflow behavior. Explain that the workflow can run from Codex or Claude Code, and that model-sensitive handoffs should include an OpenAI route, a Claude route, and a recommended default between them. Do not replace every "Claude session" with "Codex session" if the text is describing the Claude Code path; instead make the surface explicit. Keep archived `docs/plans/_done/` paths and wording unchanged as historical records. Add a compact note to the guide that `Model` is the runtime recommendation and `Effort` is provider-aware reasoning budget, so future users understand why both fields exist. Verify: read back the changed guide section and command copy; `rg -n "fresh Claude sessions|fresh Codex sessions|Model|Effort|gpt-5.5|claude-opus-4-8" docs/adhd-workflow-guide.md commands/wrap-up.md README.md AGENTS.md` shows the dual-provider behavior clearly.

### OMR-5 — Final compatibility sweep

> task: Doc/verification slice; red-gate exemption applies. Run the final migration sweep without rewriting archived history. Use `rg -n "Claude|claude-|Opus|opus|Fable|fable|sonnet|haiku|max|gpt-5" skills commands README.md AGENTS.md docs/adhd-workflow-guide.md docs/notes docs/plans -g "*.md"` and classify every hit as desired current routing, explicit legacy compatibility, reasoning/history, or a bug to fix. Confirm `docs/plans/_done/` is not edited. Also run `bash -n install.sh` and `CODEX_HOME=$(mktemp -d) ./install.sh` so the installer still works after any README/AGENTS wording changes. Verify: final report lists the remaining intentional old-label hits, confirms live skills did not accidentally become OpenAI-only or Claude-only, and shows the installer checks passed.
