# This is a Template for all Powershell Scripts for cDOT
# this is a random change
# Typically want to accept first positional parameter as the cluster name

[CmdletBinding()]
Param (
	[Parameter(Position=1)]
	 [string]$Cluster
)

	
BEGIN {
# Let's check for the DataOntap Module, if not import it

	If (!(Get-Module -Name DataONTAP)) {
		Import-Module -Name DataOntap -ErrorAction SilentlyContinue
	}
	If (!(Get-Module -Name DataONTAP)) {
		Write-Host -ForegroundColor Red -BackgroundColor Black `
			"Could not import DataONTAP module, is the DataONTAP Powershell Toolkit installed?"
	}
}

PROCESS {

}

