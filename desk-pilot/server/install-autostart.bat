@echo off
setlocal
cd /d "%~dp0"

echo DeskPilot — install background auto-start
echo.
echo Prefer install-all.bat for full setup (tasks + firewall + Mac remote).
echo.

call "%~dp0install-all.bat"
