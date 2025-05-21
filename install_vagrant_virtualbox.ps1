iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
iex ((New-Object System.Net.WebClient).DownloadString('https://vcredist.com/install.ps1'))

choco install vagrant --version=2.3.4 -y
choco install virtualbox --version=7.0.8 -y

Write-Host "Restarting computer for changes to take place now."
Write-Host "Run vagrant up within an administrator prompt once restart is complete."
