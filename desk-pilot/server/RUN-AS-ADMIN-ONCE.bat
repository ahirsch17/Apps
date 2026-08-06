@echo off
:: Re-run only if autostart or firewall broke. Not for daily use.
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath 'powershell.exe' -Verb RunAs -Wait -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0install-all-elevated.ps1\"'"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0register-user-autostart.ps1"
pythonw "%~dp0ensure_server.py"
echo Done.
pause
