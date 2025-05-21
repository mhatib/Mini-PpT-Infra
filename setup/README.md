# Network Configuration
There will be 2 subnets in this configuration.
1. External subnet - External network (where attacker resides)
2. Internal subnet - Enterprise's internal network

| Subnet | CIDR Range |
| ------ | ---------- |
| External | `111.0.10.0/24` |
| Internal | `192.168.111.0/24 `|

## Endpoints 

| Subnet | Computer | IP Address | Remarks |
| ------ | -------- | ---------- | ------- |
| External | Attacker | `111.0.10.10` | Attacker machine |
| External | Router | `111.0.10.5` | External Interface of Router |
| Internal | Router | `192.168.111.5` | Internal Interface of Router |
| Internal | Ubuntu Web Server | `192.168.111.200` | Hosts a public vulnerable web application |
| Internal | Windows Host | `192.168.111.151` | Hosts an internal vulnerable web application, Part of Active Directory |
| Internal | Domain Controller | `192.168.111.150` | Domain Controller for the Active Directory |
| Internal | SIEM | `192.168.111.100` | SIEM for the internal network |

## Routing Configuration
Add static routes and configuration to allow packets to be forwarded between internal and external subnet.

### Kali
Forward all internal destination packets to router's external interface
#### Routing Table
| CIDR | Route To |
| ---- | -------- |
| 192.168.111.0/24 | `111.0.10.5` |
`ip route add 192.168.111.0/24 via 111.0.0.5`

### Router 
* Configure router to forward packets from one interface to another
```bash
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -A FORWARD -i eth0 -o eth1 -j ACCEPT # public to internal
iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT # internal to public
```

### Ubuntu Web Server, Windows Host, Domain Controller, ELK SIEM
Forward all external destination packets to router's internal interface
#### Routing Table
| CIDR | Route To |
| ---- | -------- |
| 111.0.0.0/24 | `192.168.111.5` |
* Bash `ip route add 10.0.0.0/8 via 192.168.111.5`
* PowerShell `route /p add 111.0.0.0 mask 255.0.0.0 192.168.111.5 [if 0x2]`

## Firewall Configuration 
`TODO`

# Launch Configuration
Describe the launch configuration of each machine in a simple manner. 
Virtual machines used can be found [here](https://app.vagrantup.com/boxes/). 

## External Subnet 
### Attacker (`111.0.10.10`)
The attacker machine is a Kali 2023 machine (Box: `kalilinux/rolling`).
1. Add static route to route all traffic to `192.168.111.0/24` (internal subnet) to `111.0.10.5` (router)

### Router (`111.0.10.5`)
The router is a Ubuntu 18.04 LTS 64-bit box. (Box: `hashicorp/bionic64`).
1. Set up forwarding and logging using `iptables` from one interface to another
2. Download FileBeat debian package from `192.168.111.200` (Ubuntu Web Server) and install FileBeat
3. Update Filebeat.yml using `cat`
4. Start Filebeat service

## Internal Subnet
### Router (`192.168.111.5`)
The router is a Ubuntu 18.04 LTS 64-bit box. (Box: `hashicorp/bionic64`).
1. Set up forwarding and logging using `iptables` from one interface to another
2. Download FileBeat debian package from `192.168.111.200` (Ubuntu Web Server) and install FileBeat
3. Update Filebeat.yml using `cat`
4. Start Filebeat service

### Ubuntu Web Server (`192.168.111.200`)
The router is a Ubuntu 18.04 LTS 64-bit box. (Box: `hashicorp/bionic64`). 
1. Update apt packages, install and start apache2
2. Add static route to route all traffic to `111.0.10.0/24` (external subnet) to `192.168.111.5` (router)
3. Download Filebeat package from `artifacts.elastic.co` to `/var/www/html`
4. Install Filebeat
5. Update Filebeat.yml using `cat`
6. Start Filebeat service

### SIEM (`192.168.111.100`)
The SIEM is a Ubuntu 18.04 LTS 64-bit box. (Box: `hashicorp/bionic64`).
1. Add static route to route all traffic to `111.0.10.0/24` (external subnet) to `192.168.111.5` (router)
2. Install docker and docker-compose
3. Update elasticsearch.yml and docker-compose using `cat`
4. Use docker-compose to start ELK stack

### DC (`192.168.111.150`)
The DC is a Windows Server 2022 Standard machine (Box: `gusztavvargadr/windows-server`).
1. Add static route to route all traffic to `111.0.10.0/24` (external subnet) to `192.168.111.5` (router)
2. Add firewall rule 
3. Add audit policies
4. Add registry keys to enable powershell logging 
5. Hardcode administrator password 
6. Download, install and configure sysmon
7. Download, install and configure Winlogbeat
8. Start Winlogbeat service
9. Set up DC

### Windows Host (`192.168.111.151`)
The Windows Host is a Windows 10 Standard machine (Box: `gusztavvargadr/windows-10`).
1. Add static route to route all traffic to `111.0.10.0/24` (external subnet) to `192.168.111.5` (router)
2. Add firewall rule 
3. Add audit policies
4. Add registry keys to enable powershell logging 
5. Hardcode administrator password 
6. Download, install and configure sysmon
7. Download, install and configure Winlogbeat
8. Start Winlogbeat service
9. Wait for DC to be set up and then join AD as `host`

# FileBeat Configuration 

### Router (`111.0.10.5`/`192.168.111.5`)
Enabled the following filebeat modules:
1. `iptables`
2. `system`

### Router (`192.168.111.200`)
Enabled the following filebeat modules:
1. `apache`
2. `system`