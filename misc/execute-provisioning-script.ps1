[CmdletBinding()]
Param (
	[Parameter(Mandatory=$True,Position=1)]
	 [string[]]$InputFile
)

BEGIN {

	If (!(Get-Module -Name Posh-SSH)) {
		Import-Module -Name Posh-SSH
	}

	If (!(Get-Module -Name Posh-SSH)) {
		Write-Host -ForegroundColor Magenta "Did not detect Posh-SSH module.  Install it and run this script again"
		Exit 1
	}

	If ($InputFile -like "*.csv") {
		$FILETYPE = "CSV"
		Write-Host "Input file is of type CSV"
	} ElseIf ($InputFile -like "*.json") {
		$FILETYPE = "JSON"
		Write-Host "Input file is of type JSON"
	} Else {
		Write-Host "Cannot detect input file type"
		Write-Host "Specify type as csv or json"
		$FILETYPE = Read-Host 'Input file type (csv/json)'
	}


}

PROCESS {
# Command types to iterate through (in order of execution):
#
# prdVdmCreate
# prdIntCreate
# prdVdmAttachInt
# prdCifsCreate
# prdCifsJoin
# prdNfsLdap
# prdNfsLdapVdm
# prdNfsNsSwitch
# prdFsCreate
# prdFsDedupe
# prdFsQtree
# prdFsMnt
# prdCifsExport
# prdNfsExport
# prdRepPass
# prdCreateInterconnect
#
# Script Logic
#
# Validate the input file (check for the right properties)
# Check the commands (make sure not <MISSING_PORPERTY> type things exist)
# Throw up some warnings (going to run commands as-is)
# Test-Connection to CS (ping and SSH?)
# Import commands from input file
# Run commands, in specific order, logging output
#
	$TIMESTAMP = $(Get-Date -Format yyyyMMddHHmmss)
	$LOGFILE = ".\${TIMESTAMP}_execution-log.txt"
	
	# This will need to go in the switch statement?  Maybe

	switch ($FILETYPE) {
		CSV {
			$COMMANDS = Import-Csv $InputFile
		}
		
		JSON {
			$COMMANDS = Get-Content -Raw $InputFile | ConvertFrom-Json
		}
		
		default {
			Write-Host "Unrecognized file type"
			Exit 1
		}
	}
	# Begin Validation Phase 1	
	Write-Output "$(Get-Date -Format 'yyy.MM.dd-HH:mm:ss') - Starting Validation Phase" | Tee-Object $LOGFILE
	ForEach ($OBJ in $COMMANDS) {
		If (Get-Member -InputObject $OBJ -Name TargetSystem,CommandType,CommandString -MemberType NoteProperty) {
			$i = $i + 1
		} 
	}
	If ($($COMMANDS | Measure-Object | Select-Object -ExpandProperty Count) -eq "$i") {
		Write-Output "$(Get-Date -Format 'yyy.MM.dd-HH:mm:ss') - $i objects of $($COMMANDS | Measure-Object | Select-Object -ExpandProperty Count) validated" | Tee-Object $LOGFILE -Append
		Write-Output "$(Get-Date -Format 'yyy.MM.dd-HH:mm:ss') - Validation Phase 1 Passed - All objects contain requried properties" | Tee-Object $LOGFILE -Append
	} Else {
		Write-Output "$(Get-Date -Format 'yyy.MM.dd-HH:mm:ss') - $i objects of $($COMMANDS | Measure-Object | Select-Object -ExpandProperty Count) validated" | Tee-Object $LOGFILE -Append
		Write-Output "$(Get-Date -Format 'yyy.MM.dd-HH:mm:ss') - Not all objects contain the required properties" | Tee-Object $LOGFILE -Append
		Write-Output "$(Get-Date -Format 'yyy.MM.dd-HH:mm:ss') - Correct the input file and rerun this script" | Tee-Object $LOGFILE -Append
		Write-Output "$(Get-Date -Format 'yyy.MM.dd-HH:mm:ss') - Validation Phase 1 Failed - All objects do not contain requried properties" | Tee-Object $LOGFILE -Append
		Exit 1
	}

}

END {}
