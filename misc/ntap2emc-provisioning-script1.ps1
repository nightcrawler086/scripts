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
		Write-Host "No output format specified..."
		Write-Host "All output will be written to the console unless"
		Write-Host "you specify and format (txt/csv/json)"
		Write-Host "Enter a format, or none to send all output to the console"
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
		@{Name='SourceVfiler';Expression={$_.'PROD Vfiler'}},
		@{Name='SourceVolume';Expression={$_.'PROD Volume'}},
		@{Name='SourceAggregate';Expression={$_.'Aggregate Name'}},
		@{Name='SourceUsedCapacityGB';Expression={$_.'Volume Total Capacity (GB)'}},
		@{Name='SourceCapacityGB';Expression={$_.'Volume Total Capacity (GB)'}},
		@{Name='SourceUsedCapacityPercent';Expression={$_.'Volume Used %'}},
		@{Name='AccessType';Expression={$_.'Access Type'}},
		@{Name='SecurityStyle';Expression={$_.'Volume Security'}},
		@{Name='SourceDrLocation';Expression={$_.'COB Location'}},
		@{Name='SourceDrSystem';Expression={$_.'COB Filer'}},
		@{Name='SourceDrVfiler';Expression={$_.'COB Vfiler'}},
		@{Name='SourceDrVolume';Expression={$_.'COB Volume'}},
		@{Name='TechRefresh';Expression={$_.'Tech Refresh'}},
		@{Name='TargetSystem';Expression={$_.'Target Prod VNX Frame'}},
		@{Name='TargetDm';Expression={$_.'Prod Physical DataMover'}},
		@{Name='TargetVdm';Expression={$_.'VDM'}},
		@{Name='TargetVdmRootDir';Expression={$_.'Root VDM Directory'}},
		@{Name='TargetQipEntry';Expression={$_.'Prod QIP Entry'}},
		@{Name='TargetIp';Expression={$_.'IP Address'}},
		@{Name='TargetInterface';Expression={$_.'Interface Name'}},
		@{Name='TargetCifsServer';Expression={$_.'Cifs server Name'}},
		@{Name='TargetNfsServer';Expression={$_.'nfs server Name'}},
		@{Name='3dnsCname';Expression={$_.'3 DNS cname entry'}},
		@{Name='TargetVolume';Expression={$_.'Prod File System'}},
		@{Name='TargetQtree';Expression={$_.'Qtree&share name'}},
		@{Name='TargetStoragePool';Expression={$_.'Prod Pool'}},
		@{Name='LdapSetup';Expression={$_.'Ldap setup'}},
		@{Name='TargetDrSystem';Expression={$_.'COB VNX'}},
		@{Name='TargetDrVdm';Expression={$_.'COB VDM'}},
		@{Name='TargetDrIp';Expression={$_.'Cob IP Address'}}
	# This just slices the import file with only the source system
	# specified when the script was executed
	If ($SourceSystem -notcontains $NULL) {
		$INFILE = $INFILE | Where-Object {$_.SourceSystem -eq "$SourceSystem"}
	}
	# This array will be our working set
	$OBJARRAY = @()
	# Let's try to validate the properties of our import file
	# This is a very simple validation, looking for empty properties
	$INDEX = 0
	$PROPS = (($INFILE | Get-Member) | Where-Object {$_.MemberType -eq "NoteProperty"} | Select-Object -Property Name).Name
	ForEach ($OBJ in $INFILE) {
		$INDEX++
		$VALID = $True
		ForEach ($PROP in $PROPS) {
			#If ($OBJ.$PROP -contains $NULL -or $OBJ.$PROP -match "N/A" -and $OBJ.$PROP -ne "TargetNfsServer" -or $OBJ.$PROP -ne "TargetCifsServer") {
			If ($OBJ.$PROP -contains $NULL) {
				$VALID = $False
			}
		}
		$OBJ | Add-Member -Name IsValid -MemberType NoteProperty -Value $VALID	
		$OBJARRAY += $OBJ
	}
	# Define Output Array
	$OUTPUT = @()


}
PROCESS {
	$OBJCOUNT = $OBJARRAY | Measure-Object | Select-Object -ExpandProperty Count
	$VALIDOBJ = $OBJARRAY | Where-Object {$_.IsValid -eq $True} | Measure-Object | Select-Object -ExpandProperty Count
	Write-Host -ForegroundColor Yellow "$VALIDOBJ of $OBJCOUNT objects have empty properties"
	Write-Host -ForegroundColor Yellow "This may or may not be expected..."
	
	# Begin fill custom object with our configuration commands
	$SLICE = $OBJARRAY | Sort-Object -Property TargetVdm -Unique
	ForEach ($OBJ in $SLICE) {
		# Target VDM Creation Commands
		$CMDSTR = "nas_server -name $($OBJ.TargetVDM) -type vdm -create $($OBJ.TargetDM) -setstate loaded pool=$($OBJ.TargetStoragePool)"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdVdmCreate";
			CommandHeading = "`r`n## VDM Creations Commands $($OBJ.TargetSystem)`r`n";
			CommandString = $CMDSTR;
			ExecutionOrder = "01"
		}
	}
	$SLICE = $OBJARRAY | Sort-Object -Property TargetVdm,TargetIp -Unique
	ForEach ($OBJ in $SLICE) {
		$TGTLOC = $($OBJ.ProdLocation)
		$TGTLOCSUB = $TGTLOC.Substring(0,3)
		$TGTSYS = $($OBJ.TargetSystem)
		$TGTFRAME = $TGTSYS.Substring(0,$TGTSYS.Length-1)
		$TGTFRAMENUM = $TGTFRAME.Substring(10,4)
		$TGTDM = $($OBJ.TargetDm)
		$TGTDMNUM = $TGTDM.Substring(7)
		$CMDSTR = "server_ifconfig $($OBJ.TargetDm) -create -Device fsn0 -name ${TGTLOCSUB}${TGTFRAMENUM}DM${TGTDMNUM}C01"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdIntCreate";
			CommandHeading = "`r`n## Create Interface Commands $($OBJ.TargetSystem)`r`n";
			CommandString = "$CMDSTR"
			ExecutionOrder = "02";
			Comments = "`r`n**The interface name should be in ALL CAPS, if not correct it before running the command**`r`n"
		}
		# Generate Prod VDM Int Attach Commands
		$CMDSTR = "nas_server -vdm $($OBJ.TargetVDM) -attach ${TGTLOCSUB}${TGTFRAMENUM}DM${TGTDMNUM}C01"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdVdmAttachInt";
			CommandHeading = "`r`n## VDM Attach Interface Commands $($OBJ.TargetSystem)`r`n";
			CommandString = "$CMDSTR";
			ExecutionOrder = "03";
			Comments = "`r`n**Double-check the interface name for accuracy**`r`n"
		}
	}
	$SLICE = $OBJARRAY | Sort-Object TargetSystem,TargetDrSystem -Unique
	ForEach ($OBJ in $SLICE) {
		# Create Replication Passphrase on Source System
		$CMDSTR = "nas_cel -create $($OBJ.TargetDrSystem) -ip <COB_CS_IP> -passphrase nasadmin"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdRepPass";
			CommandHeading = "`r`n## Create Replication Passphrase Commands $($OBJ.TargetSystem)`r`n";
			CommandString = "$CMDSTR"
			ExecutionOrder = "04";
			Comments = "`r`n**Replace the <COB_CS_IP> with the Control Station IP from the COB system**`r`n"
		}
		# Create Replication Passphrase on Destination System
		$CMDSTR = "nas_cel -create $($OBJ.TargetSystem) -ip <PRD_CS_IP> -passphrase nasadmin"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "drRepPass";
			CommandHeading = "`r`n## Create Replication Passphrase Commands $($OBJ.TargetDrSystem)`r`n";
			CommandString = "$CMDSTR"
			ExecutionOrder = "05";
			Comments = "`r`n**Replace the <PRD_CS_IP> with the Control Station IP from the PROD system**`r`n"
		}
		# Create Replication Interconnect on Prod System
		$CMDSTR = "nas_cel -interconnect -create <TGT_DM#-COB_DM#> -source_server $($OBJ.TargetDm) -destination_system $($OBJ.TargetDrSystem) -destination_server <COB_DM> -source_interfaces ip=<TGT_REP_IP> -destination_interfaces ip=<COB_REP_IP>"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdCreateInterconnect";
			CommandHeading = "`r`n## Create Datamover Interconnection Commands $($OBJ.TargetSystem)`r`n";
			CommandString = "$CMDSTR"
			ExecutionOrder = "06";
			Comments = "`r`n**Replace all values in <> with their proper values**`r`n"
		}
		# Create Replication Interconnect on Cob(DR) System
		$CMDSTR = "nas_cel -interconnect -create <COB_DM#-TGT_DM#> -source_server <COB_DM> -destination_system $($OBJ.TargetSystem) -destination_server $($OBJ.TargetDm) -source_interfaces ip=<COB_REP_IP> -destination_interfaces ip=<TGT_REP_INT>"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "drCreateInterconnect";
			CommandHeading = "`r`n## Create Datamover Interconnection Commands $($OBJ.TargetDrSystem)`r`n";
			CommandString = "$CMDSTR"
			ExecutionOrder = "07";
			Comments = "`r`n**Replace all values in <> with their proper values**`r`n"
		}
		# Generate PROD VDM Replication Commands
		$CMDSTR = "nas_replicate -create $($OBJ.TargetVDM)_REP -source -vdm $($OBJ.TargetVDM) -destination -pool id=<COB_POOL_ID> -interconnect <INTERCONNECT_NAME> -max_time_out_of_sync 10 -background"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdVdmRep";
			CommandHeading = "`r`n## VDM Replication Commands $($OBJ.TargetSystem)`r`n";
			CommandString = "$CMDSTR";
			ExecutionOrder = "08";
			Comments = "`r`n**Replace the all values in <> with their proper values**`r`n"
		}
		# Generate Cob(DR) Interface Configuration Commands
		$CMDSTR = "server_ifconfig <COB_DM> -create -Device fsn0 -name <COB_INT_NAME> -protocol IP $($OBJ.TargetDrIp) <MASK> <BROADCAST>" 		
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "drIntCreate";
			CommandHeading = "`r`n## Create Interface Commands $($OBJ.TargetDrSystem)`r`n";
			CommandString = "$CMDSTR";
			ExecutionOrder = "09";
			Comments = "`r`n**Replace all values in <>.  The MASK and BROADCAST can be found from the similar interface on the system**`r`n"
		}
	}
	$SLICE = $OBJARRAY | Sort-Object -Property TargetVdm,TargetVolume -Unique
	ForEach ($OBJ in $SLICE) {
		# Target Filesystem Creation Commands
		# Need to detect floating points and round up.
		$CMDSTR = "nas_fs -name $($OBJ.TargetVolume) -type uxfs -create size=$($OBJ.SourceCapacityGB)GB pool=$($OBJ.TargetStoragePool) -option slice=y"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdFsCreate";
			CommandHeading = "`r`n## Filesystem Creation Commands for $($OBJ.TargetSystem)`r`n";
			CommandString = "$CMDSTR";
			ExecutionOrder = "10";
			Comments = "`r`n**If replicating from VNX, use the 'DR' style volume creation command**`r`n"
		}
		# FS Mount Commands
		$CMDSTR = "server_mount $($OBJ.TargetVDM) $($OBJ.TargetVolume) /$($OBJ.TargetVolume)"
        $OUTPUT += New-Object -TypeName PSObject -Property @{
	        SourceSystem = $OBJ.SourceSystem;
		    TargetSystem = $OBJ.TargetSystem;
		    TargetDrSystem = $OBJ.TargetDrSystem;
		    CommandType = "prdFsMnt";
		    CommandHeading = "`r`n## Filesystem Mount Commands $($OBJ.TargetSystem)`r`n";
		    CommandString = "$CMDSTR";
			ExecutionOrder = "11"
        }
		# FS Qtree Commands
		$DMNUM = ($($OBJ.TargetDm)).Substring(7)
		$CMDSTR = "mkdir /nasmcd/quota/slot_$DMNUM/root_vdm_<VDM_NUM>/$($OBJ.TargetVolume)/$($OBJ.TargetQtree)"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdFsQtree";
			CommandString = "$CMDSTR"
			CommandHeading = "`r`n## Filesystem Qtree Commands $($OBJ.TargetSystem)`r`n";
			ExecutionOrder = "16";
			Comments = "`r`n**These commands need to be run as root**`r`n"
		} 
		# FS Export Commands
		$CMDSTR = "server_export $($OBJ.TargetVDM) -Protocol cifs -name $($OBJ.TargetQtree) -o netbios=$($OBJ.TargetVDM) /$($OBJ.TargetVolume)/$($OBJ.TargetQtree)"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdCifsExport";
			CommandHeading = "`r`n## CIFS Export Commands $($OBJ.TargetSystem)`r`n";
			CommandString = "$CMDSTR";
			ExecutionOrder = "17"
		}
		# Cob (DR) FS Creation Commands
		$CMDSTR = "nas_fs -name $($OBJ.TargetVolume) -create samesize=$($OBJ.TargetVolume):cel=$($OBJ.TargetSystem) pool=<COB_POOL>" 
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "drFsCreate";
			CommandHeading = "`r`n## Filesystem Creation Commands $($OBJ.TargetDrSystem)`r`n";
			CommandString = "$CMDSTR";
			ExecutionOrder = "15";
			Comments = "`r`n**Replace the <COB_POOL> with the name of the storage pool on the COB VNX**`r`n"
		}
		$CMDSTR = "server_mount $($OBJ.TargetVDM) -o ro $($OBJ.TargetVolume) /$($OBJ.TargetVolume)"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "drFsMnt";
			CommandHeading = "`r`n## Filesystem Mount Commands $($OBJ.TargetDrSystem)`r`n";
			CommandString = "$CMDSTR";
			ExecutionOrder = "18";
			Comments = "`r`n**Must mount FS as read-only for replication commands to work**`r`n"
		}
		$CMDSTR = "nas_replicate -create $($OBJ.TargetVolume)_REP -source -fs $($OBJ.TargetVolume) -destination -fs $($OBJ.TargetVolume) -interconnect <INTERCONNECT_NAME> -max_time_out_of_sync 10 -background"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdFsRep";
			CommandHeading = "`r`n## Filesystem Replication Commands $($OBJ.TargetSystem)`r`n";
			CommandString = "$CMDSTR";
			ExecutionOrder = "19";
			Comments = "`r`n**Replace <INTERCONNECT_NAME> with the name of the datamover interconnect**`r`n"
		}
		$CMDSTR = "fs_dedupe -modify $($OBJ.TargetVolume) -state on"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdFsDedupe";
			CommandHeading = "`r`n## Filesystem Deduplication Commands $($OBJ.TargetSystem)`r`n";
			CommandString = "$CMDSTR";
			ExecutionOrder = "20"
			Comments = "`r`n**Only run dedupe commands if dedupe is enabled on the source**`r`n"
		}
		$CMDSTR = "nas_ckpt_schedule -create $($OBJ.TargetVolume)_DAILY_SCHED -filesystem $($OBJ.TargetVolume) -description ""1730hrs daily checkpoint schedule for $($OBJ.TargetVolume)"" -recurrence daily -every 1 -start_on <DATE> -runtimes 17:30 -keep 7"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdFsCkpt";
			CommandHeading = "`r`n## Filesystem Checkpoint Commands $($OBJ.TargetSystem)`r`n";
			CommandString = "$CMDSTR";
			ExecutionOrder = "21";
			Comments = "`r`n**Only run these commands after initial base copy has been completed**`r`n**Replace the <DATE> with the date which the command is executed**`n"
		}
		$CMDSTR = "nas_ckpt_schedule -create $($OBJ.TargetVolume)`_DAILY_SCHED -filesystem $($OBJ.TargetVolume) -description ""1710hrs daily checkpoint schedule for $($OBJ.TargetVolume)"" -recurrence daily -every 1 -start_on <DATE> -runtimes 17:10 -keep 7"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "drFsCkpt";
			CommandHeading = "`r`n## Filesystem Checkpoint Commands $($OBJ.TargetDrSystem)`r`n";
			CommandString = "$CMDSTR";
			ExecutionOrder = "22";
			Comments = "`r`n**Only run these commands after tgt->cob replication has been completed**`r`n**Replace the <DATE> with the date which the command is executed**`n"
		}
		$CMDSTR = "emcopy64.exe \\$($OBJ.SourceVfiler)\$($OBJ.SourceVolume) \\$($OBJ.TargetVdm)\$($OBJ.TargetQtree) /s /sdd /d /o /a /secfix /i /lg /purge /r:0 /w:0 /c /log:D:\emcopy-log\$($OBJ.SourceVolume).txt"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "emcopyInc";
			CommandHeading = "`r`n## Incremental emcopy.exe Commands`r`n";
			CommandString = "$CMDSTR";
			ExecutionOrder = "23"
		}
		$CMDSTR = "emcopy64.exe \\$($OBJ.SourceVfiler)\$($OBJ.SourceVolume) \\$($OBJ.TargetVdm)\$($OBJ.TargetQtree) /s /sdd /d /o /a /i /lg /purge /r:0 /w:0 /c /log:D:\emcopy-log\$($OBJ.SourceVolume)-final.txt"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "emcopyFin";
			CommandHeading = "`r`n## Final emcopy.exe Commands`r`n";
			CommandString = "$CMDSTR";
			ExecutionOrder = "24"
		}
	}
	$SLICE = $OBJARRAY | Sort-Object TargetVdm -Unique
	ForEach ($OBJ in $SLICE) {
		# Generate Prod Create CIFS Server Commands
		$CMDSTR = "server_cifs $($OBJ.TargetCifsServer) -add compname=$($OBJ.TargetCifsServer),domain=nam.nsroot.net,interface=<INT_NAME>,local_users"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdCifsCreate";
			CommandHeading = "`r`n## Create CIFS Server Commands $($OBJ.TargetSystem)`r`n";
			CommandString = "$CMDSTR";
			ExecutionOrder = "13";
			Comments = "`r`n**Replace <INT_NAME> with the interface name**`r`n"
		}
		$CMDSTR = "server_cifs $($OBJ.TargetCifsServer) -Join compname=$($OBJ.TargetCifsServer),domain=nam.nsroot.net,admin=<ADMIN_USER>,ou=`"ou=Servers:ou=NAS:ou=INFRA`""
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdCifsJoin";
			CommandHeading = "`r`n## Join CIFS Server Commands $($OBJ.TargetSystem)`r`n";
			CommandString = "$CMDSTR";
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
			$ALLTGTSYS = $OUTPUT | Sort-Object -Property TargetSystem -Unique
			ForEach ($TGTSYS in $ALLTGTSYS) {
				New-Item -Path .\ -Name ".\${TIMESTAMP}_provisioning-scripts\$($TGTSYS.SourceSystem)" -ItemType directory -Force | Out-Null
				$ALLCMDS = $OUTPUT | Where-Object {$_.TargetSystem -eq "$($TGTSYS.TargetSystem)"} 
				$ALLCMDS | Export-Csv -NoTypeInformation -Path ".\${TIMESTAMP}_provisioning-scripts\$($TGTSYS.SourceSystem)\$($TGTSYS.TargetSystem)-$($TGTSYS.TargetDrSystem).csv"
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
