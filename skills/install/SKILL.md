---
name: install
description: Set up KP-llm-BrainKit on this machine. Installs the mindset and design plugins, copies the KP skills, commands, and agents into ~/.claude, scaffolds a blank Obsidian Brain vault, writes the config, and checks the KP-God prerequisites. Trigger on "install this", "install brainkit", "install the brain kit", "set up the brain kit", or right after cloning KP-llm-BrainKit.
license: MIT
---

# Install KP-llm-BrainKit

This skill sets up the kit on the current machine. The person running it is the
**owner** of their own fresh vault. Nothing from anyone else's vault is involved.

Run these steps in order. The repo root (the folder containing this `skills/`
directory) is referred to as `<repo>`. Confirm before writing anything outside `<repo>`.

## Step 1: Gather inputs

Ask the owner two things, then confirm both before proceeding:

1. **Their name** (the vault owner). Used in the vault `CLAUDE.md` and project pages.
2. **Where to put the Brain vault.** Default: `~/Desktop/Brain`. Accept any absolute
   path. This becomes `vaultPath`.

Resolve `~` to the real home directory for the current OS (Windows: the user profile
folder, e.g. `C:\Users\<user>`; macOS/Linux: `$HOME`).

## Step 2: Scaffold the Brain vault

1. If the target vault path already exists and is non-empty, stop and ask whether to
   pick a different location or merge. Never overwrite an existing vault silently.
2. Copy the entire `<repo>/vault-template/` directory to the chosen vault path,
   including the hidden `.obsidian/` folder. The result should contain `CLAUDE.md`,
   `wiki/`, `raw/`, `production/`, `docs/`, `handoffs/`, and `.obsidian/`.
3. In the copied `CLAUDE.md`, replace the placeholder `{{set at install}}` with the
   owner's name.
4. Append a seed entry to the copied `wiki/log.md` (use today's actual date):
   `## [YYYY-MM-DD] setup | Brain vault created from KP-llm-BrainKit.`

## Step 3: Install the KP skills, commands, and agents

1. Copy each subfolder of `<repo>/skills/` into `~/.claude/skills/`, EXCEPT this
   `install` skill itself (it does not need to live there). That means: `KP-Setup`,
   `KP-Grill`, `KP-Migrate`, `KP-BugFix`, `KP-WikiHealth`, `KP-God`, `code-cowork`,
   `check-pr`, `improve-codebase-architecture`, `handoff`, `wrap-up`, `signoff`, with
   their `templates/`, `scripts/`, `state/`, and `references/` subfolders intact.
2. Copy each file in `<repo>/commands/` into `~/.claude/commands/`.
3. Copy each file in `<repo>/agents/` into `~/.claude/agents/`. These are the
   orchestration fleet KP-God dispatches: `codis` (implementer), `revis` (reviewer),
   `planner` (high-stakes planning).
4. If a skill, command, or agent of the same name already exists, ask before overwriting.

Skills copied into `~/.claude/skills/` are picked up immediately. Commands appear as
`/KP-Setup`, `/KP-Grill`, `/KP-Healthcheck`, `/KP-Migrate`, `/KP-BugFix`,
`/KP-WikiHealth`, `/KP-God`, and `/code-cowork`.

## Step 4: Write the config

Write `~/.claude/brainkit.json` (create `~/.claude/` if missing):

```json
{
  "owner": "<the owner's name>",
  "vaultPath": "<absolute path to the Brain folder>"
}
```

Every KP skill reads `vaultPath` from this file to find the vault. If the owner ever
moves the vault, they re-run this install or edit this one value.

## Step 5: Install the mindset + design plugins

These are official Anthropic plugins from the `claude-plugins-official` marketplace
(present by default). Plugin installation is a user action, so present these commands
and ask the owner to paste them into Claude Code one at a time:

```
/plugin install superpowers@claude-plugins-official
/plugin install frontend-design@claude-plugins-official
/plugin install playground@claude-plugins-official
/reload-plugins
```

- `superpowers` — the brainstorming / TDD / debugging / verification discipline that
  the KP skills compose with. Install this one even if nothing else.
- `frontend-design` — production-grade web / UX / UI design.
- `playground` — interactive single-file explorers and tools.

If a plugin is already installed, the owner can skip it.

## Step 6: Optional quality tools (recommended for code projects)

The code skills (`code-cowork`, `wrap-up`, the agents) use two free, local CLI tools
when present, and skip them gracefully when absent. Offer to install them:

- **fallow** — deterministic JS/TS audit gate (dead code, complexity, duplication,
  cycles): `npm install -g fallow`. Needs Node.js.
- **graphify** — code knowledge graph for reuse and blast-radius queries:
  `uv tool install graphifyy` (or `pip install graphifyy`). Needs Python 3.

Verify with `fallow --version` and `graphify --version`. If the owner declines or a
runtime is missing, note it and move on; nothing else depends on them.

## Step 7: KP-God prerequisites check (Windows only)

KP-God's lane fleet runs real Claude Code sessions in WezTerm tabs. It is
**Windows-native**; on macOS/Linux the KP-God skill's concepts still read fine but the
`scripts/` do not run. On Windows, check each and report what is missing:

1. **WezTerm** — `wezterm --version`. Install: `winget install wez.wezterm`
   (or from wezfurlong.org/wezterm). The fleet uses it as the lane multiplexer:
   one window per project, one tab per lane.
2. **Claude Code CLI on native Windows** — `claude --version` from PowerShell (not
   WSL). Lanes are spawned as `claude.exe` processes.
3. **git 2.5+** — `git --version`. Lane isolation uses `git worktree`.
4. **Node.js** — `node --version`. The spawn script uses it for a lossless JSON edit
   of `~/.claude.json` (the folder-trust seed).

Nothing to configure beyond having them on PATH; the scripts handle the rest
(including the WezTerm socket quirk). If any are missing, KP-God is the only thing
affected; the rest of the kit works without them.

## Step 8: Report and nudge

Tell the owner, plainly:

- The vault path that was created.
- That the KP skills, commands, and agents are installed.
- That `~/.claude/brainkit.json` now points the skills at their vault.
- Whether the three plugins were installed or still need the paste-in step.
- The result of the optional-tools and KP-God prerequisite checks.

Then suggest first moves:

1. Open the vault folder in Obsidian (File → Open Vault → pick the Brain folder).
2. Read `CLAUDE.md` once to see how the vault thinks.
3. Say "KP setup" to scaffold a first project, or drop a file in `raw/` and say
   "ingest" to file a first source.

## What this skill never does

- It never copies anyone else's content. The vault starts empty.
- It never writes secrets anywhere.
- It never overwrites an existing vault, skill, command, or agent without asking.
