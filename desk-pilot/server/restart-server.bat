@echo off
setlocal
cd /d "%~dp0"

echo Restarting DeskPilot server...
python -m pip install -r requirements.txt -q

for /f "tokens=2 delims==," %%a in ('wmic process where "CommandLine like '%%desk-pilot%%server.py%%'" get ProcessId /format:list 2^>nul ^| find "ProcessId"') do taskkill /PID %%a /F >nul 2>&1
for /f "tokens=2 delims==," %%a in ('wmic process where "CommandLine like '%%DeskPilot%%server.py%%'" get ProcessId /format:list 2^>nul ^| find "ProcessId"') do taskkill /PID %%a /F >nul 2>&1

ping 127.0.0.1 -n 2 >nul
pythonw "%~dp0ensure_server.py"
echo Server restarted. Check %%LOCALAPPDATA%%\DeskPilot\server.log for IP and PIN.
