# Adapted from https://github.com/CSAdev-engenuity/AdversaryEmulation/blob/main/vm_setup_scripts/windows_server/setup-dc.ps1

# Step 1
if ($env:COMPUTERNAME -ne "host") {
    $password = "P@ssw0rd123"
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name 'DefaultUserName' -Type String -Value "Administrator";
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name 'DefaultPassword' -Type String -Value $password;
    New-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name 'AutoAdminLogon' -Type String -Value "1";

    #Replace username and userID placeholders in Scheduled Task XML file with local values
    $sid = ([System.Security.Principal.WindowsIdentity]::GetCurrent()).User.Value;
    ((Get-Content -Path C:\Users\Public\SetupWindows.xml -Raw) -Replace '{WHOAMI}',(whoami)) -Replace '{SID}',$sid | Set-Content -Path C:\Users\Public\SetupWindows.xml;
    #Then use XML file to create Scheduled Task to continue setup process after reboots
    Register-ScheduledTask -TaskName 'SetupWindows' -XML (Get-Content -Path C:\Users\Public\SetupWindows.xml | Out-String);

    #Install Emulation and Detection tools, can consider to install these later
    # powershell -ep bypass C:\Users\Public\install-tools.ps1;

    Start-Sleep -Seconds 3;
    Rename-Computer -NewName "host" -Restart
} 
# Step 2
elseif ((Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem).Domain -ne "CSA.local") {
    #Add domain name to auto login
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name 'DefaultDomainName' -Type String -Value "CSA";

    # Set DC as DNS Server
    Set-DnsClientServerAddress -InterfaceAlias "Ethernet 2" -ServerAddresses ("192.168.111.150") # Set DC's IP as a DNS server 
    
    # Test if DC is successfully set up, if not sleep for 60 seconds
    while (-not (Test-Connection dc.CSA.local -Count 1 -Quiet)) {
        Write-Host "[i] Waiting for DC to be set up..."
        Start-Sleep -Seconds 60;
    }
    Write-Host "[i] DC Set up done!"

    # Join the AD as host
    $joinCred = New-Object pscredential -ArgumentList ([pscustomobject]@{
        UserName = $null
        Password = (ConvertTo-SecureString -String 'ws1Passw0rd!' -AsPlainText -Force)[0]
      })
    
    # DC needs to restart, so joining the domain might fail
    while (-not (Add-Computer -Domain "CSA.local" -Options UnsecuredJoin,PasswordPass -Credential $joinCred -Restart)) {
        Write-Host "[i] Waiting for DC to be boot up..."
        Start-Sleep -Seconds 30;
    }
}   
# Step 3
else {
        Unregister-ScheduledTask -TaskName 'SetupWindows' -Confirm:$false;
        Write-Host "[i] Deleted SetupWindows scheduled task";

        #Remove Autologon creds
        Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name 'DefaultUserName' -Type String -Value "";
        Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name 'DefaultPassword' -Type String -Value "";
        Remove-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name 'AutoAdminLogon';
        Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name 'DefaultDomainName' -Type String -Value "";
        Write-Host "[i] Removed autologon credentials.";
}