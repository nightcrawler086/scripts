[CmdletBinding()]
Param (
    # Need to add CHG # parameter, Decomm + Rollback switch
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

    function cifs_backup ($vfiler) {
        # Shares Variable
        $SHARES = @()
        # Access Variable
        $ACCESS = @()
        # Get the path of the vFiler's root directory
        $VFROOT = Get-NaVfiler -Name $vfiler | Select-Object -ExpandProperty Vfstores | Where {$_.IsEtc -eq $True} | Select-Object -ExpandProperty Path
        # The vFiler's /etc is always under its root
        $VFPATH = "${VFROOT}/etc"
        # Name of the config file
        $SHRFILE = "cifsconfig_share.cfg"
        # Read the file
        $CIFSCONFIG = Read-NaFile -Path "${VFPATH}/${SHRFILE}"
        # Split it on carriage return and/or newline characters
        $CIFSCONFIG = $CIFSCONFIG -split "`r`n"
        # For each line in the file
        ForEach ($L in $CIFSCONFIG) {
            # Skip any commented out or blank lines
            If ($L -match "^#" -or $line -eq "") {
                Continue
            }
            Else {
                If ($L -match "^cifs shares -add") {
                    #Process one way
                    $SHRSPL = $L -split ' (?=(?:[^"]|"[^"]*")*$)'
                    $SHRNAME = $SHRSPL[3]
                    $SHRPATH = $SHRSPL[4]
                    $SHRCMNT = $SHRSPL[6]
                    $SHRHT = [ordered]@{
                        Share = "$SHRNAME";
                        Path = "$SHRPATH";
                        Comment = "$SHRCMNT"
                    }
                    $SHROBJ = New-Object -TypeName PSObject -Property $SHRHT
                    $SHARES += $SHROBJ

                }
                ElseIf ($L -match "^cifs access") {
                    #Process another way
                    $ACCSPL = $L -split ' (?=(?:[^"]|"[^"]*")*$)', 5
                    $ACCSHR = $ACCSPL[2]
                    $ACCSID = $ACCSPL[3]
                    $ACCPRM = $ACCSPL[4]
                    $ACCHT = [ordered]@{
                        Share = "$ACCSHR";
                        Sid = "$ACCSID"
                        Permission = "$ACCPRM"
                    }
                    $ACCOBJ = New-Object -TypeName PSObject -Property $ACCHT
                    $ACCESS += $ACCOBJ
                }
                Else {
                    Continue
                }
            }
        }
        return $SHARES
        return $ACCESS
    }

    If ($Backup) {
        # Shares Variable
        $SHARES = @()

        # Access Variable
        $ACCESS = @()

        #Output Path
        $OUTPATH = "\\nasswd06cdcs4\Data_share\Data_Shared_All\North_America_Data_Center_Program\Projects\15.00 Global Storage Tech Refresh Programs\NAS Master Tracking Report\WIP\ShareBackup"
    }

    If ($Restore) {
        $RESSHR = Import-Csv $ShareFile
        $RESACC = Import-Csv $AclFile
    }
}
PROCESS {
    # First we'll test to see if the filer is online and responding
    $FALIVE = Test-Connection -ComputerName $Filer -Count 2 -Quiet
    If (!$FALIVE) {
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

    # Should functionalize this CIFS Shares/Access backup here
    # Something like this:
    # cifs_backup(VFILER)
    If ($Backup) {
        $VFROOT = Get-NaVfiler -Name $vFiler | Select-Object -ExpandProperty Vfstores | Where {$_.IsEtc -eq $True} | Select-Object -ExpandProperty Path
        $VFPATH = "${VFROOT}/etc"
        $SHRFILE = "cifsconfig_share.cfg"
        #write-host "${VFROOT}/${SHRFILE}"
        $CIFSCONFIG = Read-NaFile -Path "${VFPATH}/${SHRFILE}"
        $CIFSCONFIG = $CIFSCONFIG -split "`r`n"
        ForEach ($L in $CIFSCONFIG) {
            If ($L -match "^#" -or $line -eq "") {
                Continue
            }
            Else {
                If ($L -match "^cifs shares -add") {
                    #Process one way
                    $SHRSPL = $L -split ' (?=(?:[^"]|"[^"]*")*$)'
                    $SHRNAME = $SHRSPL[3]
                    $SHRPATH = $SHRSPL[4]
                    $SHRCMNT = $SHRSPL[6]
                    $SHRHT = [ordered]@{
                        Share = "$SHRNAME";
                        Path = "$SHRPATH";
                        Comment = "$SHRCMNT"
                    }
                    $SHROBJ = New-Object -TypeName PSObject -Property $SHRHT
                    $SHARES += $SHROBJ

                }
                ElseIf ($L -match "^cifs access") {
                    #Process another way
                    $ACCSPL = $L -split ' (?=(?:[^"]|"[^"]*")*$)', 5
                    $ACCSHR = $ACCSPL[2]
                    $ACCSID = $ACCSPL[3]
                    $ACCPRM = $ACCSPL[4]
                    $ACCHT = [ordered]@{
                        Share = "$ACCSHR";
                        Sid = "$ACCSID"
                        Permission = "$ACCPRM"
                    }
                    $ACCOBJ = New-Object -TypeName PSObject -Property $ACCHT
                    $ACCESS += $ACCOBJ
                }
                Else {
                    Continue
                }
            }
        }
    }
    # If we were going to rollback, should we search for the files on the share?
    If ($Restore) {
        Write-Host "Creating Shares..."
        ForEach ($S in $RESSHR) {
            Write-Host "Creating $($S.Share) on $($S.Path)"
            Invoke-NaSsh -Command "vfiler run $vFiler cifs shares -add $($S.Share) $($S.Path) -comment $($S.Comment)"
        }
        ForEach ($A in $RESACC) {
            Write-Host "Adding ACE for $($A.Sid) on $($A.Share) with $($A.Permission) access"
            Invoke-NaSsh -Command "vfiler run $vFiler cifs access $($A.Share) $($A.Sid) "$($A.Permission)""
        }
    }
}
END {

    If ($Backup) {
        $STUSR = $USR.Substring(0,$USR.Length-2)
        New-PSDrive -Name ShareBackup -PSProvider FileSystem -Root $OUTPATH -Credential $(Get-Credential -UserName ${DOM}\${STUSR} -Message "Enter Credentials to Connect to NAS TR Share") | Out-Null
        $STAMP = Get-Date -Format yyyyMMdd-HHmmss
        $SHARES | Export-Csv -NoTypeInformation -Path ShareBackup:\${STAMP}_${vFiler}-shares.csv
        $ACCESS | Export-Csv -NoTypeInformation -Path ShareBackup:\${STAMP}_${vFiler}-acls.csv
        $CIFSCONFIG | Out-File -FilePath ShareBackup:\${STAMP}_${vFiler}-cifsconfig_share.cfg
        Remove-PSDrive -Name ShareBackup
        net use /delete "$OUTPATH"
        Write-Host "Stored CIFS Shares in .\${STAMP}_${vFiler}-shares.csv"
        Write-Host "Stored ACLS in .\${STAMP}_${vFiler}-acls.csv"
        Write-Host "Stored raw config in .\${STAMP}_${vFiler}-cifsconfig_share.cfg"

    }

} 
            
