@echo off
cd /d "%~dp0"
echo Installing DeskPilot server dependencies...
python -m pip install -r requirements.txt
echo.
echo Starting DeskPilot server...
python server.py
pause
