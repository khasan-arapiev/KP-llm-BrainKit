# KP-God lane scripts (Windows-native)

Helpers that let the conductor run each lane as a **real Claude Code session** in its own
WezTerm tab with an isolated git worktree, instead of an in-chat subagent. This is what gives
lanes visibility (you can watch/type into any tab), hard worktree isolation, and survival
across the conductor's death.

**Backend note:** an earlier version of this fleet ran on WSL Ubuntu (tmux). Several concurrent lanes inside a small VM swapped and froze, so the fleet is Windows-native on WezTerm: no VM wall, no /mnt/c filesystem tax, no WSL networking layer.

## Window-per-project, tab-per-lane

The WezTerm **window is the project session**; each lane is a **tab titled with the
lane-id**. So the window tells the owner *which project*, the tab tells them *which lane*, and
the WezTerm tab bar is their lane picker. Example while orchestrating two projects: two WezTerm
windows, one holding tabs `checkout-model | orders-model`, the other `hero-copy | pricing-page`.

The conductor sets the session with `-Session <project>` (or `KP_FLEET_SESSION`, which now
works fine since nothing crosses a wsl.exe boundary anymore); with neither, `spawn-lane` uses
the single session that already has live lanes (falling back to `main`). Lane-ids should be
human-readable scope names (`checkout-model`, `hero-copy`), because they become the tab labels
the owner reads, and they must be **unique within their session**: a duplicate makes the lane
unsteerable. `spawn-lane` enforces this (refuses, or replaces with `-Replace`).

**Where the lane -> session mapping lives:** a running Claude session rewrites the WezTerm
WINDOW title continuously, so window titles cannot carry the session name. Explicit TAB
titles survive, so the tab title carries the lane-id, and the session mapping lives in the
**registry** (`state\lanes.json`), validated against live panes on every lookup. The registry
is a cache of ground truth, never a substitute for it: an entry only counts as live if its
GUI is the pinned one and its pane still exists with the matching tab title.

## Environment

- Runs on **native Windows**. `claude.exe` is at `~\.local\bin\`, WezTerm at
  `C:\Program Files\WezTerm\`. The Claude config (skills, agents, MCP, memory) is the same
  one this conductor runs on: one filesystem, no symlink bridge.
- Call from the conductor with:
  `powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.claude\skills\KP-God\scripts\<script>.ps1" <args>`
- **Known WezTerm-on-Windows quirk:** `wezterm cli` cannot
  auto-discover the GUI socket (relative-path bug). `_kp-common.ps1` handles it by pinning
  `WEZTERM_UNIX_SOCKET` to the full path of a live GUI's socket; if no GUI answers,
  `spawn-lane` launches one whose initial tab is the lane itself (never the `.wezterm.lua`
  default WSL shell). Nothing to do manually, but if a cli call ever fails with
  "failed to connect to Socket(gui-sock-...)", that is this quirk resurfacing.
- Closing the WezTerm window kills the lanes in it (unlike tmux, the mux lives in the GUI).
  Keep fleet windows open (minimized is fine) while lanes run.

## Permission mode is the owner's call, per session

The conductor must ask the owner how the fleet should run at the start of each orchestration
session and pass the answer through `spawn-lane.ps1 -Permissions ask|skip` — never assume a
past session's answer still holds, and never edit the script to change the mode. `ask`
(the default) launches lanes with normal permission prompts; `skip` launches with
`--dangerously-skip-permissions` (full autonomy) and is passed only when the owner explicitly
chose it for this fleet session. Whatever mode is chosen, the human gates in the skill still
stand.

## spawn-lane.ps1 `<lane-id> <project-dir> <brief-path> [flags]`

Flags: `[-Worktree] [-Session <name>] [-Replace] [-Resume] [-Dir <path>]
[-Permissions ask|skip] [-Model <model>]`

Opens a WezTerm tab titled `<lane-id>` in the project session's window and launches a Claude
session in it (via a generated `state\launchers\<lane-id>.cmd`, run under `cmd /k` so the tab
survives claude exiting). Session resolution: `-Session` > `KP_FLEET_SESSION` > the single
session with live lanes > `main`. Validates its arguments before touching WezTerm. The
session boots reading the brief as its instructions. Prints
`lane= dir= window=<session>:<lane> session= pane=` so the conductor records where the lane
landed.

- `-Worktree` — leases the lane an isolated git worktree at
  `<project>\.kp-worktrees\<lane-id>` on branch `kp/<lane-id>` (created if needed, reused if
  it already exists; the pool dir is auto-added to `.git\info\exclude`). Code lanes always
  use it.
- `-Replace` — kills any existing tab(s) with this lane-id in the target session before
  spawning. This is the flag for the HEAVY-handoff respawn: the old tab must die or the
  duplicate name wedges the lane.
- `-Resume` — relaunches with `claude --continue`, restoring the most recent conversation in
  the lane's working directory: full context back, no cold re-brief. Use it when a lane's
  tab died (reboot, crash) but its session state survived. For a code lane pass
  `-Dir <its-worktree-path>` from the board — git worktrees survive reboots. Do NOT use it
  for a HEAVY lane: that context is degraded by design, spawn fresh from the handoff instead.
- `-Dir <path>` — run in this exact directory (mutually exclusive with `-Worktree`); this is
  how `-Resume` reattaches to a still-leased worktree.
- `-Permissions ask|skip` — see above. Default `ask`.
- `-Model <m>` — pin the lane's model (e.g. `sonnet` for a mechanical or docs lane; default
  is the lane session's own default).

**Folder trust is automatic (automatic):** before launching Claude, the
script seeds `projects.<dir>.hasTrustDialogAccepted: true` in `~\.claude.json` — the same
field the dialog itself writes — so lanes never stall on the "is this folder trusted?"
prompt. Done via node for a lossless JSON round-trip, strictly additive, and skipped entirely
if the file cannot be parsed (the dialog then just appears; config is never risked).

## send-lane.ps1 `[-Session <name>] <lane-id> <text...>`

Types `text` into the live lane session and presses Enter. It auto-locates the lane through
the registry, so normally you pass only the lane-id; add `-Session <name>` to disambiguate if
the same lane-id is live in two projects (the script refuses an ambiguous send rather than
steer the wrong lane). Keep text short; for substantial follow-ups write the lane's
`inbox.md` and send `Read your inbox.md and act on it.`

## close-lane.ps1 `<lane-id> [-Session <name>] [-LaneDir <path>] [-KeepWorktree]`

The done-gate's mechanical half in one command: kills the lane's tab(s) (no idle Claude
session left burning RAM, no stale tab to wedge a later respawn — including stray tabs the
registry lost), removes the lane's leased `.kp-worktrees` git worktree if its working dir was
one (the `kp/<lane-id>` branch and its commits survive; skip with `-KeepWorktree` if the
branch still needs a manual merge from inside it), clears the registry entry, and with
`-LaneDir` stamps the lane's `status` file `CLOSED | <date>` so the watcher and a fresh
conductor read it as finished. Run it when a lane reaches `done` on the board, or to tear
down a dead/abandoned lane. It does not judge doneness; the conductor's done-gate checklist
does.

## watch-lanes.ps1 `<lanes-dir> [timeout-seconds]`

Zero-token supervision. Snapshots every `<lanes-dir>\*\status` file, sleeps, and exits the
moment any lane's status line changes (printing the diff and the full current state). It also
tracks **liveness**: a lane whose status implies a live session (`RUNNING`, `REVIEW-READY`,
`FORK`, `HEAVY`, `BLOCKED`) but whose WezTerm tab has vanished is marked `[TAB GONE]`, and
that transition wakes the conductor too — a crashed lane is caught within one poll interval,
not at the heartbeat. Recover a gone tab with `spawn-lane.ps1 -Resume`. Output lines carry
the age of each lane's state (display only, never a wake trigger). The conductor runs this as
a **background task** so the harness notification wakes it on change instead of polling.
Exit 0 = something changed; exit 2 = timeout heartbeat (default 1800s) with no change.
Relaunch after each wake.

## list-lanes.ps1

Lists every live lane across all sessions (`<session>:<lane-id>  pane=  dir=`), plus
registry entries whose tab has died (`[TAB GONE]`). The conductor-boot replacement for
`tmux list-windows -a`: it tells a fresh conductor which lanes from a previous session are
still alive to reattach versus gone to `-Resume`.

## peek-lane.ps1 `[-Session <name>] <lane-id> [-Lines <n>]`

Prints the last `<n>` lines (default 40) of a live lane's screen — the replacement for
`tmux capture-pane -p` when a lane looks stuck.

## Lane directory contract

Each lane owns `orchestrator/lanes/<lane-id>/` in the project vault:

- `brief.md` — conductor-written: goal, scope, pointers, acceptance criteria, and the
  status-protocol block (with the placeholders filled with the lane's real paths).
- `status` — lane-written, ONE line: `<STATE> | <one-liner>`, where STATE is
  `RUNNING | REVIEW-READY | FORK | HEAVY | BLOCKED | DONE` (plus `CLOSED`, stamped by
  close-lane.ps1, never by the lane). This is the only thing the watcher reads.
- `inbox.md` — conductor-written follow-ups.
- `report.md` — lane-written distilled chunk reports and fork options.
