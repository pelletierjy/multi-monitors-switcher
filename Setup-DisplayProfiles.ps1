# Detects the monitors, saves the Triple Screen layout, writes profiles.json,
# and creates the desktop shortcuts. Safe to re-run: generated files are overwritten
# with the current values, so the result is the same every time.
. (Join-Path $PSScriptRoot 'Common.ps1')
Install-MultiMonitorTool

$state =@(Get-MonitorState | Where-Object Connected)

# The layout can only be saved when every monitor is on. A disabled monitor may be missing
# from the listing entirely, so also compare against the monitor count in the existing profile.
$savedCount = 0
if (Test-Path $ProfileFile) {
    $savedCount = @((Get-Content $ProfileFile -Raw | ConvertFrom-Json).Monitors).Count
}
$someOff = (@($state | Where-Object { -not $_.Active }).Count -gt 0) -or ($state.Count -lt $savedCount)
if ($someOff) {
    if (-not (Test-Path $TripleCfg)) {
        throw 'A monitor is off and no TripleScreen.cfg exists. Turn all monitors on in Windows Display Settings first.'
    }
    Invoke-MMT -Arguments @('/LoadConfig', $TripleCfg)
    $state = @(Get-MonitorState | Where-Object Connected)
    if ((@($state | Where-Object { -not $_.Active }).Count -gt 0) -or ($state.Count -lt $savedCount)) {
        throw 'Not all monitors are on after loading TripleScreen.cfg. Turn them on in Display Settings and run setup again.'
    }
}

$center  = Find-CenterMonitor -Monitors $state
$sideIds = @($state | Where-Object Id -ne $center.Id | Sort-Object Left | ForEach-Object Id)

Invoke-MMT -Arguments @('/SaveConfig', $TripleCfg)

[pscustomobject]@{
    GeneratedAt = (Get-Date).ToString('s')
    CenterId    = $center.Id
    CenterModel = $center.Model
    SideIds     = $sideIds
    Monitors    = @($state | ForEach-Object { [pscustomobject]@{ Id = $_.Id; Model = $_.Model; Left = $_.Left; Right = $_.Right } })
} | ConvertTo-Json -Depth 4 | Set-Content -Path $ProfileFile -Encoding UTF8

# Desktop shortcuts. GetFolderPath respects OneDrive desktop redirection.
$desktop = [Environment]::GetFolderPath('Desktop')
$shell   = New-Object -ComObject WScript.Shell
$shortcuts = @(
    @{ Name = 'Central Screen Only'; Target = (Join-Path $Root 'CentralOnly.bat');  Hotkey = 'Ctrl+Alt+1' },
    @{ Name = 'Triple Screens';      Target = (Join-Path $Root 'TripleScreen.bat'); Hotkey = 'Ctrl+Alt+3' }
)
foreach ($s in $shortcuts) {
    $lnk = $shell.CreateShortcut((Join-Path $desktop "$($s.Name).lnk"))
    $lnk.TargetPath       = $s.Target
    $lnk.WorkingDirectory = $Root
    $lnk.WindowStyle      = 7   # minimized
    $lnk.Hotkey           = $s.Hotkey
    $lnk.Description      = "Display profile: $($s.Name)"
    $lnk.Save()
}

Write-Output "Center monitor: $($center.Id) ($($center.Model))"
Write-Output "Side monitors:  $($sideIds -join ', ')"
Write-Output "Saved layout:   $TripleCfg"
Write-Output "Profiles file:  $ProfileFile"
Write-Output "Shortcuts:      $desktop"
