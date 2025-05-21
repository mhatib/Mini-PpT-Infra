Write-Host "Disabling sleep and timeout"
cmd /c powercfg /change monitor-timeout-ac 0
cmd /c powercfg /change monitor-timeout-dc 0
cmd /c powercfg /change standby-timeout-ac 0
cmd /c powercfg /change standby-timeout-dc 0

Write-Host "Increasing virtual memory..."
$pagefile = Get-WmiObject Win32_ComputerSystem -EnableAllPrivileges
$pagefile.AutomaticManagedPagefile = $false
$pagefile.put() | Out-Null
$pagefileset = Get-WmiObject Win32_pagefilesetting
$pagefileset.InitialSize = 24576
$pagefileset.MaximumSize = 49152
$pagefileset.Put() | Out-Null
Gwmi win32_Pagefilesetting | Select Name, InitialSize, MaximumSize
