# /run-plan question exit — reasoning

**Decision:** Give `/run-plan`'s subagents one narrow door for surfacing a genuine ambiguity:
before writing anything, agent A (or the single agent of an exempt slice) may write the question
to `<scratch>/<slice-id>-QUESTION.md` and exit with code **3** — distinct from the gate's 0/1/2.
The orchestrator halts, names the slice, and prints the file **verbatim**. It never answers,
guesses, or ranks options. The user answers by **editing the slice's task string**, then
re-invoking `/run-plan`, which resumes from `git log` exactly as after any other halt. No
answer-passing channel exists. Agent B — and any agent that has already started writing — has no
question exit at all: mid-build, the answer is halt, not negotiate.

**Why:** The incumbent behavior (halt on anything unexpected, never ask) forces the user to
re-derive the ambiguity from a red gate and a scratch file. But any richer mechanism collides
with the orchestrator's core invariant (`plan-orchestrator-subagent-per-slice-reasoning.md`):
the orchestrator holds no context and no opinion — nothing a subagent *says* is used for
anything. A question is the one legitimate case where subagent prose must reach the user, so
the design routes it **around** the orchestrator's judgment, not through it: a distinct exit
code (machine-readable, no interpretation) plus a file printed verbatim (no summarizing, no
compaction). The orchestrator stays a for-loop.

## The boundaries, and why they sit where they do

- **Pre-build only.** Before an agent has written anything, a question is cheap and honest —
  the ambiguity is in the task string, which is exactly the artifact the user accepted at
  `/promote` time and exactly the artifact the answer should fix. Once implementation has begun,
  a "question" is usually "I got stuck" wearing a question mark; letting it reopen the task
  converts the orchestrator into a chat session and re-opens the self-report hole the whole
  design exists to close. Halt is already the correct handler for stuck.
- **The answer is a task-string edit, not a reply.** An answer channel (a file the orchestrator
  feeds back, a resume flag carrying prose) would be state the plan file doesn't hold — the next
  cold session, human or machine, would run the *un*-answered task. Editing the slice's task
  string lands the answer in the durable store, and the normal dirty-tree/resume rules already
  handle everything else. Zero new machinery.
- **Exit 3, not a magic string.** The gate owns 0 (proceed), 1 (vacuous/halt), 2 (harness
  error). A distinct code keeps the orchestrator's decision input an exit code — the same
  no-model-in-the-decision-path rule the gate itself follows. The QUESTION file is the payload;
  the code is the signal; the orchestrator needs to interpret neither.

## Options considered

- **No questions ever (incumbent)** — safe but lossy: a real ambiguity surfaces as a confusing
  red-gate halt, and the user reverse-engineers the question from scratch notes.
- **Orchestrator answers from plan context** — dead on arrival: it's the rejected
  "orchestrator reviews its subagents" design; an orchestrator that answers has formed an
  opinion about the work.
- **Interactive answer channel (pause, collect reply, resume in place)** — builds a second
  state store outside the plan file and git log, exactly the dual-write problem the
  commit-per-slice design solved; also invites mid-build negotiation.
- **Question exit, pre-build only, answer = task-string edit (chosen)** — bounded, relay-only,
  no new state, and the answer improves the plan artifact itself.

## Carried risks

- An agent may abuse exit 3 as a soft refusal ("which of these two obvious readings?") to dodge
  work. Mitigation is the prompt's wording — "genuine ambiguity, materially different outputs,
  do not guess" — and visibility: every question halt names the slice, so a plan that keeps
  asking is a plan whose task strings need work, which is `/promote` feedback, not a runner
  defect.
- Exit codes from subagent harnesses are not always controllable; the QUESTION file's existence
  is therefore the authoritative signal, the code the convention.
