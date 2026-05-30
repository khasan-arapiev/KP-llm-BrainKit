# KP-llm-BrainKit — Design Spec

Date: 2026-05-30
Owner: Khasan Arapiev
Status: awaiting review

## Goal

Ship a public, installable starter kit that gives a new user a Claude + Obsidian
"second brain" identical in behavior to Khasan's, with zero of his content. The
recipient gets the same mindset, rules, auto-evoking skills, wiki schema, and a
blank vault to shape to their own projects.

Hard rule: nothing private ships. No names, paths, credentials, business
references, or backup repos. The repo is public and permanent — treat every file
as world-readable forever.

## Non-goals

- Not shipping Khasan's actual vault content (projects, sources, lessons, credentials).
- Not redistributing Anthropic's official plugins (superpowers, frontend-design,
  playground). The installer pulls those from the marketplace instead.
- Not authoring a motion-graphics skill (none exists; out of scope unless requested later).
- No Greptile anywhere in the recipient's kit.

## Decisions (locked)

| Decision | Choice |
| --- | --- |
| Personalization | Runtime auto-detect via `~/.claude/brainkit.json` |
| Install method | Bundled `install` skill, Claude-driven |
| Repo | `KP-llm-BrainKit`, Khasan's GitHub, public, no license yet |
| Design skills | Installer pulls official `frontend-design` + `playground` from marketplace |
| Mindset plugin | Installer also pulls official `superpowers` from marketplace |
| Greptile | Removed entirely from `code-cowork` and `wrap-up` |
| Motion graphics | Skipped (does not exist) |

## Repo layout

```
KP-llm-BrainKit/
├─ README.md            what it is, 3-step quickstart
├─ INSTALL.md           detailed steps, Claude- or human-followable
├─ skills/
│   ├─ KP-Setup/        (+ templates/)
│   ├─ KP-Grill/        (+ templates/)
│   ├─ KP-Migrate/
│   ├─ KP-BugFix/
│   ├─ KP-WikiHealth/
│   ├─ code-cowork/     (Greptile removed)
│   ├─ handoff/
│   ├─ wrap-up/         (Greptile removed)
│   └─ install/         NEW installer skill
├─ commands/            KP-*.md slash-commands, sanitized
└─ vault-template/
    ├─ CLAUDE.md        generic schema + mindset/rules, no business specifics
    ├─ wiki/
    │   ├─ index.md     empty catalog (group headers only)
    │   ├─ log.md       single seed entry written at install
    │   ├─ concepts/    .gitkeep
    │   ├─ entities/    .gitkeep
    │   ├─ sources/     .gitkeep
    │   ├─ synthesis/   .gitkeep
    │   ├─ lessons/     .gitkeep
    │   ├─ projects/    .gitkeep
    │   └─ skills/      .gitkeep
    ├─ raw/assets/      .gitkeep
    ├─ production/      .gitkeep
    └─ .obsidian/       minimal app.json incl. production/ ignore filter
```

## Personalization mechanism

The installer writes `~/.claude/brainkit.json`:

```json
{ "owner": "<recipient name>", "vaultPath": "<absolute path to their Brain>" }
```

Every sanitized skill resolves the vault root by reading `vaultPath` from that file
as its first step. If the file is missing, the skill asks the user once and offers
to create it. This replaces all 79 hardcoded `C:\Users\cex\Desktop\Brain` /
`Khasan` / `khasan-arapiev` references. Cross-platform (Mac/Windows). Surviving a
moved folder = re-run the install path step.

CLAUDE.md owner name is written once at install time (simple string substitution),
since CLAUDE.md is read directly, not via a skill step.

## Install skill behavior

When the recipient gives Claude the repo link and says "install this", the
`install` skill:

1. Asks recipient name + Brain folder location (default `~/Desktop/Brain`). Confirms.
2. Installs official marketplace plugins: `superpowers`, `frontend-design`,
   `playground`. (Exact CLI verified against Claude Code docs at build time, not guessed.)
3. Copies `skills/*` → `~/.claude/skills/`, `commands/*` → `~/.claude/commands/`.
4. Scaffolds `vault-template/` → chosen location. Seeds `log.md` with a setup entry,
   substitutes owner name into `CLAUDE.md`.
5. Writes `~/.claude/brainkit.json`.
6. Prints a getting-started nudge (first ingest, first project via KP-Setup).

INSTALL.md documents the same steps for manual execution as a fallback.

## Sanitization rules (applied to every shipped file)

Strip or replace:
- Paths: `C:\Users\cex\...`, any absolute Khasan path → runtime-resolved vault root.
- Identity: `Khasan`, `Khasan Arapiev`, `khasan-arapiev`, `arapievsocial@gmail.com`
  → generic "the owner" / resolved-from-config.
- Business references: artusflow, zexora, glide-and-slide, gns, tripstash, mail-guard,
  markus-bot, hyperline, coolify, and any other project-specific names.
- Backup-skill references (backup-brain, backup-zexora, backup-claude) → removed.
- Greptile / greploop references in code-cowork and wrap-up → removed.

Keep (this is the value):
- "Never guess, find out", "be critical", "honesty over comfort", the discipline rules.
- House style (no em/en dashes, plain English, lead with the claim).
- Wiki schema: frontmatter shape, type values, folder layout, log/index formats.
- Skill auto-evoking trigger phrases.

Verification: after sanitizing, grep the entire repo for the strip-list terms.
Zero hits required before push.

## code-cowork and wrap-up after Greptile removal

- code-cowork: plan (KP-Grill or brainstorming) → architecture pass against existing
  ADRs/patterns → TDD build in house style. Ends there. No final review pass.
- wrap-up: architecture review of touched projects → vault lint → fix broken links →
  update index.md + log.md → closing message. The "Greptile loop until 5/5" stage is gone.

## Build, not push

The kit is built locally at `C:\Users\cex\Desktop\KP-llm-BrainKit\` and shown to
Khasan first. The public repo is created and pushed only on explicit go. GitHub
username confirmed at push time (likely `khasan-arapiev`).

## Success criteria

1. Repo grep for every strip-list term returns zero hits.
2. All 8 skills + install skill present with valid frontmatter.
3. vault-template opens cleanly in Obsidian; production/ is ignored.
4. A dry run of the install skill's steps produces a working `~/.claude` + Brain
   folder on a clean profile (validated by reading the steps, since we will not
   wipe Khasan's real config to test).
5. README + INSTALL readable by a non-technical recipient.
