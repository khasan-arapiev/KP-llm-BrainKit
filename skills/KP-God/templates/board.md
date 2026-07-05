---
title: {{PROJECT}} Orchestrator Board
type: orchestrator-board
project: {{SLUG}}
tags: [orchestrator, board, {{SLUG}}]
created: {{TODAY}}
updated: {{TODAY}}
---

# {{PROJECT}} Orchestrator Board

Live coordination surface and the conductor's memory. Every lane state change updates this
file immediately. A fresh conductor chat boots from here. Detail lives in `status.md`,
`plans/`, and `handoffs/`; this board points at them, it does not copy them.

**Keep it lean.** State and pointers only. No `file:line`, no env values, no pasted specs, no
duplicated blocks. When this file grows past roughly 12 KB, compact it: collapse done lanes to
one line each under "Recently done", push any narrative into the relevant handoff, keep only
live state. A board you re-read every boot must stay small.

**Running: 0/5.**

## Decisions waiting on the owner

Batched forks only. Empty when there is nothing genuinely theirs to decide.

- [ ] <lane>: <the fork in one line>. Options: <A> / <B>. Recommend: <A, because ...>

## Lanes

### <lane name> (`parked`)

- **Owner:** none <or: lane tab <session>:<lane-id> if a live session, + git worktree path, + branch>
- **Now:** <one line: the current or next chunk>
- **Next:** <one line>
- **Plan:** <pointer to briefs/<lane>.md (high-stakes lanes), or "lane self-plans", or "none yet">
- **Lane dir:** <orchestrator/lanes/<lane-id>/ — holds brief.md, status, inbox.md, report.md>
- **Handoff:** <pointer into handoffs/ or a vault page, or "none yet">
- **Blocked on:** <only when status is `blocked`>

<!-- Repeat one block per lane. Status is one of:
     running | parked | blocked | verify-owed | done.
     Keep at most 5 lanes `running`. -->

## Parked queue

Lanes ready to activate the moment a running slot frees.

- <lane>: <one line, what it will pick up>

## Recently done

Last few completed lanes, newest first. Prune freely; durable history lives in the log.

- <lane>: <what landed, where (branch/PR/page)>
