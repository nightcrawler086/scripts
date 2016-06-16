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
				CommandHeading = "`r`n## VDM Creations Commands (PROD)`r`n";
				CommandString = $CMDSTR
			}
			# Generate Prod VDM Int Attach Commands
			$CMDSTR = "nas_server -vdm $($OBJ.TargetVDM) -attach <INT_NAME>"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdVdmAttachInt";
				CommandHeading = "`r`n## VDM Attach Interface Commands (PROD)`r`n";
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
				CommandHeading = "`r`n## VDM Replication Commands (PROD)`r`n";
				CommandString = "$CMDSTR"
			}
			# Generate Cob(DR) VDM Int Attach Commands
			$CMDSTR = "nas_server -vdm $($OBJ.TargetVDM) -attach <INT_NAME>"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "drVdmAttachInt";
				CommandHeading = "`r`n## VDM Attach Interface Commands (DR)`r`n";
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
			If ($($OBJ.TargetDm) -match "server_[0-9]$") {
				$TGTDM = $($OBJ.TargetDm)
				$TGTDMNUM = $TGTDM.Substring(7)
			} Else {
				$TGTDMNUM = "<TGT_DM_NUM>"
			}
			If ($($OBJ.TargetDrDm) -match "server_[0-9]$") {
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
				CommandHeading = "`r`n## Create Replication Passphrase Commands (PROD)`r`n";
				CommandString = "$CMDSTR"
			}
			# Create Replication Passphrase on Destination System
			$CMDSTR = "nas_cel -create $($OBJ.TargetDrSystem) -ip <REP_IP> -passphrase <REP_PASS>"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "drRepPass";
				CommandHeading = "`r`n## Create Replication Passphrase Commands (DR)`r`n";
				CommandString = "$CMDSTR"
			}
			# Create Replication Interconnect on Prod System
			$CMDSTR = "nas_cel -interconnect -create $TGTLOC`_dm$TGTDMNUM`-$TGTDRLOC`_dm$TGTDRDMNUM -source_server $TGTDM -destination_system $TGTDRSYS -destination_server $TGTDRDM -source_interfaces ip=<REP_IP> -destination_interfaces ip=<REP_IP>"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdCreateInterconnect";
				CommandHeading = "`r`n## Create Replication Interconnect Commands (PROD)`r`n";
				CommandString = "$CMDSTR"
			}
			# Create Replication Interconnect on Cob(DR) System
			$CMDSTR = "nas_cel -interconnect -create $TGTDRLOC`_dm$TGTDRDMNUM`-$TGTLOC`_dm$TGTDMNUM -source_server $TGTDRDM -destination_system $TGTSYS -destination_server $TGTDM -source_interfaces ip=<REP_IP> -destination_interfaces ip=<REP_IP>"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "drCreateInterconnect";
				CommandHeading = "`r`n## Create Replication Interconnect Commands (DR)`r`n";
				CommandString = "$CMDSTR"
			}
		}
	$SUBSET = $ALLSYSTEMS | 
		Where-Object {$_.TargetIp -match "([0-9]{1,3}\.){3}[0-9]{1,3}$"} | 
			Sort-Object -Property TargetIp -Unique
	ForEach ($OBJ in $SUBSET) {
		# Generate Prod Interface Configuration Commands
		$CMDSTR = "server_ifconfig $($OBJ.TargetDM) -create -Device fsn0 -name <INT_NAME> -protocol IP $($OBJ.TargetIp) <MASK> <BROADCAST>" 		
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdIntCreate";
			CommandHeading = "`r`n## Create Interface Commands (PROD)`r`n";
			CommandString = "$CMDSTR"
		}
	}
	$SUBSET = $ALLSYSTEMS | 
		Where-Object {$_.TargetDrIp -match "([0-9]{1,3}\.){3}[0-9]{1,3}$"} | 
			Sort-Object -Property TargetDrIp -Unique
	ForEach ($OBJ in $SUBSET) {
		# Generate Cob(DR) Interface Configuration Commands
		$CMDSTR = "server_ifconfig $($OBJ.TargetDrDM) -create -Device fsn0 -name <INT_NAME> -protocol IP $($OBJ.TargetDrIp) <MASK> <BROADCAST>" 		
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "drIntCreate";
			CommandHeading = "`r`n## Create Interface Commands (DR)`r`n";
			CommandString = "$CMDSTR"
		}
	}
	$SUBSET = $ALLSYSTEMS | 
		Where-Object {$_.TargetCifsServer -ne "" -or $_.TargetCifsServer -notlike "N/A" -and $_.TargetProtocol -eq "CIFS" -or $_.TargetProtocol -eq "BOTH"} | 
			Sort-Object -Property TargetCifsServer -Unique
	ForEach ($OBJ in $SUBSET) {
		# Generate Prod Create CIFS Server Commands
		$CMDSTR = "server_cifs $($OBJ.TargetCifsServer) -add compname=$($OBJ.TargetCifsServer),domain=nam.nsroot.net,interface=<INT_NAME>,local_users"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdCifsCreate";
			CommandHeading = "`r`n## Create CIFS Server Commands (PROD)`r`n";
			CommandString = "$CMDSTR"
		}
		# Generate Prod Join CIFS Server Commands 
		$CMDSTR = "server_cifs $($OBJ.TargetCifsServer) -Join compname=$($OBJ.TargetCifsServer),domain=nam.nsroot.net,admin=<ADMIN_USER>,`"ou=Servers:ou=NAS:ou=INFRA`""
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdCifsJoin";
			CommandHeading = "`r`n## Join CIFS Server Commands (PROD)`r`n";
			CommandString = "$CMDSTR"
		}
	}
	$SUBSET = $ALLSYSTEMS | 
		Where-Object {$_.TargetNfsServer -ne "" -or $_.TargetNfsSever -notlike "N/A"} |
			Sort-Object -Property TargetNfsServer -Unique
	ForEach ($OBJ in $SUBSET) {
		If ($($OBJ.TargetNfsServer) -ne "" -or $($OBJ.TargetNfsServer) -notlike "N/A") {
			# Generate Prod NFS LDAP Commands
			$CMDSTR = "server_ldap $($OBJ.TargetDm) -add -basedn <BASE_DN> -servers <CSV_SERVER_LIST> -sslenabled n"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdNfsLdap";
				CommandHeading = "`r`n## NFS LDAP Configuration Commands (PROD)`r`n";
				CommandString = "$CMDSTR"
			}
			$CMDSTR = "nss_base_passwd <DISTINGUISHED_NAME>`r`nnss_base_group <DISTINGUISHED_NAME>`r`nnss_base_netgroup <DISTINGUISHED_NAME>"
			If ($($OBJ.TargetDm) -match "server_[0-9]$") {
				$TGTDM = $($OBJ.TargetDm)
				$DMNUM = $TGTDM.Substring(7)
				$OUTPUT += New-Object -TypeName PSObject -Property @{
					SourceSystem = $OBJ.SourceSystem;
					TargetSystem = $OBJ.TargetSystem;
					TargetDrSystem = $OBJ.TargetDrSystem;
					CommandType = "prdNfsLdapVdm";
					CommandHeading = "`r`n## NFS LDAP Configuration (VDM Level) Commands (PROD)`r`n";
					CommandString = "$CMDSTR"
					Comments = "**Write the following to the file ``/nasmcd/quota/slot_$DMNUM/root_vdm_<VDM_NUM>/.etc/ldap.conf``**"
				}
			} Else {
				$OUTPUT += New-Object -TypeName PSObject -Property @{
					SourceSystem = $OBJ.SourceSystem;
					TargetSystem = $OBJ.TargetSystem;
					TargetDrSystem = $OBJ.TargetDrSystem;
					CommandType = "prdNfsLdapVdm";
					CommandHeading = "`r`n## NFS LDAP Configuration (VDM Level) Commands (PROD)`r`n";
					CommandString = "$CMDSTR"
					Comments = "**Write the following to the file ``/nasmcd/quota/slot_<DM_NUM>/root_vdm_<VDM_NUM>/.etc/ldap.conf``**"
				}
			}
			$CMDSTR = "server_nsdomains $($OBJ.TargetVdm) -set -resolver LDAP=<LDAP_DN>`r`nserver_nsdomains $($OBJ.TargetVdm) -set -resolver DNS=<DOMAIN_NAME>`r`nserver_nsdomains $($OBJ.TargetVdm) -enable`r`nserver_nsdomains $($OBJ.TargetVdm)"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdNfsNsDomain";
				CommandHeading = "`r`n## NFS NS Domain Configuration Commands (PROD)`r`n";
				CommandString = "$CMDSTR";
				Comments = ""
			}
			$CMDSTR = "passwd: files ldap`r`ngroup: files ldap`r`nhosts: files dns`r`nnetgroup: files ldap"
			If ($($OBJ.TargetDm) -match "server_[0-9]$") {
				$TGTDM = $($OBJ.TargetDm)
				$DMNUM = $TGTDM.Substring(7)
				$OUTPUT += New-Object -TypeName PSObject -Property @{
					SourceSystem = $OBJ.SourceSystem;
					TargetSystem = $OBJ.TargetSystem;
					TargetDrSystem = $OBJ.TargetDrSystem;
					CommandType = "prdNfsNsSwitch";
					CommandHeading = "`r`n## NFS NS Switch Configuration (PROD)`r`n";
					CommandString = "$CMDSTR";
					Comments = "**Copy and paste this into the ``/nasmcd/quota/slot_$DMNUM/root_vdm_<VDM_NUM>/.etc/nsswitch.conf``**"
				}
			} Else {
				$OUTPUT += New-Object -TypeName PSObject -Property @{
					SourceSystem = $OBJ.SourceSystem;
					TargetSystem = $OBJ.TargetSystem;
					TargetDrSystem = $OBJ.TargetDrSystem;
					CommandType = "prdNfsNsSwitch";
					CommandHeading = "`r`n## NFS NS Switch Configuration (PROD)`r`n";
					CommandString = "$CMDSTR";
					Comments = "**Copy and paste this into the ``/nasmcd/quota/slot_<DMNUM>/root_vdm_<VDM_NUM>/.etc/nsswitch.conf``**"
				}	
			}
		}
	}
	# ***** Left off here *****
	# Need to revise filtering in $SUBSET definition
	# Should be $ALLSYSTEMS | Where <something> | sort -property <props> -Unique
	$SUBSET = $ALLSYSTEMS | Sort-Object -Property TargetFilesystem -Unique
	ForEach ($OBJ in $SUBSET) {
		If ($($OBJ.TargetFilesystem) -ne "" -or $($OBJ.TargetFilesystem) -notlike "N/A") {
			$CMDSTR = "nas_fs -name $($OBJ.TargetFilesystem) -type $($OBJ.TargetSecurityStyle) -create size=$($OBJ.TargetCapacityGB)GB pool=$($OBJ.TargetStoragePool) -option slice=y"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdFsCreate";
				CommandHeading = "`r`n## Filesystem Creation Commands (PROD)`r`n";
				CommandString = "$CMDSTR"
			}
			# Target Prod FS Dedupe Commands
			$CMDSTR = "fs_dedupe -modify $($OBJ.TargetFilesystem) -state on"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdFsDedupe";
				CommandHeading = "`r`n## Filesystem Deduplication Commands (PROD)`r`n";
				CommandString = "$CMDSTR";
				Comments = "`r`n**Only run dedupe commands if dedupe is enabled on the source volume**`r`n"

			}
			# Target Prod Checkpoint Commands
			$CMDSTR = "nas_ckpt_schedule -create $($OBJ.TargetFilesystem)_DAILY_SCHED -filesystem $($OBJ.TargetFilesystem) -description ""1730hrs daily checkpoint schedule for $($OBJ.TargetFilesystem)"" -recurrence daily -every 1 -start_on <DATE> -runtimes 17:30 -keep 7"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdFsCkpt";
				CommandHeading = "`r`n## Filesystem Checkpoint Commands (PROD)`r`n";
				CommandString = "$CMDSTR"
			}
			# Qtree commands
			If ($($OBJ.TargetDm) -match "server_[0-9]$") {
				$TGTDM = $($OBJ.TargetDm)
				$DMNUM = $TGTDM.Substring(7)
				$CMDSTR = "mkdir /nasmcd/quota/slot_$DMNUM/root_vdm_<VDM_NUM>/$($OBJ.TargetFilesystem)/$($OBJ.TargetQtree)"
				$OUTPUT += New-Object -TypeName PSObject -Property @{
					SourceSystem = $OBJ.SourceSystem;
					TargetSystem = $OBJ.TargetSystem;
					TargetDrSystem = $OBJ.TargetDrSystem;
					CommandType = "prdFsQtree";
					CommandString = "$CMDSTR"
					CommandHeading = "`r`n## Filesystem Qtree Commands (PROD)`r`n";
				} 
			} Else {
				$CMDSTR = "mkdir /nasmcd/quota/slot_<DM_NUM>/root_vdm_<VDM_NUM>/$($OBJ.TargetFilesystem)/$($OBJ.TargetQtree)"
				$OUTPUT += New-Object -TypeName PSObject -Property @{
					SourceSystem = $OBJ.SourceSystem;
					TargetSystem = $OBJ.TargetSystem;
					TargetDrSystem = $OBJ.TargetDrSystem;
					CommandType = "prdFsQtree";
					CommandHeading = "`r`n## Filesystem Qtree Commands (PROD)`r`n";
					CommandString = "$CMDSTR"
				} 
			}
			# FS Mount Commands
			$CMDSTR = "server_mount $($OBJ.TargetVDM) $($OBJ.TargetFilesystem) /$($OBJ.TargetFilesystem)"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdFsMnt";
				CommandHeading = "`r`n## Filesystem Mount Commands (PROD)`r`n";
				CommandString = "$CMDSTR"
			}
		}
		# FS Export Commands
		If ($($OBJ.TargetProtocol) -eq "CIFS" -or $($OBJ.TargetProtocol) -eq "BOTH") {
			$CMDSTR = "server_export $($OBJ.TargetVDM) -Protocol cifs -name $($OBJ.TargetFilesystem) -o netbios=$($OBJ.TargetVDM) /$($OBJ.TargetFilesystem)/$($OBJ.TargetFilesystem)"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdCifsExport";
				CommandHeading = "`r`n## CIFS Export Commands (PROD)`r`n";
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
				CommandHeading = "`r`n## NFS Export Commands (PROD)`r`n";
				CommandString = "$CMDSTR"
			}
		}
		# FS Replication Commands
		If ($($OBJ.TargetDrFilesystem) -ne "" -or $($OBJ.TargetDrFilesystem) -notlike "N/A") {
			$CMDSTR = "nas_replicate -create $($OBJ.TargetFilesystem)_REP -source -fs $($OBJ.TargetFilesystem) -destination -fs $($OBJ.TargetDrFilesystem) -interconnect <INTERCONNECT_NAME> -max_time_out_of_sync 10 -background"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdFsRep";
				CommandHeading = "`r`n## Filesystem Replication Commands (PROD)`r`n";
				CommandString = "$CMDSTR"
			}
			# Cob (DR) FS Creation Commands
			$CMDSTR = "nas_fs -name $($OBJ.TargetDrFilesystem) -create samesize:$($OBJ.TargetFilesystem):cel:$($OBJ.TargetDrSystem) pool:$($OBJ.TargetDrStoragePool)" 
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "drFsCreate";
				CommandHeading = "`r`n## Filesystem Creation Commands (DR)`r`n";
				CommandString = "$CMDSTR"
			}
			# Cob (DR) Mount Commands
			$CMDSTR = "server_mount $($OBJ.TargetVDM) -o ro $($OBJ.TargetDrFilesystem) /$($OBJ.TargetDrFilesystem)"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "drFsMnt";
				CommandHeading = "`r`n## Filesystem Mount Commands (DR)`r`n";
				CommandString = "$CMDSTR"
			}
			# Cob (DR) Checkpoint Commands
			$CMDSTR = "nas_ckpt_schedule -create $($OBJ.TargetDrFilesystem)_DAILY_SCHED -filesystem $($OBJ.TargetDrFilesystem) -description ""1730hrs daily checkpoint schedule for $($OBJ.TargetDrFilesystem)"" -recurrence daily -every 1 -start_on <DATE> -runtimes 17:30 -keep 7"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "drFsCkpt";
				CommandHeading = "`r`n## Filesystem Checkpoint Commands (DR)`r`n";
				CommandString = "$CMDSTR"
			}
		}
	}
}

END {

	# Write to Text File
	If ($OutFormat -eq "TXT") {
		$TIMESTAMP = $(Get-Date -Format yyyyMMddHHmmss)
		$SYSTEMS = $OUTPUT | Select-Object -Property SourceSystem,TargetSystem -Unique
		$CMDBLK = "``````"
		ForEach ($OBJ in $SYSTEMS) {
			If ($($OBJ.SourceSystem) -ne "" -and $($OBJ.TargetSystem) -ne "") {
				Write-Output "# Provisioning Script for $($OBJ.TargetSystem)`r`n" | Tee-Object "${TIMESTAMP}_$($OBJ.SourceSystem)_$($OBJ.TargetSystem)-script.txt"
			}
		}
		$CMDTYPES = $OUTPUT | Sort-Object -Property SourceSystem,TargetSystem,CommandType -Unique | Sort-Object -Property CommandType -Descending
		ForEach ($OBJ in $CMDTYPES) {
			Write-Output "$($OBJ.CommandHeading)" | Tee-Object "${TIMESTAMP}_$($OBJ.SourceSystem)_$($OBJ.TargetSystem)-script.txt" -Append
			Write-Output "$CMDBLK" | Tee-Object "${TIMESTAMP}_$($OBJ.SourceSystem)_$($OBJ.TargetSystem)-script.txt" -Append
			$ALLCMDS = $OUTPUT | Where-Object {$_.SourceSystem -eq "$($OBJ.SourceSystem)" -and $_.TargetSystem -eq "$($OBJ.TargetSystem)" -and $_.CommandType -eq "$($OBJ.CommandType)"}
			ForEach ($CMD in $ALLCMDS) {
				Write-Output $($CMD.CommandString) | Tee-Object "${TIMESTAMP}_$($CMD.SourceSystem)_$($OBJ.TargetSystem)-script.txt" -Append
			}
			Write-Output "$CMDBLK" | Tee-Object "${TIMESTAMP}_$($OBJ.SourceSystem)_$($OBJ.TargetSystem)-script.txt" -Append
		} 
	} Else {
		$OUTPUT
	}
	
}
