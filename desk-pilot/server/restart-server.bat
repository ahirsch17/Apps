@echo off
echo Restarting DeskPilot server with latest code...
cd /d "%~dp0"
python -m pip install -r requirements.txt -q
taskkill /IM python.exe /F >nul 2>&1
taskkill /IM pythonw.exe /F >nul 2>&1
ping 127.0.0.1 -n 2 >nul
start "" pythonw server.py
echo.
echo Server restarted in background. Close this window.
ping 127.0.0.1 -n 3 >nul
