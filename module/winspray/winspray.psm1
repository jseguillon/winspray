#TODO : validate config against JSON Schema
#TODO : ensure possible envs&group_vars outside of samples
#TDOO : no localmount but current dir for pure docker image runtime (no additional archive for module nor git)
#TODO : few synopsys

$script:PSModule = $ExecutionContext.SessionState.Module
$script:PSModuleRoot = $script:PSModule.ModuleBase
$script:kubesprayVersion = "2.13.1"

function Remove-Winspray-Cluster {
    Write-Host ( "# Winspray - destroying current VMs")

    Write-Verbose ( "### Winspray - launching vagrant destroy -f" )
    vagrant destroy -f

    if (!$?) { throw ("Exiting $?") } # FIXME should exit and say use -Force
    $targetDir = "old-{0}" -f (Get-Date -Format "MM-dd-yyyy-HH-mm")
    
    Write-Verbose( "### Winspray - Moving current to $targetDir" )    
    Get-ChildItem -Path "$pwd/current" -Recurse |  Move-Item -Destination "$targetDir" -Force

    Write-Host ( "## Winspray - destroy done `n" ) -ForegroundColor DarkGreen
}

function Backup-Winspray-Cluster {
        [CmdletBinding()]
    Param(
        [parameter( ValueFromPipeline )]
        [string]$BackupName = ""
    )
    Write-Host ("# Winspray - start backup with name '$BackupName'" )
    Get-VM | Where-Object {$_.Name -like 'k8s-*'} | ForEach-Object -Process {Checkpoint-VM -Name $_.Name -SnapshotName "$BackupName"}
    
    if (!$?) { exit -1 }
    Write-Host ( "## Winspray - backup '$BackupName' ok `n") -ForegroundColor DarkGreen
}

function Restore-Winspray-Cluster{
    [CmdletBinding()]
    Param(
        [parameter( ValueFromPipeline )]
        [string]$BackupName = "installed"
    )
    Write-Host ("# Winspray - start restore  with name '$BackupName'" )
    Get-VM | Where-Object {$_.Name -like 'k8s-*'} | ForEach-Object -Process {Restore-VMSnapshot -Confirm:$false -Name "$BackupName" -VMName $_.Name }
    
    if (!$?) { exit -1 }
    Write-Host ( "## Winspray - restore '$BackupName' ok `n") -ForegroundColor DarkGreen
}

function Start-Winspray-Cluster {
    Write-Host ("# Winspray - start existing VMS" )    
    Get-VM | Where-Object {$_.Name -like 'k8s-*' -and $_.State -ne "Running" } | ForEach-Object -Process { Start-VM $_.Name }
    
    Write-Host ( "## Winspray - VMS started ok  `n")  -ForegroundColor DarkGreen
}

function Stop-Winspray-Cluster {
    Write-Host ("# Winspray - start existing VMS" )
    Get-VM | Where-Object {$_.Name -like 'k8s-*'} | ForEach-Object -Process {Stop-VM  $_.Name }

    Write-Host ( "## Winspray - VMS started ok `n")  -ForegroundColor DarkGreen
}

function Prepare-Winspray-Cluster( ) {
    #FIXME : how to good inject Debug flag (from this direct cal plus from New-Winspray-Cluster)
    $AnsibleDebug = If ( $Debug ) {"-vvv"} Else {""} 

    Write-Host ( "# Winspray - preparing VMs for kubernetes" )
    Write-Verbose ( " ### Winspray - launching ansible-playbook --become -i /.../$KubernetesInfra.yaml /.../playbooks/prepare.yaml " )
    docker run --rm -v "/var/run/docker.sock:/var/run/docker.sock" -e ANSIBLE_CONFIG=/opt/winspray/ansible.cfg -v ${PWD}:/opt/winspray -t jseguillon/winspray:$script:kubesprayVersion bash -c "ansible-playbook $AnsibleDebug  --become  -i /opt/winspray/current/hosts.yaml /winspray/playbooks/prepare.yaml -e '@/opt/winspray/config/kubespray.vars.json' -e '@/opt/winspray/config/network.vars.json' -e '@/opt/winspray/config/authent.vars.json'"
    
    if (!$?) { throw "Exiting $?" }
    Write-Host ( "## Winspray - VMs prepared for kubespray `n" ) -ForegroundColor DarkGreen
}

function Install-Winspray-Cluster( ) {
    #FIXME : how to good inject Debug flag (from this direct cal plus from New-Winspray-Cluster)
    $AnsibleDebug = If ( $Debug ) {"-vvv"} Else {""} 

    Write-Host ( "# Winspray - install kubernetes" )
    Write-Verbose ( "** launching ansible-playbook --become -i /...$KubernetesInfra /.../cluster.yml" )
    docker run  --rm -v "/var/run/docker.sock:/var/run/docker.sock" -e ANSIBLE_CONFIG=/opt/winspray/ansible.cfg -v ${PWD}:/opt/winspray -t jseguillon/winspray:$script:kubesprayVersion bash -c "ansible-playbook $AnsibleDebug  --become  -i /opt/winspray/current/hosts.yaml cluster.yml -e '@/opt/winspray/config/kubespray.vars.json' -e '@/opt/winspray/config/network.vars.json' -e '@/opt/winspray/config/authent.vars.json'"
    
    if (!$?) { throw "Exiting $?" }
    Write-Host ( "## Winspray - kubernetes installed `n" ) -ForegroundColor DarkGreen
}

function Do-Winspray-Bash( ) {
    Write-Host ( "" )
    Write-Host ( "** Going to bash. Here are usefull commands : " )
    Write-Host ( "   pip install -r /opt/winspray/kubespray/requirements.txt" )
    Write-Host ( "   ansible-playbook --network host --become  -i /opt/winspray/current/hosts.yaml cluster.yml -e '@/opt/winspray/config/kubespray.vars.json' -e '@/opt/winspray/config/network.vars.json'  -e '@/opt/winspray/config/authent.vars.json'" )
    Write-Host ( "" )

    docker run -it --rm -v "/var/run/docker.sock:/var/run/docker.sock" -v ${PWD}:/opt/winspray -t jseguillon/winspray:$script:kubesprayVersion bash
    
    if (!$?) { throw "Exiting $?" }
}

function Test-Winspray-Env {
    Write-Host ("# Winspray - check env" )

    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if ( ! $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) ) {
        throw ( "** ERROR *** Please launch Powershell as administrator" )
    }

    if( (Get-WindowsOptionalFeature -Online -FeatureName *hyperv* |  Measure-Object -Line).Lines -eq 0 ) {
        throw ( "** ERROR *** Please install and acivate HyperV" )
    }

    vagrant -v
    if(!$?) {
        throw ( "** ERROR *** Please install vagrant" )
    }

    docker version
    if(!$?) {
        throw ( "** ERROR *** Please install and start docker" )
    }

    Write-Host ( "## Winspray - check ok `n" ) -ForegroundColor DarkGreen
}

function New-Winspray-Config () {
    if ( ! [System.IO.Directory]::Exists("$pwd\config" ) ) {
        Write-Verbose ( "### Winspray - create Vagrantfile" )
        Copy-Item $script:PSModuleRoot/config . -Recurse 
    }
}

function New-Winspray-Inventory ( ) {
    [CmdletBinding()]
    Param(
        [parameter( ValueFromPipeline, Mandatory=$true )]
        [string]$KubernetesInfra
    )

    Write-Host ("# Winspray - create kubespray inventory and vagant config" )

    copy  ./samples/$KubernetesInfra.yml current/infra.yaml
    if (!$?) {  throw ( "** ERROR *** could not find  ./samples/$KubernetesInfra.yml or could not copy it to 'current/' " ) }

    # launch ansible templates that renders in current/vagrant.vars.rb current/inventory.yaml + groups vars from example
    docker run -v "/var/run/docker.sock:/var/run/docker.sock" --rm -v ${PWD}:/opt/winspray -it jseguillon/winspray:$script:kubesprayVersion  ansible-playbook $AnsibleDebug --become  --limit=localhost /winspray/playbooks/inventory_create.yaml
    if (!$?) {  throw ( "** ERROR *** Found error while creating inventory" ) }

    Copy-Item ./samples/group_vars -Destination current/ -Recurse

    Write-Host ( "## Winspray - inventory and vagrant config created `n") -ForegroundColor DarkGreen
}

function New-Winspray-Cluster () {
    [CmdletBinding()]
    Param(
        [parameter( ValueFromPipeline, Mandatory=$true )]
        [string]$KubernetesInfra,
        [switch]$Force,
        [switch]$ContinueExisting
    )

    $StartMs = Get-Date

    # FIXME debug
    [bool]$ContinueExisting = ( $PSBoundParameters.ContainsKey( 'ContinueExisting' ) )
    [bool]$Force = ( $PSBoundParameters.ContainsKey( 'Force' ) )
    Test-Winspray-Env
    
    if ( ! [System.IO.Directory]::Exists("$pwd\current") ) {
        Write-Verbose ( "### Winspray - create 'current' dir" )
        $ret = mkdir $pwd/current/ | Out-Null
        if(!$?) { throw ("** ERROR *** could not create  $pwd/current/ directory. $ret" ) }
    }

    if ( ! [System.IO.File]::Exists("$pwd\Vagrantfile" ) ) {
        Write-Verbose ( "### Winspray - create Vagrantfile" )
        Copy-Item $script:PSModuleRoot/Vagrantfile .
    }
    
    New-Winspray-Config
    
    # Existing vagrant config file and Force flag ? : ok to destroy if we got new target
    if ( [System.IO.File]::Exists("$pwd\current\vagrant.vars.rb") -and (! $ContinueExisting ) ) {
        if ( $Force ) {
            Remove-Winspray-Cluster
        }
        else {
            Write-Host ( "Found existing cluster. Maybe you wanted to Start-Winspray-Cluster ?" )
            throw  "Please remove exiting cluster first or use -Force flag or start existing cluster " 
        }
    }

    # Do not replay if going with ContinueExisting
    if ( ! [System.IO.File]::Exists("$pwd\current\vagrant.vars.rb") ) {
        New-Winspray-Inventory ($KubernetesInfra);

        Write-Host ("# Winspray - create new VMs" )
        Write-Verbose ( "### Winspray - launching vagrant up" )
        
        # Export root module path so vagrant can call script 
        $env:WINSPRAYROOT=$script:PSModuleRoot

        vagrant up

        if (!$?) { throw "Exiting $?"; }
        Write-Host ( "## Winspray - VMs created ok `n" ) -ForegroundColor DarkGreen
    }
    # not new cluster ? quick start VMs for ContinueExisting mode
    else {
        Start-Winspray-Cluster
    }

    #cluster not yet prepared ? run prepare playbook
    if ( ! [System.IO.File]::Exists("$pwd\current\prepared.ok") ) {
        Prepare-Winspray-Cluster 
        echo "ok" > $pwd\current\prepared.ok

        Backup-Winspray-Cluster ("prepared")
    }
    else {
        Write-Host ("# Winspray - VMS already prepared `n" )
    }

    # kubernetes not installed ? run cluster playbook
    if ( ! [System.IO.File]::Exists("$pwd\current\installed.ok") ) {
        Install-Winspray-Cluster 
        echo "ok" > $pwd\current\installed.ok

        Backup-Winspray-Cluster ("installed")
    }
    else {
        Write-Host ("# Winspray - Kubernetes already installed. Nothing to do  `n" )
    }

    $timeExec =  (Get-Date) - $StartMs
    Write-Host ("# Winspray - kubernetes now running `n " ) -ForegroundColor DarkGreen
    Write-Host ("# Winspray - Time to start  {0}h {1}m {2}s" -f  ($timeExec.Hours, $timeExec.Minutes, $timeExec.Seconds ))
}

Export-ModuleMember -Function New-Winspray-Cluster, Remove-Winspray-Cluster, Start-Winspray-Cluster, Backup-Winspray-Cluster, Restore-Winspray-Cluster, Stop-Winspray-Cluster, Prepare-Winspray-Hosts, Install-Winspray-Hosts, Do-Winspray-Bash, Test-Winspray-Env, Set-Winspray-Inventory, Prepare-Winspray-Runtime, Do-Winspray-Bash