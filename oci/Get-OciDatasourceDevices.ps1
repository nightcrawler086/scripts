[CmdletBinding()]
Param (
	[Parameter(Mandatory=$False,Position=1)]
	 [string[]]$OCIservers,

	[Parameter(Mandatory=$True,Position=2)]
	 [string]$Username,

	[Parameter(Mandatory=$True,Position=3)]
	 [string]$Password
)

BEGIN {

	If (!(Get-Module -Name OnCommand-Insight)) {
		Import-Module -Name OnCommand-Insight -ErrorAction SilentlyContinue
	}

	If (!(Get-Module -Name OnCommand-Insight)) {
		Write-Host -ForegroundColor Red -BackgroundColor Black `
			"Could not import OnCommand-Insight module, is the OnCommand-Insight module installed?"
		Exit
	}

	$ClusterCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList `
		"$Username",(ConvertTo-SecureString $Password -AsPlainText -Force)

	$OCISERVERS = @("KDCOCIMGMT01","VDCOCIMGMT01","MDCOCIMGMT01") #gitignore

	$OUTPUT = @()

}

PROCESS {
	ForEach ($OCISERVER in $OCISERVERS) {
		Connect-OciServer -Name $OCISERVER -Credential $ClusterCreds -Insecure | Out-Null
	
		$DATASOURCES = Get-OciDataSources

        ForEach ($DATASOURCE in $DATASOURCES) {
            $DSDEVICES = Get-OciDatasourceDevices -id $DATASOURCE.id
            #$DSDEVICES = Get-OciDatasourceDevices -id $DATASOURCE.id | Select-Object Name,@{Name="type";Expression={$_.type -join '; '}},@{Name="ip";Expression={$_.ip -join '; '}},@{Name="id";Expression={$_.id -join '; '}},@{Name="wwn";Expression={$_.wwn -join '; '}}
            #$DSDEVICENAME = Get-OciDatasourceDevices -id $DATASOURCE.id | Select-Object -ExpandProperty Name
                ForEach ($DSDEVICE in $DSDEVICES) {
                    $OUTPUT += New-Object -TypeName PSObject -Property @{
                        OciServer = $OCISERVER;
                        DatasourceName = $DATASOURCE.name; 
                        DeviceType = $DSDEVICE.type; 
                        DeviceName = $DSDEVICE.name;
                        DeviceIP = $DSDEVICE.ip;
                        DeviceID = $DSDEVICE.id;
                        DeviceWWN = $DSDEVICE.wwn
                }
            }
        }	
	}
}

END {
	
    $OUTPUT

}
