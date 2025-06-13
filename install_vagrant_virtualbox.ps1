# --- Create Directory and Download NuGet Provider ---

# Define the target directory path
$providerPath = "C:\Program Files\PackageManagement\ProviderAssemblies\nuget\2.8.5.208"

# Define the URL for the DLL file
$providerUrl = "https://onegetcdn.azureedge.net/providers/Microsoft.PackageManagement.NuGetProvider-2.8.5.208.dll"

# Combine the path and filename for the output file
$providerFile = Join-Path $providerPath "Microsoft.PackageManagement.NuGetProvider-2.8.5.208.dll"

# Create the directory. The -Force parameter creates parent directories if they don't exist.
Write-Host "Creating directory: $providerPath"
New-Item -ItemType Directory -Force -Path $providerPath

# Download the NuGet provider DLL into the new directory
Write-Host "Downloading NuGet provider from $providerUrl"
Invoke-WebRequest -Uri $providerUrl -OutFile $providerFile


# Install Chocolatey package manager
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install latest VC Redistributables
iex ((New-Object System.Net.WebClient).DownloadString('https://vcredist.com/install.ps1'))

# Use Chocolatey to install specific versions of Vagrant and VirtualBox
choco install vagrant --version=2.3.4 -y
choco install virtualbox --version=7.0.8 -y

# --- Final Instructions ---

Write-Host "Restarting computer for changes to take place now."
Write-Host "Run vagrant up within an administrator prompt once restart is complete."