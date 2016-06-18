[CmdletBinding()]
Param (
	[Parameter(Mandatory=$False,Position=1)]
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
	} ElseIf ($InputFile -like "*.json") {
		$FILETYPE = "JSON"
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
	switch ($FILETYPE) {
		CSV {}
		
		JSON {}
		
		default {
			Write-Host "Unrecognized file type"
			Exit 1
		}
	}

}

END {}
