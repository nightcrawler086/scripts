[CmdletBinding()]
Param (
	[Parameter(Mandatory=$False,Position=1)]
	 [string]$File,

	[Parameter(Mandatory=$False,Position=2)]
	 [string[]]$VolumeList
)

BEGIN {

	If (!(Get-Module BitsTransfer)) {
		Import-Module BitsTransfer
	}
	If (!(Get-Module BitsTransfer)) {
		Write-Host "Need BitsTransfer Module..."
		Exit 1
	}

	If ($File) {
		$VOLUMES = Import-Csv $File
	} 
    ElseIf ($VolumeList) {
		$VOLUMES = $VolumeList
        $VOLUMES = $VOLUMES.Split(",")
	} 
    Else { 
        Echo "No input specified..."
        Echo "You must specify an input file or volume list"
        Exit 1 
    }

	$URL = "http://bravura.nam.nsroot.net/clientlist.csv"

}

PROCESS {

	Write-Host "Downloading backup client list..."
	Start-BitsTransfer -Source $URL -Destination .\clientlist.csv

	$BACKUPS = Import-Csv .\clientlist.csv

	Write-Host "Checking for matching backups..."

	ForEach ($VOL in $VOLUMES) {
        If ((Get-Member -Name Volume -InputObject $VOLUMES)) {
		    $POLICY = $BACKUPS | Where-Object {$_.'Policy Name' -like "*$($VOL.Volume)*"}
            If (!$POLICY) { 
			    Write-Host -ForegroundColor Red "$($VOL.Volume) does not have a backup policy"
		    }
		    If ($POLICY) {
			    Write-Host "$($VOL.Volume) is backed up with:  $($POLICY.'Policy Name')"
		    }
        } 
        Else {
            $POLICY = $BACKUPS | Where-Object {$_.'Policy Name' -like "*$VOL*"}
            If (!$POLICY) { 
		        Write-Host -ForegroundColor Red "$VOL does not have a backup policy"
	        }
	        If ($POLICY) {
		        Write-Host "$VOL is backed up with:  $($POLICY.'Policy Name')"
	        }
        }
	}
}

END{

Write-Host "Cleaning up..."
Remove-Item -Path .\clientlist.csv
Write-Host "Done."

}
