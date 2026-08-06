# Admin-only steps (run once with UAC): firewall, Remote Desktop, resume/wake tasks, logon autostart.

$ServerDir = $PSScriptRoot

& netsh advfirewall firewall delete rule name="DeskPilot Server" | Out-Null
& netsh advfirewall firewall add rule name="DeskPilot Server" dir=in action=allow protocol=TCP localport=8765 profile=private | Out-Null
Write-Host "DeskPilot firewall rule added (port 8765, private networks)."

& "$ServerDir\enable-remote-desktop.ps1"
& "$ServerDir\install-tasks.ps1"
& "$ServerDir\register-user-autostart.ps1"

Write-Host "Admin setup complete. You should not need to run PC commands again for daily phone control."
