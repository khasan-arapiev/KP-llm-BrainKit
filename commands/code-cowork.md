---
description: Pair-programming build mode. Plans non-trivial work, architects against existing patterns, builds to a high standard proactively. Wrap-up does the rest.
---

Invoke the `code-cowork` skill on whatever feature the owner wants built. Read `~/.claude/skills/code-cowork/SKILL.md` and follow it exactly. Pipeline: locate project + load context → plan (KP-Grill or brainstorming for non-trivial) → runtime-read-path trace for config/schema changes → quick architecture pass against existing ADRs and patterns → build with TDD and the house quality bar → fallow audit gate (JS/TS, when installed) → semantic self-review → commit on a feature branch → hand-off report. Do NOT lint the vault or update index/log — that is wrap-up's job.
