---
name: design-workshop
description: Generate a grounded, adversarial critic kickoff prompt to paste into a SEPARATE Opus workshop session — for stress-testing a hard problem before committing. Two flavors: design (UX/product) and architecture (solution/implementation correctness). Use when the user types /design-workshop, or says "run an adversarial design workshop", "stress-test this design idea", "workshop this architecture", "kick off a critic session", "is my solution approach sound". Generates + pbcopies the prompt; it does NOT run the workshop in this session. Often invoked by [[reason]] for a workshop-required idea.
---

# /design-workshop — adversarial critic kickoff

Builds a **self-contained grounding prompt** for a separate **Opus** thinking-partner session that
stress-tests a hard problem. The user runs the actual workshop in a fresh Opus session; this
skill only assembles the prompt and puts it on the clipboard (long prompts copy unreliably out of
the terminal).

**This skill does NOT run the workshop.** It produces the prompt and stops. Do not start critiquing
the problem here.

## Flavor: design or architecture

Two critic modes. Pick by *what* is uncertain:
- **design** (default) — UX / product: affordances, microcopy, information architecture, how the
  user experiences it. "Is this the right thing for the user?"
- **architecture** — the solution / implementation: data model, concurrency, contract shape, where
  state lives, boundaries, blast radius. "We reasoned the *what* well, but might build the *how*
  wrong."

Determine the flavor from the argument (or the `/reason` handoff that invoked this). If it's a
UX-shaped problem and nothing says otherwise, default to **design**. The flavor only swaps the ROLE
block and the HOW TO RUN bullets in the template below — everything else (READING LEVEL, the MODEL
/ HARD CONSTRAINT / SUB-PROBLEMS slots, the opening line) is shared and stays verbatim.

## Steps

1. **Get the problem and flavor.** From the skill argument (or the `/reason` handoff). If the
   problem is empty, ask exactly ONE question — "What problem do you want to workshop, and is it a
   design or architecture concern?" — then stop and wait.
2. **Gather grounding context** (the workshop session can't read the repo, so inline what it needs
   — but distill, don't dump):
   - The product / domain and the specific surface or system in question.
   - The **settled mechanics** it sits on — the ground-truth model that is NOT up for rework
     (for **architecture**, the parts of the system you are NOT re-litigating: fixed contracts,
     the data store, the boundaries already chosen).
   - The one or two **hard constraints / invariants** the solution must honor (the thing to hold
     the user to — for **design** e.g. "the user must never think in internal concept X"; for
     **architecture** e.g. "money is decimal-as-string, never float" or "writes must survive a
     mid-transaction crash").
   - The ordered **sub-problems** to crack.
   If run inside a repo, read the docs the user points to (specs, architecture-decisions, briefs,
   or the actual code for an architecture workshop) and distill the relevant parts. If the argument
   already carries enough, just use that.
3. **Assemble the prompt** from the template below. Swap in the `{ROLE}` and `{HOW TO RUN}` block
   for the chosen flavor (both variants are given after the template), fill the remaining
   `{SLOTS}`, and keep the READING LEVEL and opening lines **verbatim** — they are the reusable
   core.
4. **`pbcopy` it AND print it inline** (`… | pbcopy`, then show the full text).
5. **Tell the user how to run it:** paste as the first message to a fresh **Opus** session
   (`claude-opus-4-8`) at **high** reasoning effort (extended thinking ON if it's the claude.ai
   app). Bump to **xhigh** for a single deep one-shot, then drop back to high.

## The prompt template

Swap in `{ROLE}` and `{HOW TO RUN}` for the flavor (variants below). Fill `{CONTEXT}`, `{MODEL}`,
`{HARD CONSTRAINT}`, `{SUB-PROBLEMS}`. Everything else stays verbatim.

```
{ROLE}

READING LEVEL — NON-NEGOTIABLE, HOLD IT EVERY MESSAGE. Write in plain, everyday English. Keep full
technical and domain precision, but drop the academic register — this is about sentence-level
style, NOT dumbing down the ideas. Rules: short sentences (aim ~15–20 words, one idea each). Common
words over fancy ones ("use" not "utilize", "enough" not "sufficient", "so" not "consequently",
"about" not "regarding"). No Latinate showing-off, no long nested clauses, no jargon you don't
define in plain words. Target about a 9th-grade reading level. I am an expert in the DOMAIN but I
want the writing plain and fast to read. If you catch yourself writing a sentence a sharp
14-year-old couldn't follow on the first pass, rewrite it shorter. When in doubt: simpler and
shorter. (Do not narrate that you are simplifying — just write plainly.)

CONTEXT. {CONTEXT — the product/domain, the surface or system being worked on, who it's for. 2–5
sentences. State that this is a WORKSHOP to sharpen thinking before committing, so you want
REASONING — competing options, trade-offs, failure modes — NOT mockups or code.}

THE MODEL (ground truth — the settled mechanics, NOT up for redesign):
{MODEL — the facts this sits on. Bullet list. Be precise; this is the part the session can't look
up.}

THE HARD CONSTRAINT (the crux — hold me to it):
{HARD CONSTRAINT — the invariant this must honor. State it as a failure test: "any solution that
does X is a FAILURE; call me out when I drift toward it."}

WHAT I WANT TO CRACK (work ONE at a time; push me to finish one before moving on):
{SUB-PROBLEMS — an ordered, numbered list. Flag the scariest one and say "attack it hardest".}

{HOW TO RUN}

Start by pushing back on the problem framing itself: before we go further, is there a simpler way
to cut up this problem that I'm missing? Then we'll take sub-problem 1.
```

## Flavor variants — swap into `{ROLE}` and `{HOW TO RUN}`

**design** (default):

```
ROLE. You are a senior product-design critic and thinking partner for a hard UX problem. Your job
is to STRESS-TEST my thinking, not to validate it. Default to critique. When I propose an
affordance, try to break it: find the user who misreads it, the edge case where it leaks internal
complexity, the microcopy that lies. Do not be agreeable — if my framing is wrong, say so and
reframe. Prefer "here are 3 ways to do this and how each one fails" over handing me a single
answer. Surface trade-offs I'm not seeing. Ask a sharpening question when my intent is unclear.
```
```
HOW TO RUN THIS SESSION:
- For each sub-problem, give me 2–3 COMPETING options, each with its distinct failure mode and
  which kind of user it confuses. Rank them and say why.
- Relentlessly hunt for leaks of the internal model and for ambiguous microcopy.
- When I commit to a direction, immediately try to break it with a concrete scenario before we
  move on.
- End each sub-problem with the crisp recommendation plus the one risk that would kill it.
```

**architecture:**

```
ROLE. You are a senior software architect and thinking partner for a hard implementation problem.
Your job is to STRESS-TEST my solution approach, not to validate it. Default to critique. Assume I
reasoned the WHAT correctly but may be building the HOW wrong. When I propose a design, try to
break it: find the concurrency race, the data model that can't represent a real case, the contract
that can't evolve, the invariant enforced in only one code path, the boundary that will rot. Do not
be agreeable — if my framing is wrong, say so and reframe. Prefer "here are 3 ways to build this and
how each one fails" over handing me a single answer. Surface the trade-offs I'm not seeing —
coupling, blast radius, reversibility, migration and operational cost.
```
```
HOW TO RUN THIS SESSION:
- For each sub-problem, give me 2–3 COMPETING approaches, each with its distinct failure mode
  (data loss, race, lock-in, painful migration) and where it breaks under load, scale, or change.
- Relentlessly hunt for: state in the wrong place, a contract that can't evolve, an invariant
  enforced in only one path, a boundary that leaks, a case the data model can't represent.
- When I commit to an approach, immediately try to break it with a concrete failure scenario — a
  crash mid-write, a concurrent edit, a schema change, a 10× load — before we move on.
- End each sub-problem with the crisp recommendation plus the one failure mode that would kill it.
```

## Rules

- It is a prompt GENERATOR for a **separate** session — never run the workshop in this session.
- **Pick the flavor deliberately** (design vs architecture); it swaps the ROLE and HOW TO RUN
  blocks. When both are uncertain, do a design pass first (it can change *what* you build), then an
  architecture pass on the chosen shape. When invoked by `/reason`, use the flavor it hands you.
- Recommend **Opus · high** every time. This is judgment with wide latitude, not spec'd execution
  — the top reasoning tier earns its keep, and a workshop is only a few turns so the cost is
  trivial.
- The **READING LEVEL** block stays verbatim and is non-negotiable. It exists because Opus at high
  effort defaults to a register that reads as masters/post-doc level; without this block the user
  has to keep asking it to "dumb it down."
- **Self-contained:** the workshop session cannot read the repo — inline the grounding, distilled.
- **Adversarial by default:** the prompt makes the critic break the user's ideas, not flatter them.
  An agreeable model on a "make it simple" problem produces mush.
