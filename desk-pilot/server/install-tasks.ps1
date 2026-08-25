# Registers DeskPilot scheduled tasks (logon, resume-from-sleep, cold-boot sign-in).

$ErrorActionPreference = "Stop"
$ServerDir = $PSScriptRoot.TrimEnd("\")
$Pythonw = (Get-Command pythonw -ErrorAction SilentlyContinue).Source
if (-not $Pythonw) {
    $Pythonw = (Get-Command python -ErrorAction SilentlyContinue).Source
}
if (-not $Pythonw) {
    Write-Error "Python not found on PATH. Install Python 3.10+ and retry."
}

$User = $env:USERNAME
$EnsureArgs = "`"$ServerDir\ensure_server.py`""
$LoginWatchArgs = "`"$ServerDir\wake_routine.py`" --login-watch"
$ResumeWatchArgs = "`"$ServerDir\wake_routine.py`" --resume-watch"

function New-DeskPilotTaskXml {
    param(
        [string]$Id,
        [string]$Description,
        [string]$Arguments,
        [string]$TriggersXml,
        [string]$RunLevel = "LeastPrivilege"
    )

    $escapedArgs = [System.Security.SecurityElement]::Escape($Arguments)
    $escapedExe = [System.Security.SecurityElement]::Escape($Pythonw)
    $escapedDir = [System.Security.SecurityElement]::Escape($ServerDir)

    return @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Description>$Description</Description>
    <URI>\DeskPilot $Id</URI>
  </RegistrationInfo>
  <Triggers>
$TriggersXml
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>$User</UserId>
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>$RunLevel</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <Enabled>true</Enabled>
    <ExecutionTimeLimit>PT2H</ExecutionTimeLimit>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>$escapedExe</Command>
      <Arguments>$escapedArgs</Arguments>
      <WorkingDirectory>$escapedDir</WorkingDirectory>
    </Exec>
  </Actions>
</Task>
"@
}

function Register-DeskPilotTaskFromXml {
    param([string]$Name, [string]$Xml)
    Unregister-ScheduledTask -TaskName $Name -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
    Register-ScheduledTask -TaskName $Name -Xml $Xml -Force | Out-Null
    Write-Host "  Registered: $Name"
}

$logonTrigger = @'
    <LogonTrigger>
      <Enabled>true</Enabled>
      <Delay>PT10S</Delay>
    </LogonTrigger>
'@

$bootTrigger = @'
    <BootTrigger>
      <Enabled>true</Enabled>
      <Delay>PT45S</Delay>
    </BootTrigger>
'@

$bootServerTrigger = @'
    <BootTrigger>
      <Enabled>true</Enabled>
      <Delay>PT60S</Delay>
    </BootTrigger>
'@

$resumeEvent = @'
    <EventTrigger>
      <Enabled>true</Enabled>
      <Subscription>&lt;QueryList&gt;&lt;Query Id=&quot;0&quot; Path=&quot;System&quot;&gt;&lt;Select Path=&quot;System&quot;&gt;*[System[Provider[@Name='Microsoft-Windows-Kernel-Power'] and EventID=107]]&lt;/Select&gt;&lt;/Query&gt;&lt;/QueryList&gt;</Subscription>
      <Delay>PT15S</Delay>
    </EventTrigger>
'@

Write-Host "DeskPilot - registering background tasks..."
Write-Host "  Python: $Pythonw"
Write-Host ""

Register-DeskPilotTaskFromXml -Name "DeskPilot Server" -Xml (
    New-DeskPilotTaskXml -Id "Server" -Description "Start DeskPilot WebSocket server at login" -Arguments $EnsureArgs -TriggersXml $logonTrigger
)

Register-DeskPilotTaskFromXml -Name "DeskPilot Server Boot" -Xml (
    New-DeskPilotTaskXml -Id "Server Boot" -Description "Start DeskPilot server after cold boot" -Arguments $EnsureArgs -TriggersXml $bootServerTrigger
)

Register-DeskPilotTaskFromXml -Name "DeskPilot Server Resume" -Xml (
    New-DeskPilotTaskXml -Id "Server Resume" -Description "Ensure DeskPilot server after wake from sleep" -Arguments $EnsureArgs -TriggersXml $resumeEvent
)

Register-DeskPilotTaskFromXml -Name "DeskPilot Wake Login" -Xml (
    New-DeskPilotTaskXml -Id "Wake Login" -Description "Sign in after cold boot when configured" -Arguments $LoginWatchArgs -RunLevel "HighestAvailable" -TriggersXml $bootTrigger
)

Register-DeskPilotTaskFromXml -Name "DeskPilot Resume Sign-In" -Xml (
    New-DeskPilotTaskXml -Id "Resume Sign-In" -Description "Enter PIN after resume from sleep when locked" -Arguments $ResumeWatchArgs -RunLevel "HighestAvailable" -TriggersXml $resumeEvent
)

Write-Host ""
Write-Host "Done. Server auto-starts at login and after sleep; sign-in helpers run on boot/resume."
