# -*- mode: ruby -*-
# vim: ft=ruby

# To be tested
#UBUNTU20_BOX = "generic/ubuntu2004" => pb with could not load host key: /etc/ssh/ssh_host_ecdsa_key
UBUNTU19 = "generic/ubuntu1910"
UBUNTU18 = "generic/ubuntu1810"
CENTOS8 = "generic/centos8"
DEBIAN10 = "generic/debian10"

config = File.join(File.dirname(__FILE__), "current", "vagrant.vars.rb")

require config

# ---- Vagrant configuration ----
Vagrant.configure(2) do |config|
  HOSTS.each do | (name, cfg) |
    mac, cpus, minRam, maxRam, box, secondMac = cfg
   
    config.vm.define name do |machine|
      machine.vm.box = (ENV['K8S_BOX'] || box)
	    machine.vm.hostname = name

      machine.vm.provision "shell", privileged: true, inline: <<-SHELL
echo Ok for ssh with password
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

echo kubernetes == no swap
swapoff -a

echo k8s = no fw unless prod
systemctl disable firewalld

echo Installing anible required packages 
(yum install -y sshpass) || (apt-get install -y sshpass)

echo Centos 8 tweak - sets a default python for ansible
(grep CentOS-8 /etc/os-release && ln -s /usr/bin/python3 /usr/bin/python) || true

echo Centos-8 tweak - control plane interface disabled until activated from ansible
(grep CentOS-8 /etc/os-release && cat  >/etc/sysconfig/network-scripts/ifcfg-eth1 <<EOF
DEVICE="eth1"
ONBOOT="no"
EOF
) || true

echo Done
SHELL

      # Add second interface for kubernetes control plane 
      machine.trigger.after :up do |trigger|
        trigger.run = {privileged: "true", powershell_elevated_interactive: "true", path: "module/winsprayAddItf.ps1", args: ["-vmName", name, "-macAddrCtrlPlane", secondMac]}
      end

      machine.vm.provider "hyperv" do |hv|
        hv.memory = minRam
        hv.maxmemory = maxRam
        hv.cpus = cpus
		    hv.mac = mac
		    hv.vmname = name
      end

    end # config.vm.define
  end # HOSTS-each
end

# Get-VM | Where-Object {$_.Name -like 'k8s-*'} | ForEach-Object -Process {Get-VMNetworkAdapter $_.Name }
# Get-VM | Where-Object {$_.Name -like 'k8s-*'} | ForEach-Object -Process {vagrant snapshot push $_.Name}
# Get-VM | Where-Object {$_.Name -like 'k8s-*'} | ForEach-Object -Process {vagrant snapshot pop --no-provision --no-start --no-delete $_.Name}

