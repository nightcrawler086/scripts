<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-VnxFileSystems
{
    [CmdletBinding()]
    Param
    (
        # If you're querying the filesystems by name
        [Parameter(Mandatory=$false,
         ValueFromPipelineByPropertyName=$true,
         ParameterSetName="ByName",
         Position=0)]
         [ValidateNotNullOrEmpty()]
         [string]$Name,
        # If you're querying the filesystms by id
        [Parameter(Mandatory=$false,
         ValueFromPipelineByPropertyName=$true,
         ParameterSetName="ById",
         Position=1)]
         [ValidateNotNullOrEmpty()]
         [int]$Id,
        # If you're querying the filesystems by physical datamover id
        [Parameter(Mandatory=$false,
         ValueFromPipelineByPropertyName=$true,
         ParameterSetName="ByDmId",
         Position=2)]
         [ValidateNotNullOrEmpty()]
         [int]$DataMoverId,
        # If you're querying the filesystems by VdmId
        [Parameter(Mandatory=$false,
         ValueFromPipelineByPropertyName=$true,
         ParameterSetName="ByVdmId"
         Position=3)]
         [ValidateNotNullOrEmpty()]
         [int]$VdmId
    )
    BEGIN {
        # We're expecting the connection to the VNX to already be made
        # the session should be in a global variable.  If it's not there bail
        If (!$CurrentVnxSystem) {
            Write-Host -ForegroundColor Red "Not currently connected to a VNX"
            Write-Host -ForegroundColor Red "Run Connect-Vnx"
            Exit 1
        }
        # API URL, which accepts all the queries
        $APIURI = "https://${VNX}/servlets/CelerraManagementServices"
        # Standard "top" of XML Sheet
        $XMLTOP = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        # Standard format of XML Sheet
        $XMLFORMAT = '<RequestPacket xmlns="http://www.emc.com/schemas/celerra/xml_api" >'
        # Standard Footer for XML Sheet
        $XMLFOOTER = '</RequestPacket>'
        # Query for CIFS Shares for entire frame
        $QRYBEGIN = '<Request><Query>'
        $QRY = "<FileSystemQueryParams> <AspectSelection fileSystems=""true"" fileSystemCapacityInfos=""true"" /> </FileSystemQueryParams>"
        $QRYEND= '</Query></Request>'
        # Adding all the pieces together
        $FSREQSHT = $XMLTOP + $XMLFORMAT + $QRYBEGIN + $QRY + $QRYEND + $XMLFOOTER
        #$FSREQSHT = [xml]$FSREQSHT

    }
    PROCESS {
            $response = Invoke-WebRequest -Uri $APIURI -WebSession $session -Headers $headers -Body $FSREQSHT -Method Post
            $fs = [xml]$response.Content
            $output = $fs.ResponsePacket.Response.Filsystem
    }
    END {
        If (!$output) {
            $response.Content
        }
        Else {
            $output
        }
    }
}
