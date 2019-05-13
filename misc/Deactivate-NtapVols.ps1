##################################################################
#                                                                #
# Title:  Deactivate-NtapVols.ps1                                #
# Description:  This script is designed to stop access to        #
#               Netapp volumes that have been migrated.          #
#               This script will check and verify that there is  #
#               no access to the volumes and proceed  to remove  #
#               any shares/exports from the volume, and rename   #
#               the volume.                                      #
#                                                                #
# Author:  Brian Hall <brian.hall@hitachivantara.com>            #
# Version:  0.1                                                  #
# Usage:                                                         #
#                                                                #
# Notes:  All of these functions assume that the                 #
#         connection to the Filer has already been made.         #
#         The functions will not execute unless the              #
#         $CurrentNaController variable is populated             #
#                                                                #
#                                                                #
##################################################################
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
<#
.Synopsis
   CIFS Share backup function
.DESCRIPTION
   Backup and parse the cifs configuration file into objects
.EXAMPLE
   cifs_backup($vfiler, $volumes)
#>
function cifs_backup {
    [CmdletBinding()]
    Param
    (
        # Logfile to write to
        [Parameter(Mandatory=$True,
         ValueFromPipelineByPropertyName=$True,
         Position=0)]
         [ValidateNotNullOrEmpty()]
         [string]$vfiler
    )
    # This is how we get the root directory of the vFiler
    $VFROOT = Get-NaVfiler -Name $vFiler | Select-Object -ExpandProperty Vfstores |
        Where-Object {$_.IsEtc -eq $True} | Select-Object -ExpandProperty Path
    # Make the /etc directory
    $ETCDIR = "${VFROOT}/etc"
    # CIFS configuration file
    $SHRFILE = "cifsconfig_share.cfg"
    # Read the file
    $CIFSCONFIG = Read-NaFile -Path "${ETCDIR}/${SHRFILE}"
    # Split the file on newline and carriage return characters
    $CIFSCONFIG = $CIFSCONFIG -split "`r`n"
    # For each line in the file
    ForEach ($L in $CIFSCONFIG) {
        # If the line is commented out or empty, skip it
        If ($L -match "^#" -or $line -eq "") {
            Continue
        }
        Else {
            # If the line defines a CIFS share, parse it accordingly
            If ($L -match "^cifs shares -add") {
                # Split the line on spaces, unless the space is in quotes
                $SHRSPL = $L -split ' (?=(?:[^"]|"[^"]*")*$)'
                # Share name is the fourth field
                $SHRNAME = $SHRSPL[3]
                # Path is the fifth field
                $SHRPATH = $SHRSPL[4]
                # Comment is the sixth field
                $SHRCMNT = $SHRSPL[6]
                # Create a hash table with share name, path, comment
                $SHRHT = [ordered]@{
                    Share = "$SHRNAME";
                    Path = "$SHRPATH";
                    Comment = "$SHRCMNT"
                }
                # Create the obeject using the hash table
                $SHROBJ = New-Object -TypeName PSObject -Property $SHRHT
                # Add the object to an array of objects
                $SHARES += $SHROBJ
            }
            # If the this is an access definition
            ElseIf ($L -match "^cifs access") {
                # Split on space unless in quotesu
                $ACCSPL = $L -split ' (?=(?:[^"]|"[^"]*")*$)', 5
                # Share to create the access on
                $ACCSHR = $ACCSPL[2]
                # SID to define who
                $ACCSID = $ACCSPL[3]
                # Permission assigned
                $ACCPRM = $ACCSPL[4]
                # Hash table
                $ACCHT = [ordered]@{
                    Share = "$ACCSHR";
                    Sid = "$ACCSID";
                    Permission = "$ACCPRM"
                }
                # Object
                $ACCOBJ = New-Object -TypeName PSObject -Property $ACCHT
                # Array of objects
                $ACCESS += $ACCOBJ
            }
            Else {
                # If we get here, not an share definition or access
                # Also not an empty line or commented line
                # Skip if this ever happens
                Continue
            }
        }
    }
    return $SHARES
    return $ACCESS
}
<#
.Synopsis
   NFS Export Backup
.DESCRIPTION
   Backup and store the NFS exports
.EXAMPLE
   nfs_backup($vfiler)
#>
function nfs_backup {
    [CmdletBinding()]
    Param
    (
        # Logfile to write to
        [Parameter(Mandatory=$True,
         ValueFromPipelineByPropertyName=$True,
         Position=0)]
         [ValidateNotNullOrEmpty()]
         [string]$vfiler
    )
    # Need to store the exports file
    # Store the exports into objects
    # LDAP ?
}
<#
.Synopsis
    Get netstat output from filer
.Description
    Write netstat output from filer to file
.Example
    get_netstat()
#>
function get_netstat {
    Param (
        [Parameter(Mandatory=$true,
         ValueFromPipelineByPropertyName=$True,
         Position=0)]
         [ValidateNotNullOrEmpty()]
         [string]$Filer = $CurrentNaController
    )
    If (!$CurrentNaController) {
        Write-Host -ForegroundColor Red "Not currently connected to any filer."
        Exit 1
    }
    $STAMP = Get-Date -Format yyyMMdd-HHmmss
    Invoke-NaSsh -Command "netstat" | Out-File -FilePath ${STAMP}_${Filer}-netstat.txt
}
<#
.Synopsis
    Parse netstat file into objects
.Description
    Read netstat file and parse the output
.Example
    parse_netstat($file)
#>
function get_netstat {
    Param (
        [Parameter(Mandatory=$true,
         ValueFromPipelineByPropertyName=$True,
         Position=0)]
         [ValidateNotNullOrEmpty()]
         [string]$File
    )
}





########
# This is where the script actually begins executing
########
[CmdletBinding()]
Param (
    # The Filer Argument is always required
    [Parameter(Mandatory=$True,Position=1)]
    [ValidateNotNullOrEmpty()]
     [string]$Filer,
    # The vFiler Argument is always required
    [Parameter(Mandatory=$True,Position=2)]
    [ValidateNotNullOrEmpty()]
     [string]$vFiler,
    # Only required when doing a backup
    [Parameter(Mandatory=$True,ParameterSetName="Backup")]
     [switch]$Backup,
    # Only required when doing restore
    [Parameter(Mandatory=$True,ParameterSetName="Restore")]
     [switch]$Restore,
    # Only required when doing restore
    [Parameter(Mandatory=$True,ParameterSetName="Restore")]
    [ValidateNotNullOrEmpty()]
     [string]$ShareFile,
    # Only required when doing restore
    [Parameter(Mandatory=$True,ParameterSetName="Restore")]
    [ValidateNotNullOrEmpty()]
     [string]$AclFile
)
BEGIN {
    # Make sure we have DataOntap Powershell Module
    If (!(Get-Module DataOntap)) {
        Import-Module DataOntap
    }
    If (!(Get-Module DataOntap)) {
        Write-Host -ForegroundColor Red "Need DataOntap Module...Exiting"
        Exit 1
    }


}
PROCESS {
    # First we'll test to see if the filer is online and responding
    $ALIVE = Test-Connection -ComputerName $Filer -Count 2 -Quiet
    If (!$ALIVE) {
        Write-Host -ForegroundColor Yellow "$Filer is not responding to pings...quitting"
        Exit 1
    }
    # Get credentials based on currently logged in user
    $USR = $env:USERNAME
    # Get Current domain
    $DOM = $env:USERDOMAIN
    # Prompt for password with current DOMAIN\Username
    $Creds = Get-Credential -Message "Enter Credentials to connect to $Filer" -UserName ${DOM}\${USR}
    Connect-NaController -Name $Filer -Credential $Creds | Out-Null


}
END {

}
