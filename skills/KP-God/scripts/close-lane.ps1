# close-lane.ps1 <lane-id> [-Session <name>] [-LaneDir <path>] [-KeepWorktree]
#
# The done-gate's mechanical half, in one command:
#   1. Finds the lane's WezTerm tab(s) and records each working directory.
#      Unlike send-lane, ambiguity is fine here: we are tearing down, so every
#      registered lane with this id (all sessions unless -Session narrows it),
#      PLUS any stray tab titled with this lane-id, is closed.
#   2. Kills the tab(s), so no idle Claude session lingers (lingering tabs
#      leak RAM and cause the duplicate-tab wedge on lane-id reuse).
#   3. If a tab's directory was a leased .kp-worktrees git worktree, removes
#      the worktree (the kp/<lane-id> branch and its commits survive; skipped
#      with -KeepWorktree, e.g. the branch still needs a manual merge from
#      inside it).
#   4. With -LaneDir, stamps the lane's status file `CLOSED | <date>` so the
#      watcher and a fresh conductor read it as finished, not stuck.
#
# Run this when a lane reaches `done` on the board (after the review verdict
# is ship and the handoff/report is written), or to tear down a dead or
# abandoned lane. It does NOT judge doneness; the conductor's done-gate
# checklist does.
param(
    [Parameter(Mandatory, Position = 0)][string]$LaneId,
    [string]$Session,
    [string]$LaneDir,
    [switch]$KeepWorktree
)
. "$PSScriptRoot\_kp-common.ps1"

$workDirs = @()
$closed = 0
if (Connect-Fleet) {
    $paneIds = @(Get-LiveLanes -LaneId $LaneId -Session $Session | ForEach-Object PaneId)
    # stray-tab sweep: a tab titled with the lane-id that the registry lost
    # (e.g. state file wiped) still burns RAM; teardown is greedy
    if (-not $Session) {
        $paneIds += @(Get-FleetPanes | Where-Object { $_.tab_title -eq $LaneId } | ForEach-Object pane_id)
    }
    $paneIds = @($paneIds | Sort-Object -Unique)
    if ($paneIds.Count -eq 0) {
        Write-Output "close-lane: no live tab named '$LaneId' (already gone, that is fine)"
    }
    foreach ($pid_ in $paneIds) {
        $pane = Get-FleetPanes | Where-Object { $_.pane_id -eq $pid_ } | Select-Object -First 1
        if (-not $pane) { continue }
        $workDirs += $pane.CwdPath
        Invoke-Wezterm @('kill-pane', '--pane-id', $pid_) | Out-Null
        Write-Output "closed tab pane $pid_ ($LaneId, was in $($pane.CwdPath))"
        $closed++
    }
} else {
    Write-Output 'close-lane: no fleet GUI running, no tab to close'
}

# fall back to the registry's recorded dir so a dead-GUI close still returns
# the worktree
$state = Read-FleetState
$keys = @($state.lanes.Keys | Where-Object {
    $state.lanes[$_].laneId -eq $LaneId -and (-not $Session -or $state.lanes[$_].session -eq $Session)
})
if ($workDirs.Count -eq 0) {
    foreach ($k in $keys) { $workDirs += $state.lanes[$k].dir }
}

if (-not $KeepWorktree) {
    foreach ($d in ($workDirs | Sort-Object -Unique)) {
        if ($d -and $d -match '\\\.kp-worktrees\\') {
            $project = $d -replace '\\\.kp-worktrees\\.*$', ''
            $eap = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
            try { & git -C $project worktree remove $d --force 2>$null } catch {}
            $ErrorActionPreference = $eap
            if (Test-Path $d) {
                # git's delete dies on node_modules depth ("Filename too long");
                # the \\?\ long-path rmdir handles it, then prune drops the record.
                cmd /c "rmdir /s /q `"\\?\$d`"" 2>$null
                & git -C $project worktree prune
            }
            if (-not (Test-Path $d)) { Write-Output "returned worktree $d" }
            else { Write-Warning "close-lane: could not remove $d (return it manually)" }
        }
    }
}

if ($keys.Count -gt 0) {
    foreach ($k in $keys) { $state.lanes.Remove($k) }
    Write-FleetState $state
}

if ($LaneDir -and (Test-Path $LaneDir -PathType Container)) {
    "CLOSED | $(Get-Date -Format yyyy-MM-dd) lane closed by conductor" | Set-Content (Join-Path $LaneDir 'status') -Encoding utf8
    Write-Output "stamped $LaneDir\status CLOSED"
}
