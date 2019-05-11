<#
.Synopsis
   Logging function
.DESCRIPTION
   Write a string of text to a log file and the console
.EXAMPLE
   writeLog <FILE> <MESSAGE> <LEVEL>
   Level = [ INFO | WARN | ERROR ]
#>
function log {
    [CmdletBinding()]
    Param
    (
        # Logfile to write to
        [Parameter(Mandatory=$True,
         ValueFromPipelineByPropertyName=$True,
         Position=0)]
         [ValidateNotNullOrEmpty()]
         [string]$LogFile,
        # Message to write
        [Parameter(Mandatory=$True,
         ValueFromPipelineByPropertyName=$True,
         Position=1)]
         [ValidateNotNullOrEmpty()]
         [string]$Message,
        # Level (INFO, WARN, ERROR)
         [Parameter(Mandatory=$True,
         ValueFromPipelineByPropertyName=$True,
         Position=2)]
         [ValidateNotNullOrEmpty()]
         [string]$Level
    )
    BEGIN {
        # Check to be sure we're not running low on disk space
        $DRIVE = (Get-Location).Drive
        $FREESPACE = Get-WmiObject -Class Win32_LogicalDisk |
         Where-Object {$_.DeviceId -match "$DRIVE"} |
         Select-Object @{Name="FreeSpace";Expression={$_.FreeSpace / 1GB}}
        $FSROUND = [math]::Round($($FREESPACE.FreeSpace))
        If ($FSROUND -le 1) {
            Write-Host -ForegroundColor Red "Only $FREESPACE left on $DRIVE"
            Write-Host -ForegroundColor Red "Run this script from a drive with more free space"
            Throw "Not enough free space on the disk"
        }
    }
    PROCESS {
        $User = $env:USERNAME
        $DATE = Get-Date -Format yyyyMMdd-HHmmss
        $LOGSTR = "$DATE | $User | $Level - $Message"
        # Append the Log File
        Tee-Object -FilePath $LogFile -InputObject $LOGSTR -Append
    }
    END {
        return
    }
}
