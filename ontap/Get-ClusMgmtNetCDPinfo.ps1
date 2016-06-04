# Typically want to accept first positional parameter as the cluster name

[CmdletBinding()]
Param (
	[Parameter(Mandatory=$True,Position=1)]
	 [string[]]$Clusters,
     
	[Parameter(Mandatory=$False)] 
	 [string]$FailoverGroup
)

<#
    .SYNOPSIS
    This script is designed to assess the cluster management connectivity.  It will assess the configuration from 
    the failover group down to the member ports of the ifgrp (if used) and switches the physical ports are patched
    into (if CDP is working).

    .DESCRIPTION
	This script/function is to grab the CDP/LLDP info from the ports that are set up in the Cluster Management
	Failover Group.  A way to see how the nodes are cabled for management connectivity.
    
	.EXAMPLE
    PS C:\> Get-ClusMgmtNetCDPinfo.ps1 -Clusters [ <cluster1>,<cluster2>,... ]
#>

	
BEGIN {

# Let's check for the DataOntap PowerShell Module, if not import it
	If (!(Get-Module -Name DataONTAP)) {
		Import-Module -Name DataOntap -ErrorAction SilentlyContinue
	}
	If (!(Get-Module -Name DataONTAP)) {
		Write-Host -ForegroundColor Red -BackgroundColor Black `
			"Could not import DataONTAP module, is the DataONTAP Powershell Toolkit installed?"
	}
}

PROCESS {

# Need to check the port types in the Failover Group so we can grab the CDP info
# correctly (do we need to break down an ifgrp or not?)
# Improvements:
# 	- Authentication to clusters (store username and password?)
# 	- Put output into an object before we write it
# 	- Add option to specify FailoverGroup, or do all of them
# 		- How to make that useful?
    
	# Function if the ports are if_groups
	function Get-IfgrpPortInfo {
		$PORT | Select-Object Node,@{Name="IfgrpName";Expression={$_."Port"}} | Get-NcNetPortIfgrp |
			Select-Object Node,@{Name="Port";Expression={$_."Ports"}} | Get-NcNetDeviceDiscovery |
				Select-Object Node,Port,DiscoveredDevice,Interface,Platform | Write-Output
	}
	
	# Function if the ports are physical
	function Get-PhysPortInfo {
		$PORT | Select-Object Node,Port | Get-NcNetDeviceDiscovery | 
			Select-Object Node,Port,DiscoveredDevice,Interface,Platform | Write-Output
	}
	
	# Loop to process each port
	Foreach ($Cluster in $Clusters) {
        Write-Host -ForegroundColor Green -BackgroundColor Black "Provide credentials for $Cluster"
		Connect-NcController $Cluster | Out-Null
   		$PORTS = Get-NcNetInterface -Role cluster_mgmt | Select-Object FailoverGroup | Get-NcNetFailoverGroup |
   					Select-Object Node,Port | Get-NcNetPort | Select-Object Node,Port,PortType
				
				ForEach ($PORT in $PORTS) {
					If ($PORT.PortType -eq "if_group") {
						# Call the IfgrpPort function above
						Get-IfgrpPortInfo
					}
					
					ElseIf ($PORT.PortType -eq "physical") {
						# Call the PhysPort function above
						Get-PhysPortInfo
					}
					
					Else {Write-Host -ForegroundColor Red -BackgroundColor Black "Could not determine port type"}
				}
	}
}

