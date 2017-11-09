$SERVERS = @()

$SETSTATE = [System.Management.Automation.Runspaces.InitialSessionStat]::CreateDefault()

$RP = [runspacefactory]::CreateRunspacePool(1,5)

$PS = [powershell]::Create()
$PS.RunspacePool = $RP

$RP.Open()

$CMDS = New-Object -TypeName System.Collections.ArrayList

$SERVERS | foreach {
	$PSA = [powershell]::Create()
	$PSA.RunspacePool = $RP

	[void]$PSA.AddScript({
		param ($COMPUTERNAME)
		Test-Connection -Count 1 -ComputerName $COMPUTERNAME
	})

	[void]$PSA.AddParameter('COMPUTERNAME',"PSITEM")
	$HANDLE = $PSA.BeginInvoke()

	$TEMP = '' | Select Powershell,Handle
	$TEMP.Powershell =  $PSA
	$TEMP.Handle = $HANDLE

	[void]$CMDS.Add($TEMP)
}
