@echo off
echo DeskPilot — enable Wake-on-LAN on this PC
echo.
echo Run this script as Administrator.
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$adapter = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.PhysicalMediaType -ne 'Unspecified' } | Select-Object -First 1; " ^
  "if (-not $adapter) { Write-Host 'No active network adapter found.' -ForegroundColor Red; exit 1 }; " ^
  "Write-Host ('Adapter: ' + $adapter.Name); " ^
  "Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName 'Wake on Magic Packet' -DisplayValue 'Enabled' -ErrorAction SilentlyContinue; " ^
  "Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName 'Wake on Magic Packet' -RegistryKeyword '*WakeOnMagicPacket' -RegistryValue 1 -ErrorAction SilentlyContinue; " ^
  "powercfg /deviceenablewake '%($adapter.Name)%' 2>$null; " ^
  "$mac = (Get-NetAdapter -Name $adapter.Name).MacAddress; " ^
  "Write-Host ('MAC address: ' + $mac); " ^
  "Write-Host ''; " ^
  "Write-Host 'Done. Also check BIOS for Wake-on-LAN / ErP settings.' -ForegroundColor Green"

echo.
pause
