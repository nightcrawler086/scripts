[CmdletBinding()]
Param (
	[Parameter(Mandatory=$False,Position=1)]
	 [string[]]$SourceSystem,

	[Parameter(Mandatory=$True,Position=2)]
	 [string]$CsvFile

)

# This is our BEGIN block (also could be considered the setup block).  Code in this
# block will be run once.
BEGIN {

	# To do:
	#
	# Derive Interface Name from info in the spreadsheet (using a bunch of substrings)
	# Do not write Interface create commands if Interface does not exist (for target and targetDr)
	# Do not write VDM create commands if VDM does not exist (for target and targetDr)
	# Do not write replication commands if no destination volume in the spreadsheet
	# Actually get slot # for Qtree commands
	# Do not write FS create commands if FS does not exist (for target and targetDr)
	# Do not write mount commands if no FS exists in sheet (for target and targetDr)
	# Do not write checkpoint commands if no FS exists in sheet (for target and targetDr)
	# Write different commands sets if USERDATA/APPDATA, includes replication, or CIFS/NFS/BOTH
	
	# Begin Target Provisioning Commands
	
	function Write-IntCreateCommands {
		$SUBSET = $CSVDATA | Sort-Object -Property TargetIp -Unique
		Write-Output "### Interface Creation Commands`r`n" | Tee-Object $OUTFILE -Append
		Write-Output "**Subnet mask, broadcast address, and interface name need to be filled in manually**`r`n" | Tee-Object $OUTFILE -Append
		Write-Output "``````" | Tee-Object $OUTFILE -Append
		ForEach ($OBJ in $SUBSET) {
			Write-Output "server_ifconfig $($OBJ.TargetDM) -create -device fsn0 -name <INT_NAME> -protocol IP $($OBJ.TargetIp) <MASK> <BROADCAST>" | Tee-Object $OUTFILE -Append
		}
		Write-Output "``````" | Tee-Object $OUTFILE -Append
		Write-Output "`r`n" | Tee-Object $OUTFILE -Append
	}

	function Write-VdmCreateCommands {
		$SUBSET = $CSVDATA | Sort-Object -Property TargetVdm -Unique
		Write-Output "### VDM Creation Commands`r`n" | Tee-Object $OUTFILE -Append
		Write-Output "``````" | Tee-Object $OUTFILE -Append
		ForEach ($OBJ in $SUBSET) {
			Write-Output "nas_server -name $($OBJ.TargetVDM) -type vdm -create $($OBJ.TargetDM) -setstate loaded pool=$($OBJ.TargetStoragePool)" | Tee-Object $OUTFILE -Append
		}
		Write-Output "``````" | Tee-Object $OUTFILE -Append
		Write-Output "`r`n" | Tee-Object $OUTFILE -Append
	}

	function Write-VdmRepCommands {
		$SUBSET = $CSVDATA | Sort-Object -Property TargetVdm -Unique
		Write-Output "### VDM Replication Commands`r`n" | Tee-Object $OUTFILE -Append
		Write-Output "**Pool ID and Interconnect name need to be filled in manually**`r`n" | Tee-Object $OUTFILE -Append
		Write-Output "``````" | Tee-Object $OUTFILE -Append
		ForEach ($OBJ in $SUBSET) {
			Write-Output "nas_replicate -create $($OBJ.TargetVDM)_REP -source -vdm $($OBJ.TargetVDM) -destination -pool id=<POOL_ID> -interconnect <INTERCONNECT_NAME> -max_time_out_of_sync 10 -background" | Tee-Object $OUTFILE -Append
		}
		Write-Output "``````" | Tee-Object $OUTFILE -Append
		Write-Output "`r`n" | Tee-Object $OUTFILE -Append
	}

	function Write-FsCreateCommands {
		Write-Output "### Filesystem Creation Commands`r`n" | Tee-Object $OUTFILE -Append
		Write-Output "``````" | Tee-Object $OUTFILE -Append
		ForEach ($OBJ in $CSVDATA) {
			Write-Output "nas_fs -name $($OBJ.TargetFilesystem) -type $($OBJ.TargetSecurityStyle) -create size=$($OBJ.TargetCapacityGB)GB pool=$($OBJ.TargetStoragePool) -option slice=y" | Tee-Object $OUTFILE -Append
		}
		Write-Output "``````" | Tee-Object $OUTFILE -Append
		Write-Output "`r`n" | Tee-Object $OUTFILE -Append
	}

	function Write-FsRepCommands {
		Write-Output "### Filesystem Replication Commands`r`n" | Tee-Object $OUTFILE -Append
		Write-Output "**These commands are to be run after the base copy is completed**" | Tee-Object $OUTFILE -Append
		Write-Output "**The Interconnect name needs to be filled in manually**`r`n" | Tee-Object $OUTFILE -Append
		Write-Output "``````" | Tee-Object $OUTFILE -Append
		ForEach ($OBJ in $CSVDATA) {
			Write-Output "nas_replicate -create $($OBJ.TargetFilesystem)_REP -source -fs $($OBJ.TargetFilesystem) -destination -fs $($OBJ.TargetDrFilesystem) -interconnect <INTERCONNECT_NAME> -max_time_out_of_sync 10 -background" | Tee-Object $OUTFILE -Append
		}
		Write-Output "``````" | Tee-Object $OUTFILE -Append
		Write-Output "`r`n" | Tee-Object $OUTFILE -Append
	}

	function Write-FsDedupeCommands {
		Write-Output "### Filesystem Deduplication Commands`r`n" | Tee-Object $OUTFILE -Append
		Write-Output "**Only enable on target if enabled on the source**`r`n" | Tee-Object $OUTFILE -Append
		Write-Output "``````" | Tee-Object $OUTFILE -Append
		ForEach ($OBJ in $CSVDATA) {
			Write-Output "fs_dedupe -modify $($OBJ.TargetFilesystem) -state on" | Tee-Object $OUTFILE -Append
		}
		Write-Output "``````" | Tee-Object $OUTFILE -Append
		Write-Output "`r`n" | Tee-Object $OUTFILE -Append
	}

	function Write-FsCkptCommands {
		Write-Output "### Filesystem Checkpoint Commands`r`n" | Tee-Object $OUTFILE -Append
		Write-Output "**Only create the checkpoints after the migration has been completed**`r`n" | Tee-Object $OUTFILE -Append
		Write-Output "``````"
		ForEach ($OBJ in $CSVDATA) {
			Write-Output "nas_ckpt_schedule -create $($OBJ.TargetFilesystem)_DAILY_SCHED -filesystem $($OBJ.TargetFilesystem) -description ""1730hrs daily checkpoint schedule for $($OBJ.TargetFilesystem)"" -recurrence daily -every 1 -start_on <DATE> -runtimes 17:30 -keep 7" | Tee-Object $OUTFILE -Append
		}
		Write-Output "``````" | Tee-Object $OUTFILE -Append
		Write-Output "`r`n" | Tee-Object $OUTFILE -Append
	}

	function Write-FsMountCommands {
		Write-Output "### Mount Commands`r`n" | Tee-Object $OUTFILE -Append
		Write-Output "``````" | Tee-Object $OUTFILE -Append
		ForEach ($OBJ in $CSVDATA) {
			Write-Output "server_mount $($OBJ.TargetVDM) $($OBJ.TargetFilesystem) /$($OBJ.TargetFilesystem)" | Tee-Object $OUTFILE -Append
		} 
		Write-Output "``````" | Tee-Object $OUTFILE -Append
		Write-Output "`r`n" | Tee-Object $OUTFILE -Append
	}

	function Write-QtreeCommands {
		Write-Output "### Qtree Command`r`n" | Tee-Object $OUTFILE -Append
		Write-Output "**Slot (datamover) number and VDM number need to be filled in manually**`r`n" | Tee-Object $OUTFILE -Append
		Write-Output "``````" | Tee-Object $OUTFILE -Append
		ForEach ($OBJ in $CSVDATA) {
			Write-Output "mkdir /nasmcd/quota/slot_X/root_vdm_X/$($OBJ.TargetFilesystem)/$($OBJ.TargetFilesystem)" | Tee-Object $OUTFILE -Append
		}
		Write-Output "``````" | Tee-Object $OUTFILE -Append
		Write-Output "`r`n" | Tee-Object $OUTFILE -Append
	}

	function Write-CreateCifsServerCommands {
		$SUBSET = $CSVDATA | Sort-Object -Property TargetVDM -Unique
		Write-Output "### Create CIFS Server Commands`r`n" | Tee-Object $OUTFILE -Append
		Write-Output "**Interface name needs to be filled in manually**`r`n" | Tee-Object $OUTFILE -Append
		Write-Output "``````" | Tee-Object $OUTFILE -Append
		ForEach ($OBJ in $SUBSET) {
			Write-Output "server_cifs $($OBJ.TargetVDM) -add compname=$($OBJ.TargetVDM),domain=nam.nsroot.net,interface=<INT_NAME>,local_users" | Tee-Object $OUTFILE -Append
		}
		Write-Output "``````" | Tee-Object $OUTFILE -Append
		Write-Output "`r`n" | Tee-Object $OUTFILE -Append
	}

	function Write-JoinCifsServerCommands {
		$SUBSET = $CSVDATA | Sort-Object -Property TargetVDM -Unique
		Write-Output "### Join CIFS Server to Domain Commands`r`n" | Tee-Object $OUTFILE -Append
		Write-Output "**Admin user needs to be filled in manually**`r`n" | Tee-Object $OUTFILE -Append
		Write-Output "``````" | Tee-Object $OUTFILE -Append
		ForEach ($OBJ in $SUBSET) {
			Write-Output "server_cifs $($OBJ.TargetVDM) -join compname=$($OBJ.TargetVDM),domain=nam.nsroot.net,admin=<ADMIN_USER>,ou=Servers:ou-NAS:ou=INFRA" | Tee-Object $OUTFILE -Append
			}
		Write-Output "``````" | Tee-Object $OUTFILE -Append
		Write-Output "`r`n" | Tee-Object $OUTFILE -Append
		}

	function Write-CifsExportCommands {
		$SUBSET = $CSVDATA | Sort-Object -Property TargetFilesystem -Unique
		Write-Output "### Export CIFS Share Commands`r`n" | Tee-Object $OUTFILE -Append
		Write-Output "``````" | Tee-Object $OUTFILE -Append
		ForEach ($OBJ in $SUBSET) {
			Write-Output "server_export $($OBJ.TargetVDM) -protocol cifs -name $($OBJ.TargetFilesystem) -o netbios=$($OBJ.TargetVDM) /$($OBJ.TargetFilesystem)/$($OBJ.TargetFilesystem)" | Tee-Object $OUTFILE -Append
		}
		Write-Output "``````" | Tee-Object $OUTFILE -Append
		Write-Output "`r`n" | Tee-Object $OUTFILE -Append
	}

	# Begin Cob (DR) Provisioning Commands
	
	function Write-DrFsCreateCommands {
		Write-Output "### Cob (DR) Filesystem Creation Commands`r`n" | Tee-Object $OUTFILE -Append
		Write-Output "``````" | Tee-Object $OUTFILE -Append
		ForEach ($OBJ in $CSVDATA) {
			Write-Output "nas_fs -name $($OBJ.TargetDrFilesystem) -create samesize:$($OBJ.TargetFilesystem):$($OBJ.TargetVDM) pool:$($OBJ.TargetDrStoragePool)" | Tee-Object $OUTFILE -Append
		}
		Write-Output "``````" | Tee-Object $OUTFILE -Append
		Write-Output "`r`n" | Tee-Object $OUTFILE -Append
	}

	function Write-DrFsMountCommands {
		Write-Output "### Cob (DR) Filesystem Mount Commands`r`n" | Tee-Object $OUTFILE -Append
		Write-Output "``````" | Tee-Object $OUTFILE -Append
		ForEach ($OBJ in $CSVDATA) {
				Write-Output "server_mount $($OBJ.TargetVDM) -o ro $($OBJ.TargetDrFilesystem) /$($OBJ.TargetDrFilesystem)" | Tee-Object $OUTFILE -Append
			}
		Write-Output "``````" | Tee-Object $OUTFILE -Append
		Write-Output "`r`n" | Tee-Object $OUTFILE -Append
	}

	function Write-DrFsCkptCommands {
		Write-Output "### Cob (DR) Filesystem Checkpoint Commands`r`n" | Tee-Object $OUTFILE -Append
		Write-Output "``````" | Tee-Object $OUTFILE -Append
		ForEach ($OBJ in $CSVDATA) {
				Write-Output "nas_ckpt_schedule -create $($OBJ.TargetDrFilesystem)_DAILY_SCHED -filesystem $($OBJ.TargetDrFilesystem) -description ""1730hrs daily checkpoint schedule for $($OBJ.TargetDrFilesystem)"" -recurrence daily -every 1 -start_on <DATE> -runtimes 17:30 -keep 7" | Tee-Object $OUTFILE -Append
			}
		Write-Output "``````" | Tee-Object $OUTFILE -Append
		Write-Output "`r`n" | Tee-Object $OUTFILE -Append
	}

	function Write-DrSpnCommands {
		$SUBSET = $CSVDATA | Sort-Object -Property TargetVdm -Unique
		Write-Output "### Cob (DR) SPN Commands`r`n" | Tee-Object $OUTFILE -Append
		Write-Output "``````" | Tee-Object $OUTFILE -Append
		ForEach ($OBJ in $SUBSET) {
			Write-Output "setspn -A HOST/$($OBJ.TargetVDM) $($OBJ.TargetVDM)" | Tee-Object $OUTFILE -Append
			Write-Output "setspn -A HOST/$($OBJ.TargetVDM).wlbX.nam.nsroot.net $($OBJ.TargetVDM)" | Tee-Object $OUTFILE -Append
			Write-Output "setspn -A HOST/$($OBJ.TargetVDM).nam.nsroot.net $($OBJ.TargetVDM)" | Tee-Object $OUTFILE -Append
			Write-Output "setspn -L $($OBJ.TargetVDM)`r`n" | Tee-Object $OUTFILE -Append
		}
		Write-Output "``````" | Tee-Object $OUTFILE -Append
		Write-Output "`r`n" | Tee-Object $OUTFILE -Append
	}

	function Write-DrIntCreateCommands {
		$SUBSET = $CSVDATA | Sort-Object -Property TargetDrIp -Unique
		Write-Output "### Cob (DR) Interface Creation Commands`r`n" | Tee-Object $OUTFILE -Append
		Write-Output "``````" | Tee-Object $OUTFILE -Append
		ForEach ($OBJ in $SUBSET) {
			Write-Output "server_ifconfig $($OBJ.TargetDrDM) -create -device fsn0 -name <INT_NAME> -protocol IP $($OBJ.TargetDrIp) <MASK> <BROADCAST>" | Tee-Object $OUTFILE -Append
		}
		Write-Output "``````" | Tee-Object $OUTFILE -Append
		Write-Output "`r`n" | Tee-Object $OUTFILE -Append
	}

	function Write-TargetCommands {
		Write-Output "# Provisioning Script for $($SourceSystem)`r`n" | Tee-Object $OUTFILE -Append
		Write-Output "## Provisioning Commands for Target System $($CSVDATA | Select-Object -ExpandProperty TargetSystem -Unique)`r`n" | Tee-Object $OUTFILE -Append
		Write-IntCreateCommands
		Write-VdmCreateCommands
		Write-VdmRepCommands
		Write-FsCreateCommands
		Write-FsRepCommands
		Write-FsDedupeCommands
		Write-FsCkptCommands
		Write-FsMountCommands
		Write-QtreeCommands
		Write-CreateCifsServerCommands
		Write-JoinCifsServerCommands
		Write-CifsExportCommands
	}

	function Write-TargetDrCommands {
		Write-Output "## Provisioning Commands for Target Cob (DR) System $($CSVDATA | Select-Object -ExpandProperty TargetSystem -Unique)`r`n" | Tee-Object $OUTFILE -Append
		Write-DrFsCreateCommands
		Write-DrFsMountCommands
		Write-DrFsCkptCommands
		Write-DrSpnCommands
	}
}

PROCESS {

	If ($SourceSystem -ne $NULL) {
		$TIMESTAMP = $(Get-Date -Format yyyyMMddHHmmss)
		$OUTFILE = ".\${TIMESTAMP}_${SourceSystem}-provisioning-script.txt"
		$CSVDATA = Import-Csv -Path $CsvFile | Where-Object {$_.SourceSystem -eq "$SourceSystem"}
		Write-TargetCommands
		Write-TargetDrCommands
	} ElseIf ($SourceSystem -eq $NULL) {
		Write-Host -BackgroundColor Black -ForegroundColor Magenta "You did not specify a Source System..."
		Write-Host -BackgroundColor Black -ForegroundColor Magenta "Do you want me to create separate provsioning scripts"
		Write-Host -BackgroundColor Black -ForegroundColor Magenta "for each source system I find in the CSV file?"
		$RESPONSE = Read-Host '(Y/y/N/n)?:'
		If ($RESPONSE -eq "Y") {
			# Loop through source systems and create separate files per
			$ALLSOURCESYSTEMS = Import-Csv -Path $CsvFile | Select-Object -ExpandProperty SourceSystem -Unique 
			ForEach ($SYSTEM in $ALLSOURCESYSTEMS) {
				$TIMESTAMP = $(Get-Date -Format yyyyMMddHHmmss)
				$SourceSystem = $SYSTEM
				$OUTFILE = ".\${TIMESTAMP}_${SourceSystem}-provisioning-script.txt"
				$CSVDATA = Import-Csv -Path $CsvFile | Where-Object {$_.SourceSystem -eq "$SourceSystem"}
				Write-TargetCommands
				Write-TargetDrCommands
			}
		}  Else {
			Write-Host "Nothing to do.  Exiting..."
			Exit 1
		}	
	}
}

END {

}
