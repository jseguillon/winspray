# What ? 

Winspray is set of functions made to ease Kubernetes multi-node and multi OS deployement on Hyperv via Vagrant and Kubespray

Uses Powershell + Docker to manage the VMs

More details to come 

# Requirements

## Windows 10 requirements

HyperV enabled => https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/quick-start/enable-hyper-v

## Windows 10 software Requirements 

Vagrant => https://www.vagrantup.com/downloads.html

Docker Destkop => https://hub.docker.com/editions/community/docker-ce-desktop-windows

Git => https://git-scm.com/download/win

# Get ready 

## Clone and update modules 

```powershell
git clone https://github.com/jseguillon/winspray.git
cd winspray
git submodule update --init
```

## Import module

```powershell
Import-Module .\winspray.psm1 -Force
```

# Use it 

## New cluster 

Example with cluster described in `samples/minimal`

```powershell
New-Winspray-Cluster minimal

Restore-Winspray-Cluster
Stop-Winspray-Cluster
Start-Winspray-Cluster
```

## Create again

```powershell
Remove-Winspray-Cluster
New-Winspray-Cluster minimal

# or New-Winspray-Cluster minimal -Force 
```

# Other usefull commands 

```powershell
Get-Help winspray
```
