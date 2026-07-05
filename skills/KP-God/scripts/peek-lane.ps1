# peek-lane.ps1 [-Session <name>] <lane-id> [-Lines <n>]
# Prints the last <n> lines (default 40) of a live lane's screen, so the
# conductor can glance at a stuck lane without touching the GUI.
# The Windows-native replacement for `tmux capture-pane -p`.
param(
    [string]$Session,
    [Parameter(Mandatory, Position = 0)][string]$LaneId,
    [int]$Lines = 40
)
. "$PSScriptRoot\_kp-common.ps1"

if (-not (Connect-Fleet)) { Write-Error 'peek-lane: no fleet GUI running'; exit 1 }
$hits = Get-LiveLanes -LaneId $LaneId -Session $Session
if ($hits.Count -eq 0) { Write-Error "peek-lane: no live lane '$LaneId'"; exit 1 }
if ($hits.Count -gt 1) { Write-Error "peek-lane: '$LaneId' is live in multiple sessions, pass -Session"; exit 1 }
$text = Invoke-Wezterm @('get-text', '--pane-id', $hits[0].PaneId)
$text | Select-Object -Last $Lines
