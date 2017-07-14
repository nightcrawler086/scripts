[CmdletBinding()]
Param (
	[Parameter(Mandatory=$False,Position=1)]
	 [string]$InputFile
)

BEGIN {

    $OUTPUT = @()

}

PROCESS {

	$TIMER = [System.Diagnostics.StopWatch]::StartNew()
	# Importing required files
	$NASCCP = Import-Csv 'NASCCP.csv'

	$TRACKER = Import-Csv $InputFile | Where-Object {$_.Status -ne "5. Completed" -and $_.Status -ne "4. Pending Offline"}
	$TRACKER = $TRACKER | Where-Object {$_.'Target VDM' -ne "" -and $_.'Target VDM' -ne "N/A" -and $_.'Target VDM' -ne $NULL}
	$TRACKER = $TRACKER | Where-Object {$_.'Prod File System' -ne "" -and $_.'Prod File System' -ne "N/A" -and $_.'Prod File System' -ne $NULL}
	$COUNT = $TRACKER | Measure-Object
	Write-Host "$($COUNT.Count) objects to compare"
	#$TRACKER | Select-Object 'Target VDM','Prod File System'
	$COUNTER = 0
	# Conditions go here
	ForEach ($ROW in $TRACKER) {
<#
		$SLICE = @()
		If ($OBJ = $NASCCP | Where-Object {$_.NAS_VDM_vFiler -eq "$($ROW.'Target VDM')" -and $_.NAS_Volume -eq "$($ROW.'Prod File System')"}) {
			$SLICE += $OBJ
		} Else {
			$VDM = "$($OBJ.NAS_VDM_vFiler)"
			$VDM = $VDM.Replace("vnaz","vnas")
			If ($OBJ = $NASCCP | Where-Object {$_.NAS_VDM_vFiler -eq "$VDM" -and $_.NAS_Volume -eq "$($ROW.'Prod File System')"}) {
				$SLICE += $OBJ
			}
		}

		ForEach ($REC in $SLICE) {
			If ($($REC.NAS_VDM_vFiler) -and $($REC.NAS_Volume)) {
#>
				$COUNTER++
				$OUTPUT += New-Object -TypeName PSObject -Property @{
					ID = $OBJ.ID;
					NAS_Frame_PROD = $ROW.'Target Prod Frame';
					NAS_VDM_vFiler = $ROW.'Target VDM';
					NAS_Alias_vFiler = $ROW.'3 DNS cname entry';
					NAS_Volume = $ROW.'Prod File System';
					NAS_Qtree = $ROW.'Qtree & share name';
					NAS_Frame_DR = $ROW.'Target COB VNX Frame'; 
					Vendor = "emc";
					Business_Group_Distribution_List = "*CTI GLOBAL EX CIS HIA NAS TR & MIGRATIONS";
					SA_Support_Group_Distribution_List = "*CTI GLOBAL EX CIS HIA NAS TR & MIGRATIONS";
					Apps_Support_Group_Distribution_List = "*CTI GLOBAL EX CIS HIA NAS TR & MIGRATIONS";
					Business_Sector = "CRP";
					SA_SNOW_Queue = "CTI GL EX CIS HIA NAS TR & MIGRATIONS";
					App_SNOW_Queue = "CTI GL EX CIS HIA NAS TR & MIGRATIONS";
					Dispatch_Alert_SNOW_Queue = "CTI GL EX CIS HIA NAS TR & MIGRATIONS";
					AlertSuppress = "1";
					SNOW_ChangeManagement = "";
					SNOW_GreenZoneStart = "";
					SNOW_GreenZoneEnd = "";
					Snow_GreenZoneFrequency = "";
					Netbackup_Policy = $ROW.'New Tape Policy Name';
					NotificationSetting = "";
					INC = "";
					INC_Justification = "";
					AppID = "160157"
				}
			#}
		#}
	}
	Write-Host "$COUNTER objects matched in $($TIMER.Elapsed.TotalSeconds) seconds"
}


END{

$OUTPUT

}
