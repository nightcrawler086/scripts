# This is a script to pull LACP interface groups with down ports from an array of clusters

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
		
		# Getting all Dedupe/Compression Volumes
		$SISVOLS = Get-NcSis

		ForEach ($VOL in $SISVOLS) {
			# Get the `Get-NcVol` properties for the SISVOLS
			$VOLDATA = $VOL | Select-Object @{Name="Name";Expression={$_.Path}} | Get-NcVol
			$OUTPUT += New-Object -TypeName PSObject -Property @{
						Cluster = $VOLDATA.NcController;
						SVM = $VOLDATA.Vserver;
						Volume = $VOLDATA.Name
						Dedupe = $VOLDATA.Dedupe;
						Compression = $VOL.IsCompressionEnabled;
						State = $VOL.State;
						CompressionSpaceSaved = $VOLDATA.VolumeSisAttributes.CompressionSpaceSaved;
						DedupeSpaceSaved = $VOLDATA.VolumeSisAttributes.DeduplicationSpaceSaved;
						CompressionSpaceSavedPercent = $VOLDATA.VolumeSisAttributes.PercentageCompressionSpaceSaved;
						DedupeSpaceSavedPercent = $VOLDATA.VolumeSisAttributes.PercentageDeduplicationSpaceSaved;
						TotalSpaceSaved = $VOLDATA.VolumeSisAttributes.TotalSpaceSaved;
						TotalSpaceSavedPercent = $VOLDATA.VolumeSisAttributes.PercentageTotalSpaceSaved;
						Progress = $VOL.Progress;
						LastSuccessfulOperation = $VOL.LastSuccessOpEndTimestampDT;
						LastOpState = $VOL.LastOpState;
						LastOpTimeEndTimestampDT = $VOL.LastOpEndTimestampDT;
						ScheduleOrPolicy = $VOL.ScheduleOrPolicy
						
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
