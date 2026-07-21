@echo off
schtasks /Delete /TN "DeskPilot Server" /F
echo DeskPilot auto-start removed.
pause
