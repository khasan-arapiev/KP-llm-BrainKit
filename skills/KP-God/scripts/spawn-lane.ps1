# spawn-lane.ps1 <lane-id> <project-dir> <brief-path>
#               [-Worktree] [-Session <name>] [-Replace] [-Resume]
#               [-Dir <path>] [-Permissions ask|skip] [-Model <model>]
#
# Opens a real Claude session for a lane in its own WezTerm TAB (tab title =
# lane-id) inside a WezTerm WINDOW named after the PROJECT (window title
# "kp-<session>"). Windows-native successor to the WSL/tmux spawn-lane.sh,
# same contract: the window tells you WHICH project, the tab tells you WHICH
# lane/scope, and the WezTerm tab bar is the lane picker.
#
# Session-name resolution (first non-empty wins):
#   -Session <name>  >  KP_FLEET_SESSION env  >  the single existing kp-*
#   window's session  >  'main'
#
# Tab title is ALWAYS the lane-id and must be UNIQUE in its session window: a
# duplicate makes the lane unsteerable (send-lane refuses the ambiguous
# target). The script refuses to spawn onto an existing lane tab unless you
# pass -Replace, which kills the old tab(s) first. Use -Replace for the
# HEAVY-handoff respawn; use close-lane.ps1 at the done-gate so old tabs never
# linger in the first place.
#
# -Permissions ask (default) launches lanes with normal permission prompts.
# -Permissions skip launches with --dangerously-skip-permissions (full
# autonomy) and is only passed when the owner explicitly chose that mode for this
# fleet session. The conductor asks the owner which mode the fleet runs in each
# session and passes the answer through this flag; it never assumes.
#
# -Model <m> pins the lane's model (e.g. sonnet for a docs/content lane).
#
# The lane's working dir is pre-trusted in ~/.claude.json before launch, so
# Claude's folder-trust dialog never appears (automatic).
#
# -Resume relaunches a lane whose tab died (reboot, crash) with
# `claude --continue`, which restores the most recent conversation in the
# lane's working directory: full context back, no cold re-brief. For a code
# lane pass -Dir <its-worktree-path> (from the board); git worktrees survive
# reboots. Only use -Resume where a session actually ran; for a lane that
# flagged HEAVY, spawn fresh from the handoff instead (its context is degraded
# by design, that is why it flagged).
#
# With -Worktree, leases an isolated git worktree for the lane first, at
# <project>\.kp-worktrees\<lane-id> on branch kp/<lane-id> (created if
# needed, reused if it already exists). -Dir <path> uses that exact directory
# instead (mutually exclusive with -Worktree; this is how -Resume reattaches
# to a still-leased worktree).
#
# Prints: lane=<id> dir=<workdir> window=<session>:<lane> session=<session> pane=<pane-id>
param(
    [Parameter(Mandatory, Position = 0)][string]$LaneId,
    [Parameter(Mandatory, Position = 1)][string]$ProjectDir,
    [Parameter(Mandatory, Position = 2)][string]$BriefPath,
    [switch]$Worktree,
    [string]$Session,
    [switch]$Replace,
    [switch]$Resume,
    [string]$Dir,
    [ValidateSet('ask', 'skip')][string]$Permissions = 'ask',
    [string]$Model
)
. "$PSScriptRoot\_kp-common.ps1"

if (-not (Test-Path $ProjectDir -PathType Container)) { Write-Error "spawn-lane: project dir not found: $ProjectDir"; exit 1 }
if (-not (Test-Path $BriefPath -PathType Leaf)) { Write-Error "spawn-lane: brief not found: $BriefPath"; exit 1 }
if ($Worktree -and $Dir) { Write-Error 'spawn-lane: -Worktree and -Dir are mutually exclusive'; exit 1 }
if (-not (Test-Path $script:CLAUDE)) { Write-Error 'spawn-lane: claude.exe not found'; exit 1 }
$ProjectDir = (Resolve-Path $ProjectDir).Path
$BriefPath  = (Resolve-Path $BriefPath).Path

$guiUp = Connect-Fleet

# --- session resolution ---------------------------------------------------
if (-not $Session) { $Session = $env:KP_FLEET_SESSION }
if (-not $Session -and $guiUp) {
    $kpSessions = @(Get-LiveLanes | ForEach-Object Session | Sort-Object -Unique)
    if ($kpSessions.Count -eq 1) { $Session = $kpSessions[0] }
}
if (-not $Session) { $Session = 'main' }

# --- duplicate-tab guard ----------------------------------------------------
if ($guiUp) {
    $dupes = Get-LiveLanes -LaneId $LaneId -Session $Session
    if ($dupes.Count -gt 0) {
        if ($Replace) {
            foreach ($p in $dupes) { Invoke-Wezterm @('kill-pane', '--pane-id', $p.PaneId) | Out-Null }
        } else {
            Write-Error @"
spawn-lane: lane tab '$LaneId' already exists in session '$Session'.
  A live lane is steered with send-lane.ps1, never respawned.
  If the old session is dead or handed off, re-run with -Replace,
  or close it properly first with close-lane.ps1.
"@
            exit 1
        }
    }
}

# --- working directory (worktree lease) -------------------------------------
$WorkDir = $ProjectDir
if ($Dir) {
    if (-not (Test-Path $Dir -PathType Container)) { Write-Error "spawn-lane: -Dir not found: $Dir"; exit 1 }
    $WorkDir = (Resolve-Path $Dir).Path
} elseif ($Worktree) {
    & git -C $ProjectDir rev-parse --is-inside-work-tree *> $null
    if ($LASTEXITCODE -ne 0) { Write-Error "spawn-lane: -Worktree needs a git repo at $ProjectDir"; exit 1 }
    $WorkDir = Join-Path $ProjectDir ".kp-worktrees\$LaneId"
    if (-not (Test-Path $WorkDir)) {
        # keep the pool dir out of git status without touching tracked files
        $common = (& git -C $ProjectDir rev-parse --git-common-dir).Trim()
        if (-not [IO.Path]::IsPathRooted($common)) { $common = Join-Path $ProjectDir $common }
        $exclude = Join-Path $common 'info\exclude'
        New-Item -ItemType Directory -Force -Path (Split-Path $exclude) | Out-Null
        if (-not (Test-Path $exclude) -or -not (Select-String -Path $exclude -Pattern '^\.kp-worktrees/$' -Quiet)) {
            Add-Content $exclude '.kp-worktrees/'
        }
        & git -C $ProjectDir show-ref --verify --quiet "refs/heads/kp/$LaneId"
        if ($LASTEXITCODE -eq 0) { & git -C $ProjectDir worktree add $WorkDir "kp/$LaneId" | Out-Null }
        else { & git -C $ProjectDir worktree add $WorkDir -b "kp/$LaneId" | Out-Null }
        if ($LASTEXITCODE -ne 0) { Write-Error 'spawn-lane: git worktree add failed'; exit 1 }
    }
    $WorkDir = (Resolve-Path $WorkDir).Path
}

# --- pre-trust the working dir in ~/.claude.json ----------------------------
# Same field the folder-trust dialog writes. Done via node (lossless JSON
# round-trip; PowerShell's ConvertFrom-Json mangles date-like strings).
# Strictly additive: any failure leaves the file untouched and the dialog
# simply appears. Never risk wiping config.
$node = Get-Command node -ErrorAction SilentlyContinue
if ($node) {
    # Run from a temp .js file, NOT `node -e`: Windows PowerShell 5.1 mangles the
    # embedded double quotes of an inline script, and with ErrorActionPreference
    # Stop the resulting stderr became a terminating NativeCommandError that
    # killed the spawn before the tab launched (verified on Windows 11). File + argv avoids
    # both. Whole block is best-effort by design: worst case the dialog appears.
    $seedJs = Join-Path $script:STATE_DIR 'trust-seed.js'
    @'
const fs = require("fs");
const p = process.argv[2], dir = process.argv[3];
try {
  const d = JSON.parse(fs.readFileSync(p, "utf8"));
  if (typeof d !== "object" || d === null) process.exit(1);
  d.projects = d.projects || {};
  d.projects[dir] = d.projects[dir] || {};
  if (d.projects[dir].hasTrustDialogAccepted !== true) {
    d.projects[dir].hasTrustDialogAccepted = true;
    fs.writeFileSync(p + ".kp-tmp", JSON.stringify(d, null, 2));
    fs.renameSync(p + ".kp-tmp", p);
  }
} catch (e) { process.exit(1); }
'@ | Set-Content $seedJs -Encoding ascii
    $eap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { & $node.Source $seedJs "$env:USERPROFILE\.claude.json" $WorkDir 2>$null } catch {}
    $ErrorActionPreference = $eap
}

# --- build the lane launcher -------------------------------------------------
$claudeArgs = @()
if ($Resume) { $claudeArgs += '--continue' }
if ($Permissions -eq 'skip') { $claudeArgs += '--dangerously-skip-permissions' }
if ($Model) { $claudeArgs += @('--model', $Model) }
if ($Resume) {
    $prompt = "You were interrupted and are being resumed. Re-read $BriefPath (your lane brief) and your lane dir's status and inbox.md, check the real state of the work (git log, working tree), then continue the lane from where it actually stands. Follow the brief's status-file protocol exactly."
} else {
    $prompt = "Read $BriefPath and execute it as your lane brief. It defines your goal, scope, acceptance criteria, and the status-file protocol you must follow exactly."
}
# cmd /k keeps the tab alive after claude exits (the tmux version's `exec bash`)
$launcher = Join-Path $script:STATE_DIR "launchers\$LaneId.cmd"
@(
    '@echo off'
    "title $LaneId"
    "cd /d `"$WorkDir`""
    "`"$script:CLAUDE`" $($claudeArgs -join ' ') `"$prompt`""
) | Set-Content $launcher -Encoding ascii

# --- spawn the tab -----------------------------------------------------------
# The session's WezTerm window is wherever that session's live lanes already
# are (window titles cannot carry the session name: a running Claude session
# rewrites them continuously, so the registry is the mapping).
$prog = @('cmd', '/k', $launcher)
if (-not $guiUp) {
    # No GUI at all: launch one whose INITIAL tab is this lane (never the
    # .wezterm.lua default WSL shell).
    Start-FleetGui -ProgramArgs $prog -Cwd $WorkDir | Out-Null
    $pane = Get-FleetPanes | Sort-Object pane_id -Descending | Select-Object -First 1
    $paneId = [int]$pane.pane_id
} else {
    $winIds = @(Get-LiveLanes -Session $Session | ForEach-Object WindowId | Sort-Object -Unique)
    if ($winIds.Count -gt 0) {
        $paneId = [int]((Invoke-Wezterm (@('spawn', '--window-id', $winIds[0], '--cwd', $WorkDir, '--') + $prog)) -join '').Trim()
    } else {
        $paneId = [int]((Invoke-Wezterm (@('spawn', '--new-window', '--cwd', $WorkDir, '--') + $prog)) -join '').Trim()
    }
}
Invoke-Wezterm @('set-tab-title', '--pane-id', $paneId, $LaneId) | Out-Null

# --- record ------------------------------------------------------------------
$state = Read-FleetState
$winId = (Get-FleetPanes | Where-Object { $_.pane_id -eq $paneId } | Select-Object -First 1).window_id
$state.lanes["${Session}:$LaneId"] = @{
    laneId = $LaneId; session = $Session; paneId = $paneId; windowId = [int]$winId
    guiPid = $state.guiPid; dir = $WorkDir; project = $ProjectDir; spawned = (Get-Date -Format s)
}
Write-FleetState $state

Write-Output "lane=$LaneId dir=$WorkDir window=${Session}:$LaneId session=$Session pane=$paneId"
