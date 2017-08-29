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
	$HASH = @{ AlertSuppress = $($TGT.AlertSuppress);
		AppID = $($TGT.AppID);
		Apps_Support_Group_Distribution_List = $($TGT.Apps_Support_Group_Distribution_List);
		Archived_By = $($TGT.Archived_By);
		Archived_Date = $($TGT.Archived_Date);
		Business_Group_Distribution_List = $($TGT.Business_Group_Distribution_List);
		Business_Sector = $($TGT.Business_Sector);
		CCP_Record_Created_By = $($TGT.CCP_Record_Created_By);
		CCP_Record_Create_Date = $($TGT.CCP_Record_Create_Date);
		CCP_Record_Modified_By = $($TGT.CCP_Record_Modified_by);
		CCP_Record_Modify_Date = $($TGT.CCP_Record_Modify_Date);
		ID = $($TGT.ID);
		NAS_Alias_vFiler = $($TGT.NAS_Alias_vFiler);
		NAS_Frame_DR = $($TGT.NAS_Frame_DR);
		NAS_Frame_PROD = $($TGT.NAS_Frame_PROD);
		NAS_Qtree = $($TGT.NAS_Qtree);
		NAS_VDM_vFiler = $($TGT.NAS_VDM_vFiler);
		NAS_Volume = $($TGT.NAS_Volume);
		Netbackup_Policy = $($TGT.Netbackup_Policy);
		NotificationSetting = $($TGT.NotificationSetting);
		Region = $($TGT.Region);
		SA_Support_Group_Distribution_List = $($TGT.SA_Support_Group_Distribution_List);
		SNOW_ChangeManagement = $($TGT.SNOW_ChangeManagement);
		SNOW_GreenZoneEnd = $($TGT.SNOW_GreenZoneEnd);
		SNOW_GreenZoneFrequency = $($TGT.SNOW_GreenZoneFrequency);
		SNOW_GreenZoneStart = $($TGT.SNOW_GreenZoneStart);
		Vendor = $($TGT.Vendor)
	}
	# Our output array
    $OUTPUT = @()
}

PROCESS {

	$TIMER = [System.Diagnostics.StopWatch]::StartNew()
	# Importing required files

	$TRACKER = Import-Csv $MappingFile | Where-Object {$_.Status -eq "5. Completed" -or $_.Status -eq "4. Pending Offline"}
	$TRACKER = $TRACKER | Where-Object {$_.'Target VDM' -ne "" -and $_.'Target VDM' -ne "N/A" -and $_.'Target VDM' -ne $NULL}
	$TRACKER = $TRACKER | Where-Object {$_.'Prod File System' -ne "" -and $_.'Prod File System' -ne "N/A" -and $_.'Prod File System' -ne $NULL}
	#$NASCCP = $NASCCP | Where-Object {$_."$($SAPROPS[0])" -eq "" -or $_."$($SAPROPS[0])" -eq "0" -and
	#									$_."$($SAPROPS[1])" -eq "" -or $_."$($SAPROPS[1])" -eq "0" -and
	#										$_."$($SAPROPS[2])" -eq "" -or $_."$($SAPROPS[2])" -eq "0"}
	$COUNT = $TRACKER | Measure-Object
	Write-Host "$($COUNT.Count) objects in tracker to compare"
	$COUNTER = 0
	# Conditions go here
	ForEach ($ROW in $TRACKER) {
		Write-Host "$COUNTER objects compared..."
		#$VDM = "$($ROW.'Target VDM')"
		#$VDM = $VDM.Replace("vnaz","vnas")
		#Write-Host "Source= VDM: $($ROW.'NETAPP Prod VFiler') | Volume=$($ROW.'NETAPP Prod Volume')"
		#Write-Host "Target= VDM: $($ROW.'Target VDM') / $VDM | Volume=$($ROW.'Prod File System')"
		$SRC = $NASCCP | Where-Object {$_.NAS_Frame_PROD -eq "$($ROW.'NETAPP Prod Filer')" -and $_.NAS_Volume -eq "$($ROW.'NETAPP Prod Volume')"}
		$TGT = $NASCCP | Where-Object {$_.NAS_Frame_PROD -eq "$($ROW.'Target PROD VNX Frame')" -and $_.NAS_Volume -eq "$($ROW.'Prod File System')"}
		#Write-Host "Matching Source Volume Record: $SRC"
		#Write-Host "Matching Target Volume Record: $TGT"
		If ($TGT -and $SRC) {
			$OBJ = New-Object -TypeName PSObject -Property $HASH
			#Write-Host "Found Source and Target volume match in NASCCP"
			ForEach ($PROP in $SAPROPS) {
				If ($($SRC.$PROP) -ne "" -and $($SRC.$PROP) -ne "0") {
					$OBJ | Add-Member -NotePropertyMembers @{"$PROP"="$($SRC.'$PROP')"}
					$OBJ | Add-Member -NotePropertyMembers @{"${PROP}Modified"="SourceVolRecord"}
					#Write-Host "Used Source Volume Record for $($TGT.NAS_VDM_vFiler):$($TGT.NAS_Volume) $PROP"
				}
			}
		}
		ElseIf ($TGT) {
			$OBJ = New-Object -TypeName PSObject -Property $HASH
			#Write-Host "Only found target volume in NASCCP"
			If ($($ROW.'SA SNOW Queue Name') -ne "" -and $($ROW.'SA SNOW Queue Name') -ne "0" -and
				$($ROW.'SA SNOW Queue Name') -ne "#N/A" -and $($ROW.'SA SNOW Queue Name') -ne "NULL") {
				ForEach ($PROP in $SAPROPS) {
					$OBJ | Add-Member -NotePropertyMembers @{"$PROP"="$($ROW.'SA SNOW Queue Name')"}
					$OBJ | Add-Member -NotePropertyMembers @{"${PROP}Modified"="Tracker"}
					#Write-Host "Tracker for $($TGT.NAS_VDM_vFiler):$($TGT.NAS_Volume) Property $PROP"
				}
			}
		}
	$OUTPUT += $OBJ
	$COUNTER++
	}
}

END{

$OUTPUT

}
