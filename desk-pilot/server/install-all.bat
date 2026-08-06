@echo off
setlocal
cd /d "%~dp0"

echo DeskPilot one-time PC setup. After this, use your phone only.
echo You will be asked once for Administrator (firewall + Mac remote desktop).
echo.

python -m pip install -r requirements.txt -q
if errorlevel 1 (
    echo Failed to install Python dependencies.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath 'powershell.exe' -Verb RunAs -Wait -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0install-all-elevated.ps1\"'"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0register-user-autostart.ps1"
pythonw "%~dp0ensure_server.py"
ping 127.0.0.1 -n 2 >nul

echo.
echo Done. Pair once in the iPhone app, then control power/trackpad from the phone.
echo Do not run start.bat for daily use — server starts at login and after sleep.
echo.
pause
