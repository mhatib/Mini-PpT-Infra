Vagrant.configure("2") do |config| 
  if Vagrant.has_plugin?("vagrant-vbguest") then
    config.vbguest.auto_update = false
  end  


  # siem
  config.vm.define "siem" do |siem|
    siem.vm.box = "hashicorp/bionic64"
    siem.vm.hostname = "siem"

    # network
    siem.vm.network "private_network", ip: "192.168.111.100", virtualbox__intnet: "internal_nw"

    # scripts 
    siem.vm.provision "file", source: "setup/setup_files/splunk.deb", destination: "/home/vagrant/splunk.deb"
    siem.vm.provision "file", source: "setup/setup_files/sysmonaddon.tgz", destination: "/home/vagrant/sysmonaddon.tgz"
    siem.vm.provision "shell", path: "setup/setup_scripts/Splunk/siem_setup.sh", privileged: true

    # virtualise
    siem.vm.provider "virtualbox" do |v, override|
      v.name = "siem"
      v.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
      v.customize ['modifyvm', :id, '--draganddrop', 'bidirectional']
      v.memory = 2048
      v.cpus = 2
      v.gui = true
    end
  end

 # host
 config.vm.define "host" do |host|
   host.vm.box = "gusztavvargadr/windows-10"
   host.vm.hostname= "host"
   host.vm.communicator = "winssh"
   # network 
   host.vm.network "private_network", ip: "192.168.111.151", virtualbox__intnet: "internal_nw"

   # upload host setup file
   host.vm.provision "file", source: "setup/setup_files/host/SetupWindows.xml", destination: "C:/Users/Public/SetupWindows.xml"
   host.vm.provision "file", source: "setup/setup_files/host/setup-windows.ps1", destination: "C:/Users/Public/setup-windows.ps1"
   host.vm.provision "file", source: "setup/setup_files/Sysmon.zip", destination: "C:/Users/vagrant/Documents/Sysmon.zip"
   host.vm.provision "file", source: "setup/setup_files/sysmonconfig-export.xml", destination: "C:/Windows/config.xml"
   host.vm.provision "file", source: "setup/setup_files/splunkforwarder.msi", destination: "C:/Users/vagrant/Documents/splunkforwarder.msi"
   #host.vm.provision "file", source: "setup/setup_files/OTCEP.zip", destination: "C:/Users/vagrant/Documents/OTCEP.zip"

   # scripts
   host.vm.provision "shell", path: "setup/setup_scripts/Splunk/windows_host_setup.ps1", privileged: true, run: 'always'

   # virtualise
   host.vm.provider "virtualbox" do |v, override|
     v.name = "host"
     v.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
     v.customize ['modifyvm', :id, '--draganddrop', 'bidirectional']
     v.memory = 4096
     v.cpus = 2
     v.gui = true
   end 
 end
end