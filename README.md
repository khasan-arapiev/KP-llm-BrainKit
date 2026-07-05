# KP-llm-BrainKit

A Claude + Obsidian second-brain starter kit. It gives you a persistent, compounding
knowledge vault and a set of disciplined skills that make Claude plan, build, debug,
orchestrate, and file knowledge the same way every session, instead of re-deriving
everything from scratch each time.

It ships **empty**. You bring your own projects and notes. Nothing in here belongs to
anyone else.

Based on Andrej Karpathy's LLM-wiki pattern (gist `442a6bf555914893e9891c11519de94f`).

## What you get

- **A blank Obsidian vault** with a battle-tested schema: an `index`, an append-only
  `log` (with size-based rotation to `log-archive/`), and folders for sources,
  entities, concepts, syntheses, lessons, and projects. The `CLAUDE.md` inside it is
  the operating manual Claude reads first every session: session boot rules, a skill
  routing table, linking hygiene, recency/confidence conventions, and the four
  discipline rules that keep the vault lean.

- **Twelve skills** that auto-trigger on natural phrases:
  - `KP-Grill` — grills your idea with one sharp question at a time, files a PRD.
  - `KP-Setup` — scaffolds a new project (folder + matching vault pages) and audits existing ones.
  - `KP-Migrate` — retrofits an existing code project into the system (credentials by reference only, never copied).
  - `KP-BugFix` — a disciplined six-phase debugging loop that files a post-mortem.
  - `KP-WikiHealth` — full-vault health scan with a mechanical Python scanner: dead links, orphans, stale pages, duplicates, index drift.
  - `KP-God` — the orchestrator: turns a chat into a thin conductor running several parallel workstreams, each as a **real Claude Code session in its own WezTerm tab** with an isolated git worktree, steered across chunks and fix rounds, with a zero-token watcher and a per-project board file as its memory. Windows-native fleet; see prerequisites below.
  - `code-cowork` — pair-programming build mode: plan, architect against existing ADRs, trace the runtime read path for config changes, build with TDD, then two end gates (a deterministic `fallow` audit and an adversarial semantic self-review).
  - `check-pr` — review a GitHub/GitLab PR against the plan and the codebase.
  - `improve-codebase-architecture` — find consolidation and refactoring opportunities, report-only.
  - `wrap-up` — end-of-session sweep: quality pipeline per touched project, vault lint, index/log/status updates.
  - `handoff` — compact a conversation into a doc the next session picks up.
  - `signoff` — one-command session close: handoff, then wrap-up, then a copy-paste prompt to continue in a fresh chat.

- **Three agents** for KP-God's fleet, installed to `~/.claude/agents/`:
  - `codis` — senior implementer: reads the codebase deeply, reuses before inventing, plans-and-builds a lane in one coherent context.
  - `revis` — adversarial reviewer: cross-checks the diff against the plan's acceptance criteria, hunts reinvention, dead code, and silent no-ops. Read-only.
  - `planner` — high-stakes planning specialist for irreversible lanes that need your sign-off before any code.

- **The matching slash-commands** (`/KP-Setup`, `/KP-Grill`, `/KP-Healthcheck`,
  `/KP-Migrate`, `/KP-BugFix`, `/KP-WikiHealth`, `/KP-God`, `/code-cowork`).
  `wrap-up`, `handoff`, and `signoff` trigger on natural phrases ("wrap up",
  "sign off") rather than a slash-command.

- An **installer** that copies everything into place, writes the one config file
  (`~/.claude/brainkit.json`: your name + vault path), pulls three official Anthropic
  plugins (`superpowers`, `frontend-design`, `playground`), and checks the KP-God
  prerequisites on Windows.

## Prerequisites

Core kit (all platforms):

- [Claude Code](https://claude.com/claude-code)
- [Obsidian](https://obsidian.md) (free)
- `git`

Optional but recommended for code projects (the skills use them when present, skip
them when absent):

- `fallow` — deterministic JS/TS audit gate: `npm install -g fallow`
- `graphify` — code knowledge graph: `uv tool install graphifyy` (or `pip install graphifyy`)

KP-God's lane fleet (Windows only) additionally needs:

- **WezTerm** — `winget install wez.wezterm`
- **Claude Code CLI on native Windows** (`claude --version` works in PowerShell)
- **git 2.5+** (worktrees) and **Node.js**

On macOS/Linux everything except the KP-God fleet scripts works; the orchestration
skill's concepts still read fine, but lanes-in-WezTerm-tabs is Windows-native.

## Quickstart

1. **Install Obsidian** (you do not open a vault yet — the installer creates one).
2. **Get the kit.** Clone it, or just give Claude Code the link to this repo:
   ```
   git clone https://github.com/<this-repo-owner>/KP-llm-BrainKit.git
   ```
3. **Tell Claude `install this`** from inside the repo. The `install` skill asks your
   name and where to put your Brain folder, copies the skills, commands, and agents,
   scaffolds the vault, writes the config, and checks the KP-God prerequisites.

Prefer to do it by hand? See [INSTALL.md](INSTALL.md) — it includes the full
fresh-PC setup for KP-God.

After install: open the Brain folder in Obsidian, read its `CLAUDE.md` once, then say
`KP setup` to scaffold your first project — or drop a file in `raw/` and say `ingest`.

## How the pieces fit

- One feature, built start to finish → `code-cowork` inline. One agent, one context,
  the quality gates at the end.
- Something broken → `KP-BugFix`. Reproduce first, fix last, post-mortem filed.
- Fuzzy idea → `KP-Grill` until it is a PRD, then build.
- Several genuinely parallel streams → `KP-God`. The conductor stays thin, lanes run
  as visible Claude sessions you can watch and type into, `revis` reviews every code
  lane, and the board file survives any chat dying.
- End of the day → `wrap-up` (or `signoff` if the next chat should continue the work).

## What this is NOT

- It is **not** a copy of anyone's vault. It is a clean template; your content starts empty.
- It does **not** include any business data, credentials, or personal notes.
- It does **not** wire up any paid review tools. The skills run on Claude Code alone,
  plus the two optional free CLIs above.

## License

No license yet. Until one is added, treat this as "all rights reserved" for
redistribution; you are welcome to use it for your own setup.
