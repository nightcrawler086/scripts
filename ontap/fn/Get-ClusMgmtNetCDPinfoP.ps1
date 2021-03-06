# Get the Cluster Management LIF by role
# Select the FailoverGroup Property and feed it to Get-NCNetFailoverGroup
# Get the node and ifgrp name (renaming IfgrpName to "Ports") and feed it to Get-NcNetPortIfgrp
# Select the node and ports (renaming "Ports" property to "Port") and feed it to Get-NcNetDeviceDiscovery
# Select properties for output



function Get-ClusMgmtNetCDPinfoP {

Get-NcNetInterface -Role cluster_mgmt | Select-Object FailoverGroup | Get-NcNetFailoverGroup | 
	Select-Object node,port | Get-NcNetDeviceDiscovery | 
		Select-Object Node,Port,discovereddevice,Interface,Platform | Write-Output
}
Get-ClusMgmtNetCDPinfoP
