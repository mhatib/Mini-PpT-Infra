# Check for admin privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole] "Administrator")) {
    Write-Warning "You must run this script as Administrator."
    exit 1
}

# --- Create Directory and Download NuGet Provider ---
$providerPath = "C:\Program Files\PackageManagement\ProviderAssemblies\nuget\2.8.5.208"
$providerUrl = "https://onegetcdn.azureedge.net/providers/Microsoft.PackageManagement.NuGetProvider-2.8.5.208.dll"
$providerFile = Join-Path $providerPath "Microsoft.PackageManagement.NuGetProvider-2.8.5.208.dll"

try {
    Write-Host "Creating directory: $providerPath"
    New-Item -ItemType Directory -Force -Path $providerPath | Out-Null

    Write-Host "Downloading NuGet provider from $providerUrl"
    Invoke-WebRequest -Uri $providerUrl -OutFile $providerFile
} catch {
    Write-Warning "Failed to create directory or download NuGet provider: $_"
}

# Install Chocolatey if not installed
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    try {
        Write-Host "Installing Chocolatey package manager..."
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    } catch {
        Write-Error "Chocolatey installation failed: $_"
        exit 1
    }
} else {
    Write-Host "Chocolatey is already installed."
}

# Install latest Visual C++ Redistributables
try {
    Write-Host "Installing latest Visual C++ Redistributables..."
    iex ((New-Object System.Net.WebClient).DownloadString('https://vcredist.com/install.ps1'))
} catch {
    Write-Warning "Failed to install Visual C++ Redistributables: $_"
}

# Helper function to check installed Chocolatey package version
function Get-ChocoPackageVersion($packageName) {
    $pkg = choco list --local-only | Where-Object { $_ -match "^$packageName\s" }
    if ($pkg) {
        $version = $pkg -replace "$packageName\s", ""
        return $version.Trim()
    }
    return $null
}

# Desired versions
$vagrantVersion = "2.3.4"
$virtualboxVersion = "7.0.8"

# Install or upgrade Vagrant
$currentVagrantVersion = Get-ChocoPackageVersion "vagrant"
if ($currentVagrantVersion -ne $vagrantVersion) {
    Write-Host "Installing Vagrant version $vagrantVersion..."
    choco install vagrant --version=$vagrantVersion -y --force
} else {
    Write-Host "Vagrant version $vagrantVersion is already installed."
}

# Install or upgrade VirtualBox
$currentVBVersion = Get-ChocoPackageVersion "virtualbox"
if ($currentVBVersion -ne $virtualboxVersion) {
    Write-Host "Installing VirtualBox version $virtualboxVersion..."
    choco install virtualbox --version=$virtualboxVersion -y --force
} else {
    Write-Host "VirtualBox version $virtualboxVersion is already installed."
}

# Prompt for restart
Write-Host
Write-Host "Installation steps complete."
Write-Host "Please restart your computer for changes to take effect."
$answer = Read-Host "Restart now? (Y/N)"
if ($answer -match '^[Yy]') {
    Write-Host "Restarting computer..."
    Restart-Computer
} else {
    Write-Host "Please remember to restart the computer later."
}
