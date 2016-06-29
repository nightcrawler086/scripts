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
	$INFILE = $IMPORT | Select-Object @{Name="SourceSystem";Expression={$_."Source Prod Box"}},@{Name="SecurityStyle";Expression={$_."Security Style"}}, `
	@{Name="SourceFilesystem";Expression={$_."Source Filesystem"}},@{Name="SourceCapacityGB";Expression={$_."Source Prod Capacity (GB)"}},`
	@{Name="TargetSystem";Expression={$_."Target Prod VNX Frame"}},@{Name="TargetDm";Expression={$_."Target Prod Physical Datamover"}}, `
	@{Name="TargetVdm";Expression={$_."Target Virtual DataMover"}},@{Name="TargetIp";Expression={$_."Prod IP"}}, `
	@{Name="TargetCifsServer";Expression={$_."Target CIFS Server Name"}},@{Name="TargetNfsServer";Expression={$_."Target NFS Server Name"}}, `
	@{Name="TargetStoragePool";Expression={$_."Target Prod Pool"}},@{Name="TargetDrSystem";Expression={$_."Target Cob VNX Frame"}}, `
	@{Name="TargetDrDm";Expression={$_."Target COB Physical Data Mover"}},@{Name="TargetDrIp";Expression={$_."Cob IP"}}, `
	@{Name="TargetDrFilesystem";Expression={$_."Target Cob File System"}},@{Name="TargetDrStoragePool";Expression={$_."Target Cob Pool"}}

	If ($SourceSystem -ne $NULL -and $SourceSystem -ne "") {
		$INFILE = $INFILE | Where-Object {$_.SourceSystem -eq "$SourceSystem"}
	}
	# This array will be our working set
	$OBJARRAY = @()
	# Let's try to validate all the objects
	$INDEX = 0
	$PROPS = (($INFILE | Get-Member) | Where-Object {$_.MemberType -eq "NoteProperty"} | Select-Object -Property Name).Name
	ForEach ($OBJ in $INFILE) {
		$INDEX++
		$VALID = $True
		ForEach ($PROP in $PROPS) {
			#If ($OBJ.$PROP -contains $NULL -or $OBJ.$PROP -match "N/A" -and $OBJ.$PROP -ne "TargetNfsServer" -or $OBJ.$PROP -ne "TargetCifsServer") {
			If ($OBJ.$PROP -contains $NULL -and $OBJ.$PROP -match "N/A" -and $OBJ.$PROP -ne "TargetNfsServer" -and $OBJ.$PROP -ne "TargetCifsServer") {
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
	# To do:
	#
	# All filtering needs to be revised
	# Create commands and append them to the $OUTPUT array
	# This SUBSET is sufficiently filtered for VDM Creation commands on the target production side
	
	#$SUBSET = $OBJARRAY | 
	#	Where-Object {($_.TargetSystem -notmatch "N/A" -and $_.TargetSystem -ne "") -and ($_.TargetVdm -notmatch "N/A" -and $_.TargetVdm -ne "") -and ($_.TargetStoragePool -ne "" -and $_.TargetStoragePool -notmatch "N/A")} | 
	#		Sort-Object -Property TargetVdm -Unique
	
	$OBJCOUNT = $OBJARRAY | Measure-Object | Select-Object -ExpandProperty Count
	$VALIDOBJ = $OBJARRAY | Where-Object {$_.IsValid -eq $True} | Measure-Object | Select-Object -ExpandProperty Count
	Write-Host "$VALIDOBJ of $OBJCOUNT objects are valid (no properties missing)..."
	Write-Host "This may affect the generated output, take special care to ensure"
	Write-Host "valid commands are generated.  If possible, fill in all properties"
	Write-Host "and run this script again."
	Write-Host "Hit CTRL+C to exit now, or this script will contine in a few seconds"
	Start-Sleep -s 7


	$SUBSET = $OBJARRAY | Sort-Object -Property TargetVdm -Unique
	ForEach ($OBJ in $SUBSET) {
			# Generate Prod VDM Creation Commands
			$CMDSTR = "nas_server -name $($OBJ.TargetVDM) -type vdm -create $($OBJ.TargetDM) -setstate loaded pool=$($OBJ.TargetStoragePool)"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdVdmCreate";
				CommandHeading = "`r`n## VDM Creations Commands (PROD)`r`n";
				CommandString = $CMDSTR;
				ExecutionOrder = "1"
			}
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
	#$SUBSET = $OBJARRAY | 
	#	Where-Object {$_.TargetDrSystem -notmatch "N/A" -or $_.TargetDrSystem -ne "" -and $_.TargetDrVdm -notmatch "N/A" -or $_.TargetDrVdm -ne ""} | 
	#		Sort-Object -Property TargetDrSystem,TargetDrVdm -Unique
	$SUBSET = $OBJARRAY | Sort-Object TargetVdm,TargetDrSystem -Unique
	ForEach ($OBJ in $SUBSET) {
			# Generate PROD VDM Replication Commands
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
	$SUBSET = $OBJARRAY | 
		Where-Object {$_.TargetSystem -notmatch "N/A" -or $_.TargetSystem -ne "" -and $_.TargetDrSystem -notmatch "N/A" -or $_.TargetDrSystem -ne ""} | 
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
	$SUBSET = $OBJARRAY | 
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
			CommandString = "$CMDSTR";
			ExecutionOrder = "2"
		}
	}
	$SUBSET = $OBJARRAY | 
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
	$SUBSET = $OBJARRAY | 
		Where-Object {$_.TargetCifsServer -ne "" -or $_.TargetCifsServer -notmatch "N/A" -and $_.TargetProtocol -eq "CIFS" -or $_.TargetProtocol -eq "BOTH"} | 
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
			CommandString = "$CMDSTR";
			ExecutionOrder = "7"
		}
		# Generate Prod Join CIFS Server Commands 
		$CMDSTR = "server_cifs $($OBJ.TargetCifsServer) -Join compname=$($OBJ.TargetCifsServer),domain=nam.nsroot.net,admin=<ADMIN_USER>,`"ou=Servers:ou=NAS:ou=INFRA`""
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
	$SUBSET = $OBJARRAY | 
		Where-Object {$_.TargetNfsServer -ne "" -or $_.TargetNfsSever -notmatch "N/A"} |
			Sort-Object -Property TargetNfsServer -Unique
	ForEach ($OBJ in $SUBSET) {
		If ($($OBJ.TargetNfsServer) -ne "" -or $($OBJ.TargetNfsServer) -notmatch "N/A") {
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
	$SUBSET = $OBJARRAY | 
		Where-Object {$_.TargetSystem -ne "" -or $_.TargetSystem -notmatch "N/A" -and $_.TargetVdm -ne "" -or $_.TargetVdm -notmatch "N/A"} | 
			Sort-Object -Property SourceFilesystem,TargetVdm -Unique
	ForEach ($OBJ in $SUBSET) {
		If ($($OBJ.SecurityStyle) -ne "" -or $($OBJ.SecurityStyle) -notmatch "N/A" -and $($OBJ.SourceCapacityGB) -ne "" -or $($OBJ.SourceCapacityGB) -notmatch "N/A" -and $($OBJ.TargetStroagePool) -ne "" -or $($OBJ.TargetStoragePool) -notmatch "N/A") {
			# Target Prod FS Create Commands
			$CMDSTR = "nas_fs -name $($OBJ.SourceFilesystem) -type $($OBJ.SecurityStyle) -create size=$($OBJ.SourceCapacityGB)GB pool=$($OBJ.TargetStoragePool) -option slice=y"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdFsCreate";
				CommandHeading = "`r`n## Filesystem Creation Commands (PROD)`r`n";
				CommandString = "$CMDSTR";
				ExecutionOrder = "4"
			}
		}
		# Target Prod FS Dedupe Commands
		$CMDSTR = "fs_dedupe -modify $($OBJ.SourceFilesystem) -state on"
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
		$CMDSTR = "nas_ckpt_schedule -create $($OBJ.SourceFilesystem)_DAILY_SCHED -filesystem $($OBJ.SourceFilesystem) -description ""1730hrs daily checkpoint schedule for $($OBJ.SourceFilesystem)"" -recurrence daily -every 1 -start_on <DATE> -runtimes 17:30 -keep 7"
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
			$CMDSTR = "mkdir /nasmcd/quota/slot_$DMNUM/root_vdm_<VDM_NUM>/$($OBJ.SourceFilesystem)/$($OBJ.SourceFilesystem)"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdFsQtree";
				CommandString = "$CMDSTR"
				CommandHeading = "`r`n## Filesystem Qtree Commands (PROD)`r`n";
			} 
		} Else {
			$CMDSTR = "mkdir /nasmcd/quota/slot_<DM_NUM>/root_vdm_<VDM_NUM>/$($OBJ.SourceFilesystem)/$($OBJ.SourceFilesystem))"
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
		$CMDSTR = "server_mount $($OBJ.TargetVDM) $($OBJ.SourceFilesystem) /$($OBJ.SourceFilesystem)"
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
			$CMDSTR = "server_export $($OBJ.TargetVDM) -Protocol cifs -name $($OBJ.SourceFilesystem) -o netbios=$($OBJ.TargetVDM) /$($OBJ.SourceFilesystem)/$($OBJ.SourceFilesystem)"
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
			$CMDSTR = "server_export $($OBJ.TargetVDM) -Protocol nfs -name $($OBJ.SourceFilesystem) -o rw=<CLIENTS>,ro=<CLIENTS>,root=<CLIENTS> /$($OBJ.SourceFilesystem)/$($OBJ.SourceFilesystem)"
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
		If ($($OBJ.TargetDrFilesystem) -ne "" -and $($OBJ.TargetDrFilesystem) -notmatch "N/A") {
			$CMDSTR = "nas_replicate -create $($OBJ.SourceFilesystem)_REP -source -fs $($OBJ.SourceFilesystem) -destination -fs $($OBJ.TargetDrFilesystem) -interconnect <INTERCONNECT_NAME> -max_time_out_of_sync 10 -background"
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
	$SUBSET = $OBJARRAY | Where-Object {$_.TargetDrSystem -ne "" -and $_.TargetDrSystem -notmatch "N/A" -and $_.TargetDrFilesystem -ne "" -and $_.TargetDrFilesystem -notmatch "N/A"}
	ForEach ($OBJ in $SUBSET) {
		# Cob (DR) FS Creation Commands
		$CMDSTR = "nas_fs -name $($OBJ.TargetDrFilesystem) -create samesize:$($OBJ.SourceFilesystem):cel:$($OBJ.TargetDrSystem) pool:$($OBJ.TargetDrStoragePool)" 
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
		$CMDSTR = "nas_ckpt_schedule -create $($OBJ.TargetDrFilesystem)`_DAILY_SCHED -filesystem $($OBJ.TargetDrFilesystem) -description ""1730hrs daily checkpoint schedule for $($OBJ.TargetDrFilesystem)"" -recurrence daily -every 1 -start_on <DATE> -runtimes 17:30 -keep 7"
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
				Sort-Object -Property SourceSystem,TargetSystem,CommandType -Unique | 
					Sort-Object -Property CommandType -Descending
			ForEach ($OBJ in $CMDTYPES) {
				Write-Output "$($OBJ.CommandHeading)" |
					Tee-Object ".\${TIMESTAMP}_provisioning-scripts\$($OBJ.SourceSystem)\${TIMESTAMP}_$($OBJ.SourceSystem)_$($OBJ.TargetSystem)-script.txt" -Append
				#Write-Output "$($OBJ.Comments)" | Tee-Object "${TIMESTAMP}_$($OBJ.SourceSystem)_$($OBJ.TargetSystem)-script.txt" -Append
				Write-Output "$CMDBLK" |
					Tee-Object ".\${TIMESTAMP}_provisioning-scripts\$($OBJ.SourceSystem)\${TIMESTAMP}_$($OBJ.SourceSystem)_$($OBJ.TargetSystem)-script.txt" -Append
				$ALLCMDS = $OUTPUT |
					Where-Object {$_.SourceSystem -eq "$($OBJ.SourceSystem)" -and $_.TargetSystem -eq "$($OBJ.TargetSystem)" -and $_.CommandType -eq "$($OBJ.CommandType)"}
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
			$ALLTGTSYS = $OUTPUT | Sort-Object -Property TargetSystem -Unique
			ForEach ($TGTSYS in $ALLTGTSYS) {
				New-Item -Path .\ -Name ".\${TIMESTAMP}_provisioning-scripts\$($TGTSYS.SourceSystem)" -ItemType directory -Force | Out-Null
				$ALLCMDS = $OUTPUT | Where-Object {$_.TargetSystem -eq "$($TGTSYS.TargetSystem)"} 
				$ALLCMDS | Export-Csv -NoTypeInformation -Path ".\${TIMESTAMP}_provisioning-scripts\$($TGTSYS.SourceSystem)\${TIMESTAMP}_$($TGTSYS.SourceSystem)_$($TGTSYS.TargetSystem).csv"
			}
		} 
		JSON {
			$TIMESTAMP = $(Get-Date -Format yyyyMMddHHmmss)
			New-Item -Path .\ -Name ".\${TIMESTAMP}_provisioning-scripts" -ItemType directory | Out-Null
			$ALLTGTSYS = $OUTPUT | Sort-Object -Property TargetSystem -Unique
			ForEach ($TGTSYS in $ALLTGTSYS) {
				New-Item -Path .\ -Name ".\${TIMESTAMP}_provisioning-scripts\$($TGTSYS.SourceSystem)" -ItemType directory -Force | Out-Null
				$ALLCMDS = $OUTPUT | Where-Object {$_.TargetSystem -eq "$($TGTSYS.TargetSystem)"} 
				$ALLCMDS | ConvertTo-Json | Out-File -FilePath ".\${TIMESTAMP}_provisioning-scripts\$($TGTSYS.SourceSystem)\${TIMESTAMP}_$($TGTSYS.SourceSystem)_$($TGTSYS.TargetSystem).json"
			}
		}
		default {
			$OUTPUT
		}
	}
}
