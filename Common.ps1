# Shared helpers for the display profile scripts. Dot-source this file.
$ErrorActionPreference = 'Stop'

$Root        = 'C:\Tools\DisplayProfiles'
$Mmt         = Join-Path $Root 'MultiMonitorTool\MultiMonitorTool.exe'
$Snapshot    = Join-Path $Root 'monitors-snapshot.csv'
$TripleCfg   = Join-Path $Root 'TripleScreen.cfg'
$ProfileFile = Join-Path $Root 'profiles.json'

function Invoke-MMT {
    param([string[]]$Arguments)
    $p = Start-Process -FilePath $Mmt -ArgumentList $Arguments -Wait -PassThru -WindowStyle Hidden
    if ($p.ExitCode -ne 0) {
        throw "MultiMonitorTool exited with code $($p.ExitCode) for: $($Arguments -join ' ')"
    }
}

function Install-MultiMonitorTool {
    # Downloads NirSoft MultiMonitorTool into MultiMonitorTool\ if it is not already there.
    if (Test-Path $Mmt) { return }
    $dir = Split-Path $Mmt
    $zip = Join-Path $env:TEMP 'multimonitortool-x64.zip'
    Invoke-WebRequest -Uri 'https://www.nirsoft.net/utils/multimonitortool-x64.zip' -OutFile $zip -UseBasicParsing
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Expand-Archive -Path $zip -DestinationPath $dir -Force
    Remove-Item $zip
    if (-not (Test-Path $Mmt)) { throw "MultiMonitorTool download did not produce $Mmt" }
}

function Get-MonitorState {
    # Every monitor MultiMonitorTool knows about, active or not.
    Invoke-MMT -Arguments @('/scomma', $Snapshot)
    Import-Csv $Snapshot | ForEach-Object {
        $lt = $_.'Left-Top' -split ','
        $rb = $_.'Right-Bottom' -split ','
        [pscustomobject]@{
            Id        = $_.Name
            Model     = $_.'Monitor Name'
            Active    = $_.Active -eq 'Yes'
            Connected = $_.Disconnected -eq 'No'
            Primary   = $_.Primary -eq 'Yes'
            Left      = [int]$lt[0].Trim()
            Right     = [int]$rb[0].Trim()
        }
    }
}

function Find-CenterMonitor {
    # The monitor whose horizontal midpoint is closest to the midpoint of the whole layout.
    # Ties go to the primary monitor.
    param([object[]]$Monitors)
    $layoutLeft   = ($Monitors | Measure-Object Left -Minimum).Minimum
    $layoutRight  = ($Monitors | Measure-Object Right -Maximum).Maximum
    $layoutCenter = ($layoutLeft + $layoutRight) / 2
    $Monitors |
        Sort-Object @{ Expression = { [math]::Abs((($_.Left + $_.Right) / 2) - $layoutCenter) } },
                    @{ Expression = { -[int]$_.Primary } } |
        Select-Object -First 1
}

function Read-Profile {
    if (-not (Test-Path $ProfileFile)) {
        throw "profiles.json not found. Run Setup-DisplayProfiles.ps1 first."
    }
    $profile = Get-Content $ProfileFile -Raw | ConvertFrom-Json
    # Side monitors are not checked here: MultiMonitorTool stops listing a monitor once it is
    # disabled, so their absence is normal. The center monitor must always be listed.
    $listed = Get-MonitorState | Where-Object Connected | ForEach-Object Id
    if ($profile.CenterId -notin $listed) {
        throw "Center monitor $($profile.CenterId) from profiles.json is not connected. Re-run Setup-DisplayProfiles.ps1."
    }
    $profile
}

function Show-ErrorBox {
    param([string]$Message)
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show($Message, 'Display profile error', 'OK', 'Error') | Out-Null
}
