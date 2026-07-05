# _kp-common.ps1 - shared plumbing for the KP-God Windows-native fleet scripts.
# Dot-source this from the lane scripts; do not run it directly.
#
# The fleet backend is WezTerm on native Windows: one WezTerm WINDOW per project
# session, one TAB per lane (tab title = lane-id), each tab running a real
# Claude Code session. `wezterm cli` is the control plane.
#
# Two verified WezTerm-on-Windows quirks shape this design:
#  1. `wezterm cli` fails to auto-discover the GUI socket (relative-path bug:
#     "failed to connect to Socket(gui-sock-<pid>)"). Fix: set
#     WEZTERM_UNIX_SOCKET to the FULL socket path of a live GUI. Connect-Fleet
#     does that, probing every live wezterm-gui process until one answers.
#  2. A running Claude session rewrites the WINDOW title continuously (OSC
#     title updates), so window titles cannot carry the session name. Explicit
#     TAB titles survive, so: tab title = lane-id (set at spawn, load-bearing),
#     and the lane -> session mapping lives in the REGISTRY (state\lanes.json),
#     validated against live panes on every lookup. Registry entries are keyed
#     "<session>:<lane-id>" and carry the pane id and the GUI pid they were
#     spawned into; an entry only counts as live if that GUI is still the
#     pinned one AND its pane still exists with the matching tab title (pane
#     ids restart from 0 on a fresh GUI, so the guiPid check prevents a stale
#     entry from matching a recycled pane id).

$ErrorActionPreference = 'Stop'

$script:WEZTERM = 'C:\Program Files\WezTerm\wezterm.exe'
if (-not (Test-Path $script:WEZTERM)) {
    $cmd = Get-Command wezterm -ErrorAction SilentlyContinue
    if ($cmd) { $script:WEZTERM = $cmd.Source }
    else { throw 'kp-common: wezterm.exe not found (checked Program Files and PATH)' }
}
$script:WEZTERM_GUI = Join-Path (Split-Path $script:WEZTERM) 'wezterm-gui.exe'

$script:CLAUDE = "$env:USERPROFILE\.local\bin\claude.exe"
if (-not (Test-Path $script:CLAUDE)) {
    $cmd = Get-Command claude -ErrorAction SilentlyContinue
    if ($cmd) { $script:CLAUDE = $cmd.Source }
}

$script:STATE_DIR = "$env:USERPROFILE\.claude\skills\KP-God\state"
$script:SOCK_DIR  = "$env:USERPROFILE\.local\share\wezterm"
New-Item -ItemType Directory -Force -Path $script:STATE_DIR, "$script:STATE_DIR\launchers" | Out-Null

function Invoke-Wezterm {
    # Runs `wezterm cli <args>` against the pinned fleet socket. Returns stdout.
    param([Parameter(Mandatory)][string[]]$CliArgs)
    $out = & $script:WEZTERM cli --no-auto-start @CliArgs 2>&1
    if ($LASTEXITCODE -ne 0) { throw "wezterm cli $($CliArgs -join ' ') failed: $out" }
    return $out
}

function Test-Sock {
    param([string]$SockPath)
    if (-not (Test-Path $SockPath)) { return $false }
    $env:WEZTERM_UNIX_SOCKET = $SockPath
    & $script:WEZTERM cli --no-auto-start list --format json *> $null
    return ($LASTEXITCODE -eq 0)
}

function Connect-Fleet {
    # Pins WEZTERM_UNIX_SOCKET to a live, answering GUI socket and records its
    # pid in the registry. Returns $true when connected, $false when no usable
    # GUI exists (callers that need one either Start-FleetGui or bail).
    $state = Read-FleetState
    if ($state.guiPid) {
        $sock = Join-Path $script:SOCK_DIR "gui-sock-$($state.guiPid)"
        $proc = Get-Process -Id $state.guiPid -ErrorAction SilentlyContinue
        if ($proc -and $proc.ProcessName -eq 'wezterm-gui' -and (Test-Sock $sock)) { return $true }
    }
    foreach ($proc in (Get-Process wezterm-gui -ErrorAction SilentlyContinue)) {
        $sock = Join-Path $script:SOCK_DIR "gui-sock-$($proc.Id)"
        if (Test-Sock $sock) {
            $state.guiPid = $proc.Id
            Write-FleetState $state
            return $true
        }
    }
    return $false
}

function Start-FleetGui {
    # Launches a WezTerm GUI running the given program in its initial tab and
    # waits for its socket. Passing the program explicitly matters: the user's
    # .wezterm.lua default_prog is a WSL Ubuntu shell, and the whole point of
    # this backend is to never boot WSL. Returns the new GUI's pid.
    param([Parameter(Mandatory)][string[]]$ProgramArgs, [string]$Cwd)
    # Fleet windows launch with their own config file: no titlebar buttons
    # (window_decorations RESIZE) + close confirmation, because closing the
    # fleet window kills every lane in it and that happened twice by accident
    # --config-file replaces ~/.wezterm.lua
    # for this GUI only, so the user's normal WezTerm windows keep their look.
    $fleetCfg = Join-Path $script:STATE_DIR 'fleet.lua'
    @'
local wezterm = require 'wezterm'
local config = wezterm.config_builder()
config.window_decorations = "RESIZE"
config.window_close_confirmation = "AlwaysPrompt"
config.show_close_tab_button_in_tabs = false
return config
'@ | Set-Content $fleetCfg -Encoding ascii
    $guiArgs = @('--config-file', $fleetCfg, 'start')
    if ($Cwd) { $guiArgs += @('--cwd', $Cwd) }
    $guiArgs += @('--') + $ProgramArgs
    $before = @(Get-Process wezterm-gui -ErrorAction SilentlyContinue | ForEach-Object Id)
    Start-Process $script:WEZTERM_GUI -ArgumentList $guiArgs | Out-Null
    for ($i = 0; $i -lt 60; $i++) {
        Start-Sleep -Milliseconds 500
        $gui = Get-Process wezterm-gui -ErrorAction SilentlyContinue | Where-Object { $before -notcontains $_.Id } | Select-Object -First 1
        if ($gui -and (Test-Sock (Join-Path $script:SOCK_DIR "gui-sock-$($gui.Id)"))) {
            $state = Read-FleetState
            $state.guiPid = $gui.Id
            Write-FleetState $state
            return $gui.Id
        }
    }
    throw 'kp-common: launched wezterm-gui but its socket never became reachable'
}

function Read-FleetState {
    $f = Join-Path $script:STATE_DIR 'lanes.json'
    if (Test-Path $f) {
        try {
            $raw = Get-Content $f -Raw
            if ($PSVersionTable.PSVersion.Major -ge 6) {
                $s = $raw | ConvertFrom-Json -AsHashtable
            } else {
                # -AsHashtable is PS6+; under Windows PowerShell 5.1 it threw on
                # every read, so the registry silently reset to empty and lane
                # registrations were lost on the next write (verified on Windows 11).
                $o = $raw | ConvertFrom-Json
                $s = @{ guiPid = $o.guiPid; lanes = @{} }
                if ($o.lanes) {
                    foreach ($p in $o.lanes.PSObject.Properties) {
                        $e = @{}
                        foreach ($q in $p.Value.PSObject.Properties) { $e[$q.Name] = $q.Value }
                        $s.lanes[$p.Name] = $e
                    }
                }
            }
            if ($s -is [hashtable]) {
                if (-not $s.ContainsKey('lanes') -or -not ($s.lanes -is [hashtable])) { $s.lanes = @{} }
                return $s
            }
        } catch { }
    }
    return @{ guiPid = $null; lanes = @{} }
}

function Write-FleetState {
    param([Parameter(Mandatory)]$State)
    $f   = Join-Path $script:STATE_DIR 'lanes.json'
    $tmp = "$f.tmp"
    $State | ConvertTo-Json -Depth 8 | Set-Content $tmp -Encoding utf8
    Move-Item $tmp $f -Force
}

function Get-FleetPanes {
    # All panes in the pinned mux, parsed, with a plain-path Cwd.
    $json = (Invoke-Wezterm @('list', '--format', 'json')) -join "`n"
    # ConvertFrom-Json called directly (not via pipeline) + re-enumerated: under
    # Windows PowerShell 5.1 the pipeline form emits a JSON array of 2+ panes as
    # ONE nested array object, so every property read returned Object[] and
    # -match ran in array-filter mode with $Matches unset (crashed once
    # the moment a second lane spawned). PS7 is unaffected either way.
    $panes = @(ConvertFrom-Json $json | ForEach-Object { $_ })
    foreach ($p in $panes) {
        $cwd = $p.cwd
        if ($cwd -match '^file:///(.+)$') { $cwd = [uri]::UnescapeDataString($Matches[1]) -replace '/', '\' }
        $p | Add-Member -NotePropertyName CwdPath -NotePropertyValue $cwd -Force
    }
    return $panes
}

function Get-LiveLanes {
    # The fleet's ground truth: every registry entry whose pane is still alive
    # in the pinned GUI with the matching tab title. Returns objects with
    # Session, LaneId, PaneId, WindowId, Dir, Project, CwdPath. Optionally
    # filtered by lane and/or session. Assumes Connect-Fleet already succeeded.
    param([string]$LaneId, [string]$Session)
    $state = Read-FleetState
    $panes = Get-FleetPanes
    $live = @()
    foreach ($key in @($state.lanes.Keys)) {
        $e = $state.lanes[$key]
        if ($e.guiPid -ne $state.guiPid) { continue }
        $pane = $panes | Where-Object { $_.pane_id -eq $e.paneId -and $_.tab_title -eq $e.laneId } | Select-Object -First 1
        if (-not $pane) { continue }
        $live += [pscustomobject]@{
            Session = $e.session; LaneId = $e.laneId; PaneId = $e.paneId
            WindowId = $pane.window_id; Dir = $e.dir; Project = $e.project
            CwdPath = $pane.CwdPath; Key = $key
        }
    }
    if ($LaneId)  { $live = @($live | Where-Object { $_.LaneId -eq $LaneId }) }
    if ($Session) { $live = @($live | Where-Object { $_.Session -eq $Session }) }
    return $live
}

function Get-LiveTabTitles {
    # Tab titles of every pane in the pinned mux (explicit tab titles survive
    # Claude's OSC window-title rewrites, so these are trustworthy lane markers).
    try { return @(Get-FleetPanes | ForEach-Object tab_title | Where-Object { $_ }) } catch { return @() }
}
