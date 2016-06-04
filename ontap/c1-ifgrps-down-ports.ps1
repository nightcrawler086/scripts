# This is a script to pull LACP interface groups with down ports from an array of clusters

# Defining our parameters, Username and Passowrd here will be used for each cluster in the array
[CmdletBinding()]
Param (
	[Parameter(Mandatory=$False,Position=1)]
	 [string[]]$Clusters,

	[Parameter(Mandatory=$True,Position=2)]
	 [string]$Username,

	[Parameter(Mandatory=$True,Position=3)]
	 [string]$Password
)

# This is our BEGIN block (also could be considered the setup block).  Code in this 
# block will be run one time.  Could be useful if piping other objects into this 
# script
BEGIN {

	# Let's check for the DataOntap PowerShell Module, if not import it
	If (!(Get-Module -Name DataONTAP)) {
		Import-Module -Name DataOntap -ErrorAction SilentlyContinue
	}

	# Same command after attempting import, if the module still isn't there, then
	# output error to the screen and exit the script
	# The backtick (`) is a line-continuation
	If (!(Get-Module -Name DataONTAP)) {
		Write-Host -ForegroundColor Red -BackgroundColor Black `
			"Could not import DataONTAP module, is the DataONTAP Powershell Toolkit installed?"
		Exit
	}

	# Creating a credential to use to connect to all clusters
	# The ConvertTo-SecureString is required for this
	$ClusterCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "$Username",(ConvertTo-SecureString $Password -AsPlainText -Force)

	# Define array of Clusters

	# Our main function...get LACP ifgrps with downports
	# Note:  Single-mode ifgrps will always have DownPorts
	# Line will automatically contine if ending with a '|'
	function Get-LacpIfgrpsWithDownPorts {
		Get-NcNetPortIfgrp | Where-Object {$_.Mode -eq "multimode_lacp" -and $_.DownPorts -ne $NULL} |
			Select-Object Node,IfgrpName,Mode,@{Name="MemberPorts";Expression={$_.Ports -join ','}},@{Name="UpPorts";Expression={$_.UpPorts -join ','}},@{Name="DownPorts";Expression={$_.DownPorts -join ','}},MacAddress
	}

	# This is an empty variable in which we will populate a new object with the 
	# output data from each cluster
	$IFGRPS = @()

}

PROCESS {
	ForEach ($Cluster in $Clusters) {
		# Let's connect to the cluster first...
		# Connect with credentials we defined earlier, and hide result
		Connect-NcController $Cluster -Credential $ClusterCreds | Out-Null
		# Then we'll run the fuction we built, grabbing the right data, 
		# and putting it into a variable so we can pull these values out 
		# in the next step to create/append to our custom object
		$IFGRPSDP = Get-LacpIfgrpsWithDownPorts 

	# This will add the output of the function above and add/append it to a 
	# custom object for output later
	$IFGRPS += New-Object -TypeName PSObject -Property @{
							Node = $IFGRPSDP.Node; 
							IfgrpName = $IFGRPSDP.IfgrpName;
							Mode = $IFGRPSDP.Mode; 
							MemberPorts = $IFGRPSDP.MemberPorts; 
							UpPorts = $IFGRPSDP.UpPorts;
							DownPorts = $IFGRPSDP.DownPorts; 
							MacAddress = $IFGRPSDP.MacAddress
							}	
	
	}
}

END {
	# This section is to output the custom object we built
	# This section can be easily modified to output the
	# custom object to a file or use the object to do 
	# further processing
	$IFGRPS
}
