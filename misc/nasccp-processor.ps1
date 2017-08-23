[CmdletBinding()]
Param (
	[Parameter(Mandatory=$True,Position=1)]
	 [string]$MappingFile,

	[Parameter(Mandatory=$True,Position=2)]
	 [string]$NasccpFile
)

BEGIN {

	# Import the NASCCP CSV File
	$NASCCP = Import-Csv $NasccpFile
	# Defining the Properties that we need to compare
	$SAPROPS = @("SA_SNOW_Queue","App_SNOW_Queue","Dispatch_Alert_SNOW_Queue")
	# Our output array
    $OUTPUT = @()
}

PROCESS {

	$TIMER = [System.Diagnostics.StopWatch]::StartNew()
	# Importing required files

	$TRACKER = Import-Csv $MappingFile | Where-Object {$_.Status -eq "5. Completed"}
	$TRACKER = $TRACKER | Where-Object {$_.'Target VDM' -ne "" -and $_.'Target VDM' -ne "N/A" -and $_.'Target VDM' -ne $NULL}
	$TRACKER = $TRACKER | Where-Object {$_.'Prod File System' -ne "" -and $_.'Prod File System' -ne "N/A" -and $_.'Prod File System' -ne $NULL}
	$NASCCP = $NASCCP | Where-Object {$_."$($SAPROPS[0])" -eq "" -or $_."$($SAPROPS[0])" -eq "0" -and
										$_."$($SAPROPS[1])" -eq "" -or $_."$($SAPROPS[1])" -eq "0" -and
											$_."$($SAPROPS[2])" -eq "" -or $_."$($SAPROPS[2])" -eq "0"}
	$COUNT = $TRACKER | Measure-Object
	Write-Host "$($COUNT.Count) objects to compare"
	$COUNTER = 0
	# Conditions go here
	ForEach ($ROW in $TRACKER) {
		Write-Host "$COUNTER objects compared..."
		$VDM = "$($ROW.'Target VDM')"
		$VDM = $VDM.Replace("vnaz","vnas")
		$SRC = $NASCCP | Where-Object {$_.NAS_VDM_vFiler -eq "$($ROW.'NETAPP Prod VFiler')" -and $_.NAS_Volume -eq "$($ROW.'NETAPP Prod Volume')"}
		$TGT = $NASCCP | Where-Object {$_.NAS_VDM_vFiler -eq "$VDM" -and $_.NAS_Volume -eq "$($ROW.'Prod File System')"}
		If ($TGT -and $SRC) {
			ForEach ($PROP in $SAPROPS) {
				If ($($SRC."$PROP") -ne "" -and $($SRC."$PROP") -ne "0") {
					$TGT.$PROP="$($SRC."$PROP")"
					$TGT = $TGT | Add-Member -NotePropertyMembers @{"${PROP}Modified"="SourceVolRecord"}
					Write-Host "Used Source Volume Record for $($TGT.NAS_VDM_vFiler):$($TGT.NAS_Volume) $PROP"
				}
			}
			ElseIf ($TGT) {
				If ($($ROW.'SA SNOW Queue Name') -ne "" -or $($ROW.'SA SNOW Queue Name') -eq "0" -or
					$($ROW.'SA SNOW Queue Name') -eq "#N/A" -or $($ROW.'SA SNOW Queue Name') -eq "NULL") {
					ForEach ($PROP in $SAPROPS) {
						$TGT.$PROP="$($ROW.'SA SNOW Queue Name')"
						$TGT = $TGT | Add-Member -NotePropertyMembers @{"${PROP}Modified"="Tracker"}
						Write-Host "Tracker for $($TGT.NAS_VDM_vFiler):$($TGT.NAS_Volume) Property $PROP"
					}
				}
			}
		}
		$COUNTER++
		$OUTPUT += $TGT
	}
}

END{

$OUTPUT

}
