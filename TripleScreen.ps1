# Profile 2: all three monitors on, with the positions and resolutions saved by setup.
. (Join-Path $PSScriptRoot 'Common.ps1')
try {
    if (-not (Test-Path $TripleCfg)) {
        throw 'TripleScreen.cfg not found. Run Setup-DisplayProfiles.ps1 while all monitors are on.'
    }
    Invoke-MMT -Arguments @('/LoadConfig', $TripleCfg)
} catch {
    Show-ErrorBox $_.Exception.Message
    exit 1
}
