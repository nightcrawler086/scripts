[CmdletBinding()]
Param (
	[Parameter(Mandatory=$False,Position=1)]
	 [string[]]$OCIservers,

	[Parameter(Mandatory=$False,Position=2)]
	 [string]$Username,

	[Parameter(Mandatory=$False,Position=3)]
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

	# This is the old way of prompting for credentials.  Shows password in plain
	# text on the console when the script is executed
	#$ClusterCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList `
	#	"$Username",(ConvertTo-SecureString $Password -AsPlainText -Force)

	# This is the new, simple, and more secure way
	$ClusterCreds = Get-Credential

	$OCISERVERS = @("KDCOCIMGMT01","VDCOCIMGMT01","MDCOCIMGMT01") #gitignore

	$OUTPUT = @()

}

PROCESS {
	ForEach ($OCISERVER in $OCISERVERS) {
		Connect-OciServer -Name $OCISERVER -Credential $ClusterCreds -Insecure | Out-Null
	
		# Our CSV has a 3 letter datacenter column, and we will need to extract
		# our VMs based on this identifier.  The only way I have to do this
		# is pull a substring of the OCI server name
		# The following line pulls the first 3 characters from the OCI server
		# name, which will match the datacenter identifiers so we try to 
		# find the right VMs from the appropriate OCI server
		$DCID = $OCISERVER.Substring(0,3)

		# Importing all VMs from our CSV with the right datacenter ID
		$NONPRODVMS = Import-Csv .\nonprod-vms.csv | Where-Object {$_.datacenter -eq "$DCID"}
		
		# I don't have a way of getting the VMs by their name, so I'm having to
		# get all VMs and pull them out of the variable by name
		Get-OciVirtualMachines | Export-Csv -NoTypeInformation -Path .\${DCID}_all-vms.csv

        ForEach ($VM in $NONPRODVMS) {
            $VMARRAY = $ALLVMS | Where-Object {$_.Name -eq "$($VM.name)"}
 			$OUTPUT += New-Object -TypeName PSObject -Property @{
                    ociServer = $OCISERVER;
                    vmName = $VMARRAY.name; 
                    dnsName = $VMARRAY.dnsName; 
                    powerState = $VMARRAY.powerState;
                    memoryMB = $VMARRAY.memory.value;
                    capacityUsedGB = $VMARRAY.capacity.used.value / 1024; 
                    capacityTotalGB = $VMARRAY.capacity.total.value / 1024
			}
		}
	}	
}


END {
	
    $OUTPUT

}
