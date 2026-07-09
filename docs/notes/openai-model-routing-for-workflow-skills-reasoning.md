# OpenAI and Claude Model Routing for Workflow Skills - reasoning

**Decision:** Promote this as a targeted convention update, but not as an OpenAI-only migration. The workflow should make **two provider-specific recommendations** wherever a future session needs a runtime: one OpenAI/Codex route and one Claude/Claude Code route. Then it should name the recommended default between them based on the surface the user is actually using, model availability, and the task's risk. For this repo's Codex sessions, the default recommendation should usually be OpenAI `gpt-5.5 · high`; the Claude equivalent should usually be `claude-opus-4-8 · high`, with `claude-fable-5 · high` reserved for larger long-running autonomous sessions where it is available. Lighter work can route to OpenAI `gpt-5.4-mini` or Claude `claude-sonnet-5`; trivial mechanical work can use OpenAI `gpt-5.4-nano` only if verified in current docs, or Claude `claude-haiku-4-5`.
**Why:** Model names are part of the workflow contract now: `/promote` writes them into plans, `/standup` and `/pjm` surface them, and `/audit-plans` validates them. A one-provider rewrite loses the user's Claude workflow; stale unqualified labels make future sessions run the right workflow at the wrong runtime.

## Options considered
- **Leave model labels abstract** - avoids churn, but keeps `opus`/`sonnet`/`haiku` and `gpt-*` labels floating around without enough context for a fresh session to choose correctly.
- **OpenAI-only rewrite** - fits Codex sessions, but breaks the user's Claude workflow and treats active Claude model routing as historical debris.
- **Provider-qualified recommendations with a default choice (chosen)** - records both viable routes, keeps the workflow portable between Codex and Claude Code, and still gives future-you a concrete "run this here" recommendation instead of a menu.

## Risks / open questions carried into the plan
- Current OpenAI docs checked on 2026-07-09 name `gpt-5.5` for complex coding and professional work, with `gpt-5.4-mini` / `gpt-5.4-nano` as lower-cost or lower-latency options; the plan should verify current docs before hardcoding exact slugs.
- Current Anthropic docs checked on 2026-07-09 name `claude-opus-4-8` for complex agentic coding and enterprise work, `claude-fable-5` for highest-capability long-running agent work, `claude-sonnet-5` as the speed/intelligence balance, and `claude-haiku-4-5` for fastest near-frontier work.
- `Effort` needs provider-aware handling: OpenAI reasoning effort supports `none`, `low`, `medium`, `high`, and `xhigh`; Claude Code supports `low`, `medium`, `high`, `xhigh`, and session-only `max` for current Fable/Opus/Sonnet models. The plan should not erase Claude's `max` just because OpenAI lacks it.
- Update the live skill contract only (`skills/*/SKILL.md`, README/AGENTS if needed). Do not rewrite `docs/plans/_done/` historical artifacts just to modernize model names.
- Active plan validation should degrade gracefully for old unqualified `opus`/`sonnet`/`haiku`/`fable` headers and should recommend a provider-qualified replacement instead of treating them as invalid nonsense.
