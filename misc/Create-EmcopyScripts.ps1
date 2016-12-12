[CmdletBinding()]
Param (
	[Parameter(Mandatory=$True,Position=1)]
	 [string]$File
)

BEGIN {

	$INFILE = Import-Csv $File

}

PROCESS {

	ForEach ($OBJ in $INFILE) {
		$VOLNUM = $($OBJ.TargetVolume)
		$VOLNUM = $VOLNUM.Substring($VOLNUM.get_length()-4)
		$TGTQTREE = "ctiqt$VOLNUM"
		Write-Output "emcopy64.exe \\$($OBJ.SourceVfiler)\$($OBJ.SourceVolume) \\$($OBJ.TargetVdm)\$TGTQTREE /s /sdd /d /o /a /secfix /i /lg /purge /r:0 /w:0 /c /log:D:\emcopy-log\$($OBJ.SourceVolume).txt" | Tee-Object -FilePath .\incremental-commands.txt -Append
		Write-Output "emcopy64.exe \\$($OBJ.SourceVfiler)\$($OBJ.SourceVolume) \\$($OBJ.TargetVdm)\$TGTQTREE /s /sdd /d /o /a /i /lg /purge /r:0 /w:0 /c /log:D:\emcopy-log\$($OBJ.SourceVolume)-final.txt" | Tee-Object -FilePath .\final-commands.txt -Append
	}
}

END{
}
