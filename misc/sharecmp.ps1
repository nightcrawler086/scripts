<#

.SYNOPSIS
This script is for testing access to share paths, and doing some basic validation comparisons

.DESCRIPTION
This script will take a source path and destination path as arguments, and then test access to them
and compare the ACLs on a few of the folders to make sure they are the same.  

.EXAMPLE
.\Test-Access -SourcePath \\nas01\share1 -TargetPath \\nas02\share1

.\Test-Access -InputFile C:\path\to\file.csv

.NOTES
The expected format of the input file is a regular CSV file.  With fields like this:

SourcePath,TargetPath
\\nas\share,\\nas\share

#>
[CmdletBinding()]
Param (
	[Parameter(Mandatory=$True,Position=1)]
	 [string[]$SrcFile,

	[Parameter(Mandatory=$True,Position=2)]
	 [string]$DstFile
)

BEGIN {

	$SRCFILEEXT = [System.IO.Path]::GetExtension("$SrcFile")
	$DSTFILEEXT = [System.IO.Path]::GetExtension("$SrcFile")

	If ($SRCFILEEXT -ne "csv") {
		Write-Host "Source File is not a CSV.  Use compmgmt.msc to export the shares to a csv"
	}

	If ($DSTFILEEXT -ne "csv") {
		Write-Host "Destination File is not a CSV.  Use compmgmt.msc to export the shares to a csv"
	}

}

PROCESS {

	$SRC = Import-Csv "$SrcFile"
	$DST = Import-Csv "$DstFile"

	$RESULTS = Compare-Object -ReferenceObject $SRC -DifferenceObject $DST -SyncWindow 2000 -Property 'Share Name' -PassThru


}

END {

}
