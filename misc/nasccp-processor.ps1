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
	# Base output object (essentially a row in the nasccp file)
	# Currently not used
	<#
	$HASH = @{ AlertSuppress = $($T.AlertSuppress);
		AppID = $($T.AppID);
		Apps_Support_Group_Distribution_List = $($T.Apps_Support_Group_Distribution_List);
		Archived_By = $($T.Archived_By);
		Archived_Date = $($T.Archived_Date);
		Business_Group_Distribution_List = $($T.Business_Group_Distribution_List);
		Business_Sector = $($T.Business_Sector);
		CCP_Record_Created_By = $($T.CCP_Record_Created_By);
		CCP_Record_Create_Date = $($T.CCP_Record_Create_Date);
		CCP_Record_Modified_By = $($T.CCP_Record_Modified_by);
		CCP_Record_Modify_Date = $($T.CCP_Record_Modify_Date);
		ID = $($T.ID);
		NAS_Alias_vFiler = $($T.NAS_Alias_vFiler);
		NAS_Frame_DR = $($T.NAS_Frame_DR);
		NAS_Frame_PROD = $($T.NAS_Frame_PROD);
		NAS_Qtree = $($T.NAS_Qtree);
		NAS_VDM_vFiler = $($T.NAS_VDM_vFiler);
		NAS_Volume = $($T.NAS_Volume);
		Netbackup_Policy = $($T.Netbackup_Policy);
		NotificationSetting = $($T.NotificationSetting);
		Region = $($T.Region);
		SA_Support_Group_Distribution_List = $($T.SA_Support_Group_Distribution_List);
		SNOW_ChangeManagement = $($T.SNOW_ChangeManagement);
		SNOW_GreenZoneEnd = $($T.SNOW_GreenZoneEnd);
		SNOW_GreenZoneFrequency = $($T.SNOW_GreenZoneFrequency);
		SNOW_GreenZoneStart = $($T.SNOW_GreenZoneStart);
		Vendor = $($T.Vendor)
	}
	#>
	# Our output array
    $OUTPUT = @()
}

PROCESS {

	# Stopwatch
	#$TIMER = [System.Diagnostics.StopWatch]::StartNew()
	# Importing required files
	Write-Host "Processing Tracker"
	# Getting all volumes that have been migrated (Status = Completed or Pending Offline)
	# Filtering all invalid records
	$TRFILE = Import-Csv $MappingFile | Where-Object {$_.Status -eq "5. Completed" -or $_.Status -eq "4. Pending Offline"}
	$TRFILE = $TRFILE | Where-Object {$_.'Target VDM' -ne "" -and $_.'Target VDM' -ne "N/A" -and $_.'Target VDM' -ne $NULL}
	$TRFILE = $TRFILE | Where-Object {$_.'Prod File System' -ne "" -and $_.'Prod File System' -ne "N/A" -and $_.'Prod File System' -ne $NULL}
	Write-Host "Processing NASCCP file"
	# Remove Duplicates
	$NASCCP = $NASCCP | Sort-Object -Property NAS_Frame_PROD,NAS_Volume -Unique
	# Some Counters
	$COUNT = $TRFILE | Measure-Object
	Write-Host "$($COUNT.Count) objects in tracker to compare"
	$TOTAL = 0
	$STCOUNT = 0
	$TCOUNT = 0
	$NONE = 0
	# For each row in our tracker
	ForEach ($R in $TRFILE) {
		Write-Progress -Activity "Processed: $TOTAL | SRC/TGT: $STCOUNT | TGT: $TCOUNT | None: $NONE" -Status "Complete: $($TOTAL / $($COUNT.Count) * 100)`%"
		$S = $NASCCP | Where-Object {$_.NAS_Frame_PROD -eq "$($R.'NETAPP Prod Filer')" -and $_.NAS_Volume -eq "$($R.'NETAPP Prod Volume')"}
		$T = $NASCCP | Where-Object {$_.NAS_Frame_PROD -eq "$($R.'Target PROD VNX Frame')" -and $_.NAS_Volume -eq "$($R.'Prod File System')"}
		If ($T -and $S) {
			# Creates an empty hash table
			$HT = @{}
			# Loops through properties in target object, adds their
			# name/value pairs to the empty hash table
			$T.PSObject.Properties | Foreach { $HT[$_.Name] = $_.Value }
			# Creates a new object with our hash table
			$OBJ = New-Object -TypeName PSObject -Property $HT
			ForEach ($P in $SAPROPS) {
				If ($($S.$P) -ne "" -and $($S.$P) -ne "0" -and $($S.$P) -notlike "N*A") {
					# Replace empty target property with source property
					$OBJ.$P = "$($S.$P)"
					# Add new property showing where the above value is sourced
					$OBJ | Add-Member -NotePropertyMembers @{"${P}Modified"="SourceVolume"}
				}
			}
			$OUTPUT += $OBJ
			$STCOUNT++
		}
		ElseIf (!$S -and $T) {
			If ($($R.'SA SNOW Queue Name') -ne "" -and $($R.'SA SNOW Queue Name') -ne "0" -and
				$($R.'SA SNOW Queue Name') -ne "#N/A" -and $($R.'SA SNOW Queue Name') -ne "NULL") {
				# Creates an empty hash table
				$HT = @{}
				# Loops through properties in target object, adds their
				# name/value pairs to the empty hash table
				$T.PSObject.Properties | Foreach { $HT[$_.Name] = $_.Value }
				# Creates a new object with our hash table
				$OBJ = New-Object -TypeName PSObject -Property $HT
				ForEach ($P in $SAPROPS) {
					# Replaces property in target object with value from our tracker
					$OBJ.$P = $($R.'SA SNOW Queue Name')
					$OBJ | Add-Member -NotePropertyMembers @{"${P}Modified"="Tracker"}
				}
			$OUTPUT += $OBJ
			$TCOUNT++
			}
		}
		Else { $NONE++ }
		$TOTAL++
	}
}

END{

	Write-Host "Totals:"
	Write-Host "$TOTAL objects processed"
	Write-Host "$STCOUNT objects found match for Source and Target"
	Write-Host "$TCOUNT objects only found match for Target only"
	Write-Host "$NONE objects found no match in NASCCP"
	$OUTPUT

}
