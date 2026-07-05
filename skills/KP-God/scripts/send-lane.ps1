# send-lane.ps1 [-Session <name>] <lane-id> <text...>
#
# Types a message into a live lane's Claude session and presses Enter.
# A lane lives in a WezTerm TAB whose title is the lane-id; the lane -> session
# mapping lives in the fleet registry, so you normally only pass the lane-id.
# Pass -Session <name> to disambiguate if the same lane-id exists in two
# projects. Keep text short: for anything substantial, write the lane's
# inbox.md and send "Read your inbox.md and act on it."
param(
    [string]$Session,
    [Parameter(Mandatory, Position = 0)][string]$LaneId,
    [Parameter(Mandatory, Position = 1, ValueFromRemainingArguments)][string[]]$Text
)
. "$PSScriptRoot\_kp-common.ps1"

if (-not (Connect-Fleet)) { Write-Error 'send-lane: no WezTerm fleet GUI is running (no lane can be live)'; exit 1 }

$hits = Get-LiveLanes -LaneId $LaneId -Session $Session
if ($hits.Count -eq 0) {
    $where = if ($Session) { "in session '$Session'" } else { 'in any session' }
    Write-Error "send-lane: no live lane '$LaneId' $where (list-lanes.ps1 shows what is alive; spawn-lane.ps1 -Resume revives a dead one)"; exit 1
}
if ($hits.Count -gt 1) {
    Write-Error @"
send-lane: lane '$LaneId' is live in multiple sessions: $(@($hits | ForEach-Object Session) -join ', ')
  re-run with: send-lane.ps1 -Session <name> $LaneId <text>
"@
    exit 1
}

$lane = $hits[0]
$msg = $Text -join ' '
Invoke-Wezterm @('send-text', '--pane-id', $lane.PaneId, '--no-paste', '--', $msg) | Out-Null
Start-Sleep -Seconds 1
Invoke-Wezterm @('send-text', '--pane-id', $lane.PaneId, '--no-paste', '--', "`r") | Out-Null
Write-Output "sent to $($lane.Session):$LaneId (pane $($lane.PaneId))"
