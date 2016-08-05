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
	# Add NFS fuctionality
	# Create steps based on data type (app/user) and protocols (cifs/nfs/both) and replication requirements
	# Derive Interface Name from info in the spreadsheet (using a bunch of substrings)
	# Do not write Interface create commands if Interface does not exist (for target and targetDr)
	# Do not write VDM create commands if VDM does not exist (for target and targetDr)
	# Do not write replication commands if no destination volume in the spreadsheet
	# Actually get slot # for Qtree commands
	# Do not write FS create commands if FS does not exist (for target and targetDr)
	# Do not write mount commands if no FS exists in sheet (for target and targetDr)
	# Do not write checkpoint commands if no FS exists in sheet (for target and targetDr)
	# Write different commands sets if USERDATA/APPDATA, includes replication, or CIFS/NFS/BOTH
	
	# This functions as a simple alias to the Write-Output cmdlet
	function WO($TXT) {
		Invoke-Expression ("Write-Output " + $TXT)
	}
	
	# Still trying to make this work
	# function TEE {
	#	Invoke-Expression ("Tee-Object " + $OUTFILE + $_ + -Append)
	#}

	# Begin Target Provisioning Commands
	
	function Write-IntCreateCommands {
		$SUBSET = $CSVDATA | Sort-Object -Property TargetIp -Unique
		WO "### Interface Creation Commands`r`n" | Tee-Object $OUTFILE -Append
		WO "**Subnet mask, broadcast address, and interface name need to be filled in manually**`r`n" | Tee-Object $OUTFILE -Append
		WO "``````" | Tee-Object $OUTFILE -Append
		ForEach ($OBJ in $SUBSET) {
			WO "server_ifconfig $($OBJ.TargetDM) -create -device fsn0 -name <INT_NAME> -protocol IP $($OBJ.TargetIp) <MASK> <BROADCAST>" | Tee-Object $OUTFILE -Append
		}
		WO "``````" | Tee-Object $OUTFILE -Append
		WO "`r`n" | Tee-Object $OUTFILE -Append
	}

	function Write-DrIntCreateCommands {
		$SUBSET = $CSVDATA | Sort-Object -Property TargetDrIp -Unique
		WO "### Cob (Dr)Interface Creation Commands`r`n" | Tee-Object $OUTFILE -Append
		WO "**<MASK>, <BROADCAST>, and <INT_NAME> need to be filled in manually**`r`n" | Tee-Object $OUTFILE -Append
		WO "``````" | Tee-Object $OUTFILE -Append
		ForEach ($OBJ in $SUBSET) {
			WO "server_ifconfig $($OBJ.TargetDrDM) -create -device fsn0 -name <INT_NAME> -protocol IP $($OBJ.TargetDrIp) <MASK> <BROADCAST>" | Tee-Object $OUTFILE -Append
		}
		WO "``````" | Tee-Object $OUTFILE -Append
		WO "`r`n" | Tee-Object $OUTFILE -Append
		
	}

	function Write-VdmCreateCommands {
		$SUBSET = $CSVDATA | Sort-Object -Property TargetVdm -Unique
		WO "### VDM Creation Commands`r`n" | Tee-Object $OUTFILE -Append
		WO "``````" | Tee-Object $OUTFILE -Append
		ForEach ($OBJ in $SUBSET) {
			WO "nas_server -name $($OBJ.TargetVDM) -type vdm -create $($OBJ.TargetDM) -setstate loaded pool=$($OBJ.TargetStoragePool)" | Tee-Object $OUTFILE -Append
		}
		WO "``````" | Tee-Object $OUTFILE -Append
		WO "`r`n" | Tee-Object $OUTFILE -Append
	}

	function Write-VdmRepCommands {
		$SUBSET = $CSVDATA | Sort-Object -Property TargetVdm -Unique
		WO "### VDM Replication Commands`r`n" | Tee-Object $OUTFILE -Append
		WO "**Pool ID and Interconnect name need to be filled in manually**`r`n" | Tee-Object $OUTFILE -Append
		WO "``````" | Tee-Object $OUTFILE -Append
		ForEach ($OBJ in $SUBSET) {
			WO "nas_replicate -create $($OBJ.TargetVDM)_REP -source -vdm $($OBJ.TargetVDM) -destination -pool id=<POOL_ID> -interconnect <INTERCONNECT_NAME> -max_time_out_of_sync 10 -background" | Tee-Object $OUTFILE -Append
		}
		WO "``````" | Tee-Object $OUTFILE -Append
		WO "`r`n" | Tee-Object $OUTFILE -Append
	}

	function Write-FsCreateCommands {
		WO "### Filesystem Creation Commands`r`n" | Tee-Object $OUTFILE -Append
		WO "``````" | Tee-Object $OUTFILE -Append
		ForEach ($OBJ in $CSVDATA) {
			WO "nas_fs -name $($OBJ.TargetFilesystem) -type $($OBJ.TargetSecurityStyle) -create size=$($OBJ.TargetCapacityGB)GB pool=$($OBJ.TargetStoragePool) -option slice=y" | Tee-Object $OUTFILE -Append
		}
		WO "``````" | Tee-Object $OUTFILE -Append
		WO "`r`n" | Tee-Object $OUTFILE -Append
	}

	function Write-FsRepCommands {
		WO "### Filesystem Replication Commands`r`n" | Tee-Object $OUTFILE -Append
		WO "**These commands are to be run after the base copy is completed**" | Tee-Object $OUTFILE -Append
		WO "**The Interconnect name needs to be filled in manually**`r`n" | Tee-Object $OUTFILE -Append
		WO "``````" | Tee-Object $OUTFILE -Append
		ForEach ($OBJ in $CSVDATA) {
			WO "nas_replicate -create $($OBJ.TargetFilesystem)_REP -source -fs $($OBJ.TargetFilesystem) -destination -fs $($OBJ.TargetDrFilesystem) -interconnect <INTERCONNECT_NAME> -max_time_out_of_sync 10 -background" | Tee-Object $OUTFILE -Append
		}
		WO "``````" | Tee-Object $OUTFILE -Append
		WO "`r`n" | Tee-Object $OUTFILE -Append
	}

	function Write-FsDedupeCommands {
		WO "### Filesystem Deduplication Commands`r`n" | Tee-Object $OUTFILE -Append
		WO "**Only enable on target if enabled on the source**`r`n" | Tee-Object $OUTFILE -Append
		WO "``````" | Tee-Object $OUTFILE -Append
		ForEach ($OBJ in $CSVDATA) {
			WO "fs_dedupe -modify $($OBJ.TargetFilesystem) -state on" | Tee-Object $OUTFILE -Append
		}
		WO "``````" | Tee-Object $OUTFILE -Append
		WO "`r`n" | Tee-Object $OUTFILE -Append
	}

	function Write-FsCkptCommands {
		WO "### Filesystem Checkpoint Commands`r`n" | Tee-Object $OUTFILE -Append
		WO "**Only create the checkpoints after the migration has been completed**`r`n" | Tee-Object $OUTFILE -Append
		WO "``````"
		ForEach ($OBJ in $CSVDATA) {
			WO "nas_ckpt_schedule -create $($OBJ.TargetFilesystem)_DAILY_SCHED -filesystem $($OBJ.TargetFilesystem) -description ""1730hrs daily checkpoint schedule for $($OBJ.TargetFilesystem)"" -recurrence daily -every 1 -start_on <DATE> -runtimes 17:30 -keep 7" | Tee-Object $OUTFILE -Append
		}
		WO "``````" | Tee-Object $OUTFILE -Append
		WO "`r`n" | Tee-Object $OUTFILE -Append
	}

	function Write-FsMountCommands {
		WO "### Mount Commands`r`n" | Tee-Object $OUTFILE -Append
		WO "``````" | Tee-Object $OUTFILE -Append
		ForEach ($OBJ in $CSVDATA) {
			WO "server_mount $($OBJ.TargetVDM) $($OBJ.TargetFilesystem) /$($OBJ.TargetFilesystem)" | Tee-Object $OUTFILE -Append
		} 
		WO "``````" | Tee-Object $OUTFILE -Append
		WO "`r`n" | Tee-Object $OUTFILE -Append
	}

	function Write-QtreeCommands {
		WO "### Qtree Command`r`n" | Tee-Object $OUTFILE -Append
		WO "**Slot (datamover) number and VDM number need to be filled in manually**`r`n" | Tee-Object $OUTFILE -Append
		WO "``````" | Tee-Object $OUTFILE -Append
		ForEach ($OBJ in $CSVDATA) {
			WO "mkdir /nasmcd/quota/slot_X/root_vdm_X/$($OBJ.TargetFilesystem)/$($OBJ.TargetFilesystem)" | Tee-Object $OUTFILE -Append
		}
		WO "``````" | Tee-Object $OUTFILE -Append
		WO "`r`n" | Tee-Object $OUTFILE -Append
	}

	function Write-CreateCifsServerCommands {
		$SUBSET = $CSVDATA | Sort-Object -Property TargetVDM -Unique
		WO "### Create CIFS Server Commands`r`n" | Tee-Object $OUTFILE -Append
		WO "**Interface name needs to be filled in manually**`r`n" | Tee-Object $OUTFILE -Append
		WO "``````" | Tee-Object $OUTFILE -Append
		ForEach ($OBJ in $SUBSET) {
			WO "server_cifs $($OBJ.TargetVDM) -add compname=$($OBJ.TargetVDM),domain=nam.nsroot.net,interface=<INT_NAME>,local_users" | Tee-Object $OUTFILE -Append
		}
		WO "``````" | Tee-Object $OUTFILE -Append
		WO "`r`n" | Tee-Object $OUTFILE -Append
	}

	function Write-JoinCifsServerCommands {
		$SUBSET = $CSVDATA | Sort-Object -Property TargetVDM -Unique
		WO "### Join CIFS Server to Domain Commands`r`n" | Tee-Object $OUTFILE -Append
		WO "**Admin user needs to be filled in manually**`r`n" | Tee-Object $OUTFILE -Append
		WO "``````" | Tee-Object $OUTFILE -Append
		ForEach ($OBJ in $SUBSET) {
			WO "server_cifs $($OBJ.TargetVDM) -join compname=$($OBJ.TargetVDM),domain=nam.nsroot.net,admin=<ADMIN_USER>,ou=Servers:ou-NAS:ou=INFRA" | Tee-Object $OUTFILE -Append
			}
		WO "``````" | Tee-Object $OUTFILE -Append
		WO "`r`n" | Tee-Object $OUTFILE -Append
		}

	function Write-CifsExportCommands {
		$SUBSET = $CSVDATA | Sort-Object -Property TargetFilesystem -Unique
		WO "### Export CIFS Share Commands`r`n" | Tee-Object $OUTFILE -Append
		WO "``````" | Tee-Object $OUTFILE -Append
		ForEach ($OBJ in $SUBSET) {
			WO "server_export $($OBJ.TargetVDM) -protocol cifs -name $($OBJ.TargetFilesystem) -o netbios=$($OBJ.TargetVDM) /$($OBJ.TargetFilesystem)/$($OBJ.TargetFilesystem)" | Tee-Object $OUTFILE -Append
		}
		WO "``````" | Tee-Object $OUTFILE -Append
		WO "`r`n" | Tee-Object $OUTFILE -Append
	}

	# Begin Cob (DR) Provisioning Commands
	
	function Write-DrFsCreateCommands {
		WO "### Cob (DR) Filesystem Creation Commands`r`n" | Tee-Object $OUTFILE -Append
		WO "``````" | Tee-Object $OUTFILE -Append
		ForEach ($OBJ in $CSVDATA) {
			WO "nas_fs -name $($OBJ.TargetDrFilesystem) -create samesize:$($OBJ.TargetFilesystem):$($OBJ.TargetVDM) pool:$($OBJ.TargetDrStoragePool)" | Tee-Object $OUTFILE -Append
		}
		WO "``````" | Tee-Object $OUTFILE -Append
		WO "`r`n" | Tee-Object $OUTFILE -Append
	}

	function Write-DrFsMountCommands {
		WO "### Cob (DR) Filesystem Mount Commands`r`n" | Tee-Object $OUTFILE -Append
		WO "``````" | Tee-Object $OUTFILE -Append
		ForEach ($OBJ in $CSVDATA) {
				WO "server_mount $($OBJ.TargetVDM) -o ro $($OBJ.TargetDrFilesystem) /$($OBJ.TargetDrFilesystem)" | Tee-Object $OUTFILE -Append
			}
		WO "``````" | Tee-Object $OUTFILE -Append
		WO "`r`n" | Tee-Object $OUTFILE -Append
	}

	function Write-DrFsCkptCommands {
		WO "### Cob (DR) Filesystem Checkpoint Commands`r`n" | Tee-Object $OUTFILE -Append
		WO "``````" | Tee-Object $OUTFILE -Append
		ForEach ($OBJ in $CSVDATA) {
				WO "nas_ckpt_schedule -create $($OBJ.TargetDrFilesystem)_DAILY_SCHED -filesystem $($OBJ.TargetDrFilesystem) -description ""1730hrs daily checkpoint schedule for $($OBJ.TargetDrFilesystem)"" -recurrence daily -every 1 -start_on <DATE> -runtimes 17:30 -keep 7" | Tee-Object $OUTFILE -Append
			}
		WO "``````" | Tee-Object $OUTFILE -Append
		WO "`r`n" | Tee-Object $OUTFILE -Append
	}

	function Write-DrSpnCommands {
		$SUBSET = $CSVDATA | Sort-Object -Property TargetVdm -Unique
		WO "### Cob (DR) SPN Commands`r`n" | Tee-Object $OUTFILE -Append
		WO "``````" | Tee-Object $OUTFILE -Append
		ForEach ($OBJ in $SUBSET) {
			WO "setspn -A HOST/$($OBJ.TargetVDM) $($OBJ.TargetVDM)" | Tee-Object $OUTFILE -Append
			WO "setspn -A HOST/$($OBJ.TargetVDM).wlbX.nam.nsroot.net $($OBJ.TargetVDM)" | Tee-Object $OUTFILE -Append
			WO "setspn -A HOST/$($OBJ.TargetVDM).nam.nsroot.net $($OBJ.TargetVDM)" | Tee-Object $OUTFILE -Append
			WO "setspn -L $($OBJ.TargetVDM)`r`n" | Tee-Object $OUTFILE -Append
		}
		WO "``````" | Tee-Object $OUTFILE -Append
		WO "`r`n" | Tee-Object $OUTFILE -Append
	}

	function Write-DrIntCreateCommands {
		$SUBSET = $CSVDATA | Sort-Object -Property TargetDrIp -Unique
		WO "### Cob (DR) Interface Creation Commands`r`n" | Tee-Object $OUTFILE -Append
		WO "``````" | Tee-Object $OUTFILE -Append
		ForEach ($OBJ in $SUBSET) {
			WO "server_ifconfig $($OBJ.TargetDrDM) -create -device fsn0 -name <INT_NAME> -protocol IP $($OBJ.TargetDrIp) <MASK> <BROADCAST>" | Tee-Object $OUTFILE -Append
		}
		WO "``````" | Tee-Object $OUTFILE -Append
		WO "`r`n" | Tee-Object $OUTFILE -Append
	}

	function Write-AttachIntVdmCommands {
		$SUBSET = $CSVDATA | Sort-Object -Property TargetVdm -Unique
		WO "### Attach Interface to VDM Commands`r`n" | Tee-Object $OUTFILE -Append
		WO "**<INT_NAME> must be filled in manually**`r`n" | Tee-Object $OUTFILE -Append
		WO "``````" | Tee-Object $OUTFILE -Append
		ForEach ($OBJ in $SUBSET) {
			WO "nas_server -vdm $($OBJ.TargetVdm) -attach <INT_NAME>" | Tee-Object $OUTFILE -Append
		}
		WO "``````" | Tee-Object $OUTFILE -Append
		WO "`r`n" | Tee-Object $OUTFILE -Append
	}

	function Write-NfsExportCreateCommands {
		WO "### NFS Export Commands`r`n" | Tee-Object $OUTFILE -Append
		WO "**<EXPORT_OPTS> needs to be filled in manually**"
		WO "``````" | Tee-Object $OUTFILE -Append
		ForEach ($OBJ in $CSVDATA) {
			WO "server_export $($OBJ.TargetVdm -protocol nfs -name $($OBJ.TargetFilesystem)) -o <EXPORT_OPTS> /$($OBJ.TargetFilesystem)/$($OBJ.TargetQtree)" | Tee-Object $OUTFILE -Append
		}
		WO "``````" | Tee-Object $OUTFILE -Append
	}

	function Write-NfsDmLdapCommands {
		$SUBSET = $CSVDATA | Sort-Object -Property TargetVdm -Unique
		WO "### NFS LDAP Commands`r`n" | Tee-Object $OUTFILE -Append
		WO "**First check to see if LDAP is configured on the physical datamover**`r`n" | Tee-Object $OUTFILE -Append
		WO "``````" | Tee-Object $OUTFILE -Append
		ForEach ($OBJ in $SUBSET) {
			WO "server_ldap $($OBJ.TargetDm) -info -all | grep -i "ldap domain"" | Tee-Object $OUTFILE -Append
		}
		WO "``````" | Tee-Object $OUTFILE -Append
		WO "**If LDAP is not present, then add it**`r`n" | Tee-Object $OUTFILE -Append
		WO "**<BASE_DN> and <CSV_SERVER_LIST> need to be filled in manually**`r`n"
		WO "``````" | Tee-Object $OUTFILE -Append
		ForEach ($OBJ in $SUBSET) {
			WO "server_ldap $($OBJ.TargetDm) -add -basedn <BASE_DN> -servers <CSV_SERVER_LIST> -sslenabled n" | Tee-Object $OUTFILE -Append
		}
		WO "``````" | Tee-Object $OUTFILE -Append
	}

	function Write-NfsVdmLdapCommands {
		$SUBSET = $CSVDATA | Sort-Object -Property TargetVdm -Unique
		ForEach ($OBJ in $SUBSET) {
		WO "### NFS VDM LDAP Commands`r`n" | Tee-Object $OUTFILE -Append
		WO "``````" | Tee-Object $OUTFILE -Append
		WO "vi /nasmcd/quota/slot_X/root_vdm_X/.etc/ldap.conf`r`n" | Tee-Object $OUTFILE -Append
		WO "``````" | Tee-Object $OUTFILE -Append
		WO "**Write the following information into the ``ldap.conf`` file`r`n" | Tee-Object $OUTFILE -Append
		WO "``````" | Tee-Object $OUTFILE -Append
		WO "nss_bas_passwd <LDAP_DN>" | Tee-Object $OUTFILE -Append
		WO "nss_bas_group <LDAP_DN>" | Tee-Object $OUTFILE -Append
		WO "nss_base_netgrouop <LDAP_DN>" | Tee-Object $OUTFILE -Append
		}
	}



	function Write-TargetCommands {
		WO "# Provisioning Script for $($SourceSystem)`r`n" | Tee-Object $OUTFILE -Append
		WO "## Provisioning Commands for Target System $($CSVDATA | Select-Object -ExpandProperty TargetSystem -Unique)`r`n" | Tee-Object $OUTFILE -Append
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
		WO "## Provisioning Commands for Target Cob (DR) System $($CSVDATA | Select-Object -ExpandProperty TargetSystem -Unique)`r`n" | Tee-Object $OUTFILE -Append
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
