#TODO : validate config against JSON Schema
#TODO : few synopsys

$script:PSModule = $ExecutionContext.SessionState.Module
$script:PSModuleRoot = $script:PSModule.ModuleBase
$script:kubesprayVersion = "2.13.1"

function Remove-Winspray-Cluster {
    Write-Host ( "# Winspray - destroying current cluster")
    
    if ( [System.IO.Directory]::Exists("$pwd\current") ) {
        if ( [System.IO.File]::Exists("$pwd\current\vagrant.vars.rb") ) {
            Write-Verbose ( "### Winspray - launching vagrant destroy -f" )
            $env:WINSPRAYROOT=$script:PSModuleRoot
            vagrant destroy -f
            if (!$?) { throw ("Exiting $?") } # FIXME should exit and say use -Force and deal wit h this
        }
        $targetDir = "old-{0}" -f (Get-Date -Format "MM-dd-yyyy-HH-mm")
        Write-Verbose( "### Winspray - Moving current to $targetDir" )    
        Get-ChildItem -Path "$pwd/current" -Recurse |  Move-Item -Destination "$targetDir" -Force
        Write-Host ( "## Winspray - destroy done `n" ) -ForegroundColor DarkGreen
    }
    else { 
        Write-Host ( "## Winspray - nothing to destroy done. Remove VMs manually if needed `n" ) 
    }
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
    # TODO : if existing docker/playbooks => use local
    docker run --rm -v "/var/run/docker.sock:/var/run/docker.sock" -e ANSIBLE_CONFIG=/winspray/ansible.cfg -v ${PWD}:/opt/winspray -t jseguillon/winspray:$script:kubesprayVersion bash -c "ansible-playbook $AnsibleDebug --become  -i /opt/winspray/current/hosts.yaml /winspray/playbooks/prepare.yaml -e '@/opt/winspray/current/config/kubespray.vars.json'  -e '@/opt/winspray/current/config/network.vars.json' -e '@/opt/winspray/current/config/authent.vars.json'"
    
    if (!$?) { throw "Exiting $?" }
    Write-Host ( "## Winspray - VMs prepared for kubespray `n" ) -ForegroundColor DarkGreen
}

function Install-Winspray-Cluster( ) {
    #FIXME : how to good inject Debug flag (from this direct cal plus from New-Winspray-Cluster)
    $AnsibleDebug = If ( $Debug ) {"-vvv"} Else {""} 

    Write-Host ( "# Winspray - install kubernetes" )
    Write-Verbose ( "** launching ansible-playbook --become -i /...$KubernetesInfra /.../cluster.yml" )
    # TODO : if existing kubespray => use local
    docker run  --rm -v "/var/run/docker.sock:/var/run/docker.sock" -e ANSIBLE_CONFIG=/winspray/ansible.cfg -v ${PWD}:/opt/winspray -t jseguillon/winspray:$script:kubesprayVersion bash -c "ansible-playbook $AnsibleDebug  --become  -i /opt/winspray/current/hosts.yaml cluster.yml -e '@/opt/winspray/current/config/kubespray.vars.json' -e '@/opt/winspray/current/config/network.vars.json' -e '@/opt/winspray/current/config/authent.vars.json'"
    
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

function New-Winspray-Inventory ( ) {
    [CmdletBinding()]
    Param(
        [parameter( ValueFromPipeline, Mandatory=$true )]
        [string]$KubernetesInfra
    )

    Write-Host ("# Winspray - create kubespray inventory and vagant config" )
    $FileName = (Get-Item $KubernetesInfra).Name
    if ( ! [System.IO.File]::Exists("$pwd/$FileName") ) {  throw ( "** ERROR *** could not find infra file '$KubernetesInfra' in current '$pwd' path. Please ensure you launch Winspray commands in same path than infra file" ) }

    # launch ansible templates that renders in current/vagrant.vars.rb current/inventory.yaml + groups vars from example
    # TODO : if existing docker/playbooks => use local
    $NoPathInfra = (Get-Item $KubernetesInfra).Name
    docker run -v "/var/run/docker.sock:/var/run/docker.sock" --rm -v ${PWD}:/opt/winspray -it jseguillon/winspray:$script:kubesprayVersion  ansible-playbook $AnsibleDebug --become  --limit=localhost /winspray/playbooks/inventory_create.yaml -e "infra=$NoPathInfra"
    if (!$?) {  throw ( "** ERROR *** Found error while creating inventory" ) }

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

    # Existing current ? : ok to destroy if we got new target
    if ( [System.IO.Directory]::Exists("$pwd\current") -and (! $ContinueExisting ) ) {
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

Export-ModuleMember -Function Set-Winspray-Config, New-Winspray-Cluster, Remove-Winspray-Cluster, Start-Winspray-Cluster, Backup-Winspray-Cluster, Restore-Winspray-Cluster, Stop-Winspray-Cluster, Prepare-Winspray-Hosts, Install-Winspray-Hosts, New-Winspray-Inventory, Test-Winspray-Env, Set-Winspray-Inventory, Prepare-Winspray-Runtime, Do-Winspray-Bash