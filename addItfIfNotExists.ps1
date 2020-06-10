Param ( [parameter( ValueFromPipeline )]
        [String]$vmName = "",
        [parameter( ValueFromPipeline )]
        [String]$macAddrCtrlPlane = "",
        [switch]$Help
      )

If ( $Help ) {
  exit 0
}

If ( $vmName -eq "" ) {
  echo "No vm name => skipping"
  exit 0
}

If ( $macAddrCtrlPlane -eq "" ) {
  echo "No mac => exiting error"
  exit -1
}

$countItf=(Get-VMNetworkAdapter -VMName $vmName | Where-Object {$_.MacAddress -match $macAddrCtrlPlane}).count

If ($countItf -ne 1) {
  echo "Stop vm $vmName"
  Stop-VM -VMName $vmName 
  sleep 2
  echo "Add itf  $macAddrCtrlPlane to vm $vmName"
  Add-VMNetworkAdapter -VMName $vmName -SwitchName "Default Switch"  -StaticMacAddress $macAddrCtrlPlane
  sleep 2
  echo "Starting again vm  $vmName"
  Start-VM -VMName $vmName
  sleep 2
  echo "Vm now ready"
}
Else {
  echo "Itf already on this VM"
}

# dont'forget to : `Set-ExecutionPolicy unrestricted` prior to exec
