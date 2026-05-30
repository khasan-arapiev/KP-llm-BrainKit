# {{PROJECT_NAME}}

Project router. The agent reads this file first on every session.

This file is intentionally thin. Anything that is not "rules for editing this codebase" lives in the Obsidian Brain vault.

---

## Where to find what

| Topic | Location |
|---|---|
| What this project is, stack, status | `{{VAULT}}/wiki/projects/{{SLUG}}/{{SLUG}}-overview.md` |
| Module map, entry points, layering, local dev | `{{VAULT}}/wiki/projects/{{SLUG}}/core/map.md` |
| Domain glossary, vocabulary | `{{VAULT}}/wiki/projects/{{SLUG}}/core/context.md` |
| Definition of Done | `{{VAULT}}/wiki/projects/{{SLUG}}/core/review.md` |
| Last session, next up, blockers | `{{VAULT}}/wiki/projects/{{SLUG}}/core/status.md` |
| Strategy (if applicable) | `{{VAULT}}/wiki/projects/{{SLUG}}/core/strategy.md` |
| Plans / PRDs | `{{VAULT}}/wiki/projects/{{SLUG}}/plans/` |
| Decisions (ADRs) | `{{VAULT}}/wiki/projects/{{SLUG}}/decisions/` |
| Post-mortems | `{{VAULT}}/wiki/projects/{{SLUG}}/post-mortems/` |
| Captured learnings | `{{VAULT}}/wiki/projects/{{SLUG}}/learnings/` |
| Owner's working style, vault schema | `{{VAULT}}/CLAUDE.md` + linked pages |

## Skills available for this project

Slash commands and skills wired up for this codebase:

- `/KP-Setup` Scaffold project structure (folder + matching vault pages). Already run on this project.
- `/KP-Migrate` Retrofit an existing project into the vault system. Already run if this CLAUDE.md exists.
- `/KP-Healthcheck` Audit this project against the standard. Returns a score and a fix plan for approval.
- `/KP-Grill` Structured grilling session before any non-trivial work. One question per turn, files a PRD to `plans/` when done.
- `/KP-BugFix` Disciplined six-phase bug-fix loop. Files a post-mortem when done.

The skills auto-trigger on natural phrases too. Saying "this is broken" fires `KP-BugFix`. Saying "let's plan a new feature" fires `KP-Grill`. Slash commands are the explicit menu.

## Credentials

Credentials for this project live outside this repo, in a location you control (a
password manager, an env file outside git, or a secrets folder you never commit).
The vault overview lists which integrations are wired up (labels only, no values).
Read the secret directly when you need keys. Never paste values into the vault or
into chat, never commit them.

Read the vault pages relevant to the task before writing code.

---

## Code-side rules (this codebase only)

- Stack: {{STACK}}
- Entry point: see `map.md` in the vault.
- Workshop folder: `workshop/`. Scratch, experiments, drafts. Never deploy from here.
- Assets folder: `assets/`. Images, fonts, raw materials.

Code hygiene (always apply):
- No dead code. No commented-out blocks larger than 5 lines.
- No junk comments. Comments explain what something is and why, for the next reader. No "added by Claude", "as requested", "removed feature X".
- No drive-by refactors. Every changed line traces to the user's request.
- Match existing style, even if you would do it differently.

Workflow:
- Non-trivial work starts in Plan Mode. Approve the plan before code changes.
- "Deploy" means whatever this project's deploy script or process defines. Record it in `map.md` so it does not need re-explaining each time.
- Skip git commits unless the owner asks.

---

## Sensitive files

Secrets live outside this project, never in the repo. Never commit secrets.

---

## When something belongs in the vault

If you learn something worth keeping (a decision, a post-mortem, a learning), do not file it here. File it in the matching vault folder under `{{VAULT}}/wiki/projects/{{SLUG}}/`. This file stays thin.
