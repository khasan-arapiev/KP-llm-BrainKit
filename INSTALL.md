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

## 2. Install the skills and commands

Copy every folder in `<repo>/skills/` EXCEPT `install/` into `~/.claude/skills/`, and
every file in `<repo>/commands/` into `~/.claude/commands/`.

- Windows (PowerShell):
  ```powershell
  Get-ChildItem "<repo>\skills" -Directory | Where-Object Name -ne "install" |
    ForEach-Object { Copy-Item $_.FullName "$HOME\.claude\skills\" -Recurse }
  Copy-Item "<repo>\commands\*" "$HOME\.claude\commands\"
  ```
- macOS / Linux:
  ```bash
  mkdir -p ~/.claude/skills ~/.claude/commands
  for d in "<repo>"/skills/*/; do [ "$(basename "$d")" = install ] || cp -R "$d" ~/.claude/skills/; done
  cp "<repo>"/commands/* ~/.claude/commands/
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

## 5. Open and go

Open the Brain folder in Obsidian (File → Open Vault → pick the folder). Read its
`CLAUDE.md` once. Then say `KP setup` to scaffold your first project, or drop a file
in `raw/` and say `ingest`.
