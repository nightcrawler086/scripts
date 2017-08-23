Param (
	[Parameter(Mandatory=$True,Position=1)]
	 [string]$NASCCP,

	[Parameter(Mandatory=$True,Position=2)]
	 [string]$TRACKER,

	[Parameter(Mandatory=$True,Position=3)]
	 [string]$OstFile
)

BEGIN{

}

PROCESS {

$ccp = [System.IO.File]::OpenText($NASCCP)
$tr = [System.IO.File]::OpenText($TRACKER)
$ost = [System.IO.File]::OpenText($OstFile)
$output = New-Object System.IO.StreamWriter 'output.csv'
for(;;) {
    $line = $tr.ReadLine()
    if ($null -eq $line) {
        break
    }
    $data = $line.Split(",")
	$data
    #$writer.WriteLine('{0},{1},{2}', $data[0], $data[2], $data[1])
	$i++
}
$reader.Close()
$writer.Close()

}

END {

}
