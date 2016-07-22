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
	 [string[]$SourcePath,

	[Parameter(Mandatory=$True,Position=2)]
	 [string]$TargetPath,

	[Parameter(Mandatory=$False,Position=3)]
	 [string]$InputFile
)

BEGIN {

	# Check our input

}

PROCESS {

	# Use Test-Path on the share (without mounting)
	# Add Shares as PSDrive
	# Use Get-Item to check the access
	# get-childitem | get-random -count 5-10
	# Compare ACLs on those selected items

}

END {

}
