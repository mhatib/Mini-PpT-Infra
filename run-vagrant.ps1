$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$flagFile = "$env:ProgramData\MiniPpT-Infra\setup-status.txt"

if (-not (Test-Path $flagFile)) {
New-Item -Path (Split-Path $flagFile) -ItemType Directory -Force | Out-Null
New-Item -Path $flagFile -ItemType File -Force | Out-Null
}

function HasStepCompleted($step) {
Get-Content $flagFile | Select-String -SimpleMatch $step
}

function MarkStepCompleted($step) {
Add-Content $flagFile $step
}

function Ensure-AllVMsRunning {
$result = & vagrant status --machine-readable
return ($result -match ',state,running').Count -ge 2
}

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole] "Administrator")) {
Write-Warning "Please run this script as Administrator."
exit 1
}

try {
# 1. Install prerequisites
if (-not (HasStepCompleted "prereqs_installed")) {
Write-Host "`n[+] Installing prerequisites..."
& "$scriptDir\setup\setup_scripts\prereqs.ps1"
Write-Host "`n[!] A reboot is required. Please reboot manually, then re-run this script to continue."
MarkStepCompleted "prereqs_installed"
exit 0
}

# 2. Download setup files
if (-not (HasStepCompleted "downloads_done")) {
Write-Host "`n[+] Running downloads script..."
& "$scriptDir\setup\setup_scripts\downloads.ps1"
MarkStepCompleted "downloads_done"
Write-Host "`n[+] Downloads completed."
}

# 3. Apply system tweaks
if (-not (HasStepCompleted "tweaks_applied")) {
Write-Host "`n[+] Applying system performance tweaks..."
& "$scriptDir\setup\setup_scripts\system_tweaks.ps1"
MarkStepCompleted "tweaks_applied"
Write-Host "[+] Tweaks applied."
}

# 4. Vagrant Up
if (-not (HasStepCompleted "vagrant_up_done")) {
Write-Host "`n[+] Starting Vagrant environment..."
Push-Location $scriptDir

& vagrant up

if (Ensure-AllVMsRunning) {
Write-Host "[+] All VMs started successfully."
MarkStepCompleted "vagrant_up_done"
} else {
Write-Warning "`n[!] One or more VMs did not start successfully."
Write-Host " - You can troubleshoot using: 'vagrant status' or 'vagrant reload --provision'"
Write-Host " - Re-run this script after resolving the issue."
exit 1
}

Pop-Location
} else {
# If previously marked done, still verify state
Push-Location $scriptDir
if (-not (Ensure-AllVMsRunning)) {
Write-Warning "`n[!] Vagrant was marked as done but some VMs are not running."
Write-Host " - Re-attempting to bring them up..."
& vagrant up
if (-not (Ensure-AllVMsRunning)) {
Write-Error "[!] VMs are still not running. Please fix manually and re-run the script."
exit 1
}
}
Pop-Location
}

Write-Host "`n[!] Setup complete. All systems go."
} catch {
Write-Error "`n[!] An error occurred: $($_.Exception.Message)"
exit 1
}