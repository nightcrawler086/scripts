<#
.SYNOPSIS
   This cmdlet is used to get a list of all filesystems on a VNX
.DESCRIPTION
   This cmdlet returns all existing filesystems on the VNX.  If querying
   for a specific filesytem, use Get-VnxFilesystem
.EXAMPLE
   PS > Get-VnxFilesystems
#>
function Get-VnxFileSystems
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$false,
         ValueFromPipelineByPropertyName=$true,
         Position=1)]
         [ValidateNotNullOrEmpty()]
         $Fil,

        [Parameter(Mandatory=$false,
         ValueFromPipelineByPropertyName=$true,
         Position=1)]
         [ValidateNotNullOrEmpty()]
         $FileSystem,

    )
    BEGIN {
        # Expecting a Global variable to be set called
        # CurrentVnxSystem which contains the existing
        # session.
        If (!$CurrentVnxSystem) {
            Write-Host -ForegroundColor Red "Not current connected to a VNX System."
            Write-Host -ForegroundColor Red "Run Connect-VnxSystem first."
            Exit 1
        }
        # This is the query URL
        $APIURI = "https://${VNX}/servlets/CelerraManagementServices"
        # Setting header
        $HEADER = @{"Content-Type" = "x-www-form-urlencoded"}
        # Standard "top" of XML Sheet
        $XMLTOP = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        # Standard format of XML Sheet
        $XMLFORMAT = '<RequestPacket xmlns="http://www.emc.com/schemas/celerra/xml_api" >'
        # Standard Footer for XML Sheet
        $XMLFOOTER = '</RequestPacket>'
        # Query for CIFS Shares for entire frame
        $QRYBEGIN = '<Request><Query>'
        $QRY = "<FileSystemQueryParams> <AspectSelection fileSystems=""true"" fileSystemCapacityInfos=""true"" /> <Alias name=""$FileSystem"" /> </FileSystemQueryParams>"
        $QRYEND= '</Query></Request>'
        # Adding all the pieces together
        $BODY = $XMLTOP + $XMLFORMAT + $QRYBEGIN + $QRY + $QRYEND + $XMLFOOTER
        #$BODY = [xml]$BODY

    }
    PROCESS {
            $RESPONSE = Invoke-WebRequest -Uri $APIURL -WebSession $CurrentVnxSystem -Headers  $HEADER -Body $BODY -Method Post
            $fs = [xml]$RESPONSE.Content
            $OUTPUT = $fs.ResponsePacket.Response.Filesystem
    }
    END {
        If (!$OUTPUT) {
            $RESPONSE.Content
        }
        Else {
            $OUTPUT
        }
    }
}
