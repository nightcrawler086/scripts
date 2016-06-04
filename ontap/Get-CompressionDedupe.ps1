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
	$Clusters = @("Cluster1","Cluster2")

	# Typically define functions here
	function Get-NcVolGB {
		Get-NcVol | Select-Object Name,Vserver,@{Name="Size";Expression={$_.VolumeSpaceAttributes.Size /1024 /1024 / 1024}}, `
			@{Name="SizeUsed";Expression={$_.VolumeSpaceAttributes.SizeUsed /1024 /1024 / 1024}}, `
				@{Name="DedupeEnabled";Expression={$_.VolumeSisAttributes.IsSisVolume}}, `
					@{Name="SpaceSavedByCompression";Expression={$_.VolumeSisAttributes.CompressionSpaceSaved /1024 /1024 / 1024}}, `
						@{Name="PercentSavedByCompression";Expression={$_.VolumeSisAttributes.PercentageCompressionSpaceSaved}}, `
							@{Name="SpaceSavedByDedupe";Expression={$_.VolumeSisAttributes.DeduplicationSpaceSaved /1024 /1024 / 1024}}, `
								@{Name="PercentSpaceSavedByDedupe";Expression={$_.VolumeSisAttributes.PercentageDeduplicationSpaceSaved}}, `
									@{Name="TotalSpaceSaved";Expression={$_.VolumeSisAttributes.TotalSpaceSaved /1024 /1024 /1024}}, `
										@{Name="PercentageTotalSpaceSaved";Expression={$_.VolumeSisAttributes.PercentageTotalSpaceSaved}}
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
		$DATAVAR = Get-NcVolGB

		ForEach ($VOL in $DATAVAR) {
			# Create new object from the data in the variable, and add/append
			# That object into the array we defined in the BEGIN block
			$OUTPUT += New-Object -TypeName PSObject -Property @{
							VolumeName = $VOL.Name;
							SVM = $VOL.Vserver;
							SizeGB = $VOL.Size;
							SizeUsedGB = $VOL.SizeUsed;
							DedupeEnabled = $VOL.DedupeEnabled;
							SpaceSavedByCompressionGB = $VOL.SpaceSavedByCompression;
							PercentSavedByCompression = $VOL.PercentSavedByCompression;
							SpaceSavedByDedupeGB = $VOL.SpaceSavedByDedupe;
							PercentSavedByDedupe = $VOL.PercentSavedByDedupe;
							TotalSpaceSavedGB = $VOL.TotalSpaceSaved;
							PercentTotalSpaceSaved = $VOL.PercentTotalSpaceSaved

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
