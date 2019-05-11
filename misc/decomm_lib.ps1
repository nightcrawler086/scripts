##################################################################
#                                                                #
# Title:  decomm_lib.ps1                                         #
# Description:  Library of functions for Netapp Filers           #
#               that will be dot sourced from a wrapper script   #
#               to execute Citi's decommissioning process        #
#                                                                #
# Author:  Brian Hall <brian.hall@hitachivantara.com>            #
# Version:  0.1                                                  #
# Usage:  This is not supposed to be used directly.              #
#         Only sourced from another script.                      #
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
function writeLog {
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$True,
         ValueFromPipelineByPropertyName=$True,
         Position=0)]
         [ValidateNotNullOrEmpty()]
         [string]$LogFile,

        [Parameter(Mandatory=$True,
         ValueFromPipelineByPropertyName=$True,
         Position=1)]
         [ValidateNotNullOrEmpty()]
         [string]$Message,

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
   Check-NaDvolStatus
.DESCRIPTION
   This function is used to check that all data volumes
   on the filer are offline.  This is the primary function
   for the Precheck phase.  This function will be used by another
   script which will perform the connection to the filer.  This
   function will only check if there is an existing connection to 
   a filer.
.EXAMPLE
   Check-NaDvolStatus
#>
function Check-NaDvolStatus
{
    BEGIN {
        If (!$CurrentNaController) {
            Write-Host -ForegroundColor Red "Not connected to any Filer"
            Exit 1
        }
        $VOLSTATUS = @()
    }
    PROCESS {
        # Get List of vFilers
        $VFILERS = Get-NaVfiler
        $VOLUMES = Get-NaVol
        $VF0VOL = $VOLUMES | Where-Object {$_.OwningVfiler -eq "vfiler0"}
        $VF0VFS = $VFILERS | Where-Object {$_.Name -eq "vfiler0"} | Select-Object -ExpandProperty VfstoreCount
        If (($VF0VOL | Measure-Object).Count -gt $VF0VFS) {
            Write-Host -ForegroundColor Yellow "Found data volumes on vfiler0"
            $ROOTVOL = Get-NaVolRoot | Select -ExpandProperty Name
            $NOROOT = $VF0VOL | Where-Object {$_.Name -ne "$ROOTVOL"}
            Foreach ($V in $NOROOT) {
                $HT1 = [ordered]@{
                    Name = $($V.Name);
                    OwningVfiler = $($V.OwningVfiler);
                    State = $($V.State)
                }
                $OBJ = New-Object -TypeName PSObject -Property $HT1
                $VOLSTATUS += $OBJ
            }
        }
        # Loop through the vFilers 
        ForEach ($VF in $VFILERS) {
            $DVOLS = $VF | Select-Object Vfstores | Where {$_.IsEtc -eq $false}
            ForEach ($V in $DVOLS) {
                $VPATH = $($V.Path)
                $VNAME = $VPATH.Replace("/vol/","")
                $VOBJ = $VOLUMES | Where-Object {$_.Name -eq "$VNAME"}
                $HT2 = [ordered]@{
                    Name = $($VOBJ.Name);
                    OwningVfiler = $($VOBJ.OwningVfiler);
                    State = $($VOBJ.State)
                }
                $OBJ = New-Object -TypeName PSObject -Property $HT2
                $VOLSTATUS += $OBJ
            }
        }
    }      
    END {
        return $VOLSTATUS
    }
}
<#
.Synopsis
   Get-SysInfo
.DESCRIPTION
   This function is to get the following information from the system:
        - System Name
        - System IP
        - Software Version
        - Serial Number
.EXAMPLE
   Get-NaSysInfo <FILER>
#>
function Get-NaSysInfo {
    BEGIN {
        $NASYSINFO = @()
        If (!$CurrentNaController) {
            $PSCmdlet.WriteError($Global:Error[0])
            return
        }
    }
    PROCESS {
        $SYSINFO = Get-NaSystemInfo    
        $SYSVER = ($CurrentNaController).Version
        $SYSVER = $SYSVER.Split(":")[0]
        $HT = [ordered]@{
            SystemName = $($SYSINFO.SystemName);
            SerialNumber = $($SYSINFO.SystemSerialNumber);
            Model = $($SYSINFO.SystemModel);
            HAPartner = $($SYSINFO.PartnerSystemName);
            Version = "$SYSVER"
        }
        $OBJ = New-Object -TypeName PSObject -Property $HT
        $NASYSINFO += $OBJ
    }
    END {
        return $NASYSINFO
    }
}