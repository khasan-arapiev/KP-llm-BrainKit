---
name: wrap-up
description: End-of-session orchestrator. Runs a quick architecture self-review on every code project touched in the session, then lints the vault, fixes broken links, updates index.md and log.md, proposes cleanup of session junk, and prints a closing message. Use when the owner says "wrap up", "wrap-up", "end session", "I'm done for today", "ship the session", or invokes /wrap-up.
license: MIT
metadata:
  version: "1.0"
allowed-tools: Bash(gh:*) Bash(glab:*) Bash(git:*) Bash(p4:*) Read Write Edit Glob Grep
---

# wrap-up

End-of-session sweep. The owner has stopped working and wants the session's output cleaned, reviewed, fixed, and filed before they close the chat. This skill runs the pipeline and only stops when everything is green or genuinely blocked.

It is self-contained: the architecture review and vault lint are done inline, not by invoking other skills.

## Vault path

Resolve the vault root from `~/.claude/brainkit.json` (the `vaultPath` key). If that
file is missing, ask the owner where their Brain vault lives and offer to create the
config. Throughout this skill, `<vault>` means that resolved path.

---

## When to run

The owner triggers this when they are done for the session. Typical phrasings:

- "wrap up"
- "wrap-up"
- "/wrap-up"
- "I'm done for today, finalise everything"
- "end session"
- "ship the session"

Do NOT run mid-task. This is a closing ritual, not a continuous check.

---

## Pipeline

Run these phases in order. Each phase produces a status (ok / warn / fail). Roll the worst status forward so the final report reflects reality.

### Phase 0 — Detect session scope

Identify what was actually touched in this session. Sources of truth, in order:

1. The conversation context (files the owner and the agent edited, projects discussed).
2. `git status` inside each code project repo to find uncommitted work.
3. `git log --since="<session-start>"` for recent commits.
4. Vault pages with `updated:` bumped today.

Produce two lists:
- **Code targets**: code projects with changes.
- **Vault targets**: wiki pages edited.

If both lists are empty, skip to Phase 4 with a "nothing to wrap up" message.

### Phase 1 — Architecture self-review (code targets only)

For each code target, do a quick read-only architecture pass yourself. This is a check, not a redesign, and it runs unattended.

1. Re-read the project's ADRs (`wiki/projects/<slug>/decisions/`) and `core/map.md` for the boundaries and conventions in place.
2. Look at the diff the session produced. Note anything that drifts: a new module that duplicates an existing one, a boundary crossed, a pattern broken, a file that has grown past its size cap, dead code left behind.
3. If something material surfaces, file it as a learning at `wiki/projects/<slug>/learnings/<YYYY-MM-DD>-<short-slug>.md` (using the learning template in `<vault>/docs/project-handling.md`) and note it in the closing report. If nothing material → log "no architecture issues" and move on.

If the project has no ADRs or map yet → review against the conventions visible in the code, and log a warn that there is no recorded architecture to check against.

### Phase 2 — Commit and surface code state (code targets only)

For each code target:

1. Ensure all working changes are committed on a feature branch (not main). If there are uncommitted edits, commit them with a message like `wip: session wrap-up <date>`.
2. If the project has a remote and the owner uses PRs, push the branch and ensure a draft PR exists (`gh pr create --draft` or `glab mr create --draft`). Draft signals work-in-progress.
3. Record the branch and PR state (if any) for the closing report.

Never force-push or skip hooks. If a hook fails, surface the failure honestly. If the project has no remote, log a warn ("no remote, local commit only") and move on.

### Phase 3 — Vault lint

For every vault target (and any orphan link discovered along the way):

1. Run the standard vault lint checklist from `<vault>/CLAUDE.md` under "Operations → Lint":
   - Contradictions between pages.
   - Stale claims (compare to newest source on the same topic).
   - Volatile claims (pricing, competitor data, market figures) missing a recency marker, or carrying one older than ~6 months. See CLAUDE.md, Recency and confidence.
   - Orphan pages.
   - Concepts mentioned across pages without their own page.
   - Missing cross-references.
   - Broken `[[wikilinks]]`.
   - Pages where `updated:` is older than 90 days.

2. Apply only **small inline fixes** (broken links, missing cross-references, frontmatter date bumps for pages actually edited this session). Anything larger — splits, merges, contradictions — goes into the closing report for the owner to decide.

3. Update `wiki/index.md`:
   - Add any new pages created this session under their categories.
   - Remove or rename entries for pages renamed or deleted.

4. **Flip frontmatter on plans/ADRs the session finalised** (silent, no asking — this is a status record, not a destructive change):
   - PRDs whose work landed this session: `status: drafted` → `status: shipped` (or `accepted`, `abandoned`).
   - ADRs that got accepted this session: confirm `status: accepted` (not still `proposed`).
   - Don't rewrite the body of these pages — that's a separate operation. Just bump the status so the next agent knows what's done from the frontmatter rather than re-deriving it from logs.

5. Append entries to `wiki/log.md` using the parseable prefix:
   ```
   ## [YYYY-MM-DD] wrap-up | <one-line summary of the session's net change>
   ```
   If multiple distinct activities happened, write multiple lines (one per activity, each with its own op: `ingest`, `query`, `lint`, etc.). Use today's actual date — never invent a date.

### Phase 4 — Junk cleanup (ask before destroying)

Scan the working tree and surface ephemeral artifacts that became stale this session. **Never auto-delete.** This phase targets **ephemeral session junk only**, not load-bearing development assets.

#### What counts as deletable (ephemeral session junk)

ONLY propose deletion for items that match one of these narrow categories:

- **Visual mockups** under a project's `workshop/<feature>/` whose feature is now live. Pure visual reference (HTML mockups, screenshots, exported design files). NOT code, NOT plans.
- **Scratch HTML, screenshots, throwaway test fixtures** in `workshop/`, `scratch/`, or `tmp/` whose purpose was a one-off planning exercise that is now done.
- **Local build artifacts** matching `*.log`, `*.bak`, `*.tmp`, `*.swp`, `*.swo`, `*~` that are not in `.gitignore` and that were obviously produced by a tool run, not authored.
- **Empty placeholder folders** created during the session and never used.
- **Stale TODO comments in code** that explicitly say "remove when X lands" where X has demonstrably landed. This is a code edit, not a file delete, but still ask.
- **Stale "next session" pointers** in status docs that reference work already shipped. Propose the rewrite as a single grouped change (not a file delete).

That is the complete list. If the candidate does not fit one of those categories, do not propose it.

#### What is NEVER deletable, regardless of "is it still needed"

The following are **load-bearing development assets**. They may look redundant after a phase ships, but they carry information that has no other home. Do not propose them for deletion. If you catch yourself reasoning "this seems redundant because X shipped", that is the wrong frame for these:

- **Git branches.** Even fully-merged feature branches are useful as phase markers. The only reason to delete a branch is if the owner explicitly says "delete this branch".
- **Git commits, tags, reflog entries.** Never. History is sacred.
- **PRDs, plans, architecture notes, ADRs, post-mortems, learnings, lessons.** Even after the work ships. Mark them with the right frontmatter status (Phase 3 of this skill) but never delete the file. Abandoned drafts get `status: abandoned`, not deletion, unless the owner explicitly says delete.
- **Anything under `wiki/`** other than confirmed-abandoned drafts that the owner has already explicitly OKed for removal. The vault is the long-term knowledge base.
- **Anything holding secrets or credentials, ever.**
- **Tracked code files** in any project. If code is dead, the right tool is a code review pass that surfaces dead code with reasons, not a wrap-up deletion.
- **Module schemas, migrations, Prisma files, manifests.** Even empty ones (intentional scaffolding for the next phase).
- **CLAUDE.md, README.md, CONTRIBUTING.md** routers.
- **`.obsidian/` config, `.gitignore`, lockfiles, `package.json`.**

When in doubt, do not delete. The cost of leaving a stray file is near-zero. The cost of deleting something the owner still relies on is high.

#### The ask

Use a separate AskUserQuestion per category. Each ask names the category, the purpose those files served, why they are no longer needed, and the recoverability of the deletion:

> I want to delete these 5 mockup folders. Their purpose was to help us pick visuals during planning for [feature]. They shipped on [date, commit]. Deleting them frees up workshop/ and removes outdated visual references. Approve?

- gitignored → "local-only, recoverable via local filesystem undelete only"
- tracked → "this will be a commit on `<branch>`, recoverable via `git revert`"

Never group across categories. If mockups AND stale TODOs both exist, ask twice. If a category has zero items, do not ask about it (no "approve to delete 0 items" prompts).

If the owner said something at the start of the session like "clean everything that's not needed" → that is blanket approval for the categories above only, NOT a licence to delete load-bearing assets. Still group and surface for visibility, but don't pause on each ask.

If the owner never granted blanket approval → wait on every ask.

If the owner pushes back on any single item ("why is X junk?"), drop the ENTIRE category for this run and surface the reasoning in the closing report. Better to leave clutter than to bulldoze something with hidden value.

### Phase 5 — Closing report

Print a single block to the conversation. Format:

```
=== wrap-up complete ===

Code projects (N):
  - <slug>: committed on <branch>, draft PR #<num> (<link>)
  - <slug>: local commit only (no remote)
  - <slug>: blocked — <reason>

Architecture:
  - <slug>: <"no issues" or "1 learning filed — see wiki path">

Vault:
  - <X> pages updated
  - <Y> broken links fixed
  - <Z> PRD/ADR statuses bumped to shipped/accepted
  - index.md: <Z> additions
  - log.md: appended

Cleanup:
  - <N> mockup folders deleted (approved)
  - <N> stale next-session pointers trimmed (approved)
  - <N> deletions deferred (owner said keep)

Open items for you:
  - <slug>: 2 large refactor candidates need a decision (see learning page)
  - <broken cross-ref nobody owns>

All clean. Safe to close the chat.
```

If anything is genuinely blocked, end with `Blocked: <count>. Not safe to close until resolved.` instead of "Safe to close".

---

## Discipline rules

Four rules carried over from the vault's CLAUDE.md, retuned for this skill.

**A. Honesty over comfort.**
Never report "vault linted" unless every item on the checklist was checked. If a step was skipped, say which one and why. "Safe to close" is a load-bearing claim — only print it when it is true.

**B. No drive-by changes.**
The wrap-up touches what the session touched, plus anything the session's edits broke (e.g. a renamed page leaves a dangling link — fix that). It does not refactor unrelated pages, restructure unrelated code, or "improve" things the owner did not ask about. Surface those in the closing report instead.

**C. Reversibility.**
Every code change must go through a feature branch — never push direct to main, never force-push, never skip hooks. Vault edits are commits in the owner's local working copy; they are reversible via git. If a destructive action would be required (delete a vault page, drop a branch), surface it in the closing report and stop. Wait for explicit approval.

**D. Ask before destroying — always grouped, always purposeful.**
Phase 4 (cleanup) NEVER auto-deletes. Every deletion proposal is grouped by purpose and asked in plain English. The owner can approve, deny, or pick subsets. Status-record writes (PRD frontmatter flips, log entries) don't need asking because no information is lost — but file deletions and content rewrites always do.

---

## Verify checkpoints

Before printing "Safe to close", confirm each of these. If any fail, the closing report says "Not safe to close" with the failing item.

1. Phase 0 ran and produced a scope. (Or printed "nothing to wrap up".)
2. Every code target is committed, and its branch/PR state is recorded, or it is logged as blocked with a reason.
3. Any architecture learning filed exists on disk.
4. `wiki/index.md` was read and updated if any pages were created/renamed/deleted.
5. `wiki/log.md` has a new entry with today's date and the `wrap-up` op.
6. No `[[wikilinks]]` introduced by this session's edits are broken.
7. The closing report was printed.

If a checkpoint fails, say so. Do not claim the operation is complete.

---

## What this skill is NOT for

- Mid-session sanity checks. Use `KP-Healthcheck` or run the individual skills directly.
- Vault lint by itself. Just say "lint the wiki" — the CLAUDE.md operation covers it, or use `KP-WikiHealth` for the deep version.
- New project setup. Use `KP-Setup`.

This is the closing ritual. Run it once at the end of a working session.
