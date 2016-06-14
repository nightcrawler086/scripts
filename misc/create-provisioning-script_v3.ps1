[CmdletBinding()]
Param (
	[Parameter(Mandatory=$False,Position=1)]
	 [string[]]$SourceSystem,

	[Parameter(Mandatory=$True,Position=2)]
	 [string]$CsvFile,

	[Parameter(Mandatory=$False,Position=3)]
	 [string]$OutFormat

)

BEGIN {
	
	$OUTPUT = @()

}

PROCESS {
	# To do:
	#
	# Create Different output formats (CSV, TXT (makrdown-style), and HTML)
	# Add Replication configuration commands
	# Re-check NFS commands (LDAP, Export creation)
	# For some reason the "N/A" section of the If statements don't work...fix that
	#
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
	# This SUBSET is sufficiently filtered for VDM Creation commands on the target production side
	$SUBSET = $ALLSYSTEMS | 
		Where-Object {$_.TargetSystem -notlike "N/A" -or $_.TargetSystem -ne "" -and $_.TargetVdm -notlike "N/A" -or $_.TargetVdm -ne ""} | 
			Sort-Object -Property TargetVdm -Unique
	ForEach ($OBJ in $SUBSET) {
			# Generate Prod VDM Creation Commands
			$CMDSTR = "nas_server -name $($OBJ.TargetVDM) -type vdm -create $($OBJ.TargetDM) -setstate loaded pool=$($OBJ.TargetStoragePool)"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdVdmCreate";
				CommandString = $CMDSTR
			}
			# Generate Prod VDM Int Attach Commands
			$CMDSTR = "nas_server -vdm $($OBJ.TargetVDM) -attach <INT_NAME>"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdVdmAttachInt";
				CommandString = "$CMDSTR"
			} 
		}
	$SUBSET = $ALLSYSTEMS | 
		Where-Object {$_.TargetDrSystem -notlike "N/A" -or $_.TargetDrSystem -ne "" -and $_.TargetDrVdm -notlike "N/A" -or $_.TargetDrVdm -ne ""} | 
			Sort-Object -Property TargetDrSystem,TargetDrVdm -Unique
	ForEach ($OBJ in $SUBSET) {
			# Generate Cob(DR) VDM Creation Commands
			$CMDSTR = "nas_replicate -create $($OBJ.TargetVDM)_REP -source -vdm $($OBJ.TargetVDM) -destination -pool id=<POOL_ID> -interconnect <INTERCONNECT_NAME> -max_time_out_of_sync 10 -background"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdVdmRep";
				CommandString = "$CMDSTR"
			}
			# Generate Cob(DR) VDM Int Attach Commands
			$CMDSTR = "nas_server -vdm $($OBJ.TargetVDM) -attach <INT_NAME>"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "drVdmAttachInt";
				CommandString = "$CMDSTR"
			}
		}
	$SUBSET = $ALLSYSTEMS | 
		Where-Object {$_.TargetSystem -notlike "N/A" -or $_.TargetSystem -ne "" -and $_.TargetDrSystem -notlike "N/A" -or $_.TargetDrSystem -ne ""} | 
			Sort-Object TargetSystem,TargetDm,TargetDrSystem,TargetDrDm -Unique
	ForEach ($OBJ in $SUBSET) {
			$TGTSYS = $($OBJ.TargetSystem)
			$TGTLOC = $TGTSYS.Substring(0,3)
			$TGTDRSYS = $($OBJ.TargetDrSystem)
			$TGTDRLOC = $TGTDRSYS.Substring(0,3)
			If ($($OBJ.TargetDm) -match "server_[0-9]$" ) {
				$TGTDM = $($OBJ.TargetDm)
				$TGTDMNUM = $TGTDM.Substring(7)
			} Else {
				$TGTDMNUM = "<TGT_DM_NUM>"
			}
			If ($($OBJ.TargetDrDm) -match "server_[0-9]$"{
				$TGTDRDM = $($OBJ.TargetDrDm)
				$TGTDRDMNUM = $TGTDRDM.Substring(7)
			} Else {
				$TGTDRDMNUM = "<TGT_DR_DM_NUM>"
			}
			# Create Replication Passphrase on Source System
			$CMDSTR = "nas_cel -create $($OBJ.TargetSystem) -ip <REP_IP> -passphrase <REP_PASS>"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdRepPass";
				CommandString = "$CMDSTR"
			}
			# Create Replication Passphrase on Destination System
			$CMDSTR = "nas_cel -create $($OBJ.TargetDrSystem) -ip <REP_IP> -passphrase <REP_PASS>"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "drRepPass";
				CommandString = "$CMDSTR"
			}
			# Create Replication Interconnect on Prod System
			$CMDSTR = "nas_cel -interconnect -create $TGTLOC`_dm$TGTDMNUM`-$TGTDRLOC`_dm$TGTDRDMNUM -source_server $TGTDM -destination_system $TGTDRSYS -destination_server $TGTDRDM -source_interfaces ip=<REP_IP> -destination_interfaces ip=<REP_IP>"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdCreateInterconnect";
				CommandString = "$CMDSTR"
			}
			# Create Replication Interconnect on Cob(DR) System
			$CMDSTR = "nas_cel -interconnect -create $TGTDRLOC`_dm$TGTDRDMNUM`-$TGTLOC`_dm$TGTDMNUM -source_server $TGTDRDM -destination_system $TGTSYS -destination_server $TGTDM -source_interfaces ip=<REP_IP> -destination_interfaces ip=<REP_IP>"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "drCreateInterconnect";
				CommandString = "$CMDSTR"
			}
		}
	# ***** Left off here *****
	# Need to revise filtering in $SUBSET definition
	# Should be $ALLSYSTEMS | Where <something> | sort -property <props> -Unique
	$SUBSET = $ALLSYSTEMS | Sort-Object -Property TargetIp -Unique
	ForEach ($OBJ in $SUBSET) {
		If ($($OBJ.TargetIp) -ne "" -or $($OBJ.TargetIp) -notlike "N/A") {
			# Generate Prod Interface Configuration Commands
			$CMDSTR = "server_ifconfig $($OBJ.TargetDM) -create -Device fsn0 -name <INT_NAME> -protocol IP $($OBJ.TargetIp) <MASK> <BROADCAST>" 		
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdIntCreate";
				CommandString = "$CMDSTR"
			}
		}
	}
	$SUBSET = $ALLSYSTEMS | Sort-Object -Property TargetDrIp -Unique
	ForEach ($OBJ in $SUBSET) {
		If ($($OBJ.TargetDrIp) -ne "" -or $($OBJ.TargetDrIp) -notlike "N/A") {
			# Generate Cob(DR) Interface Configuration Commands
			$CMDSTR = "server_ifconfig $($OBJ.TargetDrDM) -create -Device fsn0 -name <INT_NAME> -protocol IP $($OBJ.TargetDrIp) <MASK> <BROADCAST>" 		
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "drIntCreate";
				CommandString = "$CMDSTR"
			}
		}
	}
	$SUBSET = $ALLSYSTEMS | Sort-Object -Property TargetCifsServer -Unique
	ForEach ($OBJ in $SUBSET) {
		If ($($OBJ.TargetProtocol) -eq "CIFS" -or $($OBJ.TargetProtocol) -eq "BOTH") {
			# Generate Prod Create CIFS Server Commands
			$CMDSTR = "server_cifs $($OBJ.TargetCifsServer) -add compname=$($OBJ.TargetCifsServer),domain=nam.nsroot.net,interface=<INT_NAME>,local_users"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdCifsCreate";
				CommandString = "$CMDSTR"
			}
			# Generate Prod Join CIFS Server Commands 
			$CMDSTR = "server_cifs $($OBJ.TargetCifsServer) -Join compname=$($OBJ.TargetCifsServer),domain=nam.nsroot.net,admin=<ADMIN_USER>,`"ou=Servers:ou=NAS:ou=INFRA`""
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdCifsJoin";
				CommandString = "$CMDSTR"
			}
		}
	}
	$SUBSET = $ALLSYSTEMS | Sort-Object -Property TargetNfsServer -Unique
	ForEach ($OBJ in $SUBSET) {
		If ($($OBJ.TargetNfsServer) -ne "" -or $($OBJ.TargetNfsServer) -notlike "N/A") {
			# Generate Prod NFS LDAP Commands
			$CMDSTR = "server_ldap $($OBJ.TargetDm) -add -basedn <BASE_DN> -servers <CSV_SERVER_LIST> -sslenabled n"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdNfsLdap";
				CommandString = "$CMDSTR"
			}
		}	
	}
	$SUBSET = $ALLSYSTEMS | Sort-Object -Property TargetFilesystem -Unique
	ForEach ($OBJ in $SUBSET) {
		If ($($OBJ.TargetFilesystem) -ne "" -or $($OBJ.TargetFilesystem) -notlike "N/A") {
			$CMDSTR = "nas_fs -name $($OBJ.TargetFilesystem) -type $($OBJ.TargetSecurityStyle) -create size=$($OBJ.TargetCapacityGB)GB pool=$($OBJ.TargetStoragePool) -option slice=y"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdFsCreate";
				CommandString = "$CMDSTR"
			}
			$CMDSTR = "fs_dedupe -modify $($OBJ.TargetFilesystem) -state on"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdFsDedupe";
				CommandString = "$CMDSTR"
			}
			$CMDSTR = "nas_ckpt_schedule -create $($OBJ.TargetFilesystem)_DAILY_SCHED -filesystem $($OBJ.TargetFilesystem) -description ""1730hrs daily checkpoint schedule for $($OBJ.TargetFilesystem)"" -recurrence daily -every 1 -start_on <DATE> -runtimes 17:30 -keep 7"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdFsCkpt";
				CommandString = "$CMDSTR"
			}
			# Qtree commands
			If ($($OBJ.TargetDm) -ne "" -or $($OBJ.TargetDm) -notlike "N/A") {
				$TGTDM = $($OBJ.TargetDm)
				$DMNUM = $TGTDM.Substring(7)
				$CMDSTR = "mkdir /nasmcd/quota/slot_$DMNUM/root_vdm_X/$($OBJ.TargetFilesystem)/$($OBJ.TargetQtree)"
				$OUTPUT += New-Object -TypeName PSObject -Property @{
					SourceSystem = $OBJ.SourceSystem;
					TargetSystem = $OBJ.TargetSystem;
					TargetDrSystem = $OBJ.TargetDrSystem;
					CommandType = "prdFsQtree";
					CommandString = "$CMDSTR"
				} 
			} Else {
				$CMDSTR = "mkdir /nasmcd/quota/slot_X/root_vdm_X/$($OBJ.TargetFilesystem)/$($OBJ.TargetQtree)"
				$OUTPUT += New-Object -TypeName PSObject -Property @{
					SourceSystem = $OBJ.SourceSystem;
					TargetSystem = $OBJ.TargetSystem;
					TargetDrSystem = $OBJ.TargetDrSystem;
					CommandType = "prdFsQtree";
					CommandString = "$CMDSTR"
				} 
			}
			$CMDSTR = "server_mount $($OBJ.TargetVDM) $($OBJ.TargetFilesystem) /$($OBJ.TargetFilesystem)"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdFsMnt";
				CommandString = "$CMDSTR"
			}
		}
		If ($($OBJ.TargetProtocol) -eq "CIFS" -or $($OBJ.TargetProtocol) -eq "BOTH") {
			$CMDSTR = "server_export $($OBJ.TargetVDM) -Protocol cifs -name $($OBJ.TargetFilesystem) -o netbios=$($OBJ.TargetVDM) /$($OBJ.TargetFilesystem)/$($OBJ.TargetFilesystem)"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdCifsExport";
				CommandString = "$CMDSTR"
			}
		}
		If ($($OBJ.TargetProtocol) -eq "NFS" -or $($OBJ.TargetProtocol) -eq "BOTH") {
			$CMDSTR = "server_export $($OBJ.TargetVDM) -Protocol nfs -name $($OBJ.TargetFilesystem) -o rw=<CLIENTS>,ro=<CLIENTS>,root=<CLIENTS> /$($OBJ.TargetFilesystem)/$($OBJ.TargetQtree)"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdNfsExport";
				CommandString = "$CMDSTR"
			}
		}
		If ($($OBJ.TargetDrFilesystem) -ne "" -or $($OBJ.TargetDrFilesystem) -notlike "N/A") {
			$CMDSTR = "nas_replicate -create $($OBJ.TargetFilesystem)_REP -source -fs $($OBJ.TargetFilesystem) -destination -fs $($OBJ.TargetDrFilesystem) -interconnect <INTERCONNECT_NAME> -max_time_out_of_sync 10 -background"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdFsRep";
				CommandString = "$CMDSTR"
			}
			$CMDSTR = "nas_fs -name $($OBJ.TargetDrFilesystem) -create samesize:$($OBJ.TargetFilesystem):cel:$($OBJ.TargetDrSystem) pool:$($OBJ.TargetDrStoragePool)" 
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "drFsCreate";
				CommandString = "$CMDSTR"
			}
			$CMDSTR = "server_mount $($OBJ.TargetVDM) -o ro $($OBJ.TargetDrFilesystem) /$($OBJ.TargetDrFilesystem)"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "drFsMnt";
				CommandString = "$CMDSTR"
			}
			$CMDSTR = "nas_ckpt_schedule -create $($OBJ.TargetDrFilesystem)_DAILY_SCHED -filesystem $($OBJ.TargetDrFilesystem) -description ""1730hrs daily checkpoint schedule for $($OBJ.TargetDrFilesystem)"" -recurrence daily -every 1 -start_on <DATE> -runtimes 17:30 -keep 7"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "drFsCkpt";
				CommandString = "$CMDSTR"
			}
		}
	}
}

END {
	
	$OUTPUT
}
