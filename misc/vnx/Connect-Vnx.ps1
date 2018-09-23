<#
.SYNOPSIS
   This is a function to make then inital connection to the VNX
.DESCRIPTION
    This function makes a connection to the VNX API and returns a
    web session.  The web session can be used for subsequent queries
    or configurations.  The web session will be set into a global
    variable for subsequent query/set/modify cmdlets to use
.EXAMPLE
   PS > .\Connect-Vnx -Name <SYSTEM_NAME> -Credential $creds
#>
function Connect-Vnx
{
    [CmdletBinding()]
    Param
    (
        # Specify the VNX to connect to.  Name or IP will work.
        [Parameter(Mandatory=$true,
         ValueFromPipelineByPropertyName=$true,
         Position=0)]
         [ValidateNotNullOrEmpty()]
         [string]$VNX,
        # Specify the credential object
        [Parameter(Mandatory=$true,
         ValueFromPipelineByPropertyName=$false,
         Position=1)]
         [ValidateNotNullOrEmpty()]
         [System.Management.Automation.PSCredential]$Credential,
        # Using this switch will not verify the SSL Certificate
        [Parameter(Mandatory=$false,
         ValueFromPipelineByPropertyName=$false)]
         [switch]$Insecure
    )
    BEGIN {
        If ($Insecure) {
            # This disables certificate checking, so the self-signed certs dont' stop us
            [system.net.servicepointmanager]::Servercertificatevalidationcallback = {$true}
        }
        Else {
            Write-Host -ForeGroundColor Yellow "This machine must trust the SSL Certificate of the VNX for the connection to suceed"
        }
        # Below two lines are how we retrieve the plain text version
        # of username and password
        $USER = $Credential.GetNetworkCredential().UserName
        $PASS = $Credential.GetNetworkCredential().Password
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
        # Can specify the API version here, but letting the system default to
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
        $LOGIN = Invoke-RestMethod -Uri $LOGINURI -Method 'POST' -Body $BODY -SessionVariable WS
        If ($LOGIN.StatusCode -eq 200) {
            $RESPONSE = Invoke-RestMethod -Uri $APIURI -WebSession $WS -Headers $HEADERS -Body $BODY -Method Post
        }
    }
    END {
        If ($LOGIN) {
            $global:CurrentVnxSystem = $WS
        }
    }
}
