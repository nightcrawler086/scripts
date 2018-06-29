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
function Connect-Vnx
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
        # Set login account into a PSCredential object
        $CREDS = Get-Credential -Message "Enter Credentials to Login into ${VNX}"
        # Below two lines are how we retrieve the plain text version
        # of username and password
        $USER = $CREDS.GetNetworkCredential().UserName
        $PASS = $CREDS.GetNetworkCredential().Password
        $LOGINURI = "https://${VNX}/Login"
        # Credentials provided in the body
        # They will be sent via an HTTPS connection so
        # encrypted in flight
        $BODY = "user=${USER}&password=${PASS}&Login=Login"
        # Content-Type header
        $HEADERS = @{"Content-Type" = "x-www-form-urlencoded"}
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
        $QRY = "<CelerraSystemQueryParams/>"
        $QRYEND= '</Query></Request>'
        # Standard Footer for XML Sheet
        $XMLFOOTER = '</RequestPacket>'
        # Adding all the pieces together
        $BODY = $XMLTOP + $XMLFORMAT + $QRYBEGIN + $QRY + $QRYEND + $XMLFOOTER
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
