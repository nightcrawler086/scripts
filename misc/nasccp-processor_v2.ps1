[CmdletBinding()]
Param (
	[Parameter(Mandatory=$True,Position=1)]
	 [string]$NASCCP,

	[Parameter(Mandatory=$True,Position=1)]
	 [string]$TRACKER
)

BEGIN {

	# Storing object properties in a variable
	# Hopefully to shorten code in PROCESS block
	$PROPS = @{ID = $OBJ.ID;
			NAS_Frame_PROD = "";
			NAS_VDM_vFiler = "";
			NAS_Alias_vFiler = "";
			NAS_Volume = "";
			NAS_Qtree = "";
			NAS_Frame_DR = "";
			Vendor = "emc";
			Business_Group_Distribution_List = "";
			SA_Support_Group_Distribution_List = "";
			Apps_Support_Group_Distribution_List = "";
			Business_Sector = "";
			SA_SNOW_Queue = "";
			App_SNOW_Queue = "";
			Dispatch_Alert_SNOW_Queue = "";
			AlertSuppress = "0";
			SNOW_ChangeManagement = "";
			SNOW_GreenZoneStart = "";
			SNOW_GreenZoneEnd = "";
			Snow_GreenZoneFrequency = "";
			Netbackup_Policy = "";
			NotificationSetting = "";
			INC = "";
			INC_Justification = "";
			AppID = ""
			}

    $OUTPUT = @()

}

PROCESS {

	# Get all rows from tracker that are completed or pending offline
	$TRACKER = Import-Csv $TRACKER | Where-Object {$_.Status -eq "5. Completed" -or $_.Status -eq "4. Pending Offline"}
	# Remove all rows that have empty ''Target VDM' property
	$TRACKER = $TRACKER | Where-Object {$_.'Target VDM' -ne "" -and $_.'Target VDM' -ne "*N/A" -and $_.'Target VDM' -ne $NULL}
	# Remove all rows that have empty 'Prod File System' property
	$TRACKER = $TRACKER | Where-Object {$_.'Prod File System' -ne "" -and $_.'Prod File System' -ne "N/A" -and $_.'Prod File System' -ne $NULL}
	$COUNT = $TRACKER | Measure-Object
	Write-Host "$($COUNT.Count) objects to compare"

	$COUNTER = 0

	# Start the stopwatch
	$TIMER = [System.Diagnostics.StopWatch]::StartNew()
	ForEach ($R in $TRACKER) {
		$VDM = $($R.'Target VDM')
		If ($VDM -contains "vnaz") {
			$VDM = $VDM.Replace("vnaz","vnas")
		}
		If ($VDM -contains "vnas") {
			$VDM = $VDM.Replace("vnas","vnaz")
		}
		# Look for record matching Target VDM and Target Volume in NASCCP
		$TGT = $NASCCP | Where-Object {
			$_.NAS_VDM_vFiler -eq "$($R.'Target VDM')" -or $_.NAS_VDM_vFiler -eq "$VDM" -and $_.NAS_Volume -eq "$($R.'Prod File System')"}
		# Look for record matching Source Volume to pull info from
		$SRC = $NASCCP | Where-Object {
			$_.NAS_VDM_vFiler -eq "$($R.'NETAPP Prod VFiler')" -and $_.NAS_Volume -eq "$($R.'NETAPP Prod Volume')"}
		If (!$TGT) {
			Write-Output "Could not match $($R.'Target VDM'): $($R.'Prod File System') with a record in NASCCP file"
			Continue
			# ###################################################### #
			# Need to add code to create new record here from $PROPS #
			# ###################################################### #
		}
		# Select the Property Names we need to validate
		# Not sure the next 3 lines will be required
		#$TGTPROPS = (($TGT | Get-Member) | Select-Object -Property *).Name
		#$TGTPROPS = $TGTPROPS | Select-Object -Property SA_SNOW_Queue,Apps_Support_Group_Distribution_List,
		#	SA_Support_Group_Distribution_List,App_SNOW_Queue,Business_Group_Distribution_List,Dispatch_Alert_SNOW_Queue
		#
		# This is a very long If statement to check if the SA Information for the completed volume
		# is empty, or has the NAS TR team's information already in it.
		If ( $($TGT.SA_SNOW_Queue) -eq "" -or $($TGT.SA_SNOW_Queue) -eq "CTI GL EX CIS HIA NAS TR & MIGRATIONS" -and
			 $($TGT.Apps_Support_Group_Distribution_List) -eq "" -or
			 	$($TGT.Apps_Support_Group_Distribution_List) -eq "*CTI GLOBAL EX CIS HIA NAS TR & MIGRATIONS" -and
			 $($TGT.SA_Support_Group_Distribution_List) -eq "" -or
			 	$($TGT.SA_Support_Group_Distribution_List) -eq "*CTI GLOBAL EX CIS HIA NAS TR & MIGRATIONS" -and
			 $($TGT.App_SNOW_Queue) -eq "" -or $($TGT.App_SNOW_Queue) -eq "CTI GL EX CIS HIA NAS TR & MIGRATIONS" -and
			 $($TGT.Business_Group_Distribution_List) -eq "" -or
			 	$($TGT.Business_Group_Distribution_List) -eq "*CTI GLOBAL EX CIS HIA NAS TR & MIGRATIONS" -and
			$($TGT.Dispatch_Alert_SNOW_Queue) -eq "" -or
			$($TGT.Dispatch_Alert_SNOW_Queue) -eq "CTI GL EX CIS HIA NAS TR & MIGRATIONS"
		   )
		   	# If the target volume SA info is empty, or has the NAS TR team's information as the SA info
			# Then the following If statement checks if the source volume is empty or has the NAS TR team's info
			# ****If the source volume SA info isn't empty or has the NAS TR team's info, then
			# we update the target volume with the source volume's SA info, and add it to our output variable
			{ If ( $($SRC.SA_SNOW_Queue) -ne "" -and $($SRC.SA_SNOW_Queue) -ne "CTI GL EX CIS HIA NAS TR & MIGRATIONS" -and
			 		$($SRC.Apps_Support_Group_Distribution_List) -ne "" -and
			 			$($SRC.Apps_Support_Group_Distribution_List) -ne "*CTI GLOBAL EX CIS HIA NAS TR & MIGRATIONS" -and
			 		$($SRC.SA_Support_Group_Distribution_List) -ne "" -and
			 			$($SRC.SA_Support_Group_Distribution_List) -ne "*CTI GLOBAL EX CIS HIA NAS TR & MIGRATIONS" -and
			 		$($SRC.App_SNOW_Queue) -ne "" -or $($SRC.App_SNOW_Queue) -ne "CTI GL EX CIS HIA NAS TR & MIGRATIONS" -and
			 		$($SRC.Business_Group_Distribution_List) -ne "" -and
			 			$($SRC.Business_Group_Distribution_List) -ne "*CTI GLOBAL EX CIS HIA NAS TR & MIGRATIONS" -and
					$($SRC.Dispatch_Alert_SNOW_Queue) -ne "" -and
						$($SRC.Dispatch_Alert_SNOW_Queue) -ne "CTI GL EX CIS HIA NAS TR & MIGRATIONS"
			   ) { $TGT.SA_SNOW_Queue="$($SRC.SA_SNOW_Queue)"
			   	   $TGT.Apps_Support_Group_Distribution_List="$($SRC.Apps_Support_Group_Distribution_List)"
				   $TGT.SA_Support_Group_Distribution_List="$($SRC.SA_Support_Group_Distribution_List)"
				   $TGT.App_SNOW_Queue="$($SRC.App_SNOW_Queue)"
				   $TGT.Business_Group_Distribution_List="$($SRC.Business_Group_Distribution_List)"
				   $TGT.Dispatch_Alert_SNOW_Queue="$($SRC.Dispatch_Alert_SNOW_Queue)"
				   $OUTPUT += $TGT
		   		  } ElseIf {
					# Fill with info from OST data, if it exits
					} ElseIf {
						# Fill with info from Tracker, if it exists
					  } Else { # Could not find SA info anywhere }
				$COUNTER++
			}
		}
	}
	Write-Host "$COUNTER objects matched in $($TIMER.Elapsed.TotalSeconds) seconds"
}


END{

$OUTPUT

}
