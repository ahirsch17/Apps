# Admin-only steps: firewall + Remote Desktop. Launched with elevation from install-all.bat.

$ServerDir = $PSScriptRoot
& netsh advfirewall firewall delete rule name="DeskPilot Server" | Out-Null
& netsh advfirewall firewall add rule name="DeskPilot Server" dir=in action=allow protocol=TCP localport=8765 profile=private | Out-Null
Write-Host "DeskPilot firewall rule added (port 8765, private networks)."

& "$ServerDir\enable-remote-desktop.ps1"
