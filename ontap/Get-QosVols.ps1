# This script will grab all volumes with a user-defined QoS Policy

# Defining our parameters, Username and Passowrd here will be used for each cluster in the array
[CmdletBinding()]
Param (
	[Parameter(Mandatory=$False,Position=1)]
	 [string[]]$Clusters,

	[Parameter(Mandatory=$True,Position=2)]
	 [string]$Username,

	[Parameter(Mandatory=$True,Position=3)]
	 [string]$Password
)

# This is our BEGIN block (also could be considered the setup block).  Code in this 
# block will be run one time.  Could be useful if piping other objects into this 
# script
BEGIN {

	# Let's check for the DataOntap PowerShell Module, if not import it
	If (!(Get-Module -Name DataONTAP)) {
		Import-Module -Name DataOntap -ErrorAction SilentlyContinue
	}

	# Same command after attempting import, if the module still isn't there, then
	# output error to the screen and exit the script The backtick (`) is a line-continuation
	If (!(Get-Module -Name DataONTAP)) {
		Write-Host -ForegroundColor Red -BackgroundColor Black `
			"Could not import DataONTAP module, is the DataONTAP Powershell Toolkit installed?"
		Exit
	}

	# Creating a credential to use to connect to all clusters
	# The ConvertTo-SecureString is required for this
	$ClusterCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "$Username",(ConvertTo-SecureString $Password -AsPlainText -Force)

	# Define array of Clusters
	$Clusters = @("KDCNETAPP02","KDCNETAPP03","KDCNETAPPBKP01","KDCNETAPPBKP02","KDCNETAPPGIS01","KDCNETAPPSAS01","KDCNETAPPVDI01","MDCNETAPP01","PDCNETAPP02","PDCNETAPPBKP01","PDCNETAPPBKP02","PDCNETAPPSAS01","PDCNETAPPVDI01","VDCNETAPP01","VDCNETAPP02") #gitignore

	# Here is where we define our processing functions
    # This one is to grab CDP info from from all physical ports on the node 
    function Get-VolsWithQos {
    	Get-NcQosWorkload | Where-Object {$_.WorkloadClass -eq "user_defined" -and $_.PolicyGroup -notlike "*Performance*Monitor*"}
    }

	# This is an empty array in which we will append the data gathered
	# from each cluster.  Again, only need to define it once.  We will
	# populate in the PROCESS block
	$OUTPUT = @()

}

PROCESS {
	ForEach ($Cluster in $Clusters) {
		# Let's connect to the cluster first...
		# Connect with credentials we defined earlier, and hide result
		Connect-NcController $Cluster -Credential $ClusterCreds | Out-Null
		
		# Then we'll run the fuction we built putting it into a variable so
		# we can pull these values out in the next step to create/append to 
		# our custom object
		$QOSVOLS = Get-VolsWithQos

		ForEach ($QOSVOL in $QOSVOLS) {
			# Create new object from the data in the variable, and add/append
	    	# That object into the array we defined in the BEGIN block
	    	$VOLQOSPOLICY = $QOSVOL | Select-Object @{Name="Name";Expression={$_.PolicyGroup}} | Get-NcQosPolicyGroup
	    	$OUTPUT += New-Object -TypeName PSObject -Property @{
				Cluster = $QOSVOL.NcController;
				Vserver = $QOSVOL.Vserver; 
				Volume = $QOSVOL.Volume; 
				PolicyGroup = $QOSVOL.PolicyGroup;
				ThroughputSetting = $VOLQOSPOLICY.MaxThroughput;
				TotalWorkloads = $VOLQOSPOLICY.NumWorkloads
			}
		}	
	}
}

END {
	# This section is to output the custom object we built
	# This section can be easily modified to output the
	# custom object to a file (csv, html, xml, etc) or use 
	# the object to do further processing
	$OUTPUT
}
