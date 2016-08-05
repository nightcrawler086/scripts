[CmdletBinding()]
Param (
	[Parameter(Mandatory=$False,Position=1)]
	 [string[]]$SourceSystem,

	[Parameter(Mandatory=$True,Position=2)]
	 [string]$InputFile,

	[Parameter(Mandatory=$False,Position=3)]
	 [string]$OutFormat

)

BEGIN {

	# Determine import method
	$InputFileExt = [System.IO.Path]::GetExtension("$InputFile")
	switch ($InputFileExt) {
		".xlsx" {
			If (!(Get-Module ImportExcel)) {
				Import-Module -Name ImportExcel
			}
			If (!(Get-Module ImportExcel)) {
				Write-Host "ImportExcel module not installed.  Install it and run this script again"
				Exit 1
			}
			# Let's grab the right sheet, if required
			$SHEETS = (Get-ExcelSheetInfo $InputFile | Measure-Object).Count
			If ($SHEETS -gt 1) {
				Write-Host "There are multiple sheets in this file."
				Write-Host "Select the index of the sheet you wish to process."
				$SHEETINFO = Get-ExcelSheetInfo $InputFile | Select-Object Index,Name
				$SHEETINFO
				$IDX = Read-Host 'Index #'
				$IMPORT = Import-Excel $InputFile -WorksheetName $($SHEETINFO | Where {$_.Index -eq ""$IDX} | Select-Object -ExpandProperty Name)
			} Else {
			$IMPORT = Import-Excel $InputFile
			}
		".csv" {
			Write-Host "detected csv input file. importing..."
			$IMPORT = Import-Csv $InputFile

		}
	}

	# Define Output Array
	$OUTPUT = @()

}
PROCESS {
	
	$SUBSET = $IMPORT | Sort -Property TargetVdm -Unique | Where {$_.TargetVdm -ne "None"}
	ForEach ($OBJ in $SUBSET) {
			# Generate Prod VDM Creation Commands
		If ($($OBJ.TargetDM) -eq "None") {
			$TGTDM = "<TGT_DM>"
		} Else {
			$TGTDM = $($OBJ.TargetDm)
		}
		$CMDSTR = "nas_server -name $($OBJ.TargetVDM) -type vdm -create $TGTDM -setstate loaded pool=$($OBJ.TargetStoragePool)"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdVdmCreate";
			CommandHeading = "`r`n## VDM Creations Commands (PROD)`r`n";
			CommandString = $CMDSTR;
			ExecutionOrder = "1"
		}
	}
	$SUBSET = $IMPORT | Sort -Property TargetInterface -Unique | Where {$_.TargetInterface -ne "None" -and $_.TargetVdm -ne "None"}
	ForEach ($OBJ in $SUBSET) {
		# Generate Prod VDM Int Attach Commands
		$CMDSTR = "nas_server -vdm $($OBJ.TargetVDM) -attach <INT_NAME>"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdVdmAttachInt";
			CommandHeading = "`r`n## VDM Attach Interface Commands (PROD)`r`n";
			CommandString = "$CMDSTR";
			ExecutionOrder = "3"
		}
	}
	$SUBSET = $IMPORT | Sort TargetVdm,TargetDrSystem -Unique | Where {$_.TargetVdm -ne "None" -and $_.TargetDrSystem -ne "None"}
	ForEach ($OBJ in $SUBSET) {
			# Generate PROD VDM Replication Commands
			$CMDSTR = "nas_replicate -create $($OBJ.TargetVDM)_REP -source -vdm $($OBJ.TargetVDM) -destination -pool id=<DST_POOL_ID> -interconnect <INTERCONNECT_NAME> -max_time_out_of_sync 10 -background"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdVdmRep";
				CommandHeading = "`r`n## VDM Replication Commands (PROD)`r`n";
				CommandString = "$CMDSTR"
			}
	$SUBSET = $IMPORT | Sort TargetSystem,TargetDrSystem -Unique | Where {$_.TargetDrSystem -ne "None" -and $_.TargetSystem -ne "None"}
	ForEach ($OBJ in $SUBSET) {
		# Create Replication Passphrase on Source System
		$CMDSTR = "nas_cel -create $($OBJ.TargetDrSystem) -ip <DR_CS_IP> -passphrase nasadmin"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdRepPass";
			CommandHeading = "`r`n## Create Replication Passphrase Commands (PROD)`r`n";
			CommandString = "$CMDSTR"
		}
		# Create Replication Passphrase on Destination System
		$CMDSTR = "nas_cel -create $($OBJ.TargetSystem) -ip <PRD_CS_IP> -passphrase nasadmin"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "drRepPass";
			CommandHeading = "`r`n## Create Replication Passphrase Commands (DR)`r`n";
			CommandString = "$CMDSTR"
		}
	}
	$SUBSET = $IMPORT | Sort TargetSystem,TargetDm,TargetSystem | Where {$_.TargetSystem -ne "None" -and $_.TargetDm -ne "None" -and $_.TargetDrSystem -ne "None"}
		# Create Datamover Interconnect on Prod System
		$CMDSTR = "nas_cel -interconnect -create <INTERCONNECT_NAME> -source_server $($OBJ.TargetDm) -destination_system $($OBJ.TargetDrSystem) -destination_server <TGT_DR_DM> -source_interfaces ip=<PRD_REP_INT> -destination_interfaces ip=<DR_REP_INT>"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdCreateInterconnect";
			CommandHeading = "`r`n## Create Datamover Interconnection Commands (PROD)`r`n";
			CommandString = "$CMDSTR"
		}
		# Create Replication Interconnect on Cob(DR) System
		$CMDSTR = "nas_cel -interconnect -create <INTERCONNECT_NAME> -source_server <TGT_DR_DM> -destination_system $($OBJ.TargetDrSystem) -destination_server <TGT_DR_DM> -source_interfaces ip=<DR_REP_IP> -destination_interfaces ip=<TGT_DR_REP_INT>"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "drCreateInterconnect";
			CommandHeading = "`r`n## Create Datamover Interconnection Commands (DR)`r`n";
			CommandString = "$CMDSTR"
		}
	}
	$SUBSET = $IMPORT | Sort TargetIp -Unique | Where {$_.TargetIp -ne "None"}
	ForEach ($OBJ in $SUBSET) {
		If ($($OBJ.TargetDm) -eq "None") {
			$TGTDM = "<TGT_DM>"
		} Else {
			$TGTDM = $($OBJ.TargetDm)
		}
		If ($($OBJ.TargetInterface) -eq "None") {
			$TGTINT = "<TGT_INT>"
		} Else {
			$TGTINT = $($OBJ.TargetInterface)
		}
		# Generate Prod Interface Configuration Commands
		$CMDSTR = "server_ifconfig $TGTDM -create -Device fsn0 -name $TGTINT -protocol IP $($OBJ.TargetIp) <MASK> <BROADCAST>" 		
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdIntCreate";
			CommandHeading = "`r`n## Create Interface Commands (PROD)`r`n";
			CommandString = "$CMDSTR";
			ExecutionOrder = "2"
		}
	}
	$SUBSET = $IMPORT | Sort TargetDrIp -Unique | Where {$_.TargetDrIp -ne "None"}
	ForEach ($OBJ in $SUBSET) {
		# Generate Cob(DR) Interface Configuration Commands
		$CMDSTR = "server_ifconfig <TGT_DR_DM> -create -Device fsn0 -name <INT_NAME> -protocol IP $($OBJ.TargetDrIp) <MASK> <BROADCAST>" 		
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "drIntCreate";
			CommandHeading = "`r`n## Create Interface Commands (DR)`r`n";
			CommandString = "$CMDSTR"
		}
	}
	$SUBSET = $IMPORT | Sort TargetVdm -Unique | Where {$_.Cifs -ne "None" -and $_.TargetVdm -ne "None"}
	ForEach ($OBJ in $SUBSET) {
		# Generate Prod Create CIFS Server Commands
		$CMDSTR = "server_cifs $($OBJ.TargetVdm) -add compname=$($OBJ.TargetVdm),domain=nam.nsroot.net,interface=<INT_NAME>,local_users"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdCifsCreate";
			CommandHeading = "`r`n## Create CIFS Server Commands (PROD)`r`n";
			CommandString = "$CMDSTR";
			ExecutionOrder = "7"
		}
		# Generate Prod Join CIFS Server Commands 
		$CMDSTR = "server_cifs $($OBJ.TargetVdm) -Join compname=$($OBJ.TargetVdm),domain=nam.nsroot.net,admin=<ADMIN_USER>,ou=`"ou=Servers:ou=NAS:ou=INFRA`""
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdCifsJoin";
			CommandHeading = "`r`n## Join CIFS Server Commands (PROD)`r`n";
			CommandString = "$CMDSTR";
			ExecutionOrder = "8"
		}
	}
	$SUBSET = $IMPORT | Sort TargetVdm -Unique | Where {$_.Nfs -ne "None" -and $_.TargetVdm -ne "None"}
	ForEach ($OBJ in $SUBSET) {
		# Generate Prod NFS LDAP Commands
		$CMDSTR = "server_ldap <TGT_DM> -add -basedn <BASE_DN> -servers <CSV_SERVER_LIST> -sslenabled n"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdNfsLdap";
			CommandHeading = "`r`n## NFS LDAP Configuration (Physical Datamover Level) Commands (PROD)`r`n";
			CommandString = "$CMDSTR"
		}
		$CMDSTR = "nss_base_passwd <DISTINGUISHED_NAME>`r`nnss_base_group <DISTINGUISHED_NAME>`r`nnss_base_netgroup <DISTINGUISHED_NAME>"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdNfsLdapVdm";
			CommandHeading = "`r`n## NFS LDAP Configuration (VDM Level) Commands (PROD)`r`n";
			CommandString = "$CMDSTR"
			Comments = "**Write the following to the file ``/nasmcd/quota/slot_<DM_NUM>/root_vdm_<VDM_NUM>/.etc/ldap.conf``**"
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
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdNfsNsSwitch";
			CommandHeading = "`r`n## NFS NS Switch Configuration (PROD)`r`n";
			CommandString = "$CMDSTR";
			Comments = "**Copy and paste this into the ``/nasmcd/quota/slot_<DM_NUM>/root_vdm_<VDM_NUM>/.etc/nsswitch.conf``**"
		}
	}
	$SUBSET = $IMPORT | Sort TargetFs | Where {$_.TargetFs -ne "None"}
	ForEach ($OBJ in $SUBSET) {
		# Target Prod FS Create Commands
		$CMDSTR = "nas_fs -name $($OBJ.TargetFs) -type uxfs -create size=$($OBJ.FsSizeGB)GB pool=$($OBJ.TargetStoragePool) -option slice=y"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdFsCreate";
			CommandHeading = "`r`n## Filesystem Creation Commands (PROD)`r`n";
			CommandString = "$CMDSTR";
			ExecutionOrder = "4"
		}
		If ($($OBJ.Dedupe) -eq "Yes") {
			# Target Prod FS Dedupe Commands
			$CMDSTR = "fs_dedupe -modify $($OBJ.TargetFs) -state on"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdFsDedupe";
				CommandHeading = "`r`n## Filesystem Deduplication Commands (PROD)`r`n";
				CommandString = "$CMDSTR";
				Comments = "`r`n**Only run dedupe commands if dedupe is enabled on the source volume**`r`n"
			}
		}
		# Target Prod Checkpoint Commands
		$CMDSTR = "nas_ckpt_schedule -create $($OBJ.TargetFs)_DAILY_SCHED -filesystem $($OBJ.TargetFs) -description ""1730hrs daily checkpoint schedule for $($OBJ.TargetFs)"" -recurrence daily -every 1 -start_on <DATE> -runtimes 17:30 -keep 7"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdFsCkpt";
			CommandHeading = "`r`n## Filesystem Checkpoint Commands (PROD)`r`n";
			CommandString = "$CMDSTR"
		}
		If ($($OBJ.TargetDm) -match "server_[0-9]$") {
			$TGTDM = $($OBJ.TargetDm)
			$DMNUM = $TGTDM.Substring(7)
			$CMDSTR = "mkdir /nasmcd/quota/slot_$DMNUM/root_vdm_<VDM_NUM>/$($OBJ.TargetFs)/$($OBJ.TargetFs)"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdFsQtree";
				CommandString = "$CMDSTR"
				CommandHeading = "`r`n## Filesystem Qtree Commands (PROD)`r`n";
			} 
		} Else {
			$CMDSTR = "mkdir /nasmcd/quota/slot_<DM_NUM>/root_vdm_<VDM_NUM>/$($OBJ.TargetFs)/$($OBJ.TargetFs)"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdFsQtree";
				CommandHeading = "`r`n## Filesystem Qtree Commands (PROD)`r`n";
				CommandString = "$CMDSTR";
				Comments = "Could not find valid Qtree name...using TargetFilesystem as Qtree name";
				ExecutionOrder = "6"
			}
		} 
		# FS Mount Commands
		$CMDSTR = "server_mount $($OBJ.TargetVDM) $($OBJ.TargetFs) /$($OBJ.TargetFs)"
        $OUTPUT += New-Object -TypeName PSObject -Property @{
	        SourceSystem = $OBJ.SourceSystem;
		    TargetSystem = $OBJ.TargetSystem;
		    TargetDrSystem = $OBJ.TargetDrSystem;
		    CommandType = "prdFsMnt";
		    CommandHeading = "`r`n## Filesystem Mount Commands (PROD)`r`n";
		    CommandString = "$CMDSTR";
			ExecutionOrder = "5"
        }
		# FS Export Commands
		If ($($OBJ.TargetCifsServer) -notmatch "N/A" -and $($OBJ.TargetCifsServer) -ne "") {
			$CMDSTR = "server_export $($OBJ.TargetVDM) -Protocol cifs -name $($OBJ.TargetFs) -o netbios=$($OBJ.TargetVDM) /$($OBJ.TargetFs)/$($OBJ.TargetFs)"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdCifsExport";
				CommandHeading = "`r`n## CIFS Export Commands (PROD)`r`n";
				CommandString = "$CMDSTR";
				ExecutionOrder = "9"
			}
		}
		If ($($OBJ.TargetNfsServer) -notmatch "N/A" -and $($OBJ.TargetNfsServer) -ne "") {
			$CMDSTR = "server_export $($OBJ.TargetVDM) -Protocol nfs -name $($OBJ.TargetFs) -o rw=<CLIENTS>,ro=<CLIENTS>,root=<CLIENTS> /$($OBJ.TargetFs)/$($OBJ.TargetFs)"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdNfsExport";
				CommandHeading = "`r`n## NFS Export Commands (PROD)`r`n";
				CommandString = "$CMDSTR";
				ExecutionOrder = "10"
			}
		}
		# FS Replication Commands
		If ($($OBJ.TargetDrFs) -ne "" -and $($OBJ.TargetDrFs) -notmatch "N/A") {
			$CMDSTR = "nas_replicate -create $($OBJ.TargetFs)_REP -source -fs $($OBJ.TargetFs) -destination -fs $($OBJ.TargetDrFs) -interconnect <INTERCONNECT_NAME> -max_time_out_of_sync 10 -background"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdFsRep";
				CommandHeading = "`r`n## Filesystem Replication Commands (PROD)`r`n";
				CommandString = "$CMDSTR"
			}
		}
	}
	$SUBSET = $IMPORT | Where {$_.TargetDrSystem -ne "" -and $_.TargetDrSystem -notmatch "N/A" -and $_.TargetDrFs -ne "" -and $_.TargetDrFs -notmatch "N/A"}
	ForEach ($OBJ in $SUBSET) {
		# Cob (DR) FS Creation Commands
		$CMDSTR = "nas_fs -name $($OBJ.TargetDrFs) -create samesize:$($OBJ.TargetFs):cel:$($OBJ.TargetDrSystem) pool:$($OBJ.TargetDrStoragePool)" 
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "drFsCreate";
			CommandHeading = "`r`n## Filesystem Creation Commands (DR)`r`n";
			CommandString = "$CMDSTR"
		}
		# Cob (DR) Mount Commands
		$CMDSTR = "server_mount $($OBJ.TargetVDM) -o ro $($OBJ.TargetDrFs) /$($OBJ.TargetDrFs)"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "drFsMnt";
			CommandHeading = "`r`n## Filesystem Mount Commands (DR)`r`n";
			CommandString = "$CMDSTR"
		}
		# Cob (DR) Checkpoint Commands
		$CMDSTR = "nas_ckpt_schedule -create $($OBJ.TargetDrFs)`_DAILY_SCHED -filesystem $($OBJ.TargetDrFs) -description ""1730hrs daily checkpoint schedule for $($OBJ.TargetDrFs)"" -recurrence daily -every 1 -start_on <DATE> -runtimes 17:30 -keep 7"
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

END {

	switch ($OutFormat) {
		TXT {	
			$TIMESTAMP = $(Get-Date -Format yyyyMMddHHmmss)
			New-Item -Path .\ -Name ".\${TIMESTAMP}_provisioning-scripts" -ItemType directory | Out-Null
			$SYSTEMS = $OUTPUT | Select-Object -Property SourceSystem,TargetSystem -Unique
			$CMDBLK = "``````"
			ForEach ($OBJ in $SYSTEMS) {
				If ($($OBJ.SourceSystem) -ne "" -and $($OBJ.TargetSystem) -ne "") {
					New-Item -Path .\ -Name ".\${TIMESTAMP}_provisioning-scripts\$($OBJ.SourceSystem)" -ItemType directory -Force | Out-Null
					Write-Output "# Provisioning Script for $($OBJ.TargetSystem)`r`n" |
						Tee-Object ".\${TIMESTAMP}_provisioning-scripts\$($OBJ.SourceSystem)\${TIMESTAMP}_$($OBJ.SourceSystem)_$($OBJ.TargetSystem)-script.txt" -Append
					Write-Output "**These commands still need to be validated by hand, as all values cannot be added programmatically**" |
						Tee-Object ".\${TIMESTAMP}_provisioning-scripts\$($OBJ.SourceSystem)\${TIMESTAMP}_$($OBJ.SourceSystem)_$($OBJ.TargetSystem)-script.txt" -Append
					Write-Output "**Run a Find for the string 'N/A' and placeholders enclosed in <>**" |
						Tee-Object ".\${TIMESTAMP}_provisioning-scripts\$($OBJ.SourceSystem)\${TIMESTAMP}_$($OBJ.SourceSystem)_$($OBJ.TargetSystem)-script.txt" -Append
				}
			}
			$CMDTYPES = $OUTPUT | 
				Sort -Property SourceSystem,TargetSystem,CommandType -Unique | 
					Sort -Property CommandType -Descending
			ForEach ($OBJ in $CMDTYPES) {
				Write-Output "$($OBJ.CommandHeading)" |
					Tee-Object ".\${TIMESTAMP}_provisioning-scripts\$($OBJ.SourceSystem)\${TIMESTAMP}_$($OBJ.SourceSystem)_$($OBJ.TargetSystem)-script.txt" -Append
				#Write-Output "$($OBJ.Comments)" | Tee-Object "${TIMESTAMP}_$($OBJ.SourceSystem)_$($OBJ.TargetSystem)-script.txt" -Append
				Write-Output "$CMDBLK" |
					Tee-Object ".\${TIMESTAMP}_provisioning-scripts\$($OBJ.SourceSystem)\${TIMESTAMP}_$($OBJ.SourceSystem)_$($OBJ.TargetSystem)-script.txt" -Append
				$ALLCMDS = $OUTPUT |
					Where {$_.SourceSystem -eq "$($OBJ.SourceSystem)" -and $_.TargetSystem -eq "$($OBJ.TargetSystem)" -and $_.CommandType -eq "$($OBJ.CommandType)"}
				ForEach ($CMD in $ALLCMDS) {
					#If ($($CMD.Comments) -ne "") {
					#	Write-Output "$($CMD.CommandString) # $($CMD.Comments)" | Tee-Object "${TIMESTAMP}_$($CMD.SourceSystem)_$($OBJ.TargetSystem)-script.txt" -Append
					#} Else {
					Write-Output "$($CMD.CommandString)" |
						Tee-Object ".\${TIMESTAMP}_provisioning-scripts\$($OBJ.SourceSystem)\${TIMESTAMP}_$($CMD.SourceSystem)_$($OBJ.TargetSystem)-script.txt" -Append
				}
				Write-Output "$CMDBLK" |
					Tee-Object ".\${TIMESTAMP}_provisioning-scripts\$($OBJ.SourceSystem)\${TIMESTAMP}_$($OBJ.SourceSystem)_$($OBJ.TargetSystem)-script.txt" -Append
				} 
			}
		CSV {
			$TIMESTAMP = $(Get-Date -Format yyyyMMddHHmmss)
			New-Item -Path .\ -Name ".\${TIMESTAMP}_provisioning-scripts" -ItemType directory | Out-Null
			$ALLTGTSYS = $OUTPUT | Sort -Property TargetSystem -Unique
			ForEach ($TGTSYS in $ALLTGTSYS) {
				New-Item -Path .\ -Name ".\${TIMESTAMP}_provisioning-scripts\$($TGTSYS.SourceSystem)" -ItemType directory -Force | Out-Null
				$ALLCMDS = $OUTPUT | Where {$_.TargetSystem -eq "$($TGTSYS.TargetSystem)"} 
				$ALLCMDS | Export-Csv -NoTypeInformation -Path ".\${TIMESTAMP}_provisioning-scripts\$($TGTSYS.SourceSystem)\${TIMESTAMP}_$($TGTSYS.SourceSystem)_$($TGTSYS.TargetSystem).csv"
			}
		} 
		JSON {
			$TIMESTAMP = $(Get-Date -Format yyyyMMddHHmmss)
			New-Item -Path .\ -Name ".\${TIMESTAMP}_provisioning-scripts" -ItemType directory | Out-Null
			$ALLTGTSYS = $OUTPUT | Sort -Property TargetSystem -Unique
			ForEach ($TGTSYS in $ALLTGTSYS) {
				New-Item -Path .\ -Name ".\${TIMESTAMP}_provisioning-scripts\$($TGTSYS.SourceSystem)" -ItemType directory -Force | Out-Null
				$ALLCMDS = $OUTPUT | Where {$_.TargetSystem -eq "$($TGTSYS.TargetSystem)"} 
				$ALLCMDS | ConvertTo-Json | Out-File -FilePath ".\${TIMESTAMP}_provisioning-scripts\$($TGTSYS.SourceSystem)\${TIMESTAMP}_$($TGTSYS.SourceSystem)_$($TGTSYS.TargetSystem).json"
			}
		}
		default {
			$OUTPUT
		}
	}
}
