# --- Network Route Setup ---
try {
    route /p add 111.0.10.0 mask 255.255.255.0 192.168.111.5
    Write-Host "[+] Added IP Route"
} catch {
    Write-Warning "Failed to add IP route: $_"
}

# --- Set Administrator Password ---
try {
    net user Administrator "P@ssw0rd123"
    Write-Host "[+] Administrator password set."
} catch {
    Write-Warning "Failed to set Administrator password: $_"
}

# --- Set Timezone ---
try {
    tzutil /s "Singapore Standard Time"
    Write-Host "[+] Set Timezone to: Singapore Standard Time"
} catch {
    Write-Warning "Failed to set timezone: $_"
}

# --- Configure Firewall Rules ---
try {
    netsh advfirewall firewall add rule name="ICMP Allow incoming V4 echo request" protocol=icmpv4:8,any dir=in action=allow
    netsh advfirewall firewall add rule name="ICMP Allow incoming V6 echo request" protocol=icmpv6:8,any dir=in action=allow
    Write-Host "[+] Configured Firewall"
} catch {
    Write-Warning "Failed to configure firewall rules: $_"
}

# --- Configure Audit Policies ---
try {
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
} catch {
    Write-Warning "Failed to set audit policies: $_"
}

# --- Disable Screensaver / Power Settings ---
try {
    cmd /c powercfg /change monitor-timeout-ac 0
    cmd /c powercfg /change monitor-timeout-dc 0
    cmd /c powercfg /change standby-timeout-ac 0
    cmd /c powercfg /change standby-timeout-dc 0
    Write-Host "[+] Disabled screensaver and standby timeouts"
} catch {
    Write-Warning "Failed to change power settings: $_"
}

# --- Configure PowerShell Logging ---
try {
    Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System\Audit" -Name "ProcessCreationIncludeCmdLine_Enabled" -Value 1

    if (-not (Test-Path "HKLM:\Software\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ModuleLogging")) {
        New-Item "HKLM:\Software\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ModuleLogging" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\Software\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ModuleLogging" -Name "EnableModuleLogging" -Value 1

    if (-not (Test-Path "HKLM:\Software\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ModuleLogging\ModuleNames")) {
        New-Item "HKLM:\Software\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ModuleLogging\ModuleNames" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\Software\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ModuleLogging\ModuleNames" -Name "*" -Value "*"

    if (-not (Test-Path "HKLM:\Software\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging")) {
        New-Item "HKLM:\Software\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\Software\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Name "EnableScriptBlockLogging" -Value 1

    Write-Host "[+] Configured PowerShell Module and ScriptBlock Logging"
} catch {
    Write-Warning "Failed to configure PowerShell logging: $_"
}

# --- Install Node.js MSI ---
$msiPath = "C:\Users\Public\node.msi"
try {
    Write-Host "Installing Node.js from $msiPath"
    
    Start-Process -FilePath "msiexec.exe" `
                  -ArgumentList "/i `"$msiPath`" /quiet /norestart" `
                  -Wait -NoNewWindow

    Write-Host "[+] Node.js installation completed."
} catch {
    Write-Error "Node.js installation failed: $_"
    exit 1
}

# --- Unzip Sysmon and Install ---
try {
    $sysmonZip = "C:\Users\vagrant\Documents\Sysmon.zip"
    $sysmonDir = "C:\Users\vagrant\Documents\Sysmon"

    Expand-Archive -Path $sysmonZip -DestinationPath $sysmonDir -Force
    & "$sysmonDir\Sysmon64.exe" -accepteula -i C:\Windows\config.xml
    Write-Host "[+] Sysmon installed and configured."
} catch {
    Write-Warning "Failed to install Sysmon: $_"
}

# --- Install Splunk Universal Forwarder ---
try {
    $splunkMsi = "C:\Users\vagrant\Documents\splunkforwarder.msi"
    $receivingIndexer = "192.168.111.100:9997"
    $splunkUser = "admin"
    $splunkPass = "password123"
    $agreeLicense = "yes"
    $serviceStartType = "auto"
    $maxRetries = 3
    $retryCount = 0
    $installSuccess = $false

    Write-Host "Installing Splunk Universal Forwarder..."

    while (-not $installSuccess -and $retryCount -lt $maxRetries) {
        $retryCount++
        Write-Host "Attempt $retryCount of $maxRetries..."

        # Check if service already exists
        if (Get-Service -Name "SplunkForwarder" -ErrorAction SilentlyContinue) {
            Write-Host "SplunkForwarder service already exists. Proceeding with configuration..."
            $installSuccess = $true
            break
        }

        # Attempt installation
        $process = Start-Process msiexec.exe -ArgumentList "/i `"$splunkMsi`"",
            "RECEIVING_INDEXER=$receivingIndexer",
            "SET_ADMIN_USER=1",
            "SPLUNKUSERNAME=$splunkUser",
            "SPLUNKPASSWORD=$splunkPass",
            "AGREETOLICENSE=$agreeLicense",
            "LAUNCHSPLUNK=1",
            "SERVICESTARTTYPE=$serviceStartType",
            "/qn" -Wait -PassThru -NoNewWindow

        # Check installation exit code
        if ($process.ExitCode -eq 0) {
            Write-Host "MSI installation completed successfully."
            
            # Wait for service to be created with timeout
            $timeoutSeconds = 300
            $elapsed = 0
            $checkInterval = 10

            while ($elapsed -lt $timeoutSeconds) {
                if (Get-Service -Name "SplunkForwarder" -ErrorAction SilentlyContinue) {
                    Write-Host "SplunkForwarder service found!"
                    $installSuccess = $true
                    break
                }
                Write-Host "Waiting for SplunkForwarder service to be installed... ($elapsed/$timeoutSeconds seconds)"
                Start-Sleep -Seconds $checkInterval
                $elapsed += $checkInterval
            }

            if ($installSuccess) {
                break
            } else {
                Write-Warning "Service not found after $timeoutSeconds seconds."
            }
        } else {
            Write-Warning "MSI installation failed with exit code: $($process.ExitCode)"
        }

        if (-not $installSuccess -and $retryCount -lt $maxRetries) {
            Write-Host "Waiting 20 seconds before next attempt..."
            Start-Sleep -Seconds 20
        }
    }

    if (-not $installSuccess) {
        throw "Failed to install Splunk Universal Forwarder after $maxRetries attempts"
    }

    Write-Host "[+] Splunk Universal Forwarder installed."
} catch {
    Write-Error "Splunk installation failed: $_"
    exit 1
}

# --- Configure Splunk Inputs ---
try {
    $confPath = "C:\Program Files\SplunkUniversalForwarder\etc\apps\SplunkUniversalForwarder\local\inputs.conf"
    $confContent = @'
[WinEventLog://Application]
checkpointInterval = 1
current_only = 0
disabled = 0
start_from = oldest

[WinEventLog://Security]
checkpointInterval = 1
current_only = 0
disabled = 0
start_from = oldest

[WinEventLog://System]
checkpointInterval = 1
current_only = 0
disabled = 0
start_from = oldest

[WinEventLog://ForwardedEvents]
checkpointInterval = 1
current_only = 0
disabled = 0
start_from = oldest

[WinEventLog://Setup]
checkpointInterval = 1
current_only = 0
disabled = 0

[WinEventLog://Windows PowerShell]
disabled = 0
checkpointInterval = 1
start_from = oldest

[WinEventLog://Microsoft-Windows-PowerShell/Operational]
disabled = 0
checkpointInterval = 1
start_from = oldest

[WinEventLog://Microsoft-Windows-Sysmon/Operational]
disabled = false
checkpointInterval = 1
start_from = oldest
'@

    $maxRetries = 3
    $retryCount = 0
    $configSuccess = $false
    $confDir = Split-Path -Parent $confPath

    while (-not $configSuccess -and $retryCount -lt $maxRetries) {
        $retryCount++
        Write-Host "Configuring inputs.conf - Attempt $retryCount of $maxRetries..."

        # Check if directory exists, create if not
        if (-not (Test-Path $confDir)) {
            Write-Host "Creating directory: $confDir"
            New-Item -ItemType Directory -Path $confDir -Force | Out-Null
        }

        # Write the configuration
        try {
            $confContent | Out-File -FilePath $confPath -Encoding ASCII -Force
            
            # Verify the file exists and content is correct
            if (Test-Path $confPath) {
                $fileContent = Get-Content -Path $confPath -Raw
                if ($fileContent -match "\[WinEventLog://Application\]" -and 
                    $fileContent -match "\[WinEventLog://Security\]" -and
                    $fileContent -match "\[WinEventLog://System\]") {
                    Write-Host "[+] Splunk inputs.conf configured successfully."
                    $configSuccess = $true
                    
                    # Try to restart the service
                    try {
                        Restart-Service -Name "SplunkForwarder"
                        Write-Host "[+] Restarted SplunkForwarder service."
                        break
                    } catch {
                        Write-Warning "Failed to restart SplunkForwarder service: $_"
                    }
                } else {
                    Write-Warning "inputs.conf content verification failed."
                }
            } else {
                Write-Warning "inputs.conf was not created successfully."
            }
        } catch {
            Write-Warning "Failed to write inputs.conf: $_"
        }

        if (-not $configSuccess -and $retryCount -lt $maxRetries) {
            Write-Host "Waiting 20 seconds before next attempt..."
            Start-Sleep -Seconds 20
        }
    }

    if (-not $configSuccess) {
        throw "Failed to configure Splunk inputs after $maxRetries attempts"
    }
} catch {
    Write-Warning "Failed to configure Splunk inputs or restart service: $_"
}

# --- Disable Windows Defender Real-Time Protection ---
try {
    #Set-MpPreference -DisableRealtimeMonitoring $true
    #Write-Host "[+] Disabled Real Time Protection"

    Set-MpPreference -MAPSReporting Disabled
    Write-Host "[+] Disabled cloud reporting"

    Set-MpPreference -SubmitSamplesConsent NeverSend
    Write-Host "[+] Disabled sample submission"

    Set-MpPreference -SmartScreenForExplorer Disabled
    Write-Host "[+] Disabled smart screen"

    Write-Host "Adding Windows Defender exclusions"
    $currentExclusions = (Get-MpPreference).ExclusionPath
    if ($currentExclusions -contains "c:\") {
        Remove-MpPreference -ExclusionPath "c:\"
        Write-Host "[+] Removed 'c:\' from exclusions"
    }
    Add-MpPreference -ExclusionPath "C:\Users\Public"
    Add-MpPreference -ExclusionPath "C:\Users\vagrant\Desktop\OTCEP25"
    Add-MpPreference -ExclusionPath "C:\Users\vagrant\Desktop\OTCEP25.zip"
    Add-MpPreference -ExclusionPath "C:\Users\vagrant\AppData\Roaming\Cursor"

    $preferences = Get-MpPreference
    Write-Host "Cloud Protection Status: $($preferences.MAPSReporting)"
    Write-Host "Sample Submission Consent: $($preferences.SubmitSamplesConsent)"
} catch {
    Write-Warning "Failed to configure Windows Defender settings: $_"
}

# --- Manual Cursor Installation ---
$exePath = "C:\Users\Public\cursor.exe"

if (-not (Test-Path $exePath)) {
    Write-Error "Cursor installer not found at $exePath"
    exit 1
}

Write-Host "`n"
Write-Host "=================================================================="
Write-Host "                   MANUAL ACTION REQUIRED                           "
Write-Host "=================================================================="
Write-Host "Please complete the following manual installation step:"
Write-Host "1. Install Cursor IDE by running: C:\Users\Public\cursor.exe"
Write-Host "2. Follow the installation wizard"
Write-Host "=================================================================="
Write-Host "`n"

# --- End of Script ---
Write-Host "Setup script completed." 
