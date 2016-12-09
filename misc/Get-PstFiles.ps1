Param (
	[Parameter(Mandatory=$True,Position=1)]
	 [string]$InputFile
)

BEGIN {

	$VFILERS = Import-Csv $InputFile
	
	$ALLPSTS = @()	

}

PROCESS {

	ForEach ($SYS in $VFILERS) {
		# Create a new PSDrive (aka mount)
		# Trying to combat some long path problems
		New-PsDrive -Name $SYS -PSProvider FileSystem -Root \\$SYS\C$
		Set-Location $SYS
		$PSTS = Get-ChildItem -File -Recurse -Filter "*.pst"
		ForEach ($PST in $PSTS) {
			$ALLPSTS += New-Object -TypeName PSObject -Property @{
				FileName = $PST.Name;
				FullPath = $PST.FullName;
				Size = $PST.Length;
				LastAccessTime = $PST.LastAccessTime;
				ParentDir = $PST.PsParentPath
			}
		}
	}			
}

END {

	$ALLPSTS

}

