[CmdletBinding()]
Param (
	[Parameter(Mandatory=$True,Position=1)]
	 [string[]]$InputFile
)

BEGIN {

	# We need the Posh-SSH Module.  We will try to detect/install it
	If ((Get-Module -Name Posh-SSH)) {
		Write-Host "Posh-SSH Module already installed and Imported"
	} ElseIf ((Get-Module -ListAvailable -Name Posh-SSH)){
		Write-Host "Posh-SSH installed, importing..."
	} Else {
		Write-Host "Posh-SSH module not installed, trying to install..."
		If (($PSVersionTable.PSVersion.Major) -ge 5) {
			Find-Module -Name Posh-SSH | Install-Module
		} ElseIf (($PSVersionTable.PSVersion.Major) -le 4) {
			iex (New-Object Net.WebClient).DownloadString("https://gist.github.com/darkoperator/6152630/raw/c67de4f7cd780ba367cccbc2593f38d18ce6df89/instposhsshdev")
			If (!($LastExitCode)) {
				Write-Host "Could not install the Posh-SSH module."
				Write-Host "Install it manually and rerun this script"
				Exit 1
			}
		}
	}
	# Detect and import $InputFile
	$InputFileExt = [System.IO.Path]::GetExtension("$InputFile")
	switch ($InputFileExt) {
	
		".csv" {
			Write-Host "Deteced CSV input file"
			$INFILE = Import-Csv $InputFile
		}

		".json" {
			Write-Host "Detected JSON input file"
			$INFILE = Get-Content -Raw $InputFile | ConvertFrom-Json
		}

		default {
			Write-Host "Could not detect file type."
			Write-Host "Save as .csv or .json (depending on file type), and rerun this script"
		}
	}
	# Define Array to hold our commands after validation
	$OBJARRAY = @()
	# Validate the $INFILE...as best we can
	$TIMESTAMP = $(Get-Date -Format yyyyMMddHHmmss)
	$LOGFILE = ".\${TIMESTAMP}_execution-log.txt"
	Write-Output "Logfile: $LOGFILE"
	Write-Output "$(Get-Date -Format 'yyyy.MM.dd-HH:mm:ss') - Starting Validation Phase" | Tee-Object $LOGFILE -Append
	$INDEX = 0
	$PROPS = (($INFILE | Get-Member -MemberType NoteProperty)).Name
	$OBJCOUNT = ($($INFILE | Measure-Object).Count) 
	ForEach ($OBJ in $INFILE) {
		$INDEX++
		$VALID = $True
		ForEach ($PROP in $PROPS) {
			If (!(Get-Member -Name $PROP -InputObject $OBJ -MemberType NoteProperty)) {
				$VALID = $False
			}
		}
		If ($($OBJ.CommandString) -match "[N]\/[A]" -or $($OBJ.CommandString) -match "\<[A-Z]*_[A-Z]*\>" -or $($OBJ.CommandString) -match "\<[A-Z]*\>") {
			$VALID = $False	
		}
		If ($($OBJ.TargetSystem) -notmatch "^[a-zA-Z]{3}[c][t][i][n][a][s][v][0-9]{4}[x]$") {
			$VALID = $False
		}
		# This is not working
		#If ($($OBJ.CommandType) -notmatch "^[p][r][d][A-Za-z]*$" -or $($OBJ.CommandType) -notmatch "^[d][r][A-Za-z]*$") {
		#	$VALID = $False
		#}
		$OBJ | Add-Member -Name IsValid -MemberType NoteProperty -Value $VALID
		$OBJ | Add-Member -Name Index -MemberType NoteProperty -Value $INDEX
		$OBJARRAY += $OBJ
	}
	# If we find invalid objects, spit them out and exit
	$VALIDOBJ = ($($OBJARRAY | Where-Object {$_.IsValid -eq $True} | Measure-Object).Count)
	Write-Output "$(Get-Date -Format 'yyyy.MM.dd-HH:mm:ss') - $VALIDOBJ of $OBJCOUNT objects are valid" | Tee-Object $LOGFILE -Append
	If ($VALIDOBJ -ne $OBJCOUNT) {
		$INVALIDOBJ = $OBJARRAY | Where-Object {$_.IsValid -eq $False}
		Write-Output "$(Get-Date -Format 'yyyy.MM.dd-HH:mm:ss') - The following objects were determined to be invalid" | Tee-Object $LOGFILE -Append
		ForEach ($OBJ in $INVALIDOBJ) {
			Write-Output "$(Get-Date -Format 'yyyy.MM.dd-HH:mm:ss') - Index:$($OBJ.Index) | TargetSystem:$($OBJ.TargetSystem) | CommandType:$($OBJ.CommandType) | CommandString:$($OBJ.CommandString)" | Tee-Object $LOGFILE -Append
		}
		Write-Output "$(Get-Date -Format 'yyyy.MM.dd-HH:mm:ss') - There are $(($INVALIDOBJ | Measure-Object).Count) invalid objects that need to be corrected before the rest of this script will execute" | Tee-Object $LOGFILE -Append
		Exit 1
	}

}
<#
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
	
	# Begin Validation Phase 1	
	Write-Output "$(Get-Date -Format 'yyyy.MM.dd-HH:mm:ss') - Starting Validation Phase" | Tee-Object $LOGFILE
	$i = 0
	ForEach ($OBJ in $COMMANDS) {
		If (Get-Member -InputObject $OBJ -Name TargetSystem,CommandType,CommandString -MemberType Properties) {
			$i = $i + 1
		} 
	}
	If ($($COMMANDS | Measure-Object | Select-Object -ExpandProperty Count) -eq "$i") {
		Write-Output "$(Get-Date -Format 'yyyy.MM.dd-HH:mm:ss') - $i objects of $($COMMANDS | Measure-Object | Select-Object -ExpandProperty Count) validated" | Tee-Object $LOGFILE -Append
		Write-Output "$(Get-Date -Format 'yyyy.MM.dd-HH:mm:ss') - Validation Phase 1 Passed - All objects contain requried properties" | Tee-Object $LOGFILE -Append
	} Else {
		Write-Output "$(Get-Date -Format 'yyyy.MM.dd-HH:mm:ss') - $i objects of $($COMMANDS | Measure-Object | Select-Object -ExpandProperty Count) validated" | Tee-Object $LOGFILE -Append
		Write-Output "$(Get-Date -Format 'yyyy.MM.dd-HH:mm:ss') - Not all objects contain the required properties" | Tee-Object $LOGFILE -Append
		Write-Output "$(Get-Date -Format 'yyyy.MM.dd-HH:mm:ss') - Correct the input file and rerun this script" | Tee-Object $LOGFILE -Append
		Write-Output "$(Get-Date -Format 'yyyy.MM.dd-HH:mm:ss') - Validation Phase 1 Failed - All objects do not contain requried properties" | Tee-Object $LOGFILE -Append
		Exit 1
	}

}

END {}
#>
