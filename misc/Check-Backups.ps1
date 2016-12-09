[CmdletBinding()]
Param (
	[Parameter(Mandatory=$True,Position=1)]
	 [string]$File
)

BEGIN {

	If (!(Get-Module BitsTransfer)) {
		Import-Module BitsTransfer
	}
	If (!(Get-Module BitsTransfer)) {
		Write-Host "Need BitsTransfer Module..."
		Exit
	}

	$VOLUMES = Import-Csv $File

	$URL = "https://bravura.nam.nsroot.net/clientlist.csv"

}

PROCESS {

	Write-Host "Downloading backup client list..."
	Start-BitsTransfer -Source $URL -Destination .\clientlist.csv

	$BACKUPS = Import-Csv .\clientlist.csv

	Write-Host "Checking for matching backups..."

	ForEach ($VOL in $VOLUMES) {
		$POLICY = $BACKUPS | Where-Object {$_.'Policy Name' -like "*$($VOL.Volume)*"}
		If (!$POLICY) { 
			Write-Host -ForegroundColor Red "$($VOL.Volume) does not have a backup policy"
		}
		If ($POLICY) {
			Write-Host "$($VOL.Volume) is backed up with:  $POLICY"
		}
	}
}

END{
}
