@echo off
:: Double-click this once and choose Yes on the UAC prompt.
cd /d "%~dp0"
echo Enabling Remote Desktop, firewall (8765 + RDP), and DeskPilot scheduled tasks...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0enable-remote-desktop.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-all-elevated.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-tasks.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0register-user-autostart.ps1"
echo.
echo Done. Press any key to close.
pause >nul
