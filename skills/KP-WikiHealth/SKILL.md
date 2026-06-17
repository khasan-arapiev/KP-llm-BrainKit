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

Full-vault health scan. The goal is to leave the vault in a state where future chats are faster, more accurate, and less polluted with dead or duplicated information. Mechanical checks surface candidates; the agent applies judgment to each one; the owner approves anything risky.

## Vault path

Resolve the vault root from `~/.claude/brainkit.json` (the `vaultPath` key). If that
file is missing, ask the owner where their Brain vault lives and offer to create the
config. Throughout this skill, `<vault>` means that resolved path.

## When to use

- The owner asks for a wiki/vault health check, lint, audit, or cleanup.
- Before a long planning session, to make sure the agent will be reading clean context.
- After a big migration or restructure (e.g. KP-Migrate just ran on a project).

## When NOT to use

- Mid-session, when other work is in progress. Run it at a natural break.
- On a specific project only. Use `KP-Healthcheck` for per-project audits.
- As an autofix-everything button. This skill always reports first.

## Scope (always full vault)

The scan covers everything under `<vault>/wiki/`. It does not touch `raw/`, `production/`, `.obsidian/`, `.backups/`, or anything outside `wiki/`. `CLAUDE.md` is read as the schema but never rewritten by this skill.

## How it runs

Six phases. Do them in order. Use TodoWrite to track progress across phases.

### Phase 1: Inventory

1. Glob every `.md` file under `wiki/`. Build the canonical page list.
2. For each page, parse frontmatter. Note any that are missing or malformed.
3. Build a link graph: for each page, list the `[[wikilinks]]` it contains and the pages that link to it.
4. Read `wiki/index.md` and extract every page slug it references.
5. Read `wiki/log.md` and confirm each entry matches `## [YYYY-MM-DD] <op> | <summary>` format.

Output of this phase is a working set the next phases scan against. No edits yet.

### Phase 2: Mechanical scan (surface candidates only)

Run all of these. Each produces a list of pages or issues. Nothing is fixed yet.

1. **Broken wikilinks.** Every `[[target]]` whose target does not resolve to a real page.
2. **Orphan pages.** Pages with zero inbound `[[wikilinks]]` AND not listed in `index.md`.
3. **Stale pages.** `updated:` older than 90 days from today's date.
4. **Stub pages.** Body (post-frontmatter) shorter than 50 words.
5. **Frontmatter issues.** Missing required fields (`title`, `type`, `created`, `updated`), unknown `type` values, malformed YAML.
6. **Index drift.** Pages that exist on disk but aren't in `index.md`. Entries in `index.md` whose target doesn't exist.
7. **Log format violations.** Entries that don't match the `## [YYYY-MM-DD] <op> | <summary>` prefix.
8. **Duplicate tables.** Same table headers (full row, normalised whitespace) appearing on 2+ pages.
9. **Duplicate paragraphs.** Same paragraph (3+ sentences, normalised whitespace) appearing on 2+ pages.
10. **Oversized pages.** More than 400 lines (split candidates per CLAUDE.md schema).

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

- **Unambiguous wikilink typos.** Broken `[[target]]` where exactly one page has a name within edit-distance 2 (e.g. `[[vannevar-bush]]` typo'd as `[[vannevar-bsh]]`). If two or more candidates match, escalate to Phase 5.
- **Index drift adds.** Pages that exist on disk and have proper frontmatter but aren't in `index.md` get added under the correct category.
- **Index drift removes.** Entries in `index.md` whose target file does not exist get removed.
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

- Pages deleted (with reasons).
- Pages merged (source → target).
- Pages split.
- Frontmatter fixes.
- Duplicate facts resolved (which page is now canonical).
- Auto-fixes applied (link typos, index drift, updated bumps).
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
- It does not auto-delete. Deletes always require explicit owner approval.
- It does not run code review or PR checks (that is `wrap-up`'s job).

## Trigger precedence

- **KP-WikiHealth vs wrap-up.** Wrap-up runs at end-of-session and includes a vault lint as one of its phases. KP-WikiHealth is the standalone deep version. If the owner says "wrap up", run wrap-up. If they say "lint" or "wiki health" without code-review context, run this skill.
- **KP-WikiHealth vs KP-Healthcheck.** Healthcheck is for one project folder + its vault pages. WikiHealth is for the whole `wiki/`. If the phrase names a project ("healthcheck my-app"), Healthcheck wins. If it's vault-wide ("lint the wiki", "scan the vault"), WikiHealth wins.

## Core principles

1. **Mechanical surfaces, judgment decides.** Signals like "no inbound links" surface candidates. Whether to delete is always a judgment call read against the rule: does this help future chats?
2. **Safe auto-fix, risky asks.** The skill is allowed to fix unambiguous things silently. Anything destructive or with multiple valid answers requires the owner to sign off.
3. **One report, one log entry, one run.** Don't produce intermediate reports. Don't log per-phase. The vault gets exactly one entry for the whole sweep.
4. **Leave it cleaner than you found it.** If the report says "fixed 12 things, 3 open items", the open items are real and named, not vague.
