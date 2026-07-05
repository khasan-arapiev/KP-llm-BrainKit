---
name: KP-Setup
description: >
  Project structural steward. Two commands only: `KP setup` scaffolds a new
  project folder (skinny: code, .gitignore, and a thin CLAUDE.md router
  only); `KP healthcheck` audits an existing project and produces a fix
  plan that the owner must approve before any change is applied. All project
  knowledge (map, context, review, status, ADRs, post-mortems, learnings)
  lives in the Obsidian Brain vault at <vault> and is
  out of scope for this skill. Trigger on: "KP setup", "KP-setup",
  "KP healthcheck", "KP-healthcheck", "set up project", "scaffold project",
  "new project", "audit project", "health check project", "project hygiene",
  "is this project clean".
license: MIT
---

# KP-Setup

A small, focused skill. Two commands:

1. **KP setup.** Scaffold a new project folder and its matching vault pages. Wire them together.
2. **KP healthcheck.** Audit a project folder and its vault pages. Produce a scored report plus a numbered fix plan. **Apply nothing without the owner's approval.**

Anything beyond these two is out of scope. Knowledge capture, ADRs, post-mortems, learnings, planning, debugging loops, handoffs, session state are owned by the Obsidian Brain vault. This skill never writes those.

## The architecture this skill assumes

```
Project folder (lives with the code):
  CLAUDE.md         Thin router. Points to vault. ~30 lines max.
  .gitignore
  project/          The code (or app/, src/, whatever convention)
  workshop/         Scratch, experiments, drafts. Never deployed.
  assets/           Images, fonts, raw materials.

Vault (<vault>, single source of truth for knowledge):
  wiki/projects/<slug>/
    <slug>-overview.md   The entry point. Stack, status, links. (e.g. acme-app-overview.md)
    core/                Supporting reference docs.
      map.md             Module map, entry points, layering, local dev.
      context.md         Domain glossary.
      review.md          Definition of Done.
      status.md          Last session, next up, blockers.
      strategy.md        Positioning, business model (optional).
    plans/               PRDs / forward-looking specs. Files named <short-slug>.md, no date prefix.
    decisions/           ADRs. <short-slug>.md.
    post-mortems/        Post-mortems. <short-slug>.md.
    learnings/           Captured learnings. <short-slug>.md.

  Every page inside core/, plans/, decisions/, etc. carries `aliases: [<slug>-<type>, ...]`
  in frontmatter so cross-project wikilinks like [[acme-app-map]] still resolve.

Client umbrella projects (e.g. Acme Corp) nest sub-projects, each with their own core/:
  wiki/projects/<client-slug>/
    <client-slug>-overview.md
    core/ plans/ decisions/ post-mortems/ learnings/    Client-wide.
    <subproject-slug>/
      <subproject-slug>-overview.md
      core/ plans/ decisions/ post-mortems/ learnings/   Sub-project-scoped.
```

The project `CLAUDE.md` is the only doc that lives with the code. It points the agent at the vault for everything else.

## Vault path

Resolve the vault root from `~/.claude/brainkit.json` (the `vaultPath` key). If that
file is missing, ask the owner where their Brain vault lives and offer to create the
config. Throughout this skill, `<vault>` means that resolved path.

---

## Command 1: KP setup

Trigger: "KP setup", "KP-setup", "set up project", "scaffold project <name>", "new project <name>".

### Inputs

Ask only for what cannot be inferred:
- Project name and slug (kebab-case, e.g. `recipe-box`, `studio-tool`).
- Project folder path (default: current working directory).
- Stack (one word: node, php, python, static-html, mixed). Skip if existing files make it obvious.
- One-line purpose.

### Steps

1. **Verify vault is reachable.** Check `<vault>\CLAUDE.md` exists. If not, stop and ask the owner to set up the vault first.
2. **Verify project folder.** Define "non-empty" as containing files other than `.git/`, `.gitignore`, and standard editor metadata (`.vscode/`, `.idea/`, `.editorconfig`, `.DS_Store`). If non-empty by that definition, dry-run first: list what would be created or skipped. Wait for approval.

   **Read the existing layout before deciding what to create.** If the folder already contains `src/`, `app/`, `lib/`, `pages/`, or `bot/`, treat that as the equivalent of `project/` and do NOT create a separate `project/` folder. If a framework marker exists (`next.config.*`, `vite.config.*`, `astro.config.*`, `nuxt.config.*`, `svelte.config.*`, `remix.config.*`, `package.json` with a known framework dep, `requirements.txt` for Python apps), treat the framework's expected layout as the authoritative variant and skip creating `project/` entirely. Note the chosen variant in the project's vault `map.md` so future healthchecks know what to expect.

   **Check for an existing PRD.** If `wiki/projects/<slug>/plans/` already contains a PRD, read its frontmatter (`proposed_slug`, `proposed_path`, `proposed_stack`) and pre-fill the inputs from there. Only ask for what is missing.
3. **Create project folder structure:**
   - `project/` only if no existing variant (`src/`, `app/`, `lib/`, `pages/`, `bot/`) and no framework marker is present. Otherwise reuse the existing layout.
   - `workshop/` always.
   - `assets/` always.
   - `.gitignore` from `templates/gitignore.txt` (only if missing).
   - `CLAUDE.md` from `templates/project-CLAUDE.md` (fill in `{{...}}` placeholders; `{{OWNER}}` comes from `~/.claude/brainkit.json`, and replace every `<vault>` with the resolved absolute vault path so the generated file stands alone). No README. The vault `overview.md` is the single "what is this" page.
4. **Create vault pages** at `<vault>\wiki\projects\<slug>\`:
   - `<slug>-overview.md` at the project folder root (entry point, keeps slug prefix).
   - `core/` subfolder with `map.md`, `context.md`, `review.md`, `status.md` (plus `strategy.md` if relevant). Each file's frontmatter MUST include `aliases: [<slug>-<type>, ...]` so cross-project links resolve.
   - Empty `plans\`, `decisions\`, `post-mortems\`, `learnings\` folders.
5. **Update vault `index.md`.** Add the new project under `## Projects` (create the section if missing). Format: `- [[<slug>-overview]] <one-line purpose>.`
6. **Update vault `log.md`.** Append: `## [YYYY-MM-DD] setup | New project <slug> scaffolded.`
7. **Report back.** List every file and folder created. Show the vault overview wikilink. Tell the owner to fill in `overview.md` and `context.md` first.

Never overwrite existing files. If a target file exists, skip it and flag it in the report.

---

## Command 2: KP healthcheck

Trigger: "KP healthcheck", "KP-healthcheck", "audit project", "health check this", "is this project clean".

### Two-phase flow

**Phase 1: scan and score.** Run all checks. Output a score plus a categorised issue list plus a numbered fix plan.

**Phase 2: apply fixes.** Wait for the owner's approval on the plan. Apply only the items they greenlight. Skip the rest.

This skill never auto-applies fixes. Approval is required even for fixes that look trivial.

### Project folder checks

| Check | Pass condition | Weight |
|---|---|---|
| Layering | `project/`, `workshop/`, `assets/` exist, OR a documented variant (`src/`, `app/`, `lib/`, `pages/`, `bot/`), OR a recognised framework layout (Next.js, Vite, Astro, Nuxt, Svelte, Remix, etc. detected by config file). Framework projects are not penalised for missing `project/`. | 10 |
| Trash in project root | No `*.bak`, `*.tmp`, `*.log`, `test-*.html`, scratch files. Exclude `tests/`, `__tests__/`, `e2e/`, `cypress/`, `playwright/`, `spec/`, `__fixtures__/` directories from the scan. Test files inside those directories are legit, not trash. | 10 |
| .gitignore present | Standard ignores for the stack | 5 |
| Vault overview present | `<vault>\wiki\projects\<slug>\<slug>-overview.md` exists and non-empty | 5 |
| Vault core/ folder populated | `core/map.md`, `core/context.md`, `core/review.md`, `core/status.md` all exist | 5 |
| Project `CLAUDE.md` thin | Exists, under 120 lines, contains the vault pointer | 10 |
| Junk comments | No "as requested", "removed feature X", "added by Claude" | 10 |
| File size caps | No code file over its stack's cap (table below) | 10 |
| Dead code | No commented-out blocks larger than 5 lines | 5 |

Stack size caps (lines):
- JS / TS: 300
- PHP: 400
- Python: 400
- HTML / Liquid: 500
- CSS: 600
- Markdown: 400

### Vault page checks

| Check | Pass condition | Weight |
|---|---|---|
| Project folder exists in vault | `<vault>\wiki\projects\<slug>\` present | 5 |
| Required pages exist | `<slug>-overview.md` at root, plus `core/map.md`, `core/context.md`, `core/review.md`, `core/status.md` all present | 10 |
| Freshness | No vault page with `updated:` older than 90 days | 10 |
| Dead wikilinks | Every `[[link]]` in the project's vault pages resolves | 5 |
| Indexed | Project listed in vault `index.md` | 5 |

### Output format

```
KP healthcheck: <project-name>
Score: 84 / 100

Issues:
  [10] Trash in project/: test-pricing.html, debug.log
  [05] Project CLAUDE.md is 142 lines (cap 80)
  [10] File size: project/lib/utils.js is 411 lines (cap 300)
  [05] Stale vault page: projects/<slug>/context.md updated 108 days ago

Fix plan (awaiting approval):
  1. Move test-pricing.html and debug.log to workshop/, or delete them.
  2. Trim project CLAUDE.md to the router-only template (move any prose out to the vault overview page).
  3. Propose a split of utils.js into focused modules. Surface the split before editing.
  4. Re-read project/lib/, refresh context.md in the vault, bump updated.

Reply with the numbers you want applied (e.g. "1, 2, 4"), or "all", or "none".
```

### Apply phase

After the owner approves a subset:
- Run each approved fix.
- Report what was done and what was left.
- Update vault `log.md`: `## [YYYY-MM-DD] healthcheck | <project>: applied fixes 1, 2, 4. Score now <new>/100.`

If a fix would touch code structurally (splitting a file, renaming modules), propose the change first, do not apply blindly. The healthcheck identifies the issue. The fix may still need a separate planning step.

**Destructive approval rule.** For any fix that DELETES files (trash removal, dead-file cleanup, anything irreversible), numeric approval alone is not enough. The owner must include the keyword `delete` next to the number. Examples:

- `"1, 2, 4"` applies fixes 1, 2, 4 if and only if none of them delete files. Any delete fix in that list is skipped.
- `"1, 2, delete 4"` applies 1 and 2 fully, plus explicitly executes the deletion in fix 4.
- `"all"` applies non-destructive fixes only. To apply every fix including deletes, the owner must say `"all, delete"`.

When a delete fix is skipped due to missing keyword, list it separately in the report so the owner can re-approve with the keyword if they meant to.

---

## What this skill never does

To stay in lane:

- It never writes ADRs, post-mortems, learnings, or planning docs into the project folder. Those live in the vault. If the project surfaces one of these during a healthcheck, the fix plan suggests filing it in the vault, not in the project.
- It never captures session learnings, never has a `save` command, never stages `.pending/` files. The vault owns ingest and learning.
- It never prints a status block on session start. The vault is the brain.
- It never auto-applies healthcheck fixes. Approval is always required.
- It never deletes files without the explicit `delete` keyword from the owner.
- It never tracks "in-flight workflows" or session state. If the owner needs that, it goes in the vault's status page for the project.

## Trigger precedence

- **KP-Setup vs KP-Grill.** If the owner says "let's set up a new project for X" with no PRD in hand, Grill runs first to produce a PRD, then KP-Setup reads the PRD frontmatter for inputs. If a PRD already exists at `wiki/projects/<slug>/plans/`, KP-Setup can run directly using its proposed_slug / proposed_path / proposed_stack fields.
- **KP-Setup vs KP-BugFix.** No overlap. Setup runs on new or empty folders; BugFix runs on existing failing code.

---

## Templates

In `templates/`:

- `project-CLAUDE.md` Thin router for the project root.
- `gitignore.txt` Standard ignores.
- `vault-overview.md` Vault overview page for a project.
- `vault-map.md` Vault project map page.
- `vault-context.md` Vault project context glossary.
- `vault-review.md` Vault project Definition of Done.
- `vault-status.md` Vault project session-state page.

All vault templates carry `updated:` frontmatter so the healthcheck freshness rule has something to read.

---

## Core principles

1. **Skinny by default.** This skill is structural plumbing, not a brain. Anything that resembles knowledge capture belongs to the vault.
2. **One source of truth per concept.** Code conventions in project `CLAUDE.md`. Everything else in the vault. Never duplicate.
3. **Approval before action.** Setup dry-runs on non-empty folders. Healthcheck never auto-applies fixes.
4. **Trace every edit.** Every change must trace to a command's defined steps. No drive-by edits.
5. **Honesty.** If a check was skipped or a path could not be verified, say so plainly. Do not claim "healthcheck passed" without running every check.
6. **Leave it clean.** If setup is cancelled mid-flow, remove any half-created folders or files. Healthcheck fixes that delete trash are part of the job, not a side effect. The project folder and the vault should look like only the requested operation happened.
7. **Rename hygiene (mandatory).** Any operation that renames or moves a vault page MUST, in the same run: grep the whole vault for the old slug, repoint every inbound `[[link]]` (full-path form for non-unique stems), then run `python "$env:USERPROFILE\.claude\skills\KP-WikiHealth\scripts\scan.py"` and confirm zero new broken links. A restructure that skips this tears the link graph (a past restructure that skipped this tore 400+ links).
