@echo off
echo Adding Windows Firewall rule for DeskPilot (port 8765, private networks)...
netsh advfirewall firewall delete rule name="DeskPilot Server" >nul 2>&1
netsh advfirewall firewall add rule name="DeskPilot Server" dir=in action=allow protocol=TCP localport=8765 profile=private
if errorlevel 1 (
    echo Failed. Right-click this file and choose Run as administrator.
    pause
    exit /b 1
)
echo Done. Phone should now reach this PC on port 8765 over Wi-Fi.
pause
