# What ? 

Winspray is set of functions made to ease Kubernetes multi-node and multi OS deployement on Hyperv via Vagrant and Kubespray. 

Goal : 
 - run kubespray with no effort on HyperV
 - easy & dynamic config

So far, knwon working vagrant boxes are "generic/centos8", "generic/debian10"  and "generic/ubuntu1910"

# Requirements

## Windows 10 requirements

HyperV enabled => https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/quick-start/enable-hyper-v

## Windows 10 software Requirements 

Vagrant => https://www.vagrantup.com/downloads.html

Docker Destkop => https://hub.docker.com/editions/community/docker-ce-desktop-windows

Git => https://git-scm.com/download/win

## Windows 10 network requirements

Ensure you're not connected into any kind of VPN or you'll probably get into troubles.

# Get ready 

## Clone and update modules 

```powershell
git clone https://github.com/jseguillon/winspray.git
cd winspray
git submodule update --init
```

## Import module

Import from [Powershell Gallery](https://www.powershellgallery.com/packages/winspray/) : 

```powershell
Install-Module -Name winspray
```

# Use it 

## Choose your infra 

[Pick one config file](https://github.com/jseguillon/winspray/tree/master/samples) on winspray github repo. You can edit and create your own. 

## Create tour cluster 

In this example, "minimal.yaml" infra is used : 

```powershell
New-Winspray-Cluster .\minimal.yaml

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

## Other usefull commands 

```powershell
Get-Help winspray
```

# A bit of arhitecture 

## Main flow chart

```
                                                                                                                                                                 
   winspray                                                 winspray                                                                                             
powershell module                    Vagrant             docker container              HyperV                  VMS 
       |                                |                        |                       |                      |  
       |---------|                      |                        |                       |                      |  
       |         |                      |                        |                       |                      |  
       |         | Prepare things       |                        |                       |                      |  
       |----------                      |                        |                       |                      |  
       |                    run playbook "create"                |                       |                      |  
       --------------------------------------------------------->|                       |                      |  
       |                                |                        |                       |                      |  
       |                 Vagrantfile and kubespray inventory     |                       |                      |  
       |<--------------------------------------------------------|                       |                      |  
       |        launch vagrant up       |                        |                       |                      |  
       |------------------------------->|                  create VMs                    |                      |  
       |                                |----------------------------------------------->|                      |  
       |                                |                vms created ok                  |(VMs are kwow created)|  
       |                                |<---------------------------------------------- |                      |  
       |           ok good to go        |                        |                       |                      |  
       |<------------------------------ |                        |                       |                      |  
       |                                |                        |                       |                      |  
       |                    run playbook "prepare"               |                       |                      |  
       |-------------------------------------------------------->|                       |                      |  
       |                                |                        |         prepare netwok                       |  
       |                                |                        |--------------------------------------------->|  
       |                                |                        |          network ok   |                      |  
       |                   good to go   |                        |<-------------------------------------------  |  
       |<--------------------------------------------------------|                       |                      |  
       |                                |                        |                       |                      |  
       |                launch kubespray "cluster" playbook      |                       |                      |  
       |-------------------------------------------------------->|             do all the kubespray magic       |  
       |                                |                        |--------------------------------------------->|  
       |                                |                        |          kubespray install done              |  
       |     THE END                    |                        |<---------------------------------------------|  
       |<------------------------------------------------------- |                       |                      |  
```

