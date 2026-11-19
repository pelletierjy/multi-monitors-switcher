# Profile 1: only the center monitor stays on. Side monitors are switched off.
. (Join-Path $PSScriptRoot 'Common.ps1')
try {
    $profile = Read-Profile
    Invoke-MMT -Arguments @('/SetPrimary', $profile.CenterId)
    foreach ($id in $profile.SideIds) {
        Invoke-MMT -Arguments @('/disable', $id)
    }
} catch {
    Show-ErrorBox $_.Exception.Message
    exit 1
}
