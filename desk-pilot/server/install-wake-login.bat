@echo off
setlocal
cd /d "%~dp0"

echo DeskPilot — install wake / sign-in helper
echo.
echo This helps sign into Windows after wake.
echo Works best when the PC sleeps instead of fully shutting down.
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

schtasks /Delete /TN "DeskPilot Wake Login" /F >nul 2>&1
schtasks /Create /TN "DeskPilot Wake Login" /TR "\"%PYTHONW%\" \"%SERVER_DIR%wake_routine.py\" --login-watch" /SC ONSTART /DELAY 0001:00 /RU "%USERNAME%" /RL HIGHEST /F
if errorlevel 1 (
    echo Could not create wake helper task. Try running as Administrator.
    pause
    exit /b 1
)

echo.
echo Done. After a cold boot, Windows may still need up to 60 seconds before PIN entry.
echo Use Sleep instead of Shutdown for the most reliable phone wake flow.
echo.
pause
