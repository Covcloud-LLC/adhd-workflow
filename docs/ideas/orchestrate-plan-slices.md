---
name: orchestrate-plan-slices
created: 2026-07-09
status: idea
---

# Orchestrate Plan Slices

**What:** Create a Codex skill or command that orchestrates all slices of a plan: pick the next open slice, prepare the execution handoff, reconcile completion, and continue until the plan is done.
**Why:** It could reduce manual driver overhead while preserving the workflow's checkpoint discipline.

What it should not do: silently edit every file, mark slices done without verification, commit/push/merge without confirmation, or bypass `/wrap-up`.
