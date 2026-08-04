# Enable Windows Remote Desktop (for Mac Microsoft Remote Desktop app).
# Run as Administrator (install-all.bat prompts).

$ErrorActionPreference = "Stop"

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $isAdmin) {
    Write-Warning "Run as Administrator to enable Remote Desktop and firewall rules."
    exit 1
}

Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -Value 1

Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue

Set-Service -Name TermService -StartupType Automatic
Start-Service -Name TermService -ErrorAction SilentlyContinue

$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
    $_.IPAddress -notlike "127.*" -and $_.PrefixOrigin -ne "WellKnown" -and $_.InterfaceAlias -notmatch "Bluetooth"
} | Select-Object -First 1).IPAddress

Write-Host ""
Write-Host "Remote Desktop is enabled."
Write-Host "  Local IP (same Wi-Fi as Mac): $ip"
Write-Host "  Mac app: Microsoft Remote Desktop (App Store)"
Write-Host "  For access away from home, install Tailscale on both machines (see docs/MAC_REMOTE.md)"
Write-Host ""
