$ProgressPreference = 'SilentlyContinue'

$urls = @(
    #"https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml",
    "https://raw.githubusercontent.com/mhatib/custom/main/sysmonconfig.xml",
    "https://download.sysinternals.com/files/Sysmon.zip",
    "https://download.splunk.com/products/universalforwarder/releases/9.0.3/windows/splunkforwarder-9.0.3-dd0128b1f8cd-x64-release.msi",
    "https://download.splunk.com/products/universalforwarder/releases/9.0.3/linux/splunkforwarder-9.0.3-dd0128b1f8cd-linux-2.6-amd64.deb",
    "https://download.splunk.com/products/splunk/releases/9.0.3/linux/splunk-9.0.3-dd0128b1f8cd-linux-2.6-amd64.deb"
    #"https://github.com/docker/compose/releases/download/v2.18.1/docker-compose-linux-x86_64",
    #"https://github.com/SecurityRiskAdvisors/VECTR/releases/download/ce-8.8.1/sra-vectr-runtime-8.8.1-ce.zip"
)

$destinations = @(
    "setup/setup_files/sysmonconfig-export.xml",
    "setup/setup_files/Sysmon.zip",
    "setup/setup_files/splunkforwarder.msi",
    "setup/setup_files/splunkforwarder.deb",
    "setup/setup_files/splunk.deb"
    # "setup/setup_files/attacker/docker-compose",
    # "setup/setup_files/attacker/sra-vectr-runtime-8.8.1-ce.zip"
)

for ($i = 0; $i -lt $urls.Count; $i++) {
    $url = $urls[$i]
    $dest = $destinations[$i]
    Invoke-WebRequest -Uri $url -OutFile $dest
    Write-Host "File downloaded from $url and saved to $dest"
}

Write-Host "Downloads complete!"