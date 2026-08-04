# User-level autostart (no admin): logon task + Run key for ensure_server.py

$ErrorActionPreference = "Stop"
$ServerDir = $PSScriptRoot
$Pythonw = (Get-Command pythonw -ErrorAction SilentlyContinue).Source
if (-not $Pythonw) {
    $Pythonw = (Get-Command python -ErrorAction SilentlyContinue).Source
}

$ensure = "`"$Pythonw`" `"$ServerDir\ensure_server.py`""
$runKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
Set-ItemProperty -Path $runKey -Name "DeskPilot" -Value $ensure -Type String

& schtasks.exe /Delete /TN "DeskPilot Server" /F 2>&1 | Out-Null
$create = & schtasks.exe /Create /TN "DeskPilot Server" /TR $ensure /SC ONLOGON /DELAY 0000:20 /F 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Warning "schtasks logon task failed (Run key still set): $create"
} else {
    Write-Host "Registered DeskPilot Server logon task."
}
Write-Host "DeskPilot will start at login via Run key and scheduled task."
