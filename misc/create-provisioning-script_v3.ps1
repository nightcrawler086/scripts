[CmdletBinding()]
Param (
	[Parameter(Mandatory=$False,Position=1)]
	 [string[]]$SourceSystem,

	[Parameter(Mandatory=$True,Position=2)]
	 [string]$CsvFile

)

BEGIN {
	
	$OUTPUT = @()

}

PROCESS {
	# If no SourceSystem specified, ask to perform for all systems
	If ($SourceSystem -eq $NULL) {
		Write-Host "No source system specified..."
		Write-Host "Do you want to get all commands for all systems?"
		$RESPONSE = Read-Host '(Y/y/N/n)?'
		If ($RESPONSE -eq "Y") {
			$ALLSYSTEMS = Import-Csv -Path $CsvFile
		} 
		Else {
			Write-Host "Nothing to do."
			Exit 1
		}
	}
	# If source system specified, define our working set
	If ($SourceSystem -ne $NULL) {
		$ALLSYSTEMS = Import-Csv -Path $CsvFile | Where-Object {$_.SourceSystem -eq "$SourceSystem"}
	}
	# Create commands and append them to the $OUTPUT array
	$SUBSET = $ALLSYSTEMS | Sort-Object -Property TargetVdm -Unique
	ForEach ($OBJ in $SUBSET) {
		If ($($OBJ.TargetVdm) -ne $NULL -or $($OBJ.TargetVdm) -ne "N/A") {
			# Generate Prod VDM Creation Commands
			$CMD = "nas_server -name $($OBJ.TargetVDM) -type vdm -create $($OBJ.TargetDM) -setstate loaded pool=$($OBJ.TargetStoragePool)"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdVdmCreate";
				CommandString = $CMD
			}
			# Generate Prod VDM Int Attach Commands
			$CMD = "nas_server -vdm $($OBJ.TargetVDM) -attach <INT_NAME>"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdVdmAttachInt";
				CommandString = "$CMD"
			} 
		}
		If ($($OBJ.TargetDrSystem) -ne $NULL -or $($OBJ.TargetDrSystem -ne "N/A")) {
			# Generate Cob(DR) VDM Creation Commands
			$CMD = "nas_replicate -create $($OBJ.TargetVDM)_REP -source -vdm $($OBJ.TargetVDM) -destination -pool id=<POOL_ID> -interconnect <INTERCONNECT_NAME> -max_time_out_of_sync 10 -background"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdVdmRep";
				CommandString = "$CMD"
			}
			# Generate Cob(DR) VDM Int Attach Commands
			$CMD = "nas_server -vdm $($OBJ.TargetVDM) -attach <INT_NAME>"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "drVdmAttachInt";
				CommandString = "$CMD"
			}
		}
	}
	$SUBSET = $ALLSYSTEMS | Select-Object -Property TargetIp -Unique
	ForEach ($OBJ in $SUBSET) {
		If ($($OBJ.TargetIp) -ne $NULL -or $($OBJ.TargetIp) -ne "N/A") {
			# Generate Prod Interface Configuration Commands
			$CMD = "server_ifconfig $($OBJ.TargetDM) -create -device fsn0 -name <INT_NAME> -protocol IP $($OBJ.TargetIp) <MASK> <BROADCAST>" 		
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdIntCreate";
				CommandString = "$CMD"
			}
		}
	}
	$SUBSET = $ALLSYSTEMS | Select-Object -Property TargetDrIp -Unique
	ForEach ($OBJ in $SUBSET) {
		If ($($OBJ.TargetDrIp) -ne $NULL -or $($OBJ.TargetDrIp) -ne "N/A") {
			# Generate Cob(DR) Interface Configuration Commands
			$CMD = "server_ifconfig $($OBJ.TargetDrDM) -create -device fsn0 -name <INT_NAME> -protocol IP $($OBJ.TargetDrIp) <MASK> <BROADCAST>" 		
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "drIntCreate";
				CommandString = "$CMD"
			}
		}
	}
	$SUBSET = $ALLSYSTEMS | Select-Object -Property TargetCifsServer -Unique
	ForEach ($OBJ in $SUBSET) {
		If ($($OBJ.TargetProtocol) -eq "CIFS" -or $($OBJ.TargetProtocol) -eq "BOTH") {
			# Generate Prod Create CIFS Server Commands
			$CMD = "server_cifs $($OBJ.TargetCifsServer) -add compname=$($OBJ.TargetCifsServer),domain=nam.nsroot.net,interface=<INT_NAME>,local_users"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdCifsCreate";
				CommandString = "$CMD"
			}
			# Generate Prod Join CIFS Server Commands 
			$CMD = "server_cifs $($OBJ.TargetCifsServer) -join compname=$($OBJ.TargetCifsServer),domain=nam.nsroot.net,admin=<ADMIN_USER>,ou=Servers:ou-NAS:ou=INFRA"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdCifsJoin";
				CommandString = "$CMD"
			}
		}
	}
	$SUBSET = $ALLSYSTEMS | Select-Object -Property TargetNfsServer -Unique
	ForEach ($OBJ in $SUBSET) {
		If ($($OBJ.TargetNfsServer) -ne $NULL -or $($OBJ.TargetNfsServer) -ne "N/A") {
			# Generate Prod NFS LDAP Commands
			$CMD = "server_ldap $($OBJ.TargetDm) -add -basedn <BASE_DN> -servers <CSV_SERVER_LIST> -sslenabled n"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdNfsLdap";
				CommandString = "$CMD"
			}
		}	
	}
	$SUBSET = $ALLSYSTEMS | Select-Object -Property TargetFilesystem -Unique
	ForEach ($OBJ in $SUBSET) {
		If ($($OBJ.TargetFilesystem) -ne $NULL -or $($OBJ.TargetFilesystem) -ne "N/A") {
			$CMD = "nas_fs -name $($OBJ.TargetFilesystem) -type $($OBJ.TargetSecurityStyle) -create size=$($OBJ.TargetCapacityGB)GB pool=$($OBJ.TargetStoragePool) -option slice=y"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdFsCreate";
				CommandString = "$CMD"
			}
			$CMD = "fs_dedupe -modify $($OBJ.TargetFilesystem) -state on"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdFsDedupe";
				CommandString = "$CMD"
			}
			$CMD = "nas_ckpt_schedule -create $($OBJ.TargetFilesystem)_DAILY_SCHED -filesystem $($OBJ.TargetFilesystem) -description ""1730hrs daily checkpoint schedule for $($OBJ.TargetFilesystem)"" -recurrence daily -every 1 -start_on <DATE> -runtimes 17:30 -keep 7"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdFsCkpt";
				CommandString = "$CMD"
			}
			If ($($OBJ.TargetDm) -ne $NULL -or $($OBJ.TargetDm) -ne "N/A") {
				$TGTDM = $($OBJ.TargetDm)
				$DMNUM = $TGTDM.Substring(7)
				$CMD = "mkdir /nasmcd/quota/slot_$DMNUM/root_vdm_X/$($OBJ.TargetFilesystem)/$($OBJ.TargetQtree)"
				$OUTPUT += New-Object -TypeName PSObject -Property @{
					SourceSystem = $OBJ.SourceSystem;
					TargetSystem = $OBJ.TargetSystem;
					TargetDrSystem = $OBJ.TargetDrSystem;
					CommandType = "prdFsQtree";
					CommandString = "$CMD"
				} 
			} Else {
				$CMD = "mkdir /nasmcd/quota/slot_X/root_vdm_X/$($OBJ.TargetFilesystem)/$($OBJ.TargetQtree)"
				$OUTPUT += New-Object -TypeName PSObject -Property @{
					SourceSystem = $OBJ.SourceSystem;
					TargetSystem = $OBJ.TargetSystem;
					TargetDrSystem = $OBJ.TargetDrSystem;
					CommandType = "prdFsQtree";
					CommandString = "$CMD"
				} 
			}
			$CMD = "server_mount $($OBJ.TargetVDM) $($OBJ.TargetFilesystem) /$($OBJ.TargetFilesystem)"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdFsMnt";
				CommandString = "$CMD"
			}
		}
		If ($($OBJ.TargetProtocol) -eq "CIFS" -or $($OBJ.TargetProtocol) -eq "BOTH") {
			$CMD5 = "server_export $($OBJ.TargetVDM) -protocol cifs -name $($OBJ.TargetFilesystem) -o netbios=$($OBJ.TargetVDM) /$($OBJ.TargetFilesystem)/$($OBJ.TargetFilesystem)"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdCifsExport";
				CommandString = "$CMD"
			}
		}
		If ($($OBJ.TargetProtocol) -eq "NFS" -or $($OBJ.TargetProtocol) -eq "BOTH") {
			$CMD = "server_export $($OBJ.TargetVDM) -protocol nfs -name $($OBJ.TargetFilesystem) -o rw=<CLIENTS>,ro=<CLIENTS>,root=<CLIENTS> /$($OBJ.TargetFilesystem)/$($OBJ.TargetQtree)"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdNfsExport";
				CommandString = "$CMD"
			}
		}
		If ($($OBJ.TargetDrFilesystem) -ne $NULL -or $($OBJ.TargetDrFilesystem) -ne "N/A") {
			$CMD = "nas_replicate -create $($OBJ.TargetFilesystem)_REP -source -fs $($OBJ.TargetFilesystem) -destination -fs $($OBJ.TargetDrFilesystem) -interconnect <INTERCONNECT_NAME> -max_time_out_of_sync 10 -background"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdFsRep";
				CommandString = "$CMD"
			}
			$CMD = "nas_fs -name $($OBJ.TargetDrFilesystem) -create samesize:$($OBJ.TargetFilesystem):$($OBJ.TargetVDM) pool:$($OBJ.TargetDrStoragePool)" 
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "drFsCreate";
				CommandString = "$CMD"
			}
			$CMD = "server_mount $($OBJ.TargetVDM) -o ro $($OBJ.TargetDrFilesystem) /$($OBJ.TargetDrFilesystem)"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "drFsMnt";
				CommandString = "$CMD"
			}
			$CMD = "nas_ckpt_schedule -create $($OBJ.TargetDrFilesystem)_DAILY_SCHED -filesystem $($OBJ.TargetDrFilesystem) -description ""1730hrs daily checkpoint schedule for $($OBJ.TargetDrFilesystem)"" -recurrence daily -every 1 -start_on <DATE> -runtimes 17:30 -keep 7"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "drFsCkpt";
				CommandString = "$CMD"
			}
		}
	}
}

END {
	$OUTPUT
}
