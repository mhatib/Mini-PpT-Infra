$ProgressPreference = 'SilentlyContinue'

$urls = @(
    "https://raw.githubusercontent.com/mhatib/custom/main/sysmonconfig.xml",
    "https://download.sysinternals.com/files/Sysmon.zip",
    "https://download.splunk.com/products/universalforwarder/releases/9.0.3/windows/splunkforwarder-9.0.3-dd0128b1f8cd-x64-release.msi",
    "https://download.splunk.com/products/universalforwarder/releases/9.0.3/linux/splunkforwarder-9.0.3-dd0128b1f8cd-linux-2.6-amd64.deb",
    "https://download.splunk.com/products/splunk/releases/9.0.3/linux/splunk-9.0.3-dd0128b1f8cd-linux-2.6-amd64.deb",
    "https://github.com/cyberisltd/NcatPortable/raw/master/ncat.exe",
    "https://nodejs.org/dist/v22.16.0/node-v22.16.0-x64.msi",
    "https://downloads.cursor.com/production/53b99ce608cba35127ae3a050c1738a959750865/win32/x64/user-setup/CursorUserSetup-x64-1.0.0.exe"
)

$destinations = @(
    "setup/setup_files/sysmonconfig-export.xml",
    "setup/setup_files/Sysmon.zip",
    "setup/setup_files/splunkforwarder.msi",
    "setup/setup_files/splunkforwarder.deb",
    "setup/setup_files/splunk.deb",
    "setup/setup_files/ncat.exe",
    "setup/setup_files/node.msi",
    "setup/setup_files/cursor_installer.exe"
)

for ($i = 0; $i -lt $urls.Count; $i++) {
    $url = $urls[$i]
    $dest = $destinations[$i]

    $dir = Split-Path $dest
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    $success = $false
    $attempts = 0
    $maxAttempts = 2

    while (-not $success -and $attempts -lt $maxAttempts) {
        try {
            $attempts++
            Invoke-WebRequest -Uri $url -OutFile $dest -ErrorAction Stop
            Write-Host "Downloaded: $url → $dest"
            $success = $true
        }
        catch {
            Write-Warning "Failed to download $url on attempt $attempts. Error: $_"
            if ($attempts -ge $maxAttempts) {
                Write-Error "Giving up downloading $url after $attempts attempts."
            } else {
                Start-Sleep -Seconds 3
            }
        }
    }
}

Write-Host "All downloads complete!"
