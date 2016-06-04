# Defining our parameters, Username and Passowrd here will be used for each cluster in the array
# Commenting these out since I don't really use them.
#[CmdletBinding()]
Param (
	[Parameter(Mandatory=$False,Position=1)]
	 [string[]]$SERVERS,

	[Parameter(Mandatory=$False,Position=2)]
	 [string]$HOSTNAME,

	[Parameter(Mandatory=$False,Position=3)]
	 [string]$HOSTIP,

	[Parameter(Mandatory-$True,Position=4)]
	 [string]$USER
)

# This is our BEGIN block (also could be considered the setup block).  Code in this
# block will be run one time.  Could be useful if piping other objects into this
# script
BEGIN {

	# This statement is to define the server list in the script
	# instead of as a script parameter
	If ([string]::IsNullOrEmpty($SERVERS)) {
		$SERVERS = @("Server1","Server2")
	}

	# Define our Functions
	function Add-HostFileEntry {
		Add-Content -Path "C:\Windows\system32\drivers\etc\hosts" -Value "`n$HOSTNAME    $HOSTIP"
	}

}

PROCESS {
	ForEach ($SERVER in $SERVERS) {

	Invoke-Command -ComputerName $SERVER -ScriptBlock { Add-HostFileEntry } -Credential $USER

END {

}
