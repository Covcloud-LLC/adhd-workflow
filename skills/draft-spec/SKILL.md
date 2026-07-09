---
name: draft-spec
description: Draft a Diátaxis reference/contract spec for the CURRENT repo's shipped docs — fact-dense tables, schemas, and field lists, every value grep-verified against the emitting/consuming source before it's written. Audience is developers AND context-collecting bots; refuses to draft without a named reader. Emits the six-field shipped-doc front-matter with verified-against pinned to the current commit. Use when the user types /draft-spec, or says "spec this contract", "write the reference for X", "document this schema/API/payload". Prose-shaped docs (tutorial/how-to/brief/explanation) belong to /draft-guide.
---

# /draft-spec — draft a reference/contract spec

Produce a **grep-verified reference document** for a contract in the current repo: a schema, an API
payload, a config surface, a field catalog. The readers are developers **and context-collecting
bots** (cross-repo harvesters like `rating-platform-kb`), so the output is fact-dense and
machine-scannable — tables, schemas, field lists. A stale or invented value is worse than a marked
gap for both readers.

`$ARGUMENTS` = the contract to spec (a schema/endpoint/config name), a backlog ID, or a target file
path. If it's a backlog ID, read its `task:` and `Verify:` lines from `docs/plans/` first — they
define the scope and the gate.

## What this does / does not do

- **Does:** verify every field name, path, enum value, and example against the actual
  emitting/consuming source (or a live endpoint), write a reference draft to the repo's shipped-docs
  dir, stamp the six-field front-matter, and offer to update the `docs/README.md` index.
- **Does NOT:** write narrative prose. No tutorials, no how-tos, no "why" essays — if the request is
  task- or understanding-shaped, say so and point to `/draft-guide`. **Does NOT** invent a single
  value: unverifiable → literal `‹VERIFY›` marker. **Does NOT** touch `docs/plans/` status —
  `/standup` owns status.

## Step 1 — Name the reader (refuse without one)

Every spec serves two reader classes: **developers** who will execute against the contract, and
**context-collecting bots** that harvest it cross-repo. But the doc still needs its *specific*
named reader — which developers, integrating from where. Look in this order: the plan/backlog
item's audience line, the target doc's existing header, a sibling spec's `audience:` field. If none
names a reader, **ask — never invent one.** No named reader, no draft.

## Step 2 — Ground in the current repo

1. **Read 1–2 sibling docs** in the target directory (e.g. `docs/reference/`). Match their heading
   style, table conventions, and link style — don't impose a generic template.
2. **One fact, one home.** If a field, concept, or example is already documented elsewhere in the
   repo's shipped docs, **link to it** — never duplicate. If this spec would supersede an existing
   doc, say so and set the old doc's `status: superseded-by: <path>` instead of leaving two homes.
3. Locate the **authoritative source** for the contract: the schema file, the emitting code, the
   consuming code, or the live endpoint. This is what Step 4 verifies against — name it in the doc's
   `source:` field.

## Step 3 — Register: reference, not prose

- **Tables, schemas, field lists.** Field name · type · required · constraints · example · notes.
- Example payloads are **real captured artifacts** (a fixture file, a live response), not
  hand-typed illustrations.
- Sentences only where a constraint can't live in a table cell (ordering rules, invariants,
  version notes) — and then one short sentence, plain wording.
- No narrative thread, no "first we…", no motivation sections. A reader greps this doc; write for
  the grep.

## Step 4 — Verify every value before you write it (non-negotiable)

Every **field name, path, enum value, type, default, and example payload** must be verified against
the actual emitting/consuming source or a live endpoint — not produced from memory or reasoning.

- Grep the field name in the schema/model/mapping source and confirm the spelling, casing, and
  nesting you're about to write. Cite where each was verified (file path, or endpoint + call).
- Example payloads: copy from a real fixture or a live response you just made. Money stays
  decimal-as-string — quote what the source actually holds, never a float, never a hand-computed
  rounding.
- Keep a running verification list as you go; it becomes the handoff report.
- A value you can't verify right now gets a literal **`‹VERIFY›`** marker in place — never a guess —
  and an entry in the handoff's gap list.

## Step 5 — Stamp the front-matter (automatic, never hand-typed)

Emit this block at the top of the draft. Fill every field yourself:

```yaml
doc-type: spec
audience: <the named reader from Step 1 — never blank>
status: current
verified-against: <current commit SHA — run `git rev-parse --short HEAD`>
repo: <repo name>
source: <the authoritative source paths from Step 2, plus the plan/note that queued this>
```

`verified-against` is the SHA at which Step 4's checks were run — it's how `/audit-plans` later
detects staleness. If verification hit a live endpoint instead of source, note that alongside the
SHA.

## Step 6 — Write it where shipped docs live

Output goes to the repo's shipped-docs directory — `docs/reference/` by convention, or wherever the
repo's existing specs sit. Then **offer to update `docs/README.md`** (the harvester entry-point
index) with a one-line entry for the new doc; create the index if the repo has shipped docs but no
index yet.

## Step 7 — Hand off

Report:
- **Reader** — who this spec is for and where that came from.
- **Verified** — each fact class and where it was checked (files grepped, endpoints hit, fixtures
  copied).
- **`‹VERIFY›` gaps** — every marker left in the doc, listed so they're findable.
- **Index** — whether `docs/README.md` was updated.

Then the breadcrumb: *next → `/wrap-up` if this closes a queued doc task (a contract-spec task
blocks its plan moving to `_done/`), otherwise `/standup` for the next action.*

## Self-audit before handing off

Reject your own draft if any of these are true:
- Any field name, enum value, or example that wasn't grepped/captured from source — including
  "obvious" ones.
- Narrative prose crept in (motivation paragraphs, step-by-step voice).
- It duplicates a fact that already has a home doc instead of linking.
- Any front-matter field is missing, or `verified-against` isn't the current commit.
- A money value rendered as a float or hand-computed.
