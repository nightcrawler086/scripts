<#
.SYNOPSIS
   This is a function to make then inital connection to the VNX
.DESCRIPTION
    This function makes a connection to the VNX API and returns a
    web session.  The web session can be used for subsequent queries
    or configurations.  The web session will be set into a global
    variable for subsequent query/set/modify cmdlets to use
.EXAMPLE
   PS > .\Connect-Vnx -Name <SYSTEM_NAME>
#>
function Disconnect-Vnx
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
         ValueFromPipelineByPropertyName=$true,
         Position=0)]
         [ValidateNotNullOrEmpty()]
         [string]$VNX
    )
    BEGIN {
        If (!$CurrentVnxSystem) {
            Write-Host -ForegroundColor Yellow "No VNX is currently connected."
            Exit 1
        }
        # This header is used to actually tell the API server
        # to gracefully disconnect the session
        $HEADERS = @{"CelerraConnector-Ctl" = "DISCONNECT"}
        # URL to hit for queries
        $APIURI = "https://${VNX}/servlets/CelerraManagementServices"
        # Standard "top" of XML Sheet
        $XMLTOP = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        # Standard format of XML Shee
        # Can specify the API version herel, but letting the system default to
        # its version so this will work on Celerra (hopefully) and VNX
        $XMLFORMAT = '<RequestPacket xmlns="http://www.emc.com/schemas/celerra/xml_api" >'
        # Standard beginning of a query
        $QRYBEGIN = '<Request><Query>'
        # Line specifying the parameters we're querying
        $QRYEND= '</Query></Request>'
        # Standard Footer for XML Sheet
        $XMLFOOTER = '</RequestPacket>'
        # Adding all the pieces together
        $BODY = $XMLTOP + $XMLFORMAT + $QRYBEGIN + $QRYEND + $XMLFOOTER
    }
    PROCESS {
        try {
            $LOGIN = Invoke-WebRequest -Uri $LOGINURI -Method 'POST' -Body $BODY -SessionVariable WS
        }
        catch {
            # This disables certificate checking, so the self-signed certs dont' stop us
            [system.net.servicepointmanager]::Servercertificatevalidationcallback = {$true}
        }
        If ($LOGIN.StatusCode -eq 200) {
            $RESPONSE = Invoke-WebRequest -Uri $APIURI -WebSession $WS -Headers $HEADERS -Body $BODY -Method Post
        }
    }
    END {
        If ($LOGIN) {
            $global:CurrentVnxSystem = $WS
        }
    }
}
