# Installing KP-llm-BrainKit by hand

The easiest path is to tell Claude Code `install this` from inside the repo and let
the `install` skill do everything. These are the same steps, written out, in case you
want to do them manually or check what the skill does.

Throughout, `<repo>` is the folder you cloned this into, and `~` is your home folder
(`C:\Users\<you>` on Windows, `/Users/<you>` or `/home/<you>` elsewhere).

## 1. Create your Brain vault

Pick where it lives (default `~/Desktop/Brain`) and copy the template there, including
the hidden `.obsidian` folder:

- Windows (PowerShell):
  ```powershell
  Copy-Item "<repo>\vault-template" "$HOME\Desktop\Brain" -Recurse
  ```
- macOS / Linux:
  ```bash
  cp -R "<repo>/vault-template" "$HOME/Desktop/Brain"
  ```

Then, in the new `Brain/CLAUDE.md`, replace `{{set at install}}` with your name. Add a
first line to `Brain/wiki/log.md` (use today's date):

```
## [YYYY-MM-DD] setup | Brain vault created from KP-llm-BrainKit.
```

## 2. Install the skills, commands, and agents

Copy every folder in `<repo>/skills/` EXCEPT `install/` into `~/.claude/skills/`,
every file in `<repo>/commands/` into `~/.claude/commands/`, and every file in
`<repo>/agents/` into `~/.claude/agents/`.

- Windows (PowerShell):
  ```powershell
  Get-ChildItem "<repo>\skills" -Directory | Where-Object Name -ne "install" |
    ForEach-Object { Copy-Item $_.FullName "$HOME\.claude\skills\" -Recurse }
  Copy-Item "<repo>\commands\*" "$HOME\.claude\commands\"
  New-Item -ItemType Directory -Force "$HOME\.claude\agents" | Out-Null
  Copy-Item "<repo>\agents\*" "$HOME\.claude\agents\"
  ```
- macOS / Linux:
  ```bash
  mkdir -p ~/.claude/skills ~/.claude/commands ~/.claude/agents
  for d in "<repo>"/skills/*/; do [ "$(basename "$d")" = install ] || cp -R "$d" ~/.claude/skills/; done
  cp "<repo>"/commands/* ~/.claude/commands/
  cp "<repo>"/agents/* ~/.claude/agents/
  ```

## 3. Write the config

Create `~/.claude/brainkit.json` so the skills know where your vault is:

```json
{
  "owner": "Your Name",
  "vaultPath": "/absolute/path/to/Brain"
}
```

Use the real absolute path (on Windows, e.g. `C:\\Users\\you\\Desktop\\Brain`).

## 4. Install the mindset + design plugins

In Claude Code, paste these one at a time. They come from the official
`claude-plugins-official` marketplace, which is built in:

```
/plugin install superpowers@claude-plugins-official
/plugin install frontend-design@claude-plugins-official
/plugin install playground@claude-plugins-official
/reload-plugins
```

- `superpowers` is the important one: it carries the brainstorming, TDD, debugging,
  and verification discipline the KP skills lean on.
- `frontend-design` and `playground` add web/UX/UI and interactive-tool building.

## 5. Optional quality tools (recommended for code projects)

Two free, local CLI tools that the code skills (`code-cowork`, `wrap-up`, the agents)
use automatically when present, and skip gracefully when absent:

```
npm install -g fallow          # deterministic JS/TS audit gate (needs Node.js)
uv tool install graphifyy      # code knowledge graph (or: pip install graphifyy)
```

Verify with `fallow --version` and `graphify --version`.

## 6. KP-God prerequisites (Windows only)

KP-God turns a chat into a conductor that runs several parallel workstreams, each as a
**real Claude Code session in its own WezTerm tab** with an isolated git worktree. The
lane scripts are Windows-native PowerShell; on macOS/Linux the skill's orchestration
concepts still apply but the fleet scripts will not run.

On a fresh Windows PC, KP-God needs exactly four things on PATH:

1. **WezTerm** — the lane multiplexer (one window per project, one tab per lane):
   ```
   winget install wez.wezterm
   ```
2. **Claude Code CLI, native Windows** — lanes are spawned as `claude.exe`. Check with
   `claude --version` from PowerShell (not from WSL).
3. **git 2.5+** — lane isolation uses `git worktree`. Check `git --version`.
4. **Node.js** — used once per spawn for a lossless JSON edit of `~/.claude.json`
   (auto-accepting the folder-trust dialog for lane worktrees). Check `node --version`.

That is the whole setup. The scripts in `~/.claude/skills/KP-God/scripts/` handle
everything else, including a known WezTerm-on-Windows socket quirk. Two behaviours
worth knowing before your first fleet:

- **Keep the fleet's WezTerm window open** (minimized is fine) while lanes run:
  unlike tmux, the multiplexer lives in the GUI, so closing the window kills the lanes.
- The conductor will ask you each session whether lanes run with permission prompts
  (`ask`, the default) or fully autonomous (`skip`, which passes
  `--dangerously-skip-permissions` to the lane sessions). Choose deliberately.

## 7. Open and go

Open the Brain folder in Obsidian (File → Open Vault → pick the folder). Read its
`CLAUDE.md` once. Then say `KP setup` to scaffold your first project, or drop a file
in `raw/` and say `ingest`.
