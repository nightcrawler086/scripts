# Defining our parameters 
[CmdletBinding()]
Param (
	[Parameter(Mandatory=$False,Position=1)]
	 [string[]]$Clusters,

	[Parameter(Mandatory=$False,Position=2)]
	 [string]$Hours
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

	# Interactively prompt for credentials.  Simpler and doesn't show password in clear text on the screen.
	$ClusterCreds = Get-Credential

	# Define array of Clusters if they were not passed as a parameter when the script was run
	If ($Clusters -eq $NULL) {
		$Clusters = @("Cluster1","Cluster2")
	}

	# Specify Default HOURS for comparision at 48 (2 days)
	If ($Hours -eq "$NULL") {
		Write-Host -ForegroundColor Yellow -BackgroundColor Black `
			"Hours not specified.  Using default of 48"
		$Hours = 48
	}
	
	# Defining an array to hold all of our snapmirror objects so we can compare
	# them all at once.
	$SMARRAY = @()
	
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

		# Put all snapmirror relationships from all clusters into a variable
		$SMARRAY += Get-NcSnapmirror
	}

	# Defining our time to compare against
	$TIMECOMP = (Get-Date).addhours(-($Hours))
	# Some output to the screen
	Write-Host -ForegroundColor Cyan -BackgroundColor Black `
		"Finding SnapMirror Relationships where the Newest Snapshot is older than $TIMECOMP"

	ForEach ($SM in $SMARRAY) {
		If ($SM.NewestSnapshotTimestampDT -lt $TIMECOMP) {
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				Cluster = $SM.NcController;
				Vserver = $SM.Vserver;
				RelationshipType = $SM.RelationshipType;
				Schedule = $SM.Schedule;
				SourceCluster = $SM.SourceCluster;
				SourceVolume = $SM.SourceVolume;
				SourceVserver = $SM.SourceVserver;
				DestinationCluster = $SM.DestinationCluster;
				DestinationVolume = $SM.DestinationVolume;
				DestinationVserver = $SM.DestinationVserver;
				MirrorState = $SM.MirrorState;
				UnhealthyReason = $SM.UnhealthyReason;
				RelationshipStatus = $SM.RelationshipStatus;
				NewestSnapshotTimestamp = $SM.NewestSnapshotTimestampDT
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
