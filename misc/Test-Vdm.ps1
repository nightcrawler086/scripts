[CmdletBinding()]
Param (
	[Parameter(Mandatory=$True,Position=1)]
	 [string]$VDMList

)

BEGIN {

}

PROCESS {

	ForEach ($V in $VDMS) {
		Test-Connection $V 
		[System.Net.DNS]::GetHostEntry('${V}')
	}

}

END{


}
