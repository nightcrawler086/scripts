[CmdletBinding()]
Param (
	[Parameter(Mandatory=$True,Position=1)]
	 [string[]]$InputFile
)

BEGIN {

	function log($TXT) {
		Write-Output "$(Get-Date -Format 'yyyy.MM.dd-HH:mm:ss') - $TXT"
	}
	
	# Define our log file
	$TIMESTAMP = $(Get-Date -Format yyyyMMddHHmmss)
	$LOGFILE = ".\${TIMESTAMP}_execution-log.txt"
	
	# Entering Setup Phase
	log "Starting Setup Phase" | Tee-Object $LOGFILE -Append

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
	$CMDARRAY = @()

	# Define array to hold our output (results)
	$OUTPUT = @()

	# Validate the $INFILE...as best we can
	Write-Output "Logfile: $LOGFILE"
	log "Starting Validation Phase" | Tee-Object $LOGFILE -Append
	$INDEX = 0
	$PROPS = (($INFILE | Get-Member -MemberType NoteProperty)).Name
	$OBJCOUNT = ($($INFILE | Measure-Object).Count) 
	ForEach ($OBJ in $INFILE) {
		$INDEX++
		$REASON = @()
		$VALID = $True
		ForEach ($PROP in $PROPS) {
			If (!(Get-Member -Name $PROP -InputObject $OBJ -MemberType NoteProperty)) {
				$VALID = $False
			}
		}
		If ($($OBJ.CommandString) -match "[N]\/[A]" -or $($OBJ.CommandString) -match "\<[A-Z]*_[A-Z]*\>" -or $($OBJ.CommandString) -match "\<[A-Z]*\>") {
			$VALID = $False	
			$REASON += "CommandString contained `"N/A`" or placeholder value enclosed in <>"
		}
		If ($($OBJ.TargetSystem) -notmatch "^[a-zA-Z]{3}[c][t][i][n][a][s][v][0-9]{4}[x]$") {
			$VALID = $False
			$REASON += "TargetSystem did not match expected pattern"
		}
		If ($($OBJ.CommandType) -notmatch "^[p][r][d][a-zA-Z]*$" -and $($OBJ.CommandType) -notmatch "^[d][r][a-zA-Z]*$") {
			$VALID = $False
			$REASON += "CommandType did not match expected pattern"
		}
		$OBJ | Add-Member -Name IsValid -MemberType NoteProperty -Value $VALID
		$OBJ | Add-Member -Name Index -MemberType NoteProperty -Value $INDEX
		If ($($OBJ.IsValid) -eq $False) {
			$OBJ | Add-Member -Name Reason -MemberType NoteProperty -Value $REASON
		}
		$CMDARRAY += $OBJ
	}

	# If we find invalid objects, spit them out and exit
	$VALIDOBJ = ($($CMDARRAY | Where-Object {$_.IsValid -eq $True} | Measure-Object).Count)
	log "$VALIDOBJ of $OBJCOUNT objects are valid" | Tee-Object $LOGFILE -Append
	If ($VALIDOBJ -ne $OBJCOUNT) {
		$INVALIDOBJ = $CMDARRAY | Where-Object {$_.IsValid -eq $False}
		log "The following objects were determined to be invalid" | Tee-Object $LOGFILE -Append
		ForEach ($OBJ in $INVALIDOBJ) {
			log "Index:$($OBJ.Index) | Reason:$($OBJ.Reason) | TargetSystem:$($OBJ.TargetSystem) | CommandType:$($OBJ.CommandType) | CommandString:$($OBJ.CommandString)" | Tee-Object $LOGFILE -Append
		}
		log "There are $(($INVALIDOBJ | Measure-Object).Count) invalid objects that need to be corrected before the rest of this script will execute" | Tee-Object $LOGFILE -Append
		Exit 1
	}
	log "Validation Phase Complete" | Tee-Object $LOGFILE -Append

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
# Throw up some warnings (going to run commands as-is) 
# Import commands from input file
# Run commands, in specific order, logging output
	
	# Begin testing if Target System is reachable	
	log "Begin Test Network Connectivity Phase" | Tee-Object $LOGFILE -Append
	$TGTSYS = $CMDARRAY | Select-Object -ExpandProperty TargetSystem -Unique
	$TGTDRSYS = $CMDARRAY | Select-Object -ExpandProperty TargetDrSystem -Unique
	
	# Trying to ping systems
	log "Trying to ping target systems" | Tee-Object $LOGFILE -Append
	ForEach ($SYS in $TGTSYS) {
		If (!(Test-Connection -BufferSize 32 -Count 1 -Quiet -ComputerName $SYS)) {
			log "Could not ping host $SYS)" | Tee-Object $LOGFILE -Append
		} Else {
			log "Ping to $SYS was successful" | Tee-Object $LOGFILE -Append
		}
	}
	log "Trying to ping target dr systems" | Tee-Object $LOGFILE -Append
	ForEach ($SYS in $TGTDRSYS) {
		If (!(Test-Connection -BufferSize 32 -Count 1 -Quiet -ComputerName $SYS)) {
			log "Could not ping host $SYS)" | Tee-Object $LOGFILE -Append
		} Else {
			log "Ping to $SYS was successful" | Tee-Object $LOGFILE -Append
		}
	}

	# Trying to connect on port 22
	log "Test connection to port 22 on target systems"
	ForEach ($SYS in $TGTSYS) {
		$TGTSYSSOCK = New-Object System.Net.Sockets.TcpClient("$SYS","22")
			If ($TGTSYSSOCK.Connected) {
				log "Port 22 on $SYS is open" | Tee-Object $LOGFILE -Append
				$TGTSYSSOCK.Close()
			} Else {
				log "Could not connect to port 22 on $SYS" | Tee-Object $LOGFILE -Append
				log "Verify network connectivity to $SYS from this system, then run this script again" | Tee-Object $LOGFILE -Append
			}
		}
	log "Test connection to port 22 on target dr systems"
	ForEach ($SYS in $TGTDRSYS) {
		$TGTSYSSOCK = New-Object System.Net.Sockets.TcpClient("$SYS","22")
			If ($TGTSYSSOCK.Connected) {
				log "Port 22 on $SYS is open" | Tee-Object $LOGFILE -Append
				$TGTSYSSOCK.Close()
			} Else {
				log "Could not connect to port 22 on $SYS" | Tee-Object $LOGFILE -Append
				log "Verify network connectivity to $SYS from this system, then run this script again" | Tee-Object $LOGFILE -Append
			}
		}
	log "Test Network Connectivity Phase Completed" | Tee-Object $LOGFILE -Append
	
	# Begin Execution Phase
	log	"Begin Execution Phase" | Tee-Object $LOGFILE -Append
	# print them to the screen for final validation?
	$EXECARRAY = $CMDARRAY | Where-Object {$_.ExecutionOrder -ne $Null} | Sort-Object -Property ExecutionOrder
	log "The following commands will be executed in order:" | Tee-Object $LOGFILE -Append
	Write-Output "--------------------------------------------------------------------"
	ForEach ($OBJ in $EXECARRAY) {
		If ($($OBJ.CommandType) -match "^[p][r][d][A-Za-z]*$") {
			log "Target System: $($OBJ.TargetSystem) Command: $($OBJ.CommandString)" | Tee-Object $LOGFILE -Append
		}
		If ($($OBJ.CommandType) -match "^[d][r][A-Za-z]*$") {
			log "Target DR System:  $($OBJ.TargetDrSystem) Command: $($OBJ.CommandString)" | Tee-Object $LOGFILE -Append
		}
	}
	Write-Output "--------------------------------------------------------------------"
	Write-Output "Review the above commands for accuracy, we will attempt to execute them as is"
	Pause

}

END {}
