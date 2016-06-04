# This script will pull all the CDP info from all physical (and link up) ports from an array of 
# Netapp Clusters.

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
	# output error to the screen and exit the script The backtick (`) is a line-continuation
	If (!(Get-Module -Name DataONTAP)) {
		Write-Host -ForegroundColor Red -BackgroundColor Black `
			"Could not import DataONTAP module, is the DataONTAP Powershell Toolkit installed?"
		Exit
	}

	# Creating a credential to use to connect to all clusters
	# The ConvertTo-SecureString is required for this
	$ClusterCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "$Username",(ConvertTo-SecureString $Password -AsPlainText -Force)

	# Define array of Clusters

	# Here is where we define our processing functions
    # This one is to grab CDP info from from all physical ports on the node 
    function Get-PhysPortCDPinfo {
        Get-NcNetPort | Where-Object {$_.PortType -eq "physical" -and $_.LinkStatus "up"} | Get-NcNetDeviceDiscovery |
            Select-Object NcController,Node,Port,DiscoveredDevice,Interface,Platform,Version,@{Name="DeviceIp";Expression={$_.DeviceIp -join ','}}
    }

	# This is an empty array in which we will append the data gathered
	# from each cluster.  Again, only need to define it once.  We will
	# populate in the PROCESS block
	$ALLCDPINFO = @()

}

PROCESS {
	ForEach ($Cluster in $Clusters) {
		# Let's connect to the cluster first...
		# Connect with credentials we defined earlier, and hide result
		Connect-NcController $Cluster -Credential $ClusterCreds | Out-Null
		
		# Then we'll run the fuction we built putting it into a variable so
		# we can pull these values out in the next step to create/append to 
		# our custom object
		$CDPINFO = Get-PhysPortCDPinfo

	    # Create new object from the data in the variable, and add/append
	    # That object into the array we defined in the BEGIN block
	    $ALLCDPINFO += New-Object -TypeName PSObject -Property @{
							Cluster = $CDPINFO.NcController; 
							Node = $CDPINFO.Node;
							NodePort = $CDPINFO.Port; 
							DiscoveredDevice = $CDPINFO.DiscoveredDevice; 
							SwitchInterface = $CDPINFO.Interface;
							Platform = $CDPINFO.Platform; 
							Version = $CDPINFO.Version;
                            DeviceIP = $CDPINFO.DeviceIp
		}	
	
	}
}

END {
	# This section is to output the custom object we built
	# This section can be easily modified to output the
	# custom object to a file (csv, html, xml, etc) or use 
	# the object to do further processing
	$ALLCDPINFO
}
