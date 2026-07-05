# watch-lanes.ps1 <lanes-dir> [timeout-seconds]
# Zero-token supervision: sleeps on the lanes' status files and exits the
# moment any of them changes, so the conductor (who runs this as a background
# task) is woken by the harness notification instead of polling.
#
# Also watches lane LIVENESS: a lane whose status says it should have a live
# session (RUNNING / REVIEW-READY / FORK / HEAVY / BLOCKED) but whose WezTerm
# tab has disappeared is marked [TAB GONE] - that transition wakes the
# conductor too, so a crashed or killed lane is caught in one poll interval
# instead of at the timeout heartbeat. Recover it with spawn-lane.ps1 -Resume.
#
# Output lines add the status file's age (how long the lane has sat in this
# state); age is display-only and never triggers a wake by itself.
# Exit 0: something changed (diff printed). Exit 2: timeout heartbeat, no change.
param(
    [Parameter(Mandatory, Position = 0)][string]$LanesDir,
    [Parameter(Position = 1)][int]$TimeoutSeconds = 1800
)
. "$PSScriptRoot\_kp-common.ps1"
$ErrorActionPreference = 'Continue'
$interval = 15

function Get-WatchTabs {
    if (-not (Connect-Fleet)) { return @() }
    return Get-LiveTabTitles
}

# Comparison snapshot: status line + tab liveness. Deliberately excludes
# age/mtime so a rewrite of the same status or mere passage of time never
# causes a spurious wake.
function Get-Snapshot {
    param([switch]$WithAge)
    $tabs = Get-WatchTabs
    $lines = @()
    foreach ($f in (Get-ChildItem -Path (Join-Path $LanesDir '*\status') -ErrorAction SilentlyContinue)) {
        $lane  = Split-Path (Split-Path $f.FullName) -Leaf
        $line  = (Get-Content $f.FullName -TotalCount 1 -ErrorAction SilentlyContinue)
        if ($null -eq $line) { $line = '' }
        $state = ($line -split '[ |]')[0]
        $flag  = ''
        if ($state -in @('RUNNING', 'REVIEW-READY', 'FORK', 'HEAVY', 'BLOCKED') -and $tabs -notcontains $lane) {
            $flag = ' [TAB GONE]'
        }
        if ($WithAge) {
            $secs = [int]((Get-Date) - $f.LastWriteTime).TotalSeconds
            if ($secs -ge 3600)   { $age = '{0}h{1}m' -f [math]::Floor($secs / 3600), [math]::Floor(($secs % 3600) / 60) }
            elseif ($secs -ge 60) { $age = '{0}m' -f [math]::Floor($secs / 60) }
            else                  { $age = "${secs}s" }
            $lines += "${lane}: $line$flag (in state $age)"
        } else {
            $lines += "${lane}: $line$flag"
        }
    }
    return ($lines -join "`n")
}

$base = Get-Snapshot
$elapsed = 0
while ($elapsed -lt $TimeoutSeconds) {
    Start-Sleep -Seconds $interval
    $elapsed += $interval
    $now = Get-Snapshot
    if ($now -ne $base) {
        Write-Output '=== lane status changed ==='
        $baseLines = $base -split "`n"
        $nowLines  = $now -split "`n"
        foreach ($l in $baseLines) { if ($nowLines -notcontains $l -and $l) { Write-Output "< $l" } }
        foreach ($l in $nowLines)  { if ($baseLines -notcontains $l -and $l) { Write-Output "> $l" } }
        Write-Output '=== all lanes now ==='
        Write-Output (Get-Snapshot -WithAge)
        exit 0
    }
}
Write-Output "=== watcher timeout (${TimeoutSeconds}s), no status changes ==="
Write-Output (Get-Snapshot -WithAge)
exit 2
