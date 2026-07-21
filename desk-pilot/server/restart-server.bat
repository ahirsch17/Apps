@echo off
echo Stopping extra DeskPilot server processes...
taskkill /IM python.exe /FI "WINDOWTITLE eq DeskPilot*" /F >nul 2>&1
for /f "tokens=2" %%p in ('tasklist /FI "IMAGENAME eq python.exe" /FO LIST ^| find "PID:"') do (
    wmic process where "ProcessId=%%p" get CommandLine 2>nul | find "server.py" >nul && taskkill /PID %%p /F >nul 2>&1
)
echo Starting one background server...
cd /d "%~dp0"
start "" pythonw server.py
echo Done. You can close all PowerShell windows now.
pause
