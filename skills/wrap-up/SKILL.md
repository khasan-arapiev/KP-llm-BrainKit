---
name: wrap-up
description: End-of-session orchestrator. Runs the full quality pipeline on every code project touched in the session (architecture review, fallow audit gate, Revis semantic review), then lints the vault, fixes broken links, updates index.md and log.md, and prints a closing message. Use when the owner says "wrap up", "wrap-up", "end session", "I'm done for today", "ship the session", or invokes /wrap-up.
license: MIT
metadata:
  version: "1.1"
allowed-tools: Bash(gh:*) Bash(glab:*) Bash(git:*) Bash(p4:*) Bash(fallow:*) Bash(graphify:*) Bash(python:*) Bash(npm:*) Bash(pnpm:*) Bash(yarn:*) Bash(pytest:*) Bash(go:*) Bash(cargo:*) Read Write Edit Glob Grep Agent AskUserQuestion
---

# wrap-up

## Vault path

Resolve the vault root from `~/.claude/brainkit.json` (the `vaultPath` key). If that
file is missing, ask the owner where their Brain vault lives and offer to create the
config. Throughout this skill, `<vault>` means that resolved path.

End-of-session sweep. The owner has stopped working and wants the session's output cleaned, reviewed, fixed, and filed before they close the chat. This skill runs the full pipeline and only stops when everything is green or genuinely blocked.

It composes three other skills, one subagent, and one CLI tool:

- [[improve-codebase-architecture]] — architecture review (report-only, no interactive grilling).
- `fallow` — deterministic JS/TS audit gate (dead code, complexity, duplication, cycles). Install: `npm install -g fallow`.
- **Revis** (Agent tool, `subagent_type: revis`) — semantic review of the session's diff. This is the review gate that fires on every project.
- [[check-pr]] — surfaces unresolved PR comments, failing checks, missing description. Only when a PR exists.

The wrap-up skill itself is the conductor. It does NOT reimplement what those skills do — it invokes them and threads them together.

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
2. `git status` inside each `production/<slug>/` repo to find uncommitted work.
3. `git log --since="<session-start>"` for recent commits.
4. Vault pages with `updated:` bumped today.

Produce two lists:
- **Code targets**: `production/<slug>/` projects with changes.
- **Vault targets**: wiki pages edited.

If both lists are empty, skip to Phase 4 with a "nothing to wrap up" message.

**graphify check (mandatory per code target).** For each code target, check `graphify-out/graph.json` at the repo root:

- **Present:** confirm the post-commit hook still exists (`.git/hooks/post-commit` mentioning graphify); reinstall with `graphify hook install` if it is gone (hooks get lost on re-clones and worktree moves).
- **Absent (JS/TS project):** build it once, AST-only and free, exactly as [[code-cowork]] Phase 0 does: `.graphifyignore` from the root `.gitignore` plus doc/media globs, `graphify extract . --no-cluster`, `graphify hook install`, and add `graphify-out/` to `.gitignore`.
- **`graphify` not on PATH:** log a warn `graphify not installed` and fall back to Grep for this target.

Then run `graphify affected "<file>"` on the session's changed files and keep the union as the target's **blast radius**. It scopes the Phase 1 architecture review and goes into the Phase 2 Revis brief, replacing guesswork about what the session's changes could have broken.

### Phase 1 — Architecture review (code targets only)

For each code target:

1. Invoke the `improve-codebase-architecture` skill in **report-only mode**, scoped to the Phase 0 blast radius when the graph produced one (whole-project scans on every wrap-up are noise; the session's reach is the review's reach).
   - It scans the project, finds deepening opportunities, writes an HTML report to a temp path.
   - **Do not enter the interactive grilling loop.** The wrap-up runs unattended.
2. Capture the report path.
3. File the report path into the project's vault page at
   `wiki/projects/<slug>/reviews/<YYYY-MM-DD>-architecture.md` with a one-line summary
   and a link to the HTML file. The owner reviews on their own time.

If the skill finds nothing material → log "no architecture issues" and move on.

If the skill cannot run (no source files, language unsupported) → log a warn and move on. Do not fail the whole pipeline.

### Phase 2 — Review gates (code targets only)

For each code target, in this order:

1. **Skip what was already gated.** If this session ran [[code-cowork]] on this project and its hand-off report shows a fallow `pass` and a Revis `ship` for the same diff, do not re-gate that diff. Record `gates: inherited from code-cowork` and jump to step 5. Re-gate only changes made after that report.

2. **fallow audit gate** (JS/TS projects, when `fallow --version` succeeds). Run `fallow audit --format json` scoped to the session's changed files. Same rules as code-cowork Phase 3.5: clear safe findings by hand in monorepos (NEVER `fallow fix` there, it acts repo-wide on inherited findings; single-package repos may use `fallow fix --yes --no-create-config` with a post-run package.json diff), hand-refactor the rest, never suppress with baselines, ignores, or threshold bumps. Loop until `pass` or only accepted-and-justified findings remain. Non-JS/TS stack or fallow missing → log a warn and continue.

3. **Revis review gate** (all stacks). Spawn the `revis` agent via the Agent tool on the session's diff for this project (give it the diff scope, the project slug for ADR cross-checks, what the session was trying to do, and the Phase 0 graphify blast radius so it checks the consumers the diff actually reaches, not just the changed lines). Fix every CRITICAL and IMPORTANT finding it returns. One confirmation round max; if findings survive it, hard stop and surface in the closing report. A `rework` verdict is always a hard stop: wrap-up does not redesign features, it surfaces the verdict for the next session.

4. **Commit and draft PR.** Ensure all working changes are committed (uncommitted edits get `wip: session wrap-up <date>`). If the project has a remote: push the branch and, if no PR/MR exists, open one as a DRAFT (`gh pr create --draft` / `glab mr create --draft`). Draft signals work-in-progress while still being reviewable. No remote → log a warn and move on.

5. **check-pr, only when a PR exists.** Invoke [[check-pr]] on the draft PR to surface unresolved review comments, failing checks, and a missing description; fix what it finds.

6. Record the final state for the closing report: gate verdicts, findings fixed, PR URL if any.

**Hard stop conditions** — if any of these fire, stop the loop for this project, log the reason, and move to the next project:

- The same fallow or Revis finding survives two fix rounds.
- `check-pr` reports a failing check that the agent cannot fix (e.g. a flaky external service, a missing secret).
- A push fails (auth, conflicts, protected branch).

Never force-push or skip hooks. If a hook fails, surface the failure honestly.

### Phase 3 — Vault lint

For every vault target (and any orphan link discovered along the way):

1. Run the bundled KP-WikiHealth scanner first (deterministic, two seconds):
   ```bash
   python "$env:USERPROFILE\.claude\skills\KP-WikiHealth\scripts\scan.py"
   ```
   It covers broken/ambiguous links (Brain-wide, alias-aware), orphans, stale pages, frontmatter, BOMs, index drift, log hygiene, and the log size budget, and prints a health score. **Fix every issue the session introduced** (a link written today that the scanner flags is this session's bug). Pre-existing issues it surfaces go in the closing report, not into drive-by fixes. If the log size budget fired, run the size-based rotation per CLAUDE.md → Log format.
   Then apply the judgment-only checks the scanner cannot do, scoped to pages this session touched:
   - Contradictions between pages.
   - Stale claims (compare to newest source on the same topic).
   - Volatile claims (pricing, competitor data, market figures) missing a recency marker, or carrying one older than ~6 months: flag for refresh per CLAUDE.md, Recency and confidence.
   - Concepts mentioned across pages without their own page.
   - Missing cross-references.

2. Apply only **small inline fixes** (broken links, missing cross-references, frontmatter date bumps for pages actually edited this session). Anything larger — splits, merges, contradictions — goes into the closing report for the owner to decide.

3. Update `wiki/index.md` (**vault-global sections only**). The root index now catalogs only cross-project pages: Sources, Entities, Concepts, Syntheses, Comparisons, Social, Lessons, Skills, and the Projects roster. Add/rename/remove entries there for new vault-global pages.
   - **Do NOT hand-add project-internal pages** (plans, decisions, reviews, post-mortems, learnings) to the root index. Those are cataloged by each project's generated `<slug>-index.md` (regenerated in step 5 below), not by hand. The root index has a `## Project pages` pointer, not per-page lists.
   - A new project (new `<slug>-overview.md`) gets one line in the `## Projects` roster plus a `[[<slug>-index|pages]]` link.

4. **Flip frontmatter on plans/ADRs the session finalised** (silent, no asking — this is a status record, not a destructive change):
   - PRDs whose work landed this session: `status: drafted` → `status: shipped-to-test` (or `shipped`, `accepted`, `abandoned`).
   - ADRs that got accepted this session: confirm `status: accepted` (not still `proposed`).
   - **Reconciliation sweep (anti-staleness, per project touched).** Scan that project's `plans/` and `decisions/` for stale state and flip it: a plan whose work has now promoted to prod → `status: shipped` and **move the file to `plans/archive/`** (shipped sprint plans belong in archive, not the active folder); a plan superseded by a later one → `status: superseded` + archive; an ADR acted-on but still `proposed` → `accepted`. Do NOT archive `shipped-to-test` plans whose verify pass is still pending — those are live pipeline, not done. This is the lifecycle counterpart to the amend-fold rule (CLAUDE.md Discipline A): the active folders hold live work only, done work is reconciled out. No-ask (status records, nothing lost).
   - Don't rewrite the body of these pages — that's a separate operation. Just bump the status so the next agent knows what's done from the frontmatter rather than re-deriving it from logs.
   - **Regenerate the per-project indexes (runs AFTER the flips and the reconciliation sweep above, so they reflect this session's status and any archived/moved files):** `python "$env:USERPROFILE\.claude\skills\KP-WikiHealth\scripts\scan.py" --build-indexes`. This rewrites every `wiki/projects/<slug>/<slug>-index.md` deterministically from frontmatter (title, type, status, created) and the folder layout. An `<slug>-index.md` is a build artifact: never hand-edit one. If `git diff` shows an `<slug>-index` change you did not expect, a page's frontmatter changed (or a file moved) — that is the generator doing its job, not noise.

5. Append entries to `wiki/log.md` using the project's parseable prefix:
   ```
   ## [YYYY-MM-DD] wrap-up | <one-line summary of the session's net change>
   ```
   If multiple distinct activities happened, write multiple lines (one per activity, each with its own op: `ingest`, `query`, `lint`, etc.). Use today's actual date (UTC) — never invent a date. Write the entry **detailed enough that trimming `status.md` (step 6) loses nothing** — this is the relocate-before-delete invariant.

6. **Status hygiene** (project sessions only — no-ask, runs after the log entry exists). For each project touched, trim `core/status.md` back to the contract in `<vault>\docs\project-handling.md` → "Update project status": current state (one short paragraph, latest session only), next up, blockers, load-bearing constants, alive open follow-ups, and the routing table. Apply the keep-vs-move test to every block — *"would the next chat lose a fact it needs to act or avoid a mistake?"* If no, it is backward-facing narration and was already captured in `log.md` at step 5, so remove it from status. Refresh the **Next up** section to drop work that shipped this session. This is no-ask (the content lives in the log; nothing is lost), exactly like the frontmatter flips in step 4 — do NOT route it through Phase 4's ask-first cleanup. If `status.md` is over ~80 lines after the trim, it still carries narration that belongs in the log; trim again. When a block is ambiguous, keep it in status (over-trimming is the only failure mode that hurts the next chat). Bump `updated:`.

### Phase 4 — Junk cleanup (ask before destroying)

Scan the working tree and surface ephemeral artifacts that became stale this session. **Never auto-delete.** This phase targets **ephemeral session junk only**, not load-bearing development assets.

#### What counts as deletable (ephemeral session junk)

ONLY propose deletion for items that match one of these narrow categories:

- **Visual mockups** under `production/<slug>/workshop/<feature>/` whose feature is now live. Pure visual reference (HTML mockups, screenshots, exported design files). NOT code, NOT plans.
- **Scratch HTML, screenshots, throwaway test fixtures** in `workshop/`, `scratch/`, or `tmp/` whose purpose was a one-off planning exercise that is now done.
- **Local build artifacts** matching `*.log`, `*.bak`, `*.tmp`, `*.swp`, `*.swo`, `*~` that are not in `.gitignore` and that were obviously produced by a tool run, not authored.
- **Empty placeholder folders** created during the session and never used.
- **Stale TODO comments in code** that explicitly say "remove when X lands" where X has demonstrably landed. This is a code edit, not a file delete, but still ask.
- (Status-doc hygiene is handled in Phase 3 step 6 as a no-ask move — the content is relocated to `log.md`, not lost — so it does not belong in this ask-first cleanup phase. Do not re-surface it here.)

That is the complete list. If the candidate does not fit one of those categories, do not propose it.

#### What is NEVER deletable, regardless of "is it still needed"

The following are **load-bearing development assets**. They may look redundant after a phase ships, but they carry information that has no other home. Do not propose them for deletion. If you catch yourself reasoning "this seems redundant because X shipped", that is the wrong frame for these:

- **Git branches.** Even fully-merged feature branches are useful as phase markers: `git checkout <branch>` reproduces the exact state at that phase boundary, and `git log --first-parent` reads cleaner. The only reason to delete a branch is if the owner explicitly says "delete this branch".
- **Git commits, tags, reflog entries.** Never. History is sacred.
- **PRDs, plans, architecture notes, ADRs, post-mortems, learnings, lessons.** Even after the work ships. Mark them with the right frontmatter status (Phase 3 of this skill) but never delete the file. Abandoned drafts get `status: abandoned`, not deletion, unless the owner explicitly says delete.
- **Anything under `wiki/`** other than confirmed-abandoned drafts that the owner has already explicitly OKed for removal. The vault is the long-term knowledge base.
- **Anything under `Brain/security/`** ever. Credentials and references.
- **Tracked code files** in any `production/<slug>/`. If code is dead, the right tool is a code review pass that surfaces dead code with reasons, not a wrap-up deletion.
- **Module schemas, migrations, Prisma files, manifests.** Even empty ones (an empty `modules/<slug>/schema.prisma` is intentional scaffolding for the next phase).
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
  - <slug>: fallow <pass / N fixed / N/A>, revis <ship / N findings fixed / inherited from code-cowork>, PR #<num> <link>
  - <slug>: skipped (no remote) / blocked — <reason>

Architecture reports:
  - <slug>: <wiki path to today's review page>

Vault:
  - <X> pages updated
  - <Y> broken links fixed
  - <Z> PRD/ADR statuses bumped to shipped/accepted
  - index.md: <Z> additions
  - log.md: appended

Cleanup:
  - <N> mockup folders deleted (approved)
  - <N> stale next-session pointers trimmed (approved)
  - <N> deletions deferred (the owner said keep)

Open items for you:
  - <slug>: 2 large refactor candidates need a decision (see review page)
  - <broken cross-ref nobody owns>

All clean. Safe to close the chat.
```

If anything is genuinely blocked, end with `Blocked: <count>. Not safe to close until resolved.` instead of "Safe to close".

---

## Discipline rules

Four rules carried over from the vault's CLAUDE.md, retuned for this skill.

**A. Honesty over comfort.**
Never report a gate clean unless it actually ran and you saw the result: fallow's verdict from its real output, Revis's verdict from its findings block. Never report "vault linted" unless every item on the checklist was checked. If a step was skipped, say which one and why. "Safe to close" is a load-bearing claim — only print it when it is true.

**B. No drive-by changes.**
The wrap-up touches what the session touched, plus anything the session's edits broke (e.g. a renamed page leaves a dangling link — fix that). It does not refactor unrelated pages, restructure unrelated code, or "improve" things the owner did not ask about. Surface those in the closing report instead.

**C. Reversibility.**
Every code change must go through a draft PR — never push direct to main, never force-push, never skip hooks. Vault edits are commits in the user's local working copy; they are reversible via git. If a destructive action would be required (delete a vault page, drop a branch), surface it in the closing report and stop. Wait for explicit approval.

**D. Ask before destroying — always grouped, always purposeful.**
Phase 4 (cleanup) NEVER auto-deletes. Every deletion proposal is grouped by purpose and asked in plain English: "I want to delete these N files. Their purpose was X. They are no longer needed because Y. Approve?" the owner can approve, deny, or pick subsets. Status-record writes (PRD frontmatter flips, log entries) don't need asking because no information is lost — but file deletions and content rewrites always do.

---

## Verify checkpoints

Before printing "Safe to close", confirm each of these. If any fail, the closing report says "Not safe to close" with the failing item.

1. Phase 0 ran and produced a scope, plus a graphify status per code target (blast radius captured, graph built fresh, or a logged warn). (Or printed "nothing to wrap up".)
2. Every code target has a recorded fallow verdict and Revis verdict (run this session, or inherited from a code-cowork report covering the same diff), or is logged as skipped/blocked with a reason.
3. Every architecture report path exists on disk.
4. `wiki/index.md` was read and updated if any pages were created/renamed/deleted.
5. `wiki/log.md` has a new entry with today's date and the `wrap-up` op.
6. For every project touched, `core/status.md` was trimmed to the contract (current state + next up + blockers + routing table; no session narration) and its session detail is in `log.md`. If status still narrates sessions or runs long, the trim did not run — go back to Phase 3 step 6.
7. No `[[wikilinks]]` introduced by this session's edits are broken.
8. The closing report was printed.

If a checkpoint fails, say so. Do not claim the operation is complete.

---

## What this skill is NOT for

- Mid-session sanity checks. Use `KP-Healthcheck` or run the individual skills directly.
- One-off PR review. Run `/check-pr <num>` directly.
- Vault lint by itself. Just say "lint the wiki" — the CLAUDE.md operation covers it.
- New project setup. Use `KP-Setup`.

This is the closing ritual. Run it once at the end of a working session.
