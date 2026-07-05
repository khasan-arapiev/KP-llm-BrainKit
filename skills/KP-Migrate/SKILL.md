---
name: KP-Migrate
description: >
  One-project-at-a-time migration of an existing code project into the
  KP+vault system. Scaffolds the project's vault folder at
  <vault>\wiki\projects\<slug>\, pre-fills pages from
  the project's existing docs and source layout, catalogs credentials and
  integrations BY REFERENCE ONLY (never copies secret values), backs up
  the existing project CLAUDE.md, rewrites it as a thin KP router, and
  ports any existing ADRs / post-mortems / learnings into the vault.
  Runs on ONE project per invocation. Trigger on: "KP-Migrate",
  "KP-migrate", "migrate this project", "migrate existing project",
  "wire this project to the brain", "onboard this project to the vault",
  "bring this project into the vault", "import existing project",
  "retrofit project to KP".
license: MIT
---

# KP-Migrate

Retrofits an existing code project into the KP+vault system. Run once per project. After migration, the project becomes indistinguishable from one scaffolded fresh by KP-Setup.

## When to use

- An existing project (any existing app or site) that has its own CLAUDE.md but no vault folder.
- A project that has scattered docs you want consolidated under the vault.
- Any project where the credentials catalog and integration map are not yet in the vault.

## When NOT to use

- New, empty folder. That is `KP-Setup`.
- Project already migrated (check for `<vault>\wiki\projects\<slug>\<slug>-overview.md`). Run `KP-Healthcheck` instead.
- You want to migrate everything in one go. This skill is one project per invocation by design.

## Inputs

Ask only what cannot be inferred:

- **Project slug** (kebab-case). Default: derive from folder name (e.g. `Acme Studio Tool` becomes `acme-studio-tool`). Confirm with the owner.
- **Confirmation that the cwd is the project root**, not a subfolder.
- **Path to the Security file** if auto-detection finds zero or multiple matches.

## Vault path

Resolve the vault root from `~/.claude/brainkit.json` (the `vaultPath` key). If that
file is missing, ask the owner where their Brain vault lives and offer to create the
config. Throughout this skill, `<vault>` means that resolved path.

## Security folder path

Credential files live under:

```
<vault>\security\
```

---

## The flow

### Step 1: Detect and confirm

- Confirm cwd is a project root. Look for: a `CLAUDE.md` at root, OR a recognised structure (`package.json`, `composer.json`, `requirements.txt`, framework configs).
- If no clear project root, stop and ask the owner to `cd` into the project first.
- Derive a kebab-case slug from the folder name. Show it to the owner. Wait for confirmation or override.
- **Client umbrella check.** If this project lives under a client folder with sibling sub-projects (e.g. `Clients\Acme Corp\` contains multiple deliverables), ask the owner whether this should be migrated as a standalone project or as a sub-project under a client umbrella. If umbrella, the vault path becomes `<vault>\wiki\projects\<client-slug>\<subproject-slug>\` and pages are named `<subproject-slug>-overview.md` etc. The umbrella's own overview lives at `<vault>\wiki\projects\<client-slug>\<client-slug>-overview.md` and links to every sub-project. Create the umbrella page if it does not exist yet.
- Check `<vault>\wiki\projects\<slug>\` (or the umbrella-nested path) does not already exist. If it does, stop. Tell the owner: "Project already migrated. Run `/KP-Healthcheck` instead."

### Step 2: Inventory existing docs

Read the project's existing documentation. Look for and capture content from:

- `CLAUDE.md` at root.
- `README.md` at root.
- `docs/` folder (any subfolder).
- `PROJECT-MAP.md`, `STATUS.md`, `CONTEXT.md`, `REVIEW.md` if present anywhere.
- `docs/decisions/`, `docs/adr/`, `docs/post-mortems/`, `docs/learnings/` if present.

Output a short inventory in chat: "Found X files of source documentation. Will migrate Y of them into the vault."

### Step 3: Detect framework and layering

Detect the project's layering convention by checking for:

- `next.config.*`, `vite.config.*`, `astro.config.*`, `nuxt.config.*`, `svelte.config.*`, `remix.config.*` (JS frameworks)
- `pyproject.toml`, `manage.py`, `app.py` (Python)
- `composer.json` (PHP)
- `src/`, `app/`, `lib/`, `pages/`, `bot/` (variant project folders)

Note the chosen variant. It goes into the vault `map.md`.

### Step 4: Credentials catalog (REFERENCE ONLY, NEVER VALUES)

This is the security-critical step. Read carefully.

1. Try to locate the Security file. Pattern attempts in order:
   - `Security\<slug>.json`
   - `Security\<slug-with-underscores>.json` (e.g. `gns_pdf_service.json`)
   - `Security\<slug>_service.json`
   - `Security\<first-word-of-slug>.json` (e.g. `acme.json` for `acme-site`)
2. If zero matches, ask the owner for the path. If multiple, list them and ask which.
3. If a file is found, **read it once, in memory, and extract ONLY the top-level JSON keys**. Do not log the file content. Do not echo values to chat. Do not write any value into any vault page.
4. For nested objects, extract second-level KEYS only (the field names), never values. Example: from `{"ghl": {"api_key": "x", "location_id": "y"}}` extract the labels `ghl` (with sub-fields `api_key`, `location_id`). The actual `"x"` and `"y"` values are never touched.
5. Output a list of integration labels in the vault's `overview.md` Credentials section, in the format defined in Step 6.
6. **If at any point a value looks like it might be a secret (long random string, password, key, token), do NOT include it anywhere.** Treat all values as secret.

### Step 5: Migrate existing ADRs / post-mortems / learnings

If the project has its own `docs/decisions/`, `docs/adr/`, `docs/post-mortems/`, or similar folders, copy each file into the equivalent vault folder:

- `docs/decisions/*.md` → `wiki/projects/<slug>/decisions/`
- `docs/adr/*.md` → `wiki/projects/<slug>/decisions/`
- `docs/post-mortems/*.md` → `wiki/projects/<slug>/post-mortems/`
- `docs/learnings/*.md` → `wiki/projects/<slug>/learnings/`

For each migrated file:
- Add or update the frontmatter to match the vault schema (`type`, `project`, `created`, `updated`).
- If `created` is unknown, use the file's git history first commit date, else today.

Report: "Migrated N ADRs, M post-mortems, K learnings."

### Step 6: Dry-run preview

Before writing anything, show the owner the full plan:

```
KP-Migrate plan for <slug>:

Will CREATE in vault:
  <vault>\wiki\projects\<slug>\<slug>-overview.md
  <vault>\wiki\projects\<slug>\core\map.md
  <vault>\wiki\projects\<slug>\core\context.md
  <vault>\wiki\projects\<slug>\core\review.md
  <vault>\wiki\projects\<slug>\core\status.md
  <vault>\wiki\projects\<slug>\core\strategy.md  (if strategy applies to this project)
  <vault>\wiki\projects\<slug>\plans\ (empty)
  <vault>\wiki\projects\<slug>\decisions\ (with N migrated ADRs)
  <vault>\wiki\projects\<slug>\post-mortems\ (with M migrated)
  <vault>\wiki\projects\<slug>\learnings\ (with K migrated)

Will MODIFY:
  <cwd>\CLAUDE.md
    -> backed up to CLAUDE.md.pre-migrate.bak
    -> rewritten as thin KP router

Will UPDATE in vault:
  <vault>\wiki\index.md (add under ## Projects)
  <vault>\wiki\log.md (migration entry)

Will REFERENCE in overview.md Credentials section:
  Security\<filename>.json
  Integration labels: ghl, meta, resend, hostinger, ...
  (Values stay in Security\, never copied)

Will NOT touch:
  Anything inside Security\
  Project source code (other than CLAUDE.md)
  Git history
  Remote repos

Proceed? (yes / dry-run only / cancel)
```

Wait for explicit confirmation. "yes" applies. "dry-run only" stops here. "cancel" stops here.

### Step 7: Apply

After "yes":

1. Create `<vault>\wiki\projects\<slug>\` and the sub-folders.
2. Write the project pages using KP-Setup's templates, pre-filled with extracted content.
   - `<slug>-overview.md` at the project folder root (entry point, keeps slug prefix). Includes the Credentials section (see template below).
   - `core/map.md`: entry points and modules from the source scan, plus local dev setup.
   - `core/context.md`: domain glossary from existing CONTEXT.md, else empty stub.
   - `core/status.md`: "First migration on <date>" plus current state from existing STATUS.md if any.
   - `core/review.md`: empty Definition of Done template, plus any project-specific rules from the old CLAUDE.md's DoD section.
   - `core/strategy.md`: only if the project has a strategy doc (e.g. STRATEGY.md). Skip if not applicable.
   - Every file inside `core/` must have `aliases: [<slug>-<type>, ...]` in frontmatter so cross-project wikilinks like `[[acme-app-map]]` still resolve.
3. Copy migrated ADRs / post-mortems / learnings into the right folders.
4. Backup existing project `CLAUDE.md` to `CLAUDE.md.pre-migrate.bak`.
5. Write the new thin router `CLAUDE.md` using KP-Setup's `project-CLAUDE.md` template, filled with `{{PROJECT_NAME}}`, `{{SLUG}}`, `{{STACK}}`.
6. Update `<vault>\wiki\index.md` under `## Projects`. Format: `- [[<slug>-overview]] <one-line purpose>.` Indent under a client umbrella entry if this is a sub-project.
7. Update `<vault>\wiki\credentials.md` (master credentials index) with the project's Security file mapping and integration labels.
8. Update `<vault>\wiki\log.md`: `## [YYYY-MM-DD] migrate | <slug>: scaffolded vault folder, ported N docs, wired credentials reference. Old CLAUDE.md backed up.`

### Step 8: Report

Tell the owner:

- Vault folder path.
- Number of pages created, ADRs/post-mortems/learnings ported.
- Path to the backup.
- The Credentials section as it was written (so they can verify it contains only labels, no values).
- Any anomalies (missing Security file, ambiguous CLAUDE.md content, untouchable source format) that need their attention.

---

## Credentials section template

This is the exact format for the Credentials block in `overview.md`. Use only integration LABELS, never values.

```markdown
## Credentials and integrations

Credentials live at:

`<vault>\security\<filename>.json`

Read that file directly when you need keys. Never copy values into the vault, never paste them into chat, never commit them.

### Integrations wired up

- **<label-1>** (fields: <subkey-1>, <subkey-2>, ...) — _(describe where in code this is used, if known from source scan)_
- **<label-2>** (fields: ...) — _(...)_
- **<label-3>** (fields: ...) — _(...)_

_The field list shows WHICH keys exist in the security file. Values are never reproduced here._
```

---

## What this skill NEVER does

- It never reads or copies VALUES from any file in `Security\`. Only top-level and second-level KEY names.
- It never echoes credential values to chat.
- It never writes any value from `Security\` into any vault page or any other file.
- It never modifies the contents of `Security\`.
- It never deletes the old project `CLAUDE.md`. It backs it up to `.pre-migrate.bak` instead.
- It never touches project source code (only the project's root `CLAUDE.md`).
- It never commits or pushes anything.
- It never auto-applies the plan. Step 6 dry-run + explicit "yes" gate is required.
- It never migrates more than one project per invocation.

## Failure modes and exit clauses

- **Project already migrated.** Stop, suggest `/KP-Healthcheck`.
- **No Security file found.** Continue, but flag this in the report. Write the Credentials section with: "No security file located at the standard paths. Add credentials to `Security\<slug>.json` and re-run this skill or update overview.md manually."
- **Cannot parse Security file as JSON.** Stop the credentials step, flag it, continue with the rest. Do not guess at the schema.
- **the owner says cancel or dry-run only.** Stop immediately. Delete any partial folder that was created.
- **Source folder is a git submodule.** Stop. Ask the owner whether to migrate the submodule itself or the parent.

## Trigger precedence

- **KP-Migrate vs KP-Setup.** If the project folder is empty or near-empty, that is KP-Setup territory. If it has existing code and docs, it is KP-Migrate territory. The skills should not both fire on the same project.
- **KP-Migrate vs KP-Healthcheck.** If `<vault>\wiki\projects\<slug>\` already exists, defer to KP-Healthcheck. KP-Migrate is for the first onboarding only.

## Core principles

1. **Reference, never copy.** Credentials live in `Security\`. The vault refers to them by path and lists labels only.
2. **Approval before action.** Dry-run plan + explicit "yes" before any file is written.
3. **Reversible.** The old `CLAUDE.md` is backed up, not deleted. Manual rollback is one rename away.
4. **One project per run.** Stops accidental bulk migration.
5. **Leave it clean.** If migration is cancelled mid-flow, delete any partial vault folder that was created.
6. **Honesty.** If a step had to be skipped (no Security file, unparseable JSON, ambiguous source format), report it plainly. Do not silently fudge.
7. **Rename hygiene (mandatory).** Any page the migration renames, moves, or ports MUST have every inbound `[[link]]` repointed in the same run (full-path form for non-unique stems): grep the vault for the old slug, rewrite, then run `python "$env:USERPROFILE\.claude\skills\KP-WikiHealth\scripts\scan.py"` and confirm zero new broken links. The 2026-06-10 health run repaired 426 links torn by a migration that skipped this.
