---
name: KP-WikiHealth
description: >
  Full-vault health scan. Enumerates every wiki page, runs mechanical
  checks (broken wikilinks, orphans, stale dates, stubs, malformed
  frontmatter, index.md drift, duplicate facts, oversized pages),
  then applies a qualitative read on each deletion candidate to
  judge whether its content still helps future chats. Auto-fixes
  safe stuff (broken-link typos, index drift, updated: bumps).
  Asks the owner before risky stuff (deletes, merges, splits, rewrites).
  Produces one report at the end and logs the run. Always full vault.
  Trigger on: "KP-WikiHealth", "KP-wikihealth", "wiki health",
  "health check the wiki", "lint the wiki", "lint", "scan the vault",
  "vault health", "check vault", "wiki audit", "audit the wiki",
  "clean the vault", "wiki cleanup", "dead files", "find dead pages",
  "orphan pages", "stale pages", "broken links", "wiki maintenance".
license: MIT
---

# KP-WikiHealth

## Vault path

Resolve the vault root from `~/.claude/brainkit.json` (the `vaultPath` key). If that
file is missing, ask the owner where their Brain vault lives and offer to create the
config. Throughout this skill, `<vault>` means that resolved path.

Full-vault health scan. The goal is to leave the vault in a state where future chats are faster, more accurate, and less polluted with dead or duplicated information. Mechanical checks surface candidates; the agent applies judgment to each one; the owner approves anything risky.

## When to use

- the owner asks for a wiki/vault health check, lint, audit, or cleanup.
- Before a long planning session, to make sure the agent will be reading clean context.
- After a big migration or restructure (e.g. KP-Migrate just ran on a project).

## When NOT to use

- Mid-session, when other work is in progress. Run it at a natural break.
- On a specific project only. Use `KP-Healthcheck` for per-project audits.
- As an autofix-everything button. This skill always reports first.

## Scope (always full vault)

The scan covers everything under `<vault>\wiki\`. It does not touch `raw/`, `production/`, `.obsidian/`, `.backups/`, or anything outside `wiki/`. `CLAUDE.md` is read as the schema but never rewritten by this skill.

## How it runs

Six phases. Do them in order. Use TodoWrite to track progress across phases.

### Phase 1 + 2: Mechanical scan (bundled scanner)

Run the bundled deterministic scanner. Do not re-derive these checks by hand and do not write a new ad-hoc script:

```bash
python "$env:USERPROFILE\.claude\skills\KP-WikiHealth\scripts\scan.py"
```

It prints a summary plus a 1-10 health score and writes full JSON to `%TEMP%\wikihealth.json`. Read the JSON selectively, category by category, never whole if large.

What it checks, and the rules baked into it:

1. **Broken wikilinks**, resolved **Brain-wide** (the Obsidian vault root is `Brain\`, not `wiki\`), with code fences AND inline backtick spans stripped first. Links that resolve outside `wiki/` (docs/, CLAUDE.md) are reported as `resolves_outside_wiki`, they are NOT broken.
2. **Rename candidates.** Each broken link carries suffix-match suggestions (broken `[[acme-app-status]]` suggests `projects/acme-app/core/status.md`). Bulk rename damage becomes a repoint mapping, not archaeology. Repoints use full-path links per CLAUDE.md rename hygiene.
3. **Ambiguous links.** A bare `[[status]]`-style link whose stem matches multiple files. Must be rewritten to a path link.
4. **Handoff links.** Wiki pages linking into `handoffs/` (forbidden, handoffs are transient and get deleted).
5. **Memory-slug links.** Links matching `feedback_*` / `project_*` / `user_*` (these live in `~/.claude`, they can never resolve; repoint to a `wiki/lessons/` page).
6. **Orphans, stubs, oversized, stale**, with **frozen exemptions**: pages under any `archive/` folder, under `log-archive/`, or with `status:` shipped / shipped-to-test / accepted / abandoned / superseded are history and skip the stale and oversized checks.
7. **Frontmatter issues** (required fields, unknown types, bad dates) and **UTF-8 BOMs** (a BOM breaks frontmatter parsing for most tools; always strip).
8. **Index drift** both directions, plus **log hygiene**: heading format, single-op rule, and the ~250 KB size budget that triggers a rotation to `wiki/log-archive/<YYYY-MM>.md` per CLAUDE.md.
9. **Duplicate tables and paragraphs** across pages.
10. **Doubled-path links** (`doubled_path`): any wikilink whose target contains the broken `projects/projects/` doubling (a known restructure artifact). Matched on link targets only, so prose that mentions the pattern does not false-positive. Fix is a literal `projects/projects/` → `projects/` replace, vault-wide, then re-scan to zero.
11. **Unknown status** (`unknown_status`): a `plan` or `decision` whose `status:` is outside the canonical enum in `docs/project-handling.md` → Status vocabulary. Normalize to the closest canonical value. Archived pages are exempt.
12. **Generated per-project indexes.** Every `wiki/projects/<slug>/<slug>-index.md` (`type: project-index`) is a build artifact from `scan.py --build-indexes`. The scanner skips these from required-field, stale, and orphan checks. They are what give every project-internal page an inbound link, so the root `index.md` no longer lists per-page plans/decisions/reviews.
13. **Multiple live orchestrator boards** (`multiple_live_boards`): a project with more than one `type: orchestrator-board` page outside `orchestrator/archive/`. A fresh KP-God conductor boots from `board.md`; a second live board means it can boot the wrong one and mix past/present tasks (a real failure mode: days of work built on a stale board). Fix: keep `board.md` canonical, move the rest to `orchestrator/archive/` with an `ARCHIVED` banner, carry live lanes into `board.md`. This is a Phase 5 ask (it moves files), not an auto-fix.
14. **Oversize orchestrator board** (`board_oversize`): a live board past ~12 KB. The conductor re-reads the board every boot, so an oversize board degrades its judgment; KP-God's own rule is to compact at that threshold. Fix (safe inline): collapse done lanes to one line each under "Recently done", move narrative into the relevant lane handoff, keep only live state.

### Phase 3: Qualitative judgment on deletion candidates

A page is only a *candidate* for deletion when mechanical signals hit. Whether it actually gets deleted is a judgment call:

> Would removing this page make future chats faster, more accurate, and less polluted? Or does the content still help, even if the page is orphaned or stub-like?

For each candidate (orphan, stale, or stub from Phase 2), read the page in full and produce one of these recommendations:

- **Delete.** Outdated, contradicted by newer pages, or never-finished scratch that adds no future value. Include the reason in one sentence.
- **Merge into [[X]].** Content has value but belongs on another page. Name the target.
- **Keep, link from [[X]].** Content is fine, it's just unlinked. Name where to add the inbound link.
- **Keep, refresh.** Content is still right but `updated:` is old, or a volatile claim (pricing, competitor data, market figures, API limits) carries a recency marker older than ~6 months or none at all. The fix is a re-read: verify the volatile claims, add or update `(as of YYYY-MM, source)` markers per CLAUDE.md, Recency and confidence, then bump `updated:`.
- **Keep as-is.** Mechanical signal was a false positive (e.g. intentionally short reference page, intentionally orphan top-level entry).

Never recommend Delete on a page whose content is load-bearing in another page's narrative. When in doubt, recommend Merge or Keep + link.

### Phase 4: Auto-fix the safe stuff

Apply these without asking. They are reversible by git and unambiguous:

- **Unambiguous wikilink typos.** Broken `[[target]]` where exactly one page has a name within edit-distance 2 (e.g. `[[vannevar-bush]]` typo'd as `[[vanevar-bush]]`). If two or more candidates match, escalate to Phase 5.
- **Unambiguous rename repoints.** Broken links where the scanner's rename suggestion has exactly one candidate and the surrounding prose clearly means that page. Rewrite as `[[full/path|old display]]`. Multiple candidates → Phase 5.
- **BOM strips.** Remove the UTF-8 BOM from any page that has one.
- **Doubled-path repair.** If `doubled_path` is non-empty, run a literal vault-wide `projects/projects/` → `projects/` replace (preserve line endings), then re-scan to confirm zero. Frozen `log-archive/` prose is included: the replace is meaning-preserving (same display text, link now resolves).
- **Regenerate per-project indexes.** Run `python "$env:USERPROFILE\.claude\skills\KP-WikiHealth\scripts\scan.py" --build-indexes` to rebuild every `wiki/projects/<slug>/<slug>-index.md` from current frontmatter. This is the auto-fix for any project-internal page missing from its catalog. Deterministic, so a clean `git diff` after a regen means the catalogs match the frontmatter.
- **Root index drift (vault-global only).** The root `index.md` lists only cross-project pages (Sources, Entities, Concepts, Syntheses, Comparisons, Social, Lessons, Skills, Projects roster). A vault-global page on disk with proper frontmatter but missing from `index.md` gets added under its category; an entry whose target file no longer exists gets removed. Do NOT hand-add project-internal pages here — they live in the generated `<slug>-index` files.
- **Unknown-status normalize.** A `plan`/`decision` with an off-enum `status:` gets set to the closest canonical value (see `docs/project-handling.md` → Status vocabulary).
- **Log rotation.** If the size budget fired, move all entries older than the current month to `wiki/log-archive/<YYYY-MM>.md` (same format, pointer left in log.md).
- **Frontmatter `updated:` bump.** Only on pages this run modifies. Never bump a page you didn't touch.

Each auto-fix gets a one-liner in the final report so the owner can review.

### Phase 5: Ask before fixing (risky)

For each item, present the candidate and the recommendation. Wait for the owner's go-ahead before changing anything. Batch by category to avoid 30 separate approvals.

- **Deletes.** List every Phase 3 "Delete" recommendation with the one-line reason. The owner can approve all, approve some, or override individual entries.
- **Merges.** List every "Merge into [[X]]" with source, target, and what content moves.
- **Splits.** Every oversized page (>400 lines) with a proposed split (e.g. "split into [[page-overview]] + [[page-details]]").
- **Frontmatter rewrites.** Pages with missing/malformed frontmatter, with the proposed fix.
- **Duplicate-fact resolution.** For each duplicate table or paragraph: which page is the canonical home, which becomes a `[[link]] + one-line summary`.
- **Ambiguous wikilink typos.** Broken links with multiple plausible targets, asking which to use.

### Phase 6: Report and log

After the owner approves and the changes land, produce a final report:

- The health score (from the scanner) before and after the run, so runs are comparable over time.
- Pages deleted (with reasons).
- Pages merged (source → target).
- Pages split.
- Frontmatter fixes.
- Duplicate facts resolved (which page is now canonical).
- Auto-fixes applied (link typos, repoint mappings, BOM strips, index drift, updated bumps).
- Log rotation performed, if the size budget fired.
- Open items the owner deferred (won't fix this run).

Then append a single entry to `wiki/log.md`:

```
## [YYYY-MM-DD] lint | KP-WikiHealth: <N> pages scanned, <D> deleted, <M> merged, <X> auto-fixes, <O> deferred.
```

## House style

- One report at the end, not running commentary. Phase progress goes to TodoWrite, not chat.
- Plain English in recommendations. No em or en dashes.
- Be direct about deletion reasons. "Outdated, replaced by [[X]]" is fine. "May no longer be relevant" is not.
- Never delete or merge without explicit approval. Auto-fix is reserved for the four categories in Phase 4.
- Never invent a canonical page. If Phase 5 needs the owner to pick a canonical home for a duplicate fact, ask, do not guess.

## What this skill never does

- It does not touch `production/`, `raw/`, `.obsidian/`, `.backups/`, or `CLAUDE.md`.
- It does not run per-project (use `KP-Healthcheck` for that).
- It does not auto-delete. Deletes always require explicit the owner approval.
- It does not run code review or PR checks (that is `check-pr` / `wrap-up`).

## Trigger precedence

- **KP-WikiHealth vs wrap-up.** Wrap-up runs at end-of-session and includes a vault lint as one of its phases. KP-WikiHealth is the standalone deep version. If the owner says "wrap up", run wrap-up. If they say "lint" or "wiki health" without code-review context, run this skill.
- **KP-WikiHealth vs KP-Healthcheck.** Healthcheck is for one project folder + its vault pages. WikiHealth is for the whole `wiki/`. If the phrase names a project ("healthcheck acme-site"), Healthcheck wins. If it's vault-wide ("lint the wiki", "scan the vault"), WikiHealth wins.

## Core principles

1. **Mechanical surfaces, judgment decides.** Signals like "no inbound links" surface candidates. Whether to delete is always a judgment call read against the rule: does this help future chats?
2. **Safe auto-fix, risky asks.** The skill is allowed to fix unambiguous things silently. Anything destructive or with multiple valid answers requires the owner to sign off.
3. **One report, one log entry, one run.** Don't produce intermediate reports. Don't log per-phase. The vault gets exactly one entry for the whole sweep.
4. **Leave it cleaner than you found it.** If the report says "fixed 12 things, 3 open items", the open items are real and named, not vague.
