# Defining our parameters, Username and Passowrd here will be used for each cluster in the array
# Commenting these out since I don't really use them.
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

	# Interactively prompt for credentials.  Simpler and doesn't show password in clear text on the screen.
	$ClusterCreds = Get-Credential

	# Define array of Clusters
	$Clusters = @("KDCNETAPP02","KDCNETAPP03","KDCNETAPP04","KDCNETAPPBKP01","KDCNETAPPSAS01","KDCNETAPPVDI01","MDCNETAPP01","PDCNETAPPSAS01","PDCNETAPPVDI01","VDCNETAPP01","VDCNETAPP02")

# Define our Functions
	function Get-ThickVolumes {
		Get-NcVol | Where-Object {$_.VolumeStateAttributes.IsNodeRoot -eq $False -and $_.VolumeStateAttributes.IsVserverRoot -eq $False -and $_.VolumeSpaceAttributes.SpaceGuarantee -eq "volume"}
	}

	# This is an empty array in which we will append the data gathered
	# from each cluster.  Again, only need to define it once.  We will
	# populate in the PROCESS block
	$OUTPUT = @()

}

PROCESS {
	ForEach ($Cluster in $Clusters) {
		# Let's connect to the cluster first...
		# Connect with credentials we defined earlier, and hide result
		Connect-NcController $Cluster -Credential $ClusterCreds | Out-Null

		# Then we'll run the fuction we built putting it into a variable so
		# we can pull these values out in the next step to create/append to
		# our custom object
		$DATAVAR = Get-ThickVolumes

		# Loop through each object and drop it into our OUTPUT variable
		ForEach ($OBJ in $DATAVAR) {
			$OUTPUT += New-Object -TypeName PSObject -Property @{
					Cluster = $OBJ.NcController;
					Volume = $OBJ.Name;
					SpaceGuarantee = $OBJ.VolumeSpaceAttributes.SpaceGuarantee;
					Aggregate = $OBJ.Aggregate;
					State = $OBJ.State;
					TotalSize = $OBJ.TotalSize;
					Used = $OBJ.Used;
					Available = $OBJ.Available
			}
		}
	}
}
END {
	# This section is to output the custom object we built
	# This section can be easily modified to output the
	# custom object to a file (csv, html, xml, etc) or use 
	# the object to do further processing
	$OUTPUT
}
