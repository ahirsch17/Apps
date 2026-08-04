@echo off
setlocal
cd /d "%~dp0"

echo DeskPilot wake/sign-in tasks are installed by install-all.bat / install-tasks.ps1.
echo Running full setup...
echo.
call "%~dp0install-all.bat"
