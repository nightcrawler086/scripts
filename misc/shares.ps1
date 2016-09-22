<#

.SYNOPSIS
This script is for duplicating or comparing shares and share ACLs between different NAS systems.

.DESCRIPTION
Typically, between like NAS systems, there are better methods of duplicating or comparing the shares and their ACLs.  However, between unlike systems (like Netapp + EMC), there are tools but lack some functionality.  The goal is to use some standard tools (rmtshare.exe) and wrap some powershell around it for processing its output into a usable format.

.EXAMPLE
PS > .\shares.ps1 -Action Compare -Source nas1 -Destination nas2

PS > .\shares.ps1 -Action Duplicate -Source nas1 -Destination nas2

.NOTES
The rmtshare.exe binary is required for this script to work.  Either store it in the current directory or in a directory that's stored in the $PATH variable.

#>

[CmdletBinding()]
Param (
	[Parameter(Mandatory=$True,Position=1)]
	 [string]$Action,

	[Parameter(Mandatory=$True,Position=2)]
	 [string]$Source,

	[Parameter(Mandatory=$True,Position=3)]
	 [string]$Destination

)

BEGIN {

}

PROCESS {

}

END {

}
