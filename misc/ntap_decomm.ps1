<#
.Synopsis
   This script is a single tool to automate the decommissioning process for 
   Netapp Filers.  
.DESCRIPTION
   This script is broken up into three separate phases in accordance with Citi's
   current decommissioning process.

   Precheck:
        - Check if any data volumes are still online
   Phase 1:
        - Offline all volumes
        - Release any existing snapmirror relationships
        - Inventory system
   Phase 2:
        - Search and Destroy
.EXAMPLE
   .\ntap_decomm.ps1 -Filer <FILER> -ChangeNumber <CHANGE_NUMBER> [ -Precheck | -Phase1 | -Phase2 ]
#>

[CmdletBinding()]
Param (
    # The Filer Argument is always required
    [Parameter(Mandatory=$True,Position=1)]
    [ValidateNotNullOrEmpty()]
     [string]$Filer,

    # The ChangeNumber is only required for Phase1 and Phase2
    [Parameter(Mandatory=$True,ParameterSetName="Phase1")]
    [Parameter(Mandatory=$True,ParameterSetName="Phase2")]
    [Parameter(Mandatory=$False,ParameterSetName="Precheck")]
    [ValidateNotNullOrEmpty()]
     [string]$ChangeNumer,

    # If doing a precheck, this switch and -Filer are required
    [Parameter(Mandatory=$True,ParameterSetName="Precheck")]
     [switch]$Precheck,
    
    # If executing Phase1, -Filer + -ChangeNumber + -Phase1 is required
    [Parameter(Mandatory=$True,ParameterSetName="Phase1")]
     [switch]$Phase1,
   
    # If executing Phase2, -Filer + -ChangeNumber + -Phase2 is required
    [Parameter(Mandatory=$True,ParameterSetName="Phase2")]
     [switch]$Phase2
)

BEGIN {

    If (!(Get-ChildItem -Path .\decomm_lib.ps1 -ErrorAction SilentlyContinue)) {
        Write-Host -ForegroundColor Red "Cannot find 'decomm_lib.ps1' in $((Get-Location).Path)"
        Exit 1
    }
    Else {
        Write-Host "Importing Function Library"
        . .\decomm_lib.ps1
    }

    # Make sure we have DataOntap Powershell Module
    If (!(Get-Module DataOntap)) {
        Import-Module DataOntap
    }
    If (!(Get-Module DataOntap)) {
        Write-Host -ForegroundColor Red "Need DataOntap Module...Exiting"
        Exit 1
    }

    #Define Log Levels
    $INFO = "INFO"
    $WARN = "WARN"
    $ERROR = "ERROR"

    # Output array
    $OUTPUT = @()

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
    
    # Might should add some logic here to test the properties to make sure the cluster
    # is healthy.  
    $CLUSTER = Get-NaCluster
    $PARTNER = $($CLUSTER.Partner)
    $LOGSTMP = Get-Date -Format yyyyMMdd-HHmmss
    $LOGFILE = "${LOGSTMP}_${Filer}-decomm.log"
    # Being Verbose here.
    writeLog $LOGFILE "Cluster:  $CurrentNaController / $PARTNER" $INFO
        
    If ($Precheck) {
        writeLog $LOGFILE "Starting Precheck Phase..." $INFO
        writeLog $LOGFILE "No changes will be made during this phase" $INFO
        writeLog $LOGFILE "This phase will check if the filer can proceed to Phase 1" $INFO
        $CONT = Read-Host 'Continue Executing Precheck Phase (y/n) ?'
        # If the user does not want to contine, exit.
        If ($CONT -ne "y") {
            writeLog $LOGFILE "User (${USR}) chose not to execute Precheck Phase" $INFO
            Exit 1
        }
        Else {
            writeLog $LOGFILE "User (${USR}) chose to execute Precheck Phase" $INFO
        }
        # Now we need to check to see if any data volumes are online
        # Calling the Check-NaDvolStatus function from the library
        $RESULT = Check-NaDvolStatus
        $VSTATE = $RESULT | Select-Object -ExpandProperty State -Unique
        If ($VSTATE -contains "online") {
            writeLog $LOGFILE "There are some data volumes still online:" $ERROR
            $ONLINEVOLS = $RESULT | Where {$_.State -eq "online"}
            ForEach ($VOL in $ONLINEVOLS) {
                writeLog $LOGFILE "$($VOL.OwningVfiler):$($VOL.Name) is still online" $ERROR
            }
            writeLog $LOGFILE "Precheck Phase Status:  FAILED" $ERROR
        }
        Else {
            writeLog $LOGFILE "There are no data volumes online!" $INFO
            $STAMP = Get-Date -Format yyyyMMdd-HHmmss
            writeLog $LOGFILE "Storing evidence in .\${STAMP}_${Filer}-precheck-results.csv" $INFO
            $RESULT | Export-Csv -NoTypeInformation -Path .\${STAMP}_${Filer}-precheck-results.csv
        }
    }
    ElseIf ($Phase1) {
    }
    ElseIf ($Phase2) {
    }
    Else {
        Write-Host -ForegroundColor Red "I have no idea how you got here"
        Exit 1
    }

}

END {

}