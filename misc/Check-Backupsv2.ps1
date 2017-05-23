[CmdletBinding()]
Param (
	[Parameter(Mandatory=$False,Position=1)]
	 [string]$InputFile,

	[Parameter(Mandatory=$False,Position=2)]
     [string]$ClientList,

    [Parameter(Mandatory=$False,Position=3)]
	 [string[]]$VolumeList
)

BEGIN {

	If (!$ClientList) {
		If (!(Get-Module BitsTransfer)) {
			Import-Module BitsTransfer
		}
		If (!(Get-Module BitsTransfer)) {
			Write-Host "Need BitsTransfer Module..."
			Exit 1
		}
	}

    If ($VolumeList) {
        $VOLUMES = $VolumeList
        $VOLUMES = $VOLUMES.Split(",")
    }
    ElseIf ($InputFile) {
        $VOLUMES = Import-Csv $InputFile
    } 
    ElseIf (!$InputFile) {
        $VOLUMES = Import-Csv ".\volumes.csv"
    }
    Else {
        Echo "No input specified..."
        Echo "You must specify an input file or volume list"
        Exit 1
    }

	$URL = "http://bravura.nam.nsroot.net/clientlist.csv"

    $OUTPUT = @()

}

PROCESS {

    If (!$ClientList) {
	    Write-Host "No client list specified, downloading now..."
        Start-BitsTransfer -Source $URL -Destination .\clientlist.csv
        $BACKUPS = Import-Csv .\clientlist.csv
    }

    If ($ClientList) {
        $BACKUPS = Import-Csv $ClientList
    }

    ForEach ($VOL in $VOLUMES) { 
        $POLICY = $BACKUPS | Where-Object {$_.'Policy Name' -like "*_$($VOL.TargetVolume)_*" -and $_.'Policy Name' -like "*_$($VOL.TargetFiler)_*"}
        $OUTPUT += New-Object -TypeName PSObject -Property @{
                    CobFiler = $VOL.TargetFiler;
                    Volume = $VOL.TargetVolume;
                    BackupPolicy = $POLICY.'Policy Name'
	     }
    }
}

END{

$OUTPUT

}
