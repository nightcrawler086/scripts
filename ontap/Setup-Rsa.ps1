# Defining our parameters, Username and Passowrd here will be used for each cluster in the array
# Commenting these out since I don't really use them.
#[CmdletBinding()]
#Param (
#	[Parameter(Mandatory=$False,Position=1)]
#	 [string[]]$Clusters,
#
#	[Parameter(Mandatory=$True,Position=2)]
#	 [string]$Username,
#
#	[Parameter(Mandatory=$True,Position=3)]
#	 [string]$Password
#)

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

	# Interactively prompt for credentials.  Simpler and doesn't show password in clear text on the screen.
	$ClusterCreds = Get-Credential

	# Define array of Clusters
	$Clusters = @("Cluster1","Cluster2")


	# Console Output Setup
	# Doesn't work yet
	$WHSUCCESS = Write-Host -ForegroundColor Cyan -BackgroundColor Black
	$WHFAIL = Write-Host -ForegroundColor Red -BackgroundColor Black

	# Steps to Setup RSA:
	# Verify ASUP is enabled <-- done
	# Verify/Configure Web Services are enabled <-- cannot do this in 8.2.3
	# Verify/Configure Firewall Policy <-- cannot do this in 8.2.3
	# Create role for RSA - 
	# Create user account for RSA
	# Verify spi|ontapi|compat web services are enabled for node/admin SVMs
	# Authorize RSA role to access the spi|ontapi|compat services
	#
	# Let's start with collected the current configuration

	# Define our Functions
	# Use this object to determine action to take later in the script
	$ASUPSTATUS = @()
	# Function to get status of ASUP
	function Is-AsupEnabled {
		$NODES = $(Get-NcNode)
		ForEach ($NODE in $NODES) {
			$ASUPCONF = (Get-NcAutoSupportConfig -Node $NODE)
			If ($ASUPCONF.IsEnabled -eq "True") {
				$WHSUCCESS "ASUP is enabled on $NODE"
				$ASUPSTATUS += New-Object -TypeName PSObject -Property @{
						Node = $NODE.Node;
						IsEnabled = $NODE.IsEnabled
				}
			}
			Else {
				$WHFAIL "ASUP is not enabled on $NODE"
				$ASUPSTATUS += New-Object -TypeName PSObject -Property @{
						Node = $NODE.Node;
						IsEnabled = $NODE.IsEnabled
				}
			}
		}
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
		$DATAVAR = Get-DataFromSomewhere

	# Create new object from the data in the variable, and add/append
	# That object into the array we defined in the BEGIN block
	$OUTPUT += New-Object -TypeName PSObject -Property @{
							Node = $DATAVAR.Node;
							IfgrpName = $DATAVAR.IfgrpName;
							Mode = $DATAVAR.Mode;
							MemberPorts = $DATAVAR.MemberPorts;
							UpPorts = $DATAVAR.UpPorts;
							DownPorts = $DATAVAR.DownPorts;
							MacAddress = $DATAVAR.MacAddress
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
