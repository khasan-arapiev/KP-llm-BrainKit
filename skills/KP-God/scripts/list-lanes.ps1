# list-lanes.ps1
# Lists every live fleet lane across all project sessions, one per line:
#   <session>:<lane-id>  pane=<id>  dir=<cwd>
# The Windows-native replacement for `tmux list-windows -a` at conductor boot:
# it tells a fresh conductor which lanes from a previous session are still
# alive (reattach and steer them) versus gone (spawn-lane.ps1 -Resume).
# Registry entries whose tab has died are listed as [TAB GONE] so a fresh
# conductor sees what needs reviving without cross-checking the board.
. "$PSScriptRoot\_kp-common.ps1"

if (-not (Connect-Fleet)) {
    Write-Output 'no fleet GUI running (no lanes are live)'
    exit 0
}
$live = Get-LiveLanes
foreach ($l in ($live | Sort-Object Session, LaneId)) {
    Write-Output ('{0}:{1}  pane={2}  dir={3}' -f $l.Session, $l.LaneId, $l.PaneId, $l.CwdPath)
}
$state = Read-FleetState
$liveKeys = @($live | ForEach-Object Key)
foreach ($k in ($state.lanes.Keys | Where-Object { $liveKeys -notcontains $_ } | Sort-Object)) {
    $e = $state.lanes[$k]
    Write-Output ('{0}:{1}  [TAB GONE]  last dir={2}' -f $e.session, $e.laneId, $e.dir)
}
if ($state.lanes.Count -eq 0) { Write-Output 'no live lanes' }
