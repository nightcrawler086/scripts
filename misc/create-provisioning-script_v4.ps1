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
# Don't think I'll need this anymore...
<#		
	If ($SourceSystem -ne $NULL) {
		$OBJARRAY = Import-Csv -Path $InputFile | Where-Object {$_.SourceSystem -eq "$SourceSystem"}
	} ElseIf ($SourceSystem -eq $NULL) {
		Write-Host "No source system specified..."
		Write-Host "Do you want to get all commands for all systems?"
		$RESPONSE = Read-Host '(Y/y/N/n)?'
		If ($RESPONSE -eq "Y") {
			$OBJARRAY = Import-Csv -Path $InputFile
		}
	} Else {
			Write-Host "Nothing to do..."
			Exit 1
	}
#>

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
				} ElseIf (($PSVersionTable.PSVersion.Major) -le 4){
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
		$INFILE = $IMPORT | Select-Object @{Name="SourceSystem";Expression={$_."Source Prod Box"}},@{Name="SecurityStyle";Expression={$_."Security Style"}},@{Name="SourceFilesystem";Expression={$_."Source Filesystem"}},@{Name="SourceCapacityGB";Expression={$_."Source Prod Capacity (GB)"}},@{Name="TargetSystem";Expression={$_."Target Prod VNX Frame"}},@{Name="TargetDm";Expression={$_."Target Prod Physical Datamover"}},@{Name="TargetVdm";Expression={$_."Target Virtual DataMover"}},@{Name="TargetIp";Expression={$_."Prod IP"}},@{Name="TargetCifsServer";Expression={$_."Target CIFS Server Name"}},@{Name="TargetNfsServer";Expression={$_."Target NFS Server Name"}},@{Name="TargetStoragePool";Expression={$_."Target Prod Pool"}},@{Name="TargetDrSystem";Expression={$_."Target Cob VNX Frame"}},@{Name="TargetDrDm";Expression={$_."Target COB Physical Data Mover"}},@{Name="TargetDrIp";Expression={$_."Cob IP"}},@{Name="TargetDrFileSystem";Expression={$_."Target Cob File System"}},@{Name="TargetDrStoragePool";Expression={$_."Target Cob Pool"}}

	If ($SourceSystem -ne $NULL) {
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
			If ($OBJ.$PROP -contains $NULL -or $OBJ.$PROP -match "N/A" -and $OBJ.$PROP -ne "TargetNfsServer" -or $OBJ.$PROP -ne "TargetCifsServer") {
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
	Write-Host "Hit <CTRL>+C to exit now, or this script will contine in a few seconds"
	Start-Sleep -s 7


	$SUBSET = $OBJARRAY | Sort-Object -Property TargetVdm -Unique
	ForEach ($OBJ in $SUBSET) {
			If ($($OBJ.IsValid) -eq $True) {
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
		}
	#$SUBSET = $OBJARRAY | 
	#	Where-Object {$_.TargetDrSystem -notmatch "N/A" -or $_.TargetDrSystem -ne "" -and $_.TargetDrVdm -notmatch "N/A" -or $_.TargetDrVdm -ne ""} | 
	#		Sort-Object -Property TargetDrSystem,TargetDrVdm -Unique
	$SUBSET = $OBJARRAY | Sort-Object TargetVdm,TargetDrSystem
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
			CommandString = "$CMDSTR"
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
			Sort-Object -Property TargetFilesystem,TargetVdm -Unique
	ForEach ($OBJ in $SUBSET) {
		# If no TargetFilesystem property exists, use the SourceFilesystem property
		If (!(Get-Member -InputObject $OBJ -Name TargetFilesystem -MemberType NoteProperty)) {
			$TargetFileSystem = $($OBJ.SourceFilesystem)
		}
		If (!(Get-Member -InputObject $OBJ -Name TargetQtree -MemberType NoteProperty)) {
			$TargetQtree = $($OBJ.SourceFilesystem)
		}
		If (!(Get-Member -InputObject $OBJ -Name TargetSecurityStyle -MemberType NoteProperty)) {
			$TargetSecurityStyle = $($OBJ.SourceSecurityStyle)
		}
		If ($($OBJ.TargetSecurityStyle) -ne "" -or $($OBJ.TargetSecurityStyle) -notmatch "N/A" -and $($OBJ.TargetCapacityGB) -ne "" -or $($OBJ.TargetCapacityGB) -notmatch "N/A" -and $($OBJ.TargetStroagePool) -ne "" -or $($OBJ.TargetStoragePool) -notmatch "N/A") {
			$CMDSTR = "nas_fs -name $TargetFilesystem -type $TargetSecurityStyle -create size=$($OBJ.TargetCapacityGB)GB pool=$($OBJ.TargetStoragePool) -option slice=y"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdFsCreate";
				CommandHeading = "`r`n## Filesystem Creation Commands (PROD)`r`n";
				CommandString = "$CMDSTR"
			}
		}
		# Target Prod FS Dedupe Commands
		$CMDSTR = "fs_dedupe -modify $TargetFilesystem -state on"
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
		$CMDSTR = "nas_ckpt_schedule -create $TargetFilesystem_DAILY_SCHED -filesystem $TargetFilesystem -description ""1730hrs daily checkpoint schedule for $TargetFilesystem"" -recurrence daily -every 1 -start_on <DATE> -runtimes 17:30 -keep 7"
		$OUTPUT += New-Object -TypeName PSObject -Property @{
			SourceSystem = $OBJ.SourceSystem;
			TargetSystem = $OBJ.TargetSystem;
			TargetDrSystem = $OBJ.TargetDrSystem;
			CommandType = "prdFsCkpt";
			CommandHeading = "`r`n## Filesystem Checkpoint Commands (PROD)`r`n";
			CommandString = "$CMDSTR"
		}
		# ***** Left off here *****
		# Need to revise filtering in $SUBSET definition
		# Should be $OBJARRAY | Where <something> | sort -property <props> -Unique
		# Qtree commands
		If ($($OBJ.TargetDm) -match "server_[0-9]$") {
			$TGTDM = $($OBJ.TargetDm)
			$DMNUM = $TGTDM.Substring(7)
			$CMDSTR = "mkdir /nasmcd/quota/slot_$DMNUM/root_vdm_<VDM_NUM>/$TargetFilesystem/$TargetQtree"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdFsQtree";
				CommandString = "$CMDSTR"
				CommandHeading = "`r`n## Filesystem Qtree Commands (PROD)`r`n";
			} 
		} Else {
			$CMDSTR = "mkdir /nasmcd/quota/slot_<DM_NUM>/root_vdm_<VDM_NUM>/$TargetFilesystem/$TargetQtree)"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdFsQtree";
				CommandHeading = "`r`n## Filesystem Qtree Commands (PROD)`r`n";
				CommandString = "$CMDSTR";
				Comments = "Could not find valid Qtree name...using TargetFilesystem as Qtree name"
			}
		} 
		# FS Mount Commands
		$CMDSTR = "server_mount $($OBJ.TargetVDM) $TargetFilesystem /$TargetFilesystem"
        $OUTPUT += New-Object -TypeName PSObject -Property @{
	        SourceSystem = $OBJ.SourceSystem;
		    TargetSystem = $OBJ.TargetSystem;
		    TargetDrSystem = $OBJ.TargetDrSystem;
		    CommandType = "prdFsMnt";
		    CommandHeading = "`r`n## Filesystem Mount Commands (PROD)`r`n";
		    CommandString = "$CMDSTR"
        }
		# FS Export Commands
		If ($($OBJ.TargetProtocol) -eq "CIFS" -or $($OBJ.TargetProtocol) -eq "BOTH") {
			$CMDSTR = "server_export $($OBJ.TargetVDM) -Protocol cifs -name $TargetFilesystem -o netbios=$($OBJ.TargetVDM) /$TargetFilesystem/$TargetFilesystem"
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
			$CMDSTR = "server_export $($OBJ.TargetVDM) -Protocol nfs -name $TargetFilesystem -o rw=<CLIENTS>,ro=<CLIENTS>,root=<CLIENTS> /$TargetFilesystem/$TargetQtree"
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
		If (!(Get-Member -InputObject $OBJ -Name TargetDrFilesystem -MemberType NoteProperty)) {
			$TargetDrFilesystem = $($OBJ.SourceFilesystem)
		}
		If ($($OBJ.TargetDrFilesystem) -ne "" -or $($OBJ.TargetDrFilesystem) -notmatch "N/A") {
			$CMDSTR = "nas_replicate -create $TargetFilesystem_REP -source -fs $TargetFilesystem -destination -fs $TargetDrFilesystem -interconnect <INTERCONNECT_NAME> -max_time_out_of_sync 10 -background"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "prdFsRep";
				CommandHeading = "`r`n## Filesystem Replication Commands (PROD)`r`n";
				CommandString = "$CMDSTR"
			}
			# Cob (DR) FS Creation Commands
			$CMDSTR = "nas_fs -name $TargetDrFilesystem -create samesize:$TargetFilesystem:cel:$($OBJ.TargetDrSystem) pool:$($OBJ.TargetDrStoragePool)" 
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "drFsCreate";
				CommandHeading = "`r`n## Filesystem Creation Commands (DR)`r`n";
				CommandString = "$CMDSTR"
			}
			# Cob (DR) Mount Commands
			$CMDSTR = "server_mount $($OBJ.TargetVDM) -o ro $TargetDrFilesystem /$TargetDrFilesystem"
			$OUTPUT += New-Object -TypeName PSObject -Property @{
				SourceSystem = $OBJ.SourceSystem;
				TargetSystem = $OBJ.TargetSystem;
				TargetDrSystem = $OBJ.TargetDrSystem;
				CommandType = "drFsMnt";
				CommandHeading = "`r`n## Filesystem Mount Commands (DR)`r`n";
				CommandString = "$CMDSTR"
			}
			# Cob (DR) Checkpoint Commands
			$CMDSTR = "nas_ckpt_schedule -create $TargetDrFilesystem`_DAILY_SCHED -filesystem $TargetDrFilesystem -description ""1730hrs daily checkpoint schedule for $TargetDrFilesystem"" -recurrence daily -every 1 -start_on <DATE> -runtimes 17:30 -keep 7"
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

	switch ($OutFormat) {
		TXT {	
			$TIMESTAMP = $(Get-Date -Format yyyyMMddHHmmss)
			$SYSTEMS = $OUTPUT | Select-Object -Property SourceSystem,TargetSystem -Unique
			$CMDBLK = "``````"
			ForEach ($OBJ in $SYSTEMS) {
				If ($($OBJ.SourceSystem) -ne "" -and $($OBJ.TargetSystem) -ne "") {
					Write-Output "# Provisioning Script for $($OBJ.TargetSystem)`r`n" | Tee-Object "${TIMESTAMP}_$($OBJ.SourceSystem)_$($OBJ.TargetSystem)-script.txt"
				}
			}
			$CMDTYPES = $OUTPUT | 
				Sort-Object -Property SourceSystem,TargetSystem,CommandType -Unique | 
					Sort-Object -Property CommandType -Descending
			ForEach ($OBJ in $CMDTYPES) {
				Write-Output "$($OBJ.CommandHeading)" | Tee-Object "${TIMESTAMP}_$($OBJ.SourceSystem)_$($OBJ.TargetSystem)-script.txt" -Append
				#Write-Output "$($OBJ.Comments)" | Tee-Object "${TIMESTAMP}_$($OBJ.SourceSystem)_$($OBJ.TargetSystem)-script.txt" -Append
				Write-Output "$CMDBLK" | Tee-Object "${TIMESTAMP}_$($OBJ.SourceSystem)_$($OBJ.TargetSystem)-script.txt" -Append
				$ALLCMDS = $OUTPUT | 
					Where-Object {$_.SourceSystem -eq "$($OBJ.SourceSystem)" -and $_.TargetSystem -eq "$($OBJ.TargetSystem)" -and $_.CommandType -eq "$($OBJ.CommandType)"}
				ForEach ($CMD in $ALLCMDS) {
					#If ($($CMD.Comments) -ne "") {
					#	Write-Output "$($CMD.CommandString) # $($CMD.Comments)" | Tee-Object "${TIMESTAMP}_$($CMD.SourceSystem)_$($OBJ.TargetSystem)-script.txt" -Append
					#} Else {
						Write-Output "$($CMD.CommandString)" | Tee-Object "${TIMESTAMP}_$($CMD.SourceSystem)_$($OBJ.TargetSystem)-script.txt" -Append
					#}
					Write-Output "$CMDBLK" | Tee-Object "${TIMESTAMP}_$($OBJ.SourceSystem)_$($OBJ.TargetSystem)-script.txt" -Append
				} 
			}
		}
		CSV {
			$TIMESTAMP = $(Get-Date -Format yyyyMMddHHmmss)
			$ALLTGTSYS = $OUTPUT | Sort-Object -Property TargetSystem -Unique
			ForEach ($TGTSYS in $ALLTGTSYS) {
				$ALLCMDS = $OUTPUT | Where-Object {$_.TargetSystem -eq "$($TGTSYS.TargetSystem)"} 
				$ALLCMDS | Export-Csv -NoTypeInformation -Path ".\${TIMESTAMP}_$($TGTSYS.SourceSystem)_$($TGTSYS.TargetSystem).csv"
			}
		} 
		JSON {
			$TIMESTAMP = $(Get-Date -Format yyyyMMddHHmmss)
			$ALLTGTSYS = $OUTPUT | Sort-Object -Property TargetSystem -Unique
			ForEach ($TGTSYS in $ALLTGTSYS) {
				$ALLCMDS = $OUTPUT | Where-Object {$_.TargetSystem -eq "$($TGTSYS.TargetSystem)"} 
				$ALLCMDS | ConvertTo-Json | Out-File -FilePath ".\${TIMESTAMP}_$($TGTSYS.SourceSystem)_$($TGTSYS.TargetSystem).json"
			}
		}
		default {
			$OUTPUT
		}
	}
}
