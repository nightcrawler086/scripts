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

	$Clusters = @("PDCNETAPPSAS01")
	
	# Define our Functions
	function Get-SnapmirrorData {
		Get-NcSnapmirror | Where-Object {$_.SourceVserver -eq "VKDCNETAPPRD3" -and $_.RelationshipType -eq "data_protection"} | `
			Select-Object SourceVserver,SourceVolume,DestinationVserver,DestinationVolume,LastTransferSize,LastTransferDuration,Schedule,@{Name="LastTransferEndTimeStamp";Expression={[TimeZone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($_.LastTransferTimeStamp))}}
	}

	# Define Array for output
	$OUTPUT = @()

}

PROCESS {
	ForEach ($Cluster in $Clusters) {
		
		Connect-NcController $Cluster -Credential $ClusterCreds | Out-Null
		
		# Run our function defined in BEGIN block
		$DATAVAR = Get-SnapmirrorData

		ForEach ($OBJ in $DATAVAR) {
		# Create new object with properties we want
			$OUTPUT += New-Object -TypeName PSObject -Property @{
						SourceVserver = $DATAVAR.SourceVserver;
						SourceVolume = $DATAVAR.SourceVolume;
						DestinationVolume = $DATAVAR.DestinationVolume;
						DestinationVserver = $DATAVAR.DestinationVserver;
						LastTransferSize = $DATAVAR.LastTransferSize;
						LastTransferDuration = $DATAVAR.LastTransferDuration;
						Schedule = $DATAVAR.Schedule;
						LastTransferEndTimeStamp = $DATAVAR.LastTransferEndTimeStamp
			}
		}	
	}
}

END {
	# Send our output to the terminal	
	$OUTPUT
}
