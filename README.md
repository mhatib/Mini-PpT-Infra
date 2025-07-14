# Mini-PpT-Infra

This repository sets up a mini production-like SIEM infrastructure using Vagrant and VirtualBox.

## 📁 Project Structure

```
Mini-PpT-Infra/
│
├── run-vagrant.ps1                     # ✅ Main wrapper script to automate the full setup
├── Vagrantfile                         # ⚙️ Defines the two VMs: 'siem' (Linux) and 'host' (Windows)
│
└── setup/
    ├── setup_scripts/
    │   ├── prereqs.ps1                 # 📦 Installs dependencies: Chocolatey, Vagrant, VirtualBox, VC Redistributables
    │   ├── downloads.ps1               # ⬇️ Downloads necessary setup files (e.g., Splunk, Sysmon, configs)
    │   ├── system_tweaks.ps1           # 🛠️ Applies performance tweaks: disables sleep, increases virtual memory
    │   ├── siem_setup.sh              # 🔧 Configures Splunk Enterprise on SIEM VM
    │   └── windows_host_setup.ps1     # 🖥️ Sets up Windows host with Sysmon, Splunk Forwarder, and security configs
    │
    └── setup_files/                    # 📁 Contains all supporting installation assets (.msi, .zip, .xml, etc.)
        ├── host/
```

## ✅ Prerequisites

* Windows host system
* PowerShell (run as Administrator)
* Internet connection

## 🚀 Getting Started

1. **Clone the repository:**

   ```powershell
   git clone https://github.com/mhatib/Mini-PpT-Infra.git
   cd Mini-PpT-Infra
   ```

2. **Run the setup script:**
   Run this as Administrator:

   ```powershell
   .\run-vagrant.ps1
   ```

   This script:

   * Installs prerequisites (VirtualBox, Vagrant, Chocolatey, VC Redist)
   * Downloads all required setup files
   * Provisions and configures VMs (SIEM and Windows Host)

3. **Reboot When Prompted:**
   After the prerequisites step, you'll be prompted to reboot. Once rebooted, **re-run the same script** to continue.

## 💪 Vagrant Machines

* **SIEM** (`192.168.111.100`)

  * Ubuntu (bionic64)
  * Splunk Enterprise + Sysmon Add-on

* **Host** (`192.168.111.151`)

  * Windows 10 (via `gusztavvargadr/windows-10`)
  * Sysmon, Splunk Universal Forwarder, auditing policies, etc.

## 🔄 Notes

* The script tracks progress via `.setup_progress` to prevent re-running completed steps.
* If a VM fails to start (especially SIEM), delete the VM in VirtualBox GUI and run `vagrant up`
* The Cursor installation requires manual intervention - you'll be prompted during setup

## 🔄 Re-running from Scratch

To clear the cache and re-run the installation script from the scratch, first run this command in Administrator PowerShell:

```powershell
Remove-Item "$env:ProgramData\MiniPpT-Infra\setup-status.txt" -Force -ErrorAction SilentlyContinue
```

Then re-run the main script:

```powershell
.\run-vagrant.ps1
```

## 📞 Support

For questions or issues, please open a GitHub issue or contact [@mhatib](https://github.com/mhatib).

---

Happy hunting! 🛡️
