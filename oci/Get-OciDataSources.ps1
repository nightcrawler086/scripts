# This is a script to grab the health of the collection across multiple OCI servers

# Defining our parameters, Username and Passowrd here will be used for each cluster in the array
[CmdletBinding()]
Param (
	[Parameter(Mandatory=$False,Position=1)]
	 [string[]]$OCIservers,

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
	If (!(Get-Module -Name OnCommand-Insight)) {
		Import-Module -Name OnCommand-Insight -ErrorAction SilentlyContinue
	}

	# Same command after attempting import, if the module still isn't there, then
	# output error to the screen and exit the script The backtick (`) is a line-continuation
	If (!(Get-Module -Name OnCommand-Insight)) {
		Write-Host -ForegroundColor Red -BackgroundColor Black `
			"Could not import OnCommand-Insight module, is the OnCommand-Insight module installed?"
		Exit
	}

	# Creating a credential to use to connect to all clusters
	# The ConvertTo-SecureString is required for this
    # Not sure yet if this works to connect to OCI
	$ClusterCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList `
		"$Username",(ConvertTo-SecureString $Password -AsPlainText -Force)

	# Define array of OCI Servers
	$OCISERVERS = @("KDCOCIMGMT01","VDCOCIMGMT01","MDCOCIMGMT01") #gitignore
	
	# This is an empty array in which we will append the data gathered
	# from each cluster.  Again, only need to define it once.  We will
	# populate in the PROCESS block
	$OUTPUT = @()

}

PROCESS {
	ForEach ($OCISERVER in $OCISERVERS) {
		# Let's connect to the cluster first...
		# Connect with credentials we defined earlier, and hide result
		Connect-OciServer -Name $OCISERVER -Credential $ClusterCreds -Insecure | Out-Null
		
		# This is where we would call our functions and/or perform processing 
		$DATASOURCES = Get-OciDataSources

        ForEach ($DATASOURCE in $DATASOURCES) {
        $DSDEVICES = Get-OciDatasourceDevices -id $DATASOURCE.id | Select-Object -ExpandProperty name
            # Create new object from the data in the variable, and add/append
            # That object into the array we defined in the BEGIN block
            # Leaving this here as an example.
            $OUTPUT += New-Object -TypeName PSObject -Property @{
                OciServer = $OCISERVER;
                DatasourceName = $DATASOURCE.Name; 
                Status = $DATASOURCE.status; 
                StatusText = $DATASOURCE.statusText;
                pollStatus = $DATASOURCE.pollStatus;
                vendor = $DATASOURCE.vendor;
                model = $DATASOURCE.model;
                foundationIp = $DATASOURCE.foundationip;
                LastSuccessfulAcquisition = $DATASOURCE.lastSuccessfullyAcquired;
                DatasourceDevices = $DSDEVICES.name
                #TimeStamp = $(Get-Date -Format yyyyMMdd-HHmmss)
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
