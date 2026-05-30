---
description: Audit a project folder and its vault pages, return a score and a fix plan for approval.
---

Invoke the `KP-Setup` skill and follow Command 2 (KP healthcheck) for the current project or the one the user specifies. Read `~/.claude/skills/KP-Setup/SKILL.md` and follow the "Command 2: KP healthcheck" section exactly. Output: a score, a categorised issue list, and a numbered fix plan. Apply nothing without explicit approval from the owner. For destructive fixes (file deletes), require an explicit `delete` keyword in addition to the number.
