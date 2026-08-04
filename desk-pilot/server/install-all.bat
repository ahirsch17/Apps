@echo off
setlocal
cd /d "%~dp0"

echo ====================================================
echo   DeskPilot — full PC setup (one time)
echo ====================================================
echo.

python -m pip install -r requirements.txt -q
if errorlevel 1 (
    echo Failed to install Python dependencies.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-tasks.ps1"
if errorlevel 1 (
    echo Some tasks need Administrator — trying user-level autostart...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0register-user-autostart.ps1"
)

echo.
echo Starting server now...
pythonw "%~dp0ensure_server.py"
ping 127.0.0.1 -n 3 >nul

netsh advfirewall firewall show rule name="DeskPilot Server" >nul 2>&1
if errorlevel 1 (
    echo.
    echo Firewall rule missing — requesting admin for DeskPilot + Remote Desktop...
    powershell -NoProfile -Command "Start-Process -FilePath '%~dp0install-all-elevated.ps1' -Verb RunAs -Wait"
) else (
    echo Firewall rule for DeskPilot already present.
)

echo.
echo ====================================================
echo   Setup complete
echo ====================================================
echo   Phone: pair in DeskPilot Settings (same Wi-Fi)
echo   Mac:   see desk-pilot\docs\MAC_REMOTE.md
echo   Log:   %%LOCALAPPDATA%%\DeskPilot\server.log
echo.
pause
