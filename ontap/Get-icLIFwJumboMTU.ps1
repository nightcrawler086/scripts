# Defining our parameters, Username and Passowrd here will be used for each cluster in the array
#[CmdletBinding()]
#Param (
#	[Parameter(Mandatory=$False,Position=1)]
#	 [string[]]$Clusters,
#
#	[Parameter(Mandatory=$True,Position=2)]
#	 [string]$Username,
#
#	[Parameter(Mandatory=$True,Position=3)]
#	 [string]$Password
#)

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

	# Prompt for credentials
    # Same credentials will be used for each cluster in PROCESS block
	$ClusterCreds = Get-Credential

	# Define array of Clusters
	$Clusters = @("KDCNETAPP02","KDCNETAPP03","KDCNETAPPBKP01","KDCNETAPPBKP02","KDCNETAPPGIS01","KDCNETAPPSAS01","KDCNETAPPVDI01","MDCNETAPP01","PDCNETAPPSAS01","PDCNETAPPVDI01","VDCNETAPP01","VDCNETAPP02") #gitignore
    
    # Processing Functions

    function Get-InterClusterLifs {
        Get-NcNetInterface -Role intercluster
    }

    # Define variable to fill for output
	$OUTPUT = @()

}

PROCESS {
	ForEach ($Cluster in $Clusters) {
		# Let's connect to the cluster first...
		# Connect with credentials we defined earlier, and hide result
		Connect-NcController $Cluster -Credential $ClusterCreds | Out-Null
		
        # Get intercluster LIFs and store in variable
        $ICLIFS = Get-InterClusterLIfs

		ForEach ($ICLIF in $ICLIFS) {
            # Get ports intercluster LIFs are using
            $ICLIFPORTS = $ICLIF | Select-Object @{Name="Node";Expression={$_.HomeNode -join ','}},@{Name="Port";Expression={$_.HomePort -join ','}} | Get-NcNetPort

            # Create a new object with properties we want
            $OUTPUT += New-Object -TypeName PSObject -Property @{
                Cluster = $ICLIF.NcController;
                HomeNode = $ICLIF.HomeNode;
                HomePort = $ICLIF.HomePort;
                HomePortType = $ICLIFPORTS.PortType;
                HomePortMtu = $ICLIFPORTS.Mtu;
                CurrentNode = $ICLIF.CurrentNode;
                CurrentPort = $ICLIF.CurrentPort;
                FailoverGroup = $ICLIF.FailoverGroup
                LifName = $ICLIF.InterfaceName;
                Address = $ICLIF.Address;
                Bitmask = $ICLIF.NetmaskLength
            }
        }
	}	
}

END {
    # Dump our output to the screen.
    # modify output on the line vs. the script
	$OUTPUT
}
