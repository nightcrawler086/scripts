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
	# Finish Adding LDAP commands
	# Add SPN commands
	# Derive Interface Name from info in the spreadsheet (using a bunch of substrings)

	# This will store our custom object for output	
	$OUTPUT = @()
	

<#
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
#>

	# Begin functions to drop commands into a single custom object

	function Setup-Vdm {
		$SUBSET = $CSVDATA | Select-Object -Property TargetVdm -Unique
		ForEach ($OBJ in $SUBSET) {
			If ($($OBJ.TargetVdm) -ne $NULL -or $($OBJ.TargetVdm) -ne "N/A") {
				$CMD0 = "nas_server -name $($OBJ.TargetVDM) -type vdm -create $($OBJ.TargetDM) -setstate loaded pool=$($OBJ.TargetStoragePool)"
				$OUTPUT += New-Object -TypeName PSObject -Property @{
					SourceSystem = $OBJ.SourceSystem;
					TargetSystem = $OBJ.TargetSystem;
					TargetDrSystem = $OBJ.TargetDrSystem;
					CommandType = prdVdmCreate;
					CommandString = $CMD0
				} 
				$CMD1 = "nas_server -vdm $($OBJ.TargetVDM) -attach <INT_NAME>"
				$OUTPUT += New-Object -TypeName PSObject -Property @{
					SourceSystem = $OBJ.SourceSystem;
					TargetSystem = $OBJ.TargetSystem;
					TargetDrSystem = $OBJ.TargetDrSystem;
					CommandType = prdVdmAttachInt;
					CommandString = $CMD1
				} 
			} 

			If ($($OBJ.TargetDrSystem) -ne $NULL -or $($OBJ.TargetDrSystem -ne "N/A")) {
				$CMD2 = "nas_replicate -create $($OBJ.TargetVDM)_REP -source -vdm $($OBJ.TargetVDM) -destination -pool id=<POOL_ID> -interconnect <INTERCONNECT_NAME> -max_time_out_of_sync 10 -background"
				$OUTPUT += New-Object -TypeName PSObject -Property @{
					SourceSystem = $OBJ.SourceSystem;
					TargetSystem = $OBJ.TargetSystem;
					TargetDrSystem = $OBJ.TargetDrSystem;
					CommandType = prdVdmRep;
					CommandString = $CMD2
				}
				$CMD3 = "nas_server -vdm $($OBJ.TargetVDM) -attach <INT_NAME>"
				$OUTPUT += New-Object -TypeName PSObject -Property @{
					SourceSystem = $OBJ.SourceSystem;
					TargetSystem = $OBJ.TargetSystem;
					TargetDrSystem = $OBJ.TargetDrSystem;
					CommandType = drVdmAttachInt;
					CommandString = $CMD3
				}
			}
		}
	}

	function Setup-Interfaces {
		$SUBSET = $CSVDATA | Select-Object -Property TargetIp -Unique
		ForEach ($OBJ in $SUBSET) {
			If ($($OBJ.TargetIp) -ne $NULL -or $($OBJ.TargetIp) -ne "N/A") {
				$CMD = "server_ifconfig $($OBJ.TargetDM) -create -device fsn0 -name <INT_NAME> -protocol IP $($OBJ.TargetIp) <MASK> <BROADCAST>" 		
				$OUTPUT += New-Object -TypeName PSObject -Property @{
					SourceSystem = $OBJ.SourceSystem;
					TargetSystem = $OBJ.TargetSystem;
					TargetDrSystem = $OBJ.TargetDrSystem;
					CommandType = prdIntCreate;
					CommandString = $CMD
				}
			}
		}

		$SUBSET = $CSVDATA | Select-Object -Property TargetDrIp -Unique
		ForEach ($OBJ in $SUBSET) {
			If ($($OBJ.TargetDrIp) -ne $NULL -or $($OBJ.TargetDrIp) -ne "N/A") {
				$CMD = "server_ifconfig $($OBJ.TargetDrDM) -create -device fsn0 -name <INT_NAME> -protocol IP $($OBJ.TargetDrIp) <MASK> <BROADCAST>" 		
				$OUTPUT += New-Object -TypeName PSObject -Property @{
					SourceSystem = $OBJ.SourceSystem;
					TargetSystem = $OBJ.TargetSystem;
					TargetDrSystem = $OBJ.TargetDrSystem;
					CommandType = drIntCreate;
					CommandString = $CMD
				}
			}
		}
	}

	function Setup-Cifs {
		$SUBSET = $CSVDATA | Select-Object -Property TargetCifsServer -Unique
		ForEach ($OBJ in $SUBSET) {
			If ($($OBJ.TargetProtocol) -eq "CIFS" -or $($OBJ.TargetProtocol) -eq "BOTH") {
				$CMD0 = "server_cifs $($OBJ.TargetCifsServer) -add compname=$($OBJ.TargetCifsServer),domain=nam.nsroot.net,interface=<INT_NAME>,local_users"
				$OUTPUT += New-Object -TypeName PSObject -Property @{
					SourceSystem = $OBJ.SourceSystem;
					TargetSystem = $OBJ.TargetSystem;
					TargetDrSystem = $OBJ.TargetDrSystem;
					CommandType = prdCifsCreate;
					CommandString = $CMD0
				}

				$CMD1 = "server_cifs $($OBJ.TargetCifsServer) -join compname=$($OBJ.TargetCifsServer),domain=nam.nsroot.net,admin=<ADMIN_USER>,ou=Servers:ou-NAS:ou=INFRA"
				$OUTPUT += New-Object -TypeName PSObject -Property @{
					SourceSystem = $OBJ.SourceSystem;
					TargetSystem = $OBJ.TargetSystem;
					TargetDrSystem = $OBJ.TargetDrSystem;
					CommandType = prdCifsJoin;
					CommandString = $CMD1
				}
			}
		}
	}

	function Setup-NfsLdap {
		$SUBSET = $CSVDATA | Select-Object -Property TargetNfsServer -Unique
		ForEach ($OBJ in $SUBSET) {
			If ($($OBJ.TargetNfsServer) -ne $NULL -or $($OBJ.TargetNfsServer) -ne "N/A") {
				$CMD = "server_ldap $($OBJ.TargetDm) -add -basedn <BASE_DN> -servers <CSV_SERVER_LIST> -sslenabled n"
				$OUTPUT += New-Object -TypeName PSObject -Property @{
					SourceSystem = $OBJ.SourceSystem;
					TargetSystem = $OBJ.TargetSystem;
					TargetDrSystem = $OBJ.TargetDrSystem;
					CommandType = prdNfsLdap;
					CommandString = $CMD
				}
			}	
		}
	}

	function Setup-Filesystems {
		$SUBSET = $CSVDATA | Select-Object -Property TargetFilesystem -Unique
		ForEach ($OBJ in $SUBSET) {
			If ($($OBJ.TargetFilesystem) -ne $NULL -or $($OBJ.TargetFilesystem) -ne "N/A") {
				$CMD0 = "nas_fs -name $($OBJ.TargetFilesystem) -type $($OBJ.TargetSecurityStyle) -create size=$($OBJ.TargetCapacityGB)GB pool=$($OBJ.TargetStoragePool) -option slice=y"
				$OUTPUT += New-Object -TypeName PSObject -Property @{
					SourceSystem = $OBJ.SourceSystem;
					TargetSystem = $OBJ.TargetSystem;
					TargetDrSystem = $OBJ.TargetDrSystem;
					CommandType = prdFsCreate;
					CommandString = $CMD0
				}
				$CMD1 = "fs_dedupe -modify $($OBJ.TargetFilesystem) -state on"
				$OUTPUT += New-Object -TypeName PSObject -Property @{
					SourceSystem = $OBJ.SourceSystem;
					TargetSystem = $OBJ.TargetSystem;
					TargetDrSystem = $OBJ.TargetDrSystem;
					CommandType = prdFsDedupe;
					CommandString = $CMD1
				}
				$CMD2 = "nas_ckpt_schedule -create $($OBJ.TargetFilesystem)_DAILY_SCHED -filesystem $($OBJ.TargetFilesystem) -description ""1730hrs daily checkpoint schedule for $($OBJ.TargetFilesystem)"" -recurrence daily -every 1 -start_on <DATE> -runtimes 17:30 -keep 7"
				$OUTPUT += New-Object -TypeName PSObject -Property @{
					SourceSystem = $OBJ.SourceSystem;
					TargetSystem = $OBJ.TargetSystem;
					TargetDrSystem = $OBJ.TargetDrSystem;
					CommandType = prdFsCkpt;
					CommandString = $CMD2
				}
				$DMNUM = $($OBJ.TargetDm).Substring(7)
				$CMD3 = "mkdir /nasmcd/quota/slot_$DMNUM/root_vdm_X/$($OBJ.TargetFilesystem)/$($OBJ.TargetQtree)"
				$OUTPUT += New-Object -TypeName PSObject -Property @{
					SourceSystem = $OBJ.SourceSystem;
					TargetSystem = $OBJ.TargetSystem;
					TargetDrSystem = $OBJ.TargetDrSystem;
					CommandType = prdFsQtree;
					CommandString = $CMD3
				}
				$CMD4 = "server_mount $($OBJ.TargetVDM) $($OBJ.TargetFilesystem) /$($OBJ.TargetFilesystem)"
				$OUTPUT += New-Object -TypeName PSObject -Property @{
					SourceSystem = $OBJ.SourceSystem;
					TargetSystem = $OBJ.TargetSystem;
					TargetDrSystem = $OBJ.TargetDrSystem;
					CommandType = prdFsMnt;
					CommandString = $CMD4
				}
			}
			If ($($OBJ.TargetProtocol) -eq "CIFS" -or $($OBJ.TargetProtocol) -eq "BOTH") {
				$CMD5 = "server_export $($OBJ.TargetVDM) -protocol cifs -name $($OBJ.TargetFilesystem) -o netbios=$($OBJ.TargetVDM) /$($OBJ.TargetFilesystem)/$($OBJ.TargetFilesystem)"
				$OUTPUT += New-Object -TypeName PSObject -Property @{
					SourceSystem = $OBJ.SourceSystem;
					TargetSystem = $OBJ.TargetSystem;
					TargetDrSystem = $OBJ.TargetDrSystem;
					CommandType = prdCifsExport;
					CommandString = $CMD5
				}
			}
			If ($($OBJ.TargetProtocol) -eq "NFS" -or $($OBJ.TargetProtocol) -eq "BOTH") {
				$CMD6 = "server_export $($OBJ.TargetVDM) -protocol nfs -name $($OBJ.TargetFilesystem) -o rw=<CLIENTS>,ro=<CLIENTS>,root=<CLIENTS> /$($OBJ.TargetFilesystem)/$($OBJ.TargetQtree)"
				$OUTPUT += New-Object -TypeName PSObject -Property @{
					SourceSystem = $OBJ.SourceSystem;
					TargetSystem = $OBJ.TargetSystem;
					TargetDrSystem = $OBJ.TargetDrSystem;
					CommandType = prdNfsExport;
					CommandString = $CMD6
				}
			}
			If ($($OBJ.TargetDrFilesystem) -ne $NULL -or $($OBJ.TargetDrFilesystem) -ne "N/A") {
				$CMD7 = "nas_replicate -create $($OBJ.TargetFilesystem)_REP -source -fs $($OBJ.TargetFilesystem) -destination -fs $($OBJ.TargetDrFilesystem) -interconnect <INTERCONNECT_NAME> -max_time_out_of_sync 10 -background"
				$OUTPUT += New-Object -TypeName PSObject -Property @{
					SourceSystem = $OBJ.SourceSystem;
					TargetSystem = $OBJ.TargetSystem;
					TargetDrSystem = $OBJ.TargetDrSystem;
					CommandType = prdFsRep;
					CommandString = $CMD7
				}
				$CMD8 = "nas_fs -name $($OBJ.TargetDrFilesystem) -create samesize:$($OBJ.TargetFilesystem):$($OBJ.TargetVDM) pool:$($OBJ.TargetDrStoragePool)" 
				$OUTPUT += New-Object -TypeName PSObject -Property @{
					SourceSystem = $OBJ.SourceSystem;
					TargetSystem = $OBJ.TargetSystem;
					TargetDrSystem = $OBJ.TargetDrSystem;
					CommandType = drFsCreate;
					CommandString = $CMD8
				}
				$CMD9 = "server_mount $($OBJ.TargetVDM) -o ro $($OBJ.TargetDrFilesystem) /$($OBJ.TargetDrFilesystem)"
				$OUTPUT += New-Object -TypeName PSObject -Property @{
					SourceSystem = $OBJ.SourceSystem;
					TargetSystem = $OBJ.TargetSystem;
					TargetDrSystem = $OBJ.TargetDrSystem;
					CommandType = drFsMnt;
					CommandString = $CMD9
				}
				$CMD10 = "nas_ckpt_schedule -create $($OBJ.TargetDrFilesystem)_DAILY_SCHED -filesystem $($OBJ.TargetDrFilesystem) -description ""1730hrs daily checkpoint schedule for $($OBJ.TargetDrFilesystem)"" -recurrence daily -every 1 -start_on <DATE> -runtimes 17:30 -keep 7"
				$OUTPUT += New-Object -TypeName PSObject -Property @{
					SourceSystem = $OBJ.SourceSystem;
					TargetSystem = $OBJ.TargetSystem;
					TargetDrSystem = $OBJ.TargetDrSystem;
					CommandType = drFsCkpt;
					CommandString = $CMD10
				}
			}
		}
	}

	function All-Commands {
		Setup-Vdm
		Setup-Interfaces
		Setup-Cifs
		Setup-NfsLdap
		Setup-Filesystems
	}

}

PROCESS {

	If ($SourceSystem -ne $NULL) {
		$TIMESTAMP = $(Get-Date -Format yyyyMMddHHmmss)
		$OUTFILE = ".\${TIMESTAMP}_${SourceSystem}-provisioning-script.txt"
		$CSVDATA = Import-Csv -Path $CsvFile | Where-Object {$_.SourceSystem -eq "$SourceSystem"}
		All-Commands
	} ElseIf ($SourceSystem -eq $NULL) {
		Write-Host -BackgroundColor Black -ForegroundColor Magenta "You did not specify a Source System..."
		Write-Host -BackgroundColor Black -ForegroundColor Magenta "Do you want to create separate provsioning scripts"
		Write-Host -BackgroundColor Black -ForegroundColor Magenta "for each source system in the CSV file?"
		$RESPONSE = Read-Host '(Y/y/N/n)?:'
		If ($RESPONSE -eq "Y") {
			# Loop through source systems and create separate files per
			$ALLSOURCESYSTEMS = Import-Csv -Path $CsvFile | Select-Object -ExpandProperty SourceSystem -Unique 
			ForEach ($SYSTEM in $ALLSOURCESYSTEMS) {
				$TIMESTAMP = $(Get-Date -Format yyyyMMddHHmmss)
				$SourceSystem = $SYSTEM
				$OUTFILE = ".\${TIMESTAMP}_${SourceSystem}-provisioning-script.txt"
				$CSVDATA = Import-Csv -Path $CsvFile | Where-Object {$_.SourceSystem -eq "$SourceSystem"}
				All-Commands
			}
		}  Else {
			Write-Host "Nothing to do.  Exiting..."
			Exit 1
		}	
	}
}

END {
	
	$OUTPUT

}
