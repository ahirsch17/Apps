# User-level autostart: Run registry entry only (always works, no admin).
# Logon/resume scheduled tasks are registered by install-all-elevated.ps1 (one UAC).

$ErrorActionPreference = "Stop"
$ServerDir = $PSScriptRoot
$Pythonw = (Get-Command pythonw -ErrorAction SilentlyContinue).Source
if (-not $Pythonw) {
    $Pythonw = (Get-Command python -ErrorAction SilentlyContinue).Source
}
if (-not $Pythonw) {
    Write-Error "Python not found on PATH."
}

$EnsureArgs = "`"$ServerDir\ensure_server.py`""
$runKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$runValue = "`"$Pythonw`" $EnsureArgs"
Set-ItemProperty -Path $runKey -Name "DeskPilot" -Value $runValue -Type String
Write-Host "DeskPilot Run key set (starts server at every Windows sign-in)."
