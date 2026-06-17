# KP-llm-BrainKit

A Claude + Obsidian second-brain starter kit. It gives you a persistent, compounding
knowledge vault and a set of disciplined skills that make Claude plan, build, debug,
and file knowledge the same way every session, instead of re-deriving everything from
scratch each time.

It ships **empty**. You bring your own projects and notes. Nothing in here belongs to
anyone else.

Based on Andrej Karpathy's LLM-wiki pattern (gist `442a6bf555914893e9891c11519de94f`).

## What you get

- **A blank Obsidian vault** with a battle-tested schema: an `index`, an append-only
  `log`, and folders for sources, entities, concepts, syntheses, lessons, and projects.
  The `CLAUDE.md` inside it is the operating manual Claude reads first every session.
- **Nine skills** that auto-trigger on natural phrases:
  - `KP-Grill` — grills your idea with one sharp question at a time, files a PRD.
  - `KP-Setup` — scaffolds a new project (folder + matching vault pages) and audits existing ones.
  - `KP-Migrate` — retrofits an existing code project into the system (credentials by reference only, never copied).
  - `KP-BugFix` — a disciplined six-phase debugging loop that files a post-mortem.
  - `KP-WikiHealth` — full-vault health scan: dead links, orphans, stale pages, duplicates.
  - `code-cowork` — pair-programming build mode: plan, architect, build to a high standard with TDD.
  - `wrap-up` — end-of-session sweep: review, lint the vault, update the index and log.
  - `handoff` — compact a conversation into a doc the next session can pick up.
  - `signoff` — one-command session close: writes a handoff, runs wrap-up, then prints a copy-paste prompt to continue in a fresh chat.
- **The matching slash-commands** (`/KP-Setup`, `/KP-Grill`, `/KP-Healthcheck`,
  `/KP-Migrate`, `/KP-BugFix`, `/KP-WikiHealth`, `/code-cowork`). `wrap-up`, `handoff`,
  and `signoff` trigger on natural phrases ("wrap up", "sign off") rather than a slash-command.
- An **installer** that pulls three official Anthropic plugins so your Claude has the
  same mindset and web-design ability: `superpowers` (brainstorming, TDD, debugging,
  verification), `frontend-design` (production-grade web/UX/UI), and `playground`
  (interactive tools).

## Prerequisites

- [Claude Code](https://claude.com/claude-code)
- [Obsidian](https://obsidian.md) (free)
- `git`

## Quickstart

1. **Install Obsidian** (you do not open a vault yet — the installer creates one).
2. **Get the kit.** Clone it, or just give Claude Code the link to this repo:
   ```
   git clone https://github.com/<your-username>/KP-llm-BrainKit.git
   ```
3. **Tell Claude `install this`** from inside the repo. The `install` skill asks your
   name and where to put your Brain folder, copies the skills, scaffolds the vault,
   and gives you three plugin commands to paste in.

Prefer to do it by hand? See [INSTALL.md](INSTALL.md).

After install: open the Brain folder in Obsidian, read its `CLAUDE.md` once, then say
`KP setup` to scaffold your first project — or drop a file in `raw/` and say `ingest`.

## What this is NOT

- It is **not** a copy of anyone's vault. It is a clean template; your content starts empty.
- It does **not** include any business data, credentials, or personal notes.
- It does **not** wire up any paid review tools. The skills run on Claude Code alone.

## License

No license yet. Until one is added, treat this as "all rights reserved" for
redistribution; you are welcome to use it for your own setup.
