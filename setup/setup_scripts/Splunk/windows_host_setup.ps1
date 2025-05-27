route /p add 111.0.10.0 mask 255.255.255.0 192.168.111.5
Write-Host "[+] Added IP Route"

Tzutil /s "Singapore Standard Time"
Write-Host "[+] Set Timezone to: Singapore Standard Time"

netsh advfirewall firewall add rule name="ICMP Allow incoming V4 echo request" protocol=icmpv4:8,any dir=in action=allow
netsh advfirewall firewall add rule name="ICMP Allow incoming V6 echo request" protocol=icmpv6:8,any dir=in action=allow
Write-Host "[+] Configured Firewall"

auditpol /clear /y

auditpol /set /subcategory:"Kerberos Authentication Service" /failure:enable /success:enable
auditpol /set /subcategory:"Kerberos Service Ticket Operations" /failure:enable

auditpol /set /subcategory:"Computer Account Management" /failure:enable /success:enable
auditpol /set /subcategory:"Other Account Management Events" /failure:enable /success:enable
auditpol /set /subcategory:"User Account Management" /failure:enable /success:enable

auditpol /set /subcategory:"Process Creation" /failure:enable /success:enable
auditpol /set /subcategory:"Process Termination" /failure:enable /success:enable

auditpol /set /subcategory:"Account Lockout" /failure:enable
auditpol /set /subcategory:"Group Membership" /failure:enable /success:enable
auditpol /set /subcategory:"Logoff" /success:enable
auditpol /set /subcategory:"Logon" /failure:enable /success:enable
auditpol /set /subcategory:"Other Logon/Logoff Events" /failure:enable /success:enable
auditpol /set /subcategory:"Special Logon" /failure:enable /success:enable

auditpol /set /subcategory:"Other Object Access Events" /failure:enable /success:enable
auditpol /set /subcategory:"Registry" /failure:enable /success:enable

auditpol /set /subcategory:"Audit Policy Change" /failure:enable /success:enable
auditpol /set /subcategory:"Authentication Policy Change" /failure:enable /success:enable
auditpol /set /subcategory:"Filtering Platform Policy Change" /failure:enable /success:enable
auditpol /set /subcategory:"MPSSVC Rule-Level Policy Change" /failure:enable /success:enable

auditpol /set /subcategory:"Sensitive Privilege Use" /success:enable

auditpol /set /subcategory:"Other System Events" /failure:enable /success:enable
auditpol /set /subcategory:"Security State Change" /success:enable

Write-Host "[+] Set Audit Policies"

cmd /c powercfg /change monitor-timeout-ac 0
cmd /c powercfg /change monitor-timeout-dc 0
cmd /c powercfg /change standby-timeout-ac 0
cmd /c powercfg /change standby-timeout-dc 0

Write-Host "[+] Disabled screensaver"

Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System\Audit" -Name "ProcessCreationIncludeCmdLine_Enabled" -Value 1
if(-not (Test-Path "HKLM:\Software\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ModuleLogging")) { New-Item "HKLM:\Software\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ModuleLogging" -Force }
Set-ItemProperty -Path "HKLM:\Software\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ModuleLogging" -Name "EnableModuleLogging" -Value 1
if(-not (Test-Path "HKLM:\Software\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ModuleLogging\ModuleNames")) { New-Item "HKLM:\Software\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ModuleLogging\ModuleNames" -Force }
Set-ItemProperty -Path "HKLM:\Software\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ModuleLogging\ModuleNames" -Name "*" -Value *
if(-not (Test-Path "HKLM:\Software\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging")) { New-Item "HKLM:\Software\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Force }
Set-ItemProperty -Path "HKLM:\Software\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Name "EnableScriptBlockLogging" -Value 1


# Set password of administrator account for easier RDP
net user Administrator "P@ssw0rd123"

# Unzipping Sysmon
Expand-Archive -Path "C:\Users\vagrant\Documents\Sysmon.zip" -DestinationPath "C:\Users\vagrant\Documents\Sysmon"
cmd /c C:\Users\vagrant\Documents\Sysmon\Sysmon64.exe -accepteula -i C:\Windows\config.xml

$dest = "C:\Users\vagrant\Documents\splunkforwarder.msi"
$RECEIVING_INDEXER="192.168.111.100:9997"
$LOGON_USERNAME="admin"
$LOGON_PASSWORD="password123"
$SET_ADMIN_USER=1
$SPLUNKUSERNAME="admin"
$SPLUNKPASSWORD="password123"
$AGREETOLICENSE="yes"
$LAUNCHSPLUNK=1
$SERVICESTARTTYPE="auto"

msiexec.exe /i $dest RECEIVING_INDEXER=$RECEIVING_INDEXER SET_ADMIN_USER=$SET_ADMIN_USER SPLUNKUSERNAME=$SPLUNKUSERNAME SPLUNKPASSWORD=$SPLUNKPASSWORD AGREETOLICENSE=$AGREETOLICENSE LAUNCHSPLUNK=1 SERVICESTARTTYPE=$SERVICESTARTTYPE /qn
Write-Host "[+] Installing Splunk...script will halt until it is running."

# Wait for Installation to complete
while (-not (Get-WmiObject -Class Win32_Product | Where-Object {$_.name -eq "UniversalForwarder"})) {
  Start-Sleep -Seconds 10
}

$conf = "C:\Program Files\SplunkUniversalForwarder\etc\apps\SplunkUniversalForwarder\local\inputs.conf"

echo @'

[WinEventLog://Application]
checkpointInterval = 5
current_only = 0
disabled = 0
start_from = oldest

[WinEventLog://Security]
checkpointInterval = 5
current_only = 0
disabled = 0
start_from = oldest

[WinEventLog://System]
checkpointInterval = 5
current_only = 0
disabled = 0
start_from = oldest

[WinEventLog://ForwardedEvents]
checkpointInterval = 5
current_only = 0
disabled = 0
start_from = oldest

[WinEventLog://Setup]
checkpointInterval = 5
current_only = 0
disabled = 0

[WinEventLog://Windows PowerShell]
disabled = 0
checkpointInterval = 5
start_from = oldest

[WinEventLog://Microsoft-Windows-PowerShell/Operational]
disabled = 0
checkpointInterval = 5
start_from = oldest

[WinEventLog://Microsoft-Windows-Sysmon/Operational]
disabled = false
checkpointInterval = 5
start_from = oldest

'@ > $conf

# Restart SplunkForwarder to apply configuration
Restart-Service SplunkForwarder

# turn off defender
Set-MpPreference -DisableRealtimeMonitoring $true
Write-Host "[+] Disabled Real Time Protection"
Set-MpPreference -MAPSReporting Disabled
Write-Host "[+] Disabled cloud"
Set-MpPreference -SubmitSamplesConsent NeverSend
Write-Host "[+] Disabled sample submission"

# run AD script
#Write-Host "[+] Running AD Script...machine will restart a few times."
#C:\Users\Public\setup-windows.ps1