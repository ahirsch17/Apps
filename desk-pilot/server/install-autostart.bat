@echo off
setlocal
cd /d "%~dp0"

echo DeskPilot — install background auto-start
echo.

python -m pip install -r requirements.txt -q
if errorlevel 1 (
    echo Failed to install Python dependencies.
    pause
    exit /b 1
)

set "SERVER_DIR=%~dp0"
set "PYTHONW="
for /f "delims=" %%i in ('where pythonw 2^>nul') do set "PYTHONW=%%i"
if "%PYTHONW%"=="" set "PYTHONW=pythonw"

schtasks /Delete /TN "DeskPilot Server" /F >nul 2>&1
schtasks /Create /TN "DeskPilot Server" /TR "\"%PYTHONW%\" \"%SERVER_DIR%server.py\"" /SC ONLOGON /RL LIMITED /F
if errorlevel 1 (
    echo Could not create scheduled task. Try running as Administrator.
    pause
    exit /b 1
)

echo.
echo Done. DeskPilot server will start automatically when you log in.
echo.
echo IMPORTANT: Right-click allow-firewall.bat ^> Run as administrator
echo so your phone can reach this PC over Wi-Fi.
echo.
start "" "%PYTHONW%" "%SERVER_DIR%server.py"
echo.
echo Check pairing info in: %%LOCALAPPDATA%%\DeskPilot\server.log
echo Or run server.py once in a terminal to see IP, MAC, and PIN.
echo.
pause
