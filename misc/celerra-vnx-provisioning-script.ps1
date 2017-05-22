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

	If ($OutFormat -eq "") {
		Write-Host -ForegroundColor Yellow "No output format specified..."
		Write-Host -ForegroundColor Yellow "All output will be written to the console unless you specify and format"
		Write-Host -ForegroundColor Yellow "Enter a format, or none to send all output to the console"
		$RESPONSE = Read-Host '(txt/csv/json/none)'
		If ($RESPONSE -eq $NULL -or $RESPONSE -eq "none") {
			$OutFormat = ""
		} Else {
			$OutFormat = $RESPONSE
		}
	}

	$InputFileExt = [System.IO.Path]::GetExtension("$InputFile")
	switch ($InputFileExt) {
		".xlsx" {
			Write-Host "detected excel input file..."
			Write-Host "going to try to import the necessary modules..."
			If ((Get-Module -Name ImportExcel)) {
				Write-Host "ImportExcel module installed and imported"
				$SHEETS = Get-ExcelSheetInfo $InputFile | Measure-Object | Select-Object -ExpandProperty Count
				If ($SHEETS -gt 1) {
					Write-Host "There are multiple sheets in this file..."
					Write-Host "Select the index of the sheet you wish to process:"
					$SHEETINFO = Get-ExcelSheetInfo $InputFile | Select-Object Index,Name
					$SHEETINFO | Format-Table -Autosize
					$SHEETIDX = Read-Host 'Index #'
					$IMPORT = Import-Excel $InputFile -WorksheetName $($SHEETINFO | Where {$_.Index -eq "$SHEETIDX"} | Select-Object -ExpandProperty Name)
				} Else {
					$IMPORT = Import-Excel $InputFile 
				}
			} ElseIf ((Get-Module -ListAvailable -Name ImportExcel)) {
				Write-Host "ImportExcel module installed.  Importing..."
				Import-Module -Name ImportExcel
				$SHEETS = Get-ExcelSheetInfo $InputFile | Measure-Object | Select-Object -ExpandProperty Count
				If ($SHEETS -gt 1) {
					Write-Host "There are multiple sheets in this file..."
					Write-Host "Select the index of the sheet you wish to process:"
					$SHEETINFO = Get-ExcelSheetInfo $InputFile | Select-Object Index,Name
					$SHEETINFO
					$SHEETIDX = Read-Host 'Index #'
					$IMPORT = Import-Excel $InputFile -WorksheetName $($SHEETINFO | Where {$_.Index -eq "$SHEETIDX"} | Select-Object -ExpandProperty Name)
				} Else {
					$IMPORT = Import-Excel $InputFile
				}
			} Else {
				Write-Host "Did not find the ImportExcel module...trying to install it..."
				If (($PSVersionTable.PSVersion.Major) -ge 5) {
					Find-Module -Name ImportExcel | Install-Module
					If ($LastExitCode -eq 0) {
						$SHEETS = Get-ExcelSheetInfo $InputFile | Measure-Object | Select-Object -ExpandProperty Count
						If ($SHEETS -gt 1) {
							Write-Host "There are multiple sheets in this file..."
							Write-Host "Select the index of the sheet you wish to process:"
							$SHEETINFO = Get-ExcelSheetInfo $InputFile | Select-Object Index,Name
							$SHEETINFO
							$SHEETIDX = Read-Host 'Index #'
							$IMPORT = Import-Excel $InputFile -WorksheetName $($SHEETINFO | Where {$_.Index -eq "$SHEETIDX"} | Select-Object -ExpandProperty Name)
						} Else {
							$IMPORT = Import-Excel $InputFile
						}
					}
				} ElseIf (($PSVersionTable.PSVersion.Major) -le 4) {
					iex (new-object System.Net.WebClient).DownloadString('https://raw.github.com/dfinke/ImportExcel/master/Install.ps1')
					If ($LastExitCode -eq 0) {
						$SHEETS = Get-ExcelSheetInfo $InputFile | Measure-Object | Select-Object -ExpandProperty Count
						If ($SHEETS -gt 1) {
							Write-Host "There are multiple sheets in this file..."
							Write-Host "Select the index of the sheet you wish to process:"
							$SHEETINFO = Get-ExcelSheetInfo $InputFile | Select-Object Index,Name
							$SHEETINFO
							$SHEETIDX = Read-Host 'Index #'
							$IMPORT = Import-Excel $InputFile -WorksheetName $($SHEETINFO | Where {$_.Index -eq "$SHEETIDX"} | Select-Object -ExpandProperty Name)
						} Else {
							$IMPORT = Import-Excel $InputFile
						}
					}
				}
			}
		}
		".csv" {
			Write-Host "detected csv input file. importing..."
			$IMPORT = Import-Csv $InputFile

		}
	}
	# Let's Rename our properties to what we expect
	$INFILE = $IMPORT | Select-Object @{Name='ProdLocation';Expression={$_.'PROD Location'}},
		@{Name='SourceSystem';Expression={$_.'PROD Filer'}},
		@{Name='SourceVolume';Expression={$_.'PROD Volume'}},
		@{Name='SourceQtree';Expression={$_.'Source Qtree/Directory'}},
		@{Name='SourceDm';Expression={$_.'Source PROD Physical Data Mover'}},
		@{Name='SourceVdm';Expression={$_.'Source PROD Virtual Data Mover'}},
		@{Name='SourceCifsServer';Expression={$_.'Source CIFS SERVER'}},
		@{Name='SourceCapacityGB';Expression={$_.'Source PROD Capacity (GB)'}},
		@{Name='Replication';Expression={$_.'Replications'}},
		@{Name='AccessType';Expression={$_.'Protocol (NFS/CIFS/BOTH)'}},
		@{Name='DataType';Expression={$_.'Type of Data(APP/USER/BOTH)'}},
		@{Name='SourceSecurityStyle';Expression={$_.'Source Security Style'}},
		@{Name='SourceCobCapacityGB';Expression={$_.'COB Capacity (GB)'}},
		@{Name='SourceDrLocation';Expression={$_.'COB Location'}},
		@{Name='SourceDrSystem';Expression={$_.'COB Filer'}},
		@{Name='SourceDrVdm';Expression={$_.'COB Virtual Data Mover'}},
		@{Name='SourceDrVolume';Expression={$_.'COB Volume'}},
		@{Name='TechRefresh';Expression={$_.'Tech Refresh'}},
		@{Name='TargetSystem';Expression={$_.'Target Prod VNX Frame'}},
		@{Name='TargetDm';Expression={$_.'Target Prod Physical DataMover'}},
		@{Name='TargetVdm';Expression={$_.'Target Virtual DataMover'}},
		@{Name='TargetVdmRootDir';Expression={$_.'Root VDM Directory'}},
		@{Name='TargetQipEntry';Expression={$_.'Prod QIP Entry'}},
		@{Name='TargetIp';Expression={$_.'Prod IP'}},
		@{Name='TargetInterface';Expression={$_.'Interface Name'}},
		@{Name='TargetCifsServer';Expression={$_.'Target Cifs server Name'}},
		@{Name='TargetNfsServer';Expression={$_.'Target NFS server Name'}},
		@{Name='3dnsCname';Expression={$_.'3 DNS cname entry'}},
		@{Name='3dnsSetup';Expression={$_.'3DNS setup'}},
		@{Name='3dnsRequest';Expression={$_.'3DNS Setup Request'}},
		@{Name='VpnRequest';Expression={$_.'VPN request'}},
		@{Name='TapePolicy';Expression={$_.'New Tape Policy Name Required'}},
		@{Name='Comments';Expression={$_.'Comments'}},
		@{Name='TargetVolume';Expression={$_.'Target Prod File System'}},
		@{Name='TargetQtree';Expression={$_.'Target Qtree/Directory'}},
		@{Name='TargetCapacityGB';Expression={$_.'Target Prod Capacity (GB)'}},
		@{Name='TargetSecurityStyle';Expression={$_.'Target Security Style'}},
		@{Name='TargetAccessType';Expression={$_.'Target Protocol (NFS/CIFS/BOTH)'}},
		@{Name='TargetDataType';Expression={$_.'Target Type of Data(APP/USER/BOTH)'}},
		@{Name='TargetStoragePool';Expression={$_.'Target Prod Pool'}},
		@{Name='LdapSetup';Expression={$_.'Ldap setup'}},
		@{Name='TargetDrSystem';Expression={$_.'Target COB VNX Frame'}},
		@{Name='TargetDrDm';Expression={$_.'Target COB Physical Data Mover'}},
		@{Name='TargetDrVdm';Expression={$_.'COB VDM'}},
		@{Name='TargetDrStoragePool';Expression={$_.'Target Cob Pool'}},
		@{Name='TargetDrVolume';Expression={$_.'Target Cob File System'}},
		@{Name='TargetDrCapacityGB';Expression={$_.'Target COB Capacity (GB)'}},
		@{Name='TargetDrIp';Expression={$_.'Cob IP'}},
		@{Name='TargetDrQipEntry';Expression={$_.'COB QIP Entry'}}
	
	# This just slices the import file with only the source system
	# specified when the script was executed
	
	If ($SourceSystem -notcontains $NULL) {
		$INFILE = $INFILE | Where-Object {$_.SourceSystem -eq "$SourceSystem"}
	}
	
	# Define Output Array
	$OUTPUT = @()


}
PROCESS {

	$SLICE = $INFILE | Where-Object {$_.TargetVdm -ne "None"} | Sort-Object -Property TargetVdm -Unique
	ForEach ($OBJ in $SLICE) {
		# Target VDM Creation Commands
		$PRDVDMCREATE = "nas_server -name $($OBJ.TargetVDM) -type vdm -create $($OBJ.TargetDM) -setstate loaded pool=$($OBJ.TargetStoragePool)"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdVdmCreate";
			CommandHeading = "`r`n## VDM Creations Commands $($OBJ.TargetSystem)`r`n";
			CommandString = $PRDVDMCREATE;
			ExecutionOrder = "01"
		}
	}
	##########################################
	# Start back here with the $SLICE command#
	##########################################
	$SLICE = $INFILE | Where-Object {$_.TargetDm -ne "None"} | Sort-Object -Property TargetVdm,TargetIp -Unique
	ForEach ($OBJ in $SLICE) {
		$TGTLOC = $($OBJ.ProdLocation)
		$TGTLOCSUB = $TGTLOC.Substring(0,3)
		$TGTSYS = $($OBJ.TargetSystem)
		$TGTFRAME = $TGTSYS.Substring(0,$TGTSYS.Length-1)
		$TGTFRAMENUM = $TGTFRAME.Substring(10,4)
		$TGTDM = $($OBJ.TargetDm)
		$TGTDMNUM = $TGTDM.Substring(7)
		# Prod Interface Creation Commands
		$PRDINTCREATE = "server_ifconfig $($OBJ.TargetDm) -create -Device fsn0 -name ${TGTLOCSUB}${TGTFRAMENUM}DM${TGTDMNUM}C0#"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdIntCreate";
			CommandHeading = "`r`n## Create Interface Commands $($OBJ.TargetSystem)`r`n";
			CommandString = "$PRDINTCREATE"
			ExecutionOrder = "02";
			Comments = "`r`n**The interface name should be in ALL CAPS, if not correct it before running the command**`r`n**Replace the trailing '#' with the interface number**`r`n"
		}
		# Generate Prod VDM Int Attach Commands
		$PRDVDMINTATT = "nas_server -vdm $($OBJ.TargetVDM) -attach ${TGTLOCSUB}${TGTFRAMENUM}DM${TGTDMNUM}C0#"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdVdmAttachInt";
			CommandHeading = "`r`n## VDM Attach Interface Commands $($OBJ.TargetSystem)`r`n";
			CommandString = "$PRDVDMINTATT";
			ExecutionOrder = "03";
			Comments = "`r`n**Double-check the interface name for accuracy**`r`n**Replace the trailing '#' with the interface number**`r`n"
		}
	}
	$SLICE = $INFILE | Sort-Object TargetSystem,TargetDrSystem -Unique
	ForEach ($OBJ in $SLICE) {
		# Create Replication Passphrase on Source System
		$PRDCELCREATE = "nas_cel -create $($OBJ.TargetDrSystem) -ip <COB_CS_IP> -passphrase nasadmin"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdRepPass";
			CommandHeading = "`r`n## Create Replication Passphrase Commands $($OBJ.TargetSystem)`r`n";
			CommandString = "$PRDCELCREATE"
			ExecutionOrder = "04";
			Comments = "`r`n**Replace the <COB_CS_IP> with the Control Station IP from the COB system**`r`n"
		}
		# Create Replication Passphrase on Destination System
		$DRCELCREATE = "nas_cel -create $($OBJ.TargetSystem) -ip <TGT_CS_IP> -passphrase nasadmin"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "drRepPass";
			CommandHeading = "`r`n## Create Replication Passphrase Commands $($OBJ.TargetDrSystem)`r`n";
			CommandString = "$DRCELCREATE"
			ExecutionOrder = "05";
			Comments = "`r`n**Replace the <TGT_CS_IP> with the Control Station IP from the PROD system**`r`n"
		}
		# Create Replication Interconnect on Prod System
		$PRDINCCREATE = "nas_cel -interconnect -create <TGT_DM#-COB_DM#> -source_server $($OBJ.TargetDm) -destination_system $($OBJ.TargetDrSystem) -destination_server <COB_DM> -source_interfaces ip=<TGT_REP_IP> -destination_interfaces ip=<COB_REP_IP>"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdCreateInterconnect";
			CommandHeading = "`r`n## Create Datamover Interconnection Commands $($OBJ.TargetSystem)`r`n";
			CommandString = "$PRDINCCREATE"
			ExecutionOrder = "06";
			Comments = "`r`n**Replace all values in <> with their proper values**`r`n"
		}
		# Create Replication Interconnect on Cob(DR) System
		$DRINCCREATE = "nas_cel -interconnect -create <COB_DM#-TGT_DM#> -source_server <COB_DM> -destination_system $($OBJ.TargetSystem) -destination_server $($OBJ.TargetDm) -source_interfaces ip=<COB_REP_IP> -destination_interfaces ip=<TGT_REP_INT>"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "drCreateInterconnect";
			CommandHeading = "`r`n## Create Datamover Interconnection Commands $($OBJ.TargetDrSystem)`r`n";
			CommandString = "$DRINCCREATE"
			ExecutionOrder = "07";
			Comments = "`r`n**Replace all values in <> with their proper values**`r`n"
		}
		# Generate PROD VDM Replication Commands
		$PRDVDMREP = "nas_replicate -create $($OBJ.TargetVDM)_REP -source -vdm $($OBJ.TargetVDM) -destination -pool id=<COB_POOL_ID> -interconnect <INTERCONNECT_NAME> -max_time_out_of_sync 10 -background"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdVdmRep";
			CommandHeading = "`r`n## VDM Replication Commands $($OBJ.TargetSystem)`r`n";
			CommandString = "$PRDVDMREP";
			ExecutionOrder = "08";
			Comments = "`r`n**Replace the all values in <> with their proper values**`r`n"
		}
		# Generate Cob(DR) Interface Configuration Commands
		$DRINTCREATE = "server_ifconfig <COB_DM> -create -Device fsn0 -name <COB_INT_NAME> -protocol IP $($OBJ.TargetDrIp) <MASK> <BROADCAST>" 		
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "drIntCreate";
			CommandHeading = "`r`n## Create Interface Commands $($OBJ.TargetDrSystem)`r`n";
			CommandString = "$DRINTCREATE";
			ExecutionOrder = "09";
			Comments = "`r`n**Replace all values in <>.  The MASK and BROADCAST can be found from the similar interface on the system**`r`n"
		}
	}
	$SLICE = $INFILE | Sort-Object -Property TargetVdm,TargetVolume -Unique
	ForEach ($OBJ in $SLICE) {
		# Target Filesystem Creation Commands
		$PRDFSCREATE = "nas_fs -name $($OBJ.TargetVolume) -type uxfs -create size=$($OBJ.SourceCapacityGB)GB pool=$($OBJ.TargetStoragePool) -option slice=y"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdFsCreate";
			CommandHeading = "`r`n## Filesystem Creation Commands for $($OBJ.TargetSystem)`r`n";
			CommandString = "$PRDFSCREATE";
			ExecutionOrder = "10";
			Comments = "`r`n**If replicating from VNX, use the 'DR' style volume creation command**`r`n"
		}
		# FS Mount Commands
		$PRDFSMOUNT = "server_mount $($OBJ.TargetVDM) $($OBJ.TargetVolume) /$($OBJ.TargetVolume)"
        $OUTPUT += New-Object -TypeName PSObject -Property @{
	        SourceSystem = $OBJ.SourceSystem;
		    TargetSystem = $OBJ.TargetSystem;
		    TargetDrSystem = $OBJ.TargetDrSystem;
		    CommandType = "prdFsMnt";
		    CommandHeading = "`r`n## Filesystem Mount Commands $($OBJ.TargetSystem)`r`n";
		    CommandString = "$PRDFSMOUNT";
			ExecutionOrder = "11"
        }
		# FS Qtree Commands
		$DMNUM = ($($OBJ.TargetDm)).Substring(7)
		$PRDQTCREATE = "mkdir /nasmcd/quota/slot_$DMNUM/root_vdm_<VDM_NUM>/$($OBJ.TargetVolume)/$($OBJ.TargetQtree)"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdFsQtree";
			CommandString = "$PRDQTCREATE"
			CommandHeading = "`r`n## Filesystem Qtree Commands $($OBJ.TargetSystem)`r`n";
			ExecutionOrder = "16";
			Comments = "`r`n**These commands need to be run as root**`r`n"
		} 
		# FS Export Commands
		$PRDEXPCREATE = "server_export $($OBJ.TargetVDM) -Protocol cifs -name $($OBJ.TargetQtree) -o netbios=$($OBJ.TargetVDM) /$($OBJ.TargetVolume)/$($OBJ.TargetQtree)"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdCifsExport";
			CommandHeading = "`r`n## CIFS Export Commands $($OBJ.TargetSystem)`r`n";
			CommandString = "$PRDEXPCREATE";
			ExecutionOrder = "17"
		}
		# Cob (DR) FS Creation Commands
		$DRFSCREATE = "nas_fs -name $($OBJ.TargetVolume) -create samesize=$($OBJ.TargetVolume):cel=$($OBJ.TargetSystem) pool=<COB_POOL>" 
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "drFsCreate";
			CommandHeading = "`r`n## Filesystem Creation Commands $($OBJ.TargetDrSystem)`r`n";
			CommandString = "$DRFSCREATE";
			ExecutionOrder = "15";
			Comments = "`r`n**Replace the <COB_POOL> with the name of the storage pool on the COB VNX**`r`n"
		}
		# COB (DR) FS Mount Commands
		$DRFSMOUNT = "server_mount $($OBJ.TargetVDM) -o ro $($OBJ.TargetVolume) /$($OBJ.TargetVolume)"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "drFsMnt";
			CommandHeading = "`r`n## Filesystem Mount Commands $($OBJ.TargetDrSystem)`r`n";
			CommandString = "$DRFSMOUNT";
			ExecutionOrder = "18";
			Comments = "`r`n**Must mount FS as read-only for replication commands to work**`r`n"
		}
		# Filesystem Replication Commands
		$PRDFSREP = "nas_replicate -create $($OBJ.TargetVolume)_REP -source -fs $($OBJ.TargetVolume) -destination -fs $($OBJ.TargetVolume) -interconnect <INTERCONNECT_NAME> -max_time_out_of_sync 10 -background"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdFsRep";
			CommandHeading = "`r`n## Filesystem Replication Commands $($OBJ.TargetSystem)`r`n";
			CommandString = "$PRDFSREP";
			ExecutionOrder = "19";
			Comments = "`r`n**Replace <INTERCONNECT_NAME> with the name of the datamover interconnect**`r`n"
		}
		# Filesystem Deduplication Commands
		$PRDFSDEDUPE = "fs_dedupe -modify $($OBJ.TargetVolume) -state on"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdFsDedupe";
			CommandHeading = "`r`n## Filesystem Deduplication Commands $($OBJ.TargetSystem)`r`n";
			CommandString = "$PRDFSDEDUPE";
			ExecutionOrder = "20"
			Comments = "`r`n**Only run dedupe commands if dedupe is enabled on the source**`r`n"
		}
		# Prod Filesystem Checkpoint Commands
		$PRDFSCKPT = "nas_ckpt_schedule -create $($OBJ.TargetVolume)_DAILY_SCHED -filesystem $($OBJ.TargetVolume) -description ""1730hrs daily checkpoint schedule for $($OBJ.TargetVolume)"" -recurrence daily -every 1 -start_on <DATE> -runtimes 17:30 -keep 7"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdFsCkpt";
			CommandHeading = "`r`n## Filesystem Checkpoint Commands $($OBJ.TargetSystem)`r`n";
			CommandString = "$PRDFSCKPT";
			ExecutionOrder = "21";
			Comments = "`r`n**Only run these commands after initial base copy has been completed**`r`n**Replace the <DATE> with the date which the command is executed**`n"
		}
		# COB (DR) Filesystem Backup Checkpoint Commands
		$DRFSCKPT = "nas_ckpt_schedule -create $($OBJ.TargetVolume)`_DAILY_SCHED -filesystem $($OBJ.TargetVolume) -description ""1710hrs daily checkpoint schedule for $($OBJ.TargetVolume)"" -recurrence daily -every 1 -start_on <DATE> -runtimes 17:10 -ckpt_name $($OBJ.TargetVolume)_ckpt_backup"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "drFsCkpt";
			CommandHeading = "`r`n## Filesystem Checkpoint Commands $($OBJ.TargetDrSystem)`r`n";
			CommandString = "$DRFSCKPT";
			ExecutionOrder = "22";
			Comments = "`r`n**Only run these commands after tgt->cob replication has been completed**`r`n**Replace the <DATE> with the date which the command is executed**`n"
		}
		# EMCOPY Incremental Commands
		$EMCOPYINC = "emcopy64.exe \\$($OBJ.SourceCifsServer)\$($OBJ.SourceVolume) \\$($OBJ.TargetVdm)\$($OBJ.TargetQtree) /s /sdd /d /o /a /secfix /i /lg /purge /r:0 /w:0 /c /log:D:\emcopy-log\$($OBJ.SourceVolume).txt"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "emcopyInc";
			CommandHeading = "`r`n## Incremental emcopy64.exe Commands`r`n";
			CommandString = "${EMCOPYINC}";
			ExecutionOrder = "23"
		}
		# EMCOPY Final Commands
		$EMCOPYFIN = "emcopy64.exe \\$($OBJ.SourceCifsServer)\$($OBJ.SourceVolume) \\$($OBJ.TargetVdm)\$($OBJ.TargetQtree) /s /sdd /d /o /a /i /lg /purge /r:0 /w:0 /c /log:D:\emcopy-log\$($OBJ.SourceVolume)-final.txt"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "emcopyFin";
			CommandHeading = "`r`n## Final emcopy64.exe Commands`r`n";
			CommandString = "${EMCOPYFIN}";
			ExecutionOrder = "24"
		}
	}
	$SLICE = $INFILE | Sort-Object TargetVdm -Unique
	ForEach ($OBJ in $SLICE) {
		# Generate Prod Create CIFS Server Commands
		$PRDCIFSCREATE = "server_cifs $($OBJ.TargetCifsServer) -add compname=$($OBJ.TargetCifsServer),domain=nam.nsroot.net,interface=<INT_NAME>,local_users"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdCifsCreate";
			CommandHeading = "`r`n## Create CIFS Server Commands $($OBJ.TargetSystem)`r`n";
			CommandString = "$PRDCIFSCREATE";
			ExecutionOrder = "13";
			Comments = "`r`n**Replace <INT_NAME> with the interface name**`r`n"
		}
		$PRDCIFSJOIN = "server_cifs $($OBJ.TargetCifsServer) -Join compname=$($OBJ.TargetCifsServer),domain=nam.nsroot.net,admin=<ADMIN_USER>,ou=`"ou=Servers:ou=NAS:ou=INFRA`""
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdCifsJoin";
			CommandHeading = "`r`n## Join CIFS Server Commands $($OBJ.TargetSystem)`r`n";
			CommandString = "$PRDCIFSJOIN";
			ExecutionOrder = "14";
			Comments = "`r`n**Replace the <ADMIN_USER> with a user that can add computers to the domain**`r`n"
		}
	}
}

END {

	switch ($OutFormat) {
		TXT {	
			$TIMESTAMP = $(Get-Date -Format yyyyMMddHHmmss)
			New-Item -Path .\ -Name ".\${TIMESTAMP}_provisioning-scripts" -ItemType directory | Out-Null
			$SYSTEMS = $OUTPUT | Sort-Object -Property SourceSystem,TargetSystem -Unique
			$CMDBLK = "``````"
			ForEach ($OBJ in $SYSTEMS) {
					New-Item -Path .\ -Name ".\${TIMESTAMP}_provisioning-scripts\$($OBJ.SourceSystem)" -ItemType directory -Force | Out-Null
					Write-Output "# Provisioning Script for $($OBJ.TargetSystem) & $($OBJ.TargetDrSystem)`r`n" |
						Tee-Object ".\${TIMESTAMP}_provisioning-scripts\$($OBJ.SourceSystem)\$($OBJ.TargetSystem)-$($OBJ.TargetDrSystem).txt" -Append
					Write-Output "**These commands still need to be validated by hand, as all values cannot be added programmatically**" |
						Tee-Object ".\${TIMESTAMP}_provisioning-scripts\$($OBJ.SourceSystem)\$($OBJ.TargetSystem)-$($OBJ.TargetDrSystem).txt" -Append
					Write-Output "**Run a Find for the string 'N/A' and placeholders enclosed in <>**" |
						Tee-Object ".\${TIMESTAMP}_provisioning-scripts\$($OBJ.SourceSystem)\$($OBJ.TargetSystem)-$($OBJ.TargetDrSystem).txt" -Append
			}
			$CMDTYPES = $OUTPUT | Sort-Object -Property SourceSystem,TargetSystem,CommandType -Unique | Sort-Object -Property ExecutionOrder
			ForEach ($OBJ in $CMDTYPES) {
				Write-Output "$($OBJ.CommandHeading)" | Tee-Object ".\${TIMESTAMP}_provisioning-scripts\$($OBJ.SourceSystem)\$($OBJ.TargetSystem)-$($OBJ.TargetDrSystem).txt" -Append
				Write-Output "$($OBJ.Comments)" | Tee-Object ".\${TIMESTAMP}_provisioning-scripts\$($OBJ.SourceSystem)\$($OBJ.TargetSystem)-$($OBJ.TargetDrSystem).txt" -Append
				Write-Output "$CMDBLK" | Tee-Object ".\${TIMESTAMP}_provisioning-scripts\$($OBJ.SourceSystem)\$($OBJ.TargetSystem)-$($OBJ.TargetDrSystem).txt" -Append
				$ALLCMDS = $OUTPUT | Where-Object {$_.SourceSystem -eq "$($OBJ.SourceSystem)" -and $_.TargetSystem -eq "$($OBJ.TargetSystem)" -and $_.CommandType -eq "$($OBJ.CommandType)"}
				ForEach ($CMD in $ALLCMDS) {
					Write-Output "$($CMD.CommandString)" | Tee-Object ".\${TIMESTAMP}_provisioning-scripts\$($OBJ.SourceSystem)\$($CMD.TargetSystem)-$($OBJ.TargetDrSystem).txt" -Append
				}
				Write-Output "$CMDBLK" | Tee-Object ".\${TIMESTAMP}_provisioning-scripts\$($OBJ.SourceSystem)\$($OBJ.TargetSystem)-$($OBJ.TargetDrSystem).txt" -Append
				} 
			}
		CSV {
			$TIMESTAMP = $(Get-Date -Format yyyyMMddHHmmss)
			New-Item -Path .\ -Name ".\${TIMESTAMP}_provisioning-scripts" -ItemType directory | Out-Null
			$ALLSRCSYS = $OUTPUT | Sort-Object -Property SourceSystem -Unique
			ForEach ($SRCSYS in $ALLSRCSYS) {
				New-Item -Path .\ -Name ".\${TIMESTAMP}_provisioning-scripts\$($SRCSYS.SourceSystem)" -ItemType directory -Force | Out-Null
				$ALLCMDS = $OUTPUT | Where-Object {$_.SourceSystem -eq "$($SRCSYS.SourceSystem)"} 
				$ALLCMDS | Export-Csv -NoTypeInformation -Path ".\${TIMESTAMP}_provisioning-scripts\$($SRCSYS.SourceSystem)\$($SRCSYS.TargetSystem)-$($SRCSYS.TargetDrSystem).csv"
			}
		} 
		JSON {
			$TIMESTAMP = $(Get-Date -Format yyyyMMddHHmmss)
			New-Item -Path .\ -Name ".\${TIMESTAMP}_provisioning-scripts" -ItemType directory | Out-Null
			$ALLTGTSYS = $OUTPUT | Sort-Object -Property TargetSystem -Unique
			ForEach ($TGTSYS in $ALLTGTSYS) {
				New-Item -Path .\ -Name ".\${TIMESTAMP}_provisioning-scripts\$($TGTSYS.SourceSystem)" -ItemType directory -Force | Out-Null
				$ALLCMDS = $OUTPUT | Where-Object {$_.TargetSystem -eq "$($TGTSYS.TargetSystem)"} 
				$ALLCMDS | ConvertTo-Json | Out-File -FilePath ".\${TIMESTAMP}_provisioning-scripts\$($TGTSYS.SourceSystem)\$($TGTSYS.TargetSystem)-$($TGTSYS.TargetDrSystem).json"
			}
		}
		default {
			$OUTPUT
		}
	}
}
