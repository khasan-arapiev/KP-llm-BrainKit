---
title: {{LANE}} lane plan
type: orchestrator-brief
project: {{SLUG}}
lane: {{LANE}}
status: drafted
created: {{TODAY}}
updated: {{TODAY}}
---

# {{LANE}} lane plan

The planner writes this for a **high-stakes or approval-gated lane** (irreversible, load-bearing,
or one the owner must sign off before any code). Normal lanes skip this file: Codis plan-and-builds
them in one context and carries its own plan in its report. When this file exists, the orchestrator
gets the owner's approval before Codis runs. Codis then executes it step by step and maps its report
back to the numbered steps. Revis verifies the diff against the acceptance criteria. It is the
lane's contract, not a sketch. Status moves `drafted` → `approved` → `in-progress` → `done`.

## Goal

<One sentence: the outcome this lane delivers, restated so a misread is obvious.>

## Acceptance criteria (definition of done)

This is the contract. Every box must be checkable. Codis cannot report done while one is open.

- [ ] <criterion 1, observable and verifiable>
- [ ] <criterion 2>
- [ ] <criterion 3>

## Context pointers

- **Files:** <the 3-5 files this lane touches>
- **graphify:** <present (blast radius from `graphify affected`), or absent (Grep used)>
- **ADRs / decisions:** <relevant ADRs by name, or none>
- **Status / plan:** <pointer to status.md section or the PRD this lane comes from>

## Architecture pass

<Conflicts with existing ADRs, patterns, or module boundaries, as bullets. Or "clean, proceed."
If the clean path conflicts with the ask, name the trade-off and the recommendation here, and
raise it as a fork in the planner report so the orchestrator can take it to the owner.>

## Reuse notes

<For each thing Codis might be tempted to build new: the existing symbol to reuse or extend,
with file:line. The ladder: repo → stdlib → native platform → installed dep → one line. Or
"nothing existing fits, build new because X".>

## Runtime read path (config / schema / seed / fixture / template lanes only)

<Existing rows pick this change up via X. The backfill step (migration, re-seed, re-import) is:
Y. Omit this section entirely if the lane touches no data-shape file.>

## Execution steps

Numbered, discrete, ordered. Each step names its files, what to reuse, and how to verify it.

1. <what to do>. Files: <...>. Reuse: <...>. Verify: <test/command/observation>
2. <...>
3. <...>

## Out of scope

<What this lane explicitly does NOT touch. Anything noticed but not in scope goes here, not into
a step.>

## Escalate, don't decide

<What Codis must bounce back to the orchestrator rather than decide: genuine forks, irreversible
calls, ADR contradictions. Reversible details (naming, layout, which helper) Codis decides.>

## Output contract (Codis must)

- Execute every numbered step; report each as done or skipped-with-reason.
- Reuse what the Reuse notes name; say in the report if you went a different way and why.
- Hold the house style: no comments, no dashes, no dead code, no overcomplication.
- Self-gate with fallow (JS/TS), fix every introduced finding.
- Write a handoff to `orchestrator/handoffs/{{LANE}}.md` if the lane continues; commit early in the worktree.
- Hand off to Revis when every acceptance criterion is met.
