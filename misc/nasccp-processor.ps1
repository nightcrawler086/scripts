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

	# Importing required files
	# Getting all volumes that have been migrated (Status = Completed or Pending Offline)
	# Filtering all invalid records
	$TRFILE = Import-Csv $MappingFile | Where-Object {$_.Status -eq "5. Completed" -or $_.Status -eq "4. Pending Offline"}
	$TRFILE = $TRFILE | Where-Object {$_.'Target Prod VNX Frame' -ne "" -and $_.'Target Prod VNX Frame' -ne "N/A" -and $_.'Target Prod VNX Frame' -ne $NULL}
	$TRFILE = $TRFILE | Where-Object {$_.'Prod File System' -ne "" -and $_.'Prod File System' -ne "N/A" -and $_.'Prod File System' -ne $NULL}
	# Remove Duplicates
	$NASCCP = $NASCCP | Sort-Object -Property NAS_Frame_PROD,NAS_Volume -Unique
	# Some Counters
	$COUNT = $TRFILE | Measure-Object
	Write-Host "$($COUNT.Count) objects in tracker to compare"
	$TOTAL = 0
	# For each row in our tracker
	ForEach ($R in $TRFILE) {
		Write-Progress -Activity "Processed: $TOTAL | Complete: $($TOTAL / $($COUNT.Count) * 100)`%"
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
				# If the Target record's SAPROPS don't need updating
				If ( $($T.$P) -ne ""  -and $($T.$P) -ne "0" -and $($T.$P) -notlike "N?A" -and $($T.$P) -notlike "*NAS TR & MIGRATIONS*") {
					$OBJ | Add-Member -NotePropertyMembers @{"${P}_Source"="TargetVolumeRecord"}
					$OBJ | Add-Member -NotePropertyMembers @{"${P}_Original"="$($T.$P)"}
				}
				# If Source Volume Record is Valid, use it
				ElseIf ( $($S.$P) -ne "" -and $($S.$P) -ne "0" -and $($S.$P) -notlike "N*A" -and $($T.$P) -notlike "*NAS TR & MIGRATIONS*") {
					# Replace target property with source property
					$OBJ.$P = "$($S.$P)"
					# Add new property showing where the above value is sourced
					$OBJ | Add-Member -NotePropertyMembers @{"${P}_Source"="SourceVolumeRecord"}
					$OBJ | Add-Member -NotePropertyMembers @{"${P}_Original"="$($T.$P)"}
				}
				# If the Tracker's value is valid, use it
				ElseIf ($($R.'SA SNOW Queue Name') -ne "" -and $($R.'SA SNOW Queue Name') -ne "0" -and
				$($R.'SA SNOW Queue Name') -ne "#N/A" -and $($R.'SA SNOW Queue Name') -ne "NULL") {
					# Replaces property in target object with value from our tracker
					$OBJ.$P = $($R.'SA SNOW Queue Name')
					$OBJ | Add-Member -NotePropertyMembers @{"${P}_Source"="Tracker"}
					$OBJ | Add-Member -NotePropertyMembers @{"${P}_Original"="$($T.$P)"}
				}
				# Else do nothing
				Else {
					$OBJ | Add-Member -NotePropertyMembers @{"${P}_Source"="None"}
					$OBJ | Add-Member -NotePropertyMembers @{"${P}_Original"="$($T.$P)"}
				}		
			}
			$OUTPUT += $OBJ
		}
		ElseIf (!$S -and $T) {
			# Creates an empty hash table
			$HT = @{}
			# Loops through properties in target object, adds their
			# name/value pairs to the empty hash table
			$T.PSObject.Properties | Foreach { $HT[$_.Name] = $_.Value }
			# Creates a new object with our hash table
			$OBJ = New-Object -TypeName PSObject -Property $HT
			If ( !$($T.$P) -and $($T.$P) -ne "0" -and $($T.$P) -notlike "N?A" -and $($T.$P) -notlike "*NAS TR & MIGRATIONS*") {
					$OBJ | Add-Member -NotePropertyMembers @{"${P}_Source"="TargetVolumeRecord"}
					$OBJ | Add-Member -NotePropertyMembers @{"${P}_Original"="$($T.$P)"}
			} ElseIf ($($R.'SA SNOW Queue Name') -ne "" -and $($R.'SA SNOW Queue Name') -ne "0" -and
				$($R.'SA SNOW Queue Name') -ne "#N/A" -and $($R.'SA SNOW Queue Name') -ne "NULL") {
				ForEach ($P in $SAPROPS) {
					# Replaces property in target object with value from our tracker
					$OBJ.$P = $($R.'SA SNOW Queue Name')
					$OBJ | Add-Member -NotePropertyMembers @{"${P}_Source"="Tracker"}
					$OBJ | Add-Member -NotePropertyMembers @{"${P}_Original"="$($T.$P)"}
				}
			}
			Else {
				$OBJ | Add-Member -NotePropertyMembers @{"${P}_Source"="None"}
				$OBJ | Add-Member -NotePropertyMembers @{"${P}_Original"="$($T.$P)"}
			}
			$OUTPUT += $OBJ
		}
		ElseIf ($S -and !$T) {
			$OBJ = New-Object -TypeName PSObject -Property @{ AlertSuppress = "0";
				AppID = "";
				Apps_Support_Group_Distribution_List = "";
				App_SNOW_Queue = "";
				Archived_By = "";
				Archived_Date = "";
				Business_Group_Distribution_List = "";
				Business_Sector = "";
				CCP_Record_Created_By = "BH53965";
				CCP_Record_Create_Date = "";
				CCP_Record_Modified_By = "";
				CCP_Record_Modify_Date = "";
				Dispatch_Alert_SNOW_Queue = "";
				ID = "";
				NAS_Alias_vFiler = $($R.'3 DNS cname entry');
				NAS_Frame_DR = $($R.'Target Cob VNX Frame');
				NAS_Frame_PROD = $($R.'Target Prod VNX Frame');
				NAS_Qtree = $($R.'Qtree & share name');
				NAS_VDM_vFiler = $($R.'Target VDM');
				NAS_Volume = $($R.'Prod File System');
				Netbackup_Policy = $($R.'New Tape Policy Name');
				NotificationSetting = "";
				Region = "NAM";
				SA_SNOW_Queue = "";
				SA_Support_Group_Distribution_List = $($R.'SA SNOW Queue Name');
				SNOW_ChangeManagement = "";
				SNOW_GreenZoneEnd = "";
				SNOW_GreenZoneFrequency = "";
				SNOW_GreenZoneStart = "";
				Vendor = "emc"
			}
			ForEach ($P in $SAPROPS) {
				If ( $($S.$P) -ne "" -and $($S.$P) -ne "0" -and $($S.$P) -notlike "N*A" -and $($T.$P) -notlike "*NAS TR & MIGRATIONS*") {
					# Replace target property with source property
					$OBJ.$P = "$($S.$P)"
					# Add new property showing where the above value is sourced
					$OBJ | Add-Member -NotePropertyMembers @{"${P}_Source"="SourceVolumeRecord"}
					$OBJ | Add-Member -NotePropertyMembers @{"${P}_Original"="None"}
				}
				ElseIf ($($R.'SA SNOW Queue Name') -ne "" -and $($R.'SA SNOW Queue Name') -ne "0" -and
				$($R.'SA SNOW Queue Name') -ne "#N/A" -and $($R.'SA SNOW Queue Name') -ne "NULL") {
					$OBJ.$P = "$($R.'SA SNOW Queue Name')"
					$OBJ | Add-Member -NotePropertyMembers @{"${P}_Source"="Tracker"}
					$OBJ | Add-Member -NotePropertyMembers @{"${P}_Original"="None"}
				}
				Else {
				$OBJ | Add-Member -NotePropertyMembers @{"${P}_Source"="None"}
				$OBJ | Add-Member -NotePropertyMembers @{"${P}_Original"="$($T.$P)"}
				}	
			}
			$OUTPUT += $OBJ
		}
		Else { 
			$OBJ = New-Object -TypeName PSObject -Property @{ AlertSuppress = "0";
				AppID = "";
				Apps_Support_Group_Distribution_List = "";
				App_SNOW_Queue = "";
				Archived_By = "";
				Archived_Date = "";
				Business_Group_Distribution_List = "";
				Business_Sector = "";
				CCP_Record_Created_By = "BH53965";
				CCP_Record_Create_Date = "";
				CCP_Record_Modified_By = "";
				CCP_Record_Modify_Date = "";
				Dispatch_Alert_SNOW_Queue = "";
				ID = "";
				NAS_Alias_vFiler = $($R.'3 DNS cname entry');
				NAS_Frame_DR = $($R.'Target Cob VNX Frame');
				NAS_Frame_PROD = $($R.'Target Prod VNX Frame');
				NAS_Qtree = $($R.'Qtree & share name');
				NAS_VDM_vFiler = $($R.'Target VDM');
				NAS_Volume = $($R.'Prod File System');
				Netbackup_Policy = $($R.'New Tape Policy Name');
				NotificationSetting = "";
				Region = "NAM";
				SA_SNOW_Queue = "";
				SA_Support_Group_Distribution_List = $($R.'SA SNOW Queue Name');
				SNOW_ChangeManagement = "";
				SNOW_GreenZoneEnd = "";
				SNOW_GreenZoneFrequency = "";
				SNOW_GreenZoneStart = "";
				Vendor = "emc"
			}
			ForEach ($P in $SAPROPS) {
				If ($($R.'SA SNOW Queue Name') -ne "" -and $($R.'SA SNOW Queue Name') -ne "0" -and
				$($R.'SA SNOW Queue Name') -ne "#N/A" -and $($R.'SA SNOW Queue Name') -ne "NULL") {
					# Replaces property in target object with value from our tracker
					$OBJ.$P = $($R.'SA SNOW Queue Name')
					$OBJ | Add-Member -NotePropertyMembers @{"${P}_Source"="Tracker"}
					$OBJ | Add-Member -NotePropertyMembers @{"${P}_Original"="None"}
				} 
				Else {
					$OBJ.$P = "CTI GL EX CIS HIA NAS TR & MIGRATIONS"
					$OBJ | Add-Member -NotePropertyMembers @{"${P}_Source"="Default"}
					$OBJ | Add-Member -NotePropertyMembers @{"${P}_Original"="None"}
				}
			}
			$OUTPUT += $OBJ
		}
		$TOTAL++
	}
}

END{

	$OUTPUT

}
