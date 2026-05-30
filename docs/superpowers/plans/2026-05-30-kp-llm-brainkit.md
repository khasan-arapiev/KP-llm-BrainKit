# KP-llm-BrainKit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a public, installable Claude + Obsidian second-brain starter kit that reproduces Khasan's mindset, skills, and wiki schema with zero of his private content.

**Architecture:** Sanitize 8 existing skills + KP commands by stripping all identity/path/business references and replacing hardcoded paths with a runtime config lookup (`~/.claude/brainkit.json`). Ship a blank vault template and a Claude-driven `install` skill that pulls official plugins (superpowers, frontend-design, playground), copies skills, and scaffolds the vault. Verification is a grep gate: zero leaked terms across shippable files.

**Tech Stack:** Markdown (skills, commands, vault), JSON (config), git/gh CLI. No build system. ripgrep for the verification gate.

**Source of truth for originals:**
- Skills: `~/.claude/skills/<name>/` (KP-Setup, KP-Grill, KP-Migrate, KP-BugFix, KP-WikiHealth, code-cowork, handoff, wrap-up)
- Commands: `~/.claude/commands/*.md`
- Vault CLAUDE.md + structure: `c:\Users\cex\Desktop\Brain\`

**Build location:** `c:\Users\cex\Desktop\KP-llm-BrainKit\` (git already initialized; spec committed).

---

## The Strip List (the spec for every sanitize task)

Replace or remove every occurrence (case-insensitive) of:

| Term | Action |
| --- | --- |
| `C:\Users\cex\Desktop\Brain` and any absolute path | → "the vault root (resolved from `~/.claude/brainkit.json` → `vaultPath`)" |
| `cex` (in paths) | → resolved path, no username |
| `Khasan`, `Khasan Arapiev` | → "the owner" (or owner name from config where a name is needed) |
| `khasan-arapiev` | remove (it is a GitHub handle) |
| `arapievsocial@gmail.com` | remove |
| `artusflow`, `zexora`, `glide-and-slide`, `gns`, `tripstash`, `mail-guard`, `markus-bot` | remove / replace with generic `<project-slug>` example |
| `hyperline`, `coolify` | remove (business infra) |
| `greptile`, `greploop`, `@greptile` | remove (see Tasks 9, 10) |
| `backup-brain`, `backup-zexora`, `backup-claude` | remove all references |

**Keep (this is the product's value):** the discipline rules ("never guess, find out", "be critical", "honesty over comfort"), house style (no em/en dashes, plain English, lead with the claim), the wiki schema (frontmatter, type values, folder layout, log/index formats), and every skill's auto-evoking trigger phrases.

**The grep gate** (run from `c:\Users\cex\Desktop\KP-llm-BrainKit\`, over shippable files only):

```bash
rg -i -n "cex|khasan|arapiev|artusflow|zexora|glide-and-slide|tripstash|mail-guard|markus-bot|hyperline|coolify|greptile|greploop|backup-(brain|zexora|claude)" \
  README.md INSTALL.md skills/ commands/ vault-template/
```
Expected after each task: **no matches** in the files that task produced.

---

## File Structure

| File | Responsibility |
| --- | --- |
| `README.md` | What the kit is, 3-step quickstart, what gets installed |
| `INSTALL.md` | Full manual install steps (fallback to the install skill) |
| `SANITIZE-CHECK.md` (local only, gitignored) | The grep gate command + strip list, for re-running |
| `skills/<name>/SKILL.md` | One sanitized skill each |
| `skills/install/SKILL.md` | The installer skill |
| `commands/*.md` | Sanitized KP slash-commands |
| `vault-template/CLAUDE.md` | Generic vault schema + mindset |
| `vault-template/wiki/index.md`, `log.md` | Empty catalog + seed log |
| `vault-template/.obsidian/app.json` | Minimal Obsidian config w/ production ignore filter |
| `.gitignore` | Excludes `docs/` (planning artifacts that name Khasan) |

---

## Task 1: Protect the planning docs from going public

**Files:**
- Create: `.gitignore`

- [ ] **Step 1: Write `.gitignore`**

```
# Planning artifacts name the author and his businesses — never publish.
docs/
SANITIZE-CHECK.md
.DS_Store
```

- [ ] **Step 2: Verify git no longer tracks docs for the public set**

Run: `cd "c:\Users\cex\Desktop\KP-llm-BrainKit" && git rm -r --cached docs >/dev/null 2>&1; git status --porcelain`
Expected: `docs/` no longer staged; `.gitignore` shown as new.

- [ ] **Step 3: Commit**

```bash
git add .gitignore && git commit -m "chore: gitignore planning docs (contain author identity)"
```

---

## Task 2: Vault template — CLAUDE.md

The vault CLAUDE.md is the heart of "her Claude is as smart as mine". Start from `c:\Users\cex\Desktop\Brain\CLAUDE.md` and sanitize.

**Files:**
- Create: `vault-template/CLAUDE.md`

- [ ] **Step 1: Read the original**

Run: read `c:\Users\cex\Desktop\Brain\CLAUDE.md` in full.

- [ ] **Step 2: Write the sanitized version**

Apply the strip list. Specifically:
- Replace the title owner line "Owner: Khasan Arapiev." → "Owner: {{set at install}}." (the install skill substitutes the name).
- Replace every `C:\Users\cex\Desktop\Brain\...` path with a relative vault path (e.g. `wiki/projects/<slug>/`) or "the vault root".
- Remove the line referencing the "Business CLAUDE.md" (house style cross-ref to his business vault) — keep the house-style rules themselves, drop the cross-reference.
- Keep verbatim: Purpose, Architecture (folders), Conventions, "How the agent should think and work" (all 6 rules), Discipline (A–D), Operations (Ingest/Query/Lint), Log format, Index format, Tooling notes, Open knobs.
- In "Open knobs", remove any answered-knob notes that reference his specific choices if business-specific; keep generic ones.

- [ ] **Step 3: Grep gate**

Run the grep gate over `vault-template/CLAUDE.md`.
Expected: no matches (the only allowed token is the literal `{{set at install}}` placeholder).

- [ ] **Step 4: Commit**

```bash
git add vault-template/CLAUDE.md && git commit -m "feat: sanitized vault CLAUDE.md"
```

---

## Task 3: Vault template — wiki scaffold + Obsidian config

**Files:**
- Create: `vault-template/wiki/index.md`
- Create: `vault-template/wiki/log.md`
- Create: `vault-template/wiki/{concepts,entities,sources,synthesis,lessons,projects,skills}/.gitkeep`
- Create: `vault-template/raw/assets/.gitkeep`
- Create: `vault-template/production/.gitkeep`
- Create: `vault-template/.obsidian/app.json`

- [ ] **Step 1: Write `index.md`** (empty catalog, group headers only)

```markdown
---
title: Index
type: log
tags: [index]
created: 2026-05-30
updated: 2026-05-30
sources: 0
---

# Index

The catalog of every wiki page. One line per page under its group.

## Sources

## Entities

## Concepts

## Syntheses

## Comparisons

## Projects
```

- [ ] **Step 2: Write `log.md`** (header only; install seeds the first real entry)

```markdown
---
title: Log
type: log
tags: [log]
created: 2026-05-30
updated: 2026-05-30
---

# Log

Append-only record of ingests, queries, and lint passes. Format:
`## [YYYY-MM-DD] <op> | <one-line summary>` where `<op>` is ingest | query | lint | setup | note.
```

- [ ] **Step 3: Create the `.gitkeep` files** for every empty folder listed above.

- [ ] **Step 4: Write `.obsidian/app.json`** (minimal, keeps `production/` out of search/graph)

```json
{
  "userIgnoreFilters": [
    "production/"
  ],
  "alwaysUpdateLinks": true,
  "newLinkFormat": "shortest"
}
```

- [ ] **Step 5: Verify structure**

Run: `cd "c:\Users\cex\Desktop\KP-llm-BrainKit" && find vault-template -type f | sort`
Expected: CLAUDE.md, wiki/index.md, wiki/log.md, seven `.gitkeep` under wiki/, raw/assets/.gitkeep, production/.gitkeep, .obsidian/app.json.

- [ ] **Step 6: Commit**

```bash
git add vault-template && git commit -m "feat: blank vault scaffold + obsidian config"
```

---

## Task 4: Sanitize KP-Setup (+ templates)

Highest path-reference count alongside KP-Grill. Has a `templates/` dir.

**Files:**
- Create: `skills/KP-Setup/SKILL.md`
- Create: `skills/KP-Setup/templates/*` (mirror originals, sanitized)

- [ ] **Step 1: Read originals**

Read `~/.claude/skills/KP-Setup/SKILL.md` and every file in `~/.claude/skills/KP-Setup/templates/`.

- [ ] **Step 2: Write sanitized SKILL.md**

Apply the strip list. Key transforms:
- Every `C:\Users\cex\Desktop\Brain` → "the vault root, resolved from `~/.claude/brainkit.json` (`vaultPath`)". Add, near the top of the skill's procedure, a first step: "Resolve the vault root: read `~/.claude/brainkit.json` and use its `vaultPath`. If the file is missing, ask the user for their vault location and offer to create the config."
- Remove business project examples; where an example slug is needed use `<slug>` or `example-project`.
- Keep the two-command contract (`KP setup`, `KP healthcheck`) and all logic.

- [ ] **Step 3: Write sanitized templates** (same strip list; replace owner/paths/business names).

- [ ] **Step 4: Grep gate** over `skills/KP-Setup/`. Expected: no matches.

- [ ] **Step 5: Frontmatter check**

Run: `cd "c:\Users\cex\Desktop\KP-llm-BrainKit" && head -5 skills/KP-Setup/SKILL.md`
Expected: valid YAML frontmatter with `name:` and `description:` preserved from original.

- [ ] **Step 6: Commit**

```bash
git add skills/KP-Setup && git commit -m "feat: sanitized KP-Setup skill"
```

---

## Task 5: Sanitize KP-Grill (+ templates)

Highest reference count (24). Outputs a PRD to the vault; references the vault path heavily.

**Files:**
- Create: `skills/KP-Grill/SKILL.md`
- Create: `skills/KP-Grill/templates/*`

- [ ] **Step 1: Read** `~/.claude/skills/KP-Grill/SKILL.md` and `~/.claude/skills/KP-Grill/templates/`.
- [ ] **Step 2: Write sanitized SKILL.md** — same vault-resolution first step as Task 4; strip all 24 references; keep the one-question-per-turn / cap-10 / PRD-output logic and triggers.
- [ ] **Step 3: Write sanitized templates.**
- [ ] **Step 4: Grep gate** over `skills/KP-Grill/`. Expected: no matches.
- [ ] **Step 5: Frontmatter check** (`head -5`). Expected: valid frontmatter.
- [ ] **Step 6: Commit** `git add skills/KP-Grill && git commit -m "feat: sanitized KP-Grill skill"`

---

## Task 6: Sanitize KP-WikiHealth

**Files:** Create `skills/KP-WikiHealth/SKILL.md`

- [ ] **Step 1: Read** `~/.claude/skills/KP-WikiHealth/SKILL.md` (13 references).
- [ ] **Step 2: Write sanitized SKILL.md** — vault-resolution first step; strip references; keep the full-vault scan logic, mechanical checks, auto-fix vs ask-first split, and triggers.
- [ ] **Step 3: Grep gate** over `skills/KP-WikiHealth/`. Expected: no matches.
- [ ] **Step 4: Frontmatter check.**
- [ ] **Step 5: Commit** `git add skills/KP-WikiHealth && git commit -m "feat: sanitized KP-WikiHealth skill"`

---

## Task 7: Sanitize KP-Migrate

**Files:** Create `skills/KP-Migrate/SKILL.md`

- [ ] **Step 1: Read** `~/.claude/skills/KP-Migrate/SKILL.md` (10 references).
- [ ] **Step 2: Write sanitized SKILL.md** — vault-resolution first step; strip references; keep the one-project-per-run logic, the "catalog credentials BY REFERENCE ONLY, never copy secret values" rule (important and generic), and triggers.
- [ ] **Step 3: Grep gate.** Expected: no matches.
- [ ] **Step 4: Frontmatter check.**
- [ ] **Step 5: Commit** `git add skills/KP-Migrate && git commit -m "feat: sanitized KP-Migrate skill"`

---

## Task 8: Sanitize KP-BugFix

**Files:** Create `skills/KP-BugFix/SKILL.md`

- [ ] **Step 1: Read** `~/.claude/skills/KP-BugFix/SKILL.md` (3 references).
- [ ] **Step 2: Write sanitized SKILL.md** — vault-resolution first step for the post-mortem path; strip references; keep the six-phase loop and triggers.
- [ ] **Step 3: Grep gate.** Expected: no matches.
- [ ] **Step 4: Frontmatter check.**
- [ ] **Step 5: Commit** `git add skills/KP-BugFix && git commit -m "feat: sanitized KP-BugFix skill"`

---

## Task 9: Sanitize code-cowork (remove Greptile)

**Files:** Create `skills/code-cowork/SKILL.md`

- [ ] **Step 1: Read** `~/.claude/skills/code-cowork/SKILL.md` (11 references).
- [ ] **Step 2: Write sanitized SKILL.md.** Transforms:
  - Strip all paths/identity/business references.
  - **Remove the Greptile pass entirely.** The skill becomes: plan non-trivial work (KP-Grill or brainstorming) → architecture pass against existing ADRs/patterns → TDD build in house style. Delete the "runs ONE Greptile pass at the end" sentence from both the description and the body. Update the description frontmatter so it no longer mentions Greptile.
  - Keep: house-style discipline, "does NOT lint the vault" boundary, triggers.
- [ ] **Step 3: Grep gate** (must catch `greptile`/`greploop`). Expected: no matches.
- [ ] **Step 4: Frontmatter check.**
- [ ] **Step 5: Commit** `git add skills/code-cowork && git commit -m "feat: sanitized code-cowork skill (greptile removed)"`

---

## Task 10: Sanitize wrap-up (remove Greptile)

**Files:** Create `skills/wrap-up/SKILL.md`

- [ ] **Step 1: Read** `~/.claude/skills/wrap-up/SKILL.md`.
- [ ] **Step 2: Write sanitized SKILL.md.** Transforms:
  - Strip all paths/identity/business references.
  - **Remove the "Greptile review loop until 5/5" stage entirely.** The pipeline becomes: architecture review of touched projects → vault lint → fix broken links → update index.md + log.md → closing message. Update the frontmatter description to drop Greptile.
  - Vault-resolution first step for the lint/index/log paths.
  - Keep: triggers, the "every code project touched" scoping.
- [ ] **Step 3: Grep gate.** Expected: no matches.
- [ ] **Step 4: Frontmatter check.**
- [ ] **Step 5: Commit** `git add skills/wrap-up && git commit -m "feat: sanitized wrap-up skill (greptile removed)"`

---

## Task 11: Sanitize handoff

**Files:** Create `skills/handoff/SKILL.md`

- [ ] **Step 1: Read** `~/.claude/skills/handoff/SKILL.md` (1 reference).
- [ ] **Step 2: Write sanitized SKILL.md** — strip the single reference; keep the compaction/handoff logic and triggers. If it writes handoff files to a path, resolve via vault config or a relative `handoffs/` folder.
- [ ] **Step 3: Grep gate.** Expected: no matches.
- [ ] **Step 4: Frontmatter check.**
- [ ] **Step 5: Commit** `git add skills/handoff && git commit -m "feat: sanitized handoff skill"`

---

## Task 12: Sanitize KP commands

**Files:** Create `commands/KP-Setup.md`, `KP-Grill.md`, `KP-Healthcheck.md`, `KP-Migrate.md`, `KP-BugFix.md`, `KP-WikiHealth.md`, `code-cowork.md`

- [ ] **Step 1: Read** all 7 files in `~/.claude/commands/`.
- [ ] **Step 2: Write sanitized copies** — apply the strip list to each. These are thin command wrappers; mostly path/identity strips.
- [ ] **Step 3: Grep gate** over `commands/`. Expected: no matches.
- [ ] **Step 4: Commit** `git add commands && git commit -m "feat: sanitized KP slash-commands"`

---

## Task 13: Author the install skill

This is new code, not a sanitization. It is the recipient's entry point.

**Files:** Create `skills/install/SKILL.md`

- [ ] **Step 1: Verify the plugin-install CLI** before writing the skill.

Dispatch the `claude-code-guide` agent (or check docs) with: "What is the exact command to install a plugin from the official marketplace (claude-plugins-official) non-interactively from within Claude Code or via the `claude` CLI? I need to install `superpowers`, `frontend-design`, and `playground`." Record the exact command(s). Do not guess the syntax.

- [ ] **Step 2: Write `skills/install/SKILL.md`** with this procedure:

```markdown
---
name: install
description: Set up the KP-llm-BrainKit on this machine. Installs the mindset and design plugins, copies the skills and commands, scaffolds a blank Brain vault, and writes the config. Trigger on "install this", "install brainkit", "set up the brain kit", or after cloning KP-llm-BrainKit.
---

# Install KP-llm-BrainKit

Run these steps in order. Confirm with the user before writing outside the repo.

1. Ask the user two things: their name (the vault owner) and where to put their
   Brain vault (default: `~/Desktop/Brain`). Confirm both.
2. Install the official plugins (mindset + design):
   <exact commands recorded in Step 1, for superpowers, frontend-design, playground>
   If a plugin is already installed, skip it.
3. Copy this repo's `skills/*` into the Claude skills dir (`~/.claude/skills/`) and
   `commands/*` into `~/.claude/commands/`. Do not overwrite an existing skill of the
   same name without asking.
4. Copy `vault-template/` to the chosen Brain location. In the copied `CLAUDE.md`,
   replace `{{set at install}}` with the user's name.
5. Append a seed entry to the vault `wiki/log.md`:
   `## [<today>] setup | Brain vault created from KP-llm-BrainKit.`
6. Write `~/.claude/brainkit.json`:
   `{ "owner": "<name>", "vaultPath": "<absolute path to the Brain folder>" }`
7. Tell the user it is done and suggest first moves: open the folder in Obsidian,
   then say "KP setup" to scaffold their first project, or drop a file in `raw/`
   and say "ingest".
```

(Replace the `<exact commands...>` placeholder with the real commands from Step 1 before saving.)

- [ ] **Step 3: Grep gate** over `skills/install/`. Expected: no matches.
- [ ] **Step 4: Frontmatter check.**
- [ ] **Step 5: Commit** `git add skills/install && git commit -m "feat: install skill"`

---

## Task 14: README and INSTALL

**Files:** Create `README.md`, `INSTALL.md`

- [ ] **Step 1: Write `README.md`**

Sections: one-line pitch; "What you get" (8 KP skills + mindset via superpowers + web design via frontend-design/playground + a blank Obsidian second-brain); Prerequisites (Claude Code, Obsidian, git); 3-step Quickstart ("1. Install Obsidian. 2. Clone this repo or give Claude the link. 3. Tell Claude `install this`."); a "What this is NOT" note (no author content, fully fresh); credit to the Karpathy LLM-wiki pattern; "no license yet" line.

- [ ] **Step 2: Write `INSTALL.md`** — the manual fallback: the same 7 steps the install skill performs, written for a human, including the exact plugin-install commands from Task 13 Step 1 and the `brainkit.json` shape.

- [ ] **Step 3: Grep gate** over `README.md INSTALL.md`. Expected: no matches.

- [ ] **Step 4: Commit** `git add README.md INSTALL.md && git commit -m "docs: README and INSTALL"`

---

## Task 15: Full verification gate

**Files:** none (verification only)

- [ ] **Step 1: Global grep gate** over all shippable files.

Run:
```bash
cd "c:\Users\cex\Desktop\KP-llm-BrainKit" && rg -i -n "cex|khasan|arapiev|artusflow|zexora|glide-and-slide|tripstash|mail-guard|markus-bot|hyperline|coolify|greptile|greploop|backup-(brain|zexora|claude)" README.md INSTALL.md skills/ commands/ vault-template/
```
Expected: **zero matches**. If any hit, fix the offending file and re-run before proceeding.

- [ ] **Step 2: Confirm docs/ is not tracked for publish**

Run: `git ls-files | rg "^docs/"`
Expected: zero matches (gitignored).

- [ ] **Step 3: Frontmatter sweep** — every `skills/*/SKILL.md` has `name:` and `description:`.

Run: `for f in skills/*/SKILL.md; do echo "== $f =="; head -4 "$f"; done`
Expected: valid frontmatter for all 9 skills (8 sanitized + install).

- [ ] **Step 4: Structure sweep**

Run: `find . -type f -not -path './.git/*' -not -path './docs/*' | sort`
Expected: matches the File Structure table — README, INSTALL, .gitignore, 9 skills, 7 commands, full vault-template tree.

- [ ] **Step 5: Report to Khasan** — list everything built, the zero-leak confirmation, and ask for go on creating + pushing the public repo. Do not push yet.

---

## Task 16: Publish (only on Khasan's explicit go)

**Files:** none (outward-facing)

- [ ] **Step 1: Confirm GitHub username** (likely `khasan-arapiev`) and that the repo should be public.
- [ ] **Step 2: Create the public repo**

Run: `gh repo create KP-llm-BrainKit --public --source . --remote origin --description "A Claude + Obsidian second-brain starter kit"`

- [ ] **Step 3: Push** `git push -u origin main`
- [ ] **Step 4: Verify** the remote does not contain `docs/`: `gh api repos/<user>/KP-llm-BrainKit/contents | rg docs || echo "docs absent — good"`
- [ ] **Step 5: Report** the public URL to Khasan.

---

## Self-Review

**Spec coverage:** Repo layout → Tasks 1-14. Personalization (`brainkit.json`) → vault-resolution step in every skill task + Task 13 Step 6. Install skill → Task 13. Sanitization rules → strip list + grep gate in every task + Task 15. Greptile removal → Tasks 9, 10. Build-locally-then-push → Tasks 15, 16. Success criteria 1-5 → Task 15 steps. Covered.

**Placeholder scan:** The only intentional placeholders are `{{set at install}}` in CLAUDE.md (resolved by the install skill) and `<exact commands...>` in Task 13 (resolved by Step 1 before the skill is saved). Both have explicit resolution steps. No unresolved TBDs.

**Type consistency:** Config file is `~/.claude/brainkit.json` with keys `owner` and `vaultPath` everywhere (Tasks 2, 4-11, 13). Grep gate command identical in the strip-list section and Task 15. Skill count = 9 (8 + install) consistent in Tasks 13, 15.

**Note on TDD:** This is content sanitization, so the "test" is the grep gate + frontmatter/structure checks rather than unit tests. That is the correct verification for this work; there is no application logic to unit-test.
