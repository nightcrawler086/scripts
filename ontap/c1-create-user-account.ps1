# Typically want to accept first positional parameter as the cluster name

BEGIN {

# Let's check for the DataOntap PowerShell Module, if not import it
	If (!(Get-Module -Name DataONTAP)) {
		Import-Module -Name DataOntap -ErrorAction SilentlyContinue
	}
	If (!(Get-Module -Name DataONTAP)) {
		Write-Host -ForegroundColor Red -BackgroundColor Black `
			"Could not import DataONTAP module, is the DataONTAP Powershell Toolkit installed?"
	}
}

PROCESS {

$C1Clusters = @("KDCNETAPP02","KDCNETAPP03","KDCNETAPPBKP01","KDCNETAPPBKP02","KDCNETAPPGIS01","KDCNETAPPSAS01","KDCNETAPPVDI01","MDCNETAPP01","PDCNETAPP02","PDCNETAPPBKP01","PDCNETAPPBKP02","PDCNETAPPSAS01","PDCNETAPPVDI01","VDCNETAPP01","VDCNETAPP02")
	
	# Loop to process each port
	Foreach ($Cluster in $C1Clusters) {
        Write-Host -ForegroundColor Green -BackgroundColor Black "Provide credentials for $Cluster"
		Connect-NcController $Cluster | Out-Null
		New-NcUser -UserName poshadmin -Vserver $Cluster -Application ontapi -AuthMethod password -Role admin -Password Netapp123! -Comment "Admin conAccount for PowerShell Toolkit"
				}
	}

